"use client";

import { useEffect, useState, useRef, useCallback } from "react";

// ─── Constants ───────────────────────────────────────────────
const ROW_HEIGHT = 28;
const TOTAL_ROWS = 48; // 24h x 2 (30-min slots)
const TOTAL_HEIGHT = ROW_HEIGHT * TOTAL_ROWS;
const DRAG_THRESHOLD = 5;
const DAY_NAMES_SHORT = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const DAY_NAMES_FULL = [
  "Sunday",
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
];

const SLOT_COLORS = [
  "#DBEAFE",
  "#FEF3C7",
  "#D1FAE5",
  "#FCE7F3",
  "#E0E7FF",
  "#FED7AA",
  "#CCFBF1",
  "#FDE68A",
  "#C7D2FE",
  "#FBCFE8",
  "#A7F3D0",
  "#DDD6FE",
];

// ─── Types ───────────────────────────────────────────────────
interface Host {
  name: string;
  is_primary: boolean;
}

interface Show {
  id: string;
  title: string;
  slug: string;
  cms_show_hosts?: Host[];
}

interface ScheduleSlot {
  id: string;
  show_id: string | null;
  day_of_week: number;
  start_time: string;
  end_time: string;
  label: string | null;
  is_recurring: boolean;
  cms_shows: {
    id: string;
    title: string;
    slug: string;
    cms_show_hosts?: Host[];
  } | null;
}

interface DragState {
  type: "move" | "resize-top" | "resize-bottom";
  slotId: string;
  originalSlot: ScheduleSlot;
  startMouseY: number;
  startMouseX: number;
  startRow: number;
  startDay: number;
  slotStartRow: number;
  slotEndRow: number;
  isDragging: boolean;
}

interface GhostPosition {
  dayOfWeek: number;
  startRow: number;
  endRow: number;
  valid: boolean;
}

interface ModalData {
  slot?: ScheduleSlot;
  dayOfWeek: number;
  startTime: string;
  endTime: string;
  showId: string | null;
  label: string;
}

// ─── Helpers ─────────────────────────────────────────────────

function timeToRow(time: string): number {
  const parts = time.split(":");
  const h = parseInt(parts[0]);
  const m = parseInt(parts[1]);
  return h * 2 + Math.floor(m / 30);
}

/** For end times, "00:00" means midnight = end of day (row 48) */
function endTimeToRow(time: string): number {
  const row = timeToRow(time);
  return row === 0 ? TOTAL_ROWS : row;
}

function rowToTime(row: number): string {
  if (row >= TOTAL_ROWS) return "00:00";
  const h = Math.floor(row / 2);
  const m = (row % 2) * 30;
  return `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}`;
}

function formatTime12(time: string): string {
  const parts = time.split(":");
  const h = parseInt(parts[0]);
  const m = parts[1]?.substring(0, 2) || "00";
  const ampm = h >= 12 ? "p" : "a";
  const h12 = h === 0 ? 12 : h > 12 ? h - 12 : h;
  return m === "00" ? `${h12}${ampm}` : `${h12}:${m}${ampm}`;
}

function slotColor(showId: string | null): string {
  if (!showId) return "#E5E7EB";
  let hash = 0;
  for (let i = 0; i < showId.length; i++) {
    hash = showId.charCodeAt(i) + ((hash << 5) - hash);
  }
  return SLOT_COLORS[Math.abs(hash) % SLOT_COLORS.length];
}

function getPrimaryHost(hosts?: Host[]): string | null {
  if (!hosts || hosts.length === 0) return null;
  const primary = hosts.find((h) => h.is_primary);
  return primary?.name || hosts[0]?.name || null;
}

// ─── ShowCombobox ────────────────────────────────────────────

