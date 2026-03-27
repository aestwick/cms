import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";
import {
  getWeeklySchedule,
  isVisibleShow,
  showStartTime,
  showEndTime,
  normalizeDayShows,
  deduplicateDayShows,
} from "@/lib/confessor";

// POST /api/schedule/confessor-import
// Replaces all recurring schedule slots with data from Confessor.
// Only matched shows (those with a cms_shows.program_slug match) get a show_id.
// Unmatched shows are imported with show_id=null and a label.
export async function POST(request: NextRequest) {
  const user = await getCmsUser();
  if (!user || user.role !== "admin") {
    return NextResponse.json({ error: "Admin only" }, { status: 401 });
  }

  const schedule = await getWeeklySchedule();
  if (!schedule) {
    return NextResponse.json(
      { error: "Could not reach Confessor" },
      { status: 502 }
    );
  }

  const supabase = getSupabaseAdmin();

  // Build slug → CMS show map
  const { data: cmsShows } = await supabase
    .from("cms_shows")
    .select("id, title, program_slug")
    .eq("station_id", user.station_id)
    .is("deleted_at", null);

  const slugToId = new Map<string, string>();
  if (cmsShows) {
    for (const s of cmsShows) {
      if (s.program_slug) slugToId.set(s.program_slug, s.id);
    }
  }

  // Build rows to insert
  const rows: {
    station_id: string;
    show_id: string | null;
    day_of_week: number;
    start_time: string;
    end_time: string;
    label: string | null;
    is_recurring: boolean;
    confessor_synced: boolean;
  }[] = [];

  for (const [dayKey, rawShows] of Object.entries(schedule)) {
    const dayNum = parseInt(dayKey, 10);
    if (isNaN(dayNum) || dayNum < 0 || dayNum > 6) continue;

    const shows = deduplicateDayShows(
      normalizeDayShows(rawShows).filter(isVisibleShow)
    );

    for (const show of shows) {
      const showId = slugToId.get(show.sh_altid) || null;

      rows.push({
        station_id: user.station_id,
        show_id: showId,
        day_of_week: dayNum,
        start_time: showStartTime(show),
        end_time: showEndTime(show),
        label: showId ? null : show.sh_name, // label as fallback for unmatched
        is_recurring: true,
        confessor_synced: true,
      });
    }
  }

  if (rows.length === 0) {
    return NextResponse.json(
      { error: "Confessor returned no visible shows" },
      { status: 422 }
    );
  }

  // Snapshot old slots for audit
  const { data: oldSlots } = await supabase
    .from("cms_schedule_slots")
    .select("id, show_id, day_of_week, start_time, end_time, label")
    .eq("station_id", user.station_id)
    .eq("is_recurring", true);

  // Delete existing recurring slots
  const { error: delError } = await supabase
    .from("cms_schedule_slots")
    .delete()
    .eq("station_id", user.station_id)
    .eq("is_recurring", true);

  if (delError) {
    return NextResponse.json({ error: delError.message }, { status: 500 });
  }

  // Insert new slots
  const { data: inserted, error: insError } = await supabase
    .from("cms_schedule_slots")
    .insert(rows)
    .select("id");

  if (insError) {
    return NextResponse.json({ error: insError.message }, { status: 500 });
  }

  // Audit log
  await supabase.from("cms_audit_log").insert({
    station_id: user.station_id,
    user_id: user.id,
    action: "update",
    table_name: "cms_schedule_slots",
    record_id: null,
    old_data: { slots: oldSlots, count: oldSlots?.length || 0 },
    new_data: { count: inserted?.length || 0 },
  });

  return NextResponse.json({
    success: true,
    imported: inserted?.length || 0,
    deleted: oldSlots?.length || 0,
  });
}
