import { notFound } from "next/navigation";
import Image from "next/image";
import Link from "next/link";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { ShowContactForm } from "@/components/show-contact-form";
import { EpisodeArchive } from "@/components/episode-archive";
import type { Metadata } from "next";

const SUPABASE_STORAGE_URL =
  "https://czjhwhfqohpmwprhasve.supabase.co/storage/v1/object/public";

function resolveImageUrl(path: string): string {
  if (path.startsWith("http://") || path.startsWith("https://")) return path;
  return `${SUPABASE_STORAGE_URL}/${path}`;
}

interface ShowHost {
  id: string;
  name: string;
  bio: string | null;
  photo_path: string | null;
  is_primary: boolean;
}

interface ShowTag {
  tag_id: string;
  cms_tags: {
    id: string;
    name: string;
    slug: string;
    category: string;
  };
}

interface Show {
  id: string;
  station_id: string;
  title: string;
  slug: string;
  tagline: string | null;
  description: string | null;
  history: string | null;
  show_type: string;
  program_slug: string | null;
  logo_path: string | null;
  banner_path: string | null;
  contact_preference: string;
  contact_email: string | null;
  website_url: string | null;
  rss_url: string | null;
  social_links: Record<string, string>;
  donation_cta_heading: string | null;
  donation_cta_body: string | null;
  donation_cta_url: string | null;
  broadcast_status: string;
  status_note: string | null;
  returns_at: string | null;
  schedule_note: string | null;
  cms_show_hosts: ShowHost[];
  cms_show_tags: ShowTag[];
}

interface ScheduleSlot {
  day_of_week: number;
  start_time: string;
  end_time: string;
  label: string | null;
  show_id: string | null;
  cms_shows: { title: string; slug: string } | null;
}

interface PageProps {
  params: Promise<{ slug: string }>;
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const supabase = getSupabaseAdmin();

  const { data: show } = await supabase
    .from("cms_shows")
    .select("title, tagline")
    .eq("slug", slug)
    .eq("is_active", true)
    .is("deleted_at", null)
    .single();

  if (!show) return { title: "Show Not Found — KPFK 90.7 FM" };

  return {
    title: `${show.title} — KPFK 90.7 FM`,
    description: show.tagline || `Listen to ${show.title} on KPFK 90.7 FM.`,
  };
}

/* ------------------------------------------------------------------ */
/*  SVG Icons                                                          */
/* ------------------------------------------------------------------ */

function IconGlobe({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" />
      <path d="M2 12h20M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" />
    </svg>
  );
}

function IconRss({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 11a9 9 0 0 1 9 9M4 4a16 16 0 0 1 16 16" />
      <circle cx="5" cy="19" r="1" />
    </svg>
  );
}

function IconFacebook({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
    </svg>
  );
}

function IconTwitter({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
    </svg>
  );
}

function IconInstagram({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z" />
    </svg>
  );
}

function IconYoutube({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M23.498 6.186a3.016 3.016 0 00-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 00.502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 002.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 002.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z" />
    </svg>
  );
}

function IconTiktok({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z" />
    </svg>
  );
}

const SOCIAL_ICONS: Record<string, React.ComponentType<{ className?: string }>> = {
  facebook: IconFacebook,
  twitter: IconTwitter,
  instagram: IconInstagram,
  youtube: IconYoutube,
  tiktok: IconTiktok,
};

const SOCIAL_LABELS: Record<string, string> = {
  facebook: "Facebook",
  twitter: "X / Twitter",
  instagram: "Instagram",
  youtube: "YouTube",
  tiktok: "TikTok",
};

const TAG_CATEGORY_COLORS: Record<string, string> = {
  topic: "bg-tag-topic border-charcoal/15",
  format: "bg-tag-format border-charcoal/15",
  audience: "bg-tag-audience border-charcoal/15",
};

const dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
const dayAbbrev = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];

function formatTime(t: string) {
  const [h, m] = t.split(":");
  const hour = parseInt(h);
  const ampm = hour >= 12 ? "PM" : "AM";
  const h12 = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
  return `${h12}:${m} ${ampm}`;
}

