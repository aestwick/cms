// The five KPFK "Voices" — the editorial color system shared by
// category-coding across admin and public surfaces.

export type Voice = "news" | "music" | "culture" | "community" | "talk";

export const VOICES: Voice[] = ["news", "music", "culture", "community", "talk"];

// CSS custom properties defined in the global theme.
export const VOICE_COLOR_VAR: Record<Voice, string> = {
  news: "var(--kpfk-airwave)",
  music: "var(--kpfk-sunray)",
  culture: "var(--kpfk-frequency)",
  community: "var(--kpfk-chorus)",
  talk: "var(--kpfk-ink)",
};

export function voiceColor(color: string | null | undefined): string | null {
  if (!color) return null;
  return VOICE_COLOR_VAR[color as Voice] ?? null;
}
