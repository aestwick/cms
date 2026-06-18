import { notFound } from "next/navigation";
import Link from "next/link";
import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { EpisodeForm } from "@/components/episode-form";

interface ShowRow {
  id: string;
  title: string;
  slug: string;
  program_slug: string | null;
}

interface EpisodeRow {
  title: string | null;
  description: string | null;
  body_blocks: unknown;
  transcript_url: string | null;
  is_published: boolean;
}

export default async function EditEpisodePage({
  params,
}: {
  params: Promise<{ id: string; airDate: string }>;
}) {
  const { id, airDate } = await params;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(airDate)) notFound();

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
  if (!typedShow.program_slug) notFound();

  const { data: episode } = await supabase
    .from("cms_episode_metadata")
    .select("title, description, body_blocks, transcript_url, is_published")
    .eq("station_id", user.station_id)
    .eq("program_slug", typedShow.program_slug)
    .eq("air_date", airDate)
    .maybeSingle();

  const ep = (episode as EpisodeRow) ?? null;

  return (
    <div className="max-w-3xl">
      <nav className="text-xs text-charcoal/40">
        <Link href="/admin/shows" className="hover:text-charcoal">
          Shows
        </Link>{" "}
        / {typedShow.title} /{" "}
        <Link
          href={`/admin/shows/${typedShow.id}/episodes`}
          className="hover:text-charcoal"
        >
          Episodes
        </Link>{" "}
        / {airDate}
      </nav>
      <h1 className="mt-1 text-2xl font-bold text-charcoal">
        {ep ? "Edit episode notes" : "Add episode notes"}
      </h1>
      <div className="mt-6">
        <EpisodeForm
          showId={typedShow.id}
          programSlug={typedShow.program_slug}
          airDate={airDate}
          showTitle={typedShow.title}
          initialData={
            ep
              ? {
                  title: ep.title ?? "",
                  description: ep.description ?? "",
                  body_blocks: ep.body_blocks as never,
                  transcript_url: ep.transcript_url ?? "",
                  is_published: ep.is_published,
                }
              : undefined
          }
        />
      </div>
    </div>
  );
}
