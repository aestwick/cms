import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Newsletter — KPFK CMS",
};

export default async function NewsletterPage() {
  const user = await requireRole("admin", "editor");
  const supabase = getSupabaseAdmin();

  // Fetch all active subscribers
  const { data: subscribers } = await supabase
    .from("cms_newsletter_subscribers")
    .select("id, email, created_at, confirmed_at, source")
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .is("unsubscribed_at", null)
    .order("created_at", { ascending: false });

  const all = subscribers ?? [];
  const confirmed = all.filter((s) => s.confirmed_at);
  const unconfirmed = all.filter((s) => !s.confirmed_at);

  return (
    <div>
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-charcoal">Newsletter</h1>
          <p className="mt-1 text-sm text-charcoal/50">
            {all.length} subscriber{all.length !== 1 ? "s" : ""}
          </p>
        </div>
        <button
          disabled
          className="border-2 border-charcoal/20 px-4 py-2 text-sm font-medium text-charcoal/40 cursor-not-allowed"
          title="Export coming soon"
        >
          Export CSV
        </button>
      </div>

      {/* Stats cards */}
      <div className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-3">
        <div className="border border-charcoal/20 px-4 py-4">
          <p className="font-mono text-xs uppercase tracking-wider text-charcoal/40">
            Total
          </p>
          <p className="mt-1 text-2xl font-bold text-charcoal">{all.length}</p>
        </div>
        <div className="border border-charcoal/20 px-4 py-4">
          <p className="font-mono text-xs uppercase tracking-wider text-charcoal/40">
            Confirmed
          </p>
          <p className="mt-1 text-2xl font-bold text-charcoal">
            {confirmed.length}
          </p>
        </div>
        <div className="border border-charcoal/20 px-4 py-4">
          <p className="font-mono text-xs uppercase tracking-wider text-charcoal/40">
            Unconfirmed
          </p>
          <p className="mt-1 text-2xl font-bold text-charcoal">
            {unconfirmed.length}
          </p>
        </div>
      </div>

      {/* Subscriber table */}
      {all.length > 0 ? (
        <div className="mt-8 overflow-x-auto border border-charcoal/20">
          <table className="w-full min-w-[500px] text-sm">
            <thead>
              <tr className="border-b border-charcoal/10 bg-charcoal/5 text-left">
                <th className="px-4 py-2 font-medium text-charcoal/60">
                  Email
                </th>
                <th className="px-4 py-2 font-medium text-charcoal/60">
                  Subscribed
                </th>
                <th className="px-4 py-2 font-medium text-charcoal/60">
                  Status
                </th>
                <th className="px-4 py-2 font-medium text-charcoal/60">
                  Source
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-charcoal/10">
              {all.map((sub) => (
                <tr
                  key={sub.id}
                  className="hover:bg-charcoal/[0.02]"
                >
                  <td className="px-4 py-2 font-medium text-charcoal">
                    {sub.email}
                  </td>
                  <td className="px-4 py-2 font-mono text-xs text-charcoal/50">
                    {new Date(sub.created_at).toLocaleDateString("en-US", {
                      year: "numeric",
                      month: "short",
                      day: "numeric",
                    })}
                  </td>
                  <td className="px-4 py-2">
                    {sub.confirmed_at ? (
                      <span className=" border border-green-600/20 bg-green-600/5 px-1.5 py-0.5 font-mono text-[10px] uppercase text-green-700">
                        Confirmed
                      </span>
                    ) : (
                      <span className=" border border-amber-500/20 bg-amber-500/5 px-1.5 py-0.5 font-mono text-[10px] uppercase text-amber-600">
                        Pending
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-2 font-mono text-xs text-charcoal/50">
                    {sub.source}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="mt-6 border border-charcoal/20 px-4 py-8 text-center text-sm text-charcoal/40">
          No subscribers yet.
        </div>
      )}
    </div>
  );
}
