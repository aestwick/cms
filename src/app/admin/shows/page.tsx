import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { ShowsList } from "@/components/shows-list";

export default async function ShowsListPage() {
  const user = await requireRole("admin", "editor");
  const supabase = getSupabaseAdmin();

  const { data: shows } = await supabase
    .from("cms_shows")
    .select("id, title, slug, show_type, is_active, is_claimed, broadcast_status, updated_at")
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .order("sort_order")
    .order("title");

  // Fetch schedule slots to detect discrepancies
  const { data: allSlots } = await supabase
    .from("cms_schedule_slots")
    .select("show_id")
    .eq("station_id", user.station_id)
    .eq("is_recurring", true);

  const showIdsWithSlots = (allSlots ?? []).map((s: { show_id: string }) => s.show_id);

  return (
    <ShowsList
      shows={shows ?? []}
      showIdsWithSlots={showIdsWithSlots}
    />
  );
}
