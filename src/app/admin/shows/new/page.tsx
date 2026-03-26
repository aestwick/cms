import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { ShowForm } from "@/components/show-form";

export default async function NewShowPage() {
  const user = await requireRole("admin", "editor");
  const supabase = getSupabaseAdmin();

  const { data: allTags } = await supabase
    .from("cms_tags")
    .select("id, name, slug, category")
    .eq("station_id", user.station_id)
    .order("category")
    .order("sort_order")
    .order("name");

  return (
    <div className="max-w-3xl">
      <h1 className="text-2xl font-bold text-charcoal">New Show</h1>
      <p className="mt-1 text-sm text-charcoal/50">
        Create a new show page. Hosts can be added after creation.
      </p>
      <div className="mt-6">
        <ShowForm mode="create" allTags={allTags ?? []} />
      </div>
    </div>
  );
}
