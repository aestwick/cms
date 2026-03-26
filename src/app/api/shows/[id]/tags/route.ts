import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

// GET /api/shows/[id]/tags — get tags for a show
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
    .from("cms_show_tags")
    .select("tag_id, cms_tags(id, name, slug, category)")
    .eq("show_id", id);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data);
}

// PUT /api/shows/[id]/tags — replace all tags for a show
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { tag_ids } = await request.json();
  const supabase = getSupabaseAdmin();

  // Delete existing
  await supabase.from("cms_show_tags").delete().eq("show_id", id);

  // Insert new
  if (tag_ids && tag_ids.length > 0) {
    const rows = tag_ids.map((tag_id: string) => ({ show_id: id, tag_id }));
    const { error } = await supabase.from("cms_show_tags").insert(rows);
    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }
  }

  return NextResponse.json({ success: true });
}
