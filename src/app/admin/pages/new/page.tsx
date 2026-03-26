import { requireRole } from "@/lib/auth";
import { PageForm } from "@/components/page-form";

export default async function NewPagePage() {
  await requireRole("admin", "editor");

  return (
    <div>
      <h1 className="text-2xl font-bold text-charcoal">New Page</h1>
      <div className="mt-6">
        <PageForm mode="create" />
      </div>
    </div>
  );
}
