"use client";

import { createBrowserClient } from "@supabase/ssr";
import { useRouter } from "next/navigation";
import { useMobileSidebar } from "@/hooks/use-mobile-sidebar";
import type { CmsUser } from "@/lib/auth";

export function AdminTopBar({ user }: { user: CmsUser }) {
  const router = useRouter();
  const { toggle } = useMobileSidebar();

  async function handleSignOut() {
    const supabase = createBrowserClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );
    await supabase.auth.signOut();
    router.push("/login");
  }

  return (
    <header className="flex h-12 items-center justify-between border-b border-charcoal/10 bg-off-white px-4 md:px-6">
      {/* Hamburger — visible below lg */}
      <button
        onClick={toggle}
        className="-ml-2 p-2 lg:hidden"
        aria-label="Toggle menu"
      >
        <svg
          width="20"
          height="20"
          viewBox="0 0 20 20"
          fill="currentColor"
          className="text-charcoal"
        >
          <rect y="3" width="20" height="2" rx="1" />
          <rect y="9" width="20" height="2" rx="1" />
          <rect y="15" width="20" height="2" rx="1" />
        </svg>
      </button>

      {/* Spacer on desktop where hamburger is hidden */}
      <div className="hidden lg:block" />

      <div className="flex items-center gap-3 sm:gap-4">
        <span className="max-w-[120px] truncate text-xs text-charcoal/50 sm:max-w-none">
          {user.display_name || user.email}
        </span>
        <span className="hidden border border-charcoal/20 px-1.5 py-0.5 text-[10px] font-extrabold uppercase tracking-[0.1em] text-charcoal/50 sm:inline">
          {user.role}
        </span>
        <button
          onClick={handleSignOut}
          className="text-xs font-bold uppercase tracking-[0.06em] text-charcoal/40 transition-colors hover:text-kpfk-red"
        >
          Sign out
        </button>
      </div>
    </header>
  );
}
