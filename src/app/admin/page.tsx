import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import Link from "next/link";

export const dynamic = "force-dynamic";

export default async function AdminDashboard() {
  const user = await requireRole("admin", "editor", "host");
  const supabase = getSupabaseAdmin();

  // Fetch counts in parallel
  const [showsResult, postsResult, eventsResult, slotsResult] =
    await Promise.all([
      supabase
        .from("cms_shows")
        .select("id", { count: "exact", head: true })
        .is("deleted_at", null),
      supabase
        .from("cms_posts")
        .select("id", { count: "exact", head: true })
        .is("deleted_at", null),
      supabase
        .from("cms_events")
        .select("id", { count: "exact", head: true })
        .is("deleted_at", null),
      supabase
        .from("cms_schedule_slots")
        .select("id", { count: "exact", head: true }),
    ]);

  // Fetch recent posts
  const { data: recentPosts } = await supabase
    .from("cms_posts")
    .select("id, title, slug, published_at, status")
    .is("deleted_at", null)
    .order("created_at", { ascending: false })
    .limit(5);

  // Fetch upcoming events
  const { data: upcomingEvents } = await supabase
    .from("cms_events")
    .select("id, title, slug, starts_at, category")
    .is("deleted_at", null)
    .gte("starts_at", new Date().toISOString())
    .order("starts_at", { ascending: true })
    .limit(3);

  const showCount = showsResult.count ?? 0;
  const postCount = postsResult.count ?? 0;
  const eventCount = eventsResult.count ?? 0;
  const slotCount = slotsResult.count ?? 0;

  const isAdminOrEditor = user.role === "admin" || user.role === "editor";

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-extrabold text-charcoal">
          Dashboard
        </h1>
        <p className="mt-1 text-sm text-charcoal/60">
          Welcome back, {user.display_name || user.email}.
        </p>
      </div>

      {/* Stats Cards */}
      {isAdminOrEditor && (
        <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
          <StatCard label="Shows" count={showCount} href="/admin/shows" />
          <StatCard label="Blog Posts" count={postCount} href="/admin/blog" />
          <StatCard label="Events" count={eventCount} href="/admin/events" />
          <StatCard
            label="Schedule Slots"
            count={slotCount}
            href="/admin/schedule"
          />
        </div>
      )}

      <div className="grid gap-8 lg:grid-cols-3">
        {/* Recent Activity */}
        <div className="lg:col-span-2">
          <h2 className="text-xl font-extrabold text-charcoal">
            Recent Posts
          </h2>
          <div className="mt-4 divide-y divide-charcoal/10 border border-charcoal/20 bg-white">
            {recentPosts && recentPosts.length > 0 ? (
              recentPosts.map((post) => (
                <Link
                  key={post.id}
                  href={`/admin/blog/${post.id}/edit`}
                  className="flex items-center justify-between px-5 py-4 transition-colors hover:bg-off-white"
                >
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-medium text-charcoal">
                      {post.title}
                    </p>
                    <p className="mt-0.5 text-xs text-charcoal/50">
                      {post.published_at
                        ? new Date(post.published_at).toLocaleDateString(
                            "en-US",
                            {
                              year: "numeric",
                              month: "short",
                              day: "numeric",
                            }
                          )
                        : "Not published"}
                    </p>
                  </div>
                  <StatusBadge status={post.status} />
                </Link>
              ))
            ) : (
              <p className="px-5 py-8 text-center text-sm text-charcoal/40">
                No posts yet.
              </p>
            )}
          </div>
        </div>

        {/* Sidebar: Upcoming Events + Quick Actions */}
        <div className="space-y-8">
          {/* Upcoming Events */}
          <div>
            <h2 className="text-xl font-extrabold text-charcoal">
              Upcoming Events
            </h2>
            <div className="mt-4 space-y-3">
              {upcomingEvents && upcomingEvents.length > 0 ? (
                upcomingEvents.map((event) => (
                  <Link
                    key={event.id}
                    href={`/admin/events/${event.id}/edit`}
                    className="block border border-charcoal/20 bg-white p-4 transition-colors hover:bg-off-white"
                  >
                    <p className="font-medium text-charcoal">{event.title}</p>
                    <div className="mt-1 flex items-center gap-2">
                      <span className="text-xs text-charcoal/50">
                        {new Date(event.starts_at).toLocaleDateString("en-US", {
                          month: "short",
                          day: "numeric",
                          year: "numeric",
                        })}
                      </span>
                      {event.category && (
                        <span className="rounded bg-charcoal/5 px-1.5 py-0.5 text-xs text-charcoal/60">
                          {event.category}
                        </span>
                      )}
                    </div>
                  </Link>
                ))
              ) : (
                <div className="border border-charcoal/20 bg-white px-4 py-8 text-center text-sm text-charcoal/40">
                  No upcoming events.
                </div>
              )}
            </div>
          </div>

          {/* Quick Actions */}
          {isAdminOrEditor && (
            <div>
              <h2 className="text-xl font-extrabold text-charcoal">
                Quick Actions
              </h2>
              <div className="mt-4 flex flex-col gap-3">
                <QuickActionLink href="/admin/blog/new" label="New Post" />
                <QuickActionLink href="/admin/events/new" label="New Event" />
                {user.role === "admin" && (
                  <QuickActionLink href="/admin/shows/new" label="New Show" />
                )}
              </div>
            </div>
          )}

          {/* Host-specific quick actions */}
          {user.role === "host" && (
            <div>
              <h2 className="text-xl font-extrabold text-charcoal">
                Quick Actions
              </h2>
              <div className="mt-4 flex flex-col gap-3">
                <QuickActionLink href="/admin/blog/new" label="New Post" />
                <QuickActionLink href="/admin/shows" label="My Shows" />
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

/* -------------------------------------------------------------------------- */
/*  Sub-components                                                             */
/* -------------------------------------------------------------------------- */

function StatCard({
  label,
  count,
  href,
}: {
  label: string;
  count: number;
  href: string;
}) {
  return (
    <Link
      href={href}
      className="border border-charcoal/20 bg-white p-6 transition-colors hover:border-kpfk-red/40"
    >
      <p className="text-4xl font-extrabold text-charcoal">{count}</p>
      <p className="mt-1 text-sm text-charcoal/60">{label}</p>
    </Link>
  );
}

function StatusBadge({ status }: { status: string }) {
  const styles: Record<string, string> = {
    published: "bg-green-100 text-green-800",
    draft: "bg-charcoal/10 text-charcoal/60",
    archived: "bg-amber-100 text-amber-800",
  };

  return (
    <span
      className={`ml-3 shrink-0 px-2 py-0.5 text-[10px] font-extrabold uppercase tracking-[0.08em] ${
        styles[status] ?? styles.draft
      }`}
    >
      {status}
    </span>
  );
}

function QuickActionLink({ href, label }: { href: string; label: string }) {
  return (
    <Link
      href={href}
      className="border border-charcoal/20 bg-white px-4 py-3 text-center text-sm font-medium text-charcoal transition-colors hover:border-kpfk-red hover:text-kpfk-red"
    >
      {label}
    </Link>
  );
}
