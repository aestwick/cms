import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";
import {
  captureSnapshot,
  describeOperation,
} from "@/lib/schedule-snapshots";

// GET /api/schedule/snapshots — list snapshots for the user's station
// (admin/editor only). Returns metadata only, not the slot_data blob.
export async function GET(request: NextRequest) {
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const limitParam = request.nextUrl.searchParams.get("limit");
  const parsedLimit = limitParam ? parseInt(limitParam, 10) : 30;
  const limit = Number.isFinite(parsedLimit)
    ? Math.min(Math.max(parsedLimit, 1), 100)
    : 30;

  const supabase = getSupabaseAdmin();
  const { data, error } = await supabase
    .from("cms_schedule_snapshots")
    .select(
      "id, station_id, operation, description, slot_count, created_at, created_by"
    )
    .eq("station_id", user.station_id)
    .order("created_at", { ascending: false })
    .limit(limit);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ snapshots: data ?? [] });
}

// POST /api/schedule/snapshots — manually save a snapshot of the current state.
// admin/editor only.
export async function POST(request: NextRequest) {
  const user = await getCmsUser();
  if (!user || !["admin", "editor"].includes(user.role)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  let body: { description?: string } = {};
  try {
    body = await request.json();
  } catch {
    // Empty body is fine — we'll generate a description.
  }

  const supabase = getSupabaseAdmin();

  try {
    const result = await captureSnapshot(supabase, {
      stationId: user.station_id,
      userId: user.id,
      operation: "manual_save",
      description:
        body.description?.trim() ||
        describeOperation("manual_save", {
          slotCount: 0,
          userName: user.display_name,
        }),
    });

    return NextResponse.json(
      { success: true, id: result.id, slot_count: result.slotCount },
      { status: 201 }
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : "Snapshot failed";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
