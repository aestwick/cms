import { describe, it, expect, vi } from "vitest";
import {
  captureSnapshot,
  diffSnapshots,
  describeOperation,
  type SnapshotSlot,
} from "@/lib/schedule-snapshots";

// Lightweight Supabase mock: tracks the chained .from(...).select/insert/etc.
// We don't need a full client — just enough to verify the call shape.
function makeMockSupabase(opts: {
  slots?: Partial<SnapshotSlot>[];
  insertResult?: { id: string };
  keepIdsCount?: number;
  fetchError?: { message: string };
  insertError?: { message: string };
}) {
  const slots = opts.slots ?? [];
  const inserts: unknown[] = [];
  const deletes: unknown[] = [];

  const supabase = {
    from(table: string) {
      if (table === "cms_schedule_slots") {
        return {
          select: () => ({
            eq: () =>
              Promise.resolve({
                data: opts.fetchError ? null : slots,
                error: opts.fetchError ?? null,
              }),
          }),
        };
      }

      if (table === "cms_schedule_snapshots") {
        return {
          insert: (payload: unknown) => {
            inserts.push(payload);
            return {
              select: () => ({
                single: () =>
                  Promise.resolve({
                    data: opts.insertError
                      ? null
                      : opts.insertResult ?? { id: "new-snapshot-id" },
                    error: opts.insertError ?? null,
                  }),
              }),
            };
          },
          select: () => ({
            eq: () => ({
              order: () => ({
                limit: () =>
                  Promise.resolve({
                    data: Array.from(
                      { length: opts.keepIdsCount ?? 0 },
                      (_, i) => ({ id: `keep-${i}` })
                    ),
                    error: null,
                  }),
              }),
            }),
          }),
          delete: () => ({
            eq: () => ({
              not: () => {
                deletes.push({ table });
                return Promise.resolve({ count: 0, error: null });
              },
            }),
          }),
        };
      }

      return {} as never;
    },
  };

  return { supabase, inserts, deletes };
}

describe("captureSnapshot", () => {
  it("inserts a snapshot row with the current slot data and returns its id", async () => {
    const slots: SnapshotSlot[] = [
      {
        show_id: "s1",
        day_of_week: 1,
        start_time: "09:00:00",
        end_time: "10:00:00",
        label: null,
        image_path: null,
        is_recurring: true,
        effective_date: null,
        expires_date: null,
        confessor_synced: false,
      },
    ];
    const { supabase, inserts } = makeMockSupabase({ slots });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const result = await captureSnapshot(supabase as any, {
      stationId: "station-1",
      userId: "user-1",
      operation: "manual_save",
      description: "Test snapshot",
    });

    expect(result.id).toBe("new-snapshot-id");
    expect(result.slotCount).toBe(1);
    expect(inserts).toHaveLength(1);

    const inserted = inserts[0] as Record<string, unknown>;
    expect(inserted.station_id).toBe("station-1");
    expect(inserted.created_by).toBe("user-1");
    expect(inserted.operation).toBe("manual_save");
    expect(inserted.slot_count).toBe(1);
    expect(Array.isArray(inserted.slot_data)).toBe(true);
  });

  it("captures an empty snapshot when there are no slots", async () => {
    const { supabase } = makeMockSupabase({ slots: [] });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const result = await captureSnapshot(supabase as any, {
      stationId: "station-1",
      userId: null,
      operation: "pre_revert",
      description: "Empty",
    });

    expect(result.slotCount).toBe(0);
  });

  it("throws when slot fetch fails", async () => {
    const { supabase } = makeMockSupabase({
      fetchError: { message: "boom" },
    });

    await expect(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      captureSnapshot(supabase as any, {
        stationId: "station-1",
        userId: null,
        operation: "manual_save",
        description: "x",
      })
    ).rejects.toThrow(/boom/);
  });

  it("throws when snapshot insert fails", async () => {
    const { supabase } = makeMockSupabase({
      slots: [],
      insertError: { message: "insert failed" },
    });

    await expect(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      captureSnapshot(supabase as any, {
        stationId: "station-1",
        userId: null,
        operation: "manual_save",
        description: "x",
      })
    ).rejects.toThrow(/insert failed/);
  });
});

