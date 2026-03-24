/**
 * Unit tests for shared formatting utilities (src/lib/format.ts)
 * and query helpers (src/lib/query.ts).
 *
 * These functions replaced 30+ copy-pasted inline definitions.
 * Tests ensure the consolidated versions behave identically.
 */

import { describe, it, expect } from 'vitest';
import {
  formatCurrency,
  formatDollars,
  formatDate,
  formatDateTime,
} from '@/lib/format';
import { escapeLike, DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE } from '@/lib/query';

// ─── formatCurrency ─────────────────────────────────────────────────────────

describe('formatCurrency', () => {
  it('formats cents as USD with two decimals', () => {
    expect(formatCurrency(2500)).toBe('$25.00');
    expect(formatCurrency(100)).toBe('$1.00');
    expect(formatCurrency(0)).toBe('$0.00');
    expect(formatCurrency(99)).toBe('$0.99');
  });

  it('formats large amounts with commas', () => {
    expect(formatCurrency(1234567)).toBe('$12,345.67');
  });

  it('returns dash for null', () => {
    expect(formatCurrency(null)).toBe('-');
  });

  it('returns dash for undefined (runtime safety)', () => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    expect(formatCurrency(undefined as any)).toBe('-');
  });

  it('supports no-decimals mode', () => {
    expect(formatCurrency(2500, { decimals: false })).toBe('$25');
    expect(formatCurrency(2599, { decimals: false })).toBe('$26');
    expect(formatCurrency(1234567, { decimals: false })).toBe('$12,346');
  });

  it('handles negative amounts', () => {
    expect(formatCurrency(-2500)).toBe('-$25.00');
  });
});

// ─── formatDollars ──────────────────────────────────────────────────────────

describe('formatDollars', () => {
  it('formats whole dollar amounts', () => {
    expect(formatDollars(25)).toBe('$25.00');
    expect(formatDollars(0)).toBe('$0.00');
  });

  it('rounds floating-point artifacts', () => {
    // 0.1 + 0.2 = 0.30000000000000004 in JS
    expect(formatDollars(0.1 + 0.2)).toBe('$0.30');
  });

  it('does not include commas (simple format for forms)', () => {
    expect(formatDollars(1234.56)).toBe('$1234.56');
  });

  it('truncates to two decimal places', () => {
    expect(formatDollars(9.999)).toBe('$10.00');
  });
});

// ─── formatDate ─────────────────────────────────────────────────────────────

describe('formatDate', () => {
  it('formats ISO date string with short month', () => {
    // Use noon UTC so the date doesn't shift when converted to America/Los_Angeles
    const result = formatDate('2026-02-25T12:00:00Z');
    expect(result).toMatch(/Feb\s+25,\s+2026/);
  });

  it('returns dash for null', () => {
    expect(formatDate(null)).toBe('-');
  });

  it('returns dash for empty string', () => {
    expect(formatDate('')).toBe('-');
  });

  it('accepts custom fallback', () => {
    expect(formatDate(null, { fallback: '—' })).toBe('—');
    expect(formatDate(null, { fallback: 'N/A' })).toBe('N/A');
  });

  it('supports long month format', () => {
    const result = formatDate('2026-02-25T12:00:00Z', { long: true });
    expect(result).toMatch(/February\s+25,\s+2026/);
  });

  it('accepts Date objects', () => {
    // Use noon UTC so the date doesn't shift when converted to America/Los_Angeles
    const result = formatDate(new Date('2025-12-19T12:00:00Z'));
    expect(result).toMatch(/Dec\s+19,\s+2025/);
  });

  it('accepts Date objects with long format', () => {
    const result = formatDate(new Date('2025-12-19T12:00:00Z'), { long: true });
    expect(result).toMatch(/December\s+19,\s+2025/);
  });
});

// ─── formatDateTime ─────────────────────────────────────────────────────────

describe('formatDateTime', () => {
  it('formats ISO datetime with short month and time', () => {
    const result = formatDateTime('2026-02-25T15:30:00Z');
    // Should contain month, day, year, and time components
    expect(result).toMatch(/Feb/);
    expect(result).toMatch(/25/);
    expect(result).toMatch(/2026/);
  });

  it('returns dash for null', () => {
    expect(formatDateTime(null)).toBe('-');
  });

  it('returns dash for empty string', () => {
    expect(formatDateTime('')).toBe('-');
  });

  it('accepts custom fallback', () => {
    expect(formatDateTime(null, { fallback: '—' })).toBe('—');
  });

  it('supports long format with timezone', () => {
    const result = formatDateTime('2026-02-25T15:30:00Z', { long: true });
    expect(result).toMatch(/February/);
    expect(result).toMatch(/25/);
    expect(result).toMatch(/2026/);
  });
});

// ─── escapeLike ─────────────────────────────────────────────────────────────

describe('escapeLike', () => {
  it('escapes percent sign', () => {
    expect(escapeLike('100%')).toBe('100\\%');
  });

  it('escapes underscore', () => {
    expect(escapeLike('first_name')).toBe('first\\_name');
  });

  it('escapes backslash', () => {
    expect(escapeLike('path\\to')).toBe('path\\\\to');
  });

  it('escapes all special chars together', () => {
    expect(escapeLike('%_\\')).toBe('\\%\\_\\\\');
  });

  it('leaves normal text unchanged', () => {
    expect(escapeLike('John Smith')).toBe('John Smith');
    expect(escapeLike('test@email.com')).toBe('test@email.com');
  });

  it('handles empty string', () => {
    expect(escapeLike('')).toBe('');
  });
});

// ─── Constants ──────────────────────────────────────────────────────────────

describe('query constants', () => {
  it('DEFAULT_PAGE_SIZE is 25', () => {
    expect(DEFAULT_PAGE_SIZE).toBe(25);
  });

  it('MAX_PAGE_SIZE is 100', () => {
    expect(MAX_PAGE_SIZE).toBe(100);
  });
});
