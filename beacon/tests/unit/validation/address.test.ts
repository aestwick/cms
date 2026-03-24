import { describe, it, expect } from 'vitest';
import {
  isValidUSZip,
  isValidCAPostal,
  isValidPostalCode,
  isValidUSState,
  isValidCAProvince,
  isValidStateProvince,
  normalizeState,
  normalizeCAPostal,
  normalizeUSZip,
  normalizePostalCode,
  getStatesForCountry,
} from '@/lib/validation/address';

// =============================================================================
// isValidUSZip
// =============================================================================

describe('isValidUSZip', () => {
  it('accepts 5-digit zip', () => {
    expect(isValidUSZip('90210')).toBe(true);
  });

  it('accepts ZIP+4 format', () => {
    expect(isValidUSZip('90210-1234')).toBe(true);
  });

  it('rejects 4 digits', () => {
    expect(isValidUSZip('9021')).toBe(false);
  });

  it('rejects 6 digits without dash', () => {
    expect(isValidUSZip('902101')).toBe(false);
  });

  it('rejects letters', () => {
    expect(isValidUSZip('ABCDE')).toBe(false);
  });

  it('rejects empty string', () => {
    expect(isValidUSZip('')).toBe(false);
  });

  it('rejects null/undefined', () => {
    expect(isValidUSZip(null as unknown as string)).toBe(false);
    expect(isValidUSZip(undefined as unknown as string)).toBe(false);
  });

  it('handles whitespace padding', () => {
    expect(isValidUSZip('  90210  ')).toBe(true);
  });
});

// =============================================================================
// isValidCAPostal
// =============================================================================

describe('isValidCAPostal', () => {
  it('accepts A1A 1A1 format (with space)', () => {
    expect(isValidCAPostal('A1A 1A1')).toBe(true);
  });

  it('accepts A1A1A1 format (no space)', () => {
    expect(isValidCAPostal('A1A1A1')).toBe(true);
  });

  it('accepts lowercase input', () => {
    expect(isValidCAPostal('a1a 1a1')).toBe(true);
  });

  it('accepts with hyphen separator', () => {
    expect(isValidCAPostal('A1A-1A1')).toBe(true);
  });

  it('rejects all digits', () => {
    expect(isValidCAPostal('123 456')).toBe(false);
  });

  it('rejects US zip code', () => {
    expect(isValidCAPostal('90210')).toBe(false);
  });

  it('rejects empty string', () => {
    expect(isValidCAPostal('')).toBe(false);
  });

  it('rejects null/undefined', () => {
    expect(isValidCAPostal(null as unknown as string)).toBe(false);
  });
});

// =============================================================================
// isValidPostalCode (country-aware router)
// =============================================================================

describe('isValidPostalCode', () => {
  it('validates US zip for country "US"', () => {
    expect(isValidPostalCode('90210', 'US')).toEqual({ valid: true });
  });

  it('validates US zip for country "USA"', () => {
    expect(isValidPostalCode('90210', 'USA')).toEqual({ valid: true });
  });

  it('validates US zip for country "UNITED STATES"', () => {
    expect(isValidPostalCode('90210', 'UNITED STATES')).toEqual({ valid: true });
  });

  it('rejects bad US zip with helpful message', () => {
    const result = isValidPostalCode('ABCDE', 'US');
    expect(result.valid).toBe(false);
    expect(result.error).toContain('ZIP');
  });

  it('validates CA postal for country "CA"', () => {
    expect(isValidPostalCode('A1A 1A1', 'CA')).toEqual({ valid: true });
  });

  it('validates CA postal for country "CAN"', () => {
    expect(isValidPostalCode('A1A 1A1', 'CAN')).toEqual({ valid: true });
  });

  it('validates CA postal for country "CANADA"', () => {
    expect(isValidPostalCode('A1A 1A1', 'CANADA')).toEqual({ valid: true });
  });

  it('rejects bad CA postal with helpful message', () => {
    const result = isValidPostalCode('12345', 'CA');
    expect(result.valid).toBe(false);
    expect(result.error).toContain('postal code');
  });

  it('accepts any non-empty code for unknown countries', () => {
    expect(isValidPostalCode('XYZ-123', 'MX')).toEqual({ valid: true });
  });

  it('rejects empty code regardless of country', () => {
    const result = isValidPostalCode('', 'US');
    expect(result.valid).toBe(false);
    expect(result.error).toContain('required');
  });

  it('rejects null/undefined code', () => {
    const result = isValidPostalCode(null as unknown as string, 'US');
    expect(result.valid).toBe(false);
  });

  it('handles case-insensitive country codes', () => {
    expect(isValidPostalCode('90210', 'us')).toEqual({ valid: true });
    expect(isValidPostalCode('A1A 1A1', 'canada')).toEqual({ valid: true });
  });
});

