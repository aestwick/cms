import { notFound } from "next/navigation";
import Link from "next/link";
import { headers } from "next/headers";
import type { Metadata } from "next";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { BlockRenderer } from "@/components/block-renderer";
import { EpisodePlayer } from "@/components/episode-player";
import { normalizeBlocks } from "@/lib/blocks";
import type { ConfessorEpisode } from "@/app/api/confessor/episodes/route";

export const dynamic = "force-dynamic";

interface ShowRow {
  id: string;
  title: string;
  slug: string;
  program_slug: string | null;
}

interface EpisodeRow {
  id: string;
  title: string | null;
  description: string | null;
  body_blocks: unknown;
  transcript_url: string | null;
  air_date: string;
}

function prettyDate(iso: string): string {
  // iso is YYYY-MM-DD; render without TZ drift.
  const [y, m, d] = iso.split("-").map(Number);
  return new Date(y, (m || 1) - 1, d || 1).toLocaleDateString("en-US", {
    weekday: "long",
    month: "long",
    day: "numeric",
    year: "numeric",
  });
}

async function loadShow(slug: string): Promise<ShowRow | null> {
  const supabase = getSupabaseAdmin();
  const { data } = await supabase
    .from("cms_shows")
    .select("id, title, slug, program_slug")
    .eq("slug", slug)
    .is("deleted_at", null)
    .single();
  return (data as ShowRow) ?? null;
}

async function loadEpisode(programSlug: string | null, airDate: string): Promise<EpisodeRow | null> {
  if (!programSlug) return null;
  const supabase = getSupabaseAdmin();
  const { data } = await supabase
    .from("cms_episode_metadata")
    .select("id, title, description, body_blocks, transcript_url, air_date")
    .eq("program_slug", programSlug)
    .eq("air_date", airDate)
    .eq("is_published", true)
    .maybeSingle();
  return (data as EpisodeRow) ?? null;
}

// Resolve the Confessor audio for one air date via the internal API route.
async function loadAudio(programSlug: string | null, airDate: string): Promise<ConfessorEpisode | null> {
  if (!programSlug) return null;
  try {
    const h = await headers();
    const proto = h.get("x-forwarded-proto") ?? "http";
    const base = `${proto}://${h.get("host")}`;
    const res = await fetch(
      `${base}/api/confessor/episodes?program=${encodeURIComponent(programSlug)}&num=80`,
      { next: { revalidate: 300 } }
    );
    if (!res.ok) return null;
    const { episodes } = (await res.json()) as { episodes: ConfessorEpisode[] };
    return episodes.find((e) => e.airDate === airDate) ?? null;
  } catch {
    return null;
  }
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string; airDate: string }>;
}): Promise<Metadata> {
  const { slug, airDate } = await params;
  const show = await loadShow(slug);
  if (!show) return { title: "Episode not found — KPFK 90.7 FM" };
  const ep = await loadEpisode(show.program_slug, airDate);
  const title = ep?.title || `${show.title} — ${prettyDate(airDate)}`;
  return {
    title: `${title} — KPFK 90.7 FM`,
    description: ep?.description ?? `An episode of ${show.title} on KPFK 90.7 FM.`,
  };
}

export default async function EpisodePage({
  params,
}: {
  params: Promise<{ slug: string; airDate: string }>;
}) {
  const { slug, airDate } = await params;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(airDate)) notFound();

  const show = await loadShow(slug);
  if (!show) notFound();

  const [episode, audio] = await Promise.all([
    loadEpisode(show.program_slug, airDate),
    loadAudio(show.program_slug, airDate),
  ]);

  // Nothing to show if there's neither rich metadata nor audio for this date.
  if (!episode && !audio) notFound();

  const blocks = normalizeBlocks(episode?.body_blocks);
  const heading = episode?.title || audio?.title || prettyDate(airDate);

  return (
    <div className="mx-auto max-w-3xl px-6 py-12 sm:px-8">
      <header className="pb-6" style={{ borderBottom: "3px solid var(--txt)" }}>
        <p className="kpfk-label">
          <Link href={`/on-air/${show.slug}`} className="hover:underline">
            {show.title}
          </Link>{" "}
          / Episode
        </p>
        <h1 className="kpfk-display mt-2 text-4xl sm:text-5xl" style={{ color: "var(--txt)" }}>
          {heading}
          <span style={{ color: "var(--kpfk-red)" }}>.</span>
        </h1>
        <p className="mt-2 font-mono text-sm" style={{ color: "var(--muted)" }}>
          {prettyDate(airDate)}
          {audio?.duration ? ` · ${audio.duration}` : ""}
        </p>
      </header>

      {audio?.audioUrl && (
        <div className="mt-6">
          <EpisodePlayer src={audio.audioUrl} storageKey={`${show.slug}-${airDate}`} />
        </div>
      )}

      {episode?.description && (
        <p className="mt-6 text-lg leading-relaxed" style={{ color: "var(--muted)" }}>
          {episode.description}
        </p>
      )}

      {blocks.length > 0 && (
        <div className="mt-8">
          <BlockRenderer blocks={blocks} />
        </div>
      )}

      {episode?.transcript_url && (
        <div className="mt-10 border-t pt-6" style={{ borderColor: "var(--line)" }}>
          <a
            href={episode.transcript_url}
            className="text-sm font-bold uppercase tracking-[0.08em]"
            style={{ color: "var(--kpfk-red)" }}
          >
            Read the transcript →
          </a>
        </div>
      )}
    </div>
  );
}
