"use client";

import { useEffect, useState, useCallback } from "react";
import type {
  ScheduleSnapshotSummary,
  SnapshotOperation,
} from "@/lib/schedule-snapshots";

interface Props {
  open: boolean;
  onClose: () => void;
  onReverted: () => void;
  canRevert: boolean;
}

const OPERATION_LABELS: Record<SnapshotOperation, string> = {
  confessor_import: "Confessor import",
  bulk_revert: "Revert",
  manual_save: "Manual save",
  pre_revert: "Auto-saved (pre-revert)",
};

const OPERATION_COLORS: Record<SnapshotOperation, string> = {
  confessor_import: "bg-blue-100 text-blue-800",
  bulk_revert: "bg-amber-100 text-amber-800",
  manual_save: "bg-charcoal/10 text-charcoal",
  pre_revert: "bg-amber-50 text-amber-700",
};

function formatTimestamp(iso: string): string {
  const d = new Date(iso);
  const now = new Date();
  const sameDay =
    d.getFullYear() === now.getFullYear() &&
    d.getMonth() === now.getMonth() &&
    d.getDate() === now.getDate();
  const time = d.toLocaleTimeString(undefined, {
    hour: "numeric",
    minute: "2-digit",
  });
  if (sameDay) return `Today ${time}`;
  const date = d.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
  });
  return `${date} ${time}`;
}

