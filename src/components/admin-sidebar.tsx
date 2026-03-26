"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useMobileSidebar, useIsMobile } from "@/hooks/use-mobile-sidebar";
import type { CmsRole } from "@/lib/auth";

interface NavItem {
  label: string;
  href: string;
  roles: CmsRole[];
}

const navItems: NavItem[] = [
  { label: "Dashboard", href: "/admin", roles: ["admin", "editor", "host"] },
  { label: "Shows", href: "/admin/shows", roles: ["admin", "editor"] },
  { label: "Media", href: "/admin/media", roles: ["admin", "editor"] },
  { label: "Blog", href: "/admin/blog", roles: ["admin", "editor"] },
  { label: "Pages", href: "/admin/pages", roles: ["admin", "editor"] },
  { label: "Events", href: "/admin/events", roles: ["admin", "editor"] },
  { label: "Schedule", href: "/admin/schedule", roles: ["admin", "editor"] },
  { label: "Flags", href: "/admin/flags", roles: ["admin"] },
  { label: "Users", href: "/admin/users", roles: ["admin"] },
  { label: "Settings", href: "/admin/settings", roles: ["admin"] },
];

export function AdminSidebar({ role }: { role: CmsRole }) {
  const pathname = usePathname();
  const { isOpen, close } = useMobileSidebar();
  const isMobile = useIsMobile();

  const visibleItems = navItems.filter((item) => item.roles.includes(role));

  return (
    <>
      {/* Backdrop — mobile only */}
      {isMobile && isOpen && (
        <div
          className="fixed inset-0 z-30 bg-charcoal/50"
          onClick={close}
          onTouchStart={close}
        />
      )}

      <aside
        className={`
          fixed inset-y-0 left-0 z-40 flex w-56 flex-col border-r border-charcoal/20 bg-charcoal text-off-white
          transition-transform duration-200 ease-in-out
          ${isMobile ? (isOpen ? "translate-x-0" : "-translate-x-full") : ""}
          lg:relative lg:translate-x-0
        `}
      >
        <div className="border-b border-off-white/10 px-4 py-4">
          <Link href="/admin" className="block" onClick={isMobile ? close : undefined}>
            <span className="text-lg font-bold tracking-tight">KPFK</span>
            <span className="ml-1.5 font-mono text-xs text-off-white/50">
              CMS
            </span>
          </Link>
        </div>

        <nav className="flex-1 overflow-y-auto py-3">
          {visibleItems.map((item) => {
            const isActive =
              item.href === "/admin"
                ? pathname === "/admin"
                : pathname.startsWith(item.href);

            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={isMobile ? close : undefined}
                className={`block px-4 py-3 text-sm transition-colors lg:py-2 ${
                  isActive
                    ? "bg-off-white/10 font-medium text-off-white"
                    : "text-off-white/60 hover:bg-off-white/5 hover:text-off-white"
                }`}
              >
                {item.label}
              </Link>
            );
          })}
        </nav>

        <div className="border-t border-off-white/10 px-4 py-3">
          <p className="font-mono text-xs text-off-white/30">KPFK 90.7 FM</p>
        </div>
      </aside>
    </>
  );
}
