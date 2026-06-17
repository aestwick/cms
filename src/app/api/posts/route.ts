import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";
import { canEditShow, editableShowIds } from "@/lib/authz";
import { normalizeBlocks } from "@/lib/blocks";

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
    .select("id, title, slug, status, published_at, is_featured, show_id, category_id, author_id, created_at, updated_at, cms_shows(id, title)")
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .order("created_at", { ascending: false });

  // Hosts can only see their own show's posts
  const allowedShowIds = await editableShowIds(supabase, user);
  if (allowedShowIds !== null) {
    if (allowedShowIds.length === 0) {
      return NextResponse.json([]);
    }
    query = query.in("show_id", allowedShowIds);
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

  // Hosts can only create posts scoped to a show they're linked to.
  if (user.role === "host" && !body.show_id) {
    return NextResponse.json({ error: "Hosts must scope posts to a show" }, { status: 400 });
  }
  if (!(await canEditShow(supabase, user, body.show_id))) {
    return NextResponse.json({ error: "You do not have access to this show" }, { status: 403 });
  }

  const { data, error } = await supabase
    .from("cms_posts")
    .insert({
      station_id: user.station_id,
      author_id: user.id,
      show_id: body.show_id || null,
      category_id: body.category_id || null,
      title: body.title,
      slug: body.slug,
      body: body.body || "",
      body_blocks: normalizeBlocks(body.body_blocks),
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
