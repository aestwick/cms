"use client";

import { useState } from "react";

interface Host {
  id?: string;
  name: string;
  bio: string;
  photo_path: string;
  email: string;
  is_primary: boolean;
  sort_order: number;
}

interface HostManagerProps {
  showId: string;
  initialHosts: Host[];
}

const emptyHost: Host = {
  name: "",
  bio: "",
  photo_path: "",
  email: "",
  is_primary: false,
  sort_order: 0,
};

export function HostManager({ showId, initialHosts }: HostManagerProps) {
  const [hosts, setHosts] = useState<Host[]>(
    initialHosts.length > 0
      ? initialHosts.map((h) => ({
          id: h.id,
          name: h.name || "",
          bio: h.bio || "",
          photo_path: h.photo_path || "",
          email: h.email || "",
          is_primary: h.is_primary,
          sort_order: h.sort_order,
        }))
      : []
  );
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState("");

  function addHost() {
    setHosts((prev) => [
      ...prev,
      { ...emptyHost, sort_order: prev.length },
    ]);
  }

  function removeHost(index: number) {
    setHosts((prev) => prev.filter((_, i) => i !== index));
  }

  function updateHost(index: number, field: keyof Host, value: string | boolean | number) {
    setHosts((prev) =>
      prev.map((h, i) => (i === index ? { ...h, [field]: value } : h))
    );
  }

  function setPrimary(index: number) {
    setHosts((prev) =>
      prev.map((h, i) => ({ ...h, is_primary: i === index }))
    );
  }

  async function handleSave() {
    setSaving(true);
    setMessage("");

    const res = await fetch(`/api/shows/${showId}/hosts`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        hosts: hosts.map((h, i) => ({ ...h, sort_order: i })),
      }),
    });

    setSaving(false);

    if (res.ok) {
      setMessage("Hosts saved.");
      setTimeout(() => setMessage(""), 3000);
    } else {
      const data = await res.json();
      setMessage(`Error: ${data.error}`);
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-bold text-charcoal">Hosts</h2>
        <button
          type="button"
          onClick={addHost}
          className="border border-charcoal/20 px-3 py-1 text-sm text-charcoal hover:bg-charcoal/5"
        >
          + Add host
        </button>
      </div>

      {hosts.length === 0 && (
        <p className="mt-4 text-sm text-charcoal/40">
          No hosts added yet. Add a host to associate them with this show.
        </p>
      )}

      <div className="mt-4 space-y-6">
        {hosts.map((host, index) => (
          <div
            key={index}
            className="border border-charcoal/10 p-4"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <span className="font-mono text-xs text-charcoal/30">
                  #{index + 1}
                </span>
                <button
                  type="button"
                  onClick={() => setPrimary(index)}
                  className={`rounded px-2 py-0.5 text-xs ${
                    host.is_primary
                      ? "bg-charcoal text-off-white"
                      : "border border-charcoal/20 text-charcoal/40 hover:text-charcoal"
                  }`}
                >
                  {host.is_primary ? "Primary" : "Set primary"}
                </button>
              </div>
              <button
                type="button"
                onClick={() => removeHost(index)}
                className="text-xs text-kpfk-red hover:underline"
              >
                Remove
              </button>
            </div>

            <div className="mt-3 grid grid-cols-1 gap-3 md:grid-cols-2">
              <div>
                <label className="block text-xs font-medium text-charcoal/60">
                  Name <span className="text-kpfk-red">*</span>
                </label>
                <input
                  type="text"
                  required
                  value={host.name}
                  onChange={(e) => updateHost(index, "name", e.target.value)}
                  className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-1.5 text-sm focus:border-charcoal focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-charcoal/60">
                  Email
                </label>
                <input
                  type="email"
                  value={host.email}
                  onChange={(e) => updateHost(index, "email", e.target.value)}
                  placeholder="host@kpfk.org"
                  className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-1.5 text-sm focus:border-charcoal focus:outline-none"
                />
              </div>
              <div className="md:col-span-2">
                <label className="block text-xs font-medium text-charcoal/60">
                  Bio
                </label>
                <textarea
                  value={host.bio}
                  onChange={(e) => updateHost(index, "bio", e.target.value)}
                  rows={3}
                  placeholder="Host bio — HTML supported"
                  className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-1.5 text-sm focus:border-charcoal focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-charcoal/60">
                  Photo Path
                </label>
                <input
                  type="text"
                  value={host.photo_path}
                  onChange={(e) => updateHost(index, "photo_path", e.target.value)}
                  placeholder="shows/bike-talk/host-photo.webp"
                  className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-1.5 font-mono text-sm focus:border-charcoal focus:outline-none"
                />
              </div>
            </div>
          </div>
        ))}
      </div>

      {hosts.length > 0 && (
        <div className="mt-4 flex items-center gap-3">
          <button
            type="button"
            onClick={handleSave}
            disabled={saving}
            className="border-2 border-charcoal bg-charcoal px-4 py-2 text-sm font-medium text-off-white hover:bg-charcoal/90 disabled:opacity-50"
          >
            {saving ? "Saving…" : "Save hosts"}
          </button>
          {message && (
            <span
              className={`text-sm ${
                message.startsWith("Error") ? "text-kpfk-red" : "text-green-600"
              }`}
            >
              {message}
            </span>
          )}
        </div>
      )}
    </div>
  );
}
