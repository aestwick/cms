import Link from "next/link";
import { NowPlayingWidget } from "@/components/now-playing-widget";

const navLinks = [
  { label: "On Air", href: "/on-air" },
  { label: "Schedule", href: "/schedule" },
  { label: "Blog", href: "/blog" },
  { label: "Events", href: "/events" },
  { label: "About", href: "/about" },
];

export function PublicHeader() {
  return (
    <header className="border-b-2 border-charcoal bg-off-white">
      {/* Top bar: branding + Listen Live */}
      <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-6 sm:px-8">
        <Link href="/" className="flex items-baseline gap-2">
          <span className="font-serif text-3xl font-bold tracking-tight text-charcoal">
            KPFK
          </span>
          <span className="font-mono text-sm text-charcoal/50">90.7 FM</span>
        </Link>

        <div className="flex items-center gap-5">
          <NowPlayingWidget />
          <a
            href="https://kpfk.org/stream"
            target="_blank"
            rel="noopener noreferrer"
            className="border-2 border-kpfk-red bg-kpfk-red px-5 py-2.5 text-base font-bold text-off-white transition-colors hover:bg-off-white hover:text-kpfk-red"
          >
            Listen Live
          </a>
        </div>
      </div>

      {/* Navigation bar */}
      <nav className="border-t border-charcoal/10">
        <div className="mx-auto flex max-w-7xl items-center gap-1 overflow-x-auto px-6 sm:px-8">
          {navLinks.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className="whitespace-nowrap px-5 py-4 text-base font-medium text-charcoal/70 transition-colors hover:text-charcoal"
            >
              {link.label}
            </Link>
          ))}
          <div className="ml-auto">
            <a
              href="https://donate.kpfk.org"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-block px-5 py-4 text-base font-bold text-kpfk-red transition-colors hover:text-kpfk-red/80"
            >
              Donate
            </a>
          </div>
        </div>
      </nav>
    </header>
  );
}
