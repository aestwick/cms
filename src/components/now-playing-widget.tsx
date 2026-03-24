"use client";

import { useEffect, useState } from "react";
import Link from "next/link";

interface NowPlayingData {
  show_title: string;
  show_slug: string | null;
  host_name: string | null;
  up_next: string | null;
}

export function NowPlayingWidget() {
  const [data, setData] = useState<NowPlayingData | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function fetchNowPlaying() {
      try {
        const res = await fetch("/api/confessor/now-playing");
        if (res.ok) {
          const json = await res.json();
          if (!cancelled) setData(json);
        }
      } catch {
        // Confessor unavailable — widget stays hidden
      }
    }

    fetchNowPlaying();
    const interval = setInterval(fetchNowPlaying, 60_000);
    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, []);

  if (!data) return null;

  return (
    <div className="hidden items-center gap-2 text-sm sm:flex">
      <span className="inline-block h-2 w-2 animate-pulse rounded-full bg-kpfk-red" />
      <span className="font-mono text-xs text-charcoal/50">ON NOW</span>
      {data.show_slug ? (
        <Link
          href={`/on-air/${data.show_slug}`}
          className="font-medium text-charcoal hover:text-kpfk-red"
        >
          {data.show_title}
        </Link>
      ) : (
        <span className="font-medium text-charcoal">{data.show_title}</span>
      )}
    </div>
  );
}
