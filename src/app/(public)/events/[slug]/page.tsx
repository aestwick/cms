import { notFound } from "next/navigation";
import Image from "next/image";
import Link from "next/link";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { resolveImageUrl, formatDate, formatTime } from "@/lib/format";
import type { Metadata } from "next";

const categoryLabels: Record<string, string> = {
  community: "Community",
  sponsored: "Sponsored",
  fundraising: "Fundraising",
  meeting: "Meeting",
  protest: "Protest",
  other: "Other",
};

interface PageProps {
  params: Promise<{ slug: string }>;
}

const detailDateOpts: Intl.DateTimeFormatOptions = {
  weekday: "long",
  month: "long",
  day: "numeric",
};

export async function generateMetadata({
  params,
}: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const supabase = getSupabaseAdmin();

  const { data: event } = await supabase
    .from("cms_events")
    .select("title, venue_name, starts_at")
    .eq("slug", slug)
    .is("deleted_at", null)
    .single();

  if (!event)
    return { title: "Event Not Found — KPFK 90.7 FM" };

  return {
    title: `${event.title} — KPFK 90.7 FM`,
    description: `${event.title} on ${formatDate(event.starts_at, detailDateOpts)}${event.venue_name ? ` at ${event.venue_name}` : ""}`,
  };
}

export default async function EventDetailPage({ params }: PageProps) {
  const { slug } = await params;
  const supabase = getSupabaseAdmin();

  const { data: event } = await supabase
    .from("cms_events")
    .select("*")
    .eq("slug", slug)
    .is("deleted_at", null)
    .single();

  if (!event) notFound();

  const isPast = new Date(event.starts_at) < new Date();

  return (
    <article className="mx-auto max-w-4xl px-6 py-12 sm:px-8">
      {/* Back link */}
      <Link
        href="/events"
        className="text-sm text-charcoal/50 hover:text-charcoal"
      >
        &larr; All events
      </Link>

      {/* Header */}
      <header className="mt-6 border-b-2 border-charcoal pb-8">
        <div className="flex flex-wrap items-center gap-2">
          <span className="rounded border border-charcoal/15 px-1.5 py-0.5 font-mono text-[10px] uppercase text-charcoal/50">
            {categoryLabels[event.category] || event.category}
          </span>
          {isPast && (
            <span className="rounded border border-charcoal/15 px-1.5 py-0.5 font-mono text-[10px] uppercase text-charcoal/40">
              Past Event
            </span>
          )}
          {event.is_highlighted && (
            <span className="rounded border border-amber-500/20 bg-amber-500/5 px-1.5 py-0.5 font-mono text-[10px] uppercase text-amber-600">
              Featured
            </span>
          )}
        </div>
        <h1 className="mt-4 font-serif text-4xl font-bold leading-tight text-charcoal">
          {event.title}
        </h1>
      </header>

      <div className="mt-10 grid grid-cols-1 gap-12 lg:grid-cols-3">
        {/* Main content */}
        <div className="space-y-8 lg:col-span-2">
          {/* Image */}
          {event.image_path && (
            <div className="relative aspect-[16/9] w-full overflow-hidden border border-charcoal/10 bg-charcoal/5">
              <Image
                src={resolveImageUrl(event.image_path)}
                alt={event.title}
                fill
                className="object-cover"
                sizes="(max-width: 1024px) 100vw, 640px"
              />
            </div>
          )}

          {/* Description */}
          {event.description && (
            <div
              className="prose max-w-none text-base leading-relaxed text-charcoal/80"
              dangerouslySetInnerHTML={{ __html: event.description }}
            />
          )}

          {!event.description && (
            <p className="text-base text-charcoal/50">
              No additional details for this event.
            </p>
          )}
        </div>

        {/* Sidebar */}
        <aside className="space-y-6">
          {/* Date & Time */}
          <section className="border border-charcoal/10 p-6">
            <h3 className="text-sm font-bold uppercase tracking-wider text-charcoal/40">
              When
            </h3>
            <p className="mt-3 text-base font-medium text-charcoal">
              {formatDate(event.starts_at, detailDateOpts)}
            </p>
            {!event.is_all_day && (
              <p className="mt-1 text-base text-charcoal/60">
                {formatTime(event.starts_at)}
                {event.ends_at && <span> &ndash; {formatTime(event.ends_at)}</span>}
              </p>
            )}
            {event.is_all_day && (
              <p className="mt-1 text-sm text-charcoal/50">All day</p>
            )}
          </section>

          {/* Venue */}
          {(event.venue_name || event.venue_address) && (
            <section className="border border-charcoal/10 p-6">
              <h3 className="text-sm font-bold uppercase tracking-wider text-charcoal/40">
                Where
              </h3>
              {event.venue_name && (
                <p className="mt-3 text-base font-medium text-charcoal">
                  {event.venue_name}
                </p>
              )}
              {event.venue_address && (
                <p className="mt-1 text-base text-charcoal/60">
                  {event.venue_address}
                </p>
              )}
            </section>
          )}

          {/* Price */}
          {event.price_text && (
            <section className="border border-charcoal/10 p-6">
              <h3 className="text-sm font-bold uppercase tracking-wider text-charcoal/40">
                Price
              </h3>
              <p className="mt-3 text-base font-medium text-charcoal">
                {event.price_text}
              </p>
            </section>
          )}

          {/* External link */}
          {event.event_url && (
            <a
              href={event.event_url}
              target="_blank"
              rel="noopener noreferrer"
              className="block border-2 border-kpfk-red p-6 text-center text-base font-bold text-kpfk-red transition-colors hover:bg-kpfk-red hover:text-off-white"
            >
              More Info &rarr;
            </a>
          )}
        </aside>
      </div>
    </article>
  );
}
