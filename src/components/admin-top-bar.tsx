"use client";

import { createBrowserClient } from "@supabase/ssr";
import { useRouter } from "next/navigation";
import type { CmsUser } from "@/lib/auth";

export function AdminTopBar({ user }: { user: CmsUser }) {
  const router = useRouter();

  async function handleSignOut() {
    const supabase = createBrowserClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );
    await supabase.auth.signOut();
    router.push("/login");
  }

  return (
    <header className="flex h-12 items-center justify-between border-b border-charcoal/10 bg-off-white px-6">
      <div />
      <div className="flex items-center gap-4">
        <span className="text-xs text-charcoal/50">
          {user.display_name || user.email}
        </span>
        <span className="rounded border border-charcoal/20 px-1.5 py-0.5 font-mono text-[10px] uppercase text-charcoal/40">
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
