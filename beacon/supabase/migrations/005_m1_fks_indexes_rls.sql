-- ============================================================================
-- PHASE 005: M1 Foreign Keys, Indexes, RLS, and Triggers
-- ============================================================================
-- Completes M1 tables with referential integrity, adds station-scoped RLS,
-- and creates the profile auto-creation trigger.
--
-- Run AFTER 004_m1_tables.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- FOREIGN KEYS: profiles
-- ----------------------------------------------------------------------------
alter table profiles
    add constraint profiles_id_fkey
    foreign key (id) references auth.users(id) on delete cascade,
    add constraint profiles_station_id_fkey
    foreign key (station_id) references stations(id),
    add constraint profiles_donor_id_fkey
    foreign key (donor_id) references donors(id);

-- ----------------------------------------------------------------------------
-- FOREIGN KEYS: addresses
-- ----------------------------------------------------------------------------
alter table addresses
    add constraint addresses_donor_id_fkey
    foreign key (donor_id) references donors(id);

-- ----------------------------------------------------------------------------
-- FOREIGN KEYS: gift_variants
-- ----------------------------------------------------------------------------
alter table gift_variants
    add constraint gift_variants_gift_id_fkey
    foreign key (gift_id) references gifts(id);

-- ----------------------------------------------------------------------------
-- FOREIGN KEYS: fulfillment_items
-- ----------------------------------------------------------------------------
alter table fulfillment_items
    add constraint fulfillment_items_donation_id_fkey
    foreign key (donation_id) references donations(id),
    add constraint fulfillment_items_gift_variant_id_fkey
    foreign key (gift_variant_id) references gift_variants(id),
    add constraint fulfillment_items_address_id_fkey
    foreign key (address_id) references addresses(id),
    add constraint fulfillment_items_assigned_to_fkey
    foreign key (assigned_to) references profiles(id);

-- ----------------------------------------------------------------------------
-- FOREIGN KEYS: donor_notes
-- ----------------------------------------------------------------------------
alter table donor_notes
    add constraint donor_notes_donor_id_fkey
    foreign key (donor_id) references donors(id),
    add constraint donor_notes_author_id_fkey
    foreign key (author_id) references profiles(id),
    add constraint donor_notes_supersedes_id_fkey
    foreign key (supersedes_id) references donor_notes(id);

-- ----------------------------------------------------------------------------
-- FOREIGN KEYS: donor_tags
-- ----------------------------------------------------------------------------
alter table donor_tags
    add constraint donor_tags_donor_id_fkey
    foreign key (donor_id) references donors(id),
    add constraint donor_tags_applied_by_fkey
    foreign key (applied_by) references profiles(id);

-- ----------------------------------------------------------------------------
-- FOREIGN KEYS: M0 tables referencing profiles (deferred from Phase 002)
-- ----------------------------------------------------------------------------
alter table checkout_sessions
    add constraint checkout_sessions_operator_id_fkey
    foreign key (operator_id) references profiles(id);

alter table donations
    add constraint donations_operator_id_fkey
    foreign key (operator_id) references profiles(id);

alter table audit_log
    add constraint audit_log_user_id_fkey
    foreign key (user_id) references profiles(id);

