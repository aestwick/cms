import Link from "next/link";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import type { Metadata } from "next";
import { PrintButton } from "@/components/print-button";
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
  cms_shows: { id: string; title: string; slug: string; category: string | null }[] | null;
}

const DAY_ABBR = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const DAY_NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

// Voices tint vars keyed by Voice.
const VOICE_TINT: Record<string, string> = {
  news: "var(--tint-news)",
  music: "var(--tint-music)",
  culture: "var(--tint-culture)",
  community: "var(--tint-community)",
  talk: "var(--tint-talk)",
};

// Map KPFK's freeform show categories (migration 022) onto the five Voices.
const CATEGORY_TO_VOICE: Record<string, string> = {
  "Music": "music",
  "Public Affairs - Local": "news",
  "Public Affairs - National+Syndicated": "news",
  "Arts & Entertainment": "culture",
  "Health & Spirituality": "culture",
  "Español": "community",
  "Special Program": "talk",
};

const LEGEND: { key: string; label: string }[] = [
  { key: "news", label: "News" },
  { key: "music", label: "Music" },
  { key: "culture", label: "Culture" },
  { key: "community", label: "Community" },
  { key: "talk", label: "Talk" },
];

function formatTime(t: string) {
  const [h, m] = t.split(":");
  const hour = parseInt(h);
  const ampm = hour >= 12 ? "PM" : "AM";
  const h12 = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
  return `${h12}:${m} ${ampm}`;
}

function todayInLA(): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Los_Angeles",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());
}

// Current time in LA as minutes-since-midnight, for the on-now highlight.
function nowMinutesLA(): number {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: "America/Los_Angeles",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).formatToParts(new Date());
  const h = Number(parts.find((p) => p.type === "hour")?.value ?? 0);
  const m = Number(parts.find((p) => p.type === "minute")?.value ?? 0);
  return h * 60 + m;
}

function toMinutes(t: string): number {
  const [h, m] = t.split(":").map(Number);
  return h * 60 + m;
}

function tintFor(slot: ScheduleSlot): string {
  const cat = slot.cms_shows?.[0]?.category;
  const voice = (cat && CATEGORY_TO_VOICE[cat]) || "talk";
  return VOICE_TINT[voice];
}

