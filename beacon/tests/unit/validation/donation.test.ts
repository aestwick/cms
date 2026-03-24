import { describe, it, expect } from 'vitest';
import {
  isValidAmount,
  parseOtherAmount,
  validateGiftRecipient,
  isValidFrequency,
} from '@/lib/validation/donation';

// =============================================================================
// isValidAmount
// =============================================================================

describe('isValidAmount', () => {
  it('accepts a valid dollar amount and converts to cents', () => {
    const result = isValidAmount(50);
    expect(result.valid).toBe(true);
    expect(result.normalizedAmount).toBe(5000);
  });

  it('accepts the minimum donation ($5)', () => {
    const result = isValidAmount(5);
    expect(result.valid).toBe(true);
    expect(result.normalizedAmount).toBe(500);
  });

  it('accepts the maximum donation ($10,000)', () => {
    const result = isValidAmount(10000);
    expect(result.valid).toBe(true);
    expect(result.normalizedAmount).toBe(1000000);
  });

  it('rejects below minimum', () => {
    const result = isValidAmount(4.99);
    expect(result.valid).toBe(false);
    expect(result.error).toContain('Minimum');
  });

  it('rejects above maximum', () => {
    const result = isValidAmount(10001);
    expect(result.valid).toBe(false);
    expect(result.error).toContain('Maximum');
  });

  it('rejects zero', () => {
    const result = isValidAmount(0);
    expect(result.valid).toBe(false);
  });

  it('rejects negative amounts', () => {
    const result = isValidAmount(-50);
    expect(result.valid).toBe(false);
  });

  it('rejects NaN', () => {
    const result = isValidAmount(NaN);
    expect(result.valid).toBe(false);
    expect(result.error).toContain('valid amount');
  });

  it('rejects Infinity', () => {
    const result = isValidAmount(Infinity);
    expect(result.valid).toBe(false);
    expect(result.error).toContain('valid amount');
  });

  // String parsing (from "other amount" input field)
  it('parses string dollar amounts', () => {
    const result = isValidAmount('50');
    expect(result.valid).toBe(true);
    expect(result.normalizedAmount).toBe(5000);
  });

  it('strips dollar sign from string input', () => {
    const result = isValidAmount('$50');
    expect(result.valid).toBe(true);
    expect(result.normalizedAmount).toBe(5000);
  });

  it('strips commas from string input', () => {
    const result = isValidAmount('$1,000');
    expect(result.valid).toBe(true);
    expect(result.normalizedAmount).toBe(100000);
  });

  it('handles decimal string input', () => {
    const result = isValidAmount('25.50');
    expect(result.valid).toBe(true);
    expect(result.normalizedAmount).toBe(2550);
  });

  it('rejects non-numeric string', () => {
    const result = isValidAmount('abc');
    expect(result.valid).toBe(false);
    expect(result.error).toContain('valid amount');
  });

  it('rejects empty string', () => {
    const result = isValidAmount('');
    expect(result.valid).toBe(false);
  });

  // Custom min/max overrides
  it('respects custom minimum', () => {
    const result = isValidAmount(9, { minAmount: 10 });
    expect(result.valid).toBe(false);
    expect(result.error).toContain('10');
  });

  it('respects custom maximum', () => {
    const result = isValidAmount(101, { maxAmount: 100 });
    expect(result.valid).toBe(false);
  });

  // Cents rounding — floating point safety
  it('rounds to nearest cent correctly', () => {
    // 19.99 * 100 can produce 1998.9999999... in floating point
    const result = isValidAmount(19.99);
    expect(result.valid).toBe(true);
    expect(result.normalizedAmount).toBe(1999);
  });
});

// =============================================================================
// parseOtherAmount
// =============================================================================

describe('parseOtherAmount', () => {
  it('accepts valid string amount', () => {
    const result = parseOtherAmount('50');
    expect(result.valid).toBe(true);
    expect(result.normalizedAmount).toBe(5000);
  });

  it('rejects empty string', () => {
    const result = parseOtherAmount('');
    expect(result.valid).toBe(false);
    expect(result.error).toContain('enter an amount');
  });

  it('rejects whitespace-only string', () => {
    const result = parseOtherAmount('   ');
    expect(result.valid).toBe(false);
  });

  it('rejects null/undefined', () => {
    expect(parseOtherAmount(null as unknown as string).valid).toBe(false);
    expect(parseOtherAmount(undefined as unknown as string).valid).toBe(false);
  });

  it('delegates to isValidAmount for actual validation', () => {
    // Below minimum should fail the same way
    const result = parseOtherAmount('2');
    expect(result.valid).toBe(false);
    expect(result.error).toContain('Minimum');
  });
});

// =============================================================================
// validateGiftRecipient
// =============================================================================

describe('validateGiftRecipient', () => {
  it('accepts valid recipient with just names', () => {
    const result = validateGiftRecipient({
      firstName: 'Jane',
      lastName: 'Doe',
    });
    expect(result.valid).toBe(true);
    expect(Object.keys(result.errors)).toHaveLength(0);
  });

  it('requires first name', () => {
    const result = validateGiftRecipient({
      firstName: '',
      lastName: 'Doe',
    });
    expect(result.valid).toBe(false);
    expect(result.errors.firstName).toBeDefined();
  });

  it('requires last name', () => {
    const result = validateGiftRecipient({
      firstName: 'Jane',
      lastName: '',
    });
    expect(result.valid).toBe(false);
    expect(result.errors.lastName).toBeDefined();
  });

  it('requires address fields when address is provided', () => {
    const result = validateGiftRecipient({
      firstName: 'Jane',
      lastName: 'Doe',
      address: '123 Main St',
      city: '',
      state: '',
      zip: '',
    });
    expect(result.valid).toBe(false);
    expect(result.errors.city).toBeDefined();
    expect(result.errors.state).toBeDefined();
    expect(result.errors.zip).toBeDefined();
  });

  it('accepts full valid address', () => {
    const result = validateGiftRecipient({
      firstName: 'Jane',
      lastName: 'Doe',
      address: '123 Main St',
      city: 'Los Angeles',
      state: 'CA',
      zip: '90001',
      country: 'US',
    });
    expect(result.valid).toBe(true);
  });

  it('does NOT require address fields when address is undefined', () => {
    // Address is optional — only validated when the address field is present
    const result = validateGiftRecipient({
      firstName: 'Jane',
      lastName: 'Doe',
      // No address fields at all
    });
    expect(result.valid).toBe(true);
  });

  it('collects multiple errors at once', () => {
    const result = validateGiftRecipient({});
    expect(result.valid).toBe(false);
    expect(Object.keys(result.errors).length).toBeGreaterThanOrEqual(2);
  });
});

// =============================================================================
// isValidFrequency
// =============================================================================

describe('isValidFrequency', () => {
  it('accepts "one_time"', () => {
    expect(isValidFrequency('one_time')).toBe(true);
  });

  it('accepts "monthly"', () => {
    expect(isValidFrequency('monthly')).toBe(true);
  });

  it('rejects "yearly"', () => {
    expect(isValidFrequency('yearly')).toBe(false);
  });

  it('rejects "weekly"', () => {
    expect(isValidFrequency('weekly')).toBe(false);
  });

  it('rejects empty string', () => {
    expect(isValidFrequency('')).toBe(false);
  });

  it('is case-sensitive', () => {
    expect(isValidFrequency('One_Time')).toBe(false);
    expect(isValidFrequency('MONTHLY')).toBe(false);
  });
});
