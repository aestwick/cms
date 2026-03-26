import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

// GET /api/schedule — return weekly schedule grid (public)
export async function GET() {
  const supabase = getSupabaseAdmin();

  const { data, error } = await supabase
    .from("cms_schedule_slots")
    .select("id, show_id, day_of_week, start_time, end_time, label, is_recurring, effective_date, expires_date, cms_shows(id, title, slug, cms_show_hosts(name, is_primary))")
    .eq("is_recurring", true)
    .order("day_of_week", { ascending: true })
    .order("start_time", { ascending: true });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data);
}

// POST /api/schedule — create a new schedule slot (admin/editor only)
export async function POST(request: NextRequest) {
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const supabase = getSupabaseAdmin();

  const { data, error } = await supabase
    .from("cms_schedule_slots")
    .insert({
      station_id: user.station_id,
      show_id: body.show_id || null,
      day_of_week: body.day_of_week,
      start_time: body.start_time,
      end_time: body.end_time,
      label: body.label || null,
      is_recurring: body.is_recurring ?? true,
      effective_date: body.effective_date || null,
      expires_date: body.expires_date || null,
    })
    .select("*, cms_shows(id, title, slug, cms_show_hosts(name, is_primary))")
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  await supabase.from("cms_audit_log").insert({
    station_id: user.station_id,
    user_id: user.id,
    action: "create",
    table_name: "cms_schedule_slots",
    record_id: data.id,
    new_data: data,
  });

  return NextResponse.json(data, { status: 201 });
}
