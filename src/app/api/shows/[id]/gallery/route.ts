import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

// GET /api/shows/[id]/gallery
export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = getSupabaseAdmin();
  const { data, error } = await supabase
    .from("cms_show_gallery")
    .select("*")
    .eq("show_id", id)
    .order("sort_order", { ascending: true });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data);
}

// PUT /api/shows/[id]/gallery — batch update gallery (replace all)
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const photos: Array<{
    id?: string;
    image_path: string;
    alt_text?: string;
    caption?: string;
    sort_order?: number;
  }> = body.photos;

  const supabase = getSupabaseAdmin();

  // Verify show belongs to station
  const { data: show } = await supabase
    .from("cms_shows")
    .select("id")
    .eq("id", id)
    .eq("station_id", user.station_id)
    .single();

  if (!show) {
    return NextResponse.json({ error: "Show not found" }, { status: 404 });
  }

  // Delete existing gallery for this show
  await supabase.from("cms_show_gallery").delete().eq("show_id", id);

  // Insert new photos
  if (photos.length > 0) {
    const { data, error } = await supabase
      .from("cms_show_gallery")
      .insert(
        photos.map((p, i) => ({
          show_id: id,
          image_path: p.image_path,
          alt_text: p.alt_text || null,
          caption: p.caption || null,
          sort_order: p.sort_order ?? i,
        }))
      )
      .select();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json(data);
  }

  return NextResponse.json([]);
}
