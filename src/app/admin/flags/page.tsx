import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { FlagActions } from "@/components/flag-actions";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: "Flags — KPFK CMS" };

interface Flag {
  id: string;
  station_id: string;
  reporter_id: string | null;
  url: string;
  message: string;
  user_agent: string | null;
  status: string;
  resolved_by: string | null;
  resolved_at: string | null;
  created_at: string;
  reporter: { email: string; display_name: string | null } | null;
}

export default async function FlagsPage() {
  const user = await requireRole("admin");
  const supabase = getSupabaseAdmin();

  const { data: flags } = await supabase
    .from("cms_flags")
    .select(
      "id, station_id, reporter_id, url, message, user_agent, status, resolved_by, resolved_at, created_at, reporter:cms_profiles!reporter_id(email, display_name)"
    )
    .eq("station_id", user.station_id)
    .order("created_at", { ascending: false });

  const allFlags = (flags ?? []) as unknown as Flag[];

  const openFlags = allFlags.filter((f) => f.status === "open");
  const resolvedFlags = allFlags.filter((f) => f.status === "resolved");
  const dismissedFlags = allFlags.filter((f) => f.status === "dismissed");

  return (
    <div>
      <div>
        <h1 className="text-2xl font-bold text-charcoal">Flags</h1>
        <p className="mt-1 text-sm text-charcoal/50">
          Bug reports and content flags from users
        </p>
      </div>

      {/* Status counts */}
      <div className="mt-6 grid grid-cols-3 gap-4">
        <div className="border border-charcoal/20 px-4 py-3">
          <p className="text-2xl font-bold text-kpfk-red">{openFlags.length}</p>
          <p className="text-xs font-medium uppercase tracking-wider text-charcoal/40">
            Open
          </p>
        </div>
        <div className="border border-charcoal/20 px-4 py-3">
          <p className="text-2xl font-bold text-green-700">{resolvedFlags.length}</p>
          <p className="text-xs font-medium uppercase tracking-wider text-charcoal/40">
            Resolved
          </p>
        </div>
        <div className="border border-charcoal/20 px-4 py-3">
          <p className="text-2xl font-bold text-charcoal/40">{dismissedFlags.length}</p>
          <p className="text-xs font-medium uppercase tracking-wider text-charcoal/40">
            Dismissed
          </p>
        </div>
      </div>

      {/* Open flags */}
      {openFlags.length > 0 && (
        <FlagSection title="Open" flags={openFlags} />
      )}

      {/* Resolved flags */}
      {resolvedFlags.length > 0 && (
        <FlagSection title="Resolved" flags={resolvedFlags} />
      )}

      {/* Dismissed flags */}
      {dismissedFlags.length > 0 && (
        <FlagSection title="Dismissed" flags={dismissedFlags} />
      )}

      {allFlags.length === 0 && (
        <div className="mt-6 border border-charcoal/20 px-4 py-8 text-center text-sm text-charcoal/40">
          No flags yet.
        </div>
      )}
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const styles: Record<string, string> = {
    open: "bg-kpfk-red text-off-white",
    resolved: "bg-green-700 text-white",
    dismissed: "bg-charcoal/10 text-charcoal/60",
  };

  return (
    <span
      className={`inline-block rounded px-1.5 py-0.5 font-mono text-[10px] uppercase ${styles[status] ?? styles.dismissed}`}
    >
      {status}
    </span>
  );
}

function FlagSection({ title, flags }: { title: string; flags: Flag[] }) {
  return (
    <div className="mt-8">
      <h2 className="mb-3 text-sm font-bold uppercase tracking-wider text-charcoal/40">
        {title}
      </h2>
      <div className="space-y-3">
        {flags.map((flag) => (
          <div
            key={flag.id}
            className="border border-charcoal/20 px-4 py-3"
          >
            <div className="flex items-start justify-between gap-4">
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <StatusBadge status={flag.status} />
                  <span
                    className="truncate font-mono text-xs text-charcoal/60"
                    title={flag.url}
                  >
                    {flag.url}
                  </span>
                </div>
                <p className="mt-1.5 text-sm text-charcoal">{flag.message}</p>
                <div className="mt-2 flex items-center gap-3 text-xs text-charcoal/40">
                  <span>
                    {flag.reporter?.email ?? "Anonymous"}
                  </span>
                  <span className="font-mono">
                    {new Date(flag.created_at).toLocaleDateString("en-US", {
                      month: "short",
                      day: "numeric",
                      year: "numeric",
                    })}
                  </span>
                </div>
              </div>
              <div className="flex-shrink-0 pt-0.5">
                <FlagActions flagId={flag.id} status={flag.status} />
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
