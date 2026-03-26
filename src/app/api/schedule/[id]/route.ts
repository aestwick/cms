import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

// PATCH /api/schedule/[id] — update a schedule slot
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

  const { data: oldData } = await supabase
    .from("cms_schedule_slots")
    .select("*")
    .eq("id", id)
    .eq("station_id", user.station_id)
    .single();

  if (!oldData) {
    return NextResponse.json({ error: "Slot not found" }, { status: 404 });
  }

  const updateFields: Record<string, unknown> = {};
  const allowedFields = [
    "show_id", "day_of_week", "start_time", "end_time",
    "label", "image_path", "is_recurring", "effective_date", "expires_date",
  ];

  for (const field of allowedFields) {
    if (field in body) {
      updateFields[field] = body[field];
    }
  }

  const { data, error } = await supabase
    .from("cms_schedule_slots")
    .update(updateFields)
    .eq("id", id)
    .eq("station_id", user.station_id)
    .select("*, cms_shows(id, title, slug, cms_show_hosts(name))")
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  await supabase.from("cms_audit_log").insert({
    station_id: user.station_id,
    user_id: user.id,
    action: "update",
    table_name: "cms_schedule_slots",
    record_id: id,
    old_data: oldData,
    new_data: data,
  });

  return NextResponse.json(data);
}

// DELETE /api/schedule/[id] — delete a schedule slot
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
    .from("cms_schedule_slots")
    .delete()
    .eq("id", id)
    .eq("station_id", user.station_id);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  await supabase.from("cms_audit_log").insert({
    station_id: user.station_id,
    user_id: user.id,
    action: "delete",
    table_name: "cms_schedule_slots",
    record_id: id,
  });

  return NextResponse.json({ success: true });
}
