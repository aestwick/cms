import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { TagManager } from "@/components/tag-manager";

export default async function TagsPage() {
  await requireRole("admin", "editor");
  const supabase = getSupabaseAdmin();

  const { data: tags } = await supabase
    .from("cms_tags")
    .select("*")
    .order("category")
    .order("sort_order")
    .order("name");

  return (
    <div>
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-charcoal">Tags</h1>
          <p className="mt-1 text-sm text-charcoal/50">
            Manage show tags by category
          </p>
        </div>
      </div>
      <div className="mt-8">
        <TagManager initialTags={tags ?? []} />
      </div>
    </div>
  );
}
