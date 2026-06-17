import Link from "next/link";
import Image from "next/image";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import type { Metadata } from "next";

const SUPABASE_STORAGE_URL =
  "https://czjhwhfqohpmwprhasve.supabase.co/storage/v1/object/public";

function resolveImageUrl(path: string): string {
  if (path.startsWith("http://") || path.startsWith("https://")) return path;
  return `${SUPABASE_STORAGE_URL}/${path}`;
}

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "On Air — KPFK 90.7 FM",
  description: "Browse all active shows on KPFK 90.7 FM community radio.",
};

const TAG_FILTER_ACTIVE: Record<string, string> = {
  topic: "tag-filter--active-topic",
  format: "tag-filter--active-format",
  audience: "tag-filter--active-audience",
};

const STATUS_LABELS: Record<string, string> = {
  hiatus: "On Hiatus",
  online_only: "Online Only",
};

interface Tag {
  id: string;
  name: string;
  slug: string;
  category: string;
}

interface ShowTag {
  tag_id: string;
  cms_tags: Tag;
}

interface Show {
  id: string;
  title: string;
  slug: string;
  tagline: string | null;
  show_type: string;
  logo_path: string | null;
  banner_path: string | null;
  broadcast_status: string;
  cms_show_hosts: { name: string; role: string }[];
  cms_show_tags: ShowTag[];
}

