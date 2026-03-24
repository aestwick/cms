-- ============================================================================
-- PHASE 024: Press Pass Verification System
-- ============================================================================
-- Tables for KPFK press credential verification.
-- Security personnel can scan QR codes or manually enter pass IDs to verify.
--
-- Key design decisions:
--   - verification_token is separate from pass_number for security (can rotate)
--   - verification_logs table tracks ALL lookup attempts (found or not)
--   - Public read access for verification (no auth required to check a pass)
--   - Write access restricted to service_role (admin operations)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PRESS_PASSES: Stores issued press credentials
-- ----------------------------------------------------------------------------
create table press_passes (
    id                  uuid primary key default gen_random_uuid(),
    station_id          uuid not null references stations(id),
    pass_number         text unique not null,              -- "KPFK-045"
    verification_token  text unique not null,              -- random, used in QR URLs
    holder_name         text not null,
    title               text,                               -- "Music & Promotions Director"
    photo_url           text,                               -- Supabase storage URL
    pass_type           text not null default 'staff'
                        check (pass_type in ('staff', 'talent', 'producer', 'leadership', 'volunteer')),
    status              text not null default 'active'
                        check (status in ('active', 'revoked', 'lost', 'expired')),
    issued_at           date not null,
    expires_at          date not null,
    notes               text,                               -- internal use only
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),
    deleted_at          timestamptz                         -- soft delete
);

-- Indexes for common lookups
create index idx_press_passes_station_id on press_passes(station_id);
create index idx_press_passes_pass_number on press_passes(pass_number) where deleted_at is null;
create index idx_press_passes_verification_token on press_passes(verification_token) where deleted_at is null;
create index idx_press_passes_status on press_passes(status) where deleted_at is null;

-- Function to auto-update updated_at timestamp (if not already defined)
create or replace function update_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

-- Trigger to update updated_at on changes
create trigger press_passes_updated_at
    before update on press_passes
    for each row
    execute function update_updated_at();

-- Comment explaining the table
comment on table press_passes is 'KPFK press credentials for verification by security/LEO';
comment on column press_passes.verification_token is 'Random token used in QR code URLs, separate from pass_number for security';
comment on column press_passes.pass_type is 'Category of credential holder: staff, talent, producer, leadership, volunteer';
comment on column press_passes.status is 'Current status: active, revoked, lost (reported stolen), expired';

-- ----------------------------------------------------------------------------
-- VERIFICATION_LOGS: Tracks all verification attempts (security audit trail)
-- ----------------------------------------------------------------------------
create table verification_logs (
    id                  uuid primary key default gen_random_uuid(),
    press_pass_id       uuid references press_passes(id),   -- null if not found
    lookup_type         text not null
                        check (lookup_type in ('token', 'manual')),
    lookup_value        text not null,                      -- what they searched for
    lookup_result       text not null
                        check (lookup_result in ('valid', 'not_found', 'revoked', 'lost', 'expired')),
    ip_address          inet,
    user_agent          text,
    created_at          timestamptz not null default now()
);

-- Index for querying logs by pass (to detect suspicious patterns)
create index idx_verification_logs_press_pass_id on verification_logs(press_pass_id);
create index idx_verification_logs_created_at on verification_logs(created_at);
create index idx_verification_logs_ip_address on verification_logs(ip_address);
create index idx_verification_logs_result on verification_logs(lookup_result);

-- Comment explaining the table
comment on table verification_logs is 'Audit trail of all press pass verification attempts';
comment on column verification_logs.lookup_type is 'How the lookup was performed: token (QR scan) or manual (ID entry)';
comment on column verification_logs.lookup_result is 'Result: valid, not_found, revoked, lost, expired';

-- ----------------------------------------------------------------------------
-- ROW LEVEL SECURITY
-- ----------------------------------------------------------------------------

-- Enable RLS on both tables
alter table press_passes enable row level security;
alter table verification_logs enable row level security;

-- PRESS_PASSES: Public can read active passes for verification
-- Only service_role can create/update/delete

