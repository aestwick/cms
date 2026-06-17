import { getSupabaseAdmin } from "@/lib/supabase/admin";
import Link from "next/link";
import Image from "next/image";
import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { CategoryChip } from "@/components/category-chip";
import { voiceColor } from "@/lib/voices";

export const dynamic = "force-dynamic";

const SUPABASE_STORAGE_URL =
  "https://czjhwhfqohpmwprhasve.supabase.co/storage/v1/object/public";

function resolveImageUrl(path: string): string {
  if (path.startsWith("http://") || path.startsWith("https://")) return path;
  return `${SUPABASE_STORAGE_URL}/${path}`;
}

interface Category {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  color: string | null;
  parent_id: string | null;
}

interface Post {
  id: string;
  title: string;
  slug: string;
  excerpt: string | null;
  body: string;
  featured_image_path: string | null;
  published_at: string;
  cms_shows: { title: string; slug: string } | null;
  cms_categories: { name: string; slug: string; color: string | null } | null;
}

function getExcerpt(post: Post): string {
  if (post.excerpt) return post.excerpt;
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

async function loadCategory(slug: string): Promise<Category | null> {
  const supabase = getSupabaseAdmin();
  const { data } = await supabase
    .from("cms_categories")
    .select("id, name, slug, description, color, parent_id")
    .eq("slug", slug)
    .is("deleted_at", null)
    .single();
  return (data as Category) ?? null;
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const category = await loadCategory(slug);
  if (!category) return { title: "Not found — KPFK 90.7 FM" };
  return {
    title: `${category.name} — KPFK 90.7 FM`,
    description:
      category.description ??
      `Stories filed under ${category.name} from KPFK 90.7 FM.`,
  };
}

export default async function CategoryPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const supabase = getSupabaseAdmin();

  const category = await loadCategory(slug);
  if (!category) notFound();

  // Sub-categories (so a parent page includes its children's stories).
  const { data: childRows } = await supabase
    .from("cms_categories")
    .select("id, name, slug, color")
    .eq("parent_id", category.id)
    .is("deleted_at", null)
    .order("sort_order");

  const children = childRows ?? [];
  const categoryIds = [category.id, ...children.map((c) => c.id)];

  const { data: postRows } = await supabase
    .from("cms_posts")
    .select(
      "id, title, slug, excerpt, body, featured_image_path, published_at, cms_shows(title, slug), cms_categories(name, slug, color)"
    )
    .in("category_id", categoryIds)
    .eq("status", "published")
    .is("deleted_at", null)
    .order("published_at", { ascending: false });

  const posts = (postRows ?? []).map((p) => ({
    ...p,
    cms_shows: Array.isArray(p.cms_shows) ? p.cms_shows[0] || null : p.cms_shows,
    cms_categories: Array.isArray(p.cms_categories)
      ? p.cms_categories[0] || null
      : p.cms_categories,
  })) as Post[];

  const accent = voiceColor(category.color) ?? "var(--kpfk-red)";

  return (
    <div className="mx-auto max-w-5xl px-6 py-12 sm:px-8">
      <header className="pb-6" style={{ borderBottom: "3px solid var(--txt)" }}>
        <p className="kpfk-label">
          <Link href="/blog" className="hover:underline">
            Stories
          </Link>{" "}
          / Coverage
        </p>
        <h1 className="kpfk-display mt-2 text-5xl sm:text-6xl" style={{ color: "var(--txt)" }}>
          {category.name}
          <span style={{ color: accent }}>.</span>
        </h1>
        {category.description && (
          <p className="mt-3 text-lg" style={{ color: "var(--muted)" }}>
            {category.description}
          </p>
        )}
        {children.length > 0 && (
          <div className="mt-4 flex flex-wrap gap-2">
            {children.map((c) => (
              <CategoryChip
                key={c.id}
                category={{ name: c.name, slug: c.slug, color: c.color }}
              />
            ))}
          </div>
        )}
      </header>

      {posts.length === 0 ? (
        <p className="py-16 text-center text-charcoal/40">
          No stories in this coverage area yet. Check back soon.
        </p>
      ) : (
        <div className="mt-8 space-y-0 divide-y divide-charcoal/10">
          {posts.map((post) => (
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
                    {post.cms_categories && (
                      <CategoryChip category={post.cms_categories} />
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
