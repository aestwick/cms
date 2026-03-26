"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

const roleStyles: Record<string, string> = {
  admin:
    "border-kpfk-red/30 bg-kpfk-red/10 text-kpfk-red",
  editor:
    "border-action-yellow/40 bg-action-yellow/10 text-charcoal",
  host:
    "border-tag-audience/40 bg-tag-audience text-charcoal",
};

export function UserRoleEditor({
  userId,
  currentRole,
}: {
  userId: string;
  currentRole: string;
}) {
  const router = useRouter();
  const [saving, setSaving] = useState(false);
  const [role, setRole] = useState(currentRole);

  async function handleChange(newRole: string) {
    if (newRole === role) return;
    setSaving(true);
    try {
      const res = await fetch(`/api/users/${userId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ role: newRole }),
      });
      if (!res.ok) {
        const data = await res.json();
        alert(data.error || "Failed to update role");
        return;
      }
      setRole(newRole);
      router.refresh();
    } finally {
      setSaving(false);
    }
  }

  return (
    <select
      value={role}
      onChange={(e) => handleChange(e.target.value)}
      disabled={saving}
      className={`rounded border px-2 py-1 font-mono text-xs uppercase ${roleStyles[role] ?? ""} cursor-pointer disabled:cursor-wait disabled:opacity-50`}
    >
      <option value="admin">admin</option>
      <option value="editor">editor</option>
      <option value="host">host</option>
    </select>
  );
}
