-- ============================================================================
-- PHASE 008: M5 Underwriting Tables
-- ============================================================================
-- Creates underwriting/sponsorship system tables.
-- Tables: underwriters, underwriting_agreements, underwriting_invoices,
--         underwriting_broadcasts
--
-- Note: Underwriting is a contractual exchange (not a charitable gift),
-- with different tax treatment than donations.
--
-- Run AFTER 007_m4_stewardship_tables.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- underwriters: Underwriting organizations
-- ----------------------------------------------------------------------------
-- Separate from donors table because underwriters are typically businesses
-- or organizations, not individuals making charitable gifts.
-- ----------------------------------------------------------------------------
create table underwriters (
    id                  uuid primary key default gen_random_uuid(),
    station_id          uuid not null references stations(id),
    
    -- Organization info
    name                text not null,
    legal_name          text,                                   -- for invoicing
    organization_type   text not null default 'business',       -- business, nonprofit, government, individual
    
    -- Tax/billing info
    tax_id              text,                                   -- EIN/TIN for invoicing
    
    -- Primary contact
    contact_name        text,
    contact_email       text,
    contact_phone       text,
    contact_title       text,
    
    -- Address
    street_line_1       text,
    street_line_2       text,
    city                text,
    state               text,
    postal_code         text,
    country             text default 'US',
    
    -- Billing address (if different)
    billing_same_as_primary boolean not null default true,
    billing_street_1    text,
    billing_street_2    text,
    billing_city        text,
    billing_state       text,
    billing_postal      text,
    billing_country     text,
    
    -- Relationship
    relationship_owner_id uuid references profiles(id),
    
    -- Status
    is_active           boolean not null default true,
    
    -- Notes
    notes               text,
    
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),
    deleted_at          timestamptz
);

-- Organization type constraint
alter table underwriters
    add constraint underwriters_org_type_check
    check (organization_type in ('business', 'nonprofit', 'government', 'individual'));

-- ----------------------------------------------------------------------------
-- underwriting_agreements: Underwriting contracts
-- ----------------------------------------------------------------------------
-- Tracks contracted underwriting campaigns with value, schedule, and terms.
-- ----------------------------------------------------------------------------
create table underwriting_agreements (
    id                  uuid primary key default gen_random_uuid(),
    station_id          uuid not null references stations(id),
    underwriter_id      uuid not null references underwriters(id),
    
    -- Agreement details
    name                text not null,                          -- "Q1 2025 Sponsorship"
    description         text,
    
    -- Contract document
    document_id         uuid references documents(id),
    
    -- Value
    total_value_cents   bigint not null,
    
    -- Term
    starts_at           date not null,
    ends_at             date not null,
    
    -- Payment terms
    payment_schedule    text not null default 'monthly',        -- upfront, monthly, quarterly, custom
    payment_terms_days  integer not null default 30,            -- net 30
    
    -- Deliverables (what they get)
    deliverables        jsonb not null default '{}',            -- spots_per_week, show_ids, event_mentions, etc.
    
    -- Status
    status              text not null default 'draft',          -- draft, pending_signature, active, completed, cancelled
    signed_at           date,
    
    -- Renewal
    auto_renew          boolean not null default false,
    renewal_notice_days integer,
    
    -- Notes
    internal_notes      text,
    
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),
    deleted_at          timestamptz
);

-- Status constraint
alter table underwriting_agreements
    add constraint underwriting_agreements_status_check
    check (status in ('draft', 'pending_signature', 'active', 'completed', 'cancelled'));

-- Payment schedule constraint
alter table underwriting_agreements
    add constraint underwriting_agreements_payment_check
    check (payment_schedule in ('upfront', 'monthly', 'quarterly', 'annual', 'custom'));

-- ----------------------------------------------------------------------------
-- underwriting_invoices: Invoices for underwriting
-- ----------------------------------------------------------------------------
-- Different from donation receipts: these are commercial invoices for services.
-- ----------------------------------------------------------------------------
create table underwriting_invoices (
    id                  uuid primary key default gen_random_uuid(),
    station_id          uuid not null references stations(id),
    agreement_id        uuid not null references underwriting_agreements(id),
    underwriter_id      uuid not null references underwriters(id),  -- denormalized for queries
    
    -- Invoice details
    invoice_number      text not null,                          -- "INV-2025-0001"
    description         text,
    
    -- Amounts
    subtotal_cents      bigint not null,
    tax_cents           bigint not null default 0,
    total_cents         bigint not null,
    
    -- Line items
    line_items          jsonb not null default '[]',            -- [{description, quantity, unit_price_cents, total_cents}]
    
    -- Dates
    invoice_date        date not null,
    due_date            date not null,
    period_start        date,                                   -- billing period
    period_end          date,
    
    -- Payment status
    status              text not null default 'draft',          -- draft, sent, viewed, paid, overdue, void, written_off
    sent_at             timestamptz,
    paid_at             timestamptz,
    paid_amount_cents   bigint,
    payment_method      text,                                   -- check, wire, ach, credit_card
    payment_reference   text,                                   -- check number, transaction ID
    
    -- Reminders
    reminder_sent_at    timestamptz,
    reminders_count     integer not null default 0,
    
    -- Notes
    notes               text,
    internal_notes      text,
    
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),
    deleted_at          timestamptz
);

