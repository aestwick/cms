import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

// GET /api/pages — list pages for the admin's station
export async function GET() {
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = getSupabaseAdmin();
  const { data, error } = await supabase
    .from("cms_pages")
    .select("id, title, slug, parent_id, sort_order, is_published, created_at, updated_at")
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .order("sort_order", { ascending: true })
    .order("title", { ascending: true });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data);
}

// POST /api/pages — create a new page
export async function POST(request: NextRequest) {
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const supabase = getSupabaseAdmin();

  const { data, error } = await supabase
    .from("cms_pages")
    .insert({
      station_id: user.station_id,
      parent_id: body.parent_id || null,
      title: body.title,
      slug: body.slug,
      body: body.body || "",
      meta_title: body.meta_title || null,
      meta_description: body.meta_description || null,
      sort_order: body.sort_order ?? 0,
      is_published: body.is_published ?? true,
    })
    .select()
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  // Audit log
  await supabase.from("cms_audit_log").insert({
    station_id: user.station_id,
    user_id: user.id,
    action: "create",
    table_name: "cms_pages",
    record_id: data.id,
    new_data: data,
  });

  return NextResponse.json(data, { status: 201 });
}
