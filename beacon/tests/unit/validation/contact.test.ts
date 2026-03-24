import { describe, it, expect } from 'vitest';
import {
  isValidEmail,
  isValidName,
  isValidPhone,
  validatePhone,
  normalizePhone,
} from '@/lib/validation/contact';

// =============================================================================
// isValidEmail
// =============================================================================

describe('isValidEmail', () => {
  it('accepts a normal email', () => {
    expect(isValidEmail('donor@example.com')).toBe(true);
  });

  it('accepts email with subdomain', () => {
    expect(isValidEmail('donor@mail.example.com')).toBe(true);
  });

  it('accepts email with plus tag', () => {
    expect(isValidEmail('donor+kpfk@gmail.com')).toBe(true);
  });

  it('trims whitespace before checking', () => {
    expect(isValidEmail('  donor@example.com  ')).toBe(true);
  });

  it('rejects empty string', () => {
    expect(isValidEmail('')).toBe(false);
  });

  it('rejects null/undefined coerced to string', () => {
    // TypeScript would normally catch this, but runtime safety matters
    expect(isValidEmail(null as unknown as string)).toBe(false);
    expect(isValidEmail(undefined as unknown as string)).toBe(false);
  });

  it('rejects string without @', () => {
    expect(isValidEmail('donorexample.com')).toBe(false);
  });

  it('rejects string without domain', () => {
    expect(isValidEmail('donor@')).toBe(false);
  });

  it('rejects string without local part', () => {
    expect(isValidEmail('@example.com')).toBe(false);
  });

  it('rejects string with spaces in the middle', () => {
    expect(isValidEmail('donor @example.com')).toBe(false);
  });
});

// =============================================================================
// isValidName
// =============================================================================

describe('isValidName', () => {
  it('accepts a simple name', () => {
    expect(isValidName('John')).toEqual({ valid: true });
  });

  it('accepts names with spaces', () => {
    expect(isValidName('Mary Jane')).toEqual({ valid: true });
  });

  it('accepts hyphenated names', () => {
    expect(isValidName('Mary-Anne')).toEqual({ valid: true });
  });

  it('accepts names with apostrophes', () => {
    expect(isValidName("O'Brien")).toEqual({ valid: true });
  });

  it('accepts accented characters', () => {
    expect(isValidName('François')).toEqual({ valid: true });
    expect(isValidName('María')).toEqual({ valid: true });
    expect(isValidName('Müller')).toEqual({ valid: true });
    expect(isValidName('José')).toEqual({ valid: true });
  });

  it('accepts names with periods', () => {
    expect(isValidName('Dr. Smith')).toEqual({ valid: true });
  });

  it('accepts exactly 50 characters', () => {
    const name = 'A'.repeat(50);
    expect(isValidName(name)).toEqual({ valid: true });
  });

  it('rejects names over 50 characters', () => {
    const name = 'A'.repeat(51);
    const result = isValidName(name);
    expect(result.valid).toBe(false);
    expect(result.error).toContain('50');
  });

  it('rejects empty string', () => {
    const result = isValidName('');
    expect(result.valid).toBe(false);
    expect(result.error).toContain('required');
  });

  it('rejects whitespace-only string', () => {
    const result = isValidName('   ');
    expect(result.valid).toBe(false);
    expect(result.error).toContain('required');
  });

  it('rejects null/undefined', () => {
    expect(isValidName(null as unknown as string).valid).toBe(false);
    expect(isValidName(undefined as unknown as string).valid).toBe(false);
  });

  it('rejects names with numbers', () => {
    const result = isValidName('John123');
    expect(result.valid).toBe(false);
  });

  it('rejects names with special characters', () => {
    const result = isValidName('John@Doe');
    expect(result.valid).toBe(false);
  });
});

// =============================================================================
// isValidPhone
// =============================================================================

describe('isValidPhone', () => {
  it('accepts 10-digit number', () => {
    expect(isValidPhone('5551234567')).toBe(true);
  });

  it('accepts formatted (xxx) xxx-xxxx', () => {
    expect(isValidPhone('(555) 123-4567')).toBe(true);
  });

  it('accepts xxx-xxx-xxxx', () => {
    expect(isValidPhone('555-123-4567')).toBe(true);
  });

  it('accepts 11 digits starting with 1', () => {
    expect(isValidPhone('15551234567')).toBe(true);
  });

  it('accepts 1-xxx-xxx-xxxx', () => {
    expect(isValidPhone('1-555-123-4567')).toBe(true);
  });

  it('rejects 9 digits', () => {
    expect(isValidPhone('555123456')).toBe(false);
  });

  it('rejects 11 digits NOT starting with 1', () => {
    expect(isValidPhone('25551234567')).toBe(false);
  });

  it('rejects empty string', () => {
    expect(isValidPhone('')).toBe(false);
  });

  it('rejects null/undefined', () => {
    expect(isValidPhone(null as unknown as string)).toBe(false);
    expect(isValidPhone(undefined as unknown as string)).toBe(false);
  });

  it('rejects letters', () => {
    expect(isValidPhone('abcdefghij')).toBe(false);
  });
});

// =============================================================================
// validatePhone (optional field — empty is OK)
// =============================================================================

describe('validatePhone', () => {
  it('accepts empty string (phone is optional)', () => {
    expect(validatePhone('')).toEqual({ valid: true });
  });

  it('accepts whitespace-only (treated as empty)', () => {
    expect(validatePhone('   ')).toEqual({ valid: true });
  });

  it('accepts valid phone', () => {
    expect(validatePhone('(555) 123-4567')).toEqual({ valid: true });
  });

  it('rejects invalid phone with helpful message', () => {
    const result = validatePhone('123');
    expect(result.valid).toBe(false);
    expect(result.error).toContain('valid phone number');
  });
});

// =============================================================================
// normalizePhone
// =============================================================================

describe('normalizePhone', () => {
  it('normalizes 10 digits to +1 format', () => {
    expect(normalizePhone('5551234567')).toBe('+15551234567');
  });

  it('normalizes formatted number to +1 format', () => {
    expect(normalizePhone('(555) 123-4567')).toBe('+15551234567');
  });

  it('normalizes 1-xxx-xxx-xxxx to +1 format', () => {
    expect(normalizePhone('1-555-123-4567')).toBe('+15551234567');
  });

  it('normalizes 11 digits starting with 1', () => {
    expect(normalizePhone('15551234567')).toBe('+15551234567');
  });

  it('returns empty string for empty input', () => {
    expect(normalizePhone('')).toBe('');
  });

  it('returns empty string for null/undefined', () => {
    expect(normalizePhone(null as unknown as string)).toBe('');
    expect(normalizePhone(undefined as unknown as string)).toBe('');
  });

  it('returns trimmed original for non-matching format', () => {
    // International numbers or weird inputs pass through unchanged
    expect(normalizePhone('+44 20 7946 0958')).toBe('+44 20 7946 0958');
  });
});
