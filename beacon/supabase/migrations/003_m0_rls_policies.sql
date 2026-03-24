-- ============================================================================
-- PHASE 003: M0 Row Level Security (RLS) Policies
-- ============================================================================
-- Enables RLS and creates policies for PII tables.
-- Run AFTER 002_m0_fks_indexes.sql
--
-- Policy strategy:
--   - PII tables: donors, donations, checkout_sessions, addresses (M1)
--   - Deny ALL access to anon role
--   - Allow service_role full access (for backend/webhooks)
--   - Authenticated users: station-scoped access based on profiles (added in M1)
--
-- Note: Full authenticated user policies require profiles table (Phase 004).
--       This phase sets up the foundation; Phase 005 adds user-based policies.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Enable RLS on PII tables
-- ----------------------------------------------------------------------------
alter table donors enable row level security;
alter table donations enable row level security;
alter table checkout_sessions enable row level security;
alter table memberships enable row level security;
alter table tax_documents enable row level security;
alter table email_log enable row level security;

-- Also protect audit logs (sensitive metadata)
alter table audit_log enable row level security;

-- ----------------------------------------------------------------------------
-- DONORS: PII protection
-- ----------------------------------------------------------------------------

-- Deny anon all access
create policy "donors_anon_deny_all"
    on donors
    for all
    to anon
    using (false);

-- Service role: full access (webhooks, backend jobs)
create policy "donors_service_role_all"
    on donors
    for all
    to service_role
    using (true)
    with check (true);

-- Authenticated base policy (will be refined in Phase 005 with station scoping)
-- For now: authenticated users can read donors in their station
-- This is a placeholder that allows nothing until profiles exist
create policy "donors_authenticated_select"
    on donors
    for select
    to authenticated
    using (
        -- Placeholder: requires profiles table for proper scoping
        -- Will be replaced in Phase 005
        exists (
            select 1 from auth.users 
            where auth.users.id = auth.uid()
        )
        and deleted_at is null
    );

-- Authenticated users cannot directly insert/update/delete donors
-- All mutations go through service_role (backend functions)
create policy "donors_authenticated_deny_insert"
    on donors
    for insert
    to authenticated
    with check (false);

create policy "donors_authenticated_deny_update"
    on donors
    for update
    to authenticated
    using (false);

create policy "donors_authenticated_deny_delete"
    on donors
    for delete
    to authenticated
    using (false);

-- ----------------------------------------------------------------------------
-- DONATIONS: PII protection
-- ----------------------------------------------------------------------------

-- Deny anon all access
create policy "donations_anon_deny_all"
    on donations
    for all
    to anon
    using (false);

-- Service role: full access
create policy "donations_service_role_all"
    on donations
    for all
    to service_role
    using (true)
    with check (true);

-- Authenticated: read only (station-scoped, refined in Phase 005)
create policy "donations_authenticated_select"
    on donations
    for select
    to authenticated
    using (
        exists (
            select 1 from auth.users 
            where auth.users.id = auth.uid()
        )
        and deleted_at is null
    );

create policy "donations_authenticated_deny_insert"
    on donations
    for insert
    to authenticated
    with check (false);

create policy "donations_authenticated_deny_update"
    on donations
    for update
    to authenticated
    using (false);

create policy "donations_authenticated_deny_delete"
    on donations
    for delete
    to authenticated
    using (false);

-- ----------------------------------------------------------------------------
-- CHECKOUT_SESSIONS: PII protection (contains donor_snapshot)
-- ----------------------------------------------------------------------------

-- Deny anon all access
create policy "checkout_sessions_anon_deny_all"
    on checkout_sessions
    for all
    to anon
    using (false);

-- Service role: full access
create policy "checkout_sessions_service_role_all"
    on checkout_sessions
    for all
    to service_role
    using (true)
    with check (true);

-- Authenticated: read only
create policy "checkout_sessions_authenticated_select"
    on checkout_sessions
    for select
    to authenticated
    using (
        exists (
            select 1 from auth.users 
            where auth.users.id = auth.uid()
        )
    );

create policy "checkout_sessions_authenticated_deny_insert"
    on checkout_sessions
    for insert
    to authenticated
    with check (false);

create policy "checkout_sessions_authenticated_deny_update"
    on checkout_sessions
    for update
    to authenticated
    using (false);

create policy "checkout_sessions_authenticated_deny_delete"
    on checkout_sessions
    for delete
    to authenticated
    using (false);

-- ----------------------------------------------------------------------------
-- MEMBERSHIPS: PII protection
-- ----------------------------------------------------------------------------

-- Deny anon all access
create policy "memberships_anon_deny_all"
    on memberships
    for all
    to anon
    using (false);

-- Service role: full access
create policy "memberships_service_role_all"
    on memberships
    for all
    to service_role
    using (true)
    with check (true);

-- Authenticated: read only
create policy "memberships_authenticated_select"
    on memberships
    for select
    to authenticated
    using (
        exists (
            select 1 from auth.users 
            where auth.users.id = auth.uid()
        )
        and deleted_at is null
    );

create policy "memberships_authenticated_deny_insert"
    on memberships
    for insert
    to authenticated
    with check (false);

create policy "memberships_authenticated_deny_update"
    on memberships
    for update
    to authenticated
    using (false);

create policy "memberships_authenticated_deny_delete"
    on memberships
    for delete
    to authenticated
    using (false);

