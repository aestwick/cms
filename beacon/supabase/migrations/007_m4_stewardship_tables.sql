-- ============================================================================
-- PHASE 007: M4 Matching & Stewardship Tables
-- ============================================================================
-- Creates matching gift pools and major donor stewardship tables.
-- Tables: match_pools, match_allocations, interactions, gift_intents,
--         documents, donor_extensions
--
-- Run AFTER 006_m3_events_tables.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- match_pools: Matching fund buckets
-- ----------------------------------------------------------------------------
create table match_pools (
    id              uuid primary key default gen_random_uuid(),
    station_id      uuid not null references stations(id),
    campaign_id     uuid references campaigns(id),              -- optional campaign scope
    
    -- Pool details
    name            text not null,                              -- "Holiday Match 2025"
    description     text,
    
    -- Matcher info
    matcher_name    text,                                       -- "Anonymous Foundation"
    matcher_type    text not null default 'anonymous',          -- individual, foundation, corporate, anonymous
    is_public       boolean not null default false,             -- show name publicly?
    
    -- Match terms
    match_ratio     numeric(5,2) not null default 1.00,         -- 1.00 = dollar-for-dollar, 0.50 = 50 cents per dollar
    
    -- Amounts (in cents)
    total_cents     bigint not null,                            -- total pool available
    remaining_cents bigint not null,                            -- remaining to allocate
    
    -- Eligibility rules (jsonb for flexibility)
    eligibility_rules jsonb not null default '{}',              -- min_amount, max_amount, first_time_only, etc.
    
    -- Validity
    valid_from      timestamptz,
    valid_until     timestamptz,
    is_active       boolean not null default true,
    
    -- Status
    exhausted_at    timestamptz,                                -- when remaining hit 0
    
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz
);

-- Matcher type constraint
alter table match_pools
    add constraint match_pools_matcher_type_check
    check (matcher_type in ('individual', 'foundation', 'corporate', 'anonymous'));

-- ----------------------------------------------------------------------------
-- match_allocations: Donation ↔ match links
-- ----------------------------------------------------------------------------
-- Tracks which donations consumed which match funds.
-- A donation can have multiple partial matches from different pools.
-- ----------------------------------------------------------------------------
create table match_allocations (
    id              uuid primary key default gen_random_uuid(),
    donation_id     uuid not null references donations(id),
    match_pool_id   uuid not null references match_pools(id),
    
    -- Match amount
    amount_cents    bigint not null,                            -- matched amount from this pool
    
    -- Audit
    allocated_at    timestamptz not null default now(),
    allocated_by    uuid references profiles(id),               -- null for automated
    
    created_at      timestamptz not null default now()
    -- Immutable: no updated_at or deleted_at
);

-- Prevent double-allocation of same donation to same pool
create unique index match_allocations_donation_pool_idx 
    on match_allocations(donation_id, match_pool_id);

-- ----------------------------------------------------------------------------
-- interactions: Structured interaction log (stewardship)
-- ----------------------------------------------------------------------------
-- Append-only log of human interactions with donors.
-- Critical for major donor cultivation and compliance.
-- ----------------------------------------------------------------------------
create table interactions (
    id                  uuid primary key default gen_random_uuid(),
    donor_id            uuid not null references donors(id),
    station_id          uuid not null references stations(id),
    staff_user_id       uuid not null references profiles(id),
    
    -- Interaction details
    interaction_type    text not null,                          -- phone, in_person, email, voicemail, letter, meeting
    direction           text not null default 'outbound',       -- inbound, outbound
    occurred_at         timestamptz not null,
    duration_minutes    integer,
    
    -- Content
    subject             text,
    summary             text not null,                          -- what was discussed
    
    -- For sensitive conversations
    witness_id          uuid references profiles(id),           -- second staff member present
    
    -- Follow-up
    requires_followup   boolean not null default false,
    followup_by         timestamptz,
    followup_completed  boolean not null default false,
    followup_completed_at timestamptz,
    
    -- Context links
    campaign_id         uuid references campaigns(id),
    gift_intent_id      uuid,                                   -- FK added via ALTER below
    
    created_at          timestamptz not null default now()
    -- Append-only: no updated_at or deleted_at
);

-- Interaction type constraint
alter table interactions
    add constraint interactions_type_check
    check (interaction_type in ('phone', 'in_person', 'email', 'voicemail', 'letter', 'meeting', 'event'));

alter table interactions
    add constraint interactions_direction_check
    check (direction in ('inbound', 'outbound'));

