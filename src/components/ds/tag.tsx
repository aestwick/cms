import Link from "next/link";
import type { ReactNode } from "react";

/** The five Voices used for category-coding. */
export type Voice = "music" | "news" | "culture" | "community" | "talk";

const voiceVar: Record<Voice, string> = {
  music: "var(--kpfk-sunray)",
  news: "var(--kpfk-airwave)",
  culture: "var(--kpfk-frequency)",
  community: "var(--kpfk-chorus)",
  talk: "var(--kpfk-ink)",
};

const base =
  "inline-flex items-center gap-1 rounded-full border px-3 py-1 text-[11px] font-bold uppercase tracking-[0.06em] leading-none transition-colors";

type Props = {
  children: ReactNode;
  /** Voice color; omit for a neutral red tag. */
  voice?: Voice;
  /** Render solid (filled) instead of outline. */
  solid?: boolean;
  href?: string;
  className?: string;
};

export function Tag({ children, voice, solid, href, className }: Props) {
  const color = voice ? voiceVar[voice] : "var(--kpfk-red)";
  const style = solid
    ? { background: color, borderColor: color, color: "#fff" }
    : { color, borderColor: color, background: "transparent" };

  const cls = [base, className].filter(Boolean).join(" ");

  if (href) {
    return (
      <Link href={href} className={cls} style={style}>
        {children}
      </Link>
    );
  }
  return (
    <span className={cls} style={style}>
      {children}
    </span>
  );
}