// =============================================================================
// isValidUSState / isValidCAProvince
// =============================================================================

describe('isValidUSState', () => {
  it('accepts valid state abbreviation', () => {
    expect(isValidUSState('CA')).toBe(true);
    expect(isValidUSState('NY')).toBe(true);
    expect(isValidUSState('TX')).toBe(true);
  });

  it('accepts lowercase (case-insensitive)', () => {
    expect(isValidUSState('ca')).toBe(true);
  });

  it('accepts territories', () => {
    expect(isValidUSState('PR')).toBe(true);
    expect(isValidUSState('GU')).toBe(true);
  });

  it('accepts military codes', () => {
    expect(isValidUSState('AA')).toBe(true);
    expect(isValidUSState('AE')).toBe(true);
  });

  it('rejects invalid abbreviation', () => {
    expect(isValidUSState('XX')).toBe(false);
  });

  it('rejects full state names', () => {
    // isValidUSState only accepts abbreviations
    expect(isValidUSState('California')).toBe(false);
  });

  it('rejects empty/null', () => {
    expect(isValidUSState('')).toBe(false);
    expect(isValidUSState(null as unknown as string)).toBe(false);
  });
});

describe('isValidCAProvince', () => {
  it('accepts valid province abbreviation', () => {
    expect(isValidCAProvince('ON')).toBe(true);
    expect(isValidCAProvince('BC')).toBe(true);
    expect(isValidCAProvince('QC')).toBe(true);
  });

  it('accepts lowercase', () => {
    expect(isValidCAProvince('on')).toBe(true);
  });

  it('accepts territories', () => {
    expect(isValidCAProvince('NT')).toBe(true);
    expect(isValidCAProvince('NU')).toBe(true);
    expect(isValidCAProvince('YT')).toBe(true);
  });

  it('rejects US state code', () => {
    // CA is a US state, not a Canadian province abbreviation
    expect(isValidCAProvince('CA')).toBe(false);
  });

  it('rejects empty/null', () => {
    expect(isValidCAProvince('')).toBe(false);
    expect(isValidCAProvince(null as unknown as string)).toBe(false);
  });
});

// =============================================================================
// isValidStateProvince (country-aware router)
// =============================================================================

describe('isValidStateProvince', () => {
  it('validates US state for country "US"', () => {
    expect(isValidStateProvince('CA', 'US')).toEqual({ valid: true });
  });

  it('rejects invalid US state with message', () => {
    const result = isValidStateProvince('XX', 'US');
    expect(result.valid).toBe(false);
    expect(result.error).toContain('US state');
  });

  it('validates CA province for country "CA"', () => {
    expect(isValidStateProvince('ON', 'CA')).toEqual({ valid: true });
  });

  it('rejects invalid CA province with message', () => {
    const result = isValidStateProvince('XX', 'CANADA');
    expect(result.valid).toBe(false);
    expect(result.error).toContain('Canadian province');
  });

  it('accepts any non-empty value for unknown countries', () => {
    expect(isValidStateProvince('SomeState', 'MX')).toEqual({ valid: true });
  });

  it('rejects empty regardless of country', () => {
    const result = isValidStateProvince('', 'US');
    expect(result.valid).toBe(false);
    expect(result.error).toContain('required');
  });
});

// =============================================================================
// normalizeState
// =============================================================================

