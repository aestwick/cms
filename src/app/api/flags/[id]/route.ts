import { getCmsUser } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

// PATCH /api/flags/[id] — update flag status
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
  const { status } = body;

  if (!status || !["open", "resolved", "dismissed"].includes(status)) {
    return NextResponse.json(
      { error: "Invalid status. Must be open, resolved, or dismissed." },
      { status: 400 }
    );
  }

  const supabase = getSupabaseAdmin();

  // Build update payload
  const updateFields: Record<string, unknown> = { status };

  if (status === "resolved" || status === "dismissed") {
    updateFields.resolved_by = user.id;
    updateFields.resolved_at = new Date().toISOString();
  } else {
    // Re-opening: clear resolution fields
    updateFields.resolved_by = null;
    updateFields.resolved_at = null;
  }

  const { data, error } = await supabase
    .from("cms_flags")
    .update(updateFields)
    .eq("id", id)
    .eq("station_id", user.station_id)
    .select()
    .single();

  if (error || !data) {
    return NextResponse.json(
      { error: error?.message || "Flag not found" },
      { status: error ? 500 : 404 }
    );
  }

  // Audit log
  await supabase.from("cms_audit_log").insert({
    station_id: user.station_id,
    user_id: user.id,
    action: "update",
    table_name: "cms_flags",
    record_id: id,
    old_data: null,
    new_data: data,
  });

  return NextResponse.json(data);
}
