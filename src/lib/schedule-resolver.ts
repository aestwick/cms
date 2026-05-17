/**
 * Schedule slot resolution.
 *
 * Translates the stored slot model (recurring rows + one-off override rows) into
 * the slots that actually air on a given date. Used by both the public schedule
 * page and the admin "calendar week" view.
 *
 * Override semantics:
 *   - A recurring slot with effective_date/expires_date defines its active window.
 *   - A non-recurring slot with effective_date defines a one-time airing on that
 *     specific date. It replaces (suppresses) any recurring slot it time-overlaps.
 */

export interface ResolvableSlot {
  day_of_week: number;
  start_time: string; // "HH:MM:SS"
  end_time: string;   // "HH:MM:SS"
  is_recurring: boolean;
  effective_date: string | null; // "YYYY-MM-DD"
  expires_date: string | null;   // "YYYY-MM-DD"
}

export interface ResolvedDay<T> {
  date: string;       // "YYYY-MM-DD"
  dayOfWeek: number;  // 0-6 (Sunday-Saturday)
  slots: T[];
}

/**
 * Convert "HH:MM[:SS]" to minutes since midnight.
 */
export function timeToMinutes(time: string): number {
  const parts = time.split(":");
  const h = parseInt(parts[0], 10);
  const m = parseInt(parts[1] ?? "0", 10);
  return h * 60 + m;
}

/**
 * Compute day-of-week (0-6, Sunday=0) for a YYYY-MM-DD calendar date.
 * Uses UTC arithmetic so it's deterministic regardless of the system timezone.
 * Dates are treated as their literal calendar value (e.g. 2026-05-17 is always
 * a Sunday), which matches how the DB stores them.
 */
export function dayOfWeekForIso(dateIso: string): number {
  const [y, m, d] = dateIso.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay();
}

/**
 * Add `days` to a YYYY-MM-DD date, returning a new YYYY-MM-DD.
 */
export function addDays(dateIso: string, days: number): string {
  const [y, m, d] = dateIso.split("-").map(Number);
  const next = new Date(Date.UTC(y, m - 1, d));
  next.setUTCDate(next.getUTCDate() + days);
  return next.toISOString().slice(0, 10);
}

function timeOverlaps(a: ResolvableSlot, b: ResolvableSlot): boolean {
  const aStart = timeToMinutes(a.start_time);
  const aEnd = timeToMinutes(a.end_time);
  const bStart = timeToMinutes(b.start_time);
  const bEnd = timeToMinutes(b.end_time);
  return aStart < bEnd && bStart < aEnd;
}

/**
 * Does this slot air on the given date?
 * Returns false for slots that don't match the day-of-week or whose effective
 * window doesn't include the date.
 */
export function slotAppliesOn<T extends ResolvableSlot>(
  slot: T,
  dateIso: string,
  dayOfWeek: number
): boolean {
  if (slot.day_of_week !== dayOfWeek) return false;

  if (slot.is_recurring) {
    if (slot.effective_date && slot.effective_date > dateIso) return false;
    if (slot.expires_date && slot.expires_date < dateIso) return false;
    return true;
  }

  // Non-recurring (one-off): must match the exact date.
  return slot.effective_date === dateIso;
}

/**
 * Resolve which slots actually air on `dateIso`.
 * One-off slots (is_recurring=false) suppress any recurring slot they time-overlap.
 * Result is sorted by start_time.
 */
export function resolveSlotsForDate<T extends ResolvableSlot>(
  dateIso: string,
  slots: T[]
): T[] {
  const dayOfWeek = dayOfWeekForIso(dateIso);
  const applicable = slots.filter((s) => slotAppliesOn(s, dateIso, dayOfWeek));

  const overrides: T[] = [];
  const recurring: T[] = [];
  for (const s of applicable) {
    if (s.is_recurring) recurring.push(s);
    else overrides.push(s);
  }

  const survivingRecurring = recurring.filter(
    (r) => !overrides.some((o) => timeOverlaps(r, o))
  );

  return [...survivingRecurring, ...overrides].sort(
    (a, b) => timeToMinutes(a.start_time) - timeToMinutes(b.start_time)
  );
}

/**
 * Resolve slots for an entire week.
 * `weekStartIso` is the first day of the week (caller's choice — typically today
 * or the most recent Sunday). Always returns 7 consecutive days.
 */
export function resolveSlotsForWeek<T extends ResolvableSlot>(
  weekStartIso: string,
  slots: T[]
): ResolvedDay<T>[] {
  const days: ResolvedDay<T>[] = [];
  for (let i = 0; i < 7; i++) {
    const dateIso = addDays(weekStartIso, i);
    const dayOfWeek = dayOfWeekForIso(dateIso);
    days.push({
      date: dateIso,
      dayOfWeek,
      slots: resolveSlotsForDate(dateIso, slots),
    });
  }
  return days;
}

/**
 * Return the most recent Sunday (inclusive) for the given date.
 * E.g. a Tuesday returns the prior Sunday's date.
 */
export function weekStartFor(dateIso: string): string {
  const dow = dayOfWeekForIso(dateIso);
  return addDays(dateIso, -dow);
}
