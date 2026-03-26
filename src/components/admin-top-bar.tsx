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
        className="p-2 -ml-2 lg:hidden"
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
        <span className="hidden rounded border border-charcoal/20 px-1.5 py-0.5 font-mono text-[10px] uppercase text-charcoal/40 sm:inline">
          {user.role}
        </span>
        <button
          onClick={handleSignOut}
          className="text-xs text-charcoal/40 hover:text-charcoal"
        >
          Sign out
        </button>
      </div>
    </header>
  );
}
