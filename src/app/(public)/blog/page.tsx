import { getSupabaseAdmin } from "@/lib/supabase/admin";
import Link from "next/link";
import Image from "next/image";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

const SUPABASE_STORAGE_URL =
  "https://czjhwhfqohpmwprhasve.supabase.co/storage/v1/object/public";

function resolveImageUrl(path: string): string {
  if (path.startsWith("http://") || path.startsWith("https://")) return path;
  return `${SUPABASE_STORAGE_URL}/${path}`;
}

export const metadata: Metadata = {
  title: "Blog — KPFK 90.7 FM",
  description: "News, updates, and stories from KPFK 90.7 FM, Pacifica Radio in Los Angeles.",
};

interface Post {
  id: string;
  title: string;
  slug: string;
  excerpt: string | null;
  body: string;
  featured_image_path: string | null;
  published_at: string;
  is_featured: boolean;
  cms_shows: { title: string; slug: string } | null;
}

function getExcerpt(post: Post): string {
  if (post.excerpt) return post.excerpt;
  // Strip HTML and truncate
  const text = post.body.replace(/<[^>]*>/g, "");
  return text.length > 200 ? text.slice(0, 200) + "…" : text;
}

function formatDate(d: string) {
  return new Date(d).toLocaleDateString("en-US", {
    month: "long",
    day: "numeric",
    year: "numeric",
  });
}

export default async function BlogIndexPage() {
  const supabase = getSupabaseAdmin();

  const { data: posts } = await supabase
    .from("cms_posts")
    .select("id, title, slug, excerpt, body, featured_image_path, published_at, is_featured, cms_shows(title, slug)")
    .eq("status", "published")
    .is("deleted_at", null)
    .order("is_featured", { ascending: false })
    .order("published_at", { ascending: false });

  const allPosts = (posts ?? []).map((p) => ({
    ...p,
    cms_shows: Array.isArray(p.cms_shows) ? p.cms_shows[0] || null : p.cms_shows,
  })) as Post[];

  return (
    <div className="mx-auto max-w-5xl px-6 py-12 sm:px-8">
      <header className="pb-6" style={{ borderBottom: "3px solid var(--txt)" }}>
        <p className="kpfk-label">Dispatches from the station</p>
        <h1 className="kpfk-display mt-2 text-5xl sm:text-6xl" style={{ color: "var(--txt)" }}>
          Stories<span style={{ color: "var(--kpfk-red)" }}>.</span>
        </h1>
        <p className="mt-3 text-lg" style={{ color: "var(--muted)" }}>
          News, updates, and stories from KPFK 90.7 FM.
        </p>
      </header>

      {allPosts.length === 0 ? (
        <p className="py-16 text-center text-charcoal/40">
          No posts yet. Check back soon.
        </p>
      ) : (
        <div className="mt-8 space-y-0 divide-y divide-charcoal/10">
          {allPosts.map((post) => (
            <article key={post.id} className="py-8 first:pt-0">
              <div className="flex flex-col gap-5 sm:flex-row sm:gap-8">
                {post.featured_image_path && (
                  <Link
                    href={`/blog/${post.slug}`}
                    className="relative block h-48 w-full flex-shrink-0 overflow-hidden border border-charcoal/10 sm:h-32 sm:w-48"
                  >
                    <Image
                      src={resolveImageUrl(post.featured_image_path)}
                      alt={post.title}
                      fill
                      className="object-cover"
                      sizes="(min-width: 640px) 192px, 100vw"
                    />
                  </Link>
                )}
                <div className="flex-1">
                  <div className="flex flex-wrap items-center gap-3 text-xs text-charcoal/40">
                    <time className="font-mono">{formatDate(post.published_at)}</time>
                    {post.cms_shows && (
                      <>
                        <span>·</span>
                        <Link
                          href={`/on-air/${post.cms_shows.slug}`}
                          className="text-kpfk-red hover:underline"
                        >
                          {post.cms_shows.title}
                        </Link>
                      </>
                    )}
                    {post.is_featured && (
                      <span className="rounded border border-action-yellow/40 bg-action-yellow/10 px-1.5 py-0.5 font-mono text-[10px] uppercase">
                        Featured
                      </span>
                    )}
                  </div>
                  <h2 className="mt-2 font-serif text-2xl font-bold leading-tight text-charcoal">
                    <Link href={`/blog/${post.slug}`} className="hover:text-kpfk-red">
                      {post.title}
                    </Link>
                  </h2>
                  <p className="mt-2 text-base leading-relaxed text-charcoal/60">
                    {getExcerpt(post)}
                  </p>
                  <Link
                    href={`/blog/${post.slug}`}
                    className="mt-3 inline-block text-sm font-medium text-kpfk-red hover:underline"
                  >
                    Read more
                  </Link>
                </div>
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}
