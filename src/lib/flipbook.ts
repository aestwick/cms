// Flipbook (homepage promo carousel) domain logic.
// Pure functions — status derivation and the public selection rules —
// kept separate from the routes/components so they can be unit-tested.

export type PanelStatus = "live" | "scheduled" | "expired";

export interface FlipbookPanel {
  id: string;
  title: string;
  caption: string | null;
  cta_label: string | null;
  link_url: string | null;
  opens_new_tab: boolean;
  image_path: string | null;
  accent_color: string | null;
  starts_at: string | null;
  expires_at: string | null;
  sort_order: number;
}

export interface FlipbookSettings {
  show_count: number | "all";
  randomize: boolean;
  auto_hide_expired: boolean;
}

export const DEFAULT_FLIPBOOK_SETTINGS: FlipbookSettings = {
  show_count: 20,
  randomize: false,
  auto_hide_expired: true,
};

/**
 * Derive a panel's status from its schedule window, relative to `now`.
 *  - expired:   has an expires_at in the past
 *  - scheduled: has a starts_at in the future
 *  - live:      everything else (within or without a window)
 */
export function panelStatus(
  panel: Pick<FlipbookPanel, "starts_at" | "expires_at">,
  now: Date = new Date()
): PanelStatus {
  const t = now.getTime();
  if (panel.expires_at && new Date(panel.expires_at).getTime() < t) {
    return "expired";
  }
  if (panel.starts_at && new Date(panel.starts_at).getTime() > t) {
    return "scheduled";
  }
  return "live";
}

/**
 * The panels that should appear on the public homepage, in render order.
 *  - scheduled panels are never shown,
 *  - expired panels are shown only when auto_hide_expired is off,
 *  - ordered by sort_order (or shuffled when randomize is on),
 *  - capped at show_count (unless "all").
 *
 * `shuffle` is injectable so the selection stays deterministic in tests.
 */
export function selectHomepagePanels(
  panels: FlipbookPanel[],
  settings: FlipbookSettings = DEFAULT_FLIPBOOK_SETTINGS,
  now: Date = new Date(),
  shuffle: (arr: FlipbookPanel[]) => FlipbookPanel[] = defaultShuffle
): FlipbookPanel[] {
  const visible = panels.filter((p) => {
    const status = panelStatus(p, now);
    if (status === "scheduled") return false;
    if (status === "expired") return !settings.auto_hide_expired;
    return true;
  });

  const ordered = settings.randomize
    ? shuffle([...visible])
    : [...visible].sort((a, b) => a.sort_order - b.sort_order);

  if (settings.show_count === "all") return ordered;
  const limit = Number(settings.show_count);
  return Number.isFinite(limit) && limit > 0 ? ordered.slice(0, limit) : ordered;
}

function defaultShuffle<T>(arr: T[]): T[] {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

/** Coerce a raw settings bag (from cms_stations.settings.flipbook) into a
 * complete FlipbookSettings, filling any missing keys with defaults. */
export function normalizeSettings(raw: unknown): FlipbookSettings {
  const r = (raw ?? {}) as Partial<FlipbookSettings>;
  return {
    show_count:
      r.show_count === "all" || typeof r.show_count === "number"
        ? r.show_count
        : DEFAULT_FLIPBOOK_SETTINGS.show_count,
    randomize:
      typeof r.randomize === "boolean"
        ? r.randomize
        : DEFAULT_FLIPBOOK_SETTINGS.randomize,
    auto_hide_expired:
      typeof r.auto_hide_expired === "boolean"
        ? r.auto_hide_expired
        : DEFAULT_FLIPBOOK_SETTINGS.auto_hide_expired,
  };
}
