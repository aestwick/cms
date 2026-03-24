import Link from "next/link";

export default function Home() {
  return (
    <div className="mx-auto max-w-7xl px-6 py-16 sm:px-8">
      <div className="border-2 border-charcoal p-12 text-center">
        <h1 className="font-serif text-5xl font-bold text-charcoal">
          KPFK 90.7 FM
        </h1>
        <p className="mt-4 text-xl text-charcoal/70">
          Pacifica Foundation Community Radio — Los Angeles
        </p>
        <p className="mt-2 text-base text-charcoal/50">
          Listener-supported since 1959
        </p>

        <div className="mt-10 flex flex-wrap items-center justify-center gap-5">
          <Link
            href="/on-air"
            className="border-2 border-charcoal bg-charcoal px-7 py-3 text-base font-bold text-off-white transition-colors hover:bg-off-white hover:text-charcoal"
          >
            Browse Shows
          </Link>
          <Link
            href="/schedule"
            className="border-2 border-charcoal px-7 py-3 text-base font-bold text-charcoal transition-colors hover:bg-charcoal hover:text-off-white"
          >
            View Schedule
          </Link>
          <a
            href="https://donate.kpfk.org"
            target="_blank"
            rel="noopener noreferrer"
            className="border-2 border-kpfk-red px-7 py-3 text-base font-bold text-kpfk-red transition-colors hover:bg-kpfk-red hover:text-off-white"
          >
            Support KPFK
          </a>
        </div>
      </div>
    </div>
  );
}
