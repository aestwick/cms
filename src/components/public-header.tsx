import Link from "next/link";
import Image from "next/image";
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
        <Link href="/" className="block">
          <Image
            src="https://admin.kpfk.org/images/Kpfk-horizontal.svg"
            alt="KPFK 90.7 FM"
            width={180}
            height={48}
            className="h-10 w-auto sm:h-12"
            priority
            unoptimized
          />
        </Link>

        <div className="flex items-center gap-5">
          <NowPlayingWidget />
          <a
            href="https://kpfk.org/stream"
            target="_blank"
            rel="noopener noreferrer"
            className="btn-editorial btn-editorial--primary"
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
