"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";

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

const TYPE_LABELS: Record<string, string> = {
  talk: "Talk",
  music: "Music",
  mixed: "Mixed",
};

interface Show {
  id: string;
  title: string;
  slug: string;
  show_type: string;
  is_active: boolean;
  is_claimed: boolean;
  broadcast_status: string | null;
}

interface ShowsListProps {
  shows: Show[];
  showIdsWithSlots: string[];
}

export function ShowsList({ shows: initialShows, showIdsWithSlots }: ShowsListProps) {
  const router = useRouter();
  const [shows, setShows] = useState(initialShows);
  const [search, setSearch] = useState("");
  const [typeFilter, setTypeFilter] = useState<string>("all");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [claimedFilter, setClaimedFilter] = useState<string>("all");
  const [togglingId, setTogglingId] = useState<string | null>(null);

  const slotsSet = new Set(showIdsWithSlots);

  function getWarnings(show: Show) {
    const status = show.broadcast_status || "active";
    const hasSlots = slotsSet.has(show.id);
    const warnings: string[] = [];

    if (status === "active" && !hasSlots) {
      warnings.push("No schedule slots");
    }
    if ((status === "hiatus" || status === "retired") && hasSlots) {
      warnings.push(`${STATUS_LABELS[status]} but has schedule slots`);
    }

    return warnings;
  }

  async function toggleActive(show: Show, e: React.MouseEvent) {
    e.stopPropagation();
    e.preventDefault();
    setTogglingId(show.id);

    try {
      const res = await fetch(`/api/shows/${show.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ is_active: !show.is_active }),
      });
      if (res.ok) {
        setShows((prev) =>
          prev.map((s) =>
            s.id === show.id ? { ...s, is_active: !s.is_active } : s
          )
        );
      }
    } catch {
      // silent
    }
    setTogglingId(null);
  }

  // Filter shows
  const filtered = shows.filter((show) => {
    if (search) {
      const q = search.toLowerCase();
      if (
        !show.title.toLowerCase().includes(q) &&
        !show.slug.toLowerCase().includes(q)
      )
        return false;
    }
    if (typeFilter !== "all" && show.show_type !== typeFilter) return false;
    if (statusFilter !== "all" && (show.broadcast_status || "active") !== statusFilter)
      return false;
    if (claimedFilter === "yes" && !show.is_claimed) return false;
    if (claimedFilter === "no" && show.is_claimed) return false;
    return true;
  });

  // Unique types and statuses for filter options
  const types = [...new Set(shows.map((s) => s.show_type))].sort();
  const statuses = [...new Set(shows.map((s) => s.broadcast_status || "active"))].sort();

  return (
    <div>
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-charcoal">Shows</h1>
          <p className="mt-1 text-sm text-charcoal/50">
            {filtered.length === shows.length
              ? `${shows.length} shows`
              : `${filtered.length} of ${shows.length} shows`}
          </p>
        </div>
        <Link
          href="/admin/shows/new"
          className="border-2 border-charcoal bg-charcoal px-5 py-2.5 text-base font-medium text-off-white hover:bg-charcoal/90"
        >
          New show
        </Link>
      </div>

      {/* Search + Filters */}
      <div className="mt-4 flex flex-wrap items-center gap-3">
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search shows..."
          className="w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none sm:w-64"
        />
        <select
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="border border-charcoal/20 bg-off-white px-3 py-2 text-sm text-charcoal/70 focus:border-charcoal focus:outline-none"
        >
          <option value="all">All types</option>
          {types.map((t) => (
            <option key={t} value={t}>
              {TYPE_LABELS[t] || t}
            </option>
          ))}
        </select>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="border border-charcoal/20 bg-off-white px-3 py-2 text-sm text-charcoal/70 focus:border-charcoal focus:outline-none"
        >
          <option value="all">All statuses</option>
          {statuses.map((s) => (
            <option key={s} value={s}>
              {STATUS_LABELS[s] || s}
            </option>
          ))}
        </select>
        <select
          value={claimedFilter}
          onChange={(e) => setClaimedFilter(e.target.value)}
          className="border border-charcoal/20 bg-off-white px-3 py-2 text-sm text-charcoal/70 focus:border-charcoal focus:outline-none"
        >
          <option value="all">All claims</option>
          <option value="yes">Claimed</option>
          <option value="no">Unclaimed</option>
        </select>
        {(search || typeFilter !== "all" || statusFilter !== "all" || claimedFilter !== "all") && (
          <button
            type="button"
            onClick={() => {
              setSearch("");
              setTypeFilter("all");
              setStatusFilter("all");
              setClaimedFilter("all");
            }}
            className="text-sm text-charcoal/40 hover:text-charcoal"
          >
            Clear filters
          </button>
        )}
      </div>

      {/* Desktop table */}
      <div className="mt-4 hidden border border-charcoal/20 md:block">
        <table className="w-full text-base">
          <thead>
            <tr className="border-b border-charcoal/10 bg-charcoal/5 text-left">
              <th className="px-4 py-3 font-medium text-charcoal/60">Title</th>
              <th className="px-4 py-3 font-medium text-charcoal/60">Slug</th>
              <th className="px-4 py-3 font-medium text-charcoal/60">Type</th>
              <th className="px-4 py-3 font-medium text-charcoal/60">Status</th>
              <th className="px-4 py-3 font-medium text-charcoal/60">Active</th>
              <th className="px-4 py-3 font-medium text-charcoal/60">Claimed</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((show) => {
              const warnings = getWarnings(show);
              const status = show.broadcast_status || "active";
              return (
                <tr
                  key={show.id}
                  onClick={() => router.push(`/admin/shows/${show.id}/edit`)}
                  className="cursor-pointer border-b border-charcoal/5 transition-colors hover:bg-charcoal/[0.03]"
                >
                  <td className="px-4 py-3">
                    <span className="font-medium text-charcoal">
                      {show.title}
                    </span>
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
                  <td className="px-4 py-3">
                    <button
                      type="button"
                      onClick={(e) => toggleActive(show, e)}
                      disabled={togglingId === show.id}
                      className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors ${
                        show.is_active
                          ? "bg-green-600"
                          : "bg-charcoal/20"
                      } ${togglingId === show.id ? "opacity-50" : ""}`}
                      title={show.is_active ? "Active — click to deactivate" : "Inactive — click to activate"}
                    >
                      <span
                        className={`inline-block h-3.5 w-3.5 rounded-full bg-white transition-transform ${
                          show.is_active ? "translate-x-[18px]" : "translate-x-[3px]"
                        }`}
                      />
                    </button>
                  </td>
                  <td className="px-4 py-3 text-sm text-charcoal/50">
                    {show.is_claimed ? "Yes" : "No"}
                  </td>
                </tr>
              );
            })}
            {filtered.length === 0 && (
              <tr>
                <td
                  colSpan={6}
                  className="px-4 py-8 text-center text-base text-charcoal/40"
                >
                  {shows.length === 0 ? (
                    <>
                      No shows yet.{" "}
                      <Link
                        href="/admin/shows/new"
                        className="text-kpfk-red hover:underline"
                      >
                        Create one
                      </Link>
                    </>
                  ) : (
                    "No shows match your filters."
                  )}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Mobile card list */}
      <div className="mt-4 space-y-3 md:hidden">
        {filtered.map((show) => {
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
                <span
                  className={`ml-auto inline-block h-2 w-2 rounded-full ${show.is_active ? "bg-green-600" : "bg-charcoal/20"}`}
                  title={show.is_active ? "Active" : "Inactive"}
                />
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
        {filtered.length === 0 && (
          <p className="py-8 text-center text-base text-charcoal/40">
            {shows.length === 0 ? (
              <>
                No shows yet.{" "}
                <Link
                  href="/admin/shows/new"
                  className="text-kpfk-red hover:underline"
                >
                  Create one
                </Link>
              </>
            ) : (
              "No shows match your filters."
            )}
          </p>
        )}
      </div>
    </div>
  );
}
