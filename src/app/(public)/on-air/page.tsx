import Link from "next/link";
import Image from "next/image";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import type { Metadata } from "next";

const SUPABASE_STORAGE_URL =
  "https://czjhwhfqohpmwprhasve.supabase.co/storage/v1/object/public";

function resolveImageUrl(path: string): string {
  if (path.startsWith("http://") || path.startsWith("https://")) return path;
  return `${SUPABASE_STORAGE_URL}/${path}`;
}

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
  banner_path: string | null;
  cms_show_hosts: { name: string; is_primary: boolean }[];
}

export default async function OnAirPage() {
  const supabase = getSupabaseAdmin();

  const { data: shows } = await supabase
    .from("cms_shows")
    .select("id, title, slug, tagline, show_type, logo_path, banner_path, cms_show_hosts(name, is_primary)")
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
                className="group relative flex flex-col bg-off-white transition-colors hover:bg-charcoal/[0.02]"
              >
                {/* Card banner or logo hero area */}
                {show.banner_path ? (
                  <div className="relative h-36 w-full overflow-hidden bg-charcoal/5">
                    <Image
                      src={resolveImageUrl(show.banner_path)}
                      alt=""
                      fill
                      className="object-cover transition-transform duration-300 group-hover:scale-[1.02]"
                      sizes="(min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw"
                    />
                  </div>
                ) : show.logo_path ? (
                  <div className="flex h-36 w-full items-center justify-center bg-charcoal/[0.03]">
                    <div className="relative h-24 w-24 overflow-hidden">
                      <Image
                        src={resolveImageUrl(show.logo_path)}
                        alt=""
                        fill
                        className="object-contain"
                        sizes="96px"
                      />
                    </div>
                  </div>
                ) : (
                  <div className="flex h-36 w-full items-center justify-center bg-charcoal/[0.03]">
                    <span className="font-serif text-5xl font-bold text-charcoal/10">
                      {show.title.charAt(0)}
                    </span>
                  </div>
                )}

                {/* Card body */}
                <div className="flex flex-1 flex-col p-5">
                  <h2 className="font-serif text-xl font-bold leading-tight text-charcoal">
                    {show.title}
                  </h2>
                  {hostName && (
                    <p className="mt-1 text-sm text-charcoal/50">
                      with {hostName}
                    </p>
                  )}
                  {show.tagline && (
                    <p className="mt-2 text-sm leading-relaxed text-charcoal/60">
                      {show.tagline}
                    </p>
                  )}
                  <div className="mt-auto pt-3">
                    <span className="font-mono text-xs uppercase text-charcoal/30">
                      {show.show_type}
                    </span>
                  </div>
                </div>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
