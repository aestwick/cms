import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { notFound } from "next/navigation";
import { EventForm } from "@/components/event-form";

function toLocalDatetime(iso: string | null): string {
  if (!iso) return "";
  // Format as YYYY-MM-DDTHH:mm in LA timezone for datetime-local input
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: "America/Los_Angeles",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).formatToParts(new Date(iso));
  const get = (type: string) => parts.find((p) => p.type === type)?.value ?? "00";
  return `${get("year")}-${get("month")}-${get("day")}T${get("hour")}:${get("minute")}`;
}

export default async function EditEventPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const user = await requireRole("admin", "editor");
  const { id } = await params;
  const supabase = getSupabaseAdmin();

  const { data: event } = await supabase
    .from("cms_events")
    .select("*")
    .eq("id", id)
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .single();

  if (!event) {
    notFound();
  }

  return (
    <div className="max-w-3xl">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-charcoal">
            Edit: {event.title}
          </h1>
          <p className="mt-1 font-mono text-xs text-charcoal/40">
            /events/{event.slug}
          </p>
        </div>
        {event.is_highlighted && (
          <span className=" border border-amber-500/20 bg-amber-500/5 px-2 py-1 text-xs text-amber-600">
            Featured
          </span>
        )}
      </div>

      <div className="mt-6">
        <EventForm
          mode="edit"
          eventId={id}
          initialData={{
            title: event.title,
            slug: event.slug,
            description: event.description || "",
            category: event.category,
            venue_name: event.venue_name || "",
            venue_address: event.venue_address || "",
            event_url: event.event_url || "",
            image_path: event.image_path || "",
            price_text: event.price_text || "",
            starts_at: toLocalDatetime(event.starts_at),
            ends_at: toLocalDatetime(event.ends_at),
            is_all_day: event.is_all_day,
            is_highlighted: event.is_highlighted,
          }}
        />
      </div>
    </div>
  );
}
