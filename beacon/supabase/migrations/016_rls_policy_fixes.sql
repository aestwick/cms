-- ============================================================================
-- PHASE 012: RLS Policy Fixes
-- ============================================================================
-- Fixes placeholder RLS policies that were never updated:
--   1. audit_log: Restrict to super_admin only (was allowing all authenticated)
--   2. donors: Add station scoping (was placeholder allowing all authenticated)
--   3. donations: Add station scoping (was placeholder allowing all authenticated)
--   4. checkout_sessions: Add station scoping (was placeholder)
--   5. memberships: Add station scoping (was placeholder)
--
-- Run AFTER all previous migrations.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- AUDIT_LOG: Restrict to super_admin only
-- ----------------------------------------------------------------------------
-- The audit log contains sensitive information about all changes across all
-- stations. Only super_admins should be able to see the full audit trail.

-- Drop the old permissive policy
drop policy if exists "audit_log_authenticated_select" on audit_log;

-- Create new super_admin-only policy
-- Why: Audit logs reveal changes across all stations and could expose
-- sensitive operational information. Only super_admins need this access.
create policy "audit_log_super_admin_select"
    on audit_log for select to authenticated
    using (
        exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and p.role = 'super_admin'
        )
    );

-- ----------------------------------------------------------------------------
-- DONORS: Station-scoped access
-- ----------------------------------------------------------------------------
-- Staff can only see donors belonging to their station.
-- Donors can see their own record via the donor portal.

-- Drop the old placeholder policy
drop policy if exists "donors_authenticated_select" on donors;

-- Staff can read donors in their station
-- Why: Operators need to look up donors when taking phone pledges.
-- Station scoping ensures KPFK staff can't see KPFA donors and vice versa.
create policy "donors_station_staff_select"
    on donors for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and (
                -- super_admin can see all donors
                p.role = 'super_admin'
                or (
                    -- station staff can see donors in their station
                    p.role in ('admin', 'ops', 'volunteer')
                    and p.station_id = donors.station_id
                )
            )
        )
    );

-- Donors can view their own record via portal
-- Why: Donors accessing the self-service portal need to see their own info.
create policy "donors_self_select"
    on donors for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.donor_id = donors.id
            and p.role = 'donor'
        )
    );

-- ----------------------------------------------------------------------------
-- DONATIONS: Station-scoped access
-- ----------------------------------------------------------------------------
-- Staff can only see donations belonging to their station.
-- Donors can see their own donations via the portal.

-- Drop the old placeholder policy
drop policy if exists "donations_authenticated_select" on donations;

-- Staff can read donations in their station
-- Why: Operators and admins need to see donation history for phone pledges,
-- fulfillment, and reporting. Station scoping is critical for multi-station.
create policy "donations_station_staff_select"
    on donations for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and (
                -- super_admin can see all donations
                p.role = 'super_admin'
                or (
                    -- station staff can see donations in their station
                    p.role in ('admin', 'ops', 'volunteer')
                    and p.station_id = donations.station_id
                )
            )
        )
    );

-- Donors can view their own donations via portal
-- Why: Donors need to see their giving history in the self-service portal.
create policy "donations_self_select"
    on donations for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            join donors d on d.id = p.donor_id
            where p.id = auth.uid()
            and p.role = 'donor'
            and donations.donor_id = d.id
        )
    );

-- ----------------------------------------------------------------------------
-- CHECKOUT_SESSIONS: Station-scoped access
-- ----------------------------------------------------------------------------
-- Staff can only see checkout sessions for their station.

-- Drop the old placeholder policy
drop policy if exists "checkout_sessions_authenticated_select" on checkout_sessions;

-- Staff can read checkout sessions in their station
create policy "checkout_sessions_station_staff_select"
    on checkout_sessions for select to authenticated
    using (
        exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and (
                p.role = 'super_admin'
                or (
                    p.role in ('admin', 'ops', 'volunteer')
                    and p.station_id = checkout_sessions.station_id
                )
            )
        )
    );

-- ----------------------------------------------------------------------------
-- MEMBERSHIPS: Station-scoped access
-- ----------------------------------------------------------------------------
-- Staff can only see memberships for their station.
-- Donors can see their own memberships.

-- Drop the old placeholder policy
drop policy if exists "memberships_authenticated_select" on memberships;

-- Staff can read memberships in their station
create policy "memberships_station_staff_select"
    on memberships for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and (
                p.role = 'super_admin'
                or (
                    p.role in ('admin', 'ops', 'volunteer')
                    and p.station_id = memberships.station_id
                )
            )
        )
    );

-- Donors can view their own memberships via portal
create policy "memberships_self_select"
    on memberships for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            join donors d on d.id = p.donor_id
            where p.id = auth.uid()
            and p.role = 'donor'
            and memberships.donor_id = d.id
        )
    );

-- ----------------------------------------------------------------------------
-- TAX_DOCUMENTS: Add donor self-access
-- ----------------------------------------------------------------------------
-- Donors need to access their own tax receipts.

-- Drop the old policy and recreate with donor access
drop policy if exists "tax_documents_authenticated_select" on tax_documents;

-- Staff can read tax documents in their station
create policy "tax_documents_station_staff_select"
    on tax_documents for select to authenticated
    using (
        exists (
            select 1 from profiles p
            join donations don on don.id = tax_documents.donation_id
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and (
                p.role = 'super_admin'
                or (
                    p.role in ('admin', 'ops')
                    and p.station_id = don.station_id
                )
            )
        )
    );

-- Donors can view their own tax documents
create policy "tax_documents_self_select"
    on tax_documents for select to authenticated
    using (
        exists (
            select 1 from profiles p
            join donors d on d.id = p.donor_id
            join donations don on don.donor_id = d.id
            where p.id = auth.uid()
            and p.role = 'donor'
            and tax_documents.donation_id = don.id
        )
    );

-- ----------------------------------------------------------------------------
-- EMAIL_LOG: Station-scoped access
-- ----------------------------------------------------------------------------
-- Email logs should be station-scoped for ops+ only.

-- Drop the old placeholder policy
drop policy if exists "email_log_authenticated_select" on email_log;

-- Staff (ops+) can read email logs related to their station
create policy "email_log_station_staff_select"
    on email_log for select to authenticated
    using (
        exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and (
                p.role = 'super_admin'
                or (
                    p.role in ('admin', 'ops')
                    and p.station_id = email_log.station_id
                )
            )
        )
    );

-- ============================================================================
-- End of Phase 012
-- ============================================================================
