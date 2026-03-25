import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import Link from "next/link";

export default async function BlogListPage() {
  const user = await requireRole("admin", "editor");
  const supabase = getSupabaseAdmin();

  const { data: posts } = await supabase
    .from("cms_posts")
    .select("id, title, slug, status, published_at, is_featured, show_id, author_id, created_at, cms_shows(title)")
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .order("created_at", { ascending: false });

  function formatDate(d: string | null) {
    if (!d) return "—";
    return new Date(d).toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  }

  return (
    <div>
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-charcoal">Blog Posts</h1>
          <p className="mt-1 text-sm text-charcoal/50">
            {posts?.length ?? 0} posts
          </p>
        </div>
        <Link
          href="/admin/blog/new"
          className="border-2 border-charcoal bg-charcoal px-4 py-2 text-sm font-medium text-off-white hover:bg-charcoal/90"
        >
          New post
        </Link>
      </div>

      <div className="mt-6 border border-charcoal/20">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-charcoal/10 bg-charcoal/5 text-left">
              <th className="px-4 py-2 font-medium text-charcoal/60">Title</th>
              <th className="px-4 py-2 font-medium text-charcoal/60">Show</th>
              <th className="px-4 py-2 font-medium text-charcoal/60">Status</th>
              <th className="px-4 py-2 font-medium text-charcoal/60">Date</th>
              <th className="px-4 py-2 font-medium text-charcoal/60" />
            </tr>
          </thead>
          <tbody>
            {posts?.map((post) => (
              <tr
                key={post.id}
                className="border-b border-charcoal/5 hover:bg-charcoal/[0.02]"
              >
                <td className="px-4 py-2">
                  <span className="font-medium text-charcoal">{post.title}</span>
                  {post.is_featured && (
                    <span className="ml-2 rounded border border-action-yellow/40 bg-action-yellow/10 px-1.5 py-0.5 font-mono text-[10px] uppercase text-charcoal/60">
                      Featured
                    </span>
                  )}
                </td>
                <td className="px-4 py-2 text-xs text-charcoal/50">
                  {Array.isArray(post.cms_shows) ? (post.cms_shows[0] as { title: string } | undefined)?.title || "—" : (post.cms_shows as { title: string } | null)?.title || "—"}
                </td>
                <td className="px-4 py-2">
                  <span
                    className={`inline-block h-2 w-2 rounded-full ${
                      post.status === "published" ? "bg-green-600" : "bg-charcoal/20"
                    }`}
                  />
                  <span className="ml-1.5 text-xs text-charcoal/50">
                    {post.status === "published" ? "Published" : "Draft"}
                  </span>
                </td>
                <td className="px-4 py-2 font-mono text-xs text-charcoal/40">
                  {formatDate(post.published_at || post.created_at)}
                </td>
                <td className="px-4 py-2 text-right">
                  <Link
                    href={`/admin/blog/${post.id}/edit`}
                    className="text-xs text-kpfk-red hover:underline"
                  >
                    Edit
                  </Link>
                </td>
              </tr>
            ))}
            {(!posts || posts.length === 0) && (
              <tr>
                <td
                  colSpan={5}
                  className="px-4 py-8 text-center text-sm text-charcoal/40"
                >
                  No posts yet.{" "}
                  <Link
                    href="/admin/blog/new"
                    className="text-kpfk-red hover:underline"
                  >
                    Create one
                  </Link>
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
