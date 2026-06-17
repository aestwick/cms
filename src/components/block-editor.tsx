"use client";

import { useState } from "react";
import {
  BLOCK_TYPES,
  BLOCK_LABELS,
  newBlock,
  type Block,
  type BlockType,
} from "@/lib/blocks";

// Authoring UI for a block body. Controlled: receives blocks + onChange and
// emits the full updated array. Each block type gets the inputs for its key
// fields; the output is the canonical JSON consumed by BlockRenderer and the
// podcast app. List-ish fields (items, tracks, columns) edit as one-per-line
// text for speed — kept faithful enough without a full drag-drop builder.

const lbl = "text-[11px] font-extrabold uppercase tracking-[0.12em] text-charcoal/60";
const input =
  "w-full border border-charcoal/20 bg-white px-3 py-2 text-sm focus:border-kpfk-red focus:outline-none";

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className={lbl}>{label}</span>
      <div className="mt-1">{children}</div>
    </label>
  );
}

export function BlockEditor({
  blocks,
  onChange,
}: {
  blocks: Block[];
  onChange: (blocks: Block[]) => void;
}) {
  const [adding, setAdding] = useState(false);

  function patch(id: string, fields: Partial<Block>) {
    onChange(blocks.map((b) => (b.id === id ? ({ ...b, ...fields } as Block) : b)));
  }
  function add(type: BlockType) {
    onChange([...blocks, newBlock(type)]);
    setAdding(false);
  }
  function remove(id: string) {
    onChange(blocks.filter((b) => b.id !== id));
  }
  function move(id: string, dir: -1 | 1) {
    const i = blocks.findIndex((b) => b.id === id);
    const j = i + dir;
    if (i < 0 || j < 0 || j >= blocks.length) return;
    const next = [...blocks];
    [next[i], next[j]] = [next[j], next[i]];
    onChange(next);
  }

  return (
    <div className="space-y-3">
      {blocks.map((b, i) => (
        <div key={b.id} className="border border-charcoal/15 bg-paper/40">
          <div className="flex items-center justify-between border-b border-charcoal/10 bg-charcoal/[0.03] px-3 py-1.5">
            <span className={lbl}>{BLOCK_LABELS[b.type]}</span>
            <div className="flex items-center gap-1 text-charcoal/50">
              <button type="button" onClick={() => move(b.id, -1)} disabled={i === 0} className="px-1.5 disabled:opacity-30" aria-label="Move up">↑</button>
              <button type="button" onClick={() => move(b.id, 1)} disabled={i === blocks.length - 1} className="px-1.5 disabled:opacity-30" aria-label="Move down">↓</button>
              <button type="button" onClick={() => remove(b.id)} className="px-1.5 text-kpfk-red" aria-label="Delete block">✕</button>
            </div>
          </div>
          <div className="space-y-3 p-3">
            <BlockFields block={b} patch={(f) => patch(b.id, f)} />
          </div>
        </div>
      ))}

      <div className="relative">
        <button
          type="button"
          onClick={() => setAdding((v) => !v)}
          className="w-full border-2 border-dashed border-charcoal/20 bg-paper py-3 text-xs font-extrabold uppercase tracking-[0.12em] text-kpfk-red"
        >
          + Add block
        </button>
        {adding && (
          <div className="absolute z-10 mt-1 grid w-full grid-cols-2 gap-1 border border-charcoal/20 bg-white p-2 shadow-sm sm:grid-cols-3">
            {BLOCK_TYPES.map((t) => (
              <button
                key={t}
                type="button"
                onClick={() => add(t)}
                className="px-2 py-1.5 text-left text-sm hover:bg-kpfk-red hover:text-white"
              >
                {BLOCK_LABELS[t]}
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

// Per-line helpers for list-shaped fields.
const linesToArr = (s: string) => s.split("\n").map((x) => x.trim()).filter(Boolean);
const arrToLines = (a: string[]) => a.join("\n");

function BlockFields({ block, patch }: { block: Block; patch: (f: Partial<Block>) => void }) {
  switch (block.type) {
    case "text":
      return (
        <Field label="Text (HTML allowed)">
          <textarea className={input} rows={4} value={block.html} onChange={(e) => patch({ html: e.target.value })} />
        </Field>
      );
    case "subhead":
      return (
        <div className="flex gap-3">
          <div className="flex-1"><Field label="Subhead"><input className={input} value={block.text} onChange={(e) => patch({ text: e.target.value })} /></Field></div>
          <Field label="Level">
            <select className={input} value={block.level} onChange={(e) => patch({ level: Number(e.target.value) === 3 ? 3 : 2 })}>
              <option value={2}>H2</option><option value={3}>H3</option>
            </select>
          </Field>
        </div>
      );
    case "key_takeaways":
      return <Field label="Takeaways (one per line)"><textarea className={input} rows={3} value={arrToLines(block.items)} onChange={(e) => patch({ items: linesToArr(e.target.value) })} /></Field>;
    case "pull_quote":
      return (
        <>
          <Field label="Quote"><textarea className={input} rows={2} value={block.quote} onChange={(e) => patch({ quote: e.target.value })} /></Field>
          <Field label="Attribution"><input className={input} value={block.attribution ?? ""} onChange={(e) => patch({ attribution: e.target.value || null })} /></Field>
        </>
      );
    case "take_action":
      return (
        <>
          <Field label="Heading"><input className={input} value={block.heading} onChange={(e) => patch({ heading: e.target.value })} /></Field>
          <Field label="Body"><textarea className={input} rows={2} value={block.body ?? ""} onChange={(e) => patch({ body: e.target.value || null })} /></Field>
          <div className="flex gap-3">
            <div className="flex-1"><Field label="CTA label"><input className={input} value={block.cta_label ?? ""} onChange={(e) => patch({ cta_label: e.target.value || null })} /></Field></div>
            <div className="flex-1"><Field label="CTA URL"><input className={input} value={block.cta_url ?? ""} onChange={(e) => patch({ cta_url: e.target.value || null })} /></Field></div>
          </div>
        </>
      );
    case "correction":
      return (
        <>
          <Field label="Correction"><textarea className={input} rows={2} value={block.text} onChange={(e) => patch({ text: e.target.value })} /></Field>
          <Field label="Dated"><input className={input} type="date" value={block.dated_at ?? ""} onChange={(e) => patch({ dated_at: e.target.value || null })} /></Field>
        </>
      );
    case "lee_en_espanol":
      return (
        <>
          <Field label="Link text"><input className={input} value={block.text ?? ""} onChange={(e) => patch({ text: e.target.value || null })} /></Field>
          <Field label="URL"><input className={input} value={block.url ?? ""} onChange={(e) => patch({ url: e.target.value || null })} /></Field>
        </>
      );
    case "links_resources":
      return <Field label="Links — &quot;Label | https://url&quot; per line"><textarea className={input} rows={3} value={block.items.map((l) => `${l.label} | ${l.url}`).join("\n")} onChange={(e) => patch({ items: linesToArr(e.target.value).map((line) => { const [label, url] = line.split("|").map((s) => s.trim()); return { label: label || url || "", url: url || label || "" }; }) })} /></Field>;
    case "audio_clip":
      return (
        <>
          <Field label="Label"><input className={input} value={block.label ?? ""} onChange={(e) => patch({ label: e.target.value || null })} /></Field>
          <Field label="Audio src (path or URL)"><input className={input} value={block.src ?? ""} onChange={(e) => patch({ src: e.target.value || null })} /></Field>
        </>
      );
    case "tracklist":
      return <Field label="Tracks — &quot;time | title | artist | label&quot; per line"><textarea className={input} rows={4} value={block.items.map((t) => [t.time ?? "", t.title, t.artist ?? "", t.label ?? ""].join(" | ")).join("\n")} onChange={(e) => patch({ items: linesToArr(e.target.value).map((line) => { const [time, title, artist, label] = line.split("|").map((s) => s.trim()); return { time: time || null, title: title || "", artist: artist || null, label: label || null }; }).filter((t) => t.title) })} /></Field>;
    case "guest_card":
      return (
        <>
          <div className="flex gap-3">
            <div className="flex-1"><Field label="Name"><input className={input} value={block.name} onChange={(e) => patch({ name: e.target.value })} /></Field></div>
            <div className="flex-1"><Field label="Role"><input className={input} value={block.role ?? ""} onChange={(e) => patch({ role: e.target.value || null })} /></Field></div>
          </div>
          <Field label="Bio"><textarea className={input} rows={2} value={block.bio ?? ""} onChange={(e) => patch({ bio: e.target.value || null })} /></Field>
          <div className="flex gap-3">
            <div className="flex-1"><Field label="Image path"><input className={input} value={block.image_path ?? ""} onChange={(e) => patch({ image_path: e.target.value || null })} /></Field></div>
            <div className="flex-1"><Field label="Link URL"><input className={input} value={block.link_url ?? ""} onChange={(e) => patch({ link_url: e.target.value || null })} /></Field></div>
          </div>
        </>
      );
    case "data_table":
      return (
        <>
          <Field label="Columns (comma-separated)"><input className={input} value={block.columns.join(", ")} onChange={(e) => patch({ columns: e.target.value.split(",").map((s) => s.trim()).filter(Boolean) })} /></Field>
          <Field label="Rows — cells comma-separated, one row per line"><textarea className={input} rows={3} value={block.rows.map((r) => r.join(", ")).join("\n")} onChange={(e) => patch({ rows: linesToArr(e.target.value).map((line) => line.split(",").map((s) => s.trim())) })} /></Field>
          <Field label="Caption"><input className={input} value={block.caption ?? ""} onChange={(e) => patch({ caption: e.target.value || null })} /></Field>
        </>
      );
    case "image":
      return (
        <>
          <Field label="Image path"><input className={input} value={block.image_path} onChange={(e) => patch({ image_path: e.target.value })} /></Field>
          <div className="flex gap-3">
            <div className="flex-1"><Field label="Alt text"><input className={input} value={block.alt ?? ""} onChange={(e) => patch({ alt: e.target.value || null })} /></Field></div>
            <div className="flex-1"><Field label="Caption"><input className={input} value={block.caption ?? ""} onChange={(e) => patch({ caption: e.target.value || null })} /></Field></div>
          </div>
        </>
      );
    case "gallery":
      return <Field label="Image paths (one per line)"><textarea className={input} rows={3} value={block.images.map((g) => g.image_path).join("\n")} onChange={(e) => patch({ images: linesToArr(e.target.value).map((p) => ({ image_path: p, alt: null, caption: null })) })} /></Field>;
    case "video_embed":
      return (
        <>
          <Field label="Embed URL"><input className={input} value={block.url} onChange={(e) => patch({ url: e.target.value })} /></Field>
          <Field label="Caption"><input className={input} value={block.caption ?? ""} onChange={(e) => patch({ caption: e.target.value || null })} /></Field>
        </>
      );
    case "event_card":
      return (
        <>
          <Field label="Title"><input className={input} value={block.title} onChange={(e) => patch({ title: e.target.value })} /></Field>
          <div className="flex gap-3">
            <div className="flex-1"><Field label="Starts at"><input className={input} type="datetime-local" value={block.starts_at ?? ""} onChange={(e) => patch({ starts_at: e.target.value || null })} /></Field></div>
            <div className="flex-1"><Field label="Venue"><input className={input} value={block.venue ?? ""} onChange={(e) => patch({ venue: e.target.value || null })} /></Field></div>
          </div>
          <Field label="URL"><input className={input} value={block.url ?? ""} onChange={(e) => patch({ url: e.target.value || null })} /></Field>
        </>
      );
    default:
      return null;
  }
}