export default async function OnAirPage({
  searchParams,
}: {
  searchParams: Promise<{ tag?: string }>;
}) {
  const { tag: tagParam } = await searchParams;
  const activeTags = tagParam ? tagParam.split(",").filter(Boolean) : [];

  const supabase = getSupabaseAdmin();

  // Fetch all tags for filter pills
  const { data: allTags } = await supabase
    .from("cms_tags")
    .select("id, name, slug, category")
    .order("category")
    .order("sort_order")
    .order("name");

  // Fetch shows with their tags
  const { data: shows } = await supabase
    .from("cms_shows")
    .select("id, title, slug, tagline, show_type, logo_path, banner_path, broadcast_status, cms_show_hosts(name, role), cms_show_tags(tag_id, cms_tags(id, name, slug, category))")
    .eq("is_active", true)
    .is("deleted_at", null)
    .order("sort_order", { ascending: true })
    .order("title", { ascending: true });

  const typedShows = (shows ?? []) as unknown as Show[];

  // Filter: exclude retired shows
  let filteredShows = typedShows.filter((s) => (s.broadcast_status || "active") !== "retired");

  // Filter by tags (AND logic)
  if (activeTags.length > 0) {
    filteredShows = filteredShows.filter((show) => {
      const showTagSlugs = (show.cms_show_tags ?? [])
        .filter((st) => st.cms_tags)
        .map((st) => st.cms_tags.slug);
      return activeTags.every((tag) => showTagSlugs.includes(tag));
    });
  }

  const tagsByCategory = {
    topic: (allTags ?? []).filter((t: Tag) => t.category === "topic"),
    format: (allTags ?? []).filter((t: Tag) => t.category === "format"),
    audience: (allTags ?? []).filter((t: Tag) => t.category === "audience"),
  };

  function buildTagUrl(tagSlug: string) {
    const newTags = activeTags.includes(tagSlug)
      ? activeTags.filter((t) => t !== tagSlug)
      : [...activeTags, tagSlug];
    return newTags.length > 0 ? `/on-air?tag=${newTags.join(",")}` : "/on-air";
  }

  return (
    <div className="mx-auto max-w-7xl px-6 py-12 sm:px-8">
      <p className="kpfk-label">The lineup</p>
      <h1 className="kpfk-display mt-2 text-5xl sm:text-6xl" style={{ color: "var(--txt)" }}>
        On Air<span style={{ color: "var(--kpfk-red)" }}>.</span>
      </h1>
      <p className="mt-3 text-lg" style={{ color: "var(--muted)" }}>
        All active shows on KPFK 90.7 FM.
      </p>

      {/* Tag filter pills — stamp style */}
      {allTags && allTags.length > 0 && (
        <div className="mt-8 space-y-4">
          {(["topic", "format", "audience"] as const).map((category) => {
            const categoryTags = tagsByCategory[category];
            if (categoryTags.length === 0) return null;
            return (
              <div key={category}>
                <span className="sidebar-label">
                  {category === "topic" ? "Topics" : category === "format" ? "Formats" : "Audience"}
                </span>
                <div className="mt-1.5 flex flex-wrap gap-2">
                  {categoryTags.map((tag: Tag) => {
                    const isActive = activeTags.includes(tag.slug);
                    return (
                      <Link
                        key={tag.id}
                        href={buildTagUrl(tag.slug)}
                        className={`tag-filter ${isActive ? TAG_FILTER_ACTIVE[tag.category] || "" : ""}`}
                      >
                        {tag.name}
                      </Link>
                    );
                  })}
                </div>
              </div>
            );
          })}

          {activeTags.length > 0 && (
            <Link
              href="/on-air"
              className="inline-block font-mono text-xs font-bold uppercase tracking-wide text-kpfk-red hover:underline"
            >
              Clear filters
            </Link>
          )}
        </div>
      )}

      {filteredShows.length === 0 ? (
        <p className="mt-10 font-serif text-base text-charcoal/50">
          {activeTags.length > 0
            ? "No shows match the selected filters."
            : "No shows available yet."}
        </p>
      ) : (
        <div className="mt-10 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {filteredShows.map((show) => {
            const hostsOnly = (show.cms_show_hosts ?? []).filter((h) => h.role !== "producer");
            const hostName = hostsOnly[0]?.name;
            const status = show.broadcast_status || "active";
            const isNonActive = status === "hiatus" || status === "online_only";
            const showTags = (show.cms_show_tags ?? [])
              .filter((st) => st.cms_tags)
              .map((st) => st.cms_tags);

            return (
              <Link
                key={show.id}
                href={`/on-air/${show.slug}`}
                className={`show-card group relative ${isNonActive ? "opacity-70" : ""}`}
              >
                {/* Card image — square aspect ratio */}
                {show.banner_path ? (
                  <Image
                    src={resolveImageUrl(show.banner_path)}
                    alt=""
                    width={400}
                    height={400}
                    className="show-card__image show-card__image--cover"
                    sizes="(min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw"
                  />
                ) : show.logo_path ? (
                  <Image
                    src={resolveImageUrl(show.logo_path)}
                    alt=""
                    width={400}
                    height={400}
                    className="show-card__image"
                    sizes="(min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw"
                  />
                ) : (
                  <div className="show-card__placeholder">
                    <span className="font-serif text-6xl font-bold text-charcoal/10">
                      {show.title.charAt(0)}
                    </span>
                  </div>
                )}

                {/* Status badge overlay */}
                {isNonActive && (
                  <span className="status-badge">
                    {STATUS_LABELS[status] || status}
                  </span>
                )}

                {/* Card body */}
                <div className="show-card__body">
                  <h2 className="show-card__title">{show.title}</h2>
                  {hostName && (
                    <p className="show-card__host">with {hostName}</p>
                  )}
                  {show.tagline && (
                    <p className="show-card__tagline">{show.tagline}</p>
                  )}
                  <div className="show-card__footer">
                    {showTags.length > 0 ? (
                      <>
                        {showTags.slice(0, 3).map((tag) => (
                          <span
                            key={tag.id}
                            className={`tag-stamp tag-stamp--${tag.category}`}
                          >
                            {tag.name}
                          </span>
                        ))}
                        {showTags.length > 3 && (
                          <span className="tag-stamp" style={{ borderColor: "#ccc", color: "#999" }}>
                            +{showTags.length - 3}
                          </span>
                        )}
                      </>
                    ) : (
                      <span className="show-card__type">{show.show_type}</span>
                    )}
                  </div>
                </div>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
