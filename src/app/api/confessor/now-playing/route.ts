import { NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getNowAiring, resolveAltid } from "@/lib/confessor";

// GET /api/confessor/now-playing — current show + listener count from Confessor.
// Backed by Confessor's `req=nowary` endpoint (see src/lib/confessor.ts).
export async function GET() {
  const now = await getNowAiring();

  if (!now || !now.current) {
    // Confessor unreachable or nothing airing — widget hides itself.
    return NextResponse.json({ error: "Confessor unavailable" }, { status: 502 });
  }

  // Match the airing show to a CMS show via program_slug (== Confessor sh_altid).
  let showSlug: string | null = null;
  const altid = resolveAltid(now.current.sh_altid);
  if (altid) {
    const supabase = getSupabaseAdmin();
    const { data: show } = await supabase
      .from("cms_shows")
      .select("slug")
      .eq("program_slug", altid)
      .eq("is_active", true)
      .is("deleted_at", null)
      .single();

    if (show) showSlug = show.slug;
  }

  return NextResponse.json({
    show_title: now.current.sh_name || "KPFK",
    show_slug: showSlug,
    host_name: now.current.sh_djname || null,
    up_next: now.next?.sh_name || null,
    listeners: now.listeners,
  });
}
