import { getSupabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

export async function GET() {
  const supabase = getSupabaseAdmin();
  const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || "https://kpfk.org";

  const { data: posts } = await supabase
    .from("cms_posts")
    .select("title, slug, excerpt, body, published_at, cms_shows(title)")
    .eq("status", "published")
    .is("deleted_at", null)
    .order("published_at", { ascending: false })
    .limit(50);

  const items = (posts ?? [])
    .map((post) => {
      const description = post.excerpt || post.body.replace(/<[^>]*>/g, "").slice(0, 300);
      const shows = post.cms_shows as { title: string }[] | { title: string } | null;
      const showTitle = Array.isArray(shows) ? shows[0]?.title : shows?.title;
      const category = showTitle ? `<category>${escapeXml(showTitle)}</category>` : "";
      const pubDate = post.published_at
        ? new Date(post.published_at).toUTCString()
        : new Date().toUTCString();

      return `    <item>
      <title>${escapeXml(post.title)}</title>
      <link>${siteUrl}/blog/${post.slug}</link>
      <guid isPermaLink="true">${siteUrl}/blog/${post.slug}</guid>
      <description>${escapeXml(description)}</description>
      <pubDate>${pubDate}</pubDate>
      ${category}
    </item>`;
    })
    .join("\n");

  const rss = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>KPFK 90.7 FM Blog</title>
    <link>${siteUrl}/blog</link>
    <description>News, updates, and stories from KPFK 90.7 FM, Pacifica Radio in Los Angeles.</description>
    <language>en-us</language>
    <atom:link href="${siteUrl}/feed" rel="self" type="application/rss+xml"/>
${items}
  </channel>
</rss>`;

  return new Response(rss, {
    headers: {
      "Content-Type": "application/rss+xml; charset=utf-8",
      "Cache-Control": "public, max-age=3600, s-maxage=3600",
    },
  });
}

function escapeXml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}
