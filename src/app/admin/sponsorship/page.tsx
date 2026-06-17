import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { formatDate } from "@/lib/format";
import Link from "next/link";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: "Sponsorship — KPFK CMS" };

export default async function SponsorshipPage() {
  const user = await requireRole("admin");
  const supabase = getSupabaseAdmin();

  // Fetch placements with creative counts
  const { data: placements } = await supabase
    .from("cms_sponsorship_placements")
    .select("id, zone, name, max_items, is_active, created_at")
    .eq("station_id", user.station_id)
    .order("name", { ascending: true });

  // Fetch all active creatives
  const { data: creatives } = await supabase
    .from("cms_sponsorship_creatives")
    .select(
      "id, title, placement_id, creative_type, weight, is_pinned, pin_position, starts_at, ends_at, is_active, created_at"
    )
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .order("created_at", { ascending: false });

  // Build creative count per placement
  const creativeCounts: Record<string, number> = {};
  for (const c of creatives ?? []) {
    creativeCounts[c.placement_id] = (creativeCounts[c.placement_id] || 0) + 1;
  }

  // Build placement name lookup
  const placementNames: Record<string, string> = {};
  for (const p of placements ?? []) {
    placementNames[p.id] = p.name;
  }

  return (
    <div>
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-charcoal">Sponsorship</h1>
          <p className="mt-1 text-sm text-charcoal/50">
            {placements?.length ?? 0} placement zones,{" "}
            {creatives?.length ?? 0} creatives
          </p>
        </div>
        <Link
          href="/admin/sponsorship/new"
          className="border border-kpfk-red bg-kpfk-red px-4 py-2 text-sm font-extrabold uppercase tracking-[0.04em] text-white hover:bg-kpfk-red-press"
        >
          New creative
        </Link>
      </div>

      {/* Placement zones */}
      <div className="mt-6">
        <h2 className="mb-3 text-sm font-bold uppercase tracking-wider text-charcoal/40">
          Placement Zones
        </h2>
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          {(placements ?? []).map((placement) => (
            <div
              key={placement.id}
              className="border border-charcoal/20 p-4"
            >
              <div className="flex items-start justify-between">
                <div>
                  <h3 className="font-medium text-charcoal">
                    {placement.name}
                  </h3>
                  <p className="mt-0.5 font-mono text-xs text-charcoal/40">
                    {placement.zone}
                  </p>
                </div>
                <span
                  className={` border px-1.5 py-0.5 font-mono text-[10px] uppercase ${
                    placement.is_active
                      ? "border-green-600/20 bg-green-600/5 text-green-700"
                      : "border-charcoal/15 bg-charcoal/5 text-charcoal/30"
                  }`}
                >
                  {placement.is_active ? "Active" : "Inactive"}
                </span>
              </div>
              <div className="mt-3 flex items-center gap-4 text-xs text-charcoal/50">
                <span>
                  {creativeCounts[placement.id] ?? 0} / {placement.max_items}{" "}
                  creatives
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Creatives table */}
      <div className="mt-8">
        <h2 className="mb-3 text-sm font-bold uppercase tracking-wider text-charcoal/40">
          Creatives
        </h2>

        {creatives && creatives.length > 0 ? (
          <div className="overflow-x-auto border border-charcoal/20">
            <table className="w-full min-w-[700px] text-sm">
              <thead>
                <tr className="border-b border-charcoal/10 bg-charcoal/5 text-left">
                  <th className="px-4 py-2 font-medium text-charcoal/60">
                    Title
                  </th>
                  <th className="px-4 py-2 font-medium text-charcoal/60">
                    Zone
                  </th>
                  <th className="px-4 py-2 font-medium text-charcoal/60">
                    Status
                  </th>
                  <th className="px-4 py-2 font-medium text-charcoal/60">
                    Schedule
                  </th>
                  <th className="px-4 py-2 font-medium text-charcoal/60">
                    Weight
                  </th>
                  <th className="px-4 py-2 font-medium text-charcoal/60" />
                </tr>
              </thead>
              <tbody>
                {creatives.map((creative) => (
                  <tr
                    key={creative.id}
                    className="border-b border-charcoal/5 hover:bg-charcoal/[0.02]"
                  >
                    <td className="px-4 py-2 font-medium text-charcoal">
                      <span className="flex items-center gap-2">
                        {creative.title}
                        {creative.is_pinned && (
                          <span className=" border border-amber-500/20 bg-amber-500/5 px-1.5 py-0.5 font-mono text-[10px] uppercase text-amber-600">
                            Pinned {creative.pin_position != null ? `#${creative.pin_position}` : ""}
                          </span>
                        )}
                      </span>
                    </td>
                    <td className="px-4 py-2">
                      <span className=" border border-charcoal/15 px-1.5 py-0.5 font-mono text-[10px] uppercase text-charcoal/50">
                        {placementNames[creative.placement_id] ?? "Unknown"}
                      </span>
                    </td>
                    <td className="px-4 py-2">
                      <span
                        className={` border px-1.5 py-0.5 font-mono text-[10px] uppercase ${
                          creative.is_active
                            ? "border-green-600/20 bg-green-600/5 text-green-700"
                            : "border-charcoal/15 bg-charcoal/5 text-charcoal/30"
                        }`}
                      >
                        {creative.is_active ? "Active" : "Inactive"}
                      </span>
                    </td>
                    <td className="px-4 py-2 font-mono text-xs text-charcoal/50">
                      {creative.starts_at
                        ? formatDate(creative.starts_at)
                        : "—"}
                      {" — "}
                      {creative.ends_at ? formatDate(creative.ends_at) : "—"}
                    </td>
                    <td className="px-4 py-2 font-mono text-xs text-charcoal/50">
                      {creative.weight}
                    </td>
                    <td className="px-4 py-2 text-right">
                      <Link
                        href={`/admin/sponsorship/${creative.id}/edit`}
                        className="text-xs text-kpfk-red hover:underline"
                      >
                        Edit
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="border border-charcoal/20 px-4 py-8 text-center text-sm text-charcoal/40">
            No creatives yet.{" "}
            <Link
              href="/admin/sponsorship/new"
              className="text-kpfk-red hover:underline"
            >
              Create one
            </Link>
          </div>
        )}
      </div>
    </div>
  );
}
