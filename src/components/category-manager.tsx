"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button, Input, Label } from "@/components/ds";
import { VOICES, VOICE_COLOR_VAR, type Voice } from "@/lib/voices";

export interface Category {
  id: string;
  parent_id: string | null;
  name: string;
  slug: string;
  description: string | null;
  color: Voice | null;
  show_in_nav: boolean;
  sort_order: number;
}

const selectClass =
  "border border-charcoal/20 bg-off-white px-2 py-1.5 text-sm rounded-[2px] focus:border-kpfk-red focus:outline-none";

function ColorDot({ color }: { color: Voice | null }) {
  if (!color) return <span className="inline-block h-3 w-3 border border-charcoal/20" />;
  return (
    <span
      className="inline-block h-3 w-3"
      style={{ background: VOICE_COLOR_VAR[color] }}
      title={color}
    />
  );
}

interface EditState {
  name: string;
  slug: string;
  color: Voice | "";
  description: string;
  show_in_nav: boolean;
  parent_id: string;
}

export function CategoryManager({ initial }: { initial: Category[] }) {
  const router = useRouter();
  const [cats, setCats] = useState<Category[]>(initial);
  const [saving, setSaving] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [edit, setEdit] = useState<EditState | null>(null);
  const [draft, setDraft] = useState({
    name: "",
    parent_id: "",
    color: "" as Voice | "",
    show_in_nav: false,
  });

  const topLevel = cats
    .filter((c) => !c.parent_id)
    .sort((a, b) => a.sort_order - b.sort_order);
  const childrenOf = (id: string) =>
    cats.filter((c) => c.parent_id === id).sort((a, b) => a.sort_order - b.sort_order);

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    if (!draft.name.trim()) return;
    setSaving(true);
    const res = await fetch("/api/categories", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        name: draft.name,
        parent_id: draft.parent_id || null,
        color: draft.color || null,
        show_in_nav: draft.show_in_nav,
      }),
    });
    if (res.ok) {
      const cat = await res.json();
      setCats((prev) => [...prev, cat]);
      setDraft({ name: "", parent_id: "", color: "", show_in_nav: false });
      router.refresh();
    }
    setSaving(false);
  }

  function startEdit(c: Category) {
    setEditingId(c.id);
    setEdit({
      name: c.name,
      slug: c.slug,
      color: c.color ?? "",
      description: c.description ?? "",
      show_in_nav: c.show_in_nav,
      parent_id: c.parent_id ?? "",
    });
  }

  async function handleUpdate(id: string) {
    if (!edit) return;
    const res = await fetch(`/api/categories/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        name: edit.name,
        slug: edit.slug,
        color: edit.color || null,
        description: edit.description,
        show_in_nav: edit.show_in_nav,
        parent_id: edit.parent_id || null,
      }),
    });
    if (res.ok) {
      const updated = await res.json();
      setCats((prev) => prev.map((c) => (c.id === id ? updated : c)));
      setEditingId(null);
      setEdit(null);
      router.refresh();
    }
  }

  async function handleDelete(id: string) {
    if (!confirm("Delete this category? Its sub-categories are removed too.")) return;
    const res = await fetch(`/api/categories/${id}`, { method: "DELETE" });
    if (res.ok) {
      setCats((prev) => prev.filter((c) => c.id !== id && c.parent_id !== id));
      router.refresh();
    }
  }

  function Row({ c, depth }: { c: Category; depth: number }) {
    const isEditing = editingId === c.id;
    return (
      <div className="border border-charcoal/10" style={{ marginLeft: depth * 20 }}>
        {isEditing && edit ? (
          <div className="space-y-3 p-4">
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              <div>
                <Label>Name</Label>
                <Input
                  value={edit.name}
                  onChange={(e) => setEdit({ ...edit, name: e.target.value })}
                />
              </div>
              <div>
                <Label>Slug</Label>
                <Input
                  value={edit.slug}
                  onChange={(e) => setEdit({ ...edit, slug: e.target.value })}
                />
              </div>
            </div>
            <div>
              <Label>Description</Label>
              <Input
                value={edit.description}
                onChange={(e) => setEdit({ ...edit, description: e.target.value })}
              />
            </div>
            <div className="flex flex-wrap items-center gap-4">
              <label className="flex items-center gap-2 text-sm">
                <span className="text-charcoal/60">Voice</span>
                <select
                  value={edit.color}
                  onChange={(e) => setEdit({ ...edit, color: e.target.value as Voice | "" })}
                  className={selectClass}
                >
                  <option value="">None</option>
                  {VOICES.map((v) => (
                    <option key={v} value={v}>
                      {v}
                    </option>
                  ))}
                </select>
              </label>
              <label className="flex items-center gap-2 text-sm">
                <span className="text-charcoal/60">Parent</span>
                <select
                  value={edit.parent_id}
                  onChange={(e) => setEdit({ ...edit, parent_id: e.target.value })}
                  className={selectClass}
                >
                  <option value="">— Top level —</option>
                  {topLevel
                    .filter((t) => t.id !== c.id)
                    .map((t) => (
                      <option key={t.id} value={t.id}>
                        {t.name}
                      </option>
                    ))}
                </select>
              </label>
              <label className="flex items-center gap-2 text-sm text-charcoal/60">
                <input
                  type="checkbox"
                  checked={edit.show_in_nav}
                  onChange={(e) => setEdit({ ...edit, show_in_nav: e.target.checked })}
                />
                Show in nav
              </label>
            </div>
            <div className="flex items-center gap-3">
              <Button size="sm" onClick={() => handleUpdate(c.id)}>
                Save
              </Button>
              <button
                onClick={() => {
                  setEditingId(null);
                  setEdit(null);
                }}
                className="text-sm text-charcoal/40 hover:text-charcoal"
              >
                Cancel
              </button>
            </div>
          </div>
        ) : (
          <div className="flex items-center gap-3 px-4 py-3">
            <ColorDot color={c.color} />
            <span className="font-bold text-charcoal">{c.name}</span>
            <span className="text-xs text-charcoal/30">{c.slug}</span>
            {c.show_in_nav && (
              <span className="border border-charcoal/15 px-1.5 py-0.5 text-[10px] font-extrabold uppercase tracking-[0.08em] text-charcoal/50">
                Nav
              </span>
            )}
            <div className="ml-auto flex items-center gap-3">
              <button
                onClick={() => startEdit(c)}
                className="text-sm text-charcoal/50 hover:text-charcoal"
              >
                Edit
              </button>
              <button
                onClick={() => handleDelete(c.id)}
                className="text-sm text-kpfk-red/60 hover:text-kpfk-red"
              >
                Delete
              </button>
            </div>
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Create */}
      <form
        onSubmit={handleCreate}
        className="flex flex-wrap items-end gap-3 border border-charcoal/10 p-4"
      >
        <div className="min-w-[12rem] flex-1">
          <Label>New category</Label>
          <Input
            value={draft.name}
            onChange={(e) => setDraft({ ...draft, name: e.target.value })}
            placeholder="e.g. Elections"
          />
        </div>
        <label className="flex flex-col gap-1 text-sm">
          <span className="text-xs font-extrabold uppercase tracking-[0.14em] text-charcoal/60">
            Parent
          </span>
          <select
            value={draft.parent_id}
            onChange={(e) => setDraft({ ...draft, parent_id: e.target.value })}
            className={selectClass}
          >
            <option value="">— Top level —</option>
            {topLevel.map((t) => (
              <option key={t.id} value={t.id}>
                {t.name}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 text-sm">
          <span className="text-xs font-extrabold uppercase tracking-[0.14em] text-charcoal/60">
            Voice
          </span>
          <select
            value={draft.color}
            onChange={(e) => setDraft({ ...draft, color: e.target.value as Voice | "" })}
            className={selectClass}
          >
            <option value="">None</option>
            {VOICES.map((v) => (
              <option key={v} value={v}>
                {v}
              </option>
            ))}
          </select>
        </label>
        <Button type="submit" disabled={saving || !draft.name.trim()}>
          Add
        </Button>
      </form>

      {/* Tree */}
      <div className="space-y-2">
        {topLevel.length === 0 && (
          <p className="py-6 text-sm text-charcoal/40">No coverage areas yet.</p>
        )}
        {topLevel.map((parent) => (
          <div key={parent.id} className="space-y-2">
            <Row c={parent} depth={0} />
            {childrenOf(parent.id).map((child) => (
              <Row key={child.id} c={child} depth={1} />
            ))}
          </div>
        ))}
      </div>
    </div>
  );
}
