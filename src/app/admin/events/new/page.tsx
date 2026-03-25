import { requireRole } from "@/lib/auth";
import { EventForm } from "@/components/event-form";

export default async function NewEventPage() {
  await requireRole("admin", "editor");

  return (
    <div className="max-w-3xl">
      <h1 className="text-2xl font-bold text-charcoal">New Event</h1>
      <p className="mt-1 text-sm text-charcoal/50">
        Create a community event, meeting, or other calendar listing.
      </p>
      <div className="mt-6">
        <EventForm mode="create" />
      </div>
    </div>
  );
}
