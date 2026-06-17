import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";

function slugify(input: string): string {
  return input
    ?.toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

// PATCH /api/categories/[id] — update a category
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { id } = await params;
  const body = await request.json();

  const update: Record<string, unknown> = {};
  if (body.name !== undefined) update.name = body.name;
  if (body.slug !== undefined) update.slug = slugify(body.slug);
  if (body.description !== undefined) update.description = body.description || null;
  if (body.color !== undefined) update.color = body.color || null;
  if (body.show_in_nav !== undefined) update.show_in_nav = body.show_in_nav;
  if (body.sort_order !== undefined) update.sort_order = body.sort_order;
  if (body.parent_id !== undefined) {
    // Guard against self-parenting.
    update.parent_id = body.parent_id === id ? null : body.parent_id || null;
  }

  const supabase = getSupabaseAdmin();
  const { data, error } = await supabase
    .from("cms_categories")
    .update(update)
    .eq("id", id)
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .select()
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data);
}

// DELETE /api/categories/[id] — soft-delete a category (and its children)
export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { id } = await params;
  const supabase = getSupabaseAdmin();
  const now = new Date().toISOString();

  // Soft-delete the node and any direct children.
  const { error } = await supabase
    .from("cms_categories")
    .update({ deleted_at: now })
    .eq("station_id", user.station_id)
    .or(`id.eq.${id},parent_id.eq.${id}`)
    .is("deleted_at", null);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
