"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

interface FlagActionsProps {
  flagId: string;
  status: string;
}

export function FlagActions({ flagId, status }: FlagActionsProps) {
  const router = useRouter();
  const [loading, setLoading] = useState<string | null>(null);

  async function updateStatus(newStatus: "resolved" | "dismissed") {
    setLoading(newStatus);
    try {
      const res = await fetch(`/api/flags/${flagId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: newStatus }),
      });

      if (!res.ok) {
        const data = await res.json();
        alert(data.error || "Failed to update flag");
        return;
      }

      router.refresh();
    } catch {
      alert("Failed to update flag");
    } finally {
      setLoading(null);
    }
  }

  if (status === "resolved" || status === "dismissed") {
    return (
      <button
        onClick={() => updateStatus("resolved" === status ? "dismissed" : "resolved")}
        disabled={loading !== null}
        className="text-xs text-charcoal/50 hover:text-charcoal hover:underline disabled:opacity-50"
      >
        {loading ? "..." : status === "resolved" ? "Dismiss" : "Resolve"}
      </button>
    );
  }

  return (
    <div className="flex items-center gap-3">
      <button
        onClick={() => updateStatus("resolved")}
        disabled={loading !== null}
        className="text-xs font-medium text-green-700 hover:underline disabled:opacity-50"
      >
        {loading === "resolved" ? "..." : "Resolve"}
      </button>
      <button
        onClick={() => updateStatus("dismissed")}
        disabled={loading !== null}
        className="text-xs text-charcoal/50 hover:text-charcoal hover:underline disabled:opacity-50"
      >
        {loading === "dismissed" ? "..." : "Dismiss"}
      </button>
    </div>
  );
}
