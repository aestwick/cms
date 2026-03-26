import { requireRole } from "@/lib/auth";
import { SettingsForm } from "@/components/settings-form";

export const dynamic = "force-dynamic";

export default async function AdminSettingsPage() {
  await requireRole("admin");

  return (
    <div className="space-y-8">
      <div>
        <h1 className="font-serif text-3xl font-bold text-charcoal">
          Station Settings
        </h1>
        <p className="mt-1 text-sm text-charcoal/60">
          Manage station configuration, API endpoints, and social links.
        </p>
      </div>

      <SettingsForm />
    </div>
  );
}
