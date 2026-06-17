import { describe, it, expect } from "vitest";
import {
  slugify,
  flattenCategoryOptions,
  categoryIdWithChildren,
  type CategoryNode,
} from "@/lib/categories";

describe("slugify", () => {
  it("lowercases and hyphenates", () => {
    expect(slugify("Governance & Finance")).toBe("governance-finance");
  });

  it("trims leading/trailing separators", () => {
    expect(slugify("  Hello, World!  ")).toBe("hello-world");
  });

  it("collapses runs of non-alphanumerics", () => {
    expect(slugify("News---Local___2026")).toBe("news-local-2026");
  });

  it("handles empty / nullish input", () => {
    expect(slugify("")).toBe("");
    // @ts-expect-error exercising the nullish guard
    expect(slugify(undefined)).toBe("");
  });
});

describe("flattenCategoryOptions", () => {
  const cats: CategoryNode[] = [
    { id: "news", name: "News", parent_id: null, sort_order: 1 },
    { id: "sports", name: "Sports", parent_id: null, sort_order: 2 },
    { id: "local", name: "Local", parent_id: "news", sort_order: 2 },
    { id: "national", name: "National", parent_id: "news", sort_order: 1 },
  ];

  it("orders parents by sort_order, children nested under their parent", () => {
    expect(flattenCategoryOptions(cats)).toEqual([
      { id: "news", label: "News" },
      { id: "national", label: "— National" },
      { id: "local", label: "— Local" },
      { id: "sports", label: "Sports" },
    ]);
  });

  it("drops orphans whose parent is absent", () => {
    const withOrphan: CategoryNode[] = [
      ...cats,
      { id: "ghost", name: "Ghost", parent_id: "missing", sort_order: 1 },
    ];
    const ids = flattenCategoryOptions(withOrphan).map((o) => o.id);
    expect(ids).not.toContain("ghost");
  });

  it("returns empty for no categories", () => {
    expect(flattenCategoryOptions([])).toEqual([]);
  });
});

describe("categoryIdWithChildren", () => {
  const cats = [
    { id: "news", parent_id: null },
    { id: "local", parent_id: "news" },
    { id: "national", parent_id: "news" },
    { id: "sports", parent_id: null },
  ];

  it("includes the category and its direct children", () => {
    expect(categoryIdWithChildren("news", cats).sort()).toEqual(
      ["local", "national", "news"].sort()
    );
  });

  it("returns just the id when there are no children", () => {
    expect(categoryIdWithChildren("sports", cats)).toEqual(["sports"]);
  });
});