export function ScheduleHistoryDrawer({
  open,
  onClose,
  onReverted,
  canRevert,
}: Props) {
  const [snapshots, setSnapshots] = useState<ScheduleSnapshotSummary[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [confirmingId, setConfirmingId] = useState<string | null>(null);
  const [reverting, setReverting] = useState(false);
  const [saving, setSaving] = useState(false);

  const fetchSnapshots = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const res = await fetch("/api/schedule/snapshots");
      if (!res.ok) {
        const body = await res.json().catch(() => null);
        throw new Error(body?.error || `Load failed (${res.status})`);
      }
      const data = await res.json();
      setSnapshots(data.snapshots || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load history");
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    if (open) {
      fetchSnapshots();
      setConfirmingId(null);
    }
  }, [open, fetchSnapshots]);

  // Close on Escape.
  useEffect(() => {
    if (!open) return;
    function handleKey(e: KeyboardEvent) {
      if (e.key === "Escape") {
        if (confirmingId) {
          setConfirmingId(null);
        } else {
          onClose();
        }
      }
    }
    document.addEventListener("keydown", handleKey);
    return () => document.removeEventListener("keydown", handleKey);
  }, [open, onClose, confirmingId]);

  async function handleManualSave() {
    setSaving(true);
    setError("");
    try {
      const res = await fetch("/api/schedule/snapshots", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({}),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => null);
        throw new Error(body?.error || `Save failed (${res.status})`);
      }
      await fetchSnapshots();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save snapshot");
    }
    setSaving(false);
  }

  async function handleRevert(id: string) {
    setReverting(true);
    setError("");
    try {
      const res = await fetch(`/api/schedule/snapshots/${id}/revert`, {
        method: "POST",
      });
      if (!res.ok) {
        const body = await res.json().catch(() => null);
        throw new Error(body?.error || `Revert failed (${res.status})`);
      }
      setConfirmingId(null);
      onReverted();
      await fetchSnapshots();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Revert failed");
    }
    setReverting(false);
  }

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-40 flex">
      <button
        type="button"
        aria-label="Close history"
        onClick={onClose}
        className="flex-1 bg-charcoal/30"
      />
      <aside className="flex w-full max-w-md flex-col border-l border-charcoal/10 bg-white shadow-xl">
        <header className="flex items-center justify-between border-b border-charcoal/10 px-5 py-3">
          <div>
            <h3 className="text-base font-bold text-charcoal">
              Schedule history
            </h3>
            <p className="text-xs text-charcoal/50">
              Snapshots of the schedule grid. Revert restores everything.
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="text-2xl text-charcoal/40 hover:text-charcoal"
            aria-label="Close"
          >
            &times;
          </button>
        </header>

        <div className="flex items-center gap-2 border-b border-charcoal/10 px-5 py-2">
          <button
            type="button"
            onClick={handleManualSave}
            disabled={saving}
            className="text-xs font-medium text-charcoal underline hover:text-charcoal/70 disabled:opacity-50"
          >
            {saving ? "Saving..." : "Save current state"}
          </button>
          <span className="text-xs text-charcoal/30">·</span>
          <button
            type="button"
            onClick={fetchSnapshots}
            disabled={loading}
            className="text-xs font-medium text-charcoal/60 underline hover:text-charcoal disabled:opacity-50"
          >
            Refresh
          </button>
        </div>

        <div className="flex-1 overflow-y-auto">
          {error && (
            <div className="border-b border-kpfk-red/20 bg-kpfk-red/5 px-5 py-3 text-sm text-kpfk-red">
              {error}
            </div>
          )}
          {loading ? (
            <p className="px-5 py-8 text-center text-sm text-charcoal/40">
              Loading history...
            </p>
          ) : snapshots.length === 0 ? (
            <p className="px-5 py-8 text-center text-sm text-charcoal/40">
              No snapshots yet. One will be saved automatically before the next
              Confessor import.
            </p>
          ) : (
            <ul>
              {snapshots.map((snap) => {
                const isConfirming = confirmingId === snap.id;
                return (
                  <li
                    key={snap.id}
                    className={`border-b border-charcoal/5 px-5 py-3 transition-colors ${
                      isConfirming ? "bg-amber-50" : "hover:bg-charcoal/5"
                    }`}
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div className="min-w-0 flex-1">
                        <span
                          className={`inline-block rounded-sm px-1.5 py-0.5 text-[10px] font-medium uppercase tracking-wide ${
                            OPERATION_COLORS[snap.operation]
                          }`}
                        >
                          {OPERATION_LABELS[snap.operation]}
                        </span>
                        <p className="mt-1 text-sm text-charcoal">
                          {snap.description}
                        </p>
                        <p className="mt-0.5 text-xs text-charcoal/50">
                          {formatTimestamp(snap.created_at)} ·{" "}
                          {snap.slot_count} slot
                          {snap.slot_count === 1 ? "" : "s"}
                        </p>
                      </div>
                      {canRevert &&
                        (isConfirming ? (
                          <div className="flex flex-col gap-1">
                            <button
                              type="button"
                              onClick={() => handleRevert(snap.id)}
                              disabled={reverting}
                              className="border border-amber-600 bg-amber-600 px-3 py-1 text-xs font-medium text-white hover:bg-amber-700 disabled:opacity-50"
                            >
                              {reverting ? "Reverting..." : "Confirm revert"}
                            </button>
                            <button
                              type="button"
                              onClick={() => setConfirmingId(null)}
                              disabled={reverting}
                              className="text-xs text-charcoal/60 underline hover:text-charcoal"
                            >
                              Cancel
                            </button>
                          </div>
                        ) : (
                          <button
                            type="button"
                            onClick={() => setConfirmingId(snap.id)}
                            className="flex-shrink-0 border border-charcoal/20 bg-white px-3 py-1 text-xs font-medium text-charcoal hover:bg-charcoal/5"
                          >
                            Revert
                          </button>
                        ))}
                    </div>
                    {isConfirming && (
                      <p className="mt-2 text-xs text-amber-800">
                        This replaces the current grid with this snapshot. The
                        current state will be auto-saved first so you can undo.
                      </p>
                    )}
                  </li>
                );
              })}
            </ul>
          )}
        </div>

        {!canRevert && (
          <div className="border-t border-charcoal/10 bg-charcoal/5 px-5 py-2 text-xs text-charcoal/60">
            Only admins can revert snapshots.
          </div>
        )}
      </aside>
    </div>
  );
}
