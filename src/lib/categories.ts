// Shared helpers for the coverage-area taxonomy (cms_categories).

export function slugify(input: string): string {
  return (input ?? "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

export interface CategoryNode {
  id: string;
  name: string;
  parent_id: string | null;
  sort_order: number;
}

export interface CategoryOption {
  id: string;
  label: string;
}

// Flatten a category tree into indented options for a <select>:
// top-level entries in sort order, each followed by its children
// (prefixed with an em-dash). Orphans (parent missing) are dropped.
export function flattenCategoryOptions(categories: CategoryNode[]): CategoryOption[] {
  const bySort = (a: CategoryNode, b: CategoryNode) =>
    a.sort_order - b.sort_order || a.name.localeCompare(b.name);

  return categories
    .filter((c) => !c.parent_id)
    .sort(bySort)
    .flatMap((parent) => [
      { id: parent.id, label: parent.name },
      ...categories
        .filter((c) => c.parent_id === parent.id)
        .sort(bySort)
        .map((child) => ({ id: child.id, label: `— ${child.name}` })),
    ]);
}

// Given a category id, return it plus the ids of its direct children —
// the set whose stories appear on the category's public page.
export function categoryIdWithChildren(
  id: string,
  categories: Pick<CategoryNode, "id" | "parent_id">[]
): string[] {
  const childIds = categories.filter((c) => c.parent_id === id).map((c) => c.id);
  return [id, ...childIds];
}
