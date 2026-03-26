import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

// GET /api/shows/[id]/hosts
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
    .from("cms_show_hosts")
    .select("*")
    .eq("show_id", id)
    .order("sort_order", { ascending: true });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data);
}

// POST /api/shows/[id]/hosts — add a host
export async function POST(
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

  // Verify show belongs to station
  const { data: show } = await supabase
    .from("cms_shows")
    .select("id")
    .eq("id", id)
    .eq("station_id", user.station_id)
    .single();

  if (!show) {
    return NextResponse.json({ error: "Show not found" }, { status: 404 });
  }

  const { data, error } = await supabase
    .from("cms_show_hosts")
    .insert({
      show_id: id,
      name: body.name,
      bio: body.bio || null,
      photo_path: body.photo_path || null,
      email: body.email || null,
      role: body.role || "host",
      sort_order: body.sort_order ?? 0,
    })
    .select()
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data, { status: 201 });
}

// PUT /api/shows/[id]/hosts — batch update hosts (replace all)
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const hosts: Array<{
    id?: string;
    name: string;
    bio?: string;
    photo_path?: string;
    email?: string;
    role?: string;
    sort_order?: number;
  }> = body.hosts;

  const supabase = getSupabaseAdmin();

  // Delete existing hosts for this show
  await supabase.from("cms_show_hosts").delete().eq("show_id", id);

  // Insert new hosts
  if (hosts.length > 0) {
    const { data, error } = await supabase
      .from("cms_show_hosts")
      .insert(
        hosts.map((h, i) => ({
          show_id: id,
          name: h.name,
          bio: h.bio || null,
          photo_path: h.photo_path || null,
          email: h.email || null,
          role: h.role || "host",
          sort_order: h.sort_order ?? i,
        }))
      )
      .select();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json(data);
  }

  return NextResponse.json([]);
}