-- ----------------------------------------------------------------------------
-- TAX_DOCUMENTS: PII protection (contains donor data snapshots)
-- ----------------------------------------------------------------------------

-- Deny anon all access
create policy "tax_documents_anon_deny_all"
    on tax_documents
    for all
    to anon
    using (false);

-- Service role: full access
create policy "tax_documents_service_role_all"
    on tax_documents
    for all
    to service_role
    using (true)
    with check (true);

-- Authenticated: read only
create policy "tax_documents_authenticated_select"
    on tax_documents
    for select
    to authenticated
    using (
        exists (
            select 1 from auth.users 
            where auth.users.id = auth.uid()
        )
    );

-- Tax documents are immutable - no insert/update/delete for authenticated
create policy "tax_documents_authenticated_deny_insert"
    on tax_documents
    for insert
    to authenticated
    with check (false);

create policy "tax_documents_authenticated_deny_update"
    on tax_documents
    for update
    to authenticated
    using (false);

create policy "tax_documents_authenticated_deny_delete"
    on tax_documents
    for delete
    to authenticated
    using (false);

-- ----------------------------------------------------------------------------
-- EMAIL_LOG: PII protection (contains recipient emails)
-- ----------------------------------------------------------------------------

-- Deny anon all access
create policy "email_log_anon_deny_all"
    on email_log
    for all
    to anon
    using (false);

-- Service role: full access
create policy "email_log_service_role_all"
    on email_log
    for all
    to service_role
    using (true)
    with check (true);

-- Authenticated: read only
create policy "email_log_authenticated_select"
    on email_log
    for select
    to authenticated
    using (
        exists (
            select 1 from auth.users 
            where auth.users.id = auth.uid()
        )
    );

-- Email log is append-only via service_role
create policy "email_log_authenticated_deny_insert"
    on email_log
    for insert
    to authenticated
    with check (false);

create policy "email_log_authenticated_deny_update"
    on email_log
    for update
    to authenticated
    using (false);

create policy "email_log_authenticated_deny_delete"
    on email_log
    for delete
    to authenticated
    using (false);

-- ----------------------------------------------------------------------------
-- AUDIT_LOG: Protected (sensitive change history)
-- ----------------------------------------------------------------------------

-- Deny anon all access
create policy "audit_log_anon_deny_all"
    on audit_log
    for all
    to anon
    using (false);

-- Service role: full access
create policy "audit_log_service_role_all"
    on audit_log
    for all
    to service_role
    using (true)
    with check (true);

-- Authenticated: read only (super_admin scoping added in Phase 005)
create policy "audit_log_authenticated_select"
    on audit_log
    for select
    to authenticated
    using (
        exists (
            select 1 from auth.users 
            where auth.users.id = auth.uid()
        )
    );

-- Audit log is immutable - no modifications allowed
create policy "audit_log_authenticated_deny_insert"
    on audit_log
    for insert
    to authenticated
    with check (false);

create policy "audit_log_authenticated_deny_update"
    on audit_log
    for update
    to authenticated
    using (false);

create policy "audit_log_authenticated_deny_delete"
    on audit_log
    for delete
    to authenticated
    using (false);

-- ----------------------------------------------------------------------------
-- NON-PII TABLES: More permissive policies
-- ----------------------------------------------------------------------------

-- stations: public read, service_role write
alter table stations enable row level security;

create policy "stations_anon_select"
    on stations for select to anon
    using (deleted_at is null);

create policy "stations_authenticated_select"
    on stations for select to authenticated
    using (deleted_at is null);

create policy "stations_service_role_all"
    on stations for all to service_role
    using (true) with check (true);

-- shows: public read, service_role write
alter table shows enable row level security;

create policy "shows_anon_select"
    on shows for select to anon
    using (deleted_at is null);

create policy "shows_authenticated_select"
    on shows for select to authenticated
    using (deleted_at is null);

create policy "shows_service_role_all"
    on shows for all to service_role
    using (true) with check (true);

-- campaigns: public read (for thermometers/widgets), service_role write
alter table campaigns enable row level security;

create policy "campaigns_anon_select"
    on campaigns for select to anon
    using (deleted_at is null);

create policy "campaigns_authenticated_select"
    on campaigns for select to authenticated
    using (deleted_at is null);

create policy "campaigns_service_role_all"
    on campaigns for all to service_role
    using (true) with check (true);

-- gifts: public read (for donation forms), service_role write
alter table gifts enable row level security;

create policy "gifts_anon_select"
    on gifts for select to anon
    using (deleted_at is null and is_active = true);

create policy "gifts_authenticated_select"
    on gifts for select to authenticated
    using (deleted_at is null);

create policy "gifts_service_role_all"
    on gifts for all to service_role
    using (true) with check (true);

-- system_events: no anon access, service_role only writes
alter table system_events enable row level security;

create policy "system_events_anon_deny_all"
    on system_events for all to anon
    using (false);

create policy "system_events_authenticated_select"
    on system_events for select to authenticated
    using (
        exists (
            select 1 from auth.users 
            where auth.users.id = auth.uid()
        )
    );

create policy "system_events_authenticated_deny_write"
    on system_events for insert to authenticated
    with check (false);

create policy "system_events_service_role_all"
    on system_events for all to service_role
    using (true) with check (true);

-- ============================================================================
-- End of Phase 003
-- Next: 004_m1_tables.sql (Staff CRM tables)
-- ============================================================================
