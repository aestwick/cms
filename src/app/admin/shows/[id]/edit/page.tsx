import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { notFound } from "next/navigation";
import { ShowForm } from "@/components/show-form";
import { HostManager } from "@/components/host-manager";

export default async function EditShowPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const user = await requireRole("admin", "editor");
  const { id } = await params;
  const supabase = getSupabaseAdmin();

  const { data: show } = await supabase
    .from("cms_shows")
    .select("*")
    .eq("id", id)
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .single();

  if (!show) {
    notFound();
  }

  const { data: hosts } = await supabase
    .from("cms_show_hosts")
    .select("*")
    .eq("show_id", id)
    .order("sort_order");

  // Fetch all tags and this show's tag assignments
  const { data: allTags } = await supabase
    .from("cms_tags")
    .select("id, name, slug, category")
    .eq("station_id", user.station_id)
    .order("category")
    .order("sort_order")
    .order("name");

  const { data: showTags } = await supabase
    .from("cms_show_tags")
    .select("tag_id")
    .eq("show_id", id);

  const initialTagIds = (showTags ?? []).map((st: { tag_id: string }) => st.tag_id);

  return (
    <div className="max-w-3xl">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-charcoal">Edit: {show.title}</h1>
          <p className="mt-1 font-mono text-xs text-charcoal/40">
            /on-air/{show.slug}
          </p>
        </div>
        {show.is_claimed && (
          <span className="rounded border border-green-600/20 bg-green-600/5 px-2 py-1 text-xs text-green-700">
            Claimed
          </span>
        )}
      </div>

      <div className="mt-6">
        <ShowForm
          mode="edit"
          showId={id}
          allTags={allTags ?? []}
          initialTagIds={initialTagIds}
          initialData={{
            title: show.title,
            slug: show.slug,
            tagline: show.tagline || "",
            description: show.description || "",
            history: show.history || "",
            show_type: show.show_type,
            program_slug: show.program_slug || "",
            logo_path: show.logo_path || "",
            banner_path: show.banner_path || "",
            contact_preference: show.contact_preference,
            contact_email: show.contact_email || "",
            website_url: show.website_url || "",
            rss_url: show.rss_url || "",
            social_links: show.social_links || {},
            donation_cta_heading: show.donation_cta_heading || "",
            donation_cta_body: show.donation_cta_body || "",
            is_active: show.is_active,
            sort_order: show.sort_order,
            broadcast_status: show.broadcast_status || "active",
            status_note: show.status_note || "",
            returns_at: show.returns_at || "",
            schedule_note: show.schedule_note || "",
          }}
        />
      </div>

      <div className="mt-10 border-t border-charcoal/10 pt-8">
        <HostManager showId={id} initialHosts={hosts || []} />
      </div>
    </div>
  );
}
