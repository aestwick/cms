"use client";

import { useEffect, useState } from "react";

interface StationSettings {
  fund_drive_active: boolean;
  default_contact_email: string;
  social_links: {
    facebook: string;
    twitter: string;
    instagram: string;
  };
}

interface StationData {
  id: string;
  name: string;
  slug: string;
  tagline: string | null;
  timezone: string;
  stream_url: string | null;
  beacon_api_url: string | null;
  confessor_api_url: string | null;
  analytics_site_id: string | null;
  settings: StationSettings;
  created_at: string;
  updated_at: string;
}

export function SettingsForm() {
  const [station, setStation] = useState<StationData | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  // Form state
  const [name, setName] = useState("");
  const [tagline, setTagline] = useState("");
  const [streamUrl, setStreamUrl] = useState("");
  const [beaconApiUrl, setBeaconApiUrl] = useState("");
  const [confessorApiUrl, setConfessorApiUrl] = useState("");
  const [fundDriveActive, setFundDriveActive] = useState(false);
  const [defaultContactEmail, setDefaultContactEmail] = useState("");
  const [facebook, setFacebook] = useState("");
  const [twitter, setTwitter] = useState("");
  const [instagram, setInstagram] = useState("");

  useEffect(() => {
    async function loadSettings() {
      try {
        const res = await fetch("/api/settings");
        if (!res.ok) {
          throw new Error("Failed to load settings");
        }
        const data: StationData = await res.json();
        setStation(data);

        // Populate form
        setName(data.name || "");
        setTagline(data.tagline || "");
        setStreamUrl(data.stream_url || "");
        setBeaconApiUrl(data.beacon_api_url || "");
        setConfessorApiUrl(data.confessor_api_url || "");
        setFundDriveActive(data.settings?.fund_drive_active ?? false);
        setDefaultContactEmail(data.settings?.default_contact_email || "");
        setFacebook(data.settings?.social_links?.facebook || "");
        setTwitter(data.settings?.social_links?.twitter || "");
        setInstagram(data.settings?.social_links?.instagram || "");
      } catch (err) {
        setError(err instanceof Error ? err.message : "Failed to load settings");
      } finally {
        setLoading(false);
      }
    }

    loadSettings();
  }, []);

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);
    setSuccess(false);

    try {
      const res = await fetch("/api/settings", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name,
          tagline: tagline || null,
          stream_url: streamUrl || null,
          beacon_api_url: beaconApiUrl || null,
          confessor_api_url: confessorApiUrl || null,
          settings: {
            fund_drive_active: fundDriveActive,
            default_contact_email: defaultContactEmail,
            social_links: {
              facebook: facebook || "",
              twitter: twitter || "",
              instagram: instagram || "",
            },
          },
        }),
      });

      if (!res.ok) {
        const body = await res.json();
        throw new Error(body.error || "Failed to save settings");
      }

      const updated = await res.json();
      setStation(updated);
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save settings");
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <div className=" border border-charcoal/20 bg-white p-12 text-center text-charcoal/40">
        Loading settings...
      </div>
    );
  }

  if (error && !station) {
    return (
      <div className=" border border-red-200 bg-red-50 p-6 text-red-800">
        {error}
      </div>
    );
  }

  return (
    <form onSubmit={handleSave} className=" border border-charcoal/20 bg-white">
      {/* Station Info */}
      <div className="border-b border-charcoal/10 px-6 py-8">
        <h2 className="font-serif text-xl font-bold text-charcoal">
          Station Info
        </h2>
        <p className="mt-1 text-sm text-charcoal/50">
          Basic station identity and display name.
        </p>
        <div className="mt-6 grid gap-6 sm:grid-cols-2">
          <div>
            <label className="mb-2 block font-mono text-xs uppercase tracking-wide text-charcoal/60">
              Station Name
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full border-2 border-charcoal/20 px-4 py-2 text-charcoal transition-colors rounded-[2px] focus:border-kpfk-red focus:outline-none"
              required
            />
          </div>
          <div>
            <label className="mb-2 block font-mono text-xs uppercase tracking-wide text-charcoal/60">
              Slug
            </label>
            <input
              type="text"
              value={station?.slug || ""}
              disabled
              className="w-full border-2 border-charcoal/10 bg-charcoal/5 px-4 py-2 text-charcoal/50"
            />
            <p className="mt-1 text-xs text-charcoal/40">
              Slug cannot be changed.
            </p>
          </div>
          <div className="sm:col-span-2">
            <label className="mb-2 block font-mono text-xs uppercase tracking-wide text-charcoal/60">
              Tagline
            </label>
            <input
              type="text"
              value={tagline}
              onChange={(e) => setTagline(e.target.value)}
              className="w-full border-2 border-charcoal/20 px-4 py-2 text-charcoal transition-colors rounded-[2px] focus:border-kpfk-red focus:outline-none"
              placeholder="e.g. Listener-Sponsored Radio for Los Angeles"
            />
          </div>
        </div>
      </div>

      {/* Stream & APIs */}
      <div className="border-b border-charcoal/10 px-6 py-8">
        <h2 className="font-serif text-xl font-bold text-charcoal">
          Stream & APIs
        </h2>
        <p className="mt-1 text-sm text-charcoal/50">
          External service URLs that the CMS connects to.
        </p>
        <div className="mt-6 grid gap-6">
          <div>
            <label className="mb-2 block font-mono text-xs uppercase tracking-wide text-charcoal/60">
              Stream URL
            </label>
            <input
              type="url"
              value={streamUrl}
              onChange={(e) => setStreamUrl(e.target.value)}
              className="w-full border-2 border-charcoal/20 px-4 py-2 text-charcoal transition-colors rounded-[2px] focus:border-kpfk-red focus:outline-none"
              placeholder="https://stream.kpfk.org/live"
            />
          </div>
          <div>
            <label className="mb-2 block font-mono text-xs uppercase tracking-wide text-charcoal/60">
              Beacon API URL
            </label>
            <input
              type="url"
              value={beaconApiUrl}
              onChange={(e) => setBeaconApiUrl(e.target.value)}
              className="w-full border-2 border-charcoal/20 px-4 py-2 text-charcoal transition-colors rounded-[2px] focus:border-kpfk-red focus:outline-none"
              placeholder="https://beacon.kpfk.org/api"
            />
          </div>
          <div>
            <label className="mb-2 block font-mono text-xs uppercase tracking-wide text-charcoal/60">
              Confessor API URL
            </label>
            <input
              type="url"
              value={confessorApiUrl}
              onChange={(e) => setConfessorApiUrl(e.target.value)}
              className="w-full border-2 border-charcoal/20 px-4 py-2 text-charcoal transition-colors rounded-[2px] focus:border-kpfk-red focus:outline-none"
              placeholder="https://confessor.kpfk.org"
            />
          </div>
        </div>
      </div>

      {/* Fund Drive */}
      <div className="border-b border-charcoal/10 px-6 py-8">
        <h2 className="font-serif text-xl font-bold text-charcoal">
          Fund Drive
        </h2>
        <p className="mt-1 text-sm text-charcoal/50">
          Controls fund drive mode across the public site.
        </p>
        <div className="mt-6">
          <label className="flex cursor-pointer items-start gap-4">
            <input
              type="checkbox"
              checked={fundDriveActive}
              onChange={(e) => setFundDriveActive(e.target.checked)}
              className="mt-1 h-5 w-5 shrink-0 border-2 border-charcoal/30 text-kpfk-red accent-kpfk-red focus:ring-kpfk-red"
            />
            <div>
              <span className="font-medium text-charcoal">
                Fund Drive Active
              </span>
              <p className="mt-1 text-sm text-charcoal/50">
                When enabled, fund drive banners and donation CTAs appear
                site-wide. This adds donation prompts throughout the site but
                does not change colors or layout.
              </p>
            </div>
          </label>
          {fundDriveActive && (
            <div className="mt-4 border border-amber-300 bg-amber-50 px-4 py-3 text-sm text-amber-800">
              Fund drive mode is currently active. Donation CTAs are visible
              site-wide. Toggle off when the drive ends.
            </div>
          )}
        </div>
      </div>

      {/* Contact */}
      <div className="border-b border-charcoal/10 px-6 py-8">
        <h2 className="font-serif text-xl font-bold text-charcoal">
          Contact
        </h2>
        <p className="mt-1 text-sm text-charcoal/50">
          Default contact email used for forms when no show-specific email is
          configured.
        </p>
        <div className="mt-6">
          <label className="mb-2 block font-mono text-xs uppercase tracking-wide text-charcoal/60">
            Default Contact Email
          </label>
          <input
            type="email"
            value={defaultContactEmail}
            onChange={(e) => setDefaultContactEmail(e.target.value)}
            className="w-full max-w-md border-2 border-charcoal/20 px-4 py-2 text-charcoal transition-colors rounded-[2px] focus:border-kpfk-red focus:outline-none"
            placeholder="info@kpfk.org"
          />
        </div>
      </div>

      {/* Social Links */}
      <div className="border-b border-charcoal/10 px-6 py-8">
        <h2 className="font-serif text-xl font-bold text-charcoal">
          Social Links
        </h2>
        <p className="mt-1 text-sm text-charcoal/50">
          Station social media profiles shown in the site footer and header.
        </p>
        <div className="mt-6 grid gap-6">
          <div>
            <label className="mb-2 block font-mono text-xs uppercase tracking-wide text-charcoal/60">
              Facebook
            </label>
            <input
              type="url"
              value={facebook}
              onChange={(e) => setFacebook(e.target.value)}
              className="w-full border-2 border-charcoal/20 px-4 py-2 text-charcoal transition-colors rounded-[2px] focus:border-kpfk-red focus:outline-none"
              placeholder="https://facebook.com/kpfk"
            />
          </div>
          <div>
            <label className="mb-2 block font-mono text-xs uppercase tracking-wide text-charcoal/60">
              Twitter / X
            </label>
            <input
              type="url"
              value={twitter}
              onChange={(e) => setTwitter(e.target.value)}
              className="w-full border-2 border-charcoal/20 px-4 py-2 text-charcoal transition-colors rounded-[2px] focus:border-kpfk-red focus:outline-none"
              placeholder="https://twitter.com/kpfk"
            />
          </div>
          <div>
            <label className="mb-2 block font-mono text-xs uppercase tracking-wide text-charcoal/60">
              Instagram
            </label>
            <input
              type="url"
              value={instagram}
              onChange={(e) => setInstagram(e.target.value)}
              className="w-full border-2 border-charcoal/20 px-4 py-2 text-charcoal transition-colors rounded-[2px] focus:border-kpfk-red focus:outline-none"
              placeholder="https://instagram.com/kpfk907fm"
            />
          </div>
        </div>
      </div>

      {/* Actions */}
      <div className="flex items-center gap-4 px-6 py-6">
        <button
          type="submit"
          disabled={saving}
          className=" border-2 border-charcoal bg-charcoal px-6 py-3 font-medium text-off-white transition-colors hover:bg-off-white hover:text-charcoal disabled:cursor-not-allowed disabled:opacity-50"
        >
          {saving ? "Saving..." : "Save Settings"}
        </button>

        {success && (
          <span className="text-sm font-medium text-green-700">
            Settings saved successfully.
          </span>
        )}

        {error && station && (
          <span className="text-sm font-medium text-red-700">{error}</span>
        )}
      </div>
    </form>
  );
}
