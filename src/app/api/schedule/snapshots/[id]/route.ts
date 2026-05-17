import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

// GET /api/schedule/snapshots/[id] — fetch a single snapshot with slot_data
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
    .from("cms_schedule_snapshots")
    .select("*")
    .eq("id", id)
    .eq("station_id", user.station_id)
    .single();

  if (error || !data) {
    return NextResponse.json({ error: "Snapshot not found" }, { status: 404 });
  }

  return NextResponse.json(data);
}

// DELETE /api/schedule/snapshots/[id] — remove a snapshot (admin only)
export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const user = await getCmsUser();
  if (!user || user.role !== "admin") {
    return NextResponse.json({ error: "Admin only" }, { status: 401 });
  }

  const supabase = getSupabaseAdmin();
  const { error } = await supabase
    .from("cms_schedule_snapshots")
    .delete()
    .eq("id", id)
    .eq("station_id", user.station_id);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ success: true });
}
