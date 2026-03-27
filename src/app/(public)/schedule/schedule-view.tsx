"use client";

import Link from "next/link";
import { useState } from "react";

// ─── Types ─────────────────────────────────────────────────

interface ScheduleSlot {
  id: string;
  show_id: string | null;
  day_of_week: number;
  start_time: string;
  end_time: string;
  label: string | null;
  cms_shows: {
    id: string;
    title: string;
    slug: string;
    category: string | null;
  } | null;
}

// ─── Constants ─────────────────────────────────────────────

const DAY_NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
const DAY_NAMES_SHORT = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

const CATEGORY_COLORS: Record<string, string> = {
  "Arts & Entertainment": "#96A8FF",
  "Español": "#FFE2BD",
  "Health & Spirituality": "#FFEB87",
  "Music": "#FFD9E4",
  "News": "#E8FFEA",
  "Public Affairs - Local": "#E5D9FF",
  "Public Affairs - National+Syndicated": "#CABFE0",
  "Special Program": "#FF757A",
};

const GRID_ROW_HEIGHT = 48; // px per hour
const HOURS = Array.from({ length: 24 }, (_, i) => i);

// ─── Helpers ───────────────────────────────────────────────

function formatTime(t: string) {
  const [h, m] = t.split(":");
  const hour = parseInt(h);
  const ampm = hour >= 12 ? "PM" : "AM";
  const h12 = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
  return `${h12}:${m} ${ampm}`;
}

function formatTimeShort(t: string) {
  const [h, m] = t.split(":");
  const hour = parseInt(h);
  const ampm = hour >= 12 ? "p" : "a";
  const h12 = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
  return m === "00" ? `${h12}${ampm}` : `${h12}:${m}${ampm}`;
}

function timeToMinutes(t: string): number {
  const [h, m] = t.split(":").map(Number);
  return h * 60 + m;
}

function getCurrentDayIndex(): number {
  return new Date().getDay();
}

function slotColor(category: string | null | undefined): string {
  if (!category) return "#E5E7EB";
  return CATEGORY_COLORS[category] ?? "#E5E7EB";
}

function showName(slot: ScheduleSlot): string {
  return slot.cms_shows?.title || slot.label || "Programming";
}

// ─── Component ─────────────────────────────────────────────

export function ScheduleView({ slots }: { slots: ScheduleSlot[] }) {
  const [view, setView] = useState<"feed" | "grid">("feed");
  const today = getCurrentDayIndex();

  // Group by day
  const slotsByDay: Record<number, ScheduleSlot[]> = {};
  for (let d = 0; d < 7; d++) slotsByDay[d] = [];
  for (const slot of slots) {
    (slotsByDay[slot.day_of_week] ??= []).push(slot);
  }

  // Feed view: days starting from today
  const orderedDays = Array.from({ length: 7 }, (_, i) => (today + i) % 7);

  return (
    <div className="mx-auto max-w-7xl px-6 py-12 sm:px-8">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="font-serif text-4xl font-bold text-charcoal">Schedule</h1>
          <p className="mt-2 text-lg text-charcoal/60">
            KPFK 90.7 FM weekly broadcast schedule
          </p>
        </div>

        {/* View toggle */}
        <div className="flex gap-1 self-start border border-charcoal/20 p-0.5">
          <button
            onClick={() => setView("feed")}
            className={`px-3 py-1.5 text-sm font-medium transition-colors ${
              view === "feed"
                ? "bg-charcoal text-off-white"
                : "text-charcoal/60 hover:text-charcoal"
            }`}
          >
            List
          </button>
          <button
            onClick={() => setView("grid")}
            className={`px-3 py-1.5 text-sm font-medium transition-colors ${
              view === "grid"
                ? "bg-charcoal text-off-white"
                : "text-charcoal/60 hover:text-charcoal"
            }`}
          >
            Grid
          </button>
        </div>
      </div>

      {slots.length === 0 ? (
        <p className="mt-10 text-base text-charcoal/50">Schedule coming soon.</p>
      ) : view === "feed" ? (
        <FeedView
          slotsByDay={slotsByDay}
          orderedDays={orderedDays}
          today={today}
        />
      ) : (
        <GridView slotsByDay={slotsByDay} today={today} />
      )}
    </div>
  );
}

// ─── Feed View ─────────────────────────────────────────────

