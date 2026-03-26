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

const TAG_CATEGORY_COLORS: Record<string, { active: string; inactive: string }> = {
  topic: {
    active: "bg-tag-topic border-charcoal/30 text-charcoal font-medium",
    inactive: "border-charcoal/15 text-charcoal/50 hover:border-charcoal/30",
  },
  format: {
    active: "bg-tag-format border-charcoal/30 text-charcoal font-medium",
    inactive: "border-charcoal/15 text-charcoal/50 hover:border-charcoal/30",
  },
  audience: {
    active: "bg-tag-audience border-charcoal/30 text-charcoal font-medium",
    inactive: "border-charcoal/15 text-charcoal/50 hover:border-charcoal/30",
  },
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
      <h1 className="font-serif text-4xl font-bold text-charcoal">On Air</h1>
      <p className="mt-3 text-lg text-charcoal/60">
        All active shows on KPFK 90.7 FM
      </p>

      {/* Tag filter pills */}
      {allTags && allTags.length > 0 && (
        <div className="mt-8 space-y-4">
          {(["topic", "format", "audience"] as const).map((category) => {
            const categoryTags = tagsByCategory[category];
            if (categoryTags.length === 0) return null;
            return (
              <div key={category}>
                <span className="text-xs font-bold uppercase tracking-wider text-charcoal/30">
                  {category === "topic" ? "Topics" : category === "format" ? "Formats" : "Audience"}
                </span>
                <div className="mt-1.5 flex flex-wrap gap-2">
                  {categoryTags.map((tag: Tag) => {
                    const isActive = activeTags.includes(tag.slug);
                    const colors = TAG_CATEGORY_COLORS[tag.category] || TAG_CATEGORY_COLORS.topic;
                    return (
                      <Link
                        key={tag.id}
                        href={buildTagUrl(tag.slug)}
                        className={`border px-3 py-1.5 text-sm transition-colors ${
                          isActive ? colors.active : colors.inactive
                        }`}
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
              className="inline-block text-sm text-kpfk-red hover:underline"
            >
              Clear filters
            </Link>
          )}
        </div>
      )}

      {filteredShows.length === 0 ? (
        <p className="mt-10 text-base text-charcoal/50">
          {activeTags.length > 0
            ? "No shows match the selected filters."
            : "No shows available yet."}
        </p>
      ) : (
        <div className="mt-10 grid grid-cols-1 gap-px border border-charcoal/20 bg-charcoal/10 sm:grid-cols-2 lg:grid-cols-3">
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
                className={`group relative flex flex-col bg-off-white transition-colors hover:bg-charcoal/[0.02] ${
                  isNonActive ? "opacity-70" : ""
                }`}
              >
                {/* Card banner or logo hero area */}
                {show.banner_path ? (
                  <div className="relative h-36 w-full overflow-hidden bg-charcoal/5">
                    <Image
                      src={resolveImageUrl(show.banner_path)}
                      alt=""
                      fill
                      className="object-cover transition-transform duration-300 group-hover:scale-[1.02]"
                      sizes="(min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw"
                    />
                  </div>
                ) : show.logo_path ? (
                  <div className="flex h-36 w-full items-center justify-center bg-charcoal/[0.03]">
                    <div className="relative h-24 w-24 overflow-hidden rounded-full">
                      <Image
                        src={resolveImageUrl(show.logo_path)}
                        alt=""
                        fill
                        className="object-cover"
                        sizes="96px"
                      />
                    </div>
                  </div>
                ) : (
                  <div className="flex h-36 w-full items-center justify-center bg-charcoal/[0.03]">
                    <span className="font-serif text-5xl font-bold text-charcoal/10">
                      {show.title.charAt(0)}
                    </span>
                  </div>
                )}

                {/* Status badge overlay */}
                {isNonActive && (
                  <span className="absolute right-2 top-2 border border-charcoal/20 bg-off-white px-2 py-0.5 font-mono text-[10px] uppercase text-charcoal/50">
                    {STATUS_LABELS[status] || status}
                  </span>
                )}

                {/* Card body */}
                <div className="flex flex-1 flex-col p-5">
                  <h2 className="font-serif text-xl font-bold leading-tight text-charcoal">
                    {show.title}
                  </h2>
                  {hostName && (
                    <p className="mt-1 text-sm text-charcoal/50">
                      with {hostName}
                    </p>
                  )}
                  {show.tagline && (
                    <p className="mt-2 text-sm leading-relaxed text-charcoal/60">
                      {show.tagline}
                    </p>
                  )}
                  {/* Show tags on card */}
                  {showTags.length > 0 && (
                    <div className="mt-3 flex flex-wrap gap-1.5">
                      {showTags.slice(0, 4).map((tag) => (
                        <span
                          key={tag.id}
                          className={`border px-2 py-0.5 text-[11px] text-charcoal/50 ${
                            TAG_CATEGORY_COLORS[tag.category]?.inactive || "border-charcoal/15"
                          }`}
                        >
                          {tag.name}
                        </span>
                      ))}
                      {showTags.length > 4 && (
                        <span className="px-1 text-[11px] text-charcoal/30">
                          +{showTags.length - 4}
                        </span>
                      )}
                    </div>
                  )}
                  <div className="mt-auto pt-3">
                    <span className="font-mono text-xs uppercase text-charcoal/30">
                      {show.show_type}
                    </span>
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
