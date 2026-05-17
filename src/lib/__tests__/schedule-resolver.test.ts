import { describe, it, expect } from "vitest";
import {
  addDays,
  dayOfWeekForIso,
  resolveSlotsForDate,
  resolveSlotsForWeek,
  slotAppliesOn,
  timeToMinutes,
  weekStartFor,
  type ResolvableSlot,
} from "@/lib/schedule-resolver";

// Test fixtures: 2026-05-17 is a Sunday (day 0).
const SUNDAY = "2026-05-17";
const MONDAY = "2026-05-18";
const TUESDAY = "2026-05-19";

function slot(overrides: Partial<ResolvableSlot> = {}): ResolvableSlot {
  return {
    day_of_week: 0,
    start_time: "09:00:00",
    end_time: "10:00:00",
    is_recurring: true,
    effective_date: null,
    expires_date: null,
    ...overrides,
  };
}

describe("timeToMinutes", () => {
  it("parses HH:MM:SS", () => {
    expect(timeToMinutes("09:30:00")).toBe(570);
  });

  it("parses HH:MM", () => {
    expect(timeToMinutes("09:30")).toBe(570);
  });

  it("handles midnight", () => {
    expect(timeToMinutes("00:00:00")).toBe(0);
  });

  it("handles 23:59", () => {
    expect(timeToMinutes("23:59:00")).toBe(1439);
  });
});

describe("dayOfWeekForIso", () => {
  it("returns Sunday=0 for 2026-05-17", () => {
    expect(dayOfWeekForIso("2026-05-17")).toBe(0);
  });

  it("returns Tuesday=2", () => {
    expect(dayOfWeekForIso("2026-05-19")).toBe(2);
  });

  it("returns Saturday=6", () => {
    expect(dayOfWeekForIso("2026-05-23")).toBe(6);
  });

  it("is timezone-independent (uses UTC)", () => {
    // Same iso date always returns same day regardless of when tests run.
    expect(dayOfWeekForIso("2026-01-01")).toBe(4); // Thursday
  });
});

describe("addDays", () => {
  it("adds positive days", () => {
    expect(addDays("2026-05-17", 1)).toBe("2026-05-18");
    expect(addDays("2026-05-17", 7)).toBe("2026-05-24");
  });

  it("adds negative days", () => {
    expect(addDays("2026-05-17", -1)).toBe("2026-05-16");
  });

  it("crosses month boundary", () => {
    expect(addDays("2026-05-31", 1)).toBe("2026-06-01");
  });

  it("crosses year boundary", () => {
    expect(addDays("2026-12-31", 1)).toBe("2027-01-01");
  });

  it("handles leap year February", () => {
    expect(addDays("2024-02-28", 1)).toBe("2024-02-29");
    expect(addDays("2024-02-29", 1)).toBe("2024-03-01");
  });

  it("handles non-leap year February", () => {
    expect(addDays("2025-02-28", 1)).toBe("2025-03-01");
  });
});

describe("weekStartFor", () => {
  it("returns the same day if Sunday", () => {
    expect(weekStartFor("2026-05-17")).toBe("2026-05-17");
  });

  it("returns the prior Sunday for a Tuesday", () => {
    expect(weekStartFor("2026-05-19")).toBe("2026-05-17");
  });

  it("returns the prior Sunday for a Saturday", () => {
    expect(weekStartFor("2026-05-23")).toBe("2026-05-17");
  });
});

