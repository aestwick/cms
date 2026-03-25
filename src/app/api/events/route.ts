import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

// GET /api/events — list events for the admin's station
export async function GET() {
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = getSupabaseAdmin();
  const { data, error } = await supabase
    .from("cms_events")
    .select(
      "id, title, slug, category, venue_name, starts_at, ends_at, is_all_day, is_highlighted, created_at, updated_at"
    )
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .order("starts_at", { ascending: false });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data);
}

// POST /api/events — create a new event
export async function POST(request: NextRequest) {
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const supabase = getSupabaseAdmin();

  const { data, error } = await supabase
    .from("cms_events")
    .insert({
      station_id: user.station_id,
      title: body.title,
      slug: body.slug,
      description: body.description || null,
      category: body.category || "community",
      venue_name: body.venue_name || null,
      venue_address: body.venue_address || null,
      event_url: body.event_url || null,
      image_path: body.image_path || null,
      price_text: body.price_text || null,
      starts_at: body.starts_at,
      ends_at: body.ends_at || null,
      is_all_day: body.is_all_day ?? false,
      is_highlighted: body.is_highlighted ?? false,
      created_by: user.id,
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
    table_name: "cms_events",
    record_id: data.id,
    new_data: data,
  });

  return NextResponse.json(data, { status: 201 });
}
