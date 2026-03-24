import Link from "next/link";

export function PublicFooter() {
  return (
    <footer className="border-t-2 border-charcoal bg-charcoal text-off-white">
      <div className="mx-auto max-w-7xl px-6 py-14 sm:px-8">
        <div className="grid grid-cols-1 gap-10 sm:grid-cols-2 lg:grid-cols-4">
          {/* Branding */}
          <div>
            <span className="font-serif text-2xl font-bold">KPFK 90.7 FM</span>
            <p className="mt-3 text-base text-off-white/60">
              Pacifica Foundation community radio in Los Angeles. Listener-supported since 1959.
            </p>
          </div>

          {/* Navigation */}
          <div>
            <h3 className="text-sm font-bold uppercase tracking-wider text-off-white/40">
              Explore
            </h3>
            <ul className="mt-4 space-y-3 text-base">
              <li>
                <Link href="/on-air" className="text-off-white/70 hover:text-off-white">
                  Shows
                </Link>
              </li>
              <li>
                <Link href="/schedule" className="text-off-white/70 hover:text-off-white">
                  Schedule
                </Link>
              </li>
              <li>
                <Link href="/blog" className="text-off-white/70 hover:text-off-white">
                  Blog
                </Link>
              </li>
              <li>
                <Link href="/events" className="text-off-white/70 hover:text-off-white">
                  Events
                </Link>
              </li>
            </ul>
          </div>

          {/* About */}
          <div>
            <h3 className="text-sm font-bold uppercase tracking-wider text-off-white/40">
              Station
            </h3>
            <ul className="mt-4 space-y-3 text-base">
              <li>
                <Link href="/about" className="text-off-white/70 hover:text-off-white">
                  About KPFK
                </Link>
              </li>
              <li>
                <Link href="/contact" className="text-off-white/70 hover:text-off-white">
                  Contact
                </Link>
              </li>
              <li>
                <Link href="/volunteer" className="text-off-white/70 hover:text-off-white">
                  Volunteer
                </Link>
              </li>
              <li>
                <a
                  href="https://donate.kpfk.org"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-off-white/70 hover:text-off-white"
                >
                  Donate
                </a>
              </li>
            </ul>
          </div>

          {/* Listen */}
          <div>
            <h3 className="text-sm font-bold uppercase tracking-wider text-off-white/40">
              Listen
            </h3>
            <p className="mt-4 text-base text-off-white/60">
              KPFK 90.7 FM — Los Angeles
            </p>
            <a
              href="https://kpfk.org/stream"
              target="_blank"
              rel="noopener noreferrer"
              className="mt-4 inline-block border border-off-white/30 px-5 py-2.5 text-base font-medium text-off-white transition-colors hover:border-off-white hover:bg-off-white/10"
            >
              Stream Online
            </a>
          </div>
        </div>

        <div className="mt-12 border-t border-off-white/10 pt-8 text-center">
          <p className="font-mono text-sm text-off-white/30">
            &copy; {new Date().getFullYear()} Pacifica Foundation. KPFK 90.7 FM, Los Angeles.
          </p>
        </div>
      </div>
    </footer>
  );
}
