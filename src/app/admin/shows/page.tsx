import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import Link from "next/link";

const STATUS_LABELS: Record<string, string> = {
  active: "Active",
  hiatus: "Hiatus",
  online_only: "Online Only",
  retired: "Retired",
};

const STATUS_COLORS: Record<string, string> = {
  active: "bg-green-600",
  hiatus: "bg-yellow-500",
  online_only: "bg-blue-500",
  retired: "bg-charcoal/30",
};

export default async function ShowsListPage() {
  const user = await requireRole("admin", "editor");
  const supabase = getSupabaseAdmin();

  const { data: shows } = await supabase
    .from("cms_shows")
    .select("id, title, slug, show_type, is_active, is_claimed, broadcast_status, updated_at")
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .order("sort_order")
    .order("title");

  // Fetch schedule slots to detect discrepancies
  const { data: allSlots } = await supabase
    .from("cms_schedule_slots")
    .select("show_id")
    .eq("station_id", user.station_id)
    .eq("is_recurring", true);

  const showIdsWithSlots = new Set((allSlots ?? []).map((s: { show_id: string }) => s.show_id));

  function getWarnings(show: { id: string; broadcast_status?: string; is_active: boolean }) {
    const status = show.broadcast_status || "active";
    const hasSlots = showIdsWithSlots.has(show.id);
    const warnings: string[] = [];

    if (status === "active" && !hasSlots) {
      warnings.push("Active show with no schedule slots");
    }
    if ((status === "hiatus" || status === "retired") && hasSlots) {
      warnings.push(`${STATUS_LABELS[status]} show still has active schedule slots`);
    }

    return warnings;
  }

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
          className="border-2 border-charcoal bg-charcoal px-5 py-2.5 text-base font-medium text-off-white hover:bg-charcoal/90"
        >
          New show
        </Link>
      </div>

      {/* Desktop table */}
      <div className="mt-6 hidden border border-charcoal/20 md:block">
        <table className="w-full text-base">
          <thead>
            <tr className="border-b border-charcoal/10 bg-charcoal/5 text-left">
              <th className="px-4 py-3 font-medium text-charcoal/60">Title</th>
              <th className="px-4 py-3 font-medium text-charcoal/60">Slug</th>
              <th className="px-4 py-3 font-medium text-charcoal/60">Type</th>
              <th className="px-4 py-3 font-medium text-charcoal/60">Status</th>
              <th className="px-4 py-3 font-medium text-charcoal/60">Claimed</th>
              <th className="px-4 py-3 font-medium text-charcoal/60" />
            </tr>
          </thead>
          <tbody>
            {shows?.map((show) => {
              const warnings = getWarnings(show);
              const status = show.broadcast_status || "active";
              return (
                <tr
                  key={show.id}
                  className="border-b border-charcoal/5 hover:bg-charcoal/[0.02]"
                >
                  <td className="px-4 py-3">
                    <span className="font-medium text-charcoal">{show.title}</span>
                    {warnings.length > 0 && (
                      <div className="mt-1">
                        {warnings.map((w, i) => (
                          <span
                            key={i}
                            className="mr-2 inline-block border border-yellow-500/30 bg-yellow-50 px-1.5 py-0.5 text-xs text-yellow-700"
                          >
                            {w}
                          </span>
                        ))}
                      </div>
                    )}
                  </td>
                  <td className="px-4 py-3 font-mono text-sm text-charcoal/50">
                    {show.slug}
                  </td>
                  <td className="px-4 py-3">
                    <span className="border border-charcoal/15 px-1.5 py-0.5 font-mono text-xs uppercase text-charcoal/50">
                      {show.show_type}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <span className="flex items-center gap-2">
                      <span
                        className={`inline-block h-2 w-2 rounded-full ${STATUS_COLORS[status] || "bg-charcoal/20"}`}
                      />
                      <span className="text-sm text-charcoal/50">
                        {STATUS_LABELS[status] || status}
                      </span>
                    </span>
                  </td>
                  <td className="px-4 py-3 text-sm text-charcoal/50">
                    {show.is_claimed ? "Yes" : "No"}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <Link
                      href={`/admin/shows/${show.id}/edit`}
                      className="text-sm text-kpfk-red hover:underline"
                    >
                      Edit
                    </Link>
                  </td>
                </tr>
              );
            })}
            {(!shows || shows.length === 0) && (
              <tr>
                <td
                  colSpan={6}
                  className="px-4 py-8 text-center text-base text-charcoal/40"
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

      {/* Mobile card list */}
      <div className="mt-6 space-y-3 md:hidden">
        {shows?.map((show) => {
          const warnings = getWarnings(show);
          const status = show.broadcast_status || "active";
          return (
            <Link
              key={show.id}
              href={`/admin/shows/${show.id}/edit`}
              className="block border border-charcoal/20 p-5 active:bg-charcoal/[0.03]"
            >
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0 flex-1">
                  <h3 className="truncate text-base font-medium text-charcoal">
                    {show.title}
                  </h3>
                  <p className="mt-0.5 truncate font-mono text-xs text-charcoal/40">
                    /on-air/{show.slug}
                  </p>
                </div>
                <span className="flex-shrink-0 border border-charcoal/15 px-1.5 py-0.5 font-mono text-[10px] uppercase text-charcoal/50">
                  {show.show_type}
                </span>
              </div>
              <div className="mt-2 flex items-center gap-4 text-sm text-charcoal/50">
                <span className="flex items-center gap-1.5">
                  <span
                    className={`inline-block h-2 w-2 rounded-full ${STATUS_COLORS[status] || "bg-charcoal/20"}`}
                  />
                  {STATUS_LABELS[status] || status}
                </span>
                {show.is_claimed && <span>Claimed</span>}
              </div>
              {warnings.length > 0 && (
                <div className="mt-2">
                  {warnings.map((w, i) => (
                    <span
                      key={i}
                      className="mr-2 inline-block border border-yellow-500/30 bg-yellow-50 px-1.5 py-0.5 text-xs text-yellow-700"
                    >
                      {w}
                    </span>
                  ))}
                </div>
              )}
            </Link>
          );
        })}
        {(!shows || shows.length === 0) && (
          <p className="py-8 text-center text-base text-charcoal/40">
            No shows yet.{" "}
            <Link
              href="/admin/shows/new"
              className="text-kpfk-red hover:underline"
            >
              Create one
            </Link>
          </p>
        )}
      </div>
    </div>
  );
}
