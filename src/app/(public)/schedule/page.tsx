import Link from "next/link";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import type { Metadata } from "next";
import {
  resolveSlotsForWeek,
  type ResolvableSlot,
} from "@/lib/schedule-resolver";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Schedule — KPFK 90.7 FM",
  description: "Weekly broadcast schedule for KPFK 90.7 FM community radio.",
};

interface ScheduleSlot extends ResolvableSlot {
  id: string;
  show_id: string | null;
  label: string | null;
  cms_shows: { id: string; title: string; slug: string }[] | null;
}

const DAY_NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

function formatTime(t: string) {
  const [h, m] = t.split(":");
  const hour = parseInt(h);
  const ampm = hour >= 12 ? "PM" : "AM";
  const h12 = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
  return `${h12}:${m} ${ampm}`;
}

// Compute today's date in LA timezone as YYYY-MM-DD. Uses the runtime locale's
// "en-CA" formatter which always emits ISO-style dates.
function todayInLA(): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Los_Angeles",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());
}

export default async function SchedulePage() {
  const supabase = getSupabaseAdmin();

  const today = todayInLA();
  const { data } = await supabase
    .from("cms_schedule_slots")
    .select(
      "id, show_id, day_of_week, start_time, end_time, label, is_recurring, effective_date, expires_date, cms_shows(id, title, slug)"
    )
    .order("day_of_week", { ascending: true })
    .order("start_time", { ascending: true });

  const allSlots = (data ?? []) as ScheduleSlot[];

  // Render this week, starting today (not Sunday) so visitors see what's
  // happening now first. Today + 6 forward days.
  const week = resolveSlotsForWeek<ScheduleSlot>(today, allSlots);
  const totalSlots = week.reduce((sum, d) => sum + d.slots.length, 0);

  return (
    <div className="mx-auto max-w-7xl px-6 py-12 sm:px-8">
      <h1 className="font-serif text-4xl font-bold text-charcoal">Schedule</h1>
      <p className="mt-3 text-lg text-charcoal/60">
        KPFK 90.7 FM weekly broadcast schedule
      </p>

      {totalSlots === 0 ? (
        <p className="mt-10 text-base text-charcoal/50">Schedule coming soon.</p>
      ) : (
        <div className="mt-10 space-y-10">
          {week.map((day, idx) => (
            <section key={day.date}>
              <h2 className="flex items-center gap-3 border-b-2 border-charcoal pb-3 font-serif text-2xl font-bold text-charcoal">
                {DAY_NAMES[day.dayOfWeek]}
                {idx === 0 && (
                  <span className="font-mono text-sm font-normal text-kpfk-red">
                    TODAY
                  </span>
                )}
              </h2>

              {day.slots.length === 0 ? (
                <p className="mt-4 text-base text-charcoal/40">
                  No scheduled programming
                </p>
              ) : (
                <div className="mt-4 divide-y divide-charcoal/10 border border-charcoal/10">
                  {day.slots.map((slot) => {
                    const isOverride = !slot.is_recurring;
                    return (
                      <div
                        key={slot.id}
                        className="flex items-center gap-5 px-5 py-4 transition-colors hover:bg-charcoal/[0.02]"
                      >
                        <span className="w-44 flex-shrink-0 font-mono text-base text-charcoal/50">
                          {formatTime(slot.start_time)} – {formatTime(slot.end_time)}
                        </span>
                        <div className="flex items-baseline gap-3">
                          {slot.cms_shows?.[0] ? (
                            <Link
                              href={`/on-air/${slot.cms_shows[0].slug}`}
                              className="font-serif text-xl font-medium text-charcoal hover:text-kpfk-red"
                            >
                              {slot.label || slot.cms_shows[0].title}
                            </Link>
                          ) : (
                            <span className="font-serif text-xl font-medium text-charcoal">
                              {slot.label || "Programming"}
                            </span>
                          )}
                          {isOverride && (
                            <span className="rounded-sm bg-amber-100 px-1.5 py-0.5 font-mono text-[10px] uppercase tracking-wide text-amber-800">
                              Special
                            </span>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </section>
          ))}
        </div>
      )}
    </div>
  );
}