function ShowCombobox({
  shows,
  value,
  onChange,
}: {
  shows: Show[];
  value: string | null;
  onChange: (showId: string | null) => void;
}) {
  const [query, setQuery] = useState("");
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const selected = shows.find((s) => s.id === value);

  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, []);

  const filtered = shows.filter((s) => {
    if (!query) return true;
    const q = query.toLowerCase();
    const host = getPrimaryHost(s.cms_show_hosts);
    return (
      s.title.toLowerCase().includes(q) ||
      (host && host.toLowerCase().includes(q))
    );
  });

  return (
    <div ref={ref} className="relative">
      <input
        ref={inputRef}
        type="text"
        value={open ? query : selected?.title ?? ""}
        onChange={(e) => {
          setQuery(e.target.value);
          if (!open) setOpen(true);
        }}
        onFocus={() => {
          setOpen(true);
          setQuery("");
        }}
        placeholder="Search shows..."
        className="block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm"
      />
      {value && !open && (
        <button
          type="button"
          onClick={() => {
            onChange(null);
            setQuery("");
            inputRef.current?.focus();
          }}
          className="absolute right-2 top-1/2 -translate-y-1/2 text-charcoal/40 hover:text-charcoal text-lg leading-none"
        >
          &times;
        </button>
      )}
      {open && (
        <div className="absolute left-0 right-0 top-full z-50 mt-1 max-h-60 overflow-y-auto border border-charcoal/20 bg-off-white shadow-lg">
          <button
            type="button"
            onClick={() => {
              onChange(null);
              setOpen(false);
              setQuery("");
            }}
            className="w-full px-3 py-2 text-left text-sm text-charcoal/50 hover:bg-charcoal/5"
          >
            &mdash; No show (label only) &mdash;
          </button>
          {filtered.map((show) => {
            const host = getPrimaryHost(show.cms_show_hosts);
            return (
              <button
                key={show.id}
                type="button"
                onClick={() => {
                  onChange(show.id);
                  setOpen(false);
                  setQuery("");
                }}
                className={`w-full px-3 py-2 text-left text-sm hover:bg-charcoal/5 ${
                  show.id === value ? "bg-charcoal/10 font-medium" : ""
                }`}
              >
                {show.title}
                {host && (
                  <span className="ml-2 text-charcoal/40">&mdash; {host}</span>
                )}
              </button>
            );
          })}
          {filtered.length === 0 && (
            <div className="px-3 py-2 text-sm text-charcoal/30">
              No shows found
            </div>
          )}
        </div>
      )}
    </div>
  );
}

// ─── Main Component ──────────────────────────────────────────

