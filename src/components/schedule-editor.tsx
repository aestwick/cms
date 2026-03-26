"use client";

import { useEffect, useState, useRef, useCallback } from "react";
import { useIsMobile } from "@/hooks/use-mobile-sidebar";

// ─── Constants ───────────────────────────────────────────────
const ROW_HEIGHT = 28;
const TOTAL_ROWS = 48; // 24h x 2 (30-min slots)
const TOTAL_HEIGHT = ROW_HEIGHT * TOTAL_ROWS;
const MOUSE_DRAG_THRESHOLD = 5;
const TOUCH_DRAG_THRESHOLD = 10;
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

// ─── Confessor Import Types ─────────────────────────────────
interface ConfessorPreviewSlot {
  confessor_altid: string;
  show_name: string;
  host_name: string;
  day_of_week: number;
  start_time: string;
  end_time: string;
  category: string;
  matched_show_id: string | null;
  matched_show_title: string | null;
}

interface ConfessorPreviewResponse {
  incoming: ConfessorPreviewSlot[];
  current_count: number;
  incoming_count: number;
  unmatched_shows: { altid: string; name: string }[];
}

// ─── Types ───────────────────────────────────────────────────
interface Host {
  name: string;
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
  image_path: string | null;
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
  isTouch: boolean;
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
  imagePath: string;
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
  return hosts[0]?.name || null;
}

// ─── TimePicker ─────────────────────────────────────────────

const HOURS_AM = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
const HOURS_PM = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
const MINUTES = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];

function parseTime24(time: string): { hour: number; minute: number } {
  const [h, m] = time.split(":").map(Number);
  return { hour: h, minute: m };
}

function to24Hour(h12: number, period: "AM" | "PM"): number {
  if (period === "AM") return h12 === 12 ? 0 : h12;
  return h12 === 12 ? 12 : h12 + 12;
}

