// Canonical block schema for Story and Episode bodies.
//
// Bodies are stored as a JSONB array of typed blocks (cms_posts.body_blocks
// and cms_episode_metadata.body_blocks). This is a STABLE PUBLIC CONTRACT:
// external consumers — notably the podcast app pulling episode data — parse
// this JSON directly, so field names and the discriminated `type` tag must
// stay backward-compatible. Add new block types; don't rename fields.
//
// PDF/document embed is intentionally not here yet (design backlog).

export const BLOCK_SCHEMA_VERSION = 1;

export type BlockType =
  | "text"
  | "subhead"
  | "key_takeaways"
  | "pull_quote"
  | "take_action"
  | "correction"
  | "lee_en_espanol"
  | "links_resources"
  | "audio_clip"
  | "tracklist"
  | "guest_card"
  | "data_table"
  | "image"
  | "gallery"
  | "video_embed"
  | "event_card";

export const BLOCK_TYPES: BlockType[] = [
  "text",
  "subhead",
  "key_takeaways",
  "pull_quote",
  "take_action",
  "correction",
  "lee_en_espanol",
  "links_resources",
  "audio_clip",
  "tracklist",
  "guest_card",
  "data_table",
  "image",
  "gallery",
  "video_embed",
  "event_card",
];

// Human labels for the "+ Add block" menu, in the design's order.
export const BLOCK_LABELS: Record<BlockType, string> = {
  text: "Text",
  subhead: "Subhead",
  key_takeaways: "Key takeaways",
  pull_quote: "Pull quote",
  take_action: "Take action",
  correction: "Correction notice",
  lee_en_espanol: "Lee en español",
  links_resources: "Links & resources",
  audio_clip: "Audio pull-clip",
  tracklist: "Tracklist",
  guest_card: "Guest card",
  data_table: "Data table",
  image: "Image",
  gallery: "Gallery",
  video_embed: "Video embed",
  event_card: "Event card",
};

interface BlockBase {
  id: string;
  type: BlockType;
}

export interface TextBlock extends BlockBase { type: "text"; html: string }
export interface SubheadBlock extends BlockBase { type: "subhead"; text: string; level: 2 | 3 }
export interface KeyTakeawaysBlock extends BlockBase { type: "key_takeaways"; items: string[] }
export interface PullQuoteBlock extends BlockBase { type: "pull_quote"; quote: string; attribution: string | null }
export interface TakeActionBlock extends BlockBase { type: "take_action"; heading: string; body: string | null; cta_label: string | null; cta_url: string | null }
export interface CorrectionBlock extends BlockBase { type: "correction"; text: string; dated_at: string | null }
export interface LeeEnEspanolBlock extends BlockBase { type: "lee_en_espanol"; url: string | null; text: string | null }
export interface LinkItem { label: string; url: string }
export interface LinksResourcesBlock extends BlockBase { type: "links_resources"; items: LinkItem[] }
export interface AudioClipBlock extends BlockBase { type: "audio_clip"; src: string | null; label: string | null; start_seconds: number | null; end_seconds: number | null }
export interface Track { time: string | null; title: string; artist: string | null; label: string | null }
export interface TracklistBlock extends BlockBase { type: "tracklist"; items: Track[] }
export interface GuestCardBlock extends BlockBase { type: "guest_card"; name: string; role: string | null; bio: string | null; image_path: string | null; link_url: string | null }
export interface DataTableBlock extends BlockBase { type: "data_table"; columns: string[]; rows: string[][]; caption: string | null }
export interface MediaItem { image_path: string; alt: string | null; caption: string | null }
export interface ImageBlock extends BlockBase, MediaItem { type: "image" }
export interface GalleryBlock extends BlockBase { type: "gallery"; images: MediaItem[] }
export interface VideoEmbedBlock extends BlockBase { type: "video_embed"; url: string; provider: string | null; caption: string | null }
export interface EventCardBlock extends BlockBase { type: "event_card"; title: string; starts_at: string | null; venue: string | null; url: string | null; image_path: string | null }

export type Block =
  | TextBlock | SubheadBlock | KeyTakeawaysBlock | PullQuoteBlock | TakeActionBlock
  | CorrectionBlock | LeeEnEspanolBlock | LinksResourcesBlock | AudioClipBlock | TracklistBlock
  | GuestCardBlock | DataTableBlock | ImageBlock | GalleryBlock | VideoEmbedBlock | EventCardBlock;

function rid(): string {
  return "b_" + Math.random().toString(36).slice(2, 10);
}

const str = (v: unknown, fallback = ""): string => (typeof v === "string" ? v : fallback);
const strOrNull = (v: unknown): string | null => (typeof v === "string" && v !== "" ? v : null);
const numOrNull = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? v : null);
const strArray = (v: unknown): string[] => (Array.isArray(v) ? v.filter((x) => typeof x === "string") : []);

