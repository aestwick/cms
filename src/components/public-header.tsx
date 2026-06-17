import Link from "next/link";
import { NowPlayingWidget } from "@/components/now-playing-widget";
import { ThemeToggle } from "@/components/theme-toggle";
import { getSupabaseAdmin } from "@/lib/supabase/admin";

const navLinks = [
  { label: "On Air", href: "/on-air" },
  { label: "Schedule", href: "/schedule" },
  { label: "Blog", href: "/blog" },
  { label: "Events", href: "/events" },
  { label: "About", href: "/about" },
];

// Top-level coverage areas flagged for the nav. Resilient: if the
// categories table isn't present yet (migration unapplied), the nav
// simply renders without them rather than breaking every page.
async function getNavCategories(): Promise<{ label: string; href: string }[]> {
  try {
    const supabase = getSupabaseAdmin();
    const { data, error } = await supabase
      .from("cms_categories")
      .select("name, slug")
      .is("parent_id", null)
      .eq("show_in_nav", true)
      .is("deleted_at", null)
      .order("sort_order")
      .order("name");
    if (error || !data) return [];
    return data.map((c) => ({ label: c.name, href: `/category/${c.slug}` }));
  } catch {
    return [];
  }
}

function Wordmark() {
  return (
    <Link href="/" className="block leading-none" aria-label="KPFK 90.7 FM home">
      <span
        className="kpfk-display block text-[26px] sm:text-[30px]"
        style={{ color: "var(--bar-txt)" }}
      >
        KPFK
      </span>
      <span className="kpfk-label mt-1 block" style={{ color: "var(--bar-muted)" }}>
        90.7<span style={{ color: "var(--kpfk-red)" }}>FM</span> · Los Angeles
      </span>
    </Link>
  );
}

export async function PublicHeader() {
  const navCategories = await getNavCategories();
  return (
    <header style={{ background: "var(--bar)", color: "var(--bar-txt)" }}>
      {/* Top bar: branding + listen / donate */}
      <div className="mx-auto flex max-w-7xl items-center justify-between gap-4 px-6 py-5 sm:px-8">
        <Wordmark />

        <div className="flex items-center gap-3 sm:gap-5">
          <NowPlayingWidget />
          <ThemeToggle />
          <a
            href="https://kpfk.org/stream"
            target="_blank"
            rel="noopener noreferrer"
            className="border border-kpfk-red bg-kpfk-red px-5 py-2.5 text-sm font-extrabold uppercase tracking-[0.04em] text-white transition-colors hover:bg-kpfk-red-press"
          >
            Listen Live
          </a>
        </div>
      </div>

      {/* Navigation bar */}
      <nav
        className="border-t"
        style={{ borderColor: "color-mix(in srgb, var(--bar-txt) 14%, transparent)" }}
      >
        <div className="mx-auto flex max-w-7xl items-center gap-1 overflow-x-auto px-6 sm:px-8">
          {navLinks.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className="whitespace-nowrap px-4 py-3.5 text-sm font-bold uppercase tracking-[0.04em] transition-colors"
              style={{ color: "var(--bar-muted)" }}
            >
              {link.label}
            </Link>
          ))}
          {navCategories.map((cat) => (
            <Link
              key={cat.href}
              href={cat.href}
              className="whitespace-nowrap px-4 py-3.5 text-sm font-bold uppercase tracking-[0.04em] transition-colors"
              style={{ color: "var(--bar-muted)" }}
            >
              {cat.label}
            </Link>
          ))}
          <a
            href="https://donate.kpfk.org"
            target="_blank"
            rel="noopener noreferrer"
            className="ml-auto whitespace-nowrap px-4 py-3.5 text-sm font-extrabold uppercase tracking-[0.04em] transition-colors"
            style={{ color: "var(--kpfk-red)" }}
          >
            Donate
          </a>
        </div>
      </nav>
    </header>
  );
}
