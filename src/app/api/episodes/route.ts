import { getCmsUser } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { canEditShow } from "@/lib/authz";
import { NextRequest, NextResponse } from "next/server";

// GET /api/episodes — list episode metadata for a show
export async function GET(request: NextRequest) {
  const user = await getCmsUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { searchParams } = new URL(request.url);
  const showId = searchParams.get("show_id");
  const programSlug = searchParams.get("program_slug");

  if (!showId && !programSlug) {
    return NextResponse.json(
      { error: "show_id or program_slug is required" },
      { status: 400 }
    );
  }

  const supabase = getSupabaseAdmin();

  // If host, verify they have access to the requested show
  if (showId && !(await canEditShow(supabase, user, showId))) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  let query = supabase
    .from("cms_episode_metadata")
    .select("*")
    .eq("station_id", user.station_id)
    .order("air_date", { ascending: false })
    .limit(50);

  if (showId) {
    query = query.eq("show_id", showId);
  }

  if (programSlug) {
    query = query.eq("program_slug", programSlug);
  }

  const { data, error } = await query;

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data);
}

// POST /api/episodes — create or upsert episode metadata
export async function POST(request: NextRequest) {
  const user = await getCmsUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();

  if (!body.show_id || !body.program_slug || !body.air_date) {
    return NextResponse.json(
      { error: "show_id, program_slug, and air_date are required" },
      { status: 400 }
    );
  }

  const supabase = getSupabaseAdmin();

  // Verify show belongs to user's station
  const { data: show } = await supabase
    .from("cms_shows")
    .select("id, station_id")
    .eq("id", body.show_id)
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .single();

  if (!show) {
    return NextResponse.json({ error: "Show not found" }, { status: 404 });
  }

  // If host, verify they have access to this show
  if (!(await canEditShow(supabase, user, body.show_id))) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { data, error } = await supabase
    .from("cms_episode_metadata")
    .upsert(
      {
        station_id: user.station_id,
        show_id: body.show_id,
        program_slug: body.program_slug,
        air_date: body.air_date,
        title: body.title || null,
        description: body.description || null,
        transcript_url: body.transcript_url || null,
        segments: body.segments || null,
        is_published: body.is_published ?? true,
        created_by: user.id,
      },
      { onConflict: "station_id,program_slug,air_date" }
    )
    .select()
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  // Audit log
  await supabase.from("cms_audit_log").insert({
    station_id: user.station_id,
    user_id: user.id,
    action: "upsert",
    table_name: "cms_episode_metadata",
    record_id: data.id,
    new_data: data,
  });

  return NextResponse.json(data, { status: 201 });
}

// PATCH /api/episodes — update episode metadata by id
export async function PATCH(request: NextRequest) {
  const user = await getCmsUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();

  if (!body.id) {
    return NextResponse.json(
      { error: "id is required" },
      { status: 400 }
    );
  }

  const supabase = getSupabaseAdmin();

  // Fetch existing record for auth check and audit
  const { data: existing } = await supabase
    .from("cms_episode_metadata")
    .select("*")
    .eq("id", body.id)
    .eq("station_id", user.station_id)
    .single();

  if (!existing) {
    return NextResponse.json({ error: "Episode not found" }, { status: 404 });
  }

  // If host, verify they have access to this show
  if (!(await canEditShow(supabase, user, existing.show_id))) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const updateFields: Record<string, unknown> = {};
  const allowedFields = [
    "title",
    "description",
    "transcript_url",
    "segments",
    "is_published",
  ];

  const nullableFields = new Set(["title", "description", "transcript_url", "segments"]);

  for (const field of allowedFields) {
    if (field in body) {
      updateFields[field] =
        nullableFields.has(field) && body[field] === "" ? null : body[field];
    }
  }

  const { data, error } = await supabase
    .from("cms_episode_metadata")
    .update(updateFields)
    .eq("id", body.id)
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
    table_name: "cms_episode_metadata",
    record_id: body.id,
    old_data: existing,
    new_data: data,
  });

  return NextResponse.json(data);
}
