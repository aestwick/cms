import { describe, it, expect } from "vitest";
import {
  canEditShow,
  editableShowIds,
  HOST_EDITABLE_SHOW_FIELDS,
} from "@/lib/authz";
import type { CmsUser } from "@/lib/auth";

// Minimal chainable Supabase stub. `rows` is what the query resolves to;
// maybeSingle() yields the first row (or null), and awaiting the builder
// yields { data: rows }.
function mockSupabase(rows: Array<Record<string, unknown>>) {
  const builder: Record<string, unknown> = {
    select: () => builder,
    eq: () => builder,
    maybeSingle: () => Promise.resolve({ data: rows[0] ?? null }),
    then: (resolve: (v: { data: typeof rows }) => unknown) =>
      Promise.resolve({ data: rows }).then(resolve),
  };
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return { from: () => builder } as any;
}

function user(role: CmsUser["role"]): CmsUser {
  return {
    id: "u1",
    email: "h@example.com",
    role,
    station_id: "s1",
    display_name: null,
  };
}

describe("canEditShow", () => {
  it("admin and editor can edit any show without a DB lookup", async () => {
    // Pass a supabase that would throw if queried, to prove it's not used.
    const exploding = {
      from() {
        throw new Error("should not query for admin/editor");
      },
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } as any;
    expect(await canEditShow(exploding, user("admin"), "show1")).toBe(true);
    expect(await canEditShow(exploding, user("editor"), "show1")).toBe(true);
  });

  it("host can edit a show they are linked to", async () => {
    const sb = mockSupabase([{ id: "link1" }]);
    expect(await canEditShow(sb, user("host"), "show1")).toBe(true);
  });

  it("host cannot edit a show they are not linked to", async () => {
    const sb = mockSupabase([]);
    expect(await canEditShow(sb, user("host"), "show1")).toBe(false);
  });

  it("host cannot edit a station-wide (null show) record", async () => {
    const sb = mockSupabase([{ id: "link1" }]); // even if a link existed
    expect(await canEditShow(sb, user("host"), null)).toBe(false);
    expect(await canEditShow(sb, user("host"), undefined)).toBe(false);
  });

  it("admin can edit a null-show record", async () => {
    const sb = mockSupabase([]);
    expect(await canEditShow(sb, user("admin"), null)).toBe(true);
  });
});

describe("editableShowIds", () => {
  it("returns null (no restriction) for admin and editor", async () => {
    const sb = mockSupabase([]);
    expect(await editableShowIds(sb, user("admin"))).toBeNull();
    expect(await editableShowIds(sb, user("editor"))).toBeNull();
  });

  it("returns the host's linked show ids", async () => {
    const sb = mockSupabase([{ show_id: "a" }, { show_id: "b" }]);
    expect(await editableShowIds(sb, user("host"))).toEqual(["a", "b"]);
  });

  it("returns an empty list for a host with no shows", async () => {
    const sb = mockSupabase([]);
    expect(await editableShowIds(sb, user("host"))).toEqual([]);
  });
});

describe("HOST_EDITABLE_SHOW_FIELDS", () => {
  it("includes bio fields but excludes identity / ops fields", () => {
    expect(HOST_EDITABLE_SHOW_FIELDS.has("description")).toBe(true);
    expect(HOST_EDITABLE_SHOW_FIELDS.has("history")).toBe(true);
    for (const locked of [
      "slug",
      "title",
      "show_type",
      "program_slug",
      "is_active",
      "sort_order",
      "broadcast_status",
    ]) {
      expect(HOST_EDITABLE_SHOW_FIELDS.has(locked)).toBe(false);
    }
  });
});