/** Coerce one raw object into a valid Block, or null if its type is unknown. */
function normalizeBlock(raw: unknown): Block | null {
  if (!raw || typeof raw !== "object") return null;
  const r = raw as Record<string, unknown>;
  const type = r.type as BlockType;
  if (!BLOCK_TYPES.includes(type)) return null;
  const id = str(r.id) || rid();

  switch (type) {
    case "text":
      return { id, type, html: str(r.html) };
    case "subhead":
      return { id, type, text: str(r.text), level: r.level === 3 ? 3 : 2 };
    case "key_takeaways":
      return { id, type, items: strArray(r.items) };
    case "pull_quote":
      return { id, type, quote: str(r.quote), attribution: strOrNull(r.attribution) };
    case "take_action":
      return { id, type, heading: str(r.heading), body: strOrNull(r.body), cta_label: strOrNull(r.cta_label), cta_url: strOrNull(r.cta_url) };
    case "correction":
      return { id, type, text: str(r.text), dated_at: strOrNull(r.dated_at) };
    case "lee_en_espanol":
      return { id, type, url: strOrNull(r.url), text: strOrNull(r.text) };
    case "links_resources":
      return { id, type, items: Array.isArray(r.items) ? (r.items as unknown[]).map((i) => { const o = (i ?? {}) as Record<string, unknown>; return { label: str(o.label), url: str(o.url) }; }).filter((i) => i.url) : [] };
    case "audio_clip":
      return { id, type, src: strOrNull(r.src), label: strOrNull(r.label), start_seconds: numOrNull(r.start_seconds), end_seconds: numOrNull(r.end_seconds) };
    case "tracklist":
      return { id, type, items: Array.isArray(r.items) ? (r.items as unknown[]).map((i) => { const o = (i ?? {}) as Record<string, unknown>; return { time: strOrNull(o.time), title: str(o.title), artist: strOrNull(o.artist), label: strOrNull(o.label) }; }).filter((i) => i.title) : [] };
    case "guest_card":
      return { id, type, name: str(r.name), role: strOrNull(r.role), bio: strOrNull(r.bio), image_path: strOrNull(r.image_path), link_url: strOrNull(r.link_url) };
    case "data_table":
      return { id, type, columns: strArray(r.columns), rows: Array.isArray(r.rows) ? (r.rows as unknown[]).map(strArray) : [], caption: strOrNull(r.caption) };
    case "image":
      return { id, type, image_path: str(r.image_path), alt: strOrNull(r.alt), caption: strOrNull(r.caption) };
    case "gallery":
      return { id, type, images: Array.isArray(r.images) ? (r.images as unknown[]).map((i) => { const o = (i ?? {}) as Record<string, unknown>; return { image_path: str(o.image_path), alt: strOrNull(o.alt), caption: strOrNull(o.caption) }; }).filter((i) => i.image_path) : [] };
    case "video_embed":
      return { id, type, url: str(r.url), provider: strOrNull(r.provider), caption: strOrNull(r.caption) };
    case "event_card":
      return { id, type, title: str(r.title), starts_at: strOrNull(r.starts_at), venue: strOrNull(r.venue), url: strOrNull(r.url), image_path: strOrNull(r.image_path) };
  }
}

/** Parse/validate a raw body (array, JSON string, or null) into clean blocks.
 * Unknown block types are dropped so bad data can never crash rendering. */
export function normalizeBlocks(raw: unknown): Block[] {
  let arr: unknown = raw;
  if (typeof raw === "string") {
    try { arr = JSON.parse(raw); } catch { return []; }
  }
  if (!Array.isArray(arr)) return [];
  return arr.map(normalizeBlock).filter((b): b is Block => b !== null);
}

/** Plain-text projection of a body — for excerpts, search, and as a clean
 * fallback for consumers that don't render rich blocks. */
export function blocksToPlainText(blocks: Block[]): string {
  const parts: string[] = [];
  for (const b of blocks) {
    switch (b.type) {
      case "text": parts.push(b.html.replace(/<[^>]*>/g, " ")); break;
      case "subhead": parts.push(b.text); break;
      case "key_takeaways": parts.push(b.items.join(". ")); break;
      case "pull_quote": parts.push(b.quote); break;
      case "take_action": parts.push([b.heading, b.body].filter(Boolean).join(". ")); break;
      case "correction": parts.push(b.text); break;
      case "guest_card": parts.push([b.name, b.bio].filter(Boolean).join(": ")); break;
      case "event_card": parts.push(b.title); break;
      default: break;
    }
  }
  return parts.join(" ").replace(/\s+/g, " ").trim();
}

/** A fresh, valid block of the given type for the editor's "+ Add block". */
export function newBlock(type: BlockType): Block {
  return normalizeBlock({ type })!;
}