function formatScheduleBadge(slots: { day_of_week: number; start_time: string; end_time: string }[]) {
  if (slots.length === 0) return null;

  // Group consecutive days with same time
  const groups: { days: number[]; start: string; end: string }[] = [];
  for (const slot of slots) {
    const last = groups[groups.length - 1];
    if (last && last.start === slot.start_time && last.end === slot.end_time) {
      last.days.push(slot.day_of_week);
    } else {
      groups.push({ days: [slot.day_of_week], start: slot.start_time, end: slot.end_time });
    }
  }

  return groups.map((g) => {
    const dayStr =
      g.days.length === 1
        ? dayAbbrev[g.days[0]]
        : `${dayAbbrev[g.days[0]]}\u2013${dayAbbrev[g.days[g.days.length - 1]]}`;
    return `${dayStr} \u2022 ${formatTime(g.start)}\u2013${formatTime(g.end)} \u2022 KPFK 90.7 FM`;
  });
}

export default async function ShowPage({ params }: PageProps) {
  const { slug } = await params;
  const supabase = getSupabaseAdmin();

  // For retired shows, allow access by direct URL but still render
  const { data: show } = await supabase
    .from("cms_shows")
    .select("*, cms_show_hosts(*), cms_show_tags(tag_id, cms_tags(id, name, slug, category))")
    .eq("slug", slug)
    .eq("is_active", true)
    .is("deleted_at", null)
    .single();

  if (!show) notFound();

  const typedShow = show as unknown as Show;
  const hosts = (typedShow.cms_show_hosts ?? []).sort(
    (a, b) => (b.is_primary ? 1 : 0) - (a.is_primary ? 1 : 0)
  );
  const showContact = ["form", "both"].includes(typedShow.contact_preference);
  const showEmail = ["email", "both"].includes(typedShow.contact_preference);
  const socialEntries = Object.entries(typedShow.social_links || {}).filter(
    ([, url]) => url
  );
  const tags = (typedShow.cms_show_tags ?? [])
    .filter((st) => st.cms_tags)
    .map((st) => st.cms_tags);

  const broadcastStatus = typedShow.broadcast_status || "active";

  // Fetch schedule slots for this show
  const { data: scheduleSlots } = await supabase
    .from("cms_schedule_slots")
    .select("day_of_week, start_time, end_time, label, show_id")
    .eq("show_id", typedShow.id)
    .eq("is_recurring", true)
    .order("day_of_week", { ascending: true })
    .order("start_time", { ascending: true });

  // Fetch show posts
  const { data: showPosts } = await supabase
    .from("cms_posts")
    .select("id, title, slug, excerpt, body, published_at")
    .eq("show_id", typedShow.id)
    .eq("status", "published")
    .is("deleted_at", null)
    .order("published_at", { ascending: false })
    .limit(5);

  // Find adjacent shows (on air nearby)
  let adjacentShows: { title: string; slug: string; relationship: string }[] = [];
  if (scheduleSlots && scheduleSlots.length > 0) {
    const firstSlot = scheduleSlots[0];
    // Find show before
    const { data: before } = await supabase
      .from("cms_schedule_slots")
      .select("cms_shows(title, slug)")
      .eq("day_of_week", firstSlot.day_of_week)
      .eq("is_recurring", true)
      .lt("end_time", firstSlot.start_time)
      .not("show_id", "eq", typedShow.id)
      .order("end_time", { ascending: false })
      .limit(1);

    // Find show after
    const { data: after } = await supabase
      .from("cms_schedule_slots")
      .select("cms_shows(title, slug)")
      .eq("day_of_week", firstSlot.day_of_week)
      .eq("is_recurring", true)
      .gt("start_time", firstSlot.end_time)
      .not("show_id", "eq", typedShow.id)
      .order("start_time", { ascending: true })
      .limit(1);

    if (before?.[0]?.cms_shows) {
      const s = before[0].cms_shows as unknown as { title: string; slug: string };
      adjacentShows.push({ ...s, relationship: `Before on ${dayNames[firstSlot.day_of_week]}s` });
    }
    if (after?.[0]?.cms_shows) {
      const s = after[0].cms_shows as unknown as { title: string; slug: string };
      adjacentShows.push({ ...s, relationship: `After on ${dayNames[firstSlot.day_of_week]}s` });
    }
  }

  const hasLinks = typedShow.website_url || typedShow.rss_url || socialEntries.length > 0;
  const donateHeading = typedShow.donation_cta_heading || `Support ${typedShow.title}`;
  const donateBody = typedShow.donation_cta_body || "Keep community radio on the air.";
  const donateUrl = typedShow.donation_cta_url || "https://donate.kpfk.org";

  const scheduleBadgeLines = formatScheduleBadge(scheduleSlots ?? []);

  return (
    <article>
      {/* ============================================================ */}
      {/* Masthead                                                      */}
      {/* ============================================================ */}
      {typedShow.banner_path ? (
        <header className="relative h-72 w-full overflow-hidden bg-charcoal sm:h-80 lg:h-96">
          <Image
            src={resolveImageUrl(typedShow.banner_path)}
            alt={`${typedShow.title} banner`}
            fill
            className="object-cover"
            sizes="100vw"
            priority
          />
          <div className="absolute inset-0 bg-gradient-to-t from-charcoal/80 via-charcoal/30 to-transparent" />
          <div className="absolute inset-x-0 bottom-0 mx-auto max-w-7xl px-6 pb-6 sm:px-8">
            <div className="flex items-end gap-5">
              {typedShow.logo_path && (
                <div className="relative hidden h-32 w-32 flex-shrink-0 overflow-hidden border-2 border-off-white/20 bg-charcoal/50 backdrop-blur sm:block lg:h-36 lg:w-36">
                  <Image
                    src={resolveImageUrl(typedShow.logo_path)}
                    alt={`${typedShow.title} logo`}
                    fill
                    className="object-contain p-2"
                    sizes="160px"
                  />
                </div>
              )}
              <div>
                <span className="font-mono text-xs uppercase tracking-wider text-off-white/60">
                  {typedShow.show_type}
                </span>
                <h1 className="font-serif text-3xl font-bold leading-tight text-off-white sm:text-4xl lg:text-5xl">
                  {typedShow.title}
                </h1>
                {typedShow.tagline && (
                  <p className="mt-1 text-lg text-off-white/70">{typedShow.tagline}</p>
                )}
                {/* Tags in masthead */}
                {tags.length > 0 && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    {tags.map((tag) => (
                      <Link
                        key={tag.id}
                        href={`/on-air?tag=${tag.slug}`}
                        className={`border px-2.5 py-1 text-xs text-off-white/80 transition-colors hover:text-off-white ${
                          tag.category === "topic"
                            ? "border-off-white/20 bg-off-white/10"
                            : tag.category === "format"
                              ? "border-off-white/20 bg-off-white/10"
                              : "border-off-white/20 bg-off-white/10"
                        }`}
                      >
                        {tag.name}
                      </Link>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        </header>
      ) : (
        <header className="relative w-full overflow-hidden border-b-2 border-charcoal bg-charcoal/[0.03]">
          <div className="mx-auto flex max-w-7xl items-end gap-5 px-6 py-8 sm:px-8 sm:py-10">
            {typedShow.logo_path ? (
              <div className="relative h-32 w-32 flex-shrink-0 overflow-hidden border border-charcoal/10 bg-off-white sm:h-36 sm:w-36">
                <Image
                  src={resolveImageUrl(typedShow.logo_path)}
                  alt={`${typedShow.title} logo`}
                  fill
                  className="object-contain p-2"
                  sizes="(min-width: 640px) 176px, 144px"
                />
              </div>
            ) : (
              <div className="flex h-32 w-32 flex-shrink-0 items-center justify-center border border-charcoal/10 bg-charcoal/5 sm:h-36 sm:w-36">
                <span className="font-serif text-6xl font-bold text-charcoal/15 sm:text-7xl">
                  {typedShow.title.charAt(0)}
                </span>
              </div>
            )}
            <div className="pb-1">
              <span className="font-mono text-xs uppercase tracking-wider text-charcoal/40">
                {typedShow.show_type}
              </span>
              <h1 className="font-serif text-3xl font-bold leading-tight text-charcoal sm:text-4xl lg:text-5xl">
                {typedShow.title}
              </h1>
              {typedShow.tagline && (
                <p className="mt-2 text-lg text-charcoal/60 sm:text-xl">{typedShow.tagline}</p>
              )}
              {/* Tags in masthead */}
              {tags.length > 0 && (
                <div className="mt-3 flex flex-wrap gap-2">
                  {tags.map((tag) => (
                    <Link
                      key={tag.id}
                      href={`/on-air?tag=${tag.slug}`}
                      className={`border px-2.5 py-1 text-xs transition-colors hover:text-charcoal ${TAG_CATEGORY_COLORS[tag.category] || "border-charcoal/15 bg-charcoal/5"} text-charcoal/70`}
                    >
                      {tag.name}
                    </Link>
                  ))}
                </div>
              )}
            </div>
          </div>
        </header>
      )}

      {/* ============================================================ */}
      {/* Schedule Badge / Broadcast Status Bar                         */}
      {/* ============================================================ */}
      <div className="border-b border-charcoal/10">
        <div className="mx-auto max-w-7xl px-6 py-4 sm:px-8">
          {broadcastStatus === "active" && scheduleBadgeLines && scheduleBadgeLines.length > 0 ? (
            <div className="space-y-2">
              {scheduleBadgeLines.map((line, i) => (
                <div
                  key={i}
                  className="inline-block bg-charcoal px-5 py-2.5 font-mono text-sm tracking-wide text-off-white"
                >
                  {line}
                </div>
              ))}
              {typedShow.schedule_note && (
                <p className="mt-1 text-sm text-charcoal/50">{typedShow.schedule_note}</p>
              )}
            </div>
          ) : broadcastStatus === "active" ? (
            <div>
              <p className="text-sm text-charcoal/50">Schedule not yet available.</p>
              {typedShow.schedule_note && (
                <p className="mt-1 text-sm text-charcoal/50">{typedShow.schedule_note}</p>
              )}
            </div>
          ) : broadcastStatus === "hiatus" ? (
            <div className="flex items-center gap-3">
              <span className="inline-block h-2.5 w-2.5 rounded-full bg-yellow-500" />
              <span className="text-base text-charcoal/70">
                {typedShow.status_note || "Currently on break."}
                {typedShow.returns_at && (
                  <span className="ml-2 font-medium">
                    Returning {new Date(typedShow.returns_at).toLocaleDateString("en-US", { month: "long", day: "numeric", year: "numeric" })}
                  </span>
                )}
              </span>
            </div>
          ) : broadcastStatus === "online_only" ? (
            <div className="flex items-center gap-3">
              <span className="inline-block h-2.5 w-2.5 rounded-full bg-blue-500" />
              <span className="text-base text-charcoal/70">
                {typedShow.status_note || "Stream past episodes"}
              </span>
            </div>
          ) : broadcastStatus === "retired" ? (
            <div className="flex items-center gap-3">
              <span className="inline-block h-2.5 w-2.5 rounded-full bg-charcoal/30" />
              <span className="text-base text-charcoal/50">
                {typedShow.status_note || "This show is no longer in production"}
              </span>
            </div>
          ) : null}
        </div>
      </div>

      {/* ============================================================ */}
      {/* Two-column: Main content + sidebar                            */}
      {/* ============================================================ */}
      <div className="mx-auto max-w-7xl px-6 py-12 sm:px-8">
        <div className="grid grid-cols-1 gap-0 lg:grid-cols-3">
          {/* Main content (2/3) */}
          <div className="space-y-12 lg:col-span-2 lg:pr-10">
            {/* About */}
            {typedShow.description && (
              <section>
                <h2 className="font-serif text-2xl font-bold text-charcoal">About the Show</h2>
                <div
                  className="prose mt-5 max-w-none text-base leading-relaxed text-charcoal/80"
                  dangerouslySetInnerHTML={{ __html: typedShow.description }}
                />
              </section>
            )}

            {/* History */}
            {typedShow.history && (
              <section>
                <h2 className="font-serif text-2xl font-bold text-charcoal">History &amp; Legacy</h2>
                <div
                  className="prose mt-5 max-w-none text-base leading-relaxed text-charcoal/80"
                  dangerouslySetInnerHTML={{ __html: typedShow.history }}
                />
              </section>
            )}

            {/* Show blog posts */}
            {showPosts && showPosts.length > 0 && (
              <section>
                <h2 className="font-serif text-2xl font-bold text-charcoal">Show Blog</h2>
                <div className="mt-5 space-y-0 divide-y divide-charcoal/10">
                  {showPosts.map((post) => (
                    <article key={post.id} className="py-5 first:pt-0">
                      <time className="font-mono text-xs text-charcoal/40">
                        {post.published_at
                          ? new Date(post.published_at).toLocaleDateString("en-US", {
                              month: "short",
                              day: "numeric",
                              year: "numeric",
                            })
                          : ""}
                      </time>
                      <h3 className="mt-1 font-serif text-xl font-bold text-charcoal">
                        <Link href={`/blog/${post.slug}`} className="hover:text-kpfk-red">
                          {post.title}
                        </Link>
                      </h3>
                      <p className="mt-1 text-base text-charcoal/60">
                        {post.excerpt || (post.body ? post.body.replace(/<[^>]*>/g, "").slice(0, 200) + "\u2026" : "")}
                      </p>
                    </article>
                  ))}
                </div>
              </section>
            )}

            {/* Episode archive */}
            {typedShow.program_slug ? (
              <EpisodeArchive
                programSlug={typedShow.program_slug}
                showTitle={typedShow.title}
              />
            ) : (
              <section className="border border-charcoal/10 p-8">
                <h2 className="font-serif text-xl font-bold text-charcoal">Recent Episodes</h2>
                <p className="mt-3 text-base text-charcoal/40">
                  Episode archive not yet available for this show.
                </p>
              </section>
            )}

            {/* Contact form */}
            {showContact && (
              <section>
                <h2 className="font-serif text-2xl font-bold text-charcoal">
                  Contact {typedShow.title}
                </h2>
                <div className="mt-5">
                  <ShowContactForm showId={typedShow.id} showTitle={typedShow.title} />
                </div>
              </section>
            )}
          </div>

          {/* ======================================================== */}
          {/* Sidebar (1/3) with left border                            */}
          {/* ======================================================== */}
          <aside className="mt-12 space-y-8 border-charcoal/10 lg:mt-0 lg:border-l lg:pl-10">
            {/* Hosts — rectangular portraits */}
            {hosts.length > 0 && (
              <section>
                <h3 className="text-sm font-bold uppercase tracking-wider text-charcoal/40">
                  {hosts.length === 1 ? "Host" : "Hosts"}
                </h3>
                <div className="mt-4 space-y-6">
                  {hosts.map((host) => (
                    <div key={host.id}>
                      <div className="flex items-start gap-4">
                        {host.photo_path ? (
                          <div className="relative h-[100px] w-[80px] flex-shrink-0 overflow-hidden border border-charcoal/10 bg-charcoal/5">
                            <Image
                              src={resolveImageUrl(host.photo_path)}
                              alt={`${host.name} photo`}
                              fill
                              className="object-cover"
                              sizes="80px"
                            />
                          </div>
                        ) : (
                          <div className="flex h-[100px] w-[80px] items-center justify-center border border-charcoal/10 bg-charcoal/5">
                            <span className="text-2xl font-bold text-charcoal/20">
                              {host.name.charAt(0)}
                            </span>
                          </div>
                        )}
                        <div>
                          <p className="text-lg font-medium text-charcoal">{host.name}</p>
                          {host.is_primary && (
                            <span className="font-mono text-xs uppercase text-charcoal/30">
                              Primary host
                            </span>
                          )}
                        </div>
                      </div>
                      {host.bio && (
                        <div
                          className="mt-3 text-base leading-relaxed text-charcoal/60"
                          dangerouslySetInnerHTML={{ __html: host.bio }}
                        />
                      )}
                    </div>
                  ))}
                </div>
              </section>
            )}

            {/* Contact email */}
            {showEmail && typedShow.contact_email && (
              <section>
                <h3 className="text-sm font-bold uppercase tracking-wider text-charcoal/40">
                  Email
                </h3>
                <a
                  href={`mailto:${typedShow.contact_email}`}
                  className="mt-3 block text-base text-kpfk-red hover:text-kpfk-red/80"
                >
                  {typedShow.contact_email}
                </a>
              </section>
            )}

            {/* Links with icons */}
            {hasLinks && (
              <section>
                <h3 className="text-sm font-bold uppercase tracking-wider text-charcoal/40">
                  Links
                </h3>
                <ul className="mt-4 space-y-3">
                  {typedShow.website_url && (
                    <li>
                      <a
                        href={typedShow.website_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center gap-3 text-base text-charcoal/70 transition-colors hover:text-kpfk-red"
                      >
                        <IconGlobe className="h-5 w-5 flex-shrink-0" />
                        <span>Website</span>
                      </a>
                    </li>
                  )}
                  {typedShow.rss_url && (
                    <li>
                      <a
                        href={typedShow.rss_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center gap-3 text-base text-charcoal/70 transition-colors hover:text-kpfk-red"
                      >
                        <IconRss className="h-5 w-5 flex-shrink-0" />
                        <span>RSS Feed</span>
                      </a>
                    </li>
                  )}
                  {socialEntries.map(([platform, url]) => {
                    const Icon = SOCIAL_ICONS[platform];
                    const label = SOCIAL_LABELS[platform] || platform;
                    return (
                      <li key={platform}>
                        <a
                          href={url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="flex items-center gap-3 text-base text-charcoal/70 transition-colors hover:text-kpfk-red"
                        >
                          {Icon ? (
                            <Icon className="h-5 w-5 flex-shrink-0" />
                          ) : (
                            <IconGlobe className="h-5 w-5 flex-shrink-0" />
                          )}
                          <span>{label}</span>
                        </a>
                      </li>
                    );
                  })}
                </ul>
              </section>
            )}

            {/* Donate CTA */}
            <section className="border-2 border-kpfk-red p-6 text-center">
              <p className="font-serif text-xl font-bold text-charcoal">
                {donateHeading}
              </p>
              <p className="mt-2 text-base text-charcoal/60">
                {donateBody}
              </p>
              <a
                href={donateUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="mt-5 inline-block border-2 border-kpfk-red bg-kpfk-red px-7 py-3 text-base font-bold text-off-white transition-colors hover:bg-off-white hover:text-kpfk-red"
              >
                Donate Now
              </a>
            </section>

            {/* On Air Nearby */}
            {adjacentShows.length > 0 && (
              <section>
                <h3 className="text-sm font-bold uppercase tracking-wider text-charcoal/40">
                  On Air Nearby
                </h3>
                <div className="mt-4 space-y-3">
                  {adjacentShows.map((adj) => (
                    <Link
                      key={adj.slug}
                      href={`/on-air/${adj.slug}`}
                      className="block border border-charcoal/10 p-4 transition-colors hover:bg-charcoal/[0.02]"
                    >
                      <p className="font-serif text-base font-medium text-charcoal hover:text-kpfk-red">
                        {adj.title}
                      </p>
                      <p className="mt-0.5 font-mono text-xs text-charcoal/40">
                        {adj.relationship}
                      </p>
                    </Link>
                  ))}
                </div>
              </section>
            )}
          </aside>
        </div>
      </div>
    </article>
  );
}
