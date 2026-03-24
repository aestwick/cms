import { requireRole } from "@/lib/auth";
import { ShowForm } from "@/components/show-form";

export default async function NewShowPage() {
  await requireRole("admin", "editor");

  return (
    <div className="max-w-3xl">
      <h1 className="text-2xl font-bold text-charcoal">New Show</h1>
      <p className="mt-1 text-sm text-charcoal/50">
        Create a new show page. Hosts can be added after creation.
      </p>
      <div className="mt-6">
        <ShowForm mode="create" />
      </div>
    </div>
  );
}
