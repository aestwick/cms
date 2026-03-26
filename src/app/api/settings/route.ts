import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

// GET /api/settings — fetch station settings (admin only)
export async function GET() {
  const user = await getCmsUser();
  if (!user || user.role !== "admin") {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = getSupabaseAdmin();
  const { data, error } = await supabase
    .from("cms_stations")
    .select("*")
    .eq("id", user.station_id)
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data);
}

// PATCH /api/settings — update station settings (admin only)
export async function PATCH(request: NextRequest) {
  const user = await getCmsUser();
  if (!user || user.role !== "admin") {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const supabase = getSupabaseAdmin();

  // Build the update object from allowed fields
  const update: Record<string, unknown> = {};

  if (body.name !== undefined) update.name = body.name;
  if (body.tagline !== undefined) update.tagline = body.tagline;
  if (body.stream_url !== undefined) update.stream_url = body.stream_url;
  if (body.beacon_api_url !== undefined) update.beacon_api_url = body.beacon_api_url;
  if (body.confessor_api_url !== undefined) update.confessor_api_url = body.confessor_api_url;
  if (body.analytics_site_id !== undefined) update.analytics_site_id = body.analytics_site_id;
  if (body.settings !== undefined) update.settings = body.settings;

  if (Object.keys(update).length === 0) {
    return NextResponse.json({ error: "No fields to update" }, { status: 400 });
  }

  const { data, error } = await supabase
    .from("cms_stations")
    .update(update)
    .eq("id", user.station_id)
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
    table_name: "cms_stations",
    record_id: data.id,
    new_data: update,
  });

  return NextResponse.json(data);
}
