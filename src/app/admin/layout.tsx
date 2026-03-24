import { getCmsUser } from "@/lib/auth";
import { redirect } from "next/navigation";
import { AdminSidebar } from "@/components/admin-sidebar";
import { AdminTopBar } from "@/components/admin-top-bar";

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const user = await getCmsUser();

  if (!user) {
    redirect("/login");
  }

  return (
    <div className="flex h-screen overflow-hidden">
      <AdminSidebar role={user.role} />
      <div className="flex flex-1 flex-col overflow-hidden">
        <AdminTopBar user={user} />
        <main className="flex-1 overflow-y-auto bg-off-white p-6">
          {children}
        </main>
      </div>
    </div>
  );
}
