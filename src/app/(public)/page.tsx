import Link from "next/link";
import Image from "next/image";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getBeaconEvents } from "@/lib/beacon";
import { resolveImageUrl, formatDate, formatTime, formatTime24 } from "@/lib/format";
import NewsletterSignup from "@/components/newsletter-signup";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "KPFK 90.7 FM — Pacifica Community Radio Los Angeles",
  description:
    "Listener-supported community radio since 1959. News, music, culture, and public affairs programming for Los Angeles and beyond.",
};

interface UnifiedEvent {
  id: string;
  title: string;
  slug: string;
  starts_at: string;
  ends_at?: string | null;
  is_all_day?: boolean;
  category: string;
  venue_name?: string | null;
  image_url?: string | null;
  source: "cms" | "beacon";
  ticket_url?: string | null;
}

export default async function HomePage() {
  const supabase = getSupabaseAdmin();

  // Fetch all data in parallel
  const [scheduleResult, postsResult, cmsEventsResult, beaconEvents] =
    await Promise.all([
      supabase
        .from("cms_schedule_slots")
        .select(
          "id, show_id, day_of_week, start_time, end_time, label, cms_shows(id, title, slug)"
        )
        .eq("is_recurring", true)
        .eq("day_of_week", new Date().getDay())
        .order("start_time", { ascending: true })
        .limit(6),
      supabase
        .from("cms_posts")
        .select(
          "id, title, slug, excerpt, body, featured_image_path, published_at, is_featured, cms_shows(title, slug)"
        )
        .eq("status", "published")
        .is("deleted_at", null)
        .order("published_at", { ascending: false })
        .limit(4),
      supabase
        .from("cms_events")
        .select(
          "id, title, slug, starts_at, ends_at, is_all_day, category, venue_name, image_path"
        )
        .is("deleted_at", null)
        .gte("starts_at", new Date().toISOString())
        .order("starts_at", { ascending: true })
        .limit(8),
      getBeaconEvents(),
    ]);

  const scheduleSlots = scheduleResult.data ?? [];
  const recentPosts = postsResult.data ?? [];

  // Merge CMS + Beacon events
  const cmsEvents: UnifiedEvent[] = (cmsEventsResult.data ?? []).map((e) => ({
    id: e.id,
    title: e.title,
    slug: e.slug,
    starts_at: e.starts_at,
    ends_at: e.ends_at,
    is_all_day: e.is_all_day,
    category: e.category,
    venue_name: e.venue_name,
    image_url: e.image_path ? resolveImageUrl(e.image_path) : null,
    source: "cms",
  }));

  const beaconUnified: UnifiedEvent[] = beaconEvents.map((e) => ({
    id: e.id,
    title: e.title,
    slug: e.slug,
    starts_at: e.starts_at,
    ends_at: e.ends_at,
    category: "beacon",
    venue_name: e.venue,
    image_url: e.image_url,
    ticket_url: e.ticket_url,
    source: "beacon",
  }));

  const upcomingEvents = [...cmsEvents, ...beaconUnified]
    .sort(
      (a, b) =>
        new Date(a.starts_at).getTime() - new Date(b.starts_at).getTime()
    )
    .slice(0, 4);

  const dayNames = [
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ];
  const todayName = dayNames[new Date().getDay()];

  return (
    <div className="mx-auto max-w-7xl px-6 py-12 sm:px-8">
      {/* ------------------------------------------------------------------ */}
      {/* Hero / Now Playing                                                  */}
      {/* ------------------------------------------------------------------ */}
      <section className="card-editorial p-8 text-center sm:p-12">
        <p className="show-card__type">
          Pacifica Foundation Community Radio — Los Angeles
        </p>
        <h1 className="mt-4 font-serif text-5xl font-bold text-charcoal sm:text-6xl">
          KPFK 90.7 FM
        </h1>
        <p className="mt-3 font-serif text-lg text-charcoal/60">
          Listener-supported since 1959
        </p>

        <div className="mt-8 flex flex-wrap items-center justify-center gap-4">
          <a
            href="#"
            className="btn-editorial btn-editorial--primary inline-flex items-center gap-2"
          >
            <span aria-hidden="true" className="text-lg">&#9654;</span>
            Listen Live
          </a>
          <a
            href="https://donate.kpfk.org"
            target="_blank"
            rel="noopener noreferrer"
            className="btn-editorial btn-editorial--secondary"
          >
            Support KPFK
          </a>
        </div>
      </section>

      {/* ------------------------------------------------------------------ */}
      {/* Two-column: Schedule + Blog                                         */}
      {/* ------------------------------------------------------------------ */}
      <div className="mt-12 grid grid-cols-1 gap-px border-2 border-charcoal bg-charcoal/10 lg:grid-cols-3">
        {/* Today's Schedule */}
        <div className="bg-off-white p-6 lg:col-span-1">
          <div className="flex items-baseline justify-between">
            <h2 className="font-serif text-2xl font-bold text-charcoal">
              Today
            </h2>
            <span className="show-card__type">
              {todayName}
            </span>
          </div>

          {scheduleSlots.length > 0 ? (
            <ul className="mt-5 divide-y divide-charcoal/10">
              {scheduleSlots.map((slot: any) => {
                const show = slot.cms_shows;
                return (
                  <li key={slot.id} className="py-3 first:pt-0 last:pb-0">
                    <p className="font-mono text-xs text-charcoal/40">
                      {formatTime24(slot.start_time)}
                      {" — "}
                      {formatTime24(slot.end_time)}
                    </p>
                    {show ? (
                      <Link
                        href={`/on-air/${show.slug}`}
                        className="mt-0.5 block font-serif text-base font-semibold text-charcoal hover:text-kpfk-red"
                      >
                        {show.title}
                      </Link>
                    ) : (
                      <p className="mt-0.5 font-serif text-base font-semibold text-charcoal">
                        {slot.label || "Programming"}
                      </p>
                    )}
                  </li>
                );
              })}
            </ul>
          ) : (
            <p className="mt-5 text-sm text-charcoal/40">
              No schedule data for today.
            </p>
          )}

          <Link
            href="/schedule"
            className="mt-5 inline-block font-mono text-xs font-bold uppercase tracking-wide text-kpfk-red hover:underline"
          >
            Full Schedule &rarr;
          </Link>
        </div>

        {/* Recent Blog Posts */}
        <div className="bg-off-white p-6 lg:col-span-2">
          <div className="flex items-baseline justify-between">
            <h2 className="font-serif text-2xl font-bold text-charcoal">
              Latest
            </h2>
            <Link
              href="/blog"
              className="mono-link"
            >
              All Posts &rarr;
            </Link>
          </div>

          {recentPosts.length > 0 ? (
            <div className="mt-5 grid grid-cols-1 gap-6 sm:grid-cols-2">
              {recentPosts.map((post: any) => (
                <article key={post.id} className="group">
                  {post.featured_image_path && (
                    <div className="relative mb-3 h-40 w-full overflow-hidden bg-charcoal/5">
                      <Image
                        src={resolveImageUrl(post.featured_image_path)}
                        alt={post.title}
                        fill
                        className="object-cover transition-transform group-hover:scale-[1.02]"
                        sizes="(min-width: 640px) 50vw, 100vw"
                      />
                    </div>
                  )}
                  {post.cms_shows && (
                    <p className="show-card__type">
                      {(post.cms_shows as any).title}
                    </p>
                  )}
                  <Link href={`/blog/${post.slug}`}>
                    <h3 className="mt-1 font-serif text-lg font-bold leading-snug text-charcoal group-hover:text-kpfk-red">
                      {post.title}
                    </h3>
                  </Link>
                  {post.excerpt && (
                    <p className="mt-1.5 line-clamp-2 text-sm text-charcoal/60">
                      {post.excerpt}
                    </p>
                  )}
                  {post.published_at && (
                    <p className="mt-2 font-mono text-xs text-charcoal/30">
                      {formatDate(post.published_at)}
                    </p>
                  )}
                </article>
              ))}
            </div>
          ) : (
            <p className="mt-5 text-sm text-charcoal/40">
              No posts yet.
            </p>
          )}
        </div>
      </div>

      {/* ------------------------------------------------------------------ */}
      {/* Upcoming Events                                                     */}
      {/* ------------------------------------------------------------------ */}
      <section className="mt-12">
        <div className="flex items-baseline justify-between">
          <h2 className="font-serif text-2xl font-bold text-charcoal">
            Upcoming Events
          </h2>
          <Link
            href="/events"
            className="mono-link"
          >
            All Events &rarr;
          </Link>
        </div>

        {upcomingEvents.length > 0 ? (
          <div className="mt-5 grid grid-cols-1 gap-px border-2 border-charcoal/20 bg-charcoal/10 sm:grid-cols-2 lg:grid-cols-4">
            {upcomingEvents.map((event) => {
              const isExternal = event.source === "beacon";
              const href = isExternal
                ? event.ticket_url ||
                  `https://events.kpfk.org/public/${event.slug}`
                : `/events/${event.slug}`;

              const inner = (
                <div className="flex h-full flex-col">
                  {event.image_url && (
                    <div className="relative h-32 w-full overflow-hidden bg-charcoal/5">
                      <Image
                        src={event.image_url}
                        alt={event.title}
                        fill
                        className="object-cover"
                        sizes="(min-width: 1024px) 25vw, (min-width: 640px) 50vw, 100vw"
                      />
                    </div>
                  )}
                  <div className="flex flex-1 flex-col p-5">
                    <p className="font-mono text-xs text-charcoal/40">
                      {formatDate(event.starts_at, {
                        weekday: "short",
                        year: undefined,
                      })}
                      {!event.is_all_day && (
                        <span className="ml-1 text-charcoal/30">
                          {formatTime(event.starts_at)}
                        </span>
                      )}
                    </p>
                    <h3 className="mt-1.5 font-serif text-base font-bold leading-snug text-charcoal">
                      {event.title}
                    </h3>
                    {event.venue_name && (
                      <p className="mt-1 text-xs text-charcoal/40">
                        {event.venue_name}
                      </p>
                    )}
                    {isExternal && (
                      <span className="mt-auto pt-3">
                        <span className="badge badge--accent">Tickets</span>
                      </span>
                    )}
                  </div>
                </div>
              );

              if (isExternal) {
                return (
                  <a
                    key={`beacon-${event.id}`}
                    href={href}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="block bg-off-white transition-colors hover:bg-charcoal/[0.02]"
                  >
                    {inner}
                  </a>
                );
              }

              return (
                <Link
                  key={`cms-${event.id}`}
                  href={href}
                  className="block bg-off-white transition-colors hover:bg-charcoal/[0.02]"
                >
                  {inner}
                </Link>
              );
            })}
          </div>
        ) : (
          <p className="mt-5 text-sm text-charcoal/40">
            No upcoming events at this time.
          </p>
        )}
      </section>

      {/* ------------------------------------------------------------------ */}
      {/* Newsletter Signup                                                   */}
      {/* ------------------------------------------------------------------ */}
      <section className="card-editorial mt-12 p-8 sm:p-10">
        <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:gap-10">
          <div className="flex-1">
            <h2 className="font-serif text-2xl font-bold text-charcoal">
              Stay Connected
            </h2>
            <p className="mt-2 text-base text-charcoal/60">
              Get the KPFK newsletter — programming highlights, events, and
              station news delivered to your inbox.
            </p>
          </div>
          <div className="w-full lg:w-auto lg:min-w-[28rem]">
            <NewsletterSignup />
          </div>
        </div>
      </section>
    </div>
  );
}
