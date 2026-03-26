"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export interface ShowFormData {
  title: string;
  slug: string;
  tagline: string;
  description: string;
  history: string;
  show_type: "talk" | "music" | "mixed";
  program_slug: string;
  logo_path: string;
  banner_path: string;
  contact_preference: "form" | "email" | "both" | "none";
  contact_email: string;
  website_url: string;
  rss_url: string;
  social_links: Record<string, string>;
  donation_cta_heading: string;
  donation_cta_body: string;
  donation_cta_url: string;
  is_active: boolean;
  sort_order: number;
  broadcast_status: "active" | "hiatus" | "online_only" | "retired";
  status_note: string;
  returns_at: string;
  schedule_note: string;
}

// --- Social link auto-detection ---

interface SocialLinkEntry {
  id: string;
  url: string;
  platform: string;
}

const PLATFORM_PATTERNS: [RegExp, string][] = [
  [/facebook\.com|fb\.com|fb\.me/i, "facebook"],
  [/twitter\.com|x\.com/i, "twitter"],
  [/instagram\.com/i, "instagram"],
  [/youtube\.com|youtu\.be/i, "youtube"],
  [/tiktok\.com/i, "tiktok"],
  [/threads\.net/i, "threads"],
  [/mastodon\.|mstdn\.|mas\.to/i, "mastodon"],
  [/bsky\.app|bsky\.social/i, "bluesky"],
  [/linkedin\.com/i, "linkedin"],
  [/spotify\.com/i, "spotify"],
  [/podcasts\.apple\.com|itunes\.apple\.com/i, "apple_podcasts"],
  [/podcasts\.google\.com/i, "google_podcasts"],
  [/soundcloud\.com/i, "soundcloud"],
  [/bandcamp\.com/i, "bandcamp"],
  [/patreon\.com/i, "patreon"],
  [/substack\.com/i, "substack"],
  [/tumblr\.com/i, "tumblr"],
  [/twitch\.tv/i, "twitch"],
  [/discord\.gg|discord\.com/i, "discord"],
  [/t\.me|telegram\.me/i, "telegram"],
  [/\.rss$|\/feed\/?$|\/rss\/?$|feeds\.|feedburner\./i, "rss"],
];

const PLATFORM_LABELS: Record<string, string> = {
  facebook: "Facebook",
  twitter: "X / Twitter",
  instagram: "Instagram",
  youtube: "YouTube",
  tiktok: "TikTok",
  threads: "Threads",
  mastodon: "Mastodon",
  bluesky: "Bluesky",
  linkedin: "LinkedIn",
  spotify: "Spotify",
  apple_podcasts: "Apple Podcasts",
  google_podcasts: "Google Podcasts",
  soundcloud: "SoundCloud",
  bandcamp: "Bandcamp",
  patreon: "Patreon",
  substack: "Substack",
  tumblr: "Tumblr",
  twitch: "Twitch",
  discord: "Discord",
  telegram: "Telegram",
  rss: "RSS Feed",
};

function detectPlatform(url: string): string {
  if (!url) return "";
  for (const [pattern, platform] of PLATFORM_PATTERNS) {
    if (pattern.test(url)) return platform;
  }
  return "";
}

let nextLinkId = 0;
function makeLinkId() {
  return `link_${++nextLinkId}`;
}

function socialLinksToEntries(links: Record<string, string>): SocialLinkEntry[] {
  const entries = Object.entries(links)
    .filter(([, url]) => url)
    .map(([platform, url]) => ({ id: makeLinkId(), url, platform }));
  return entries.length > 0 ? entries : [{ id: makeLinkId(), url: "", platform: "" }];
}

function entriesToSocialLinks(entries: SocialLinkEntry[]): Record<string, string> {
  const result: Record<string, string> = {};
  const usedKeys = new Set<string>();
  for (const entry of entries) {
    if (!entry.url.trim()) continue;
    const key = entry.platform || `other_${entry.id}`;
    // Handle duplicate platforms by appending a suffix
    let finalKey = key;
    let i = 2;
    while (usedKeys.has(finalKey)) {
      finalKey = `${key}_${i++}`;
    }
    usedKeys.add(finalKey);
    result[finalKey] = entry.url.trim();
  }
  return result;
}

