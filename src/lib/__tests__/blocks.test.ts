import { describe, it, expect } from "vitest";
import {
  normalizeBlocks,
  blocksToPlainText,
  newBlock,
  BLOCK_TYPES,
  type Block,
} from "@/lib/blocks";

describe("normalizeBlocks", () => {
  it("parses a JSON string body", () => {
    const json = JSON.stringify([{ id: "x", type: "text", html: "<p>Hi</p>" }]);
    expect(normalizeBlocks(json)).toEqual([{ id: "x", type: "text", html: "<p>Hi</p>" }]);
  });

  it("returns [] for null, garbage, or invalid JSON", () => {
    expect(normalizeBlocks(null)).toEqual([]);
    expect(normalizeBlocks("{not json")).toEqual([]);
    expect(normalizeBlocks(42)).toEqual([]);
  });

  it("drops blocks with unknown types", () => {
    const out = normalizeBlocks([
      { type: "text", html: "ok" },
      { type: "pdf_embed", url: "x" }, // not in the schema
      { type: "subhead", text: "Heading" },
    ]);
    expect(out.map((b) => b.type)).toEqual(["text", "subhead"]);
  });

  it("generates an id when missing", () => {
    const [b] = normalizeBlocks([{ type: "text", html: "x" }]);
    expect(b.id).toMatch(/^b_/);
  });

  it("coerces missing/wrong fields to safe defaults", () => {
    const [b] = normalizeBlocks([{ type: "pull_quote", quote: 123 }]);
    expect(b).toMatchObject({ type: "pull_quote", quote: "", attribution: null });
  });

  it("filters incomplete list/track items", () => {
    const [links] = normalizeBlocks([
      { type: "links_resources", items: [{ label: "A", url: "/a" }, { label: "no url" }] },
    ]) as [Extract<Block, { type: "links_resources" }>];
    expect(links.items).toEqual([{ label: "A", url: "/a" }]);

    const [tl] = normalizeBlocks([
      { type: "tracklist", items: [{ title: "Song", artist: "X" }, { artist: "no title" }] },
    ]) as [Extract<Block, { type: "tracklist" }>];
    expect(tl.items).toHaveLength(1);
    expect(tl.items[0]).toMatchObject({ title: "Song", artist: "X", time: null, label: null });
  });

  it("normalizes a data_table's rows to string arrays", () => {
    const [t] = normalizeBlocks([
      { type: "data_table", columns: ["A", "B"], rows: [["1", "2"], "bad"] },
    ]) as [Extract<Block, { type: "data_table" }>];
    expect(t.columns).toEqual(["A", "B"]);
    expect(t.rows).toEqual([["1", "2"], []]);
  });
});

describe("newBlock", () => {
  it("produces a valid block for every type in the schema", () => {
    for (const type of BLOCK_TYPES) {
      const b = newBlock(type);
      expect(b.type).toBe(type);
      expect(b.id).toMatch(/^b_/);
      // round-trips through normalize unchanged in type
      expect(normalizeBlocks([b])[0].type).toBe(type);
    }
  });
});

describe("blocksToPlainText", () => {
  it("strips html and joins readable text across block types", () => {
    const blocks = normalizeBlocks([
      { type: "text", html: "<p>Hello <b>world</b></p>" },
      { type: "subhead", text: "A heading" },
      { type: "pull_quote", quote: "Quotable" },
      { type: "image", image_path: "/x.jpg", alt: "ignored" },
    ]);
    const text = blocksToPlainText(blocks);
    expect(text).toContain("Hello world");
    expect(text).toContain("A heading");
    expect(text).toContain("Quotable");
    expect(text).not.toContain("<");
  });
});