describe("slotAppliesOn", () => {
  it("matches recurring slot on correct day-of-week with no date window", () => {
    expect(
      slotAppliesOn(slot({ day_of_week: 0 }), SUNDAY, 0)
    ).toBe(true);
  });

  it("rejects recurring slot on wrong day-of-week", () => {
    expect(
      slotAppliesOn(slot({ day_of_week: 1 }), SUNDAY, 0)
    ).toBe(false);
  });

  it("rejects recurring slot before its effective_date", () => {
    expect(
      slotAppliesOn(
        slot({ effective_date: "2026-06-01" }),
        SUNDAY,
        0
      )
    ).toBe(false);
  });

  it("accepts recurring slot on its effective_date", () => {
    expect(
      slotAppliesOn(
        slot({ effective_date: SUNDAY }),
        SUNDAY,
        0
      )
    ).toBe(true);
  });

  it("rejects recurring slot after its expires_date", () => {
    expect(
      slotAppliesOn(
        slot({ expires_date: "2026-05-10" }),
        SUNDAY,
        0
      )
    ).toBe(false);
  });

  it("accepts recurring slot on its expires_date", () => {
    expect(
      slotAppliesOn(
        slot({ expires_date: SUNDAY }),
        SUNDAY,
        0
      )
    ).toBe(true);
  });

  it("matches non-recurring slot exactly on effective_date", () => {
    expect(
      slotAppliesOn(
        slot({ is_recurring: false, effective_date: SUNDAY }),
        SUNDAY,
        0
      )
    ).toBe(true);
  });

  it("rejects non-recurring slot on a different date even with matching day-of-week", () => {
    // SUNDAY and 2026-05-24 are both Sundays
    expect(
      slotAppliesOn(
        slot({ is_recurring: false, effective_date: "2026-05-24" }),
        SUNDAY,
        0
      )
    ).toBe(false);
  });

  it("rejects non-recurring slot with no effective_date", () => {
    expect(
      slotAppliesOn(
        slot({ is_recurring: false, effective_date: null }),
        SUNDAY,
        0
      )
    ).toBe(false);
  });
});

describe("resolveSlotsForDate", () => {
  it("returns recurring slots for the given day, sorted by start_time", () => {
    const slots = [
      slot({ start_time: "12:00:00", end_time: "13:00:00" }),
      slot({ start_time: "09:00:00", end_time: "10:00:00" }),
      slot({ day_of_week: 1, start_time: "08:00:00", end_time: "09:00:00" }),
    ];

    const result = resolveSlotsForDate(SUNDAY, slots);

    expect(result).toHaveLength(2);
    expect(result[0].start_time).toBe("09:00:00");
    expect(result[1].start_time).toBe("12:00:00");
  });

  it("returns empty array when no slots match", () => {
    const slots = [slot({ day_of_week: 1 })];
    expect(resolveSlotsForDate(SUNDAY, slots)).toEqual([]);
  });

  it("one-off override replaces overlapping recurring slot", () => {
    const recurring = slot({
      start_time: "09:00:00",
      end_time: "10:00:00",
      is_recurring: true,
    });
    const override = slot({
      start_time: "09:00:00",
      end_time: "10:00:00",
      is_recurring: false,
      effective_date: SUNDAY,
    });

    const result = resolveSlotsForDate(SUNDAY, [recurring, override]);

    expect(result).toHaveLength(1);
    expect(result[0]).toBe(override);
  });

  it("one-off override does not affect non-overlapping recurring slot", () => {
    const earlyRecurring = slot({
      start_time: "09:00:00",
      end_time: "10:00:00",
      is_recurring: true,
    });
    const lateRecurring = slot({
      start_time: "14:00:00",
      end_time: "15:00:00",
      is_recurring: true,
    });
    const override = slot({
      start_time: "09:00:00",
      end_time: "10:00:00",
      is_recurring: false,
      effective_date: SUNDAY,
    });

    const result = resolveSlotsForDate(SUNDAY, [
      earlyRecurring,
      lateRecurring,
      override,
    ]);

    expect(result).toHaveLength(2);
    expect(result).toContain(lateRecurring);
    expect(result).toContain(override);
    expect(result).not.toContain(earlyRecurring);
  });

  it("partial overlap (one-off starts mid-slot) still suppresses recurring", () => {
    const recurring = slot({
      start_time: "09:00:00",
      end_time: "11:00:00",
    });
    const override = slot({
      start_time: "10:00:00",
      end_time: "11:00:00",
      is_recurring: false,
      effective_date: SUNDAY,
    });

    const result = resolveSlotsForDate(SUNDAY, [recurring, override]);
    expect(result).toHaveLength(1);
    expect(result[0]).toBe(override);
  });

  it("adjacent slots (one ends where next starts) do not overlap", () => {
    const recurring = slot({
      start_time: "09:00:00",
      end_time: "10:00:00",
    });
    const override = slot({
      start_time: "10:00:00",
      end_time: "11:00:00",
      is_recurring: false,
      effective_date: SUNDAY,
    });

    const result = resolveSlotsForDate(SUNDAY, [recurring, override]);
    expect(result).toHaveLength(2);
  });

  it("ignores override targeting a different date", () => {
    const recurring = slot({
      start_time: "09:00:00",
      end_time: "10:00:00",
    });
    const override = slot({
      start_time: "09:00:00",
      end_time: "10:00:00",
      is_recurring: false,
      effective_date: "2026-05-24", // also Sunday, but different date
    });

    const result = resolveSlotsForDate(SUNDAY, [recurring, override]);
    expect(result).toHaveLength(1);
    expect(result[0]).toBe(recurring);
  });

  it("respects effective_date on recurring slot (replacement starting later)", () => {
    const oldRecurring = slot({
      start_time: "09:00:00",
      end_time: "10:00:00",
      expires_date: "2026-05-17", // ends on SUNDAY (inclusive)
    });
    const newRecurring = slot({
      start_time: "09:00:00",
      end_time: "10:00:00",
      effective_date: "2026-05-18", // starts Monday
    });

    // SUNDAY: only old applies
    const sunResult = resolveSlotsForDate(SUNDAY, [oldRecurring, newRecurring]);
    expect(sunResult).toEqual([oldRecurring]);

    // Next week's Sunday: only new applies
    const nextSunResult = resolveSlotsForDate("2026-05-24", [oldRecurring, newRecurring]);
    expect(nextSunResult).toEqual([newRecurring]);
  });

  it("two overrides at different times both apply", () => {
    const overrideA = slot({
      start_time: "09:00:00",
      end_time: "10:00:00",
      is_recurring: false,
      effective_date: SUNDAY,
    });
    const overrideB = slot({
      start_time: "14:00:00",
      end_time: "15:00:00",
      is_recurring: false,
      effective_date: SUNDAY,
    });

    const result = resolveSlotsForDate(SUNDAY, [overrideA, overrideB]);
    expect(result).toHaveLength(2);
    expect(result[0]).toBe(overrideA);
    expect(result[1]).toBe(overrideB);
  });
});

