import Link from "next/link";

export default function Home() {
  return (
    <div className="mx-auto max-w-7xl px-4 py-12 sm:px-6">
      <div className="border-2 border-charcoal p-8 text-center">
        <h1 className="font-serif text-5xl font-bold text-charcoal">
          KPFK 90.7 FM
        </h1>
        <p className="mt-3 text-lg text-charcoal/70">
          Pacifica Foundation Community Radio — Los Angeles
        </p>
        <p className="mt-1 text-sm text-charcoal/50">
          Listener-supported since 1959
        </p>

        <div className="mt-8 flex flex-wrap items-center justify-center gap-4">
          <Link
            href="/on-air"
            className="border-2 border-charcoal bg-charcoal px-6 py-2.5 text-sm font-bold text-off-white transition-colors hover:bg-off-white hover:text-charcoal"
          >
            Browse Shows
          </Link>
          <Link
            href="/schedule"
            className="border-2 border-charcoal px-6 py-2.5 text-sm font-bold text-charcoal transition-colors hover:bg-charcoal hover:text-off-white"
          >
            View Schedule
          </Link>
          <a
            href="https://donate.kpfk.org"
            target="_blank"
            rel="noopener noreferrer"
            className="border-2 border-kpfk-red px-6 py-2.5 text-sm font-bold text-kpfk-red transition-colors hover:bg-kpfk-red hover:text-off-white"
          >
            Support KPFK
          </a>
        </div>
      </div>
    </div>
  );
}
