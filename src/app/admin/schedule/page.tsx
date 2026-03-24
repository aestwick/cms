import { requireRole } from "@/lib/auth";
import { ScheduleEditor } from "@/components/schedule-editor";

export default async function AdminSchedulePage() {
  await requireRole("admin", "editor");

  return (
    <div>
      <h1 className="font-serif text-2xl font-bold text-charcoal">Schedule</h1>
      <p className="mt-1 text-sm text-charcoal/50">
        Manage the 24/7 weekly broadcast grid. Confessor sync coming in Phase 3.
      </p>
      <div className="mt-6">
        <ScheduleEditor />
      </div>
    </div>
  );
}
