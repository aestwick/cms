import { describe, it, expect, beforeAll } from 'vitest';
import {
  generateSessionToken,
  verifySessionToken,
} from '@/lib/stripe/checkout';

// These functions use STRIPE_SECRET_KEY as HMAC key — set a test value
beforeAll(() => {
  process.env.STRIPE_SECRET_KEY = 'sk_test_fake_key_for_unit_tests';
});

// =============================================================================
// generateSessionToken + verifySessionToken
// =============================================================================

describe('generateSessionToken', () => {
  it('returns a 16-character hex string', () => {
    const token = generateSessionToken('cs_test_abc123');
    expect(token).toMatch(/^[0-9a-f]{16}$/);
  });

  it('is deterministic (same input = same output)', () => {
    const token1 = generateSessionToken('cs_test_abc123');
    const token2 = generateSessionToken('cs_test_abc123');
    expect(token1).toBe(token2);
  });

  it('produces different tokens for different sessions', () => {
    const token1 = generateSessionToken('cs_test_session_1');
    const token2 = generateSessionToken('cs_test_session_2');
    expect(token1).not.toBe(token2);
  });
});

describe('verifySessionToken', () => {
  it('verifies a correct token', () => {
    const sessionId = 'cs_test_verify_me';
    const token = generateSessionToken(sessionId);
    expect(verifySessionToken(sessionId, token)).toBe(true);
  });

  it('rejects a wrong token', () => {
    const sessionId = 'cs_test_verify_me';
    expect(verifySessionToken(sessionId, 'deadbeef12345678')).toBe(false);
  });

  it('rejects a token of wrong length', () => {
    const sessionId = 'cs_test_verify_me';
    expect(verifySessionToken(sessionId, 'short')).toBe(false);
  });

  it('rejects empty token', () => {
    const sessionId = 'cs_test_verify_me';
    expect(verifySessionToken(sessionId, '')).toBe(false);
  });

  it('rejects token from a different session', () => {
    const token = generateSessionToken('cs_test_session_A');
    expect(verifySessionToken('cs_test_session_B', token)).toBe(false);
  });
});
