"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

interface Tag {
  id: string;
  name: string;
  slug: string;
  category: "topic" | "format" | "audience";
  sort_order: number;
}

const CATEGORY_LABELS: Record<string, string> = {
  topic: "Topics",
  format: "Formats",
  audience: "Audience",
};

const CATEGORY_COLORS: Record<string, string> = {
  topic: "bg-tag-topic",
  format: "bg-tag-format",
  audience: "bg-tag-audience",
};

export function TagManager({ initialTags }: { initialTags: Tag[] }) {
  const router = useRouter();
  const [tags, setTags] = useState<Tag[]>(initialTags);
  const [newTag, setNewTag] = useState({ name: "", category: "topic" as Tag["category"] });
  const [saving, setSaving] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editForm, setEditForm] = useState({ name: "", category: "topic" as Tag["category"] });

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    if (!newTag.name.trim()) return;
    setSaving(true);

    const res = await fetch("/api/tags", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(newTag),
    });

    if (res.ok) {
      const tag = await res.json();
      setTags((prev) => [...prev, tag]);
      setNewTag({ name: "", category: "topic" });
      router.refresh();
    }
    setSaving(false);
  }

  async function handleUpdate(id: string) {
    const res = await fetch(`/api/tags/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        name: editForm.name,
        category: editForm.category,
        slug: editForm.name
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, "-")
          .replace(/^-|-$/g, ""),
      }),
    });

    if (res.ok) {
      const updated = await res.json();
      setTags((prev) => prev.map((t) => (t.id === id ? updated : t)));
      setEditingId(null);
      router.refresh();
    }
  }

  async function handleDelete(id: string) {
    if (!confirm("Delete this tag? It will be removed from all shows.")) return;

    const res = await fetch(`/api/tags/${id}`, { method: "DELETE" });
    if (res.ok) {
      setTags((prev) => prev.filter((t) => t.id !== id));
      router.refresh();
    }
  }

  const grouped = {
    topic: tags.filter((t) => t.category === "topic"),
    format: tags.filter((t) => t.category === "format"),
    audience: tags.filter((t) => t.category === "audience"),
  };

  return (
    <div className="space-y-8">
      {/* Create form */}
      <form onSubmit={handleCreate} className="flex items-end gap-3">
        <div className="flex-1">
          <label className="block text-sm font-medium text-charcoal">Tag name</label>
          <input
            type="text"
            value={newTag.name}
            onChange={(e) => setNewTag((prev) => ({ ...prev, name: e.target.value }))}
            placeholder="e.g. Social Justice"
            className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2.5 text-base rounded-[2px] focus:border-kpfk-red focus:outline-none"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-charcoal">Category</label>
          <select
            value={newTag.category}
            onChange={(e) => setNewTag((prev) => ({ ...prev, category: e.target.value as Tag["category"] }))}
            className="mt-1 block border border-charcoal/20 bg-off-white px-3 py-2.5 text-base rounded-[2px] focus:border-kpfk-red focus:outline-none"
          >
            <option value="topic">Topic</option>
            <option value="format">Format</option>
            <option value="audience">Audience</option>
          </select>
        </div>
        <button
          type="submit"
          disabled={saving || !newTag.name.trim()}
          className="border-2 border-charcoal bg-charcoal px-5 py-2.5 text-base font-medium text-off-white hover:bg-charcoal/90 disabled:opacity-50"
        >
          Add tag
        </button>
      </form>

      {/* Tags by category */}
      {(["topic", "format", "audience"] as const).map((category) => (
        <section key={category}>
          <h3 className="text-sm font-bold uppercase tracking-wider text-charcoal/40">
            {CATEGORY_LABELS[category]}
          </h3>
          <div className="mt-3 space-y-1">
            {grouped[category].length === 0 && (
              <p className="py-3 text-sm text-charcoal/30">No {category} tags yet.</p>
            )}
            {grouped[category].map((tag) => (
              <div
                key={tag.id}
                className="flex items-center gap-3 border border-charcoal/10 px-4 py-3"
              >
                {editingId === tag.id ? (
                  <>
                    <input
                      type="text"
                      value={editForm.name}
                      onChange={(e) => setEditForm((prev) => ({ ...prev, name: e.target.value }))}
                      className="flex-1 border border-charcoal/20 bg-off-white px-2 py-1 text-base rounded-[2px] focus:border-kpfk-red focus:outline-none"
                    />
                    <select
                      value={editForm.category}
                      onChange={(e) => setEditForm((prev) => ({ ...prev, category: e.target.value as Tag["category"] }))}
                      className="border border-charcoal/20 bg-off-white px-2 py-1 text-sm focus:outline-none"
                    >
                      <option value="topic">Topic</option>
                      <option value="format">Format</option>
                      <option value="audience">Audience</option>
                    </select>
                    <button
                      onClick={() => handleUpdate(tag.id)}
                      className="text-sm font-medium text-charcoal hover:underline"
                    >
                      Save
                    </button>
                    <button
                      onClick={() => setEditingId(null)}
                      className="text-sm text-charcoal/40 hover:text-charcoal"
                    >
                      Cancel
                    </button>
                  </>
                ) : (
                  <>
                    <span className={`${CATEGORY_COLORS[tag.category]} border border-charcoal/10 px-2 py-0.5 text-sm text-charcoal`}>
                      {tag.name}
                    </span>
                    <span className="font-mono text-xs text-charcoal/30">{tag.slug}</span>
                    <div className="ml-auto flex items-center gap-3">
                      <button
                        onClick={() => {
                          setEditingId(tag.id);
                          setEditForm({ name: tag.name, category: tag.category });
                        }}
                        className="text-sm text-charcoal/50 hover:text-charcoal"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => handleDelete(tag.id)}
                        className="text-sm text-kpfk-red/60 hover:text-kpfk-red"
                      >
                        Delete
                      </button>
                    </div>
                  </>
                )}
              </div>
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}
