import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

// GET /api/pages/[id] — get a single page
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
    .from("cms_pages")
    .select("*")
    .eq("id", id)
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .single();

  if (error || !data) {
    return NextResponse.json({ error: "Page not found" }, { status: 404 });
  }

  return NextResponse.json(data);
}

// PATCH /api/pages/[id] — update a page
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const supabase = getSupabaseAdmin();

  // Fetch old data for audit
  const { data: oldData } = await supabase
    .from("cms_pages")
    .select("*")
    .eq("id", id)
    .eq("station_id", user.station_id)
    .single();

  if (!oldData) {
    return NextResponse.json({ error: "Page not found" }, { status: 404 });
  }

  const updateFields: Record<string, unknown> = {};
  const allowedFields = [
    "title", "slug", "body", "parent_id", "meta_title",
    "meta_description", "sort_order", "is_published",
  ];

  for (const field of allowedFields) {
    if (field in body) {
      updateFields[field] = body[field];
    }
  }

  const { data, error } = await supabase
    .from("cms_pages")
    .update(updateFields)
    .eq("id", id)
    .eq("station_id", user.station_id)
    .select()
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  // Audit log
  await supabase.from("cms_audit_log").insert({
    station_id: user.station_id,
    user_id: user.id,
    action: "update",
    table_name: "cms_pages",
    record_id: id,
    old_data: oldData,
    new_data: data,
  });

  return NextResponse.json(data);
}

// DELETE /api/pages/[id] — soft delete
export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = getSupabaseAdmin();
  const { error } = await supabase
    .from("cms_pages")
    .update({ deleted_at: new Date().toISOString() })
    .eq("id", id)
    .eq("station_id", user.station_id);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  // Audit log
  await supabase.from("cms_audit_log").insert({
    station_id: user.station_id,
    user_id: user.id,
    action: "delete",
    table_name: "cms_pages",
    record_id: id,
  });

  return NextResponse.json({ success: true });
}
