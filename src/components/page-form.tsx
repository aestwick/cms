"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";

export interface PageFormData {
  title: string;
  slug: string;
  body: string;
  parent_id: string;
  meta_title: string;
  meta_description: string;
  sort_order: number;
  is_published: boolean;
}

const emptyPage: PageFormData = {
  title: "",
  slug: "",
  body: "",
  parent_id: "",
  meta_title: "",
  meta_description: "",
  sort_order: 0,
  is_published: true,
};

interface PageFormProps {
  initialData?: Partial<PageFormData>;
  pageId?: string;
  mode: "create" | "edit";
}

interface PageOption {
  id: string;
  title: string;
  slug: string;
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

export function PageForm({ initialData, pageId, mode }: PageFormProps) {
  const router = useRouter();
  const [form, setForm] = useState<PageFormData>({ ...emptyPage, ...initialData });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [slugManual, setSlugManual] = useState(mode === "edit");
  const [pages, setPages] = useState<PageOption[]>([]);

  useEffect(() => {
    fetch("/api/pages")
      .then((res) => (res.ok ? res.json() : []))
      .then((data) => setPages(data.filter((p: PageOption) => p.id !== pageId)))
      .catch(() => {});
  }, [pageId]);

  function updateField<K extends keyof PageFormData>(key: K, value: PageFormData[K]) {
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

    const url = mode === "create" ? "/api/pages" : `/api/pages/${pageId}`;
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

    router.push("/admin/pages");
    router.refresh();
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-8">
      {/* === Page Info === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Page Info</h2>
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
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Slug <span className="text-kpfk-red">*</span>
            </label>
            <div className="mt-1 flex items-center gap-2">
              <span className="text-xs font-mono text-charcoal/40">/p/</span>
              <input
                type="text"
                required
                pattern="[a-z0-9-]+"
                value={form.slug}
                onChange={(e) => {
                  setSlugManual(true);
                  updateField("slug", e.target.value);
                }}
                className="block flex-1 border border-charcoal/20 bg-off-white px-3 py-2 font-mono text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
              />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Parent Page
            </label>
            <select
              value={form.parent_id}
              onChange={(e) => updateField("parent_id", e.target.value)}
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
            >
              <option value="">None (top-level page)</option>
              {pages.map((page) => (
                <option key={page.id} value={page.id}>
                  {page.title}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Sort Order
            </label>
            <input
              type="number"
              value={form.sort_order}
              onChange={(e) => updateField("sort_order", parseInt(e.target.value) || 0)}
              className="mt-1 block w-32 border border-charcoal/20 bg-off-white px-3 py-2 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
            />
          </div>
        </div>
      </section>

      {/* === Content === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">Content</h2>
        <div className="mt-4">
          <label className="block text-sm font-medium text-charcoal">
            Body
          </label>
          <textarea
            value={form.body}
            onChange={(e) => updateField("body", e.target.value)}
            rows={16}
            placeholder="Page content…"
            className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
          />
          <p className="mt-1 text-xs text-charcoal/40">
            HTML supported. Rich text editor coming in a future phase.
          </p>
        </div>
      </section>

      {/* === SEO === */}
      <section>
        <h2 className="text-lg font-bold text-charcoal">SEO</h2>
        <div className="mt-4 space-y-4">
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Meta Title
            </label>
            <input
              type="text"
              value={form.meta_title}
              onChange={(e) => updateField("meta_title", e.target.value)}
              placeholder="Auto-generated from title if empty"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-charcoal">
              Meta Description
            </label>
            <textarea
              value={form.meta_description}
              onChange={(e) => updateField("meta_description", e.target.value)}
              rows={2}
              placeholder="Short description for search engines"
              className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none"
            />
          </div>
        </div>
      </section>

      {/* === Publishing === */}
      <section>
        <div className="flex items-center gap-3">
          <input
            id="is_published"
            type="checkbox"
            checked={form.is_published}
            onChange={(e) => updateField("is_published", e.target.checked)}
            className="h-4 w-4 accent-charcoal"
          />
          <label htmlFor="is_published" className="text-sm text-charcoal">
            Published (visible to the public)
          </label>
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
          className="border border-kpfk-red bg-kpfk-red px-6 py-2 text-sm font-extrabold uppercase tracking-[0.04em] text-white hover:bg-kpfk-red-press disabled:opacity-50"
        >
          {saving
            ? "Saving…"
            : mode === "create"
              ? "Create page"
              : "Save changes"}
        </button>
        <button
          type="button"
          onClick={() => router.push("/admin/pages")}
          className="px-4 py-2 text-sm text-charcoal/60 hover:text-charcoal"
        >
          Cancel
        </button>
      </div>
    </form>
  );
}
