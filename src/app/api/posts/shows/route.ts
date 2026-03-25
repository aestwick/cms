import { NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

// GET /api/posts/shows — shows the current user can post to
// For admin/editor: all shows. For hosts: only their assigned shows.
export async function GET() {
  const user = await getCmsUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = getSupabaseAdmin();

  if (user.role === "host") {
    // Get shows assigned to this host
    const { data: hostShows } = await supabase
      .from("cms_show_hosts")
      .select("show_id, cms_shows(id, title)")
      .eq("profile_id", user.id);

    const shows = (hostShows ?? [])
      .map((h) => {
        const show = Array.isArray(h.cms_shows) ? h.cms_shows[0] : h.cms_shows;
        return show ? { id: show.id, title: show.title } : null;
      })
      .filter(Boolean);

    return NextResponse.json(shows);
  }

  // Admin/editor: all active shows
  const { data, error } = await supabase
    .from("cms_shows")
    .select("id, title")
    .eq("station_id", user.station_id)
    .eq("is_active", true)
    .is("deleted_at", null)
    .order("title");

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data);
}
