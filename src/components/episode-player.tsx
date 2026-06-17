"use client";

import { useEffect, useRef, useState } from "react";

// Precise, non-skeuomorphic episode audio player (per the design brief):
// play/pause, scrub, ±15s, speed, and resumes from the last position
// (localStorage['kpfk-ep-<storageKey>']). Designed to feel mechanical and
// immediate, not like hardware.

const SPEEDS = [1, 1.25, 1.5, 2];

function fmt(s: number): string {
  if (!s || !isFinite(s)) return "0:00";
  const m = Math.floor(s / 60);
  const sec = Math.floor(s % 60);
  return `${m}:${sec.toString().padStart(2, "0")}`;
}

export function EpisodePlayer({
  src,
  storageKey,
}: {
  src: string;
  storageKey: string;
}) {
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const [playing, setPlaying] = useState(false);
  const [current, setCurrent] = useState(0);
  const [duration, setDuration] = useState(0);
  const [speedIdx, setSpeedIdx] = useState(0);

  const key = `kpfk-ep-${storageKey}`;

  // Restore saved position once metadata is known.
  useEffect(() => {
    const a = audioRef.current;
    if (!a) return;
    const onLoaded = () => {
      setDuration(a.duration);
      try {
        const saved = Number(window.localStorage.getItem(key));
        if (saved && saved < a.duration - 5) a.currentTime = saved;
      } catch {}
    };
    a.addEventListener("loadedmetadata", onLoaded);
    return () => a.removeEventListener("loadedmetadata", onLoaded);
  }, [key]);

  // Persist position as it plays (throttled to whole seconds).
  function onTime() {
    const a = audioRef.current;
    if (!a) return;
    setCurrent(a.currentTime);
    try {
      window.localStorage.setItem(key, String(Math.floor(a.currentTime)));
    } catch {}
  }

  function toggle() {
    const a = audioRef.current;
    if (!a) return;
    if (a.paused) a.play();
    else a.pause();
  }
  function nudge(delta: number) {
    const a = audioRef.current;
    if (!a) return;
    a.currentTime = Math.max(0, Math.min(a.duration || 0, a.currentTime + delta));
  }
  function cycleSpeed() {
    const next = (speedIdx + 1) % SPEEDS.length;
    setSpeedIdx(next);
    if (audioRef.current) audioRef.current.playbackRate = SPEEDS[next];
  }
  function seek(e: React.ChangeEvent<HTMLInputElement>) {
    const a = audioRef.current;
    if (!a) return;
    a.currentTime = (Number(e.target.value) / 100) * (a.duration || 0);
  }

  const pct = duration ? (current / duration) * 100 : 0;

  return (
    <div className="border p-4" style={{ borderColor: "var(--line)", background: "var(--card)" }}>
      <audio
        ref={audioRef}
        src={src}
        preload="metadata"
        onPlay={() => setPlaying(true)}
        onPause={() => setPlaying(false)}
        onTimeUpdate={onTime}
        onEnded={() => setPlaying(false)}
      />
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={toggle}
          className="flex h-11 w-11 flex-shrink-0 items-center justify-center bg-kpfk-red text-white"
          aria-label={playing ? "Pause" : "Play"}
        >
          {playing ? "❙❙" : "▶"}
        </button>
        <button type="button" onClick={() => nudge(-15)} className="text-xs font-bold uppercase tracking-wide" style={{ color: "var(--muted)" }}>−15s</button>
        <button type="button" onClick={() => nudge(15)} className="text-xs font-bold uppercase tracking-wide" style={{ color: "var(--muted)" }}>+15s</button>
        <div className="flex flex-1 items-center gap-2">
          <span className="font-mono text-xs" style={{ color: "var(--faint)" }}>{fmt(current)}</span>
          <input
            type="range"
            min={0}
            max={100}
            value={pct}
            onChange={seek}
            className="h-1 flex-1 cursor-pointer accent-kpfk-red"
            aria-label="Seek"
          />
          <span className="font-mono text-xs" style={{ color: "var(--faint)" }}>{fmt(duration)}</span>
        </div>
        <button type="button" onClick={cycleSpeed} className="border px-2 py-1 text-xs font-bold" style={{ borderColor: "var(--line)", color: "var(--txt)" }}>
          {SPEEDS[speedIdx]}×
        </button>
      </div>
    </div>
  );
}
