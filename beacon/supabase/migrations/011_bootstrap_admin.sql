-- Migration: Bootstrap first admin user
-- Problem: New signups get role='donor' by default, but someone needs admin access
-- to invite other staff members. This creates a chicken-and-egg situation.
--
-- Solution: This migration promotes all @kpfk.org users with 'donor' role to
-- 'super_admin'. We use super_admin because:
--   1. It doesn't require station_id (can manage all stations)
--   2. First user needs full access to bootstrap the system
--   3. They can later invite properly-scoped admins for each station
--
-- Note: This is a one-time bootstrap. Future staff should be invited via the
-- invite system which properly assigns roles and station_id from the start.

-- Promote @kpfk.org users who currently have 'donor' role to 'super_admin'
-- This solves the bootstrapping problem where the first user can't access admin
update profiles
set
    role = 'super_admin',
    updated_at = now()
where
    email like '%@kpfk.org'
    and role = 'donor'
    and deleted_at is null;

-- Log how many users were promoted (for debugging in Supabase logs)
do $$
declare
    promoted_count integer;
begin
    select count(*) into promoted_count
    from profiles
    where email like '%@kpfk.org'
    and role = 'super_admin'
    and deleted_at is null;

    raise notice 'Admin bootstrap: % @kpfk.org users now have super_admin role', promoted_count;
end;
$$;
