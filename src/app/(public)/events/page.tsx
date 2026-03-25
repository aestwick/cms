import Link from "next/link";
import Image from "next/image";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getBeaconEvents } from "@/lib/beacon";
import { resolveImageUrl, formatDate, formatTime } from "@/lib/format";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Events — KPFK 90.7 FM",
  description:
    "Upcoming events from KPFK 90.7 FM and the community.",
};

const categoryLabels: Record<string, string> = {
  community: "Community",
  sponsored: "Sponsored",
  fundraising: "Fundraising",
  meeting: "Meeting",
  protest: "Protest",
  other: "Other",
  beacon: "KPFK Event",
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
  price_text?: string | null;
  is_highlighted?: boolean;
  source: "cms" | "beacon";
  ticket_url?: string | null;
}

export default async function EventsPage() {
  const supabase = getSupabaseAdmin();

  // Fetch CMS events and Beacon events in parallel
  const [cmsResult, beaconEvents] = await Promise.all([
    supabase
      .from("cms_events")
      .select(
        "id, title, slug, starts_at, ends_at, is_all_day, category, venue_name, image_path, price_text, is_highlighted"
      )
      .is("deleted_at", null)
      .gte("starts_at", new Date().toISOString())
      .order("starts_at", { ascending: true }),
    getBeaconEvents(),
  ]);

  const cmsEvents: UnifiedEvent[] = (cmsResult.data ?? []).map((e) => ({
    id: e.id,
    title: e.title,
    slug: e.slug,
    starts_at: e.starts_at,
    ends_at: e.ends_at,
    is_all_day: e.is_all_day,
    category: e.category,
    venue_name: e.venue_name,
    image_url: e.image_path ? resolveImageUrl(e.image_path) : null,
    price_text: e.price_text,
    is_highlighted: e.is_highlighted,
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

  // Merge and sort by date
  const allEvents = [...cmsEvents, ...beaconUnified].sort(
    (a, b) => new Date(a.starts_at).getTime() - new Date(b.starts_at).getTime()
  );

  const highlighted = allEvents.filter((e) => e.is_highlighted);
  const regular = allEvents.filter((e) => !e.is_highlighted);

  return (
    <div className="mx-auto max-w-7xl px-6 py-12 sm:px-8">
      <h1 className="font-serif text-4xl font-bold text-charcoal">Events</h1>
      <p className="mt-3 text-lg text-charcoal/60">
        Upcoming events from KPFK and the community
      </p>

      {/* Featured events */}
      {highlighted.length > 0 && (
        <div className="mt-10 space-y-6">
          {highlighted.map((event) => (
            <EventCard key={`${event.source}-${event.id}`} event={event} featured />
          ))}
        </div>
      )}

      {/* All upcoming events */}
      {regular.length > 0 ? (
        <div className="mt-10 grid grid-cols-1 gap-px border border-charcoal/20 bg-charcoal/10 sm:grid-cols-2 lg:grid-cols-3">
          {regular.map((event) => (
            <EventCard key={`${event.source}-${event.id}`} event={event} />
          ))}
        </div>
      ) : highlighted.length === 0 ? (
        <p className="mt-10 text-base text-charcoal/50">
          No upcoming events at this time.
        </p>
      ) : null}
    </div>
  );
}

function EventCard({
  event,
  featured = false,
}: {
  event: UnifiedEvent;
  featured?: boolean;
}) {
  const isExternal = event.source === "beacon";
  const href = isExternal
    ? event.ticket_url || `https://events.kpfk.org/public/${event.slug}`
    : `/events/${event.slug}`;

  const card = (
    <div className={featured ? "flex flex-col gap-5 sm:flex-row" : ""}>
      {event.image_url && (
        <div
          className={`relative overflow-hidden bg-charcoal/5 ${
            featured ? "h-48 w-full sm:h-48 sm:w-64" : "h-40 w-full"
          }`}
        >
          <Image
            src={event.image_url}
            alt={event.title}
            fill
            className="object-cover"
            sizes={featured ? "256px" : "300px"}
          />
        </div>
      )}
      <div className="flex flex-1 flex-col">
        <div className="flex items-start gap-2">
          <span className="rounded border border-charcoal/15 px-1.5 py-0.5 font-mono text-[10px] uppercase text-charcoal/50">
            {categoryLabels[event.category] || event.category}
          </span>
          {isExternal && (
            <span className="rounded border border-kpfk-red/20 bg-kpfk-red/5 px-1.5 py-0.5 font-mono text-[10px] uppercase text-kpfk-red">
              Tickets
            </span>
          )}
        </div>
        <h2
          className={`mt-2 font-serif font-bold leading-tight text-charcoal ${
            featured ? "text-2xl" : "text-xl"
          }`}
        >
          {event.title}
        </h2>
        <p className="mt-2 text-base text-charcoal/60">
          {formatDate(event.starts_at, { weekday: "short", year: undefined })}
          {!event.is_all_day && (
            <span className="ml-1 text-charcoal/40">
              at {formatTime(event.starts_at)}
            </span>
          )}
        </p>
        {event.venue_name && (
          <p className="mt-1 text-sm text-charcoal/50">{event.venue_name}</p>
        )}
        {event.price_text && (
          <p className="mt-1 text-sm font-medium text-charcoal/60">
            {event.price_text}
          </p>
        )}
      </div>
    </div>
  );

  if (isExternal) {
    return (
      <a
        href={href}
        target="_blank"
        rel="noopener noreferrer"
        className={`block bg-off-white transition-colors hover:bg-charcoal/[0.02] ${
          featured
            ? "border-2 border-kpfk-red p-6"
            : "p-6"
        }`}
      >
        {card}
      </a>
    );
  }

  return (
    <Link
      href={href}
      className={`block bg-off-white transition-colors hover:bg-charcoal/[0.02] ${
        featured
          ? "border-2 border-kpfk-red p-6"
          : "p-6"
      }`}
    >
      {card}
    </Link>
  );
}
