import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { formatDate } from "@/lib/format";
import { UserRoleEditor } from "@/components/user-role-editor";
import Link from "next/link";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: "Users — KPFK CMS" };

export default async function UsersPage() {
  const user = await requireRole("admin");
  const supabase = getSupabaseAdmin();

  const { data: profiles } = await supabase
    .from("cms_profiles")
    .select("id, display_name, email, role, created_at")
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .order("created_at", { ascending: false });

  const users = profiles ?? [];

  const counts = {
    admin: users.filter((u) => u.role === "admin").length,
    editor: users.filter((u) => u.role === "editor").length,
    host: users.filter((u) => u.role === "host").length,
  };

  return (
    <div>
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-charcoal">Users</h1>
          <p className="mt-1 text-sm text-charcoal/50">
            {users.length} active user{users.length !== 1 ? "s" : ""}
          </p>
        </div>
        <Link
          href="/admin/users/invite"
          className="border-2 border-charcoal bg-charcoal px-4 py-2 text-sm font-medium text-off-white hover:bg-charcoal/90"
        >
          Invite user
        </Link>
      </div>

      {/* Stats cards */}
      <div className="mt-6 grid grid-cols-3 gap-4">
        <div className="border border-charcoal/20 px-4 py-3">
          <p className="text-xs font-bold uppercase tracking-wider text-charcoal/40">
            Admins
          </p>
          <p className="mt-1 text-2xl font-bold text-kpfk-red">
            {counts.admin}
          </p>
        </div>
        <div className="border border-charcoal/20 px-4 py-3">
          <p className="text-xs font-bold uppercase tracking-wider text-charcoal/40">
            Editors
          </p>
          <p className="mt-1 text-2xl font-bold text-charcoal">
            {counts.editor}
          </p>
        </div>
        <div className="border border-charcoal/20 px-4 py-3">
          <p className="text-xs font-bold uppercase tracking-wider text-charcoal/40">
            Hosts
          </p>
          <p className="mt-1 text-2xl font-bold text-charcoal">
            {counts.host}
          </p>
        </div>
      </div>

      {/* Users table */}
      {users.length > 0 ? (
        <div className="mt-6 overflow-x-auto border border-charcoal/20">
          <table className="w-full min-w-[600px] text-sm">
            <thead>
              <tr className="border-b border-charcoal/10 bg-charcoal/5 text-left">
                <th className="px-4 py-2 font-medium text-charcoal/60">
                  Name
                </th>
                <th className="px-4 py-2 font-medium text-charcoal/60">
                  Email
                </th>
                <th className="px-4 py-2 font-medium text-charcoal/60">
                  Role
                </th>
                <th className="px-4 py-2 font-medium text-charcoal/60">
                  Joined
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-charcoal/10">
              {users.map((u) => (
                <tr
                  key={u.id}
                  className="hover:bg-charcoal/[0.02]"
                >
                  <td className="px-4 py-2 font-medium text-charcoal">
                    {u.display_name || "\u2014"}
                  </td>
                  <td className="px-4 py-2 font-mono text-xs text-charcoal/60">
                    {u.email}
                  </td>
                  <td className="px-4 py-2">
                    <UserRoleEditor userId={u.id} currentRole={u.role} />
                  </td>
                  <td className="px-4 py-2 font-mono text-xs text-charcoal/50">
                    {formatDate(u.created_at)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="mt-6 border border-charcoal/20 px-4 py-8 text-center text-sm text-charcoal/40">
          No users yet.{" "}
          <Link
            href="/admin/users/invite"
            className="text-kpfk-red hover:underline"
          >
            Invite one
          </Link>
        </div>
      )}
    </div>
  );
}