-- ----------------------------------------------------------------------------
-- INDEXES: profiles
-- ----------------------------------------------------------------------------
create index profiles_station_id_idx on profiles(station_id) where deleted_at is null;
create index profiles_role_idx on profiles(role) where deleted_at is null;
create index profiles_donor_id_idx on profiles(donor_id) where donor_id is not null;
create index profiles_email_idx on profiles(email) where deleted_at is null;
create index profiles_is_active_idx on profiles(is_active) where deleted_at is null;
create index profiles_deleted_at_idx on profiles(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: addresses
-- ----------------------------------------------------------------------------
create index addresses_donor_id_idx on addresses(donor_id) where deleted_at is null;
create index addresses_type_idx on addresses(donor_id, address_type) where deleted_at is null;
create index addresses_default_idx on addresses(donor_id, address_type, is_default) 
    where deleted_at is null and is_default = true;
create index addresses_deleted_at_idx on addresses(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: gift_variants
-- ----------------------------------------------------------------------------
create index gift_variants_gift_id_idx on gift_variants(gift_id) where deleted_at is null;
create index gift_variants_sku_idx on gift_variants(sku) where sku is not null and deleted_at is null;
create index gift_variants_active_idx on gift_variants(gift_id, is_active, sort_order) 
    where deleted_at is null;
create index gift_variants_low_stock_idx on gift_variants(gift_id)
    where deleted_at is null 
    and inventory_count is not null 
    and low_stock_threshold is not null
    and inventory_count <= low_stock_threshold;
create index gift_variants_deleted_at_idx on gift_variants(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: fulfillment_items
-- ----------------------------------------------------------------------------
create index fulfillment_items_donation_id_idx on fulfillment_items(donation_id) where deleted_at is null;
create index fulfillment_items_gift_variant_id_idx on fulfillment_items(gift_variant_id) where deleted_at is null;
create index fulfillment_items_address_id_idx on fulfillment_items(address_id) where address_id is not null;
create index fulfillment_items_assigned_to_idx on fulfillment_items(assigned_to) where assigned_to is not null;
create index fulfillment_items_status_idx on fulfillment_items(status) where deleted_at is null;
-- Queue views: pending items needing assignment
create index fulfillment_items_pending_idx on fulfillment_items(created_at) 
    where deleted_at is null and status = 'pending';
-- Queue views: assigned items in progress
create index fulfillment_items_in_progress_idx on fulfillment_items(assigned_to, status)
    where deleted_at is null and status in ('assigned', 'processing');
create index fulfillment_items_deleted_at_idx on fulfillment_items(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: donor_notes
-- ----------------------------------------------------------------------------
create index donor_notes_donor_id_idx on donor_notes(donor_id) where deleted_at is null;
create index donor_notes_author_id_idx on donor_notes(author_id) where author_id is not null;
create index donor_notes_type_idx on donor_notes(donor_id, note_type) where deleted_at is null;
create index donor_notes_pinned_idx on donor_notes(donor_id, is_pinned)
    where deleted_at is null and is_pinned = true;
create index donor_notes_supersedes_idx on donor_notes(supersedes_id) where supersedes_id is not null;
create index donor_notes_deleted_at_idx on donor_notes(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: donor_tags
-- ----------------------------------------------------------------------------
create index donor_tags_donor_id_idx on donor_tags(donor_id) where deleted_at is null;
create index donor_tags_tag_idx on donor_tags(tag) where deleted_at is null;
-- Find all donors with a specific tag
create index donor_tags_tag_donor_idx on donor_tags(tag, donor_id) where deleted_at is null;
create index donor_tags_applied_by_idx on donor_tags(applied_by) where applied_by is not null;
create index donor_tags_deleted_at_idx on donor_tags(deleted_at) where deleted_at is null;
-- Unique constraint (partial - soft delete aware)
create unique index donor_tags_donor_tag_unique_idx 
    on donor_tags(donor_id, tag) 
    where deleted_at is null;

-- ----------------------------------------------------------------------------
-- RLS: profiles
-- ----------------------------------------------------------------------------
alter table profiles enable row level security;

-- Anon: no access
create policy "profiles_anon_deny_all"
    on profiles for all to anon
    using (false);

-- Service role: full access
create policy "profiles_service_role_all"
    on profiles for all to service_role
    using (true) with check (true);

-- Users can read their own profile
create policy "profiles_self_select"
    on profiles for select to authenticated
    using (id = auth.uid() and deleted_at is null);

-- Users can update their own profile (limited fields - enforced in app)
create policy "profiles_self_update"
    on profiles for update to authenticated
    using (id = auth.uid() and deleted_at is null)
    with check (id = auth.uid());

-- Admins can read all profiles in their station
create policy "profiles_station_admin_select"
    on profiles for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and (
                p.role = 'super_admin'
                or (p.role in ('admin', 'ops') and p.station_id = profiles.station_id)
            )
        )
    );

-- ----------------------------------------------------------------------------
-- RLS: addresses (PII)
-- ----------------------------------------------------------------------------
alter table addresses enable row level security;

-- Anon: no access
create policy "addresses_anon_deny_all"
    on addresses for all to anon
    using (false);

-- Service role: full access
create policy "addresses_service_role_all"
    on addresses for all to service_role
    using (true) with check (true);

-- Authenticated: read addresses for donors in their station
create policy "addresses_authenticated_select"
    on addresses for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            join donors d on d.station_id = p.station_id
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and d.id = addresses.donor_id
            and (p.role in ('super_admin', 'admin', 'ops', 'volunteer'))
        )
    );

-- Donors can read their own addresses
create policy "addresses_donor_self_select"
    on addresses for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.donor_id = addresses.donor_id
            and p.role = 'donor'
        )
    );

-- No direct writes from authenticated users
create policy "addresses_authenticated_deny_insert"
    on addresses for insert to authenticated
    with check (false);

create policy "addresses_authenticated_deny_update"
    on addresses for update to authenticated
    using (false);

create policy "addresses_authenticated_deny_delete"
    on addresses for delete to authenticated
    using (false);

-- ----------------------------------------------------------------------------
-- RLS: gift_variants (not PII, but protected)
-- ----------------------------------------------------------------------------
alter table gift_variants enable row level security;

-- Public read for active variants (needed for donation forms)
create policy "gift_variants_anon_select"
    on gift_variants for select to anon
    using (deleted_at is null and is_active = true);

create policy "gift_variants_authenticated_select"
    on gift_variants for select to authenticated
    using (deleted_at is null);

create policy "gift_variants_service_role_all"
    on gift_variants for all to service_role
    using (true) with check (true);

-- ----------------------------------------------------------------------------
-- RLS: fulfillment_items (references PII)
-- ----------------------------------------------------------------------------
alter table fulfillment_items enable row level security;

-- Anon: no access
create policy "fulfillment_items_anon_deny_all"
    on fulfillment_items for all to anon
    using (false);

