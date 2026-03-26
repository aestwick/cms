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
  social_links: {
    facebook?: string;
    twitter?: string;
    instagram?: string;
    youtube?: string;
    tiktok?: string;
  };
  donation_cta_heading: string;
  donation_cta_body: string;
  donation_cta_url: string;
  is_active: boolean;
  sort_order: number;
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
};

interface ShowFormProps {
  initialData?: Partial<ShowFormData>;
  showId?: string;
  mode: "create" | "edit";
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

export function ShowForm({ initialData, showId, mode }: ShowFormProps) {
  const router = useRouter();
  const [form, setForm] = useState<ShowFormData>({ ...emptyShow, ...initialData });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [slugManual, setSlugManual] = useState(mode === "edit");

  function updateField<K extends keyof ShowFormData>(key: K, value: ShowFormData[K]) {
    setForm((prev) => ({ ...prev, [key]: value }));
  }

  function updateSocialLink(platform: string, url: string) {
    setForm((prev) => ({
      ...prev,
      social_links: { ...prev.social_links, [platform]: url },
    }));
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

    const url = mode === "create" ? "/api/shows" : `/api/shows/${showId}`;
    const method = mode === "create" ? "POST" : "PATCH";

    const res = await fetch(url, {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(form),
    });

    const data = await res.json();
    setSaving(false);

    if (!res.ok) {
      setError(data.error || "Something went wrong");
      return;
    }

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
        <div className="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
          {(["facebook", "twitter", "instagram", "youtube", "tiktok"] as const).map(
            (platform) => (
              <div key={platform}>
                <label className="block text-sm font-medium capitalize text-charcoal">
                  {platform}
                </label>
                <input
                  type="url"
                  value={(form.social_links as Record<string, string>)[platform] || ""}
                  onChange={(e) => updateSocialLink(platform, e.target.value)}
                  placeholder={`https://${platform}.com/...`}
                  className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
                />
              </div>
            )
          )}
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
              className="mt-1 block w-32 border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
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
