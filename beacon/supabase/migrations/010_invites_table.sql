-- ============================================================================
-- PHASE 010: Staff Invites Table
-- ============================================================================
-- Creates the invites table for invite-only admin signup flow.
-- Super_admins and admins can invite staff members who receive a magic link
-- to create their account with a pre-assigned role.
--
-- Run AFTER 009_program_schedule_tables.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- invites: Pending staff invitations
-- ----------------------------------------------------------------------------
-- Workflow:
-- 1. Admin creates invite with email and role
-- 2. System sends magic link with token to email
-- 3. User clicks link, creates account, invite marked as used
-- 4. Profile created with pre-assigned role from invite
--
-- Tokens are single-use and expire after 7 days by default.
-- ----------------------------------------------------------------------------
create table invites (
    id              uuid primary key default gen_random_uuid(),
    station_id      uuid not null,                              -- FK to stations

    -- Invite details
    email           text not null,                              -- normalized (lowercase, trimmed)
    token           text not null unique,                       -- secure random token for URL
    role            text not null default 'volunteer',          -- role to assign on signup

    -- Tracking
    invited_by      uuid not null,                              -- FK to profiles (who sent the invite)
    expires_at      timestamptz not null,                       -- when the invite expires
    used_at         timestamptz,                                -- when the invite was used (null = pending)

    created_at      timestamptz not null default now()
    -- No updated_at: invites are immutable once created
    -- No deleted_at: expired invites are just ignored
);

-- Role constraint (same roles as profiles, except 'donor' which can't be invited)
alter table invites
    add constraint invites_role_check
    check (role in ('super_admin', 'admin', 'ops', 'volunteer'));

-- Foreign keys
alter table invites
    add constraint invites_station_id_fkey
    foreign key (station_id) references stations(id);

alter table invites
    add constraint invites_invited_by_fkey
    foreign key (invited_by) references profiles(id);

-- Indexes
-- Look up pending invites by token (primary use case)
create unique index invites_token_idx on invites(token);

-- Find pending invites by email (to prevent duplicates)
-- Note: Can't use now() in index predicate (not immutable), so we just filter on used_at
-- Application code should also check expires_at > now() at query time
create index invites_email_pending_idx on invites(email)
    where used_at is null;

-- List invites by station for admin view
create index invites_station_id_idx on invites(station_id);

-- Find expired invites for cleanup
create index invites_expires_at_idx on invites(expires_at)
    where used_at is null;

-- ----------------------------------------------------------------------------
-- RLS Policies for invites
-- ----------------------------------------------------------------------------
alter table invites enable row level security;

-- Super_admin can see all invites
create policy "super_admin_all_invites" on invites
    for all
    to authenticated
    using (
        exists (
            select 1 from profiles
            where profiles.id = auth.uid()
            and profiles.role = 'super_admin'
            and profiles.is_active = true
            and profiles.deleted_at is null
        )
    );

-- Admin can see and create invites for their station
create policy "admin_station_invites" on invites
    for all
    to authenticated
    using (
        exists (
            select 1 from profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
            and profiles.station_id = invites.station_id
            and profiles.is_active = true
            and profiles.deleted_at is null
        )
    );

-- ============================================================================
-- End of Phase 010
-- ============================================================================
