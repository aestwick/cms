import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

function slugify(input: string): string {
  return input
    ?.toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

// GET /api/categories — list the station's coverage-area tree
export async function GET() {
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = getSupabaseAdmin();
  const { data, error } = await supabase
    .from("cms_categories")
    .select("*")
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .order("sort_order")
    .order("name");

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data);
}

// POST /api/categories — create a category
export async function POST(request: NextRequest) {
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const slug = body.slug ? slugify(body.slug) : slugify(body.name);

  if (!body.name || !slug) {
    return NextResponse.json({ error: "Name is required" }, { status: 400 });
  }

  const supabase = getSupabaseAdmin();
  const { data, error } = await supabase
    .from("cms_categories")
    .insert({
      station_id: user.station_id,
      parent_id: body.parent_id || null,
      name: body.name,
      slug,
      description: body.description || null,
      color: body.color || null,
      show_in_nav: body.show_in_nav ?? false,
      sort_order: body.sort_order ?? 0,
    })
    .select()
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data, { status: 201 });
}
