import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import Link from "next/link";

interface PageRow {
  id: string;
  title: string;
  slug: string;
  parent_id: string | null;
  sort_order: number;
  is_published: boolean;
  updated_at: string;
}

export default async function PagesListPage() {
  const user = await requireRole("admin", "editor");
  const supabase = getSupabaseAdmin();

  const { data: pages } = await supabase
    .from("cms_pages")
    .select("id, title, slug, parent_id, sort_order, is_published, updated_at")
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .order("sort_order", { ascending: true })
    .order("title", { ascending: true });

  // Build a parent title lookup
  const pageMap = new Map<string, string>();
  (pages ?? []).forEach((p: PageRow) => pageMap.set(p.id, p.title));

  return (
    <div>
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-charcoal">Pages</h1>
          <p className="mt-1 text-sm text-charcoal/50">
            {pages?.length ?? 0} pages
          </p>
        </div>
        <Link
          href="/admin/pages/new"
          className="border border-kpfk-red bg-kpfk-red px-4 py-2 text-sm font-extrabold uppercase tracking-[0.04em] text-white hover:bg-kpfk-red-press"
        >
          New page
        </Link>
      </div>

      <div className="mt-6 border border-charcoal/20">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-charcoal/10 bg-charcoal/5 text-left">
              <th className="px-4 py-2 font-medium text-charcoal/60">Title</th>
              <th className="px-4 py-2 font-medium text-charcoal/60">Slug</th>
              <th className="px-4 py-2 font-medium text-charcoal/60">Parent</th>
              <th className="px-4 py-2 font-medium text-charcoal/60">Status</th>
              <th className="px-4 py-2 font-medium text-charcoal/60" />
            </tr>
          </thead>
          <tbody>
            {(pages as PageRow[] | null)?.map((page) => (
              <tr
                key={page.id}
                className="border-b border-charcoal/5 hover:bg-charcoal/[0.02]"
              >
                <td className="px-4 py-2 font-medium text-charcoal">
                  {page.parent_id && (
                    <span className="mr-1 text-charcoal/30">└</span>
                  )}
                  {page.title}
                </td>
                <td className="px-4 py-2 font-mono text-xs text-charcoal/50">
                  /p/{page.slug}
                </td>
                <td className="px-4 py-2 text-xs text-charcoal/50">
                  {page.parent_id ? pageMap.get(page.parent_id) || "—" : "—"}
                </td>
                <td className="px-4 py-2">
                  <span
                    className={`inline-block h-2 w-2 rounded-full ${
                      page.is_published ? "bg-green-600" : "bg-charcoal/20"
                    }`}
                  />
                  <span className="ml-1.5 text-xs text-charcoal/50">
                    {page.is_published ? "Published" : "Draft"}
                  </span>
                </td>
                <td className="px-4 py-2 text-right">
                  <Link
                    href={`/admin/pages/${page.id}/edit`}
                    className="text-xs text-kpfk-red hover:underline"
                  >
                    Edit
                  </Link>
                </td>
              </tr>
            ))}
            {(!pages || pages.length === 0) && (
              <tr>
                <td
                  colSpan={5}
                  className="px-4 py-8 text-center text-sm text-charcoal/40"
                >
                  No pages yet.{" "}
                  <Link
                    href="/admin/pages/new"
                    className="text-kpfk-red hover:underline"
                  >
                    Create one
                  </Link>
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
