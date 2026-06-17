import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

// GET /api/posts/[id] — get a single post
export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const user = await getCmsUser();
  if (!user || !["admin", "editor", "host"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = getSupabaseAdmin();
  const { data, error } = await supabase
    .from("cms_posts")
    .select("*, cms_shows(id, title, slug)")
    .eq("id", id)
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .single();

  if (error || !data) {
    return NextResponse.json({ error: "Post not found" }, { status: 404 });
  }

  // Hosts can only view their own show's posts (not station-wide posts)
  if (user.role === "host") {
    if (!data.show_id) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 403 });
    }
    const { data: hostLink } = await supabase
      .from("cms_show_hosts")
      .select("id")
      .eq("profile_id", user.id)
      .eq("show_id", data.show_id)
      .single();

    if (!hostLink) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 403 });
    }
  }

  return NextResponse.json(data);
}

// PATCH /api/posts/[id] — update a post
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const user = await getCmsUser();
  if (!user || !["admin", "editor", "host"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const supabase = getSupabaseAdmin();

  // Fetch old data for audit
  const { data: oldData } = await supabase
    .from("cms_posts")
    .select("*")
    .eq("id", id)
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .single();

  if (!oldData) {
    return NextResponse.json({ error: "Post not found" }, { status: 404 });
  }

  // Hosts can only edit their own show's posts (not station-wide posts)
  if (user.role === "host") {
    if (!oldData.show_id) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 403 });
    }
    const { data: hostLink } = await supabase
      .from("cms_show_hosts")
      .select("id")
      .eq("profile_id", user.id)
      .eq("show_id", oldData.show_id)
      .single();

    if (!hostLink) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 403 });
    }
  }

  const updateFields: Record<string, unknown> = {};
  const allowedFields = [
    "title", "slug", "body", "excerpt", "featured_image_path",
    "status", "show_id", "category_id", "is_featured",
  ];

  for (const field of allowedFields) {
    if (field in body) {
      updateFields[field] = body[field];
    }
  }

  // Set published_at when publishing for the first time
  if (body.status === "published" && oldData.status !== "published") {
    updateFields.published_at = new Date().toISOString();
  }

  const { data, error } = await supabase
    .from("cms_posts")
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
    table_name: "cms_posts",
    record_id: id,
    old_data: oldData,
    new_data: data,
  });

  return NextResponse.json(data);
}

// DELETE /api/posts/[id] — soft delete
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
    .from("cms_posts")
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
    table_name: "cms_posts",
    record_id: id,
  });

  return NextResponse.json({ success: true });
}
