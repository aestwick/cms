import { getCmsUser } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

// PATCH /api/users/[id] — update role or display_name
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const user = await getCmsUser();
  if (!user || user.role !== "admin") {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const supabase = getSupabaseAdmin();

  // Fetch old data for audit
  const { data: oldData } = await supabase
    .from("cms_profiles")
    .select("*")
    .eq("id", id)
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .single();

  if (!oldData) {
    return NextResponse.json({ error: "User not found" }, { status: 404 });
  }

  const updateFields: Record<string, unknown> = {};
  const allowedFields = ["role", "display_name"];

  for (const field of allowedFields) {
    if (field in body) {
      updateFields[field] = body[field];
    }
  }

  // Validate role if provided
  if (updateFields.role && !["admin", "editor", "host"].includes(updateFields.role as string)) {
    return NextResponse.json({ error: "Invalid role" }, { status: 400 });
  }

  if (Object.keys(updateFields).length === 0) {
    return NextResponse.json({ error: "No valid fields to update" }, { status: 400 });
  }

  const { data, error } = await supabase
    .from("cms_profiles")
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
    table_name: "cms_profiles",
    record_id: id,
    old_data: oldData,
    new_data: data,
  });

  return NextResponse.json(data);
}

// DELETE /api/users/[id] — soft delete (set deleted_at)
export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const user = await getCmsUser();
  if (!user || user.role !== "admin") {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  // Prevent self-deletion
  if (id === user.id) {
    return NextResponse.json({ error: "Cannot delete your own account" }, { status: 400 });
  }

  const supabase = getSupabaseAdmin();
  const { error } = await supabase
    .from("cms_profiles")
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
    table_name: "cms_profiles",
    record_id: id,
  });

  return NextResponse.json({ success: true });
}
