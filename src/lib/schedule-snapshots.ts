import type { SupabaseClient } from "@supabase/supabase-js";

export type SnapshotOperation =
  | "confessor_import"
  | "bulk_revert"
  | "manual_save"
  | "pre_revert";

export interface SnapshotSlot {
  show_id: string | null;
  day_of_week: number;
  start_time: string;
  end_time: string;
  label: string | null;
  image_path: string | null;
  is_recurring: boolean;
  effective_date: string | null;
  expires_date: string | null;
  confessor_synced: boolean;
}

export interface ScheduleSnapshot {
  id: string;
  station_id: string;
  operation: SnapshotOperation;
  description: string;
  slot_data: SnapshotSlot[];
  slot_count: number;
  created_at: string;
  created_by: string | null;
}

// Snapshot summary — list view payload without slot_data blob.
export type ScheduleSnapshotSummary = Omit<ScheduleSnapshot, "slot_data">;

// How many snapshots to keep per station. Older snapshots are pruned.
export const SNAPSHOT_RETENTION = 30;

const SLOT_COLUMNS = [
  "show_id",
  "day_of_week",
  "start_time",
  "end_time",
  "label",
  "image_path",
  "is_recurring",
  "effective_date",
  "expires_date",
  "confessor_synced",
] as const;

/**
 * Capture the current state of all schedule slots for a station.
 * Returns the new snapshot's id, or throws on error.
 */
export async function captureSnapshot(
  supabase: SupabaseClient,
  params: {
    stationId: string;
    userId: string | null;
    operation: SnapshotOperation;
    description: string;
  }
): Promise<{ id: string; slotCount: number }> {
  const { data: slots, error: fetchError } = await supabase
    .from("cms_schedule_slots")
    .select(SLOT_COLUMNS.join(","))
    .eq("station_id", params.stationId);

  if (fetchError) {
    throw new Error(`Failed to read slots for snapshot: ${fetchError.message}`);
  }

  const slotData = (slots || []) as unknown as SnapshotSlot[];

  const { data: inserted, error: insertError } = await supabase
    .from("cms_schedule_snapshots")
    .insert({
      station_id: params.stationId,
      operation: params.operation,
      description: params.description,
      slot_data: slotData,
      slot_count: slotData.length,
      created_by: params.userId,
    })
    .select("id")
    .single();

  if (insertError || !inserted) {
    throw new Error(
      `Failed to write snapshot: ${insertError?.message || "unknown error"}`
    );
  }

  await pruneSnapshots(supabase, params.stationId);

  return { id: inserted.id, slotCount: slotData.length };
}

/**
 * Delete snapshots older than the retention window for a station.
 * Keeps the most recent SNAPSHOT_RETENTION snapshots.
 */
export async function pruneSnapshots(
  supabase: SupabaseClient,
  stationId: string,
  keep: number = SNAPSHOT_RETENTION
): Promise<number> {
  const { data: keepIds } = await supabase
    .from("cms_schedule_snapshots")
    .select("id")
    .eq("station_id", stationId)
    .order("created_at", { ascending: false })
    .limit(keep);

  if (!keepIds || keepIds.length < keep) return 0;

  const ids = keepIds.map((r) => r.id);
  const { count, error } = await supabase
    .from("cms_schedule_snapshots")
    .delete({ count: "exact" })
    .eq("station_id", stationId)
    .not("id", "in", `(${ids.join(",")})`);

  if (error) {
    throw new Error(`Snapshot prune failed: ${error.message}`);
  }
  return count || 0;
}

/**
 * Compare two slot arrays and return a count summary.
 * Used in revert confirmation UI ("This will change 42 slots").
 */
export function diffSnapshots(
  current: SnapshotSlot[],
  target: SnapshotSlot[]
): { added: number; removed: number; unchanged: number } {
  const key = (s: SnapshotSlot) =>
    `${s.day_of_week}|${s.start_time}|${s.end_time}|${s.show_id || ""}|${s.label || ""}|${s.is_recurring}|${s.effective_date || ""}`;

  const currentKeys = new Set(current.map(key));
  const targetKeys = new Set(target.map(key));

  let unchanged = 0;
  for (const k of currentKeys) {
    if (targetKeys.has(k)) unchanged++;
  }

  return {
    added: target.length - unchanged,
    removed: current.length - unchanged,
    unchanged,
  };
}

/**
 * Build a human-readable description for a snapshot operation.
 */
export function describeOperation(
  operation: SnapshotOperation,
  details: { slotCount?: number; previousCount?: number; userName?: string | null }
): string {
  const who = details.userName ? ` by ${details.userName}` : "";
  switch (operation) {
    case "confessor_import":
      return `Imported ${details.slotCount ?? 0} slots from Confessor${who}`;
    case "bulk_revert":
      return `Reverted to earlier snapshot${who}`;
    case "manual_save":
      return `Manual save (${details.slotCount ?? 0} slots)${who}`;
    case "pre_revert":
      return `Auto-saved before revert${who}`;
  }
}