describe("diffSnapshots", () => {
  const slot = (overrides: Partial<SnapshotSlot> = {}): SnapshotSlot => ({
    show_id: null,
    day_of_week: 1,
    start_time: "09:00:00",
    end_time: "10:00:00",
    label: null,
    image_path: null,
    is_recurring: true,
    effective_date: null,
    expires_date: null,
    confessor_synced: false,
    ...overrides,
  });

  it("reports zero diff for identical lists", () => {
    const a = [slot({ show_id: "s1" }), slot({ show_id: "s2", day_of_week: 2 })];
    const b = [slot({ show_id: "s1" }), slot({ show_id: "s2", day_of_week: 2 })];

    expect(diffSnapshots(a, b)).toEqual({
      added: 0,
      removed: 0,
      unchanged: 2,
    });
  });

  it("counts added and removed slots", () => {
    const current = [slot({ show_id: "s1" }), slot({ show_id: "s2", day_of_week: 2 })];
    const target = [slot({ show_id: "s1" }), slot({ show_id: "s3", day_of_week: 3 })];

    expect(diffSnapshots(current, target)).toEqual({
      added: 1,
      removed: 1,
      unchanged: 1,
    });
  });

  it("treats a slot with a different start_time as different", () => {
    const current = [slot({ show_id: "s1", start_time: "09:00:00" })];
    const target = [slot({ show_id: "s1", start_time: "09:30:00" })];

    expect(diffSnapshots(current, target)).toEqual({
      added: 1,
      removed: 1,
      unchanged: 0,
    });
  });

  it("treats label-only slots as keyable", () => {
    const current = [slot({ show_id: null, label: "Special" })];
    const target = [slot({ show_id: null, label: "Special" })];

    expect(diffSnapshots(current, target).unchanged).toBe(1);
  });

  it("distinguishes recurring vs one-off slots at the same time", () => {
    const current = [slot({ show_id: "s1", is_recurring: true })];
    const target = [slot({ show_id: "s1", is_recurring: false })];

    expect(diffSnapshots(current, target).unchanged).toBe(0);
  });

  it("handles empty current → all target slots are added", () => {
    const target = [slot({ show_id: "s1" })];
    expect(diffSnapshots([], target)).toEqual({
      added: 1,
      removed: 0,
      unchanged: 0,
    });
  });

  it("handles empty target → all current slots are removed", () => {
    const current = [slot({ show_id: "s1" })];
    expect(diffSnapshots(current, [])).toEqual({
      added: 0,
      removed: 1,
      unchanged: 0,
    });
  });
});

describe("describeOperation", () => {
  it("formats Confessor import with slot count and user", () => {
    expect(
      describeOperation("confessor_import", {
        slotCount: 42,
        userName: "Alice",
      })
    ).toBe("Imported 42 slots from Confessor by Alice");
  });

  it("formats Confessor import without a user", () => {
    expect(
      describeOperation("confessor_import", { slotCount: 42, userName: null })
    ).toBe("Imported 42 slots from Confessor");
  });

  it("formats pre_revert", () => {
    expect(
      describeOperation("pre_revert", { userName: "Bob" })
    ).toBe("Auto-saved before revert by Bob");
  });

  it("formats manual_save with count", () => {
    expect(
      describeOperation("manual_save", { slotCount: 30, userName: null })
    ).toBe("Manual save (30 slots)");
  });

  it("formats bulk_revert", () => {
    expect(
      describeOperation("bulk_revert", { userName: "Alice" })
    ).toBe("Reverted to earlier snapshot by Alice");
  });
});

// Sanity: vi import isn't unused — keep the linter quiet.
void vi;
