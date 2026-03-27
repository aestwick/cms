import Link from "next/link";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Schedule — KPFK 90.7 FM",
  description: "Weekly broadcast schedule for KPFK 90.7 FM community radio.",
};

interface ScheduleSlot {
  id: string;
  show_id: string | null;
  day_of_week: number;
  start_time: string;
  end_time: string;
  label: string | null;
  cms_shows: { id: string; title: string; slug: string } | null;
}

const DAY_NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

function formatTime(t: string) {
  const [h, m] = t.split(":");
  const hour = parseInt(h);
  const ampm = hour >= 12 ? "PM" : "AM";
  const h12 = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
  return `${h12}:${m} ${ampm}`;
}

function getCurrentDayIndex(): number {
  // LA timezone — approximate for SSR
  return new Date().getDay();
}

export default async function SchedulePage() {
  const supabase = getSupabaseAdmin();

  const { data } = await supabase
    .from("cms_schedule_slots")
    .select("id, show_id, day_of_week, start_time, end_time, label, cms_shows(id, title, slug)")
    .eq("is_recurring", true)
    .order("day_of_week", { ascending: true })
    .order("start_time", { ascending: true });

  const slots = (data ?? []) as ScheduleSlot[];
  const today = getCurrentDayIndex();

  // Group by day
  const slotsByDay: Record<number, ScheduleSlot[]> = {};
  for (let d = 0; d < 7; d++) slotsByDay[d] = [];
  for (const slot of slots) {
    (slotsByDay[slot.day_of_week] ??= []).push(slot);
  }

  // Reorder days starting from today
  const orderedDays = Array.from({ length: 7 }, (_, i) => (today + i) % 7);

  return (
    <div className="mx-auto max-w-7xl px-6 py-12 sm:px-8">
      <h1 className="font-serif text-4xl font-bold text-charcoal">Schedule</h1>
      <p className="mt-3 text-lg text-charcoal/60">
        KPFK 90.7 FM weekly broadcast schedule
      </p>

      {slots.length === 0 ? (
        <p className="mt-10 text-base text-charcoal/50">Schedule coming soon.</p>
      ) : (
        <div className="mt-10 space-y-10">
          {orderedDays.map((dayIndex) => (
            <section key={dayIndex}>
              <h2 className="flex items-center gap-3 border-b-2 border-charcoal pb-3 font-serif text-2xl font-bold text-charcoal">
                {DAY_NAMES[dayIndex]}
                {dayIndex === today && (
                  <span className="font-mono text-sm font-normal text-kpfk-red">
                    TODAY
                  </span>
                )}
              </h2>

              {slotsByDay[dayIndex].length === 0 ? (
                <p className="mt-4 text-base text-charcoal/40">
                  No scheduled programming
                </p>
              ) : (
                <div className="mt-4 divide-y divide-charcoal/10 border border-charcoal/10">
                  {slotsByDay[dayIndex].map((slot) => (
                    <div
                      key={slot.id}
                      className="flex items-center gap-5 px-5 py-4 transition-colors hover:bg-charcoal/[0.02]"
                    >
                      <span className="w-44 flex-shrink-0 font-mono text-base text-charcoal/50">
                        {formatTime(slot.start_time)} – {formatTime(slot.end_time)}
                      </span>
                      <div>
                        {slot.cms_shows ? (
                          <Link
                            href={`/on-air/${slot.cms_shows.slug}`}
                            className="font-serif text-xl font-medium text-charcoal hover:text-kpfk-red"
                          >
                            {slot.cms_shows.title}
                          </Link>
                        ) : (
                          <span className="font-serif text-xl font-medium text-charcoal">
                            {slot.label || "Programming"}
                          </span>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </section>
          ))}
        </div>
      )}
    </div>
  );
}
