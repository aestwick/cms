"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";

export interface PostFormData {
  title: string;
  slug: string;
  body: string;
  excerpt: string;
  featured_image_path: string;
  status: "draft" | "published";
  show_id: string;
  is_featured: boolean;
}

const emptyPost: PostFormData = {
  title: "",
  slug: "",
  body: "",
  excerpt: "",
  featured_image_path: "",
  status: "draft",
  show_id: "",
  is_featured: false,
};

interface PostFormProps {
  initialData?: Partial<PostFormData>;
  postId?: string;
  mode: "create" | "edit";
}

interface ShowOption {
  id: string;
  title: string;
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

export function PostForm({ initialData, postId, mode }: PostFormProps) {
  const router = useRouter();
  const [form, setForm] = useState<PostFormData>({ ...emptyPost, ...initialData });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [slugManual, setSlugManual] = useState(mode === "edit");
  const [shows, setShows] = useState<ShowOption[]>([]);

  useEffect(() => {
    // Try /api/shows first (admin/editor), fall back to /api/posts/shows (host-accessible)
    fetch("/api/shows")
      .then((res) => {
        if (res.ok) return res.json();
        // Hosts don't have access to /api/shows — use dedicated endpoint
        return fetch("/api/posts/shows").then((r) => (r.ok ? r.json() : []));
      })
      .then((data) => setShows(data))
      .catch(() => {});
  }, []);

  function updateField<K extends keyof PostFormData>(key: K, value: PostFormData[K]) {
    setForm((prev) => ({ ...prev, [key]: value }));
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

    const url = mode === "create" ? "/api/posts" : `/api/posts/${postId}`;
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

    router.push("/admin/blog");
    router.refresh();
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-8">
      {/* === Post Info === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Post Info</h2>
        <div className="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
          <div className="md:col-span-2">
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
              <span className="text-xs font-mono text-charcoal/40">/blog/</span>
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
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Show (optional)
            </label>
            <select
              value={form.show_id}
              onChange={(e) => updateField("show_id", e.target.value)}
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
            >
              <option value="">No show — station-wide post</option>
              {shows.map((show) => (
                <option key={show.id} value={show.id}>
                  {show.title}
                </option>
              ))}
            </select>
            <p className="mt-1 text-xs text-charcoal/40">
              Show-scoped posts also appear on the show&apos;s public page.
            </p>
          </div>
        </div>
      </section>

      {/* === Content === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Content</h2>
        <div className="mt-4 space-y-4">
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Body <span className="text-kpfk-red">*</span>
            </label>
            <textarea
              required
              value={form.body}
              onChange={(e) => updateField("body", e.target.value)}
              rows={16}
              placeholder="Write your post content here…"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
            />
            <p className="mt-1 text-xs text-charcoal/40">
              HTML supported. Rich text editor coming in a future phase.
            </p>
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Excerpt
            </label>
            <textarea
              value={form.excerpt}
              onChange={(e) => updateField("excerpt", e.target.value)}
              rows={3}
              placeholder="Short summary for listing pages. Auto-generated from body if left empty."
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
            />
          </div>
        </div>
      </section>

      {/* === Media === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Featured Image</h2>
        <div className="mt-4">
          <label className="block text-sm font-medium text-charcoal">
            Image Path
          </label>
          <input
            type="text"
            value={form.featured_image_path}
            onChange={(e) => updateField("featured_image_path", e.target.value)}
            placeholder="posts/my-post/hero.webp"
            className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 font-mono text-sm focus:border-charcoal focus:outline-none"
          />
          <p className="mt-1 text-xs text-charcoal/40">
            Supabase Storage path. Media library upload coming in a future phase.
          </p>
        </div>
      </section>

      {/* === Publishing === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Publishing</h2>
        <div className="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Status
            </label>
            <select
              value={form.status}
              onChange={(e) => updateField("status", e.target.value as PostFormData["status"])}
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
            >
              <option value="draft">Draft</option>
              <option value="published">Published</option>
            </select>
          </div>
          <div className="flex items-center gap-3 pt-6">
            <input
              id="is_featured"
              type="checkbox"
              checked={form.is_featured}
              onChange={(e) => updateField("is_featured", e.target.checked)}
              className="h-4 w-4 accent-charcoal"
            />
            <label htmlFor="is_featured" className="text-sm text-charcoal">
              Featured post (pinned to homepage)
            </label>
          </div>
        </div>
      </section>

      {/* === Submit === */}
      {error && (
        <p className="text-sm text-kpfk-red">{error}</p>
      )}
      <div className="flex items-center gap-3 border-t border-charcoal/10 pt-6">
        <button
          type="submit"
          disabled={saving}
          className="border-2 border-charcoal bg-charcoal px-6 py-2 text-sm font-medium text-off-white hover:bg-charcoal/90 disabled:opacity-50"
        >
          {saving
            ? "Saving…"
            : mode === "create"
              ? "Create post"
              : "Save changes"}
        </button>
        <button
          type="button"
          onClick={() => router.push("/admin/blog")}
          className="px-4 py-2 text-sm text-charcoal/60 hover:text-charcoal"
        >
          Cancel
        </button>
      </div>
    </form>
  );
}