function FeedView({
  slotsByDay,
  orderedDays,
  today,
}: {
  slotsByDay: Record<number, ScheduleSlot[]>;
  orderedDays: number[];
  today: number;
}) {
  return (
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
                  <div className="flex items-center gap-3">
                    <span
                      className="inline-block h-3 w-3 flex-shrink-0 rounded-full"
                      style={{ backgroundColor: slotColor(slot.cms_shows?.category) }}
                    />
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
  );
}

// ─── Grid View ─────────────────────────────────────────────

function GridView({
  slotsByDay,
  today,
}: {
  slotsByDay: Record<number, ScheduleSlot[]>;
  today: number;
}) {
  return (
    <div className="mt-10">
      {/* Category legend */}
      <div className="mb-6 flex flex-wrap gap-3">
        {Object.entries(CATEGORY_COLORS).map(([name, color]) => (
          <div key={name} className="flex items-center gap-1.5">
            <span
              className="inline-block h-3 w-3 rounded-sm"
              style={{ backgroundColor: color }}
            />
            <span className="text-xs text-charcoal/60">{name}</span>
          </div>
        ))}
      </div>

      <div className="overflow-x-auto">
        <div className="min-w-[800px]">
          {/* Day headers */}
          <div className="grid grid-cols-[60px_repeat(7,1fr)] border-b border-charcoal/20">
            <div />
            {Array.from({ length: 7 }, (_, i) => (today + i) % 7).map(
              (dayIndex) => (
                <div
                  key={dayIndex}
                  className="px-1 py-2 text-center text-sm font-medium text-charcoal"
                >
                  <span className="hidden sm:inline">{DAY_NAMES[dayIndex]}</span>
                  <span className="sm:hidden">{DAY_NAMES_SHORT[dayIndex]}</span>
                  {dayIndex === today && (
                    <span className="ml-1 text-xs text-kpfk-red">today</span>
                  )}
                </div>
              )
            )}
          </div>

          {/* Grid body */}
          <div className="relative grid grid-cols-[60px_repeat(7,1fr)]">
            {/* Hour labels + gridlines */}
            <div className="relative">
              {HOURS.map((hour) => (
                <div
                  key={hour}
                  className="relative border-b border-charcoal/5"
                  style={{ height: GRID_ROW_HEIGHT }}
                >
                  <span className="absolute -top-2.5 right-2 text-[11px] text-charcoal/40">
                    {formatTimeShort(`${hour.toString().padStart(2, "0")}:00`)}
                  </span>
                </div>
              ))}
            </div>

            {/* Day columns */}
            {Array.from({ length: 7 }, (_, i) => (today + i) % 7).map(
              (dayIndex) => (
                <div
                  key={dayIndex}
                  className="relative border-l border-charcoal/10"
                  style={{ height: GRID_ROW_HEIGHT * 24 }}
                >
                  {/* Hour gridlines */}
                  {HOURS.map((hour) => (
                    <div
                      key={hour}
                      className="absolute left-0 right-0 border-b border-charcoal/5"
                      style={{ top: hour * GRID_ROW_HEIGHT }}
                    />
                  ))}

                  {/* Slots */}
                  {slotsByDay[dayIndex].map((slot) => {
                    const startMin = timeToMinutes(slot.start_time);
                    let endMin = timeToMinutes(slot.end_time);
                    if (endMin <= startMin) endMin = 24 * 60; // midnight wrap
                    const top = (startMin / 60) * GRID_ROW_HEIGHT;
                    const height = Math.max(
                      ((endMin - startMin) / 60) * GRID_ROW_HEIGHT,
                      GRID_ROW_HEIGHT / 2
                    );
                    const bg = slotColor(slot.cms_shows?.category);
                    const name = showName(slot);
                    const isSmall = height < GRID_ROW_HEIGHT * 0.8;

                    return (
                      <div
                        key={slot.id}
                        className="group absolute left-0.5 right-0.5 overflow-hidden border border-charcoal/10"
                        style={{
                          top,
                          height,
                          backgroundColor: bg,
                        }}
                      >
                        <div className="h-full px-1.5 py-0.5">
                          {slot.cms_shows ? (
                            <Link
                              href={`/on-air/${slot.cms_shows.slug}`}
                              className="block truncate text-[11px] font-medium leading-tight text-charcoal hover:text-kpfk-red"
                            >
                              {name}
                            </Link>
                          ) : (
                            <span className="block truncate text-[11px] font-medium leading-tight text-charcoal">
                              {name}
                            </span>
                          )}
                          {!isSmall && (
                            <span className="mt-0.5 block truncate text-[10px] leading-tight text-charcoal/50">
                              {formatTimeShort(slot.start_time)}–{formatTimeShort(slot.end_time)}
                            </span>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
