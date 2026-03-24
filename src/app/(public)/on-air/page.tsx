import Link from "next/link";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "On Air — KPFK 90.7 FM",
  description: "Browse all active shows on KPFK 90.7 FM community radio.",
};

interface Show {
  id: string;
  title: string;
  slug: string;
  tagline: string | null;
  show_type: string;
  logo_path: string | null;
  cms_show_hosts: { name: string; is_primary: boolean }[];
}

export default async function OnAirPage() {
  const supabase = getSupabaseAdmin();

  const { data: shows } = await supabase
    .from("cms_shows")
    .select("id, title, slug, tagline, show_type, logo_path, cms_show_hosts(name, is_primary)")
    .eq("is_active", true)
    .is("deleted_at", null)
    .order("sort_order", { ascending: true })
    .order("title", { ascending: true });

  const allShows = (shows ?? []) as Show[];

  return (
    <div className="mx-auto max-w-7xl px-6 py-12 sm:px-8">
      <h1 className="font-serif text-4xl font-bold text-charcoal">On Air</h1>
      <p className="mt-3 text-lg text-charcoal/60">
        All active shows on KPFK 90.7 FM
      </p>

      {allShows.length === 0 ? (
        <p className="mt-10 text-base text-charcoal/50">No shows available yet.</p>
      ) : (
        <div className="mt-10 grid grid-cols-1 gap-px border border-charcoal/20 bg-charcoal/10 sm:grid-cols-2 lg:grid-cols-3">
          {allShows.map((show) => {
            const primaryHost = show.cms_show_hosts?.find((h) => h.is_primary);
            const hostName = primaryHost?.name || show.cms_show_hosts?.[0]?.name;

            return (
              <Link
                key={show.id}
                href={`/on-air/${show.slug}`}
                className="flex flex-col bg-off-white p-6 transition-colors hover:bg-charcoal/[0.02]"
              >
                <div className="flex items-start gap-4">
                  {show.logo_path ? (
                    <div className="h-14 w-14 flex-shrink-0 border border-charcoal/10 bg-charcoal/5" />
                  ) : (
                    <div className="flex h-14 w-14 flex-shrink-0 items-center justify-center border border-charcoal/10 bg-charcoal/5">
                      <span className="font-serif text-xl font-bold text-charcoal/30">
                        {show.title.charAt(0)}
                      </span>
                    </div>
                  )}
                  <div className="min-w-0 flex-1">
                    <h2 className="font-serif text-xl font-bold leading-tight text-charcoal">
                      {show.title}
                    </h2>
                    {hostName && (
                      <p className="mt-1 text-base text-charcoal/50">
                        with {hostName}
                      </p>
                    )}
                  </div>
                </div>
                {show.tagline && (
                  <p className="mt-3 text-base leading-relaxed text-charcoal/60">
                    {show.tagline}
                  </p>
                )}
                <div className="mt-auto pt-4">
                  <span className="font-mono text-xs uppercase text-charcoal/30">
                    {show.show_type}
                  </span>
                </div>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