-- ----------------------------------------------------------------------------
-- gift_intents: Major donor gift intentions
-- ----------------------------------------------------------------------------
-- Captures what donor said they wanted to give.
-- Immutable; corrections create new rows with supersedes_id.
-- ----------------------------------------------------------------------------
create table gift_intents (
    id                  uuid primary key default gen_random_uuid(),
    donor_id            uuid not null references donors(id),
    station_id          uuid not null references stations(id),
    recorded_by         uuid not null references profiles(id),
    
    -- Intent details
    intent_type         text not null,                          -- major_gift, bequest, planned_gift, restricted_gift, pledge
    stated_amount_cents bigint,                                 -- null if unspecified
    stated_amount_range text,                                   -- "between 10k-25k"
    
    -- When the gift might come
    expected_date       date,
    expected_timeframe  text,                                   -- "next fiscal year", "in my will"
    
    -- Evidence
    evidence_type       text not null,                          -- verbal, written, signed_agreement
    evidence_date       date not null,                          -- when evidence was received
    evidence_notes      text,                                   -- what exactly was said/written
    
    -- Confidence
    confidence_level    text not null default 'low',            -- low, medium, high, confirmed
    
    -- Restrictions (if any)
    has_restrictions    boolean not null default false,
    restriction_details text,
    
    -- Linked document (if signed agreement exists)
    document_id         uuid,                                   -- FK added via ALTER below
    
    -- Correction chain
    supersedes_id       uuid references gift_intents(id),
    superseded_at       timestamptz,
    
    created_at          timestamptz not null default now()
    -- Immutable: no updated_at or deleted_at
);

-- Intent type constraint
alter table gift_intents
    add constraint gift_intents_type_check
    check (intent_type in ('major_gift', 'bequest', 'planned_gift', 'restricted_gift', 'pledge', 'sponsorship'));

alter table gift_intents
    add constraint gift_intents_evidence_type_check
    check (evidence_type in ('verbal', 'written', 'email', 'signed_agreement'));

alter table gift_intents
    add constraint gift_intents_confidence_check
    check (confidence_level in ('low', 'medium', 'high', 'confirmed'));

-- Now add FK from interactions to gift_intents
alter table interactions
    add constraint interactions_gift_intent_id_fkey
    foreign key (gift_intent_id) references gift_intents(id);

-- ----------------------------------------------------------------------------
-- documents: Legal documents storage (stewardship)
-- ----------------------------------------------------------------------------
-- Stores contracts, bequests, MOUs with access control.
-- Access is logged in audit_log.
-- ----------------------------------------------------------------------------
create table documents (
    id                  uuid primary key default gen_random_uuid(),
    donor_id            uuid references donors(id),             -- null for non-donor documents
    station_id          uuid not null references stations(id),
    uploaded_by         uuid not null references profiles(id),
    
    -- Document details
    document_type       text not null,                          -- contract, bequest, mou, sponsorship, correspondence, other
    title               text not null,
    description         text,
    
    -- File storage
    file_url            text not null,                          -- Supabase Storage URL
    file_name           text not null,
    file_size_bytes     bigint,
    mime_type           text,
    
    -- Dates
    effective_date      date,
    expiration_date     date,
    signed_date         date,
    
    -- Signatories
    signed_by           text[],                                 -- names of signatories
    
    -- Access control
    visibility_level    text not null default 'station',        -- station, admin_only, super_admin_only
    
    -- Status
    status              text not null default 'active',         -- draft, active, expired, superseded
    supersedes_id       uuid references documents(id),
    
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),
    deleted_at          timestamptz
);

-- Document type constraint
alter table documents
    add constraint documents_type_check
    check (document_type in ('contract', 'bequest', 'mou', 'sponsorship', 'correspondence', 'tax_document', 'other'));

alter table documents
    add constraint documents_visibility_check
    check (visibility_level in ('station', 'admin_only', 'super_admin_only'));

alter table documents
    add constraint documents_status_check
    check (status in ('draft', 'active', 'expired', 'superseded'));

-- Now add FK from gift_intents to documents
alter table gift_intents
    add constraint gift_intents_document_id_fkey
    foreign key (document_id) references documents(id);

