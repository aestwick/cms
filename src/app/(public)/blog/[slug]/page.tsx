import { notFound } from "next/navigation";
import Image from "next/image";
import Link from "next/link";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

const SUPABASE_STORAGE_URL =
  "https://czjhwhfqohpmwprhasve.supabase.co/storage/v1/object/public";

function resolveImageUrl(path: string): string {
  if (path.startsWith("http://") || path.startsWith("https://")) return path;
  return `${SUPABASE_STORAGE_URL}/${path}`;
}

interface PageProps {
  params: Promise<{ slug: string }>;
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const supabase = getSupabaseAdmin();

  const { data: post } = await supabase
    .from("cms_posts")
    .select("title, excerpt, body")
    .eq("slug", slug)
    .eq("status", "published")
    .is("deleted_at", null)
    .single();

  if (!post) return { title: "Post Not Found — KPFK 90.7 FM" };

  const description = post.excerpt || post.body.replace(/<[^>]*>/g, "").slice(0, 160);

  return {
    title: `${post.title} — KPFK 90.7 FM`,
    description,
  };
}

export default async function BlogPostPage({ params }: PageProps) {
  const { slug } = await params;
  const supabase = getSupabaseAdmin();

  const { data: post } = await supabase
    .from("cms_posts")
    .select("*, cms_shows(id, title, slug)")
    .eq("slug", slug)
    .eq("status", "published")
    .is("deleted_at", null)
    .single();

  if (!post) notFound();

  // Normalize Supabase join (may return array)
  const showData = Array.isArray(post.cms_shows)
    ? (post.cms_shows[0] as { id: string; title: string; slug: string } | undefined) ?? null
    : (post.cms_shows as { id: string; title: string; slug: string } | null);

  const publishedDate = post.published_at
    ? new Date(post.published_at).toLocaleDateString("en-US", {
        weekday: "long",
        month: "long",
        day: "numeric",
        year: "numeric",
      })
    : null;

  // Fetch author name
  const { data: author } = await supabase
    .from("cms_profiles")
    .select("display_name, email")
    .eq("id", post.author_id)
    .single();

  const authorName = author?.display_name || author?.email || "KPFK Staff";

  return (
    <article className="mx-auto max-w-3xl px-6 py-12 sm:px-8">
      {/* Breadcrumb */}
      <nav className="mb-8 text-sm text-charcoal/40">
        <Link href="/blog" className="hover:text-charcoal">
          Blog
        </Link>
        <span className="mx-2">/</span>
        <span className="text-charcoal/60">{post.title}</span>
      </nav>

      {/* Header */}
      <header className="masthead" style={{ marginBottom: "2rem" }}>
        {showData && (
          <Link
            href={`/on-air/${showData.slug}`}
            className="inline-block text-sm font-medium text-kpfk-red hover:underline"
          >
            {showData.title}
          </Link>
        )}
        <h1 className="mt-2 font-serif text-4xl font-bold leading-tight text-charcoal">
          {post.title}
        </h1>
        <div className="mt-4 flex flex-wrap items-center gap-3 text-sm text-charcoal/50">
          <span>{authorName}</span>
          {publishedDate && (
            <>
              <span>·</span>
              <time className="font-mono text-xs">{publishedDate}</time>
            </>
          )}
        </div>
      </header>

      {/* Featured image */}
      {post.featured_image_path && (
        <div className="relative mt-8 aspect-[2/1] w-full overflow-hidden border border-charcoal/10">
          <Image
            src={resolveImageUrl(post.featured_image_path)}
            alt={post.title}
            fill
            className="object-cover"
            sizes="(max-width: 768px) 100vw, 768px"
            priority
          />
        </div>
      )}

      {/* Body */}
      <div
        className="prose mt-10 max-w-none text-base leading-relaxed text-charcoal/80"
        dangerouslySetInnerHTML={{ __html: post.body }}
      />

      {/* Footer */}
      <footer className="mt-12 border-t border-charcoal/10 pt-8">
        <Link
          href="/blog"
          className="text-sm font-medium text-kpfk-red hover:underline"
        >
          &larr; Back to all posts
        </Link>
      </footer>
    </article>
  );
}
