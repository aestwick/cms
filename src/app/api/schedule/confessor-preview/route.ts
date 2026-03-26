import { NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";
import {
  getWeeklySchedule,
  isVisibleShow,
  confessorTimeToSlotTime,
  parseDayString,
  type ConfessorShow,
} from "@/lib/confessor";

export interface PreviewSlot {
  confessor_altid: string;
  show_name: string;
  host_name: string;
  day_of_week: number;
  start_time: string; // HH:MM
  end_time: string; // HH:MM
  category: string;
  matched_show_id: string | null; // CMS show UUID if matched via program_slug
  matched_show_title: string | null;
}

export interface ConfessorPreviewResponse {
  incoming: PreviewSlot[];
  current_count: number;
  incoming_count: number;
  unmatched_shows: { altid: string; name: string }[];
}

// GET /api/schedule/confessor-preview
// Fetches schedule from Confessor and diffs against current CMS schedule.
export async function GET() {
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const schedule = await getWeeklySchedule();
  if (!schedule) {
    return NextResponse.json(
      { error: "Could not reach Confessor. Is CONFESSOR_API_URL configured?" },
      { status: 502 }
    );
  }

  // Flatten Confessor schedule into per-day-slot entries
  // The getshows endpoint returns an object keyed by day number
  const allShows: { show: ConfessorShow; dayOfWeek: number }[] = [];

  for (const [dayKey, shows] of Object.entries(schedule)) {
    const dayNum = parseInt(dayKey, 10);
    if (isNaN(dayNum) || dayNum < 0 || dayNum > 6) continue;
    if (!Array.isArray(shows)) continue;

    for (const show of shows) {
      if (!isVisibleShow(show)) continue;
      allShows.push({ show, dayOfWeek: dayNum });
    }
  }

  // If getshows returned shows with sh_days but without per-day breakdown,
  // we might need to expand them. The getshows endpoint with before/after
  // typically returns already-expanded per-day entries, but handle both:
  const incoming: PreviewSlot[] = [];
  const seenAltids = new Set<string>();

  for (const { show, dayOfWeek } of allShows) {
    incoming.push({
      confessor_altid: show.sh_altid,
      show_name: show.sh_name,
      host_name: show.sh_djname || "",
      day_of_week: dayOfWeek,
      start_time: confessorTimeToSlotTime(show.sh_stime),
      end_time: confessorTimeToSlotTime(show.sh_ends),
      category: show.ca_name || "",
      matched_show_id: null,
      matched_show_title: null,
    });
    seenAltids.add(show.sh_altid);
  }

  // Match incoming shows to CMS shows via program_slug
  const supabase = getSupabaseAdmin();
  const { data: cmsShows } = await supabase
    .from("cms_shows")
    .select("id, title, program_slug")
    .eq("station_id", user.station_id)
    .is("deleted_at", null);

  const slugToShow = new Map<string, { id: string; title: string }>();
  if (cmsShows) {
    for (const s of cmsShows) {
      if (s.program_slug) {
        slugToShow.set(s.program_slug, { id: s.id, title: s.title });
      }
    }
  }

  const unmatched: { altid: string; name: string }[] = [];
  const unmatchedSet = new Set<string>();

  for (const slot of incoming) {
    const match = slugToShow.get(slot.confessor_altid);
    if (match) {
      slot.matched_show_id = match.id;
      slot.matched_show_title = match.title;
    } else if (!unmatchedSet.has(slot.confessor_altid)) {
      unmatchedSet.add(slot.confessor_altid);
      unmatched.push({ altid: slot.confessor_altid, name: slot.show_name });
    }
  }

  // Count current recurring slots
  const { count } = await supabase
    .from("cms_schedule_slots")
    .select("id", { count: "exact", head: true })
    .eq("station_id", user.station_id)
    .eq("is_recurring", true);

  return NextResponse.json({
    incoming,
    current_count: count || 0,
    incoming_count: incoming.length,
    unmatched_shows: unmatched,
  } satisfies ConfessorPreviewResponse);
}
