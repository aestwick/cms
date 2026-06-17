import { notFound } from "next/navigation";
import Link from "next/link";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import type { Metadata } from "next";

export const dynamic = "force-dynamic";

interface PageProps {
  params: Promise<{ slug: string }>;
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const supabase = getSupabaseAdmin();

  const { data: page } = await supabase
    .from("cms_pages")
    .select("title, meta_title, meta_description")
    .eq("slug", slug)
    .eq("is_published", true)
    .is("deleted_at", null)
    .single();

  if (!page) return { title: "Page Not Found — KPFK 90.7 FM" };

  return {
    title: `${page.meta_title || page.title} — KPFK 90.7 FM`,
    description: page.meta_description || undefined,
  };
}

export default async function PublicPage({ params }: PageProps) {
  const { slug } = await params;
  const supabase = getSupabaseAdmin();

  const { data: page } = await supabase
    .from("cms_pages")
    .select("*")
    .eq("slug", slug)
    .eq("is_published", true)
    .is("deleted_at", null)
    .single();

  if (!page) notFound();

  // Fetch child pages if any
  const { data: childPages } = await supabase
    .from("cms_pages")
    .select("id, title, slug")
    .eq("parent_id", page.id)
    .eq("is_published", true)
    .is("deleted_at", null)
    .order("sort_order", { ascending: true })
    .order("title", { ascending: true });

  return (
    <article className="mx-auto max-w-3xl px-6 py-12 sm:px-8">
      <header className="pb-6" style={{ borderBottom: "3px solid var(--txt)" }}>
        <h1 className="text-4xl font-extrabold sm:text-5xl" style={{ color: "var(--txt)" }}>
          {page.title}
        </h1>
      </header>

      {/* Body */}
      {page.body && (
        <div
          className="prose mt-10 max-w-none text-lg leading-relaxed"
          style={{ color: "var(--txt)" }}
          dangerouslySetInnerHTML={{ __html: page.body }}
        />
      )}

      {/* Child pages */}
      {childPages && childPages.length > 0 && (
        <nav className="mt-10 border-t pt-8" style={{ borderColor: "var(--line)" }}>
          <h2 className="kpfk-label">In this section</h2>
          <ul className="mt-4 space-y-2">
            {childPages.map((child) => (
              <li key={child.id}>
                <Link
                  href={`/p/${child.slug}`}
                  className="text-base text-kpfk-red hover:underline"
                >
                  {child.title}
                </Link>
              </li>
            ))}
          </ul>
        </nav>
      )}
    </article>
  );
}