describe("resolveSlotsForWeek", () => {
  it("returns 7 consecutive days starting from weekStartIso", () => {
    const result = resolveSlotsForWeek(SUNDAY, []);
    expect(result).toHaveLength(7);
    expect(result[0].date).toBe(SUNDAY);
    expect(result[0].dayOfWeek).toBe(0);
    expect(result[6].date).toBe("2026-05-23");
    expect(result[6].dayOfWeek).toBe(6);
  });

  it("distributes slots to their matching days", () => {
    const slots = [
      slot({ day_of_week: 0, start_time: "09:00:00", end_time: "10:00:00" }),
      slot({ day_of_week: 2, start_time: "14:00:00", end_time: "15:00:00" }),
    ];

    const result = resolveSlotsForWeek(SUNDAY, slots);

    expect(result[0].slots).toHaveLength(1);
    expect(result[1].slots).toHaveLength(0);
    expect(result[2].slots).toHaveLength(1);
  });

  it("can start mid-week", () => {
    const result = resolveSlotsForWeek(TUESDAY, []);
    expect(result[0].date).toBe(TUESDAY);
    expect(result[0].dayOfWeek).toBe(2);
    expect(result[6].dayOfWeek).toBe(1); // wraps around to Monday
  });

  it("handles overrides within the week", () => {
    const recurring = slot({
      day_of_week: 1, // Monday
      start_time: "09:00:00",
      end_time: "10:00:00",
    });
    const override = slot({
      day_of_week: 1,
      start_time: "09:00:00",
      end_time: "10:00:00",
      is_recurring: false,
      effective_date: MONDAY,
    });

    const result = resolveSlotsForWeek(SUNDAY, [recurring, override]);

    // Monday is index 1
    expect(result[1].slots).toHaveLength(1);
    expect(result[1].slots[0]).toBe(override);
  });
});