describe('normalizeState', () => {
  it('keeps valid US abbreviation as-is', () => {
    expect(normalizeState('CA')).toBe('CA');
  });

  it('uppercases lowercase abbreviation', () => {
    expect(normalizeState('ca')).toBe('CA');
  });

  it('resolves full US state name to abbreviation', () => {
    expect(normalizeState('California')).toBe('CA');
    expect(normalizeState('new york')).toBe('NY');
    expect(normalizeState('TEXAS')).toBe('TX');
  });

  it('resolves full CA province name to abbreviation', () => {
    expect(normalizeState('Ontario')).toBe('ON');
    expect(normalizeState('british columbia')).toBe('BC');
  });

  it('keeps valid CA abbreviation as-is', () => {
    expect(normalizeState('ON')).toBe('ON');
  });

  it('returns trimmed input for unknown values', () => {
    expect(normalizeState('XX')).toBe('XX');
    expect(normalizeState('  ZZ  ')).toBe('ZZ');
  });

  it('returns empty string for empty/null', () => {
    expect(normalizeState('')).toBe('');
    expect(normalizeState(null as unknown as string)).toBe('');
  });
});

// =============================================================================
// normalizeCAPostal
// =============================================================================

describe('normalizeCAPostal', () => {
  it('formats A1A1A1 to A1A 1A1', () => {
    expect(normalizeCAPostal('a1a1a1')).toBe('A1A 1A1');
  });

  it('keeps already-formatted code', () => {
    expect(normalizeCAPostal('A1A 1A1')).toBe('A1A 1A1');
  });

  it('uppercases lowercase input', () => {
    expect(normalizeCAPostal('k1a 0b1')).toBe('K1A 0B1');
  });

  it('returns empty for empty/null', () => {
    expect(normalizeCAPostal('')).toBe('');
    expect(normalizeCAPostal(null as unknown as string)).toBe('');
  });
});

// =============================================================================
// normalizeUSZip
// =============================================================================

describe('normalizeUSZip', () => {
  it('keeps 5-digit zip unchanged', () => {
    expect(normalizeUSZip('90210')).toBe('90210');
  });

  it('strips dash from ZIP+4', () => {
    expect(normalizeUSZip('90210-1234')).toBe('902101234');
  });

  it('handles 9 digits without dash', () => {
    expect(normalizeUSZip('902101234')).toBe('902101234');
  });

  it('returns empty for empty/null', () => {
    expect(normalizeUSZip('')).toBe('');
    expect(normalizeUSZip(null as unknown as string)).toBe('');
  });
});

// =============================================================================
// normalizePostalCode (country-aware router)
// =============================================================================

describe('normalizePostalCode', () => {
  it('normalizes US zip', () => {
    expect(normalizePostalCode('90210-1234', 'US')).toBe('902101234');
  });

  it('normalizes CA postal code', () => {
    expect(normalizePostalCode('a1a1a1', 'CANADA')).toBe('A1A 1A1');
  });

  it('trims other country codes', () => {
    expect(normalizePostalCode('  12345  ', 'MX')).toBe('12345');
  });

  it('returns empty for empty/null', () => {
    expect(normalizePostalCode('', 'US')).toBe('');
    expect(normalizePostalCode(null as unknown as string, 'US')).toBe('');
  });
});

// =============================================================================
// getStatesForCountry
// =============================================================================

describe('getStatesForCountry', () => {
  it('returns US states for "US"', () => {
    const states = getStatesForCountry('US');
    expect(states.length).toBeGreaterThan(50); // 50 states + territories + military
    expect(states.find(s => s.value === 'CA')).toEqual({ value: 'CA', label: 'California' });
  });

  it('returns CA provinces for "CANADA"', () => {
    const provinces = getStatesForCountry('CANADA');
    expect(provinces.length).toBe(13);
    expect(provinces.find(s => s.value === 'ON')).toEqual({ value: 'ON', label: 'Ontario' });
  });

  it('returns empty array for unknown country', () => {
    expect(getStatesForCountry('MX')).toEqual([]);
  });

  it('handles case insensitivity', () => {
    expect(getStatesForCountry('us').length).toBeGreaterThan(50);
    expect(getStatesForCountry('canada').length).toBe(13);
  });
});
