import type { SupabaseClient } from "@supabase/supabase-js";
import type { CmsUser } from "@/lib/auth";

// Authorization helpers for show-scoped access.
//
// IMPORTANT: the CMS uses the service-role Supabase client for admin/API
// routes, which BYPASSES Row Level Security. That means authorization is
// enforced here, in application code — every host-writable route must call
// these helpers before reading/writing. A route that allows the `host` role
// without a scoping check would let any host touch any show.
//
// `supabase` must be a client that can read cms_show_hosts (i.e. the
// service-role admin client).

/**
 * Can this user edit the given show?
 *  - admin / editor: any show in their station.
 *  - host: only shows they are linked to via cms_show_hosts.
 *
 * A null/empty showId (e.g. a station-wide post with no show) is editable
 * only by admin/editor — never by a host.
 */
export async function canEditShow(
  supabase: SupabaseClient,
  user: CmsUser,
  showId: string | null | undefined
): Promise<boolean> {
  if (user.role === "admin" || user.role === "editor") return true;
  if (user.role !== "host" || !showId) return false;

  const { data } = await supabase
    .from("cms_show_hosts")
    .select("id")
    .eq("profile_id", user.id)
    .eq("show_id", showId)
    .maybeSingle();

  return Boolean(data);
}

/**
 * The set of show ids a user may act on, for filtering list queries.
 *  - admin / editor: null, meaning "no show restriction" (caller still
 *    scopes by station_id).
 *  - host: the explicit list of linked show ids (possibly empty).
 */
export async function editableShowIds(
  supabase: SupabaseClient,
  user: CmsUser
): Promise<string[] | null> {
  if (user.role === "admin" || user.role === "editor") return null;
  if (user.role !== "host") return [];

  const { data } = await supabase
    .from("cms_show_hosts")
    .select("show_id")
    .eq("profile_id", user.id);

  return (data ?? []).map((r) => r.show_id as string);
}

/**
 * Fields on cms_shows a host may edit. Per CLAUDE.md a host edits "bio,
 * hosts, episode notes" — identity and station-ops fields (title, slug,
 * show_type, program_slug, is_active, sort_order, broadcast_status, …) stay
 * admin/editor-only.
 */
export const HOST_EDITABLE_SHOW_FIELDS = new Set<string>([
  "tagline",
  "description",
  "history",
  "logo_path",
  "banner_path",
  "contact_preference",
  "contact_email",
  "website_url",
  "rss_url",
  "social_links",
  "donation_cta_heading",
  "donation_cta_body",
]);
