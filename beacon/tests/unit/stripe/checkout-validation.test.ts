import { describe, it, expect, vi, beforeEach } from 'vitest';
import { validateCheckoutRequest } from '@/lib/stripe/checkout';
import type { CheckoutRequest } from '@/lib/stripe/checkout';

// Mock Supabase so we don't need a real DB connection.
// Only the gift lookup (step 7) hits the DB — everything else is pure validation.
vi.mock('@/lib/supabase-admin', () => ({
  getSupabaseAdmin: () => ({
    from: () => ({
      select: () => ({
        eq: () => ({
          eq: () => ({
            is: () => ({
              single: () => Promise.resolve({ data: null, error: null }),
            }),
          }),
        }),
      }),
    }),
  }),
}));

// =============================================================================
// Test helper: builds a minimal valid checkout request
// =============================================================================

function validRequest(overrides: Partial<CheckoutRequest> = {}): CheckoutRequest {
  return {
    donation_type: 'one_time',
    amount: 5000, // $50.00 in cents
    anonymous: false,
    cover_fees: false,
    consent: { updates: false, email_tax_letter: false },
    donor: {}, // All donor fields are optional — Stripe collects email at checkout
    success_url: 'https://donate.kpfk.org/success',
    cancel_url: 'https://donate.kpfk.org/cancel',
    ...overrides,
  };
}

// =============================================================================
// Amount validation (the type coercion guard — most critical security check)
// =============================================================================

describe('validateCheckoutRequest — amount validation', () => {
  it('accepts valid integer amount in cents', async () => {
    const result = await validateCheckoutRequest(validRequest({ amount: 5000 }));
    expect(result).toBeNull(); // null = no errors
  });

  it('rejects amount as string (type coercion attack)', async () => {
    const result = await validateCheckoutRequest(
      validRequest({ amount: '1000' as unknown as number })
    );
    expect(result).not.toBeNull();
    expect(result!.code).toBe('INVALID_AMOUNT');
  });

  it('rejects float amount (must be whole cents)', async () => {
    const result = await validateCheckoutRequest(validRequest({ amount: 50.5 }));
    expect(result).not.toBeNull();
    expect(result!.code).toBe('INVALID_AMOUNT');
  });

  it('rejects NaN', async () => {
    const result = await validateCheckoutRequest(validRequest({ amount: NaN }));
    expect(result).not.toBeNull();
    expect(result!.code).toBe('INVALID_AMOUNT');
  });

  it('rejects Infinity', async () => {
    const result = await validateCheckoutRequest(validRequest({ amount: Infinity }));
    expect(result).not.toBeNull();
    expect(result!.code).toBe('INVALID_AMOUNT');
  });

  it('rejects amount below $5.00 (500 cents)', async () => {
    const result = await validateCheckoutRequest(validRequest({ amount: 499 }));
    expect(result).not.toBeNull();
    expect(result!.code).toBe('AMOUNT_TOO_LOW');
  });

  it('accepts exactly $5.00 (500 cents)', async () => {
    const result = await validateCheckoutRequest(validRequest({ amount: 500 }));
    expect(result).toBeNull();
  });

  it('accepts exactly $10,000 (1,000,000 cents)', async () => {
    const result = await validateCheckoutRequest(validRequest({ amount: 1000000 }));
    expect(result).toBeNull();
  });

  it('rejects above $10,000', async () => {
    const result = await validateCheckoutRequest(validRequest({ amount: 1000001 }));
    expect(result).not.toBeNull();
    expect(result!.code).toBe('AMOUNT_TOO_HIGH');
  });

  it('rejects zero', async () => {
    const result = await validateCheckoutRequest(validRequest({ amount: 0 }));
    expect(result).not.toBeNull();
  });

  it('rejects negative amount', async () => {
    const result = await validateCheckoutRequest(validRequest({ amount: -5000 }));
    expect(result).not.toBeNull();
  });
});

// =============================================================================
// Annual giving validation
// =============================================================================