interface TagOption {
  id: string;
  name: string;
  slug: string;
  category: "topic" | "format" | "audience";
}

const emptyShow: ShowFormData = {
  title: "",
  slug: "",
  tagline: "",
  description: "",
  history: "",
  show_type: "talk",
  program_slug: "",
  logo_path: "",
  banner_path: "",
  contact_preference: "form",
  contact_email: "",
  website_url: "",
  rss_url: "",
  social_links: {},
  donation_cta_heading: "",
  donation_cta_body: "",
  donation_cta_url: "",
  is_active: true,
  sort_order: 0,
  broadcast_status: "active",
  status_note: "",
  returns_at: "",
  schedule_note: "",
};

interface ShowFormProps {
  initialData?: Partial<ShowFormData>;
  showId?: string;
  mode: "create" | "edit";
  allTags?: TagOption[];
  initialTagIds?: string[];
}

function slugify(text: string): string {
  const articles = /\b(the|an|a)\b/gi;
  return text
    .replace(articles, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

const TAG_CATEGORY_COLORS: Record<string, string> = {
  topic: "bg-tag-topic",
  format: "bg-tag-format",
  audience: "bg-tag-audience",
};

export function ShowForm({ initialData, showId, mode, allTags = [], initialTagIds = [] }: ShowFormProps) {
  const router = useRouter();
  const merged = { ...emptyShow, ...initialData };
  const [form, setForm] = useState<ShowFormData>(merged);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [slugManual, setSlugManual] = useState(mode === "edit");
  const [selectedTagIds, setSelectedTagIds] = useState<string[]>(initialTagIds);
  const [socialEntries, setSocialEntries] = useState<SocialLinkEntry[]>(
    socialLinksToEntries(merged.social_links || {})
  );

  function updateField<K extends keyof ShowFormData>(key: K, value: ShowFormData[K]) {
    setForm((prev) => ({ ...prev, [key]: value }));
  }

  function updateSocialEntry(id: string, url: string) {
    setSocialEntries((prev) =>
      prev.map((entry) =>
        entry.id === id ? { ...entry, url, platform: detectPlatform(url) } : entry
      )
    );
  }

  function addSocialEntry() {
    setSocialEntries((prev) => [...prev, { id: makeLinkId(), url: "", platform: "" }]);
  }

  function removeSocialEntry(id: string) {
    setSocialEntries((prev) => {
      const next = prev.filter((e) => e.id !== id);
      return next.length > 0 ? next : [{ id: makeLinkId(), url: "", platform: "" }];
    });
  }

  function handleTitleChange(title: string) {
    updateField("title", title);
    if (!slugManual) {
      updateField("slug", slugify(title));
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError("");

    // Convert dynamic entries to Record, stripping empties
    const cleanedLinks = entriesToSocialLinks(socialEntries);
    const payload = { ...form, social_links: cleanedLinks };

    // Also clean up the entries in the UI to remove empty rows
    const cleaned = socialEntries.filter((e) => e.url.trim());
    setSocialEntries(cleaned.length > 0 ? cleaned : [{ id: makeLinkId(), url: "", platform: "" }]);

    const url = mode === "create" ? "/api/shows" : `/api/shows/${showId}`;
    const method = mode === "create" ? "POST" : "PATCH";

    const res = await fetch(url, {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    const data = await res.json();

    if (!res.ok) {
      setSaving(false);
      setError(data.error || "Something went wrong");
      return;
    }

    // Save tags
    const tagShowId = mode === "create" ? data.id : showId;
    if (tagShowId) {
      await fetch(`/api/shows/${tagShowId}/tags`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ tag_ids: selectedTagIds }),
      });
    }

    setSaving(false);
    router.push("/admin/shows");
    router.refresh();
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-8">
      {/* === Core Info === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Show Info</h2>
        <div className="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Title <span className="text-kpfk-red">*</span>
            </label>
            <input
              type="text"
              required
              value={form.title}
              onChange={(e) => handleTitleChange(e.target.value)}
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Slug <span className="text-kpfk-red">*</span>
            </label>
            <div className="mt-1 flex items-center gap-2">
              <span className="text-xs text-charcoal/40 font-mono">/on-air/</span>
              <input
                type="text"
                required
                pattern="[a-z0-9-]+"
                value={form.slug}
                onChange={(e) => {
                  setSlugManual(true);
                  updateField("slug", e.target.value);
                }}
                className="block flex-1 border border-charcoal/20 bg-off-white px-3 py-2 font-mono text-sm focus:border-charcoal focus:outline-none"
              />
            </div>
          </div>
          <div className="md:col-span-2">
            <label className="block text-sm font-medium text-charcoal">
              Tagline
            </label>
            <input
              type="text"
              value={form.tagline}
              onChange={(e) => updateField("tagline", e.target.value)}
              placeholder="Short one-liner about the show"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
            />
          </div>
        </div>
      </section>

      {/* === Show Type & Program Slug === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Show Type & Mapping</h2>
        <div className="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Show Type
            </label>
            <select
              value={form.show_type}
              onChange={(e) => updateField("show_type", e.target.value as ShowFormData["show_type"])}
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
            >
              <option value="talk">Talk</option>
              <option value="music">Music</option>
              <option value="mixed">Mixed</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Program Slug
            </label>
            <input
              type="text"
              value={form.program_slug}
              onChange={(e) => updateField("program_slug", e.target.value)}
              placeholder="Confessor/Beacon program identifier"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 font-mono text-sm focus:border-charcoal focus:outline-none"
            />
            <p className="mt-1 text-xs text-charcoal/40">
              Maps to Confessor schedule and Beacon programs. Must match exactly.
            </p>
          </div>
        </div>
      </section>

      {/* === Description & History (rich text fields) === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Content</h2>
        <div className="mt-4 space-y-4">
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Description
            </label>
            <textarea
              value={form.description}
              onChange={(e) => updateField("description", e.target.value)}
              rows={6}
              placeholder="About the show — displayed in the main content area"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
            />
            <p className="mt-1 text-xs text-charcoal/40">
              HTML supported. Rich text editor coming in a future phase.
            </p>
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              History & Legacy
            </label>
            <textarea
              value={form.history}
              onChange={(e) => updateField("history", e.target.value)}
              rows={4}
              placeholder="Optional section about the show's history"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
            />
          </div>
        </div>
      </section>

      {/* === Media Paths === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Media</h2>
        <p className="mt-1 text-xs text-charcoal/40">
          Storage paths for logo and banner images. Media library upload coming in a future phase.
        </p>
        <div className="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Logo Path
            </label>
            <input
              type="text"
              value={form.logo_path}
              onChange={(e) => updateField("logo_path", e.target.value)}
              placeholder="shows/bike-talk/logo.webp"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 font-mono text-sm focus:border-charcoal focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Banner Path
            </label>
            <input
              type="text"
              value={form.banner_path}
              onChange={(e) => updateField("banner_path", e.target.value)}
              placeholder="shows/bike-talk/banner.webp"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 font-mono text-sm focus:border-charcoal focus:outline-none"
            />
          </div>
        </div>
      </section>

      {/* === Contact === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Contact</h2>
        <div className="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Contact Preference
            </label>
            <select
              value={form.contact_preference}
              onChange={(e) => updateField("contact_preference", e.target.value as ShowFormData["contact_preference"])}
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
            >
              <option value="form">Contact form only</option>
              <option value="email">Public email only</option>
              <option value="both">Form + public email</option>
              <option value="none">No contact</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Contact Email
            </label>
            <input
              type="email"
              value={form.contact_email}
              onChange={(e) => updateField("contact_email", e.target.value)}
              placeholder="host@example.com"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
            />
          </div>
        </div>
      </section>

      {/* === Links === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Links</h2>
        <div className="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Website URL
            </label>
            <input
              type="url"
              value={form.website_url}
              onChange={(e) => updateField("website_url", e.target.value)}
              placeholder="https://example.com"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              RSS Feed URL
            </label>
            <input
              type="url"
              value={form.rss_url}
              onChange={(e) => updateField("rss_url", e.target.value)}
              placeholder="https://example.com/feed.xml"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
            />
          </div>
        </div>
      </section>

      {/* === Social Links === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Social Media</h2>
        <p className="mt-1 text-xs text-charcoal/40">
          Paste any social or podcast URL — the platform is detected automatically.
        </p>
        <div className="mt-4 space-y-3">
          {socialEntries.map((entry) => (
            <div key={entry.id} className="flex items-center gap-2">
              <span className="w-28 flex-shrink-0 text-xs font-medium text-charcoal/50">
                {entry.platform ? (PLATFORM_LABELS[entry.platform] || entry.platform) : "Link"}
              </span>
              <input
                type="url"
                value={entry.url}
                onChange={(e) => updateSocialEntry(entry.id, e.target.value)}
                placeholder="https://..."
                className="block flex-1 border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
              />
              <button
                type="button"
                onClick={() => removeSocialEntry(entry.id)}
                className="flex-shrink-0 px-2 py-2 text-charcoal/30 hover:text-kpfk-red"
                title="Remove link"
              >
                <svg className="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
                </svg>
              </button>
            </div>
          ))}
          <button
            type="button"
            onClick={addSocialEntry}
            className="mt-1 text-sm font-medium text-charcoal/50 hover:text-charcoal"
          >
            + Add another link
          </button>
        </div>
      </section>

      {/* === Donation CTA Override === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Donation CTA</h2>
        <p className="mt-1 text-xs text-charcoal/40">
          Override the default sidebar donation call-to-action. Leave blank to use defaults.
        </p>
        <div className="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <label className="block text-sm font-medium text-charcoal">
              CTA Heading
            </label>
            <input
              type="text"
              value={form.donation_cta_heading}
              onChange={(e) => updateField("donation_cta_heading", e.target.value)}
              placeholder={`Support ${form.title || "this show"}`}
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Donate URL
            </label>
            <input
              type="url"
              value={form.donation_cta_url}
              onChange={(e) => updateField("donation_cta_url", e.target.value)}
              placeholder="https://donate.kpfk.org"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
            />
          </div>
          <div className="md:col-span-2">
            <label className="block text-sm font-medium text-charcoal">
              CTA Body Text
            </label>
            <input
              type="text"
              value={form.donation_cta_body}
              onChange={(e) => updateField("donation_cta_body", e.target.value)}
              placeholder="Keep community radio on the air."
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
            />
          </div>
        </div>
      </section>

      {/* === Broadcast Status === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Broadcast Status</h2>
        <div className="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Status
            </label>
            <select
              value={form.broadcast_status}
              onChange={(e) => updateField("broadcast_status", e.target.value as ShowFormData["broadcast_status"])}
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2.5 text-base focus:border-charcoal focus:outline-none"
            >
              <option value="active">Active</option>
              <option value="hiatus">On Hiatus</option>
              <option value="online_only">Online Only</option>
              <option value="retired">Retired</option>
            </select>
          </div>
          {form.broadcast_status === "hiatus" && (
            <div>
              <label className="block text-sm font-medium text-charcoal">
                Returns At
              </label>
              <input
                type="date"
                value={form.returns_at}
                onChange={(e) => updateField("returns_at", e.target.value)}
                className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2.5 text-base focus:border-charcoal focus:outline-none"
              />
            </div>
          )}
          <div className="md:col-span-2">
            <label className="block text-sm font-medium text-charcoal">
              Status Note
            </label>
            <input
              type="text"
              value={form.status_note}
              onChange={(e) => updateField("status_note", e.target.value)}
              placeholder="e.g. New episodes returning June 2026"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2.5 text-base focus:border-charcoal focus:outline-none"
            />
            <p className="mt-1 text-xs text-charcoal/40">
              Free text displayed publicly where the schedule badge would go.
            </p>
          </div>
          <div className="md:col-span-2">
            <label className="block text-sm font-medium text-charcoal">
              Schedule Note
            </label>
            <input
              type="text"
              value={form.schedule_note}
              onChange={(e) => updateField("schedule_note", e.target.value)}
              placeholder="e.g. New episodes daily — airing Mon–Thu on KPFK"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2.5 text-base focus:border-charcoal focus:outline-none"
            />
            <p className="mt-1 text-xs text-charcoal/40">
              Displayed below the auto-generated schedule badge.
            </p>
          </div>
        </div>
      </section>

      {/* === Tags === */}
      {allTags.length > 0 && (
        <section>
          <h2 className="text-lg font-bold text-charcoal">Tags</h2>
          <p className="mt-1 text-xs text-charcoal/40">Click to toggle tags for this show.</p>
          {(["topic", "format", "audience"] as const).map((category) => {
            const categoryTags = allTags.filter((t) => t.category === category);
            if (categoryTags.length === 0) return null;
            return (
              <div key={category} className="mt-4">
                <span className="text-xs font-bold uppercase tracking-wider text-charcoal/40">
                  {category === "topic" ? "Topics" : category === "format" ? "Formats" : "Audience"}
                </span>
                <div className="mt-2 flex flex-wrap gap-2">
                  {categoryTags.map((tag) => {
                    const isSelected = selectedTagIds.includes(tag.id);
                    return (
                      <button
                        key={tag.id}
                        type="button"
                        onClick={() => {
                          setSelectedTagIds((prev) =>
                            isSelected
                              ? prev.filter((id) => id !== tag.id)
                              : [...prev, tag.id]
                          );
                        }}
                        className={`border px-3 py-1.5 text-sm transition-colors ${
                          isSelected
                            ? `${TAG_CATEGORY_COLORS[tag.category]} border-charcoal/30 font-medium text-charcoal`
                            : "border-charcoal/15 text-charcoal/40 hover:border-charcoal/30 hover:text-charcoal/60"
                        }`}
                      >
                        {tag.name}
                      </button>
                    );
                  })}
                </div>
              </div>
            );
          })}
        </section>
      )}

      {/* === Settings === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Settings</h2>
        <div className="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Sort Order
            </label>
            <input
              type="number"
              value={form.sort_order}
              onChange={(e) => updateField("sort_order", parseInt(e.target.value) || 0)}
              className="mt-1 block w-32 border border-charcoal/20 bg-off-white px-3 py-2.5 text-base focus:border-charcoal focus:outline-none"
            />
          </div>
          <div className="flex items-center gap-3 pt-6">
            <input
              id="is_active"
              type="checkbox"
              checked={form.is_active}
              onChange={(e) => updateField("is_active", e.target.checked)}
              className="h-4 w-4 accent-charcoal"
            />
            <label htmlFor="is_active" className="text-sm text-charcoal">
              Show is active (visible in directory)
            </label>
          </div>
        </div>
      </section>

      {/* === Submit === */}
      {error && (
        <p className="text-sm text-kpfk-red">{error}</p>
      )}
      <div className="flex flex-col gap-3 border-t border-charcoal/10 pt-6 sm:flex-row sm:items-center">
        <button
          type="submit"
          disabled={saving}
          className="border-2 border-charcoal bg-charcoal px-6 py-2.5 text-sm font-medium text-off-white hover:bg-charcoal/90 disabled:opacity-50"
        >
          {saving
            ? "Saving…"
            : mode === "create"
              ? "Create show"
              : "Save changes"}
        </button>
        <button
          type="button"
          onClick={() => router.push("/admin/shows")}
          className="px-4 py-2.5 text-sm text-charcoal/60 hover:text-charcoal"
        >
          Cancel
        </button>
      </div>
    </form>
  );
}