-- Service role: full access
create policy "fulfillment_items_service_role_all"
    on fulfillment_items for all to service_role
    using (true) with check (true);

-- Staff can read fulfillment items for donations in their station
create policy "fulfillment_items_staff_select"
    on fulfillment_items for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            join donations don on don.station_id = p.station_id
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and don.id = fulfillment_items.donation_id
            and p.role in ('super_admin', 'admin', 'ops', 'volunteer')
        )
    );

-- No direct writes
create policy "fulfillment_items_authenticated_deny_insert"
    on fulfillment_items for insert to authenticated
    with check (false);

create policy "fulfillment_items_authenticated_deny_update"
    on fulfillment_items for update to authenticated
    using (false);

create policy "fulfillment_items_authenticated_deny_delete"
    on fulfillment_items for delete to authenticated
    using (false);

-- ----------------------------------------------------------------------------
-- RLS: donor_notes (PII)
-- ----------------------------------------------------------------------------
alter table donor_notes enable row level security;

-- Anon: no access
create policy "donor_notes_anon_deny_all"
    on donor_notes for all to anon
    using (false);

-- Service role: full access
create policy "donor_notes_service_role_all"
    on donor_notes for all to service_role
    using (true) with check (true);

-- Staff can read internal notes for donors in their station
create policy "donor_notes_staff_select"
    on donor_notes for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            join donors d on d.station_id = p.station_id
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and d.id = donor_notes.donor_id
            and p.role in ('super_admin', 'admin', 'ops')
        )
    );

-- Donors can only see donor_visible notes on their own record
create policy "donor_notes_donor_self_select"
    on donor_notes for select to authenticated
    using (
        deleted_at is null
        and note_type = 'donor_visible'
        and exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.donor_id = donor_notes.donor_id
            and p.role = 'donor'
        )
    );

-- No direct writes
create policy "donor_notes_authenticated_deny_insert"
    on donor_notes for insert to authenticated
    with check (false);

create policy "donor_notes_authenticated_deny_update"
    on donor_notes for update to authenticated
    using (false);

create policy "donor_notes_authenticated_deny_delete"
    on donor_notes for delete to authenticated
    using (false);

-- ----------------------------------------------------------------------------
-- RLS: donor_tags
-- ----------------------------------------------------------------------------
alter table donor_tags enable row level security;

-- Anon: no access
create policy "donor_tags_anon_deny_all"
    on donor_tags for all to anon
    using (false);

-- Service role: full access
create policy "donor_tags_service_role_all"
    on donor_tags for all to service_role
    using (true) with check (true);

-- Staff can read tags for donors in their station
create policy "donor_tags_staff_select"
    on donor_tags for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            join donors d on d.station_id = p.station_id
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and d.id = donor_tags.donor_id
            and p.role in ('super_admin', 'admin', 'ops', 'volunteer')
        )
    );

-- No direct writes
create policy "donor_tags_authenticated_deny_insert"
    on donor_tags for insert to authenticated
    with check (false);

create policy "donor_tags_authenticated_deny_update"
    on donor_tags for update to authenticated
    using (false);

create policy "donor_tags_authenticated_deny_delete"
    on donor_tags for delete to authenticated
    using (false);

-- ----------------------------------------------------------------------------
-- TRIGGER: Auto-create profile on auth.users signup
-- ----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (id, email, role, is_active)
    values (
        new.id,
        new.email,
        'donor',  -- default role; staff accounts upgraded manually
        true
    );
    return new;
end;
$$;

-- Trigger on auth.users insert
create trigger on_auth_user_created
    after insert on auth.users
    for each row
    execute function public.handle_new_user();

-- ----------------------------------------------------------------------------
-- TRIGGER: Update updated_at timestamps
-- ----------------------------------------------------------------------------
create or replace function public.update_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

-- Apply to all tables with updated_at
create trigger stations_updated_at before update on stations
    for each row execute function update_updated_at();
create trigger shows_updated_at before update on shows
    for each row execute function update_updated_at();
create trigger campaigns_updated_at before update on campaigns
    for each row execute function update_updated_at();
create trigger donors_updated_at before update on donors
    for each row execute function update_updated_at();
create trigger gifts_updated_at before update on gifts
    for each row execute function update_updated_at();
create trigger memberships_updated_at before update on memberships
    for each row execute function update_updated_at();
create trigger checkout_sessions_updated_at before update on checkout_sessions
    for each row execute function update_updated_at();
create trigger donations_updated_at before update on donations
    for each row execute function update_updated_at();
create trigger profiles_updated_at before update on profiles
    for each row execute function update_updated_at();
create trigger addresses_updated_at before update on addresses
    for each row execute function update_updated_at();
create trigger gift_variants_updated_at before update on gift_variants
    for each row execute function update_updated_at();
create trigger fulfillment_items_updated_at before update on fulfillment_items
    for each row execute function update_updated_at();
create trigger donor_notes_updated_at before update on donor_notes
    for each row execute function update_updated_at();

-- ============================================================================
-- End of Phase 005
-- Next: 006_m3_events_tables.sql (Events & Tickets)
-- ============================================================================
