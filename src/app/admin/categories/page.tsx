import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { CategoryManager, type Category } from "@/components/category-manager";

export const dynamic = "force-dynamic";

export default async function AdminCategoriesPage() {
  const user = await requireRole("admin", "editor");
  const supabase = getSupabaseAdmin();

  const { data } = await supabase
    .from("cms_categories")
    .select("id, parent_id, name, slug, description, color, show_in_nav, sort_order")
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .order("sort_order")
    .order("name");

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-extrabold text-charcoal">Coverage areas</h1>
        <p className="mt-1 text-sm text-charcoal/60">
          The editorial taxonomy for Stories. Coverage areas can hold
          sub-categories; each carries a Voice color used across the site.
        </p>
      </div>

      <CategoryManager initial={(data ?? []) as Category[]} />
    </div>
  );
}
