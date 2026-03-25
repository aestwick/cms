import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import Link from "next/link";

const categoryLabels: Record<string, string> = {
  community: "Community",
  sponsored: "Sponsored",
  fundraising: "Fundraising",
  meeting: "Meeting",
  protest: "Protest",
  other: "Other",
};

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    timeZone: "America/Los_Angeles",
  });
}

function formatTime(iso: string): string {
  return new Date(iso).toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    timeZone: "America/Los_Angeles",
  });
}

export default async function EventsListPage() {
  const user = await requireRole("admin", "editor");
  const supabase = getSupabaseAdmin();

  const { data: events } = await supabase
    .from("cms_events")
    .select(
      "id, title, slug, category, venue_name, starts_at, ends_at, is_all_day, is_highlighted, updated_at"
    )
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .order("starts_at", { ascending: false });

  const now = new Date().toISOString();
  const upcoming = events?.filter((e) => e.starts_at >= now) ?? [];
  const past = events?.filter((e) => e.starts_at < now) ?? [];

  return (
    <div>
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-charcoal">Events</h1>
          <p className="mt-1 text-sm text-charcoal/50">
            {events?.length ?? 0} events ({upcoming.length} upcoming)
          </p>
        </div>
        <Link
          href="/admin/events/new"
          className="border-2 border-charcoal bg-charcoal px-4 py-2 text-sm font-medium text-off-white hover:bg-charcoal/90"
        >
          New event
        </Link>
      </div>

      {/* Upcoming events */}
      {upcoming.length > 0 && (
        <div className="mt-6">
          <h2 className="mb-3 text-sm font-bold uppercase tracking-wider text-charcoal/40">
            Upcoming
          </h2>
          <EventTable events={upcoming} />
        </div>
      )}

      {/* Past events */}
      {past.length > 0 && (
        <div className="mt-8">
          <h2 className="mb-3 text-sm font-bold uppercase tracking-wider text-charcoal/40">
            Past
          </h2>
          <EventTable events={past} />
        </div>
      )}

      {(!events || events.length === 0) && (
        <div className="mt-6 border border-charcoal/20 px-4 py-8 text-center text-sm text-charcoal/40">
          No events yet.{" "}
          <Link
            href="/admin/events/new"
            className="text-kpfk-red hover:underline"
          >
            Create one
          </Link>
        </div>
      )}
    </div>
  );
}

interface EventRow {
  id: string;
  title: string;
  slug: string;
  category: string;
  venue_name: string | null;
  starts_at: string;
  ends_at: string | null;
  is_all_day: boolean;
  is_highlighted: boolean;
}

function EventTable({ events }: { events: EventRow[] }) {
  return (
    <div className="border border-charcoal/20">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-charcoal/10 bg-charcoal/5 text-left">
            <th className="px-4 py-2 font-medium text-charcoal/60">Title</th>
            <th className="px-4 py-2 font-medium text-charcoal/60">Date</th>
            <th className="px-4 py-2 font-medium text-charcoal/60">
              Category
            </th>
            <th className="px-4 py-2 font-medium text-charcoal/60">Venue</th>
            <th className="px-4 py-2 font-medium text-charcoal/60" />
          </tr>
        </thead>
        <tbody>
          {events.map((event) => (
            <tr
              key={event.id}
              className="border-b border-charcoal/5 hover:bg-charcoal/[0.02]"
            >
              <td className="px-4 py-2 font-medium text-charcoal">
                <span className="flex items-center gap-2">
                  {event.title}
                  {event.is_highlighted && (
                    <span className="rounded border border-amber-500/20 bg-amber-500/5 px-1.5 py-0.5 font-mono text-[10px] uppercase text-amber-600">
                      Featured
                    </span>
                  )}
                </span>
              </td>
              <td className="px-4 py-2 text-charcoal/60">
                {formatDate(event.starts_at)}
                {!event.is_all_day && (
                  <span className="ml-1 text-charcoal/40">
                    {formatTime(event.starts_at)}
                  </span>
                )}
              </td>
              <td className="px-4 py-2">
                <span className="rounded border border-charcoal/15 px-1.5 py-0.5 font-mono text-[10px] uppercase text-charcoal/50">
                  {categoryLabels[event.category] || event.category}
                </span>
              </td>
              <td className="px-4 py-2 text-xs text-charcoal/50">
                {event.venue_name || "\u2014"}
              </td>
              <td className="px-4 py-2 text-right">
                <Link
                  href={`/admin/events/${event.id}/edit`}
                  className="text-xs text-kpfk-red hover:underline"
                >
                  Edit
                </Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
