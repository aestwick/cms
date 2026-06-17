import { describe, it, expect } from "vitest";
import {
  panelStatus,
  selectHomepagePanels,
  normalizeSettings,
  DEFAULT_FLIPBOOK_SETTINGS,
  type FlipbookPanel,
  type FlipbookSettings,
} from "@/lib/flipbook";

const NOW = new Date("2026-06-16T12:00:00Z");

function panel(overrides: Partial<FlipbookPanel> = {}): FlipbookPanel {
  return {
    id: "p",
    title: "Panel",
    caption: null,
    cta_label: null,
    link_url: null,
    opens_new_tab: true,
    image_path: null,
    accent_color: null,
    starts_at: null,
    expires_at: null,
    sort_order: 0,
    ...overrides,
  };
}

describe("panelStatus", () => {
  it("is live with no schedule window", () => {
    expect(panelStatus(panel(), NOW)).toBe("live");
  });
  it("is scheduled when starts_at is in the future", () => {
    expect(panelStatus(panel({ starts_at: "2026-07-01T00:00:00Z" }), NOW)).toBe(
      "scheduled"
    );
  });
  it("is expired when expires_at is in the past", () => {
    expect(panelStatus(panel({ expires_at: "2026-06-01T00:00:00Z" }), NOW)).toBe(
      "expired"
    );
  });
  it("is live inside an open window", () => {
    expect(
      panelStatus(
        panel({ starts_at: "2026-06-01T00:00:00Z", expires_at: "2026-07-01T00:00:00Z" }),
        NOW
      )
    ).toBe("live");
  });
});

describe("selectHomepagePanels", () => {
  const live = panel({ id: "live", sort_order: 2 });
  const live2 = panel({ id: "live2", sort_order: 1 });
  const scheduled = panel({ id: "sched", starts_at: "2026-07-01T00:00:00Z" });
  const expired = panel({ id: "exp", expires_at: "2026-06-01T00:00:00Z" });

  it("excludes scheduled panels and orders by sort_order", () => {
    const out = selectHomepagePanels([live, live2, scheduled], DEFAULT_FLIPBOOK_SETTINGS, NOW);
    expect(out.map((p) => p.id)).toEqual(["live2", "live"]);
  });

  it("hides expired panels when auto_hide_expired is on", () => {
    const out = selectHomepagePanels([live, expired], DEFAULT_FLIPBOOK_SETTINGS, NOW);
    expect(out.map((p) => p.id)).toEqual(["live"]);
  });

  it("keeps expired panels when auto_hide_expired is off", () => {
    const settings: FlipbookSettings = { ...DEFAULT_FLIPBOOK_SETTINGS, auto_hide_expired: false };
    const out = selectHomepagePanels([live, expired], settings, NOW);
    expect(out.map((p) => p.id).sort()).toEqual(["exp", "live"]);
  });

  it("caps the result at show_count", () => {
    const many = [0, 1, 2, 3, 4].map((i) => panel({ id: `p${i}`, sort_order: i }));
    const settings: FlipbookSettings = { ...DEFAULT_FLIPBOOK_SETTINGS, show_count: 3 };
    expect(selectHomepagePanels(many, settings, NOW)).toHaveLength(3);
  });

  it("returns all when show_count is 'all'", () => {
    const many = [0, 1, 2, 3, 4].map((i) => panel({ id: `p${i}`, sort_order: i }));
    const settings: FlipbookSettings = { ...DEFAULT_FLIPBOOK_SETTINGS, show_count: "all" };
    expect(selectHomepagePanels(many, settings, NOW)).toHaveLength(5);
  });

  it("uses the injected shuffle when randomize is on", () => {
    const settings: FlipbookSettings = { ...DEFAULT_FLIPBOOK_SETTINGS, randomize: true };
    const reverse = (a: FlipbookPanel[]) => [...a].reverse();
    const out = selectHomepagePanels([live2, live], settings, NOW, reverse);
    expect(out.map((p) => p.id)).toEqual(["live", "live2"]);
  });
});

describe("normalizeSettings", () => {
  it("fills missing keys with defaults", () => {
    expect(normalizeSettings({})).toEqual(DEFAULT_FLIPBOOK_SETTINGS);
    expect(normalizeSettings(null)).toEqual(DEFAULT_FLIPBOOK_SETTINGS);
  });
  it("preserves valid values including 'all'", () => {
    expect(normalizeSettings({ show_count: "all", randomize: true, auto_hide_expired: false })).toEqual({
      show_count: "all",
      randomize: true,
      auto_hide_expired: false,
    });
  });
  it("rejects a bogus show_count back to default", () => {
    expect(normalizeSettings({ show_count: "lots" }).show_count).toBe(
      DEFAULT_FLIPBOOK_SETTINGS.show_count
    );
  });
});
