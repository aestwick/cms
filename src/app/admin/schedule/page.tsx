import { requireRole } from "@/lib/auth";
import { ScheduleEditor } from "@/components/schedule-editor";

export default async function AdminSchedulePage() {
  const user = await requireRole("admin", "editor");

  return (
    <div>
      <h1 className="font-serif text-2xl font-bold text-charcoal">Schedule</h1>
      <p className="mt-1 text-sm text-charcoal/50">
        Manage the 24/7 weekly broadcast grid. Use &ldquo;Import from Confessor&rdquo; to sync.
      </p>
      <div className="mt-6">
        <ScheduleEditor userRole={user.role} />
      </div>
    </div>
  );
}
