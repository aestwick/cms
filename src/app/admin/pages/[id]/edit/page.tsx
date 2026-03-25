import { notFound } from "next/navigation";
import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { PageForm } from "@/components/page-form";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function EditPagePage({ params }: PageProps) {
  const { id } = await params;
  const user = await requireRole("admin", "editor");
  const supabase = getSupabaseAdmin();

  const { data: page } = await supabase
    .from("cms_pages")
    .select("*")
    .eq("id", id)
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .single();

  if (!page) notFound();

  return (
    <div>
      <h1 className="text-2xl font-bold text-charcoal">Edit Page</h1>
      <p className="mt-1 font-mono text-xs text-charcoal/40">/p/{page.slug}</p>
      <div className="mt-6">
        <PageForm
          mode="edit"
          pageId={id}
          initialData={{
            title: page.title,
            slug: page.slug,
            body: page.body,
            parent_id: page.parent_id || "",
            meta_title: page.meta_title || "",
            meta_description: page.meta_description || "",
            sort_order: page.sort_order,
            is_published: page.is_published,
          }}
        />
      </div>
    </div>
  );
}
