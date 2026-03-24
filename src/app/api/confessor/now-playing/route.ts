import { NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";

// GET /api/confessor/now-playing — proxy to Confessor for current show info
export async function GET() {
  const confessorBase = process.env.CONFESSOR_API_BASE_URL;

  if (!confessorBase) {
    return NextResponse.json(
      { error: "Confessor not configured" },
      { status: 503 }
    );
  }

  try {
    const res = await fetch(`${confessorBase}/api/now-playing`, {
      next: { revalidate: 30 },
    });

    if (!res.ok) {
      return NextResponse.json(
        { error: "Confessor unavailable" },
        { status: 502 }
      );
    }

    const confessorData = await res.json();

    // Try to match to a CMS show via program_slug
    let showSlug: string | null = null;
    if (confessorData.program_slug) {
      const supabase = getSupabaseAdmin();
      const { data: show } = await supabase
        .from("cms_shows")
        .select("slug")
        .eq("program_slug", confessorData.program_slug)
        .eq("is_active", true)
        .is("deleted_at", null)
        .single();

      if (show) {
        showSlug = show.slug;
      }
    }

    return NextResponse.json({
      show_title: confessorData.show_title || confessorData.program_name || "KPFK",
      show_slug: showSlug,
      host_name: confessorData.host_name || null,
      up_next: confessorData.up_next?.show_title || null,
    });
  } catch {
    return NextResponse.json(
      { error: "Failed to reach Confessor" },
      { status: 502 }
    );
  }
}
