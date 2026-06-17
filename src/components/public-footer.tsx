import Link from "next/link";

const columns: { heading: string; links: { label: string; href: string; external?: boolean }[] }[] = [
  {
    heading: "Explore",
    links: [
      { label: "Shows", href: "/on-air" },
      { label: "Schedule", href: "/schedule" },
      { label: "Blog", href: "/blog" },
      { label: "Events", href: "/events" },
    ],
  },
  {
    heading: "Station",
    links: [
      { label: "About KPFK", href: "/about" },
      { label: "Contact", href: "/contact" },
      { label: "Volunteer", href: "/volunteer" },
      { label: "Donate", href: "https://donate.kpfk.org", external: true },
    ],
  },
];

export function PublicFooter() {
  return (
    <footer
      className="mt-auto"
      style={{ background: "var(--kpfk-ink)", color: "var(--kpfk-paper)" }}
    >
      <div className="mx-auto max-w-7xl px-6 py-14 sm:px-8">
        <div className="grid grid-cols-1 gap-10 sm:grid-cols-2 lg:grid-cols-4">
          {/* Branding */}
          <div>
            <span className="kpfk-display block text-[32px]">KPFK</span>
            <span className="kpfk-label mt-1 block" style={{ color: "var(--kpfk-ash-400)" }}>
              90.7<span style={{ color: "var(--kpfk-red)" }}>FM</span>
            </span>
            <p className="mt-4 text-base" style={{ color: "var(--kpfk-ash-400)" }}>
              Pacifica Foundation community radio in Los Angeles.
              Listener-supported since 1959.
            </p>
          </div>

          {columns.map((col) => (
            <div key={col.heading}>
              <h3 className="kpfk-label" style={{ color: "var(--kpfk-ash-400)" }}>
                {col.heading}
              </h3>
              <ul className="mt-4 space-y-3 text-base">
                {col.links.map((link) => (
                  <li key={link.label}>
                    {link.external ? (
                      <a
                        href={link.href}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="transition-colors hover:text-white"
                        style={{ color: "color-mix(in srgb, var(--kpfk-paper) 75%, transparent)" }}
                      >
                        {link.label}
                      </a>
                    ) : (
                      <Link
                        href={link.href}
                        className="transition-colors hover:text-white"
                        style={{ color: "color-mix(in srgb, var(--kpfk-paper) 75%, transparent)" }}
                      >
                        {link.label}
                      </Link>
                    )}
                  </li>
                ))}
              </ul>
            </div>
          ))}

          {/* Listen */}
          <div>
            <h3 className="kpfk-label" style={{ color: "var(--kpfk-ash-400)" }}>
              Listen
            </h3>
            <p className="mt-4 text-base" style={{ color: "var(--kpfk-ash-400)" }}>
              KPFK 90.7 FM — Los Angeles
            </p>
            <a
              href="https://kpfk.org/stream"
              target="_blank"
              rel="noopener noreferrer"
              className="mt-4 inline-block border px-5 py-2.5 text-sm font-extrabold uppercase tracking-[0.04em] transition-colors hover:bg-white/10"
              style={{ borderColor: "color-mix(in srgb, var(--kpfk-paper) 30%, transparent)" }}
            >
              Stream Online
            </a>
          </div>
        </div>

        <div
          className="mt-12 border-t pt-8 text-center"
          style={{ borderColor: "color-mix(in srgb, var(--kpfk-paper) 12%, transparent)" }}
        >
          <p className="text-sm" style={{ color: "var(--kpfk-ash-400)" }}>
            &copy; {new Date().getFullYear()} Pacifica Foundation. KPFK 90.7 FM,
            Los Angeles.
          </p>
        </div>
      </div>
    </footer>
  );
}