-- ----------------------------------------------------------------------------
-- donor_extensions: Major donor profile extensions
-- ----------------------------------------------------------------------------
-- Additional fields for major donor stewardship workflows.
-- Separate table to avoid bloating the main donors table.
-- ----------------------------------------------------------------------------
create table donor_extensions (
    id                      uuid primary key default gen_random_uuid(),
    donor_id                uuid not null unique references donors(id),
    
    -- Donor classification
    donor_type              text not null default 'standard',   -- standard, major, planned_giving, corporate, foundation
    
    -- Relationship management
    relationship_owner_id   uuid references profiles(id),       -- assigned staff member
    secondary_owner_id      uuid references profiles(id),       -- backup contact
    
    -- Capacity/propensity
    estimated_capacity_cents bigint,
    capacity_source         text,                               -- wealth screening, self-reported, research
    
    -- Risk assessment (internal only)
    risk_level              text default 'none',                -- none, low, medium, high
    risk_notes              text,
    
    -- Engagement metrics
    last_contact_date       date,
    last_gift_date          date,
    total_lifetime_cents    bigint not null default 0,
    largest_gift_cents      bigint,
    
    -- Preferences
    contact_preferences     jsonb not null default '{}',        -- preferred_channel, best_time, do_not_call, etc.
    recognition_preferences jsonb not null default '{}',        -- anonymous, name_only, full_recognition
    
    -- Special handling
    vip_flag                boolean not null default false,
    board_member            boolean not null default false,
    
    created_at              timestamptz not null default now(),
    updated_at              timestamptz not null default now()
    -- No deleted_at: tied to donor lifecycle
);

-- Donor type constraint
alter table donor_extensions
    add constraint donor_extensions_type_check
    check (donor_type in ('standard', 'major', 'planned_giving', 'corporate', 'foundation'));

alter table donor_extensions
    add constraint donor_extensions_risk_check
    check (risk_level in ('none', 'low', 'medium', 'high'));

-- ----------------------------------------------------------------------------
-- INDEXES: match_pools
-- ----------------------------------------------------------------------------
create index match_pools_station_id_idx on match_pools(station_id) where deleted_at is null;
create index match_pools_campaign_id_idx on match_pools(campaign_id) where campaign_id is not null;
create index match_pools_active_idx on match_pools(station_id, is_active)
    where deleted_at is null and remaining_cents > 0;
create index match_pools_deleted_at_idx on match_pools(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: match_allocations
-- ----------------------------------------------------------------------------
create index match_allocations_donation_id_idx on match_allocations(donation_id);
create index match_allocations_match_pool_id_idx on match_allocations(match_pool_id);
create index match_allocations_allocated_at_idx on match_allocations(allocated_at);

-- ----------------------------------------------------------------------------
-- INDEXES: interactions
-- ----------------------------------------------------------------------------
create index interactions_donor_id_idx on interactions(donor_id);
create index interactions_station_id_idx on interactions(station_id);
create index interactions_staff_user_id_idx on interactions(staff_user_id);
create index interactions_occurred_at_idx on interactions(station_id, occurred_at);
create index interactions_type_idx on interactions(station_id, interaction_type);
create index interactions_followup_idx on interactions(station_id, requires_followup, followup_completed)
    where requires_followup = true and followup_completed = false;
create index interactions_campaign_id_idx on interactions(campaign_id) where campaign_id is not null;
create index interactions_gift_intent_id_idx on interactions(gift_intent_id) where gift_intent_id is not null;

-- ----------------------------------------------------------------------------
-- INDEXES: gift_intents
-- ----------------------------------------------------------------------------
create index gift_intents_donor_id_idx on gift_intents(donor_id);
create index gift_intents_station_id_idx on gift_intents(station_id);
create index gift_intents_recorded_by_idx on gift_intents(recorded_by);
create index gift_intents_type_idx on gift_intents(station_id, intent_type);
create index gift_intents_confidence_idx on gift_intents(station_id, confidence_level);
create index gift_intents_current_idx on gift_intents(donor_id) where superseded_at is null;
create index gift_intents_document_id_idx on gift_intents(document_id) where document_id is not null;

-- ----------------------------------------------------------------------------
-- INDEXES: documents
-- ----------------------------------------------------------------------------
create index documents_donor_id_idx on documents(donor_id) where donor_id is not null and deleted_at is null;
create index documents_station_id_idx on documents(station_id) where deleted_at is null;
create index documents_uploaded_by_idx on documents(uploaded_by);
create index documents_type_idx on documents(station_id, document_type) where deleted_at is null;
create index documents_status_idx on documents(station_id, status) where deleted_at is null;
create index documents_effective_date_idx on documents(station_id, effective_date) where deleted_at is null;
create index documents_deleted_at_idx on documents(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: donor_extensions
-- ----------------------------------------------------------------------------
create index donor_extensions_donor_id_idx on donor_extensions(donor_id);
create index donor_extensions_relationship_owner_idx on donor_extensions(relationship_owner_id) 
    where relationship_owner_id is not null;
create index donor_extensions_donor_type_idx on donor_extensions(donor_type);
create index donor_extensions_vip_idx on donor_extensions(vip_flag) where vip_flag = true;
create index donor_extensions_board_idx on donor_extensions(board_member) where board_member = true;

-- ----------------------------------------------------------------------------
-- RLS: match_pools (public read for active, staff write)
-- ----------------------------------------------------------------------------
alter table match_pools enable row level security;

-- Public can see active pools (for thermometer displays)
create policy "match_pools_anon_select"
    on match_pools for select to anon
    using (deleted_at is null and is_active = true and is_public = true);

create policy "match_pools_authenticated_select"
    on match_pools for select to authenticated
    using (deleted_at is null);

create policy "match_pools_service_role_all"
    on match_pools for all to service_role
    using (true) with check (true);

-- ----------------------------------------------------------------------------
-- RLS: match_allocations
-- ----------------------------------------------------------------------------
alter table match_allocations enable row level security;

create policy "match_allocations_anon_deny_all"
    on match_allocations for all to anon
    using (false);

create policy "match_allocations_authenticated_select"
    on match_allocations for select to authenticated
    using (
        exists (
            select 1 from profiles p
            join donations d on d.station_id = p.station_id
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and d.id = match_allocations.donation_id
            and p.role in ('super_admin', 'admin', 'ops')
        )
    );

create policy "match_allocations_service_role_all"
    on match_allocations for all to service_role
    using (true) with check (true);

-- ----------------------------------------------------------------------------
-- RLS: interactions (sensitive stewardship data)
-- ----------------------------------------------------------------------------
alter table interactions enable row level security;

create policy "interactions_anon_deny_all"
    on interactions for all to anon
    using (false);

-- Only ops+ can read interactions
create policy "interactions_staff_select"
    on interactions for select to authenticated
    using (
        exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and (p.role = 'super_admin' or (p.role in ('admin', 'ops') and p.station_id = interactions.station_id))
        )
    );

create policy "interactions_service_role_all"
    on interactions for all to service_role
    using (true) with check (true);

-- ----------------------------------------------------------------------------
-- RLS: gift_intents (sensitive)
-- ----------------------------------------------------------------------------
alter table gift_intents enable row level security;

create policy "gift_intents_anon_deny_all"
    on gift_intents for all to anon
    using (false);

create policy "gift_intents_staff_select"
    on gift_intents for select to authenticated
    using (
        exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and (p.role = 'super_admin' or (p.role in ('admin', 'ops') and p.station_id = gift_intents.station_id))
        )
    );

