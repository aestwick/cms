"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export type EventCategory =
  | "community"
  | "sponsored"
  | "fundraising"
  | "meeting"
  | "protest"
  | "other";

export interface EventFormData {
  title: string;
  slug: string;
  description: string;
  category: EventCategory;
  venue_name: string;
  venue_address: string;
  event_url: string;
  image_path: string;
  price_text: string;
  starts_at: string;
  ends_at: string;
  is_all_day: boolean;
  is_highlighted: boolean;
}

const emptyEvent: EventFormData = {
  title: "",
  slug: "",
  description: "",
  category: "community",
  venue_name: "",
  venue_address: "",
  event_url: "",
  image_path: "",
  price_text: "",
  starts_at: "",
  ends_at: "",
  is_all_day: false,
  is_highlighted: false,
};

const categoryLabels: Record<EventCategory, string> = {
  community: "Community",
  sponsored: "Sponsored",
  fundraising: "Fundraising",
  meeting: "Meeting",
  protest: "Protest",
  other: "Other",
};

interface EventFormProps {
  initialData?: Partial<EventFormData>;
  eventId?: string;
  mode: "create" | "edit";
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

export function EventForm({ initialData, eventId, mode }: EventFormProps) {
  const router = useRouter();
  const [form, setForm] = useState<EventFormData>({
    ...emptyEvent,
    ...initialData,
  });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [slugManual, setSlugManual] = useState(mode === "edit");

  function updateField<K extends keyof EventFormData>(
    key: K,
    value: EventFormData[K]
  ) {
    setForm((prev) => ({ ...prev, [key]: value }));
  }

  function handleTitleChange(title: string) {
    updateField("title", title);
    if (!slugManual) {
      updateField("slug", slugify(title));
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError("");

    const url =
      mode === "create" ? "/api/events" : `/api/events/${eventId}`;
    const method = mode === "create" ? "POST" : "PATCH";

    const payload = {
      ...form,
      starts_at: form.starts_at ? new Date(form.starts_at).toISOString() : null,
      ends_at: form.ends_at ? new Date(form.ends_at).toISOString() : null,
    };

    const res = await fetch(url, {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    const data = await res.json();
    setSaving(false);

    if (!res.ok) {
      setError(data.error || "Something went wrong");
      return;
    }

    router.push("/admin/events");
    router.refresh();
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-8">
      {/* === Core Info === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Event Info</h2>
        <div className="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
          <div className="md:col-span-2">
            <label className="block text-sm font-medium text-charcoal">
              Title <span className="text-kpfk-red">*</span>
            </label>
            <input
              type="text"
              required
              value={form.title}
              onChange={(e) => handleTitleChange(e.target.value)}
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Slug <span className="text-kpfk-red">*</span>
            </label>
            <div className="mt-1 flex items-center gap-2">
              <span className="font-mono text-xs text-charcoal/40">
                /events/
              </span>
              <input
                type="text"
                required
                pattern="[a-z0-9-]+"
                value={form.slug}
                onChange={(e) => {
                  setSlugManual(true);
                  updateField("slug", e.target.value);
                }}
                className="block flex-1 border border-charcoal/20 bg-off-white px-3 py-2 font-mono text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
              />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Category
            </label>
            <select
              value={form.category}
              onChange={(e) =>
                updateField("category", e.target.value as EventCategory)
              }
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
            >
              {Object.entries(categoryLabels).map(([value, label]) => (
                <option key={value} value={value}>
                  {label}
                </option>
              ))}
            </select>
          </div>
        </div>
      </section>

      {/* === Date & Time === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Date &amp; Time</h2>
        <div className="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Starts at <span className="text-kpfk-red">*</span>
            </label>
            <input
              type="datetime-local"
              required
              value={form.starts_at}
              onChange={(e) => updateField("starts_at", e.target.value)}
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Ends at
            </label>
            <input
              type="datetime-local"
              value={form.ends_at}
              onChange={(e) => updateField("ends_at", e.target.value)}
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
            />
          </div>
          <div className="flex items-center gap-3">
            <input
              id="is_all_day"
              type="checkbox"
              checked={form.is_all_day}
              onChange={(e) => updateField("is_all_day", e.target.checked)}
              className="h-4 w-4 accent-charcoal"
            />
            <label htmlFor="is_all_day" className="text-sm text-charcoal">
              All-day event
            </label>
          </div>
        </div>
      </section>

      {/* === Description === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Description</h2>
        <div className="mt-4">
          <textarea
            value={form.description}
            onChange={(e) => updateField("description", e.target.value)}
            rows={6}
            placeholder="Event description — displayed on the event detail page"
            className="block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
          />
          <p className="mt-1 text-xs text-charcoal/40">
            HTML supported. Rich text editor coming in a future phase.
          </p>
        </div>
      </section>

      {/* === Venue === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Venue</h2>
        <div className="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Venue Name
            </label>
            <input
              type="text"
              value={form.venue_name}
              onChange={(e) => updateField("venue_name", e.target.value)}
              placeholder="e.g. KPFK Studios"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Venue Address
            </label>
            <input
              type="text"
              value={form.venue_address}
              onChange={(e) => updateField("venue_address", e.target.value)}
              placeholder="3729 Cahuenga Blvd W, Los Angeles, CA"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
            />
          </div>
        </div>
      </section>

      {/* === Links & Media === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Links &amp; Media</h2>
        <div className="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Event URL
            </label>
            <input
              type="url"
              value={form.event_url}
              onChange={(e) => updateField("event_url", e.target.value)}
              placeholder="https://example.com/event"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Price
            </label>
            <input
              type="text"
              value={form.price_text}
              onChange={(e) => updateField("price_text", e.target.value)}
              placeholder="Free, $10, Sliding scale $5-$25"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
            />
          </div>
          <div className="md:col-span-2">
            <label className="block text-sm font-medium text-charcoal">
              Image Path
            </label>
            <input
              type="text"
              value={form.image_path}
              onChange={(e) => updateField("image_path", e.target.value)}
              placeholder="events/community-fair-2026.webp"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 font-mono text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
            />
          </div>
        </div>
      </section>

      {/* === Settings === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Settings</h2>
        <div className="mt-4">
          <div className="flex items-center gap-3">
            <input
              id="is_highlighted"
              type="checkbox"
              checked={form.is_highlighted}
              onChange={(e) =>
                updateField("is_highlighted", e.target.checked)
              }
              className="h-4 w-4 accent-charcoal"
            />
            <label htmlFor="is_highlighted" className="text-sm text-charcoal">
              Highlight on events page (featured event)
            </label>
          </div>
        </div>
      </section>

      {/* === Submit === */}
      {error && <p className="text-sm text-kpfk-red">{error}</p>}
      <div className="flex items-center gap-3 border-t border-charcoal/10 pt-6">
        <button
          type="submit"
          disabled={saving}
          className="border border-kpfk-red bg-kpfk-red px-6 py-2 text-sm font-extrabold uppercase tracking-[0.04em] text-white hover:bg-kpfk-red-press disabled:opacity-50"
        >
          {saving
            ? "Saving\u2026"
            : mode === "create"
              ? "Create event"
              : "Save changes"}
        </button>
        <button
          type="button"
          onClick={() => router.push("/admin/events")}
          className="px-4 py-2 text-sm text-charcoal/60 hover:text-charcoal"
        >
          Cancel
        </button>
      </div>
    </form>
  );
}
