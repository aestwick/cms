import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

// GET /api/sponsorship — list placements with their creatives
export async function GET() {
  const user = await getCmsUser();
  if (!user || user.role !== "admin") {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = getSupabaseAdmin();

  const { data: placements, error: pError } = await supabase
    .from("cms_sponsorship_placements")
    .select("*")
    .eq("station_id", user.station_id)
    .order("name", { ascending: true });

  if (pError) {
    return NextResponse.json({ error: pError.message }, { status: 500 });
  }

  const { data: creatives, error: cError } = await supabase
    .from("cms_sponsorship_creatives")
    .select("*")
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .order("created_at", { ascending: false });

  if (cError) {
    return NextResponse.json({ error: cError.message }, { status: 500 });
  }

  // Group creatives by placement
  const creativesByPlacement: Record<string, typeof creatives> = {};
  for (const c of creatives ?? []) {
    if (!creativesByPlacement[c.placement_id]) {
      creativesByPlacement[c.placement_id] = [];
    }
    creativesByPlacement[c.placement_id]!.push(c);
  }

  const result = (placements ?? []).map((p) => ({
    ...p,
    creatives: creativesByPlacement[p.id] ?? [],
  }));

  return NextResponse.json(result);
}

// POST /api/sponsorship — create a new creative
export async function POST(request: NextRequest) {
  const user = await getCmsUser();
  if (!user || user.role !== "admin") {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const supabase = getSupabaseAdmin();

  const { data, error } = await supabase
    .from("cms_sponsorship_creatives")
    .insert({
      station_id: user.station_id,
      placement_id: body.placement_id,
      title: body.title,
      creative_type: body.creative_type || "image",
      image_path: body.image_path || null,
      html_content: body.html_content || null,
      click_url: body.click_url || null,
      alt_text: body.alt_text || null,
      weight: body.weight ?? 1,
      is_pinned: body.is_pinned ?? false,
      pin_position: body.pin_position ?? null,
      starts_at: body.starts_at || null,
      ends_at: body.ends_at || null,
      is_active: body.is_active ?? true,
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
    table_name: "cms_sponsorship_creatives",
    record_id: data.id,
    new_data: data,
  });

  return NextResponse.json(data, { status: 201 });
}
