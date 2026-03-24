-- ============================================================================
-- Migration 022: Fix profiles RLS infinite recursion
-- ============================================================================
-- The profiles_station_admin_select policy caused infinite recursion because
-- it queries the profiles table to check if the user is an admin, which
-- triggers the same policy check again.
--
-- Fix: Use a security definer function to check the user's role without
-- triggering RLS on the profiles table.
-- ============================================================================

-- Create a security definer function to get the current user's profile
-- This function runs with the privileges of the function owner (postgres/service_role)
-- so it bypasses RLS and won't cause recursion
CREATE OR REPLACE FUNCTION get_current_user_profile()
RETURNS TABLE (
    id uuid,
    role text,
    station_id uuid,
    is_active boolean
)
SECURITY DEFINER
SET search_path = public
LANGUAGE sql
STABLE
AS $$
    SELECT p.id, p.role, p.station_id, p.is_active
    FROM profiles p
    WHERE p.id = auth.uid()
    AND p.deleted_at IS NULL
    LIMIT 1;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION get_current_user_profile() TO authenticated;

-- Drop the problematic recursive policy
DROP POLICY IF EXISTS "profiles_station_admin_select" ON profiles;

-- Create a new non-recursive policy for admins to read profiles in their station
-- Uses the security definer function instead of querying profiles directly
CREATE POLICY "profiles_station_admin_select"
    ON profiles FOR SELECT TO authenticated
    USING (
        deleted_at IS NULL
        AND EXISTS (
            SELECT 1 FROM get_current_user_profile() p
            WHERE p.is_active = true
            AND (
                p.role = 'super_admin'
                OR (p.role IN ('admin', 'ops') AND p.station_id = profiles.station_id)
            )
        )
    );

-- ============================================================================
-- End of Migration 022
-- ============================================================================
