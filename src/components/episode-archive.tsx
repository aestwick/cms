"use client";

import { useEffect, useState, useCallback, useRef } from "react";
import Link from "next/link";

interface Episode {
  title: string;
  date: string;
  shortDate: string;
  airDate: string;
  duration: string;
  audioUrl: string;
  timestamp: number;
  headline: string | null;
  guest: string | null;
  summary: string | null;
}

interface EpisodeArchiveProps {
  programSlug: string;
  showTitle: string;
  showSlug: string;
}

const EPISODES_PER_PAGE = 6;

function PlayIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className}>
      <path d="M8 5v14l11-7z" />
    </svg>
  );
}

function PauseIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className}>
      <path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z" />
    </svg>
  );
}

function DownloadIcon({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      className={className}
    >
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3" />
    </svg>
  );
}

function formatTime(seconds: number): string {
  if (!seconds || !isFinite(seconds)) return "0:00";
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, "0")}`;
}

export function EpisodeArchive({ programSlug, showTitle, showSlug }: EpisodeArchiveProps) {
  const [episodes, setEpisodes] = useState<Episode[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);

  // Audio playback state
  const [currentIndex, setCurrentIndex] = useState<number | null>(null);
  const [playing, setPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const [currentTime, setCurrentTime] = useState(0);
  const [totalTime, setTotalTime] = useState(0);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  // Expanded descriptions
  const [expandedSummaries, setExpandedSummaries] = useState<Set<number>>(
    new Set()
  );

  const fetchEpisodes = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(
        `/api/confessor/episodes?program=${encodeURIComponent(programSlug)}&num=50`
      );
      if (!res.ok) throw new Error("Failed to load episodes");
      const data = await res.json();
      setEpisodes(data.episodes || []);
    } catch {
      setError("Unable to load episodes right now. Please try again later.");
    } finally {
      setLoading(false);
    }
  }, [programSlug]);

  useEffect(() => {
    fetchEpisodes();
  }, [fetchEpisodes]);

  // Clean up audio on unmount
  useEffect(() => {
    return () => {
      if (audioRef.current) {
        audioRef.current.pause();
        audioRef.current = null;
      }
    };
  }, []);

  function playEpisode(index: number) {
    // If same episode, toggle
    if (currentIndex === index && audioRef.current) {
      if (audioRef.current.paused) {
        audioRef.current.play();
      } else {
        audioRef.current.pause();
      }
      return;
    }

    // Stop current
    if (audioRef.current) {
      audioRef.current.pause();
      audioRef.current = null;
    }

    const ep = episodes[index];
    const audio = new Audio(ep.audioUrl);
    audioRef.current = audio;
    setCurrentIndex(index);
    setProgress(0);
    setCurrentTime(0);
    setTotalTime(0);

    audio.onplay = () => setPlaying(true);
    audio.onpause = () => setPlaying(false);
    audio.ontimeupdate = () => {
      if (audio.duration) {
        setProgress((audio.currentTime / audio.duration) * 100);
        setCurrentTime(audio.currentTime);
        setTotalTime(audio.duration);
      }
    };
    audio.onended = () => {
      // Autoplay next
      if (index < episodes.length - 1) {
        playEpisode(index + 1);
      } else {
        setPlaying(false);
      }
    };
    audio.onerror = () => setPlaying(false);

    audio.play();
  }

  function handleSeek(e: React.MouseEvent<HTMLDivElement>) {
    if (!audioRef.current || !audioRef.current.duration) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const percent = (e.clientX - rect.left) / rect.width;
    audioRef.current.currentTime = percent * audioRef.current.duration;
  }

  function handleDownload(ep: Episode) {
    const a = document.createElement("a");
    a.href = ep.audioUrl;
    a.download = `${ep.title.replace(/[^a-z0-9]/gi, "_").toLowerCase()}.mp3`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  }

  function toggleSummary(index: number) {
    setExpandedSummaries((prev) => {
      const next = new Set(prev);
      if (next.has(index)) next.delete(index);
      else next.add(index);
      return next;
    });
  }

  const totalPages = Math.ceil(episodes.length / EPISODES_PER_PAGE);
  const start = (page - 1) * EPISODES_PER_PAGE;
  const pageEpisodes = episodes.slice(start, start + EPISODES_PER_PAGE);
  const currentEpisode =
    currentIndex !== null ? episodes[currentIndex] : null;

  if (loading) {
    return (
      <section className="border border-charcoal/10 p-8">
        <h2 className="font-serif text-2xl font-bold text-charcoal">
          Recent Episodes
        </h2>
        <p className="mt-4 text-base text-charcoal/40">Loading episodes...</p>
      </section>
    );
  }

  if (error) {
    return (
      <section className="border border-charcoal/10 p-8">
        <h2 className="font-serif text-2xl font-bold text-charcoal">
          Recent Episodes
        </h2>
        <p className="mt-4 text-base text-charcoal/60">{error}</p>
        <button
          onClick={fetchEpisodes}
          className="mt-3 text-sm font-bold text-kpfk-red hover:text-kpfk-red/80"
        >
          Try again
        </button>
      </section>
    );
  }

  if (episodes.length === 0) {
    return (
      <section className="border border-charcoal/10 p-8">
        <h2 className="font-serif text-2xl font-bold text-charcoal">
          Recent Episodes
        </h2>
        <p className="mt-4 text-base text-charcoal/40">
          No archived episodes available yet.
        </p>
      </section>
    );
  }

  return (
    <section className="border border-charcoal/10">
      {/* Header */}
      <div className="border-b border-charcoal/10 bg-charcoal px-6 py-4">
        <p className="font-mono text-xs uppercase tracking-wider text-off-white/50">
          Episode Archive
        </p>
        <h2 className="font-serif text-xl font-bold text-off-white">
          {showTitle}
        </h2>
        <p className="mt-1 font-mono text-xs text-off-white/40">
          {episodes.length} episode{episodes.length !== 1 ? "s" : ""} available
        </p>
      </div>

      {/* Episode list */}
      <div className="divide-y divide-charcoal/10">
        {pageEpisodes.map((ep, i) => {
          const globalIndex = start + i;
          const isActive = currentIndex === globalIndex;
          const isPlaying = isActive && playing;

          return (
            <div
              key={globalIndex}
              className={`flex items-start gap-4 px-6 py-4 transition-colors ${
                isActive
                  ? "border-l-4 border-l-kpfk-red bg-charcoal/[0.02]"
                  : "hover:bg-charcoal/[0.02]"
              }`}
            >
              {/* Play button */}
              <button
                onClick={() => playEpisode(globalIndex)}
                className="mt-0.5 flex h-8 w-8 flex-shrink-0 items-center justify-center bg-kpfk-red text-off-white transition-colors hover:bg-charcoal"
                aria-label={isPlaying ? "Pause episode" : "Play episode"}
              >
                {isPlaying ? (
                  <PauseIcon className="h-3.5 w-3.5" />
                ) : (
                  <PlayIcon className="h-3.5 w-3.5" />
                )}
              </button>

              {/* Details */}
              <div className="min-w-0 flex-1">
                <p className="font-serif text-base font-bold text-charcoal">
                  {ep.headline || `${ep.title} — ${ep.shortDate}`}
                </p>
                <p className="mt-0.5 font-mono text-xs text-charcoal/40">
                  {ep.date}
                  {ep.duration ? ` · ${ep.duration}` : ""}
                  {ep.guest ? ` · Guest: ${ep.guest}` : ""}
                </p>
                {ep.airDate && (
                  <Link
                    href={`/on-air/${showSlug}/${ep.airDate}`}
                    className="mt-1 inline-block text-xs font-bold uppercase tracking-[0.06em] text-kpfk-red hover:underline"
                  >
                    Episode page →
                  </Link>
                )}

                {isPlaying && (
                  <p className="mt-1 font-mono text-xs font-bold uppercase text-kpfk-red">
                    <span className="animate-pulse">●</span> Now Playing
                  </p>
                )}

                {/* Expandable summary */}
                {ep.summary && (
                  <div className="mt-2">
                    <p
                      className={`text-sm leading-relaxed text-charcoal/60 ${
                        expandedSummaries.has(globalIndex)
                          ? ""
                          : "line-clamp-2"
                      }`}
                    >
                      {ep.summary}
                    </p>
                    <button
                      onClick={() => toggleSummary(globalIndex)}
                      className="mt-1 text-xs text-kpfk-red underline hover:text-charcoal"
                    >
                      {expandedSummaries.has(globalIndex)
                        ? "Read less"
                        : "Read more..."}
                    </button>
                  </div>
                )}

                {/* Download */}
                <button
                  onClick={() => handleDownload(ep)}
                  className="mt-2 inline-flex items-center gap-1.5 border border-charcoal/15 px-3 py-1 text-xs font-bold text-charcoal/60 transition-colors hover:border-charcoal/30 hover:text-charcoal"
                >
                  <DownloadIcon className="h-3 w-3" />
                  Download
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between border-t border-charcoal/10 px-6 py-3">
          <span className="font-mono text-xs text-charcoal/40">
            Page {page} of {totalPages}
          </span>
          <div className="flex gap-2">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1}
              className="border border-charcoal/15 px-3 py-1 text-xs font-bold text-charcoal/60 transition-colors hover:border-charcoal/30 disabled:opacity-30"
            >
              Prev
            </button>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="border border-charcoal/15 px-3 py-1 text-xs font-bold text-charcoal/60 transition-colors hover:border-charcoal/30 disabled:opacity-30"
            >
              Next
            </button>
          </div>
        </div>
      )}

      {/* Fixed playback bar */}
      {currentEpisode && (
        <div className="fixed bottom-0 left-0 right-0 z-50 bg-charcoal text-off-white">
          <div className="mx-auto max-w-7xl px-4 py-3">
            {/* Now playing info */}
            <div className="mb-2 flex items-center justify-between">
              <div className="min-w-0">
                <p className="truncate font-sans text-sm font-bold uppercase tracking-wide">
                  {currentEpisode.headline || currentEpisode.title}
                </p>
                <p className="font-mono text-xs text-off-white/50">
                  {currentEpisode.shortDate}
                </p>
              </div>
              <div className="ml-4 font-mono text-xs text-off-white/50">
                {formatTime(currentTime)} / {formatTime(totalTime)}
              </div>
            </div>

            {/* Progress bar */}
            <div
              className="mb-2 h-1.5 cursor-pointer overflow-hidden bg-off-white/20"
              onClick={handleSeek}
            >
              <div
                className="h-full bg-kpfk-red transition-[width] duration-100"
                style={{ width: `${progress}%` }}
              />
            </div>

            {/* Controls */}
            <div className="flex items-center gap-3">
              <button
                onClick={() => {
                  if (audioRef.current)
                    audioRef.current.currentTime = Math.max(
                      0,
                      audioRef.current.currentTime - 15
                    );
                }}
                className="text-xs text-off-white/50 hover:text-off-white"
                aria-label="Rewind 15 seconds"
              >
                -15s
              </button>
              <button
                onClick={() => {
                  if (currentIndex !== null) playEpisode(currentIndex);
                }}
                className="flex h-9 w-9 items-center justify-center bg-kpfk-red text-off-white transition-colors hover:bg-off-white hover:text-charcoal"
                aria-label={playing ? "Pause" : "Play"}
              >
                {playing ? (
                  <PauseIcon className="h-4 w-4" />
                ) : (
                  <PlayIcon className="h-4 w-4" />
                )}
              </button>
              <button
                onClick={() => {
                  if (audioRef.current)
                    audioRef.current.currentTime = Math.min(
                      audioRef.current.duration || 0,
                      audioRef.current.currentTime + 30
                    );
                }}
                className="text-xs text-off-white/50 hover:text-off-white"
                aria-label="Forward 30 seconds"
              >
                +30s
              </button>
            </div>
          </div>
        </div>
      )}
    </section>
  );
}