-- Status constraint
alter table underwriting_invoices
    add constraint underwriting_invoices_status_check
    check (status in ('draft', 'sent', 'viewed', 'paid', 'overdue', 'void', 'written_off'));

-- Unique invoice numbers per station
create unique index underwriting_invoices_number_idx 
    on underwriting_invoices(station_id, invoice_number) 
    where deleted_at is null;

-- ----------------------------------------------------------------------------
-- underwriting_broadcasts: Scheduled broadcast spots
-- ----------------------------------------------------------------------------
-- Tracks scheduled and aired underwriting credits.
-- ----------------------------------------------------------------------------
create table underwriting_broadcasts (
    id                  uuid primary key default gen_random_uuid(),
    station_id          uuid not null references stations(id),
    agreement_id        uuid not null references underwriting_agreements(id),
    
    -- Show/slot assignment
    show_id             uuid references shows(id),
    
    -- Timing
    scheduled_at        timestamptz not null,                   -- when it should air
    scheduled_duration_seconds integer not null default 15,     -- standard 15s credit
    
    -- Actual airing
    aired_at            timestamptz,
    actual_duration_seconds integer,
    
    -- Content
    copy_text           text,                                   -- the underwriting credit script
    copy_approved       boolean not null default false,
    copy_approved_at    timestamptz,
    copy_approved_by    uuid references profiles(id),
    
    -- Status
    status              text not null default 'scheduled',      -- scheduled, aired, missed, cancelled
    
    -- Notes
    notes               text,
    
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now()
    -- No deleted_at: historical record
);

-- Status constraint
alter table underwriting_broadcasts
    add constraint underwriting_broadcasts_status_check
    check (status in ('scheduled', 'aired', 'missed', 'cancelled'));

-- ----------------------------------------------------------------------------
-- INDEXES: underwriters
-- ----------------------------------------------------------------------------
create index underwriters_station_id_idx on underwriters(station_id) where deleted_at is null;
create index underwriters_name_idx on underwriters(station_id, name) where deleted_at is null;
create index underwriters_is_active_idx on underwriters(station_id, is_active) where deleted_at is null;
create index underwriters_relationship_owner_idx on underwriters(relationship_owner_id) 
    where relationship_owner_id is not null;
create index underwriters_deleted_at_idx on underwriters(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: underwriting_agreements
-- ----------------------------------------------------------------------------
create index uw_agreements_station_id_idx on underwriting_agreements(station_id) where deleted_at is null;
create index uw_agreements_underwriter_id_idx on underwriting_agreements(underwriter_id) where deleted_at is null;
create index uw_agreements_document_id_idx on underwriting_agreements(document_id) where document_id is not null;
create index uw_agreements_status_idx on underwriting_agreements(station_id, status) where deleted_at is null;
create index uw_agreements_dates_idx on underwriting_agreements(station_id, starts_at, ends_at) where deleted_at is null;
create index uw_agreements_active_idx on underwriting_agreements(station_id)
    where deleted_at is null and status = 'active';
create index uw_agreements_deleted_at_idx on underwriting_agreements(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: underwriting_invoices
-- ----------------------------------------------------------------------------
create index uw_invoices_station_id_idx on underwriting_invoices(station_id) where deleted_at is null;
create index uw_invoices_agreement_id_idx on underwriting_invoices(agreement_id) where deleted_at is null;
create index uw_invoices_underwriter_id_idx on underwriting_invoices(underwriter_id) where deleted_at is null;
create index uw_invoices_status_idx on underwriting_invoices(station_id, status) where deleted_at is null;
create index uw_invoices_due_date_idx on underwriting_invoices(station_id, due_date) where deleted_at is null;
create index uw_invoices_overdue_idx on underwriting_invoices(station_id, due_date)
    where deleted_at is null and status in ('sent', 'viewed', 'overdue');
create index uw_invoices_deleted_at_idx on underwriting_invoices(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: underwriting_broadcasts
-- ----------------------------------------------------------------------------
create index uw_broadcasts_station_id_idx on underwriting_broadcasts(station_id);
create index uw_broadcasts_agreement_id_idx on underwriting_broadcasts(agreement_id);
create index uw_broadcasts_show_id_idx on underwriting_broadcasts(show_id) where show_id is not null;
create index uw_broadcasts_scheduled_at_idx on underwriting_broadcasts(station_id, scheduled_at);
create index uw_broadcasts_status_idx on underwriting_broadcasts(station_id, status);
create index uw_broadcasts_pending_idx on underwriting_broadcasts(station_id, scheduled_at)
    where status = 'scheduled';
create index uw_broadcasts_copy_approval_idx on underwriting_broadcasts(station_id, copy_approved)
    where status = 'scheduled' and copy_approved = false;

-- ----------------------------------------------------------------------------
-- RLS: underwriters
-- ----------------------------------------------------------------------------
alter table underwriters enable row level security;

create policy "underwriters_anon_deny_all"
    on underwriters for all to anon
    using (false);

create policy "underwriters_staff_select"
    on underwriters for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and (p.role = 'super_admin' or (p.role in ('admin', 'ops') and p.station_id = underwriters.station_id))
        )
    );

create policy "underwriters_service_role_all"
    on underwriters for all to service_role
    using (true) with check (true);

-- ----------------------------------------------------------------------------
-- RLS: underwriting_agreements
-- ----------------------------------------------------------------------------
alter table underwriting_agreements enable row level security;

create policy "uw_agreements_anon_deny_all"
    on underwriting_agreements for all to anon
    using (false);

create policy "uw_agreements_staff_select"
    on underwriting_agreements for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and (p.role = 'super_admin' or (p.role in ('admin', 'ops') and p.station_id = underwriting_agreements.station_id))
        )
    );