export function ScheduleEditor() {
  const [slots, setSlots] = useState<ScheduleSlot[]>([]);
  const [shows, setShows] = useState<Show[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState<ModalData | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [ghost, setGhost] = useState<GhostPosition | null>(null);

  const gridRef = useRef<HTMLDivElement>(null);
  const dragRef = useRef<DragState | null>(null);

  // ── Fetch data ──
  useEffect(() => {
    Promise.all([
      fetch("/api/schedule").then((r) => r.json()),
      fetch("/api/shows").then((r) => r.json()),
    ]).then(([slotsData, showsData]) => {
      setSlots(Array.isArray(slotsData) ? slotsData : []);
      setShows(Array.isArray(showsData) ? showsData : []);
      setLoading(false);
    });
  }, []);

  // ── Scroll to 6 AM on load ──
  const scrollContainerRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!loading && scrollContainerRef.current) {
      scrollContainerRef.current.scrollTop = 6 * 2 * ROW_HEIGHT;
    }
  }, [loading]);

  // ── Overlap detection ──
  const hasOverlap = useCallback(
    (
      dayOfWeek: number,
      startRow: number,
      endRow: number,
      excludeId?: string
    ) => {
      return slots.some((slot) => {
        if (slot.id === excludeId) return false;
        if (slot.day_of_week !== dayOfWeek) return false;
        const slotStart = timeToRow(slot.start_time);
        const slotEnd = endTimeToRow(slot.end_time);
        return startRow < slotEnd && endRow > slotStart;
      });
    },
    [slots]
  );

  // ── Grid position from mouse event ──
  const getGridPosition = useCallback(
    (clientX: number, clientY: number) => {
      if (!gridRef.current) return null;
      const rect = gridRef.current.getBoundingClientRect();
      const x = clientX - rect.left;
      const y = clientY - rect.top;
      const columnWidth = rect.width / 7;
      const day = Math.max(0, Math.min(6, Math.floor(x / columnWidth)));
      const row = Math.max(
        0,
        Math.min(TOTAL_ROWS - 1, Math.floor(y / ROW_HEIGHT))
      );
      return { day, row };
    },
    []
  );

  // ── Drag/resize mouse handlers ──
  const handleSlotMouseDown = useCallback(
    (
      e: React.MouseEvent,
      slot: ScheduleSlot,
      type: "move" | "resize-top" | "resize-bottom"
    ) => {
      e.preventDefault();
      e.stopPropagation();
      dragRef.current = {
        type,
        slotId: slot.id,
        originalSlot: slot,
        startMouseY: e.clientY,
        startMouseX: e.clientX,
        startRow: timeToRow(slot.start_time),
        startDay: slot.day_of_week,
        slotStartRow: timeToRow(slot.start_time),
        slotEndRow: endTimeToRow(slot.end_time),
        isDragging: false,
      };
    },
    []
  );

  useEffect(() => {
    function computeNewPosition(
      drag: DragState,
      pos: { day: number; row: number }
    ) {
      const duration = drag.slotEndRow - drag.slotStartRow;
      let newStartRow: number, newEndRow: number, newDay: number;

      if (drag.type === "move") {
        const rowDelta = pos.row - drag.startRow;
        newStartRow = drag.slotStartRow + rowDelta;
        newEndRow = newStartRow + duration;
        newDay = pos.day;
        if (newStartRow < 0) {
          newStartRow = 0;
          newEndRow = duration;
        }
        if (newEndRow > TOTAL_ROWS) {
          newEndRow = TOTAL_ROWS;
          newStartRow = TOTAL_ROWS - duration;
        }
      } else if (drag.type === "resize-top") {
        newStartRow = Math.max(
          0,
          Math.min(pos.row, drag.slotEndRow - 1)
        );
        newEndRow = drag.slotEndRow;
        newDay = drag.startDay;
      } else {
        newStartRow = drag.slotStartRow;
        newEndRow = Math.max(
          drag.slotStartRow + 1,
          Math.min(TOTAL_ROWS, pos.row + 1)
        );
        newDay = drag.startDay;
      }

      return { newStartRow, newEndRow, newDay };
    }

    function handleMouseMove(e: MouseEvent) {
      const drag = dragRef.current;
      if (!drag) return;

      const dx = e.clientX - drag.startMouseX;
      const dy = e.clientY - drag.startMouseY;
      if (!drag.isDragging && Math.abs(dx) + Math.abs(dy) < DRAG_THRESHOLD) {
        return;
      }
      drag.isDragging = true;

      const pos = getGridPosition(e.clientX, e.clientY);
      if (!pos) return;

      const { newStartRow, newEndRow, newDay } = computeNewPosition(drag, pos);
      const valid = !hasOverlap(newDay, newStartRow, newEndRow, drag.slotId);
      setGhost({ dayOfWeek: newDay, startRow: newStartRow, endRow: newEndRow, valid });
    }

    async function handleMouseUp(e: MouseEvent) {
      const drag = dragRef.current;
      if (!drag) return;
      dragRef.current = null;
      setGhost(null);

      if (!drag.isDragging) {
        // Click, not drag — open edit modal
        const slot = drag.originalSlot;
        setModal({
          slot,
          dayOfWeek: slot.day_of_week,
          startTime: slot.start_time.substring(0, 5),
          endTime: slot.end_time.substring(0, 5),
          showId: slot.show_id,
          label: slot.label || "",
        });
        setError("");
        return;
      }

      const pos = getGridPosition(e.clientX, e.clientY);
      if (!pos) return;

      const { newStartRow, newEndRow, newDay } = computeNewPosition(drag, pos);

      if (hasOverlap(newDay, newStartRow, newEndRow, drag.slotId)) return;
      if (
        newStartRow === drag.slotStartRow &&
        newEndRow === drag.slotEndRow &&
        newDay === drag.startDay
      )
        return;

      const res = await fetch(`/api/schedule/${drag.slotId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          day_of_week: newDay,
          start_time: rowToTime(newStartRow),
          end_time: rowToTime(newEndRow),
        }),
      });

      if (res.ok) {
        const data = await res.json();
        setSlots((prev) => prev.map((s) => (s.id === data.id ? data : s)));
      }
    }

    document.addEventListener("mousemove", handleMouseMove);
    document.addEventListener("mouseup", handleMouseUp);
    return () => {
      document.removeEventListener("mousemove", handleMouseMove);
      document.removeEventListener("mouseup", handleMouseUp);
    };
  }, [getGridPosition, hasOverlap]);

  // ── Click empty cell to create ──
  const handleGridClick = useCallback(
    (e: React.MouseEvent, dayIndex: number) => {
      if ((e.target as HTMLElement).closest("[data-slot]")) return;
      if (!gridRef.current) return;

      const rect = gridRef.current.getBoundingClientRect();
      const y = e.clientY - rect.top;
      const row = Math.max(
        0,
        Math.min(TOTAL_ROWS - 1, Math.floor(y / ROW_HEIGHT))
      );

      const startRow = row;
      const endRow = Math.min(TOTAL_ROWS, startRow + 2); // default 1 hour

      setModal({
        dayOfWeek: dayIndex,
        startTime: rowToTime(startRow),
        endTime: rowToTime(endRow),
        showId: null,
        label: "",
      });
      setError("");
    },
    []
  );

  // ── Modal save ──
  async function handleModalSave() {
    if (!modal) return;
    setSaving(true);
    setError("");

    const startRow = timeToRow(modal.startTime);
    const endRow = endTimeToRow(modal.endTime);

    if (endRow <= startRow) {
      setError("End time must be after start time");
      setSaving(false);
      return;
    }

    if (hasOverlap(modal.dayOfWeek, startRow, endRow, modal.slot?.id)) {
      setError("This time overlaps with an existing slot");
      setSaving(false);
      return;
    }

    const isNew = !modal.slot;
    const url = isNew ? "/api/schedule" : `/api/schedule/${modal.slot!.id}`;
    const method = isNew ? "POST" : "PATCH";

    const res = await fetch(url, {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        show_id: modal.showId || null,
        day_of_week: modal.dayOfWeek,
        start_time: modal.startTime,
        end_time: modal.endTime,
        label: modal.label || null,
        is_recurring: true,
      }),
    });

    const data = await res.json();
    setSaving(false);

    if (!res.ok) {
      setError(data.error || "Failed to save");
      return;
    }

    if (isNew) {
      setSlots((prev) => [...prev, data]);
    } else {
      setSlots((prev) => prev.map((s) => (s.id === data.id ? data : s)));
    }
    setModal(null);
  }

  async function handleModalDelete() {
    if (!modal?.slot) return;
    const res = await fetch(`/api/schedule/${modal.slot.id}`, {
      method: "DELETE",
    });
    if (res.ok) {
      setSlots((prev) => prev.filter((s) => s.id !== modal.slot!.id));
      setModal(null);
    }
  }

  // ── Render ──
  if (loading) {
    return <p className="text-sm text-charcoal/50">Loading schedule...</p>;
  }

  const slotsByDay: Record<number, ScheduleSlot[]> = {};
  for (let d = 0; d < 7; d++) slotsByDay[d] = [];
  for (const slot of slots) {
    (slotsByDay[slot.day_of_week] ??= []).push(slot);
  }

  // Generate start time options (row 0–47)
  const startTimeOptions = Array.from({ length: TOTAL_ROWS }, (_, i) => ({
    value: rowToTime(i),
    label: formatTime12(rowToTime(i)),
  }));

  // Generate end time options (row 1–48, where 48 = "00:00" midnight)
  const endTimeOptions = Array.from({ length: TOTAL_ROWS }, (_, i) => {
    const row = i + 1;
    const time = rowToTime(row);
    const label =
      row === TOTAL_ROWS ? "12:00a (midnight)" : formatTime12(time);
    return { value: time, label };
  });

  return (
    <div className="relative select-none">
      <div
        ref={scrollContainerRef}
        className="overflow-y-auto border border-charcoal/20"
        style={{ maxHeight: "calc(100vh - 180px)" }}
      >
        {/* Day headers — sticky */}
        <div className="sticky top-0 z-30 flex border-b border-charcoal/20 bg-off-white">
          <div className="w-14 flex-shrink-0" />
          {DAY_NAMES_SHORT.map((name, i) => (
            <div
              key={i}
              className={`flex-1 min-w-[100px] py-2 text-center text-xs font-bold uppercase tracking-wider text-charcoal/60 ${
                i < 6 ? "border-r border-charcoal/10" : ""
              }`}
            >
              {name}
            </div>
          ))}
        </div>

        {/* Grid body */}
        <div className="flex">
          {/* Time labels */}
          <div className="w-14 flex-shrink-0">
            {Array.from({ length: 24 }, (_, h) => (
              <div
                key={h}
                className="pr-2 text-right font-mono text-[10px] leading-none text-charcoal/40"
                style={{ height: ROW_HEIGHT * 2 }}
              >
                <span className="relative -top-1.5">
                  {formatTime12(`${String(h).padStart(2, "0")}:00`)}
                </span>
              </div>
            ))}
          </div>

          {/* Day columns */}
          <div ref={gridRef} className="flex flex-1">
            {DAY_NAMES_SHORT.map((_, dayIndex) => (
              <div
                key={dayIndex}
                className={`relative flex-1 min-w-[100px] cursor-pointer ${
                  dayIndex < 6 ? "border-r border-charcoal/10" : ""
                }`}
                style={{ height: TOTAL_HEIGHT }}
                onClick={(e) => handleGridClick(e, dayIndex)}
              >
                {/* Half-hour grid lines */}
                {Array.from({ length: TOTAL_ROWS }, (_, i) => (
                  <div
                    key={i}
                    className={`border-b ${
                      i % 2 === 1
                        ? "border-charcoal/10"
                        : "border-charcoal/[0.04]"
                    }`}
                    style={{ height: ROW_HEIGHT }}
                  />
                ))}

                {/* Slots */}
                {slotsByDay[dayIndex]
                  .sort((a, b) => a.start_time.localeCompare(b.start_time))
                  .map((slot) => {
                    const startRow = timeToRow(slot.start_time);
                    const endRow = endTimeToRow(slot.end_time);
                    const height = (endRow - startRow) * ROW_HEIGHT;
                    const displayName =
                      slot.label || slot.cms_shows?.title || "Untitled";
                    const hostName = slot.cms_shows
                      ? getPrimaryHost(slot.cms_shows.cms_show_hosts)
                      : null;
                    const bgColor = slotColor(slot.show_id);
                    const isCompact = height <= ROW_HEIGHT;
                    const isMedium = height <= ROW_HEIGHT * 2;

                    return (
                      <div
                        key={slot.id}
                        data-slot="true"
                        className="group absolute left-0.5 right-0.5 cursor-grab overflow-hidden rounded-sm border border-charcoal/15 active:cursor-grabbing"
                        style={{
                          top: startRow * ROW_HEIGHT + 1,
                          height: height - 2,
                          backgroundColor: bgColor,
                          zIndex: 1,
                        }}
                        onMouseDown={(e) =>
                          handleSlotMouseDown(e, slot, "move")
                        }
                      >
                        {/* Resize handle: top */}
                        <div
                          className="absolute left-0 right-0 top-0 z-10 h-2 cursor-n-resize opacity-0 transition-opacity hover:bg-charcoal/20 group-hover:opacity-100"
                          onMouseDown={(e) => {
                            e.stopPropagation();
                            handleSlotMouseDown(e, slot, "resize-top");
                          }}
                        />

                        {/* Content */}
                        <div className="h-full px-1.5 py-0.5">
                          <div
                            className={`truncate font-medium leading-tight text-charcoal ${
                              isCompact ? "text-[10px]" : "text-xs"
                            }`}
                          >
                            {displayName}
                          </div>
                          {!isCompact && hostName && (
                            <div className="mt-0.5 truncate text-[10px] leading-tight text-charcoal/50">
                              {hostName}
                            </div>
                          )}
                          {!isMedium && (
                            <div className="mt-0.5 font-mono text-[9px] text-charcoal/40">
                              {formatTime12(slot.start_time)}&ndash;
                              {formatTime12(slot.end_time)}
                            </div>
                          )}
                        </div>

                        {/* Resize handle: bottom */}
                        <div
                          className="absolute bottom-0 left-0 right-0 z-10 h-2 cursor-s-resize opacity-0 transition-opacity hover:bg-charcoal/20 group-hover:opacity-100"
                          onMouseDown={(e) => {
                            e.stopPropagation();
                            handleSlotMouseDown(e, slot, "resize-bottom");
                          }}
                        />
                      </div>
                    );
                  })}

                {/* Ghost preview during drag */}
                {ghost && ghost.dayOfWeek === dayIndex && (
                  <div
                    className={`pointer-events-none absolute left-0.5 right-0.5 rounded-sm border-2 border-dashed ${
                      ghost.valid
                        ? "border-charcoal/40 bg-charcoal/10"
                        : "border-kpfk-red/40 bg-kpfk-red/10"
                    }`}
                    style={{
                      top: ghost.startRow * ROW_HEIGHT,
                      height: (ghost.endRow - ghost.startRow) * ROW_HEIGHT,
                      zIndex: 5,
                    }}
                  />
                )}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ── Modal ── */}
      {modal && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-charcoal/50"
          onClick={() => {
            setModal(null);
            setError("");
          }}
        >
          <div
            className="w-full max-w-md border border-charcoal/20 bg-off-white p-6 shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            <h3 className="font-serif text-lg font-bold text-charcoal">
              {modal.slot ? "Edit Slot" : "New Slot"} &mdash;{" "}
              {DAY_NAMES_FULL[modal.dayOfWeek]}
            </h3>

            <div className="mt-4 space-y-4">
              {/* Show selector */}
              <div>
                <label className="mb-1 block text-xs font-medium text-charcoal/60">
                  Show
                </label>
                <ShowCombobox
                  shows={shows}
                  value={modal.showId}
                  onChange={(id) =>
                    setModal((prev) => (prev ? { ...prev, showId: id } : null))
                  }
                />
              </div>

              {/* Times */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="mb-1 block text-xs font-medium text-charcoal/60">
                    Start
                  </label>
                  <select
                    value={modal.startTime}
                    onChange={(e) =>
                      setModal((prev) =>
                        prev ? { ...prev, startTime: e.target.value } : null
                      )
                    }
                    className="block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm"
                  >
                    {startTimeOptions.map((opt) => (
                      <option key={opt.value} value={opt.value}>
                        {opt.label}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="mb-1 block text-xs font-medium text-charcoal/60">
                    End
                  </label>
                  <select
                    value={modal.endTime}
                    onChange={(e) =>
                      setModal((prev) =>
                        prev ? { ...prev, endTime: e.target.value } : null
                      )
                    }
                    className="block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm"
                  >
                    {endTimeOptions.map((opt) => (
                      <option key={opt.value} value={opt.value}>
                        {opt.label}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Label */}
              <div>
                <label className="mb-1 block text-xs font-medium text-charcoal/60">
                  Label override{" "}
                  <span className="text-charcoal/30">(optional)</span>
                </label>
                <input
                  type="text"
                  value={modal.label}
                  onChange={(e) =>
                    setModal((prev) =>
                      prev ? { ...prev, label: e.target.value } : null
                    )
                  }
                  placeholder="e.g. Pacifica National Programming"
                  className="block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm"
                />
              </div>

              {/* Day */}
              <div>
                <label className="mb-1 block text-xs font-medium text-charcoal/60">
                  Day
                </label>
                <select
                  value={modal.dayOfWeek}
                  onChange={(e) =>
                    setModal((prev) =>
                      prev
                        ? { ...prev, dayOfWeek: parseInt(e.target.value) }
                        : null
                    )
                  }
                  className="block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm"
                >
                  {DAY_NAMES_FULL.map((name, i) => (
                    <option key={i} value={i}>
                      {name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            {error && <p className="mt-3 text-sm text-kpfk-red">{error}</p>}

            <div className="mt-6 flex items-center justify-between">
              <div className="flex gap-3">
                <button
                  onClick={handleModalSave}
                  disabled={saving}
                  className="border-2 border-charcoal bg-charcoal px-5 py-2 text-sm font-medium text-off-white hover:bg-charcoal/90 disabled:opacity-50"
                >
                  {saving ? "Saving..." : "Save"}
                </button>
                <button
                  onClick={() => {
                    setModal(null);
                    setError("");
                  }}
                  className="px-4 py-2 text-sm text-charcoal/60 hover:text-charcoal"
                >
                  Cancel
                </button>
              </div>
              {modal.slot && (
                <button
                  onClick={handleModalDelete}
                  className="text-sm text-kpfk-red/60 hover:text-kpfk-red"
                >
                  Delete
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