create policy "gift_intents_service_role_all"
    on gift_intents for all to service_role
    using (true) with check (true);

-- ----------------------------------------------------------------------------
-- RLS: documents (access-controlled)
-- ----------------------------------------------------------------------------
alter table documents enable row level security;

create policy "documents_anon_deny_all"
    on documents for all to anon
    using (false);

-- Station-level docs: all station staff
-- Admin-only docs: admin+
-- Super-admin-only: super_admin only
create policy "documents_staff_select"
    on documents for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and (
                (p.role = 'super_admin')
                or (p.role = 'admin' and p.station_id = documents.station_id and documents.visibility_level in ('station', 'admin_only'))
                or (p.role = 'ops' and p.station_id = documents.station_id and documents.visibility_level = 'station')
            )
        )
    );

create policy "documents_service_role_all"
    on documents for all to service_role
    using (true) with check (true);

-- ----------------------------------------------------------------------------
-- RLS: donor_extensions (sensitive)
-- ----------------------------------------------------------------------------
alter table donor_extensions enable row level security;

create policy "donor_extensions_anon_deny_all"
    on donor_extensions for all to anon
    using (false);

create policy "donor_extensions_staff_select"
    on donor_extensions for select to authenticated
    using (
        exists (
            select 1 from profiles p
            join donors d on d.station_id = p.station_id
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and d.id = donor_extensions.donor_id
            and p.role in ('super_admin', 'admin', 'ops')
        )
    );

create policy "donor_extensions_service_role_all"
    on donor_extensions for all to service_role
    using (true) with check (true);

-- ----------------------------------------------------------------------------
-- TRIGGERS: updated_at
-- ----------------------------------------------------------------------------
create trigger match_pools_updated_at before update on match_pools
    for each row execute function update_updated_at();
create trigger documents_updated_at before update on documents
    for each row execute function update_updated_at();
create trigger donor_extensions_updated_at before update on donor_extensions
    for each row execute function update_updated_at();

-- ============================================================================
-- End of Phase 007
-- Next: 008_m5_underwriting_tables.sql (Underwriting)
-- ============================================================================
