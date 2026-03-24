import { requireRole } from "@/lib/auth";

export default async function AdminDashboard() {
  const user = await requireRole("admin", "editor", "host");

  return (
    <div>
      <h1 className="text-2xl font-bold text-charcoal">Dashboard</h1>
      <p className="mt-2 text-sm text-charcoal/60">
        Welcome back, {user.display_name || user.email}.
      </p>
    </div>
  );
}
