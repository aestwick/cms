import { requireRole } from "@/lib/auth";
import { PostForm } from "@/components/post-form";

export default async function NewPostPage() {
  await requireRole("admin", "editor", "host");

  return (
    <div>
      <h1 className="text-2xl font-bold text-charcoal">New Blog Post</h1>
      <div className="mt-6">
        <PostForm mode="create" />
      </div>
    </div>
  );
}
