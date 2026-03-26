import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

// GET /api/shows — list shows for the admin's station
export async function GET() {
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = getSupabaseAdmin();
  const { data, error } = await supabase
    .from("cms_shows")
    .select("id, title, slug, show_type, is_active, is_claimed, sort_order, created_at, updated_at, cms_show_hosts(name, is_primary)")
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .order("sort_order", { ascending: true })
    .order("title", { ascending: true });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data);
}

// POST /api/shows — create a new show
export async function POST(request: NextRequest) {
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const supabase = getSupabaseAdmin();

  const { data, error } = await supabase
    .from("cms_shows")
    .insert({
      station_id: user.station_id,
      title: body.title,
      slug: body.slug,
      tagline: body.tagline || null,
      description: body.description || null,
      history: body.history || null,
      show_type: body.show_type || "talk",
      program_slug: body.program_slug || null,
      logo_path: body.logo_path || null,
      banner_path: body.banner_path || null,
      contact_preference: body.contact_preference || "form",
      contact_email: body.contact_email || null,
      website_url: body.website_url || null,
      rss_url: body.rss_url || null,
      social_links: body.social_links || {},
      donation_cta_heading: body.donation_cta_heading || null,
      donation_cta_body: body.donation_cta_body || null,
      donation_cta_url: body.donation_cta_url || null,
      is_active: body.is_active ?? true,
      sort_order: body.sort_order ?? 0,
      broadcast_status: body.broadcast_status || "active",
      status_note: body.status_note || null,
      returns_at: body.returns_at || null,
      schedule_note: body.schedule_note || null,
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
    table_name: "cms_shows",
    record_id: data.id,
    new_data: data,
  });

  return NextResponse.json(data, { status: 201 });
}
