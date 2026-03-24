// Phase 8A Verification Script — run with: node scripts/verify-phase-8a.mjs
// Tests QR signing, QR code generation, and PDF ticket generation end-to-end.

process.env.EVENT_TICKET_SIGNING_SECRET = 'test-secret-for-verification-only';

const { signTicketToken, verifyTicketToken, hashToken } = await import('../src/lib/events/qr.ts');
const { generateQrDataUrl, generateQrBuffer } = await import('../src/lib/events/qr-code.ts');
const { generateTicketPdf } = await import('../src/lib/events/ticket-pdf.ts');

let passed = 0;
let failed = 0;

function check(label, condition) {
  if (condition) {
    console.log(`  PASS: ${label}`);
    passed++;
  } else {
    console.log(`  FAIL: ${label}`);
    failed++;
  }
}

// ============================================================================
// Test 1: QR Token Signing
// ============================================================================
console.log('\n=== 1. QR Token Signing ===');

const options = {
  ticketId: '550e8400-e29b-41d4-a716-446655440000',
  eventId: '660e8400-e29b-41d4-a716-446655440001',
  ticketTypeId: '770e8400-e29b-41d4-a716-446655440002',
  ticketNumber: 'TKT-001234',
  eventEndsAt: new Date('2026-12-31T23:59:59Z'),
};

const { qr_token, qr_token_hash } = signTicketToken(options);

check('Token is a non-empty string', typeof qr_token === 'string' && qr_token.length > 50);
check('Token has JWT format (3 dot-separated parts)', qr_token.split('.').length === 3);
check('Hash is 64-char hex string', typeof qr_token_hash === 'string' && qr_token_hash.length === 64);

// ============================================================================
// Test 2: Token Verification (valid token)
// ============================================================================
console.log('\n=== 2. Token Verification (valid) ===');

const result = verifyTicketToken(qr_token);

check('Token verifies as valid', result.valid === true);
check('Payload contains correct ticket ID', result.payload?.tid === options.ticketId);
check('Payload contains correct event ID', result.payload?.eid === options.eventId);
check('Payload contains correct ticket type ID', result.payload?.ttid === options.ticketTypeId);
check('Payload contains correct ticket number', result.payload?.tn === options.ticketNumber);
check('Payload has issued-at timestamp', typeof result.payload?.iat === 'number');
check('Payload has expiration timestamp', typeof result.payload?.exp === 'number');
const expectedExp = Math.floor(options.eventEndsAt.getTime() / 1000) + 86400;
check('Expiration is 24h after event end', result.payload?.exp === expectedExp);

// ============================================================================
// Test 3: Token Verification (tampered)
// ============================================================================
console.log('\n=== 3. Token Verification (tampered) ===');

const tamperedToken = qr_token.slice(0, -5) + 'XXXXX';
const tamperedResult = verifyTicketToken(tamperedToken);

check('Rejects tampered token', tamperedResult.valid === false);
check('Returns error message', typeof tamperedResult.error === 'string' && tamperedResult.error.length > 0);

// ============================================================================
// Test 4: Token Verification (garbage input)
// ============================================================================
console.log('\n=== 4. Token Verification (garbage input) ===');

const garbageResult = verifyTicketToken('not-a-jwt');
check('Rejects non-JWT string', garbageResult.valid === false);

const emptyResult = verifyTicketToken('');
check('Rejects empty string', emptyResult.valid === false);

// ============================================================================
// Test 5: Token Verification (expired)
// ============================================================================
console.log('\n=== 5. Token Verification (expired) ===');

const expiredOptions = { ...options, eventEndsAt: new Date('2020-01-01T00:00:00Z') };
const { qr_token: expiredToken } = signTicketToken(expiredOptions);
const expiredResult = verifyTicketToken(expiredToken);

check('Rejects expired token', expiredResult.valid === false);
check('Error mentions expiration', expiredResult.error?.includes('expired'));