describe('validateCheckoutRequest — annual giving', () => {
  function annualRequest(overrides: Partial<CheckoutRequest> = {}): CheckoutRequest {
    return validRequest({
      donation_type: 'annual',
      amount: 30000, // $300 (Sustainer annual tier)
      ...overrides,
    });
  }

  it('accepts valid annual donation', async () => {
    const result = await validateCheckoutRequest(annualRequest());
    expect(result).toBeNull();
  });

  it('rejects annual donation below $25', async () => {
    const result = await validateCheckoutRequest(annualRequest({ amount: 2499 }));
    expect(result).not.toBeNull();
    expect(result!.code).toBe('ANNUAL_AMOUNT_TOO_LOW');
  });

  it('accepts exactly $25 annual donation', async () => {
    const result = await validateCheckoutRequest(annualRequest({ amount: 2500 }));
    expect(result).toBeNull();
  });
});

// =============================================================================
// Shipping address validation
// =============================================================================

describe('validateCheckoutRequest — shipping address', () => {
  it('validates shipping zip for US addresses', async () => {
    const result = await validateCheckoutRequest(
      validRequest({
        selected_premium_id: 'some-gift-uuid',
        donor: {
          shipping: {
            line1: '123 Main St',
            city: 'LA',
            state: 'CA',
            postal_code: 'INVALID',
            country: 'US',
          },
        },
      })
    );
    expect(result).not.toBeNull();
    expect(result!.code).toBe('INVALID_SHIPPING_ZIP');
  });

  it('validates shipping state for US addresses', async () => {
    const result = await validateCheckoutRequest(
      validRequest({
        selected_premium_id: 'some-gift-uuid',
        donor: {
          shipping: {
            line1: '123 Main St',
            city: 'LA',
            state: 'XX',
            postal_code: '90001',
            country: 'US',
          },
        },
      })
    );
    expect(result).not.toBeNull();
    expect(result!.code).toBe('INVALID_SHIPPING_STATE');
  });

  it('rejects incomplete shipping address', async () => {
    const result = await validateCheckoutRequest(
      validRequest({
        selected_premium_id: 'some-gift-uuid',
        donor: {
          shipping: {
            line1: '',
            city: 'LA',
            state: 'CA',
            postal_code: '90001',
            country: 'US',
          },
        },
      })
    );
    expect(result).not.toBeNull();
    expect(result!.code).toBe('INCOMPLETE_SHIPPING');
  });
});

// =============================================================================
// Donor field validation
// =============================================================================

describe('validateCheckoutRequest — donor fields', () => {
  it('validates donor phone if provided', async () => {
    const result = await validateCheckoutRequest(
      validRequest({
        donor: { phone: '123' },
      })
    );
    expect(result).not.toBeNull();
    expect(result!.code).toBe('INVALID_PHONE');
  });

  it('accepts valid donor phone', async () => {
    const result = await validateCheckoutRequest(
      validRequest({
        donor: { phone: '(555) 123-4567' },
      })
    );
    expect(result).toBeNull();
  });

  it('validates donor email format if provided', async () => {
    const result = await validateCheckoutRequest(
      validRequest({
        donor: { email: 'not-an-email' },
      })
    );
    expect(result).not.toBeNull();
    expect(result!.code).toBe('INVALID_DONOR_EMAIL');
  });

  it('validates donor first name if provided', async () => {
    const result = await validateCheckoutRequest(
      validRequest({
        donor: { first_name: 'John123' },
      })
    );
    expect(result).not.toBeNull();
    expect(result!.code).toBe('INVALID_DONOR_NAME');
  });

  it('validates donor last name if provided', async () => {
    const result = await validateCheckoutRequest(
      validRequest({
        donor: { last_name: 'Doe@#$' },
      })
    );
    expect(result).not.toBeNull();
    expect(result!.code).toBe('INVALID_DONOR_NAME');
  });

  it('allows omitting all donor fields (Stripe collects email at checkout)', async () => {
    const result = await validateCheckoutRequest(validRequest());
    expect(result).toBeNull();
  });
});

// =============================================================================
// Premium / gift selection validation
// =============================================================================

describe('validateCheckoutRequest — premium validation', () => {
  it('rejects unknown premium ID (not BHM, not in DB)', async () => {
    // Mock returns null for DB lookup, and ID doesn't match any BHM gift
    const result = await validateCheckoutRequest(
      validRequest({ selected_premium_id: 'unknown-uuid-12345' })
    );
    expect(result).not.toBeNull();
    expect(result!.code).toBe('INVALID_PREMIUM_ID');
  });

  it('accepts request with no premium selected', async () => {
    const result = await validateCheckoutRequest(validRequest());
    expect(result).toBeNull();
  });
});
