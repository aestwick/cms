"use client";

import { useEffect, useState } from "react";

interface Show {
  id: string;
  title: string;
  slug: string;
}

interface ScheduleSlot {
  id: string;
  show_id: string | null;
  day_of_week: number;
  start_time: string;
  end_time: string;
  label: string | null;
  is_recurring: boolean;
  cms_shows: Show | null;
}

const DAY_NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

function formatTime(t: string) {
  const [h, m] = t.split(":");
  const hour = parseInt(h);
  const ampm = hour >= 12 ? "PM" : "AM";
  const h12 = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
  return `${h12}:${m} ${ampm}`;
}

export function ScheduleEditor() {
  const [slots, setSlots] = useState<ScheduleSlot[]>([]);
  const [shows, setShows] = useState<Show[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingSlot, setEditingSlot] = useState<Partial<ScheduleSlot> | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

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

  function startNew() {
    setEditingSlot({
      day_of_week: 0,
      start_time: "00:00",
      end_time: "01:00",
      show_id: null,
      label: "",
      is_recurring: true,
    });
    setError("");
  }

  function startEdit(slot: ScheduleSlot) {
    setEditingSlot({ ...slot });
    setError("");
  }

  async function handleSave() {
    if (!editingSlot) return;
    setSaving(true);
    setError("");

    const isNew = !editingSlot.id;
    const url = isNew ? "/api/schedule" : `/api/schedule/${editingSlot.id}`;
    const method = isNew ? "POST" : "PATCH";

    const res = await fetch(url, {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        show_id: editingSlot.show_id || null,
        day_of_week: editingSlot.day_of_week,
        start_time: editingSlot.start_time,
        end_time: editingSlot.end_time,
        label: editingSlot.label || null,
        is_recurring: editingSlot.is_recurring ?? true,
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
    setEditingSlot(null);
  }

  async function handleDelete(id: string) {
    const res = await fetch(`/api/schedule/${id}`, { method: "DELETE" });
    if (res.ok) {
      setSlots((prev) => prev.filter((s) => s.id !== id));
    }
  }

  if (loading) {
    return <p className="text-sm text-charcoal/50">Loading schedule...</p>;
  }

  // Group slots by day
  const slotsByDay: Record<number, ScheduleSlot[]> = {};
  for (let d = 0; d < 7; d++) slotsByDay[d] = [];
  for (const slot of slots) {
    (slotsByDay[slot.day_of_week] ??= []).push(slot);
  }

  return (
    <div>
      <button
        onClick={startNew}
        className="border-2 border-charcoal bg-charcoal px-4 py-2 text-sm font-medium text-off-white hover:bg-charcoal/90"
      >
        Add Slot
      </button>

      {/* Slot editor modal */}
      {editingSlot && (
        <div className="mt-4 border border-charcoal/20 bg-off-white p-5">
          <h3 className="text-sm font-bold text-charcoal">
            {editingSlot.id ? "Edit Slot" : "New Slot"}
          </h3>
          <div className="mt-3 grid grid-cols-1 gap-3 sm:grid-cols-4">
            <div>
              <label className="block text-xs font-medium text-charcoal/60">Day</label>
              <select
                value={editingSlot.day_of_week}
                onChange={(e) =>
                  setEditingSlot((prev) => ({
                    ...prev,
                    day_of_week: parseInt(e.target.value),
                  }))
                }
                className="mt-1 block w-full border border-charcoal/20 bg-off-white px-2 py-1.5 text-sm"
              >
                {DAY_NAMES.map((name, i) => (
                  <option key={i} value={i}>
                    {name}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-charcoal/60">Start</label>
              <input
                type="time"
                value={editingSlot.start_time || ""}
                onChange={(e) =>
                  setEditingSlot((prev) => ({ ...prev, start_time: e.target.value }))
                }
                className="mt-1 block w-full border border-charcoal/20 bg-off-white px-2 py-1.5 text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-charcoal/60">End</label>
              <input
                type="time"
                value={editingSlot.end_time || ""}
                onChange={(e) =>
                  setEditingSlot((prev) => ({ ...prev, end_time: e.target.value }))
                }
                className="mt-1 block w-full border border-charcoal/20 bg-off-white px-2 py-1.5 text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-charcoal/60">Show</label>
              <select
                value={editingSlot.show_id || ""}
                onChange={(e) =>
                  setEditingSlot((prev) => ({
                    ...prev,
                    show_id: e.target.value || null,
                  }))
                }
                className="mt-1 block w-full border border-charcoal/20 bg-off-white px-2 py-1.5 text-sm"
              >
                <option value="">— No show —</option>
                {shows.map((show) => (
                  <option key={show.id} value={show.id}>
                    {show.title}
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div className="mt-3">
            <label className="block text-xs font-medium text-charcoal/60">
              Label override (optional)
            </label>
            <input
              type="text"
              value={editingSlot.label || ""}
              onChange={(e) =>
                setEditingSlot((prev) => ({ ...prev, label: e.target.value }))
              }
              placeholder="Custom display name for this slot"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-2 py-1.5 text-sm"
            />
          </div>
          {error && <p className="mt-2 text-sm text-kpfk-red">{error}</p>}
          <div className="mt-4 flex items-center gap-3">
            <button
              onClick={handleSave}
              disabled={saving}
              className="border-2 border-charcoal bg-charcoal px-4 py-1.5 text-sm font-medium text-off-white hover:bg-charcoal/90 disabled:opacity-50"
            >
              {saving ? "Saving..." : "Save"}
            </button>
            <button
              onClick={() => setEditingSlot(null)}
              className="px-3 py-1.5 text-sm text-charcoal/60 hover:text-charcoal"
            >
              Cancel
            </button>
          </div>
        </div>
      )}

      {/* Weekly grid */}
      <div className="mt-6 space-y-6">
        {DAY_NAMES.map((dayName, dayIndex) => (
          <div key={dayIndex}>
            <h3 className="border-b border-charcoal/10 pb-1 text-sm font-bold uppercase tracking-wider text-charcoal/40">
              {dayName}
            </h3>
            {slotsByDay[dayIndex].length === 0 ? (
              <p className="mt-2 text-xs text-charcoal/30">No slots</p>
            ) : (
              <div className="mt-2 space-y-1">
                {slotsByDay[dayIndex]
                  .sort((a, b) => a.start_time.localeCompare(b.start_time))
                  .map((slot) => (
                    <div
                      key={slot.id}
                      className="flex items-center justify-between border border-charcoal/10 px-3 py-2"
                    >
                      <div className="flex items-center gap-3">
                        <span className="w-32 font-mono text-xs text-charcoal/50">
                          {formatTime(slot.start_time)}–{formatTime(slot.end_time)}
                        </span>
                        <span className="text-sm font-medium text-charcoal">
                          {slot.label || slot.cms_shows?.title || "—"}
                        </span>
                        {slot.cms_shows && !slot.label && (
                          <span className="font-mono text-[10px] text-charcoal/30">
                            {slot.cms_shows.slug}
                          </span>
                        )}
                      </div>
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => startEdit(slot)}
                          className="text-xs text-charcoal/40 hover:text-charcoal"
                        >
                          Edit
                        </button>
                        <button
                          onClick={() => handleDelete(slot.id)}
                          className="text-xs text-kpfk-red/50 hover:text-kpfk-red"
                        >
                          Delete
                        </button>
                      </div>
                    </div>
                  ))}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
