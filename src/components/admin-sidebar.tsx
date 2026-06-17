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

interface NavGroup {
  heading: string;
  items: NavItem[];
}

const navGroups: NavGroup[] = [
  {
    heading: "Overview",
    items: [
      { label: "Dashboard", href: "/admin", roles: ["admin", "editor", "host"] },
    ],
  },
  {
    heading: "Content",
    items: [
      { label: "Shows", href: "/admin/shows", roles: ["admin", "editor"] },
      { label: "Blog", href: "/admin/blog", roles: ["admin", "editor"] },
      { label: "Pages", href: "/admin/pages", roles: ["admin", "editor"] },
      { label: "Events", href: "/admin/events", roles: ["admin", "editor"] },
      { label: "Schedule", href: "/admin/schedule", roles: ["admin", "editor"] },
      { label: "Media", href: "/admin/media", roles: ["admin", "editor"] },
      { label: "Tags", href: "/admin/tags", roles: ["admin", "editor"] },
    ],
  },
  {
    heading: "Station",
    items: [
      { label: "Newsletter", href: "/admin/newsletter", roles: ["admin", "editor"] },
      { label: "Sponsorship", href: "/admin/sponsorship", roles: ["admin"] },
      { label: "Flags", href: "/admin/flags", roles: ["admin"] },
      { label: "Users", href: "/admin/users", roles: ["admin"] },
      { label: "Settings", href: "/admin/settings", roles: ["admin"] },
    ],
  },
];

export function AdminSidebar({ role }: { role: CmsRole }) {
  const pathname = usePathname();
  const { isOpen, close } = useMobileSidebar();
  const isMobile = useIsMobile();

  const visibleGroups = navGroups
    .map((group) => ({
      ...group,
      items: group.items.filter((item) => item.roles.includes(role)),
    }))
    .filter((group) => group.items.length > 0);

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
          fixed inset-y-0 left-0 z-40 flex w-64 flex-col border-r text-off-white
          transition-transform duration-200 ease-in-out
          ${isMobile ? (isOpen ? "translate-x-0" : "-translate-x-full") : ""}
          lg:relative lg:translate-x-0
        `}
        style={{ background: "var(--kpfk-ink)", borderColor: "color-mix(in srgb, var(--kpfk-paper) 12%, transparent)" }}
      >
        <div
          className="border-b px-5 py-5"
          style={{ borderColor: "color-mix(in srgb, var(--kpfk-paper) 12%, transparent)" }}
        >
          <Link
            href="/admin"
            className="block leading-none"
            onClick={isMobile ? close : undefined}
          >
            <span className="kpfk-display block text-2xl text-off-white">KPFK</span>
            <span className="kpfk-label mt-1 block" style={{ color: "var(--kpfk-ash-400)" }}>
              90.7<span style={{ color: "var(--kpfk-red)" }}>FM</span> · CMS
            </span>
          </Link>
        </div>

        <nav className="flex-1 overflow-y-auto py-4">
          {visibleGroups.map((group) => (
            <div key={group.heading} className="mb-4">
              <p
                className="px-5 pb-1.5 text-[11px] font-extrabold uppercase tracking-[0.14em]"
                style={{ color: "var(--kpfk-ash-400)" }}
              >
                {group.heading}
              </p>
              {group.items.map((item) => {
                const isActive =
                  item.href === "/admin"
                    ? pathname === "/admin"
                    : pathname.startsWith(item.href);

                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={isMobile ? close : undefined}
                    className="block px-5 py-2.5 text-base font-medium transition-colors"
                    style={
                      isActive
                        ? {
                            color: "#fff",
                            background: "color-mix(in srgb, var(--kpfk-paper) 8%, transparent)",
                            boxShadow: "inset 3px 0 0 var(--kpfk-red)",
                          }
                        : { color: "color-mix(in srgb, var(--kpfk-paper) 62%, transparent)" }
                    }
                  >
                    {item.label}
                  </Link>
                );
              })}
            </div>
          ))}
        </nav>

        <div
          className="border-t px-5 py-4"
          style={{ borderColor: "color-mix(in srgb, var(--kpfk-paper) 12%, transparent)" }}
        >
          <p className="kpfk-label" style={{ color: "var(--kpfk-ash-400)" }}>
            KPFK 90.7 FM
          </p>
        </div>
      </aside>
    </>
  );
}