create policy "uw_agreements_service_role_all"
    on underwriting_agreements for all to service_role
    using (true) with check (true);

-- ----------------------------------------------------------------------------
-- RLS: underwriting_invoices
-- ----------------------------------------------------------------------------
alter table underwriting_invoices enable row level security;

create policy "uw_invoices_anon_deny_all"
    on underwriting_invoices for all to anon
    using (false);

create policy "uw_invoices_staff_select"
    on underwriting_invoices for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and (p.role = 'super_admin' or (p.role in ('admin', 'ops') and p.station_id = underwriting_invoices.station_id))
        )
    );

create policy "uw_invoices_service_role_all"
    on underwriting_invoices for all to service_role
    using (true) with check (true);

-- ----------------------------------------------------------------------------
-- RLS: underwriting_broadcasts
-- ----------------------------------------------------------------------------
alter table underwriting_broadcasts enable row level security;

create policy "uw_broadcasts_anon_deny_all"
    on underwriting_broadcasts for all to anon
    using (false);

create policy "uw_broadcasts_staff_select"
    on underwriting_broadcasts for select to authenticated
    using (
        exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and (p.role = 'super_admin' or (p.role in ('admin', 'ops') and p.station_id = underwriting_broadcasts.station_id))
        )
    );

create policy "uw_broadcasts_service_role_all"
    on underwriting_broadcasts for all to service_role
    using (true) with check (true);

-- ----------------------------------------------------------------------------
-- TRIGGERS: updated_at
-- ----------------------------------------------------------------------------
create trigger underwriters_updated_at before update on underwriters
    for each row execute function update_updated_at();
create trigger uw_agreements_updated_at before update on underwriting_agreements
    for each row execute function update_updated_at();
create trigger uw_invoices_updated_at before update on underwriting_invoices
    for each row execute function update_updated_at();
create trigger uw_broadcasts_updated_at before update on underwriting_broadcasts
    for each row execute function update_updated_at();

-- ============================================================================
-- End of Phase 008
-- ============================================================================
-- 
-- MIGRATION COMPLETE!
--
-- Summary of all phases:
--   001: M0 base tables (donation pipeline)
--   002: M0 foreign keys + indexes
--   003: M0 RLS policies (PII protection)
--   004: M1 tables (staff CRM)
--   005: M1 FKs, indexes, RLS, triggers
--   006: M3 events & tickets
--   007: M4 matching & stewardship
--   008: M5 underwriting
--
-- Total tables: 29
--   - Core: stations, shows, campaigns, donors, donations, gifts, memberships
--   - Pre-payment: checkout_sessions
--   - Audit: audit_log, system_events, email_log, tax_documents
--   - CRM: profiles, addresses, gift_variants, fulfillment_items, donor_notes, donor_tags
--   - Events: events, ticket_types, promo_codes, event_registrations, event_registration_gifts
--   - Stewardship: match_pools, match_allocations, interactions, gift_intents, documents, donor_extensions
--   - Underwriting: underwriters, underwriting_agreements, underwriting_invoices, underwriting_broadcasts
--
-- ============================================================================
