import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

// GET /api/shows/[id] — get a single show with hosts
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
    .from("cms_shows")
    .select("*, cms_show_hosts(*)")
    .eq("id", id)
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .single();

  if (error || !data) {
    return NextResponse.json({ error: "Show not found" }, { status: 404 });
  }

  return NextResponse.json(data);
}

// PATCH /api/shows/[id] — update a show
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
    .from("cms_shows")
    .select("*")
    .eq("id", id)
    .eq("station_id", user.station_id)
    .single();

  if (!oldData) {
    return NextResponse.json({ error: "Show not found" }, { status: 404 });
  }

  const updateFields: Record<string, unknown> = {};
  const allowedFields = [
    "title", "slug", "tagline", "description", "history", "show_type",
    "program_slug", "logo_path", "banner_path", "contact_preference",
    "contact_email", "website_url", "rss_url", "social_links",
    "is_active", "sort_order",
  ];

  for (const field of allowedFields) {
    if (field in body) {
      updateFields[field] = body[field];
    }
  }

  const { data, error } = await supabase
    .from("cms_shows")
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
    table_name: "cms_shows",
    record_id: id,
    old_data: oldData,
    new_data: data,
  });

  return NextResponse.json(data);
}

// DELETE /api/shows/[id] — soft delete
export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const user = await getCmsUser();
  if (!user || user.role !== "admin") {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = getSupabaseAdmin();
  const { error } = await supabase
    .from("cms_shows")
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
    table_name: "cms_shows",
    record_id: id,
  });

  return NextResponse.json({ success: true });
}