function TimePicker({
  value,
  onChange,
  label,
}: {
  value: string;
  onChange: (time: string) => void;
  label: string;
}) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const { hour, minute } = parseTime24(value);
  const period: "AM" | "PM" = hour >= 12 ? "PM" : "AM";
  const h12 = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;

  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, []);

  function selectHour(h: number, p: "AM" | "PM") {
    const h24 = to24Hour(h, p);
    onChange(`${String(h24).padStart(2, "0")}:${String(minute).padStart(2, "0")}`);
  }

  function selectMinute(m: number) {
    onChange(`${String(hour).padStart(2, "0")}:${String(m).padStart(2, "0")}`);
  }

  const displayTime = `${h12}:${String(minute).padStart(2, "0")} ${period.toLowerCase()}`;

  return (
    <div ref={ref} className="relative">
      <button
        type="button"
        onClick={() => setOpen(!open)}
        className="flex w-full items-center gap-2 border border-charcoal/20 bg-off-white px-3 py-2.5 text-left text-sm"
      >
        <svg className="h-4 w-4 text-charcoal/40" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
          <circle cx="12" cy="12" r="10" />
          <path d="M12 6v6l4 2" />
        </svg>
        {displayTime}
        <svg className="ml-auto h-3 w-3 text-charcoal/30" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path d="M6 9l6 6 6-6" />
        </svg>
      </button>

      {open && (
        <div className="absolute left-0 top-full z-50 mt-1 w-[320px] border border-charcoal/20 bg-off-white p-3 shadow-lg">
          <div className="flex gap-4">
            {/* Hour grid */}
            <div className="flex-1">
              <div className="mb-2 text-center text-xs font-medium text-charcoal/50">
                Hour
              </div>
              {/* AM rows */}
              <div className="mb-1 flex items-center gap-1">
                <span className="w-7 text-[10px] font-medium text-charcoal/40">AM</span>
                <div className="grid flex-1 grid-cols-6 gap-0.5">
                  {HOURS_AM.map((h) => (
                    <button
                      key={`am-${h}`}
                      type="button"
                      onClick={() => selectHour(h, "AM")}
                      className={`rounded px-1 py-1.5 text-xs ${
                        h12 === h && period === "AM"
                          ? "bg-charcoal text-off-white"
                          : "text-charcoal hover:bg-charcoal/10"
                      }`}
                    >
                      {h}
                    </button>
                  ))}
                </div>
              </div>
              {/* PM rows */}
              <div className="flex items-center gap-1">
                <span className="w-7 text-[10px] font-medium text-charcoal/40">PM</span>
                <div className="grid flex-1 grid-cols-6 gap-0.5">
                  {HOURS_PM.map((h) => (
                    <button
                      key={`pm-${h}`}
                      type="button"
                      onClick={() => selectHour(h, "PM")}
                      className={`rounded px-1 py-1.5 text-xs ${
                        h12 === h && period === "PM"
                          ? "bg-charcoal text-off-white"
                          : "text-charcoal hover:bg-charcoal/10"
                      }`}
                    >
                      {h}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Divider */}
            <div className="w-px bg-charcoal/10" />

            {/* Minute grid */}
            <div>
              <div className="mb-2 text-center text-xs font-medium text-charcoal/50">
                Minute
              </div>
              <div className="grid grid-cols-4 gap-0.5">
                {MINUTES.map((m) => (
                  <button
                    key={m}
                    type="button"
                    onClick={() => selectMinute(m)}
                    className={`rounded px-2 py-1.5 text-xs ${
                      minute === m
                        ? "bg-charcoal text-off-white"
                        : "text-charcoal hover:bg-charcoal/10"
                    }`}
                  >
                    {String(m).padStart(2, "0")}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
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
        className="block w-full border border-charcoal/20 bg-off-white px-3 py-2.5 text-sm"
      />
      {open && (
        <div className="absolute left-0 right-0 top-full z-50 mt-1 max-h-60 overflow-y-auto border border-charcoal/20 bg-off-white shadow-lg">
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
                className={`w-full px-3 py-2.5 text-left text-sm hover:bg-charcoal/5 ${
                  show.id === value ? "bg-charcoal/10 font-medium" : ""
                }`}
              >
                {show.title}
                {host && (
                  <span className="ml-2 text-charcoal/40">
                    &mdash; {host}
                  </span>
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
  const [selectedDay, setSelectedDay] = useState(() => new Date().getDay());

  // Confessor import state
  const [importPreview, setImportPreview] = useState<ConfessorPreviewResponse | null>(null);
  const [importLoading, setImportLoading] = useState(false);
  const [importApplying, setImportApplying] = useState(false);
  const [importError, setImportError] = useState("");
  const [importSuccess, setImportSuccess] = useState("");

  const isMobile = useIsMobile(768); // below md breakpoint

  const gridRef = useRef<HTMLDivElement>(null);
  const dragRef = useRef<DragState | null>(null);
  const scrollContainerRef = useRef<HTMLDivElement>(null);

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

  // ── Grid position from coordinates ──
  const getGridPosition = useCallback(
    (clientX: number, clientY: number) => {
      if (!gridRef.current) return null;
      const rect = gridRef.current.getBoundingClientRect();
      const x = clientX - rect.left;
      const y = clientY - rect.top;
      const numColumns = isMobile ? 1 : 7;
      const columnWidth = rect.width / numColumns;
      const colIndex = Math.max(
        0,
        Math.min(numColumns - 1, Math.floor(x / columnWidth))
      );
      // On mobile, the column index is always 0, but the actual day is selectedDay
      const day = isMobile ? selectedDay : colIndex;
      const row = Math.max(
        0,
        Math.min(TOTAL_ROWS - 1, Math.floor(y / ROW_HEIGHT))
      );
      return { day, row };
    },
    [isMobile, selectedDay]
  );

  // ── Shared drag computation ──
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
      newStartRow = Math.max(0, Math.min(pos.row, drag.slotEndRow - 1));
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

  // ── Start drag (shared for mouse and touch) ──
  const startDrag = useCallback(
    (
      clientX: number,
      clientY: number,
      slot: ScheduleSlot,
      type: "move" | "resize-top" | "resize-bottom",
      isTouch: boolean
    ) => {
      dragRef.current = {
        type,
        slotId: slot.id,
        originalSlot: slot,
        startMouseY: clientY,
        startMouseX: clientX,
        startRow: timeToRow(slot.start_time),
        startDay: slot.day_of_week,
        slotStartRow: timeToRow(slot.start_time),
        slotEndRow: endTimeToRow(slot.end_time),
        isDragging: false,
        isTouch,
      };
    },
    []
  );

  const handleSlotMouseDown = useCallback(
    (
      e: React.MouseEvent,
      slot: ScheduleSlot,
      type: "move" | "resize-top" | "resize-bottom"
    ) => {
      e.preventDefault();
      e.stopPropagation();
      startDrag(e.clientX, e.clientY, slot, type, false);
    },
    [startDrag]
  );

  const handleSlotTouchStart = useCallback(
    (e: React.TouchEvent, slot: ScheduleSlot) => {
      e.stopPropagation();
      const touch = e.touches[0];
      startDrag(touch.clientX, touch.clientY, slot, "move", true);
    },
    [startDrag]
  );

  // ── Finalize drag ──
  const finalizeDrag = useCallback(
    async (clientX: number, clientY: number) => {
      const drag = dragRef.current;
      if (!drag) return;
      dragRef.current = null;
      setGhost(null);

      if (!drag.isDragging) {
        // Click/tap — open edit modal
        const slot = drag.originalSlot;
        setModal({
          slot,
          dayOfWeek: slot.day_of_week,
          startTime: slot.start_time.substring(0, 5),
          endTime: slot.end_time.substring(0, 5),
          showId: slot.show_id,
          label: slot.label || "",
          imagePath: slot.image_path || "",
        });
        setError("");
        return;
      }

      const pos = getGridPosition(clientX, clientY);
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
    },
    [getGridPosition, hasOverlap]
  );

  // ── Mouse + touch event listeners ──
  useEffect(() => {
    function handlePointerMove(clientX: number, clientY: number) {
      const drag = dragRef.current;
      if (!drag) return;

      const threshold = drag.isTouch
        ? TOUCH_DRAG_THRESHOLD
        : MOUSE_DRAG_THRESHOLD;
      const dx = clientX - drag.startMouseX;
      const dy = clientY - drag.startMouseY;
      if (!drag.isDragging && Math.abs(dx) + Math.abs(dy) < threshold) {
        return false; // not dragging yet
      }
      drag.isDragging = true;

      const pos = getGridPosition(clientX, clientY);
      if (!pos) return true;

      const { newStartRow, newEndRow, newDay } = computeNewPosition(drag, pos);
      const valid = !hasOverlap(newDay, newStartRow, newEndRow, drag.slotId);
      setGhost({
        dayOfWeek: newDay,
        startRow: newStartRow,
        endRow: newEndRow,
        valid,
      });
      return true;
    }

    function handleMouseMove(e: MouseEvent) {
      handlePointerMove(e.clientX, e.clientY);
    }

    function handleMouseUp(e: MouseEvent) {
      if (!dragRef.current) return;
      finalizeDrag(e.clientX, e.clientY);
    }

    function handleTouchMove(e: TouchEvent) {
      const drag = dragRef.current;
      if (!drag || !drag.isTouch) return;
      const touch = e.touches[0];
      const isDragging = handlePointerMove(touch.clientX, touch.clientY);
      // Only prevent scroll once we've started dragging
      if (isDragging && drag.isDragging) {
        e.preventDefault();
      }
    }

    function handleTouchEnd(e: TouchEvent) {
      const drag = dragRef.current;
      if (!drag || !drag.isTouch) return;
      const touch = e.changedTouches[0];
      finalizeDrag(touch.clientX, touch.clientY);
    }

    document.addEventListener("mousemove", handleMouseMove);
    document.addEventListener("mouseup", handleMouseUp);
    document.addEventListener("touchmove", handleTouchMove, { passive: false });
    document.addEventListener("touchend", handleTouchEnd);
    return () => {
      document.removeEventListener("mousemove", handleMouseMove);
      document.removeEventListener("mouseup", handleMouseUp);
      document.removeEventListener("touchmove", handleTouchMove);
      document.removeEventListener("touchend", handleTouchEnd);
    };
  }, [getGridPosition, hasOverlap, finalizeDrag]);

  // ── Click/tap empty cell to create ──
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
      const endRow = Math.min(TOTAL_ROWS, startRow + 2);

      setModal({
        dayOfWeek: dayIndex,
        startTime: rowToTime(startRow),
        endTime: rowToTime(endRow),
        showId: null,
        label: "",
        imagePath: "",
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

    if (!modal.showId) {
      setError("Please select a show");
      setSaving(false);
      return;
    }

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
        show_id: modal.showId,
        day_of_week: modal.dayOfWeek,
        start_time: modal.startTime,
        end_time: modal.endTime,
        label: modal.label || null,
        image_path: modal.imagePath || null,
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

  // ── Confessor import ──
  async function handleConfessorPreview() {
    setImportLoading(true);
    setImportError("");
    setImportSuccess("");
    try {
      const res = await fetch("/api/schedule/confessor-preview");
      if (!res.ok) {
        const data = await res.json();
        setImportError(data.error || "Failed to fetch Confessor schedule");
        setImportLoading(false);
        return;
      }
      const data: ConfessorPreviewResponse = await res.json();
      setImportPreview(data);
    } catch {
      setImportError("Network error reaching Confessor preview");
    }
    setImportLoading(false);
  }

  async function handleConfessorApply() {
    setImportApplying(true);
    setImportError("");
    try {
      const res = await fetch("/api/schedule/confessor-import", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
      });
      const data = await res.json();
      if (!res.ok) {
        setImportError(data.error || "Import failed");
        setImportApplying(false);
        return;
      }
      setImportPreview(null);
      setImportSuccess(`Imported ${data.imported} slots (replaced ${data.deleted}).`);
      // Reload schedule
      const slotsRes = await fetch("/api/schedule");
      const slotsData = await slotsRes.json();
      setSlots(Array.isArray(slotsData) ? slotsData : []);
    } catch {
      setImportError("Network error during import");
    }
    setImportApplying(false);
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

  // Which days to render in the grid
  const visibleDays = isMobile
    ? [selectedDay]
    : [0, 1, 2, 3, 4, 5, 6];

  // ── Slot renderer (shared between mobile and desktop) ──
  function renderSlot(slot: ScheduleSlot) {
    const startRow = timeToRow(slot.start_time);
    const endRow = endTimeToRow(slot.end_time);
    const height = (endRow - startRow) * ROW_HEIGHT;
    const displayName = slot.label || slot.cms_shows?.title || "Untitled";
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
          touchAction: "none",
        }}
        onMouseDown={(e) => handleSlotMouseDown(e, slot, "move")}
        onTouchStart={(e) => handleSlotTouchStart(e, slot)}
      >
        {/* Resize handle: top — desktop only */}
        <div
          className="absolute left-0 right-0 top-0 z-10 hidden h-2 cursor-n-resize opacity-0 transition-opacity hover:bg-charcoal/20 group-hover:opacity-100 md:block"
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

        {/* Resize handle: bottom — desktop only */}
        <div
          className="absolute bottom-0 left-0 right-0 z-10 hidden h-2 cursor-s-resize opacity-0 transition-opacity hover:bg-charcoal/20 group-hover:opacity-100 md:block"
          onMouseDown={(e) => {
            e.stopPropagation();
            handleSlotMouseDown(e, slot, "resize-bottom");
          }}
        />
      </div>
    );
  }

  return (
    <div className="relative select-none">
      {/* ── Confessor import button ── */}
      <div className="mb-4 flex items-center gap-3">
        <button
          onClick={handleConfessorPreview}
          disabled={importLoading}
          className="inline-flex items-center gap-2 border border-charcoal/20 bg-off-white px-4 py-2 text-sm font-medium text-charcoal hover:bg-charcoal/5 disabled:opacity-50"
        >
          <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5m-13.5-9L12 3m0 0l4.5 4.5M12 3v13.5" />
          </svg>
          {importLoading ? "Fetching..." : "Import from Confessor"}
        </button>
        {importSuccess && (
          <span className="text-sm text-green-700">{importSuccess}</span>
        )}
      </div>

      {/* ── Confessor preview modal ── */}
      {importPreview && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-charcoal/50 p-4"
          onClick={() => { setImportPreview(null); setImportError(""); }}
        >
          <div
            className="max-h-[90vh] w-full max-w-2xl overflow-y-auto border border-charcoal/20 bg-off-white p-5 shadow-xl sm:p-6"
            onClick={(e) => e.stopPropagation()}
          >
            <h3 className="font-serif text-lg font-bold text-charcoal">
              Import Schedule from Confessor
            </h3>
            <p className="mt-1 text-sm text-charcoal/50">
              This will <strong>replace all {importPreview.current_count} recurring slots</strong> with{" "}
              <strong>{importPreview.incoming_count} slots</strong> from Confessor.
            </p>

            {/* Unmatched shows warning */}
            {importPreview.unmatched_shows.length > 0 && (
              <div className="mt-4 border border-amber-300 bg-amber-50 p-3">
                <p className="text-sm font-medium text-amber-800">
                  {importPreview.unmatched_shows.length} show{importPreview.unmatched_shows.length > 1 ? "s" : ""} not matched to CMS
                </p>
                <p className="mt-1 text-xs text-amber-700">
                  These will be imported with a label but no linked show page.
                  Set <code className="rounded bg-amber-100 px-1">program_slug</code> on the CMS show to match.
                </p>
                <ul className="mt-2 space-y-0.5 text-xs text-amber-800">
                  {importPreview.unmatched_shows.map((s) => (
                    <li key={s.altid}>
                      <code className="rounded bg-amber-100 px-1">{s.altid}</code>{" "}
                      &mdash; {s.name}
                    </li>
                  ))}
                </ul>
              </div>
            )}

            {/* Preview grid */}
            <div className="mt-4 max-h-[50vh] overflow-y-auto border border-charcoal/10">
              <table className="w-full text-xs">
                <thead className="sticky top-0 bg-charcoal/5">
                  <tr>
                    <th className="px-2 py-1.5 text-left font-medium text-charcoal/60">Day</th>
                    <th className="px-2 py-1.5 text-left font-medium text-charcoal/60">Time</th>
                    <th className="px-2 py-1.5 text-left font-medium text-charcoal/60">Show</th>
                    <th className="px-2 py-1.5 text-left font-medium text-charcoal/60">Host</th>
                    <th className="px-2 py-1.5 text-left font-medium text-charcoal/60">Match</th>
                  </tr>
                </thead>
                <tbody>
                  {importPreview.incoming
                    .sort((a, b) => a.day_of_week - b.day_of_week || a.start_time.localeCompare(b.start_time))
                    .map((slot, i) => (
                      <tr key={i} className={`border-t border-charcoal/5 ${!slot.matched_show_id ? "bg-amber-50/50" : ""}`}>
                        <td className="px-2 py-1.5 text-charcoal/70">{DAY_NAMES_SHORT[slot.day_of_week]}</td>
                        <td className="px-2 py-1.5 font-mono text-charcoal/60">
                          {formatTime12(slot.start_time)}&ndash;{formatTime12(slot.end_time)}
                        </td>
                        <td className="px-2 py-1.5 font-medium text-charcoal">{slot.show_name}</td>
                        <td className="px-2 py-1.5 text-charcoal/50">{slot.host_name || "\u2014"}</td>
                        <td className="px-2 py-1.5">
                          {slot.matched_show_id ? (
                            <span className="text-green-700">{slot.matched_show_title}</span>
                          ) : (
                            <span className="text-amber-600">unmatched</span>
                          )}
                        </td>
                      </tr>
                    ))}
                </tbody>
              </table>
            </div>

            {importError && (
              <p className="mt-3 text-sm text-kpfk-red">{importError}</p>
            )}

            <div className="mt-5 flex items-center gap-3">
              <button
                onClick={handleConfessorApply}
                disabled={importApplying}
                className="border-2 border-kpfk-red bg-kpfk-red px-5 py-2.5 text-sm font-medium text-off-white hover:bg-kpfk-red/90 disabled:opacity-50"
              >
                {importApplying ? "Importing..." : `Replace ${importPreview.current_count} slots with ${importPreview.incoming_count}`}
              </button>
              <button
                onClick={() => { setImportPreview(null); setImportError(""); }}
                className="px-4 py-2.5 text-sm text-charcoal/60 hover:text-charcoal"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Mobile day switcher ── */}
      {isMobile && (
        <div className="mb-3 flex gap-1">
          {DAY_NAMES_SHORT.map((name, i) => (
            <button
              key={i}
              onClick={() => setSelectedDay(i)}
              className={`flex-1 py-2 text-center text-xs font-bold uppercase tracking-wider ${
                i === selectedDay
                  ? "bg-charcoal text-off-white"
                  : "bg-charcoal/5 text-charcoal/50 active:bg-charcoal/10"
              }`}
            >
              {name}
            </button>
          ))}
        </div>
      )}

      <div
        ref={scrollContainerRef}
        className="overflow-y-auto border border-charcoal/20"
        style={{ maxHeight: "calc(100vh - 220px)" }}
      >
        {/* Day headers — sticky, desktop only */}
        {!isMobile && (
          <div className="sticky top-0 z-30 flex border-b border-charcoal/20 bg-off-white">
            <div className="w-14 flex-shrink-0" />
            {DAY_NAMES_SHORT.map((name, i) => (
              <div
                key={i}
                className={`min-w-[100px] flex-1 py-2 text-center text-xs font-bold uppercase tracking-wider text-charcoal/60 ${
                  i < 6 ? "border-r border-charcoal/10" : ""
                }`}
              >
                {name}
              </div>
            ))}
          </div>
        )}

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
            {visibleDays.map((dayIndex, colIdx) => (
              <div
                key={dayIndex}
                className={`relative flex-1 cursor-pointer ${
                  !isMobile ? "min-w-[100px]" : ""
                } ${
                  !isMobile && colIdx < visibleDays.length - 1
                    ? "border-r border-charcoal/10"
                    : ""
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
                  .map(renderSlot)}

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
          className="fixed inset-0 z-50 flex items-center justify-center bg-charcoal/50 p-4"
          onClick={() => {
            setModal(null);
            setError("");
          }}
        >
          <div
            className="max-h-[90vh] w-full max-w-md overflow-y-auto border border-charcoal/20 bg-off-white p-5 shadow-xl sm:p-6"
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
                  Show <span className="text-kpfk-red">*</span>
                </label>
                <ShowCombobox
                  shows={shows}
                  value={modal.showId}
                  onChange={(id) =>
                    setModal((prev) =>
                      prev ? { ...prev, showId: id } : null
                    )
                  }
                />
              </div>

              {/* Times */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="mb-1 block text-xs font-medium text-charcoal/60">
                    Start
                  </label>
                  <TimePicker
                    label="Start"
                    value={modal.startTime}
                    onChange={(t) =>
                      setModal((prev) =>
                        prev ? { ...prev, startTime: t } : null
                      )
                    }
                  />
                </div>
                <div>
                  <label className="mb-1 block text-xs font-medium text-charcoal/60">
                    End
                  </label>
                  <TimePicker
                    label="End"
                    value={modal.endTime}
                    onChange={(t) =>
                      setModal((prev) =>
                        prev ? { ...prev, endTime: t } : null
                      )
                    }
                  />
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
                  className="block w-full border border-charcoal/20 bg-off-white px-3 py-2.5 text-sm"
                />
              </div>

              {/* Day of week — button group */}
              <div>
                <label className="mb-1 block text-xs font-medium text-charcoal/60">
                  Day
                </label>
                <div className="flex gap-1">
                  {DAY_NAMES_SHORT.map((name, i) => (
                    <button
                      key={i}
                      type="button"
                      onClick={() =>
                        setModal((prev) =>
                          prev ? { ...prev, dayOfWeek: i } : null
                        )
                      }
                      className={`flex-1 rounded border py-2 text-center text-xs font-medium transition-colors ${
                        i === modal.dayOfWeek
                          ? "border-charcoal bg-charcoal text-off-white"
                          : "border-charcoal/20 bg-off-white text-charcoal/50 hover:border-charcoal/40 hover:text-charcoal"
                      }`}
                    >
                      {name}
                    </button>
                  ))}
                </div>
              </div>

              {/* Image path — for special programming art */}
              <div>
                <label className="mb-1 block text-xs font-medium text-charcoal/60">
                  Slot artwork{" "}
                  <span className="text-charcoal/30">(optional)</span>
                </label>
                <input
                  type="text"
                  value={modal.imagePath}
                  onChange={(e) =>
                    setModal((prev) =>
                      prev ? { ...prev, imagePath: e.target.value } : null
                    )
                  }
                  placeholder="e.g. schedule/special-programming.webp"
                  className="block w-full border border-charcoal/20 bg-off-white px-3 py-2.5 text-sm"
                />
                <p className="mt-1 text-[11px] text-charcoal/30">
                  Supabase Storage path. Media browser coming soon.
                </p>
              </div>
            </div>

            {error && (
              <p className="mt-3 text-sm text-kpfk-red">{error}</p>
            )}

            <div className="mt-6 flex items-center justify-between">
              <div className="flex gap-3">
                <button
                  onClick={handleModalSave}
                  disabled={saving}
                  className="border-2 border-charcoal bg-charcoal px-5 py-2.5 text-sm font-medium text-off-white hover:bg-charcoal/90 disabled:opacity-50"
                >
                  {saving ? "Saving..." : "Save"}
                </button>
                <button
                  onClick={() => {
                    setModal(null);
                    setError("");
                  }}
                  className="px-4 py-2.5 text-sm text-charcoal/60 hover:text-charcoal"
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
