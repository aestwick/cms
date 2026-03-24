import { getSupabaseServer } from "@/lib/supabase/server";
import { redirect } from "next/navigation";

export type CmsRole = "admin" | "editor" | "host";

export interface CmsUser {
  id: string;
  email: string;
  role: CmsRole;
  station_id: string;
  display_name: string | null;
}

/**
 * Get the current authenticated CMS user with their profile.
 * Returns null if not authenticated or no CMS profile exists.
 */
export async function getCmsUser(): Promise<CmsUser | null> {
  const supabase = await getSupabaseServer();

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: profile } = await supabase
    .from("cms_profiles")
    .select("id, station_id, role, display_name, email")
    .eq("id", user.id)
    .is("deleted_at", null)
    .single();

  if (!profile) return null;

  return {
    id: profile.id,
    email: profile.email,
    role: profile.role as CmsRole,
    station_id: profile.station_id,
    display_name: profile.display_name,
  };
}

/**
 * Require an authenticated CMS user with one of the specified roles.
 * Redirects to /login if not authenticated, or /unauthorized if wrong role.
 */
export async function requireRole(...roles: CmsRole[]): Promise<CmsUser> {
  const user = await getCmsUser();

  if (!user) {
    redirect("/login");
  }

  if (roles.length > 0 && !roles.includes(user.role)) {
    redirect("/unauthorized");
  }

  return user;
}