-- Anon can SELECT limited fields for verification (public verification page)
create policy "press_passes_anon_select_for_verification"
    on press_passes
    for select
    to anon
    using (deleted_at is null);

-- Service role: full access for admin operations
create policy "press_passes_service_role_all"
    on press_passes
    for all
    to service_role
    using (true)
    with check (true);

-- Authenticated staff can read all passes in their station
create policy "press_passes_authenticated_select"
    on press_passes
    for select
    to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles
            where profiles.user_id = auth.uid()
            and profiles.station_id = press_passes.station_id
            and profiles.deleted_at is null
        )
    );

-- Only service_role can insert/update/delete
create policy "press_passes_authenticated_deny_insert"
    on press_passes
    for insert
    to authenticated
    with check (false);

create policy "press_passes_authenticated_deny_update"
    on press_passes
    for update
    to authenticated
    using (false);

create policy "press_passes_authenticated_deny_delete"
    on press_passes
    for delete
    to authenticated
    using (false);

-- VERIFICATION_LOGS: Anon can INSERT (to log their lookup), only service_role can read

-- Anon can insert verification logs (public verification page logs attempts)
create policy "verification_logs_anon_insert"
    on verification_logs
    for insert
    to anon
    with check (true);

-- Anon cannot read logs
create policy "verification_logs_anon_deny_select"
    on verification_logs
    for select
    to anon
    using (false);

-- Service role: full access
create policy "verification_logs_service_role_all"
    on verification_logs
    for all
    to service_role
    using (true)
    with check (true);

-- Authenticated staff can read logs for their station's passes
create policy "verification_logs_authenticated_select"
    on verification_logs
    for select
    to authenticated
    using (
        exists (
            select 1 from press_passes pp
            join profiles p on p.station_id = pp.station_id
            where pp.id = verification_logs.press_pass_id
            and p.user_id = auth.uid()
            and p.deleted_at is null
        )
    );

-- Authenticated can insert logs
create policy "verification_logs_authenticated_insert"
    on verification_logs
    for insert
    to authenticated
    with check (true);

-- No update/delete for anyone except service_role (logs are immutable)
create policy "verification_logs_authenticated_deny_update"
    on verification_logs
    for update
    to authenticated
    using (false);

create policy "verification_logs_authenticated_deny_delete"
    on verification_logs
    for delete
    to authenticated
    using (false);

-- ----------------------------------------------------------------------------
-- STORAGE BUCKET: press-pass-photos
-- ----------------------------------------------------------------------------
-- Creates a public bucket for press pass photos
-- Photos need to be publicly accessible for the verification page
--
-- Path format: {station_id}/{pass_number}.jpg
-- Example: abc123-uuid/KPFK-045.jpg

-- Create the storage bucket (if not exists)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'press-pass-photos',
    'press-pass-photos',
    true,  -- public bucket (photos must be viewable without auth)
    5242880,  -- 5MB max file size
    array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

-- Storage policies for the bucket

-- Allow public read access (for verification page to display photos)
create policy "press_pass_photos_public_read"
    on storage.objects
    for select
    to anon, authenticated
    using (bucket_id = 'press-pass-photos');

-- Only service_role can upload/update/delete photos (admin operations)
-- Note: Service role bypasses RLS, so we only need to block anon/authenticated
create policy "press_pass_photos_authenticated_deny_insert"
    on storage.objects
    for insert
    to authenticated
    with check (
        bucket_id = 'press-pass-photos'
        and false  -- deny all authenticated inserts; use service_role
    );

create policy "press_pass_photos_authenticated_deny_update"
    on storage.objects
    for update
    to authenticated
    using (
        bucket_id = 'press-pass-photos'
        and false  -- deny all authenticated updates
    );

create policy "press_pass_photos_authenticated_deny_delete"
    on storage.objects
    for delete
    to authenticated
    using (
        bucket_id = 'press-pass-photos'
        and false  -- deny all authenticated deletes
    );

-- ============================================================================
-- End of Phase 024
-- ============================================================================
