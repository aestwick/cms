"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { BlockEditor } from "@/components/block-editor";
import { normalizeBlocks, type Block } from "@/lib/blocks";

export interface EpisodeFormData {
  title: string;
  description: string;
  body_blocks: Block[];
  transcript_url: string;
  is_published: boolean;
}

const emptyEpisode: EpisodeFormData = {
  title: "",
  description: "",
  body_blocks: [],
  transcript_url: "",
  is_published: true,
};

interface EpisodeFormProps {
  showId: string;
  programSlug: string;
  airDate: string; // YYYY-MM-DD
  showTitle: string;
  initialData?: Partial<EpisodeFormData>;
}

export function EpisodeForm({
  showId,
  programSlug,
  airDate,
  showTitle,
  initialData,
}: EpisodeFormProps) {
  const router = useRouter();
  const [form, setForm] = useState<EpisodeFormData>({
    ...emptyEpisode,
    ...initialData,
    // body_blocks arrives from the DB as raw JSONB — coerce to clean Blocks.
    body_blocks: normalizeBlocks(initialData?.body_blocks),
  });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  function updateField<K extends keyof EpisodeFormData>(key: K, value: EpisodeFormData[K]) {
    setForm((prev) => ({ ...prev, [key]: value }));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError("");

    // POST upserts on (station, program_slug, air_date) — one call handles
    // both first-time notes and edits.
    const res = await fetch("/api/episodes", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        show_id: showId,
        program_slug: programSlug,
        air_date: airDate,
        ...form,
      }),
    });

    const data = await res.json();
    setSaving(false);

    if (!res.ok) {
      setError(data.error || "Something went wrong");
      return;
    }

    router.push(`/admin/shows/${showId}/episodes`);
    router.refresh();
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-8">
      {/* === Episode Info === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Episode Notes</h2>
        <p className="mt-1 text-xs text-charcoal/40">
          {showTitle} · air date{" "}
          <span className="font-mono">{airDate}</span>. Audio and air date come
          from Confessor; these notes are stored by the CMS and joined at display
          time.
        </p>
        <div className="mt-4 space-y-4">
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Episode title (optional)
            </label>
            <input
              type="text"
              value={form.title}
              onChange={(e) => updateField("title", e.target.value)}
              placeholder="Falls back to the Confessor title if left empty"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Description / summary
            </label>
            <textarea
              value={form.description}
              onChange={(e) => updateField("description", e.target.value)}
              rows={3}
              placeholder="Short summary shown above the episode body."
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
            />
          </div>
        </div>
      </section>

      {/* === Show notes (blocks) === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Show Notes</h2>
        <p className="mb-2 mt-1 text-xs text-charcoal/40">
          Build the episode page from blocks (guests, tracklist, links, pull
          quotes). Stored as structured JSON.
        </p>
        <BlockEditor
          blocks={form.body_blocks}
          onChange={(b) => updateField("body_blocks", b)}
        />
      </section>

      {/* === Transcript === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Transcript</h2>
        <div className="mt-4">
          <label className="block text-sm font-medium text-charcoal">
            Transcript URL (optional)
          </label>
          <input
            type="url"
            value={form.transcript_url}
            onChange={(e) => updateField("transcript_url", e.target.value)}
            placeholder="https://…"
            className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 font-mono text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
          />
          <p className="mt-1 text-xs text-charcoal/40">
            QIR transcript join coming in a later phase; for now, link out.
          </p>
        </div>
      </section>

      {/* === Publishing === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Publishing</h2>
        <div className="mt-4 flex items-center gap-3">
          <input
            id="is_published"
            type="checkbox"
            checked={form.is_published}
            onChange={(e) => updateField("is_published", e.target.checked)}
            className="h-4 w-4 accent-charcoal"
          />
          <label htmlFor="is_published" className="text-sm text-charcoal">
            Published (visible on the public episode page)
          </label>
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
          {saving ? "Saving…" : "Save episode notes"}
        </button>
        <button
          type="button"
          onClick={() => router.push(`/admin/shows/${showId}/episodes`)}
          className="px-4 py-2 text-sm text-charcoal/60 hover:text-charcoal"
        >
          Cancel
        </button>
      </div>
    </form>
  );
}
