import { notFound } from "next/navigation";
import Link from "next/link";
import { headers } from "next/headers";
import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import type { ConfessorEpisode } from "@/app/api/confessor/episodes/route";

export const dynamic = "force-dynamic";

interface ShowRow {
  id: string;
  title: string;
  slug: string;
  program_slug: string | null;
}

async function loadConfessorEpisodes(programSlug: string): Promise<ConfessorEpisode[]> {
  try {
    const h = await headers();
    const proto = h.get("x-forwarded-proto") ?? "http";
    const base = `${proto}://${h.get("host")}`;
    const res = await fetch(
      `${base}/api/confessor/episodes?program=${encodeURIComponent(programSlug)}&num=60`,
      { next: { revalidate: 300 } }
    );
    if (!res.ok) return [];
    const { episodes } = (await res.json()) as { episodes: ConfessorEpisode[] };
    return episodes.filter((e) => e.airDate);
  } catch {
    return [];
  }
}

export default async function ShowEpisodesPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const user = await requireRole("admin", "editor");
  const supabase = getSupabaseAdmin();

  const { data: show } = await supabase
    .from("cms_shows")
    .select("id, title, slug, program_slug")
    .eq("id", id)
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .single();

  if (!show) notFound();
  const typedShow = show as ShowRow;

  // Episode metadata we already have, keyed by air_date.
  const { data: metaRows } = await supabase
    .from("cms_episode_metadata")
    .select("air_date, title, is_published, body_blocks")
    .eq("station_id", user.station_id)
    .eq("show_id", typedShow.id)
    .order("air_date", { ascending: false });

  const metaByDate = new Map<
    string,
    { title: string | null; is_published: boolean; hasBlocks: boolean }
  >();
  for (const m of (metaRows ?? []) as Array<{
    air_date: string;
    title: string | null;
    is_published: boolean;
    body_blocks: unknown;
  }>) {
    metaByDate.set(m.air_date, {
      title: m.title,
      is_published: m.is_published,
      hasBlocks: Array.isArray(m.body_blocks) && m.body_blocks.length > 0,
    });
  }

  const confessor = typedShow.program_slug
    ? await loadConfessorEpisodes(typedShow.program_slug)
    : [];

  // Merge: every Confessor air date, plus any metadata-only dates not in the
  // recent Confessor window (e.g. older episodes).
  const seen = new Set(confessor.map((e) => e.airDate));
  const extraDates = [...metaByDate.keys()].filter((d) => !seen.has(d));
  const rows: Array<{ airDate: string; confessorTitle: string | null }> = [
    ...confessor.map((e) => ({ airDate: e.airDate, confessorTitle: e.title })),
    ...extraDates.map((d) => ({ airDate: d, confessorTitle: null })),
  ];

  return (
    <div>
      <nav className="text-xs text-charcoal/40">
        <Link href="/admin/shows" className="hover:text-charcoal">
          Shows
        </Link>{" "}
        / {typedShow.title}
      </nav>
      <h1 className="mt-1 text-2xl font-bold text-charcoal">Episodes</h1>
      <p className="mt-1 text-sm text-charcoal/50">
        Air dates from Confessor. Add CMS notes (summary, show notes, transcript)
        to any episode — they appear on the public episode page.
      </p>

      {!typedShow.program_slug && (
        <p className="mt-6 border border-charcoal/10 bg-white p-4 text-sm text-charcoal/60">
          This show has no <code className="font-mono">program_slug</code>, so it
          isn&apos;t linked to a Confessor program yet. Set one on the{" "}
          <Link href={`/admin/shows/${typedShow.id}/edit`} className="text-kpfk-red hover:underline">
            show edit page
          </Link>{" "}
          to pull its episode archive.
        </p>
      )}

      {typedShow.program_slug && rows.length === 0 && (
        <p className="mt-6 text-sm text-charcoal/50">
          No episodes found for this program yet.
        </p>
      )}

      {rows.length > 0 && (
        <div className="mt-6 overflow-hidden border border-charcoal/10 bg-white">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-charcoal/10 text-left text-xs uppercase tracking-wide text-charcoal/40">
                <th className="px-4 py-3 font-semibold">Air date</th>
                <th className="px-4 py-3 font-semibold">Title</th>
                <th className="px-4 py-3 font-semibold">CMS notes</th>
                <th className="px-4 py-3" />
              </tr>
            </thead>
            <tbody className="divide-y divide-charcoal/5">
              {rows.map((row) => {
                const meta = metaByDate.get(row.airDate);
                return (
                  <tr key={row.airDate} className="hover:bg-off-white">
                    <td className="px-4 py-3 font-mono text-charcoal/70">
                      {row.airDate}
                    </td>
                    <td className="px-4 py-3 text-charcoal">
                      {meta?.title || row.confessorTitle || (
                        <span className="text-charcoal/30">Untitled</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      {meta ? (
                        <span className="inline-flex items-center gap-1.5">
                          <span className="text-charcoal/70">
                            {meta.hasBlocks ? "Notes + blocks" : "Notes"}
                          </span>
                          {!meta.is_published && (
                            <span className="rounded-sm bg-charcoal/10 px-1.5 py-0.5 text-[10px] uppercase text-charcoal/50">
                              Draft
                            </span>
                          )}
                        </span>
                      ) : (
                        <span className="text-charcoal/30">—</span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <Link
                        href={`/admin/shows/${typedShow.id}/episodes/${row.airDate}`}
                        className="text-sm font-semibold text-kpfk-red hover:underline"
                      >
                        {meta ? "Edit" : "Add notes"}
                      </Link>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
