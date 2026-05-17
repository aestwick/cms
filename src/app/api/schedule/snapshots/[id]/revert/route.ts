import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";
import {
  captureSnapshot,
  describeOperation,
  type ScheduleSnapshot,
  type SnapshotSlot,
} from "@/lib/schedule-snapshots";

// POST /api/schedule/snapshots/[id]/revert
// Atomically replaces all schedule slots for the station with the snapshot's
// slot_data. Captures the current state as a "pre_revert" snapshot first so
// the revert itself can be undone.
// admin only — this is destructive.
export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const user = await getCmsUser();
  if (!user || user.role !== "admin") {
    return NextResponse.json({ error: "Admin only" }, { status: 401 });
  }

  const supabase = getSupabaseAdmin();

  const { data: snapshot, error: fetchError } = await supabase
    .from("cms_schedule_snapshots")
    .select("*")
    .eq("id", id)
    .eq("station_id", user.station_id)
    .single<ScheduleSnapshot>();

  if (fetchError || !snapshot) {
    return NextResponse.json({ error: "Snapshot not found" }, { status: 404 });
  }

  // 1. Capture current state so revert is itself revertable.
  try {
    await captureSnapshot(supabase, {
      stationId: user.station_id,
      userId: user.id,
      operation: "pre_revert",
      description: describeOperation("pre_revert", {
        userName: user.display_name,
      }),
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Pre-revert snapshot failed";
    return NextResponse.json({ error: message }, { status: 500 });
  }

  // 2. Delete all current slots for the station.
  const { error: delError } = await supabase
    .from("cms_schedule_slots")
    .delete()
    .eq("station_id", user.station_id);

  if (delError) {
    return NextResponse.json({ error: delError.message }, { status: 500 });
  }

  // 3. Insert snapshot's slot_data (only if it has entries).
  const slotData = (snapshot.slot_data || []) as SnapshotSlot[];
  let inserted = 0;
  if (slotData.length > 0) {
    const rows = slotData.map((s) => ({
      station_id: user.station_id,
      show_id: s.show_id,
      day_of_week: s.day_of_week,
      start_time: s.start_time,
      end_time: s.end_time,
      label: s.label,
      image_path: s.image_path,
      is_recurring: s.is_recurring,
      effective_date: s.effective_date,
      expires_date: s.expires_date,
      confessor_synced: s.confessor_synced,
    }));

    const { data: insData, error: insError } = await supabase
      .from("cms_schedule_slots")
      .insert(rows)
      .select("id");

    if (insError) {
      return NextResponse.json({ error: insError.message }, { status: 500 });
    }
    inserted = insData?.length ?? 0;
  }

  // 4. Audit log.
  await supabase.from("cms_audit_log").insert({
    station_id: user.station_id,
    user_id: user.id,
    action: "update",
    table_name: "cms_schedule_slots",
    record_id: null,
    old_data: { reverted_to_snapshot: snapshot.id },
    new_data: { restored_count: inserted },
  });

  return NextResponse.json({
    success: true,
    restored: inserted,
    snapshot_id: snapshot.id,
  });
}