export default async function SchedulePage() {
  const supabase = getSupabaseAdmin();

  const today = todayInLA();
  const { data } = await supabase
    .from("cms_schedule_slots")
    .select(
      "id, show_id, day_of_week, start_time, end_time, label, is_recurring, effective_date, expires_date, cms_shows(id, title, slug, category)"
    )
    .order("day_of_week", { ascending: true })
    .order("start_time", { ascending: true });

  const allSlots = (data ?? []) as ScheduleSlot[];

  // Resolve this week starting today so visitors see what's on now first.
  const week = resolveSlotsForWeek<ScheduleSlot>(today, allSlots);
  const totalSlots = week.reduce((sum, d) => sum + d.slots.length, 0);
  const nowMin = nowMinutesLA();

  return (
    <div className="mx-auto max-w-7xl px-6 py-12 sm:px-8">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="kpfk-label">Broadcast week</p>
          <h1 className="kpfk-display mt-2 text-5xl sm:text-6xl" style={{ color: "var(--txt)" }}>
            Schedule<span style={{ color: "var(--kpfk-red)" }}>.</span>
          </h1>
          <p className="mt-3 text-lg" style={{ color: "var(--muted)" }}>
            KPFK 90.7 FM — all times Pacific.
          </p>
        </div>
        <div className="no-print flex items-center gap-3">
          <PrintButton />
        </div>
      </div>

      {/* Legend */}
      <div className="no-print mt-6 flex flex-wrap items-center gap-x-5 gap-y-2">
        {LEGEND.map((item) => (
          <span key={item.key} className="inline-flex items-center gap-2 text-xs" style={{ color: "var(--muted)" }}>
            <span
              className="inline-block h-3 w-3 border"
              style={{ background: VOICE_TINT[item.key], borderColor: "var(--line)" }}
            />
            {item.label}
          </span>
        ))}
      </div>

      {totalSlots === 0 ? (
        <p className="mt-10 text-base" style={{ color: "var(--faint)" }}>
          Schedule coming soon.
        </p>
      ) : (
        <div className="mt-8 overflow-x-auto">
          {/* Week grid: 7 day columns (stacks on mobile = the Day view). */}
          <div
            className="grid grid-cols-1 gap-px sm:[grid-template-columns:repeat(7,minmax(160px,1fr))]"
            style={{ background: "var(--line)", border: "1px solid var(--line)" }}
          >
            {week.map((day, idx) => {
              const isToday = idx === 0;
              return (
                <div key={day.date} className="flex flex-col" style={{ background: "var(--card)" }}>
                  {/* Sticky day header */}
                  <div
                    className="sticky top-0 z-10 border-b px-3 py-2.5"
                    style={{
                      background: isToday ? "var(--bar)" : "var(--card)",
                      color: isToday ? "var(--bar-txt)" : "var(--txt)",
                      borderColor: "var(--line)",
                    }}
                  >
                    <span className="text-xs font-extrabold uppercase tracking-[0.1em]">
                      <span className="sm:hidden">{DAY_NAMES[day.dayOfWeek]}</span>
                      <span className="hidden sm:inline">{DAY_ABBR[day.dayOfWeek]}</span>
                    </span>
                    {isToday && (
                      <span className="ml-2 text-[10px] font-extrabold uppercase tracking-[0.14em] text-kpfk-red">
                        Today
                      </span>
                    )}
                  </div>

                  {/* Program blocks */}
                  <div className="flex flex-1 flex-col">
                    {day.slots.length === 0 ? (
                      <p className="px-3 py-4 text-xs" style={{ color: "var(--faint)" }}>
                        —
                      </p>
                    ) : (
                      day.slots.map((slot) => {
                        const isOverride = !slot.is_recurring;
                        const isLive =
                          isToday &&
                          nowMin >= toMinutes(slot.start_time) &&
                          nowMin < toMinutes(slot.end_time);
                        const title = slot.label || slot.cms_shows?.[0]?.title || "Programming";
                        const slug = slot.cms_shows?.[0]?.slug;
                        const inner = (
                          <>
                            <span
                              className="block text-[11px] font-bold uppercase tracking-[0.06em]"
                              style={{ color: "var(--faint)" }}
                            >
                              {formatTime(slot.start_time)}
                            </span>
                            <span
                              className="mt-0.5 block text-sm font-bold leading-snug"
                              style={{ color: "var(--txt)" }}
                            >
                              {title}
                            </span>
                            {isLive && (
                              <span className="mt-1 inline-flex items-center gap-1.5 text-[10px] font-extrabold uppercase tracking-[0.14em] text-kpfk-red">
                                <span
                                  className="inline-block h-1.5 w-1.5 rounded-full bg-kpfk-red"
                                  style={{ animation: "kpfk-pulse 1.8s infinite" }}
                                />
                                On Now
                              </span>
                            )}
                            {isOverride && (
                              <span className="mt-1 inline-block text-[10px] font-extrabold uppercase tracking-[0.1em] text-kpfk-red">
                                Special
                              </span>
                            )}
                          </>
                        );
                        const blockStyle = {
                          borderBottom: "1px solid var(--hair)",
                          borderLeft: `3px solid ${tintFor(slot)}`,
                          background: isLive ? "var(--live-bg)" : "transparent",
                        } as const;

                        return slug ? (
                          <Link
                            key={slot.id}
                            href={`/on-air/${slug}`}
                            className="block px-3 py-2.5 transition-colors hover:bg-[color-mix(in_srgb,var(--txt)_4%,transparent)]"
                            style={blockStyle}
                          >
                            {inner}
                          </Link>
                        ) : (
                          <div key={slot.id} className="px-3 py-2.5" style={blockStyle}>
                            {inner}
                          </div>
                        );
                      })
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