// ============================================================================
// Test 6: Hash Consistency
// ============================================================================
console.log('\n=== 6. Hash Consistency ===');

const hash1 = hashToken(qr_token);
const hash2 = hashToken(qr_token);

check('Same input produces same hash', hash1 === hash2);
check('Hash matches qr_token_hash from signing', hash1 === qr_token_hash);

// Different tokens produce different hashes
const { qr_token: token2 } = signTicketToken({ ...options, ticketId: '99999999-0000-0000-0000-000000000000' });
const hash3 = hashToken(token2);
check('Different tokens produce different hashes', hash1 !== hash3);

// ============================================================================
// Test 7: QR Code Generation
// ============================================================================
console.log('\n=== 7. QR Code Generation ===');

const dataUrl = await generateQrDataUrl(qr_token);
check('Returns a data URL string', typeof dataUrl === 'string');
check('Data URL starts with PNG header', dataUrl.startsWith('data:image/png;base64,'));
check('Data URL has substantial content', dataUrl.length > 200);

const buffer = await generateQrBuffer(qr_token);
check('Returns a Buffer', Buffer.isBuffer(buffer));
check('Buffer has PNG magic bytes', buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4E && buffer[3] === 0x47);
check('Buffer has substantial size', buffer.length > 500);

// ============================================================================
// Test 8: PDF Ticket Generation
// ============================================================================
console.log('\n=== 8. PDF Ticket Generation ===');

const eventData = {
  title: 'KPFK Annual Benefit Concert',
  date: 'Saturday, March 15, 2026',
  time: '7:00 PM PST',
  doorsOpen: '6:00 PM',
  venueName: 'The Echo',
  venueAddress: '1822 Sunset Blvd, Los Angeles, CA 90026',
  accessibilityInfo: 'Wheelchair accessible. ASL interpreter available.',
};

const orderInfo = {
  confirmationCode: 'KPFK-A3X9',
  buyerName: 'Jane Doe',
};

const tickets = [
  {
    ticketNumber: 'TKT-001234',
    ticketTypeName: 'General Admission',
    attendeeName: 'Jane Doe',
    qrToken: qr_token,
  },
  {
    ticketNumber: 'TKT-001235',
    ticketTypeName: 'VIP',
    attendeeName: 'Jane Doe',
    qrToken: signTicketToken({ ...options, ticketNumber: 'TKT-001235' }).qr_token,
  },
];

const pdfBuffer = await generateTicketPdf(eventData, orderInfo, tickets);

check('Returns a Buffer', Buffer.isBuffer(pdfBuffer));
check('Buffer starts with PDF header (%PDF)', pdfBuffer.slice(0, 5).toString() === '%PDF-');
check('PDF has substantial size (>10KB)', pdfBuffer.length > 10000);
check('PDF is a reasonable size (<5MB)', pdfBuffer.length < 5 * 1024 * 1024);

// Verify the PDF contains expected text content
const pdfText = pdfBuffer.toString('latin1');
check('PDF contains event title', pdfText.includes('KPFK Annual Benefit Concert'));
check('PDF contains ticket number', pdfText.includes('TKT-001234'));
check('PDF contains attendee name', pdfText.includes('Jane Doe'));
check('PDF contains confirmation code', pdfText.includes('KPFK-A3X9'));
check('PDF contains venue name', pdfText.includes('The Echo'));

// Test single ticket PDF
const singleTicketPdf = await generateTicketPdf(eventData, orderInfo, [tickets[0]]);
check('Single ticket PDF generates successfully', Buffer.isBuffer(singleTicketPdf));
check('Single ticket PDF is smaller than 2-ticket', singleTicketPdf.length < pdfBuffer.length);

// ============================================================================
// Summary
// ============================================================================
console.log('\n' + '='.repeat(50));
console.log(`Results: ${passed} passed, ${failed} failed, ${passed + failed} total`);
console.log('='.repeat(50));

if (failed > 0) {
  process.exit(1);
}
