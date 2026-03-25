import { notFound } from "next/navigation";
import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { PostForm } from "@/components/post-form";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function EditPostPage({ params }: PageProps) {
  const { id } = await params;
  const user = await requireRole("admin", "editor", "host");
  const supabase = getSupabaseAdmin();

  const { data: post } = await supabase
    .from("cms_posts")
    .select("*")
    .eq("id", id)
    .eq("station_id", user.station_id)
    .is("deleted_at", null)
    .single();

  if (!post) notFound();

  // Hosts can only edit posts scoped to their shows
  if (user.role === "host" && post.show_id) {
    const { data: hostLink } = await supabase
      .from("cms_show_hosts")
      .select("id")
      .eq("profile_id", user.id)
      .eq("show_id", post.show_id)
      .single();

    if (!hostLink) notFound();
  } else if (user.role === "host") {
    // Hosts cannot edit station-wide posts
    notFound();
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-charcoal">Edit Post</h1>
      <p className="mt-1 font-mono text-xs text-charcoal/40">{post.slug}</p>
      <div className="mt-6">
        <PostForm
          mode="edit"
          postId={id}
          initialData={{
            title: post.title,
            slug: post.slug,
            body: post.body,
            excerpt: post.excerpt || "",
            featured_image_path: post.featured_image_path || "",
            status: post.status,
            show_id: post.show_id || "",
            is_featured: post.is_featured,
          }}
        />
      </div>
    </div>
  );
}
