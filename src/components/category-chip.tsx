import Link from "next/link";
import { voiceColor } from "@/lib/voices";

export interface CategoryChipData {
  name: string;
  slug: string;
  color: string | null;
}

// A small Voice-colored chip linking to the coverage-area page.
export function CategoryChip({ category }: { category: CategoryChipData }) {
  const dot = voiceColor(category.color);
  return (
    <Link
      href={`/category/${category.slug}`}
      className="inline-flex items-center gap-1.5 border border-charcoal/15 px-2 py-0.5 text-[11px] font-extrabold uppercase tracking-[0.06em] text-charcoal/70 hover:border-charcoal/40 hover:text-charcoal"
    >
      {dot && (
        <span className="inline-block h-2 w-2" style={{ background: dot }} />
      )}
      {category.name}
    </Link>
  );
}
