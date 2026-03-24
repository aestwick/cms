import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import Link from "next/link";

export default async function ShowsListPage() {
  const user = await requireRole("admin", "editor");
  const supabase = getSupabaseAdmin();

  const { data: shows } = await supabase
    .from("cms_shows")
    .select("id, title, slug, show_type, is_active, is_claimed, updated_at")
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .order("sort_order")
    .order("title");

  return (
    <div>
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-charcoal">Shows</h1>
          <p className="mt-1 text-sm text-charcoal/50">
            {shows?.length ?? 0} shows
          </p>
        </div>
        <Link
          href="/admin/shows/new"
          className="border-2 border-charcoal bg-charcoal px-4 py-2 text-sm font-medium text-off-white hover:bg-charcoal/90"
        >
          New show
        </Link>
      </div>

      <div className="mt-6 border border-charcoal/20">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-charcoal/10 bg-charcoal/5 text-left">
              <th className="px-4 py-2 font-medium text-charcoal/60">Title</th>
              <th className="px-4 py-2 font-medium text-charcoal/60">Slug</th>
              <th className="px-4 py-2 font-medium text-charcoal/60">Type</th>
              <th className="px-4 py-2 font-medium text-charcoal/60">Status</th>
              <th className="px-4 py-2 font-medium text-charcoal/60">Claimed</th>
              <th className="px-4 py-2 font-medium text-charcoal/60" />
            </tr>
          </thead>
          <tbody>
            {shows?.map((show) => (
              <tr
                key={show.id}
                className="border-b border-charcoal/5 hover:bg-charcoal/[0.02]"
              >
                <td className="px-4 py-2 font-medium text-charcoal">
                  {show.title}
                </td>
                <td className="px-4 py-2 font-mono text-xs text-charcoal/50">
                  {show.slug}
                </td>
                <td className="px-4 py-2">
                  <span className="rounded border border-charcoal/15 px-1.5 py-0.5 font-mono text-[10px] uppercase text-charcoal/50">
                    {show.show_type}
                  </span>
                </td>
                <td className="px-4 py-2">
                  <span
                    className={`inline-block h-2 w-2 rounded-full ${
                      show.is_active ? "bg-green-600" : "bg-charcoal/20"
                    }`}
                  />
                  <span className="ml-1.5 text-xs text-charcoal/50">
                    {show.is_active ? "Active" : "Inactive"}
                  </span>
                </td>
                <td className="px-4 py-2 text-xs text-charcoal/50">
                  {show.is_claimed ? "Yes" : "No"}
                </td>
                <td className="px-4 py-2 text-right">
                  <Link
                    href={`/admin/shows/${show.id}/edit`}
                    className="text-xs text-kpfk-red hover:underline"
                  >
                    Edit
                  </Link>
                </td>
              </tr>
            ))}
            {(!shows || shows.length === 0) && (
              <tr>
                <td
                  colSpan={6}
                  className="px-4 py-8 text-center text-sm text-charcoal/40"
                >
                  No shows yet.{" "}
                  <Link
                    href="/admin/shows/new"
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
