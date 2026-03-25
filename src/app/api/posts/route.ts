import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

// GET /api/posts — list posts for the admin's station
export async function GET(request: NextRequest) {
  const user = await getCmsUser();
  if (!user || !["admin", "editor", "host"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = getSupabaseAdmin();
  const showId = request.nextUrl.searchParams.get("show_id");

  let query = supabase
    .from("cms_posts")
    .select("id, title, slug, status, published_at, is_featured, show_id, author_id, created_at, updated_at, cms_shows(id, title)")
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .order("created_at", { ascending: false });

  // Hosts can only see their own show's posts
  if (user.role === "host") {
    const { data: hostShows } = await supabase
      .from("cms_show_hosts")
      .select("show_id")
      .eq("profile_id", user.id);

    const showIds = (hostShows ?? []).map((h) => h.show_id);
    if (showIds.length === 0) {
      return NextResponse.json([]);
    }
    query = query.in("show_id", showIds);
  } else if (showId) {
    query = query.eq("show_id", showId);
  }

  const { data, error } = await query;

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data);
}

// POST /api/posts — create a new blog post
export async function POST(request: NextRequest) {
  const user = await getCmsUser();
  if (!user || !["admin", "editor", "host"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const supabase = getSupabaseAdmin();

  // Hosts can only create posts scoped to their shows
  if (user.role === "host") {
    if (!body.show_id) {
      return NextResponse.json({ error: "Hosts must scope posts to a show" }, { status: 400 });
    }
    const { data: hostLink } = await supabase
      .from("cms_show_hosts")
      .select("id")
      .eq("profile_id", user.id)
      .eq("show_id", body.show_id)
      .single();

    if (!hostLink) {
      return NextResponse.json({ error: "You do not have access to this show" }, { status: 403 });
    }
  }

  const { data, error } = await supabase
    .from("cms_posts")
    .insert({
      station_id: user.station_id,
      author_id: user.id,
      show_id: body.show_id || null,
      title: body.title,
      slug: body.slug,
      body: body.body || "",
      excerpt: body.excerpt || null,
      featured_image_path: body.featured_image_path || null,
      status: body.status || "draft",
      published_at: body.status === "published" ? new Date().toISOString() : null,
      is_featured: body.is_featured ?? false,
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
    table_name: "cms_posts",
    record_id: data.id,
    new_data: data,
  });

  return NextResponse.json(data, { status: 201 });
}
