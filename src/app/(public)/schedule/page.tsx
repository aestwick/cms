import { getSupabaseAdmin } from "@/lib/supabase/admin";
import type { Metadata } from "next";
import { ScheduleView } from "./schedule-view";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Schedule — KPFK 90.7 FM",
  description: "Weekly broadcast schedule for KPFK 90.7 FM community radio.",
};

export default async function SchedulePage() {
  const supabase = getSupabaseAdmin();

  const { data } = await supabase
    .from("cms_schedule_slots")
    .select("id, show_id, day_of_week, start_time, end_time, label, cms_shows(id, title, slug, category)")
    .eq("is_recurring", true)
    .order("day_of_week", { ascending: true })
    .order("start_time", { ascending: true });

  return <ScheduleView slots={data ?? []} />;
}
