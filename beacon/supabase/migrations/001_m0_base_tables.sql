-- ============================================================================
-- PHASE 001: M0 Base Tables (PKs + columns only, no foreign keys)
-- ============================================================================
-- Creates core donation pipeline tables for "Closed Loop" milestone.
-- Tables: stations, shows, campaigns, donors, donations, gifts, memberships,
--         checkout_sessions, audit_log, system_events, email_log, tax_documents
--
-- Assumptions:
--   - Clean slate (no existing tables)
--   - All IDs are UUIDs with gen_random_uuid() default
--   - Soft deletes via deleted_at (timestamptz)
--   - Timestamps use timestamptz (UTC storage, TZ-aware)
--   - Money stored as integer cents (*_cents columns)
-- ============================================================================

-- Enable required extensions
create extension if not exists "uuid-ossp";

-- ----------------------------------------------------------------------------
-- stations: Radio stations in the Pacifica network
-- ----------------------------------------------------------------------------
create table stations (
    id              uuid primary key default gen_random_uuid(),
    code            text not null unique,                       -- 'kpfk', 'kpfa', 'wbai'
    call_sign       text not null,                              -- 'KPFK'
    name            text not null,                              -- 'KPFK 90.7 FM Los Angeles'
    timezone        text not null default 'America/Los_Angeles',
    website_url     text,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz
);

-- ----------------------------------------------------------------------------
-- shows: Programs/shows per station
-- ----------------------------------------------------------------------------
create table shows (
    id              uuid primary key default gen_random_uuid(),
    station_id      uuid not null,                              -- FK added in phase 002
    slug            text not null,                              -- 'uprising', 'background-briefing'
    name            text not null,
    description     text,
    host_name       text,
    is_active       boolean not null default true,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz
);

-- ----------------------------------------------------------------------------
-- campaigns: Fundraising campaigns (fund drives, events, evergreen, appeals)
-- ----------------------------------------------------------------------------
create table campaigns (
    id              uuid primary key default gen_random_uuid(),
    station_id      uuid not null,                              -- FK added in phase 002
    code            text not null,                              -- 'fall-2025', 'hedges-event'
    name            text not null,
    campaign_type   text not null default 'fund_drive',         -- fund_drive, event, evergreen, special_appeal
    description     text,
    starts_at       timestamptz,
    ends_at         timestamptz,
    goal_cents      bigint,                                     -- revenue goal
    goal_donors     integer,                                    -- donor count goal
    goal_sustainers integer,                                    -- new sustainer goal
    is_active       boolean not null default false,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz
);

-- ----------------------------------------------------------------------------
-- donors: People who donate (per-station uniqueness)
-- ----------------------------------------------------------------------------
create table donors (
    id                      uuid primary key default gen_random_uuid(),
    station_id              uuid not null,                      -- FK added in phase 002
    
    -- Contact info
    email                   text not null,                      -- as entered
    email_normalized        text not null,                      -- lowercase, trimmed
    first_name              text,
    last_name               text,
    phone                   text,
    
    -- Stripe link
    stripe_customer_id      text,                               -- cus_xxx
    
    -- Preferences (jsonb for flexibility)
    preferences             jsonb not null default '{}',        -- email_opt_in, sms_opt_in, mail_opt_in, etc.
    
    -- Metadata
    source                  text,                               -- how they first found us
    created_at              timestamptz not null default now(),
    updated_at              timestamptz not null default now(),
    deleted_at              timestamptz
    -- Per-station uniqueness enforced via partial unique index in 002
);

-- ----------------------------------------------------------------------------
-- gifts: Premium catalog (thank-you gifts)
-- ----------------------------------------------------------------------------
create table gifts (
    id                      uuid primary key default gen_random_uuid(),
    station_id              uuid not null,                      -- FK added in phase 002
    name                    text not null,
    description             text,
    category                text,                               -- 'book', 'ticket', 'merch', 'digital'
    minimum_cents           bigint not null default 0,          -- min donation to qualify
    fmv_cents               bigint not null default 0,          -- fair market value for IRS
    is_active               boolean not null default true,
    sort_order              integer not null default 0,
    created_at              timestamptz not null default now(),
    updated_at              timestamptz not null default now(),
    deleted_at              timestamptz
);

-- ----------------------------------------------------------------------------
-- memberships: Recurring membership records (linked to Stripe subscriptions)
-- ----------------------------------------------------------------------------
create table memberships (
    id                      uuid primary key default gen_random_uuid(),
    donor_id                uuid not null,                      -- FK added in phase 002
    station_id              uuid not null,                      -- FK added in phase 002 (denormalized for queries)
    
    -- Stripe link
    stripe_subscription_id  text,                               -- sub_xxx
    
    -- Membership details
    tier                    text not null default 'member',     -- member, sustainer, defender
    amount_cents            bigint not null,                    -- monthly amount
    status                  text not null default 'active',     -- active, paused, cancelled, lapsed
    
    -- Lifecycle dates
    started_at              timestamptz not null default now(),
    cancelled_at            timestamptz,
    lapsed_at               timestamptz,                        -- when marked lapsed
    
    -- Payment failure tracking
    payment_failed_at       timestamptz,
    payment_failures_count  integer not null default 0,
    
    created_at              timestamptz not null default now(),
    updated_at              timestamptz not null default now(),
    deleted_at              timestamptz
);

-- Membership tier constraint
alter table memberships
    add constraint memberships_tier_check
    check (tier in ('member', 'sustainer', 'defender'));

-- Membership status constraint
alter table memberships
    add constraint memberships_status_check
    check (status in ('active', 'paused', 'cancelled', 'lapsed'));

-- ----------------------------------------------------------------------------
-- checkout_sessions: Pre-payment staging (bridges form → Stripe → donation)
-- ----------------------------------------------------------------------------
create table checkout_sessions (
    id                          uuid primary key default gen_random_uuid(),
    station_id                  uuid not null,                  -- FK added in phase 002
    
    -- Stripe link (null for cash/check pledges)
    stripe_checkout_session_id  text unique,                    -- cs_xxx
    
    -- Mode determines workflow
    mode                        text not null,                  -- web, phone_card, phone_check, phone_cash
    operator_id                 uuid,                           -- FK to profiles (null for web self-service)
    
    -- Status workflow
    status                      text not null default 'pending', -- pending, completed, expired, cancelled, failed
    
    -- Snapshots (raw data from step 1, before donor/donation records exist)
    donor_snapshot              jsonb not null default '{}',    -- email, name, phone, address
    donation_snapshot           jsonb not null default '{}',    -- amount, campaign, show, gift, fees, utm, etc.
    
    -- Linked records (populated after completion)
    donor_id                    uuid,                           -- FK added in phase 002
    donation_id                 uuid,                           -- FK added in phase 002
    
    -- Lifecycle
    expires_at                  timestamptz,                    -- for cleanup of abandoned sessions
    completed_at                timestamptz,
    
    created_at                  timestamptz not null default now(),
    updated_at                  timestamptz not null default now()
    -- No deleted_at: we keep all sessions for audit trail
);

-- Checkout session mode constraint
alter table checkout_sessions
    add constraint checkout_sessions_mode_check
    check (mode in ('web', 'phone_card', 'phone_check', 'phone_cash'));

-- Checkout session status constraint
alter table checkout_sessions
    add constraint checkout_sessions_status_check
    check (status in ('pending', 'completed', 'expired', 'cancelled', 'failed'));

-- ----------------------------------------------------------------------------
-- donations: Individual donation transactions
-- ----------------------------------------------------------------------------
create table donations (
    id                      uuid primary key default gen_random_uuid(),
    donor_id                uuid not null,                      -- FK added in phase 002
    station_id              uuid not null,                      -- FK added in phase 002 (denormalized)
    checkout_session_id     uuid,                               -- FK added in phase 002
    
    -- Attribution
    campaign_id             uuid,                               -- FK added in phase 002
    show_id                 uuid,                               -- FK added in phase 002
    gift_id                 uuid,                               -- FK added in phase 002 (selected premium)
    
    -- Money
    amount_cents            bigint not null,                    -- donation amount
    fee_coverage_cents      bigint not null default 0,          -- optional fee offset
    currency                text not null default 'usd',
    
    -- Payment details
    payment_provider        text not null,                      -- stripe, check, cash
    payment_method_type     text,                               -- card, us_bank_account, etc.
    stripe_payment_intent_id text,                              -- pi_xxx
    check_number            text,                               -- for check payments
    
    -- Status workflow
    status                  text not null default 'pending',    -- pending, processing, succeeded, failed, refunded
    
    -- Operator tracking (null for web self-service)
    operator_id             uuid,                               -- FK to profiles
    
    -- Source tracking
    source_code             text,                               -- on-air promo code
    utm_source              text,
    utm_medium              text,
    utm_campaign            text,
    referrer_url            text,
    
    -- Timestamps
    received_at             timestamptz,                        -- when payment confirmed
    created_at              timestamptz not null default now(),
    updated_at              timestamptz not null default now(),
    deleted_at              timestamptz
);

-- Donation payment provider constraint
alter table donations
    add constraint donations_payment_provider_check
    check (payment_provider in ('stripe', 'check', 'cash'));

-- Donation status constraint
alter table donations
    add constraint donations_status_check
    check (status in ('pending', 'processing', 'succeeded', 'failed', 'refunded'));

-- ----------------------------------------------------------------------------
-- tax_documents: Immutable receipt snapshots (never updated, only superseded)
-- ----------------------------------------------------------------------------
create table tax_documents (
    id                      uuid primary key default gen_random_uuid(),
    donation_id             uuid not null,                      -- FK added in phase 002
    donor_id                uuid not null,                      -- FK added in phase 002 (denormalized)
    station_id              uuid not null,                      -- FK added in phase 002 (denormalized)
    
    -- Document content (immutable snapshot)
    document_type           text not null default 'receipt',    -- receipt, annual_summary, correction
    snapshot_json           jsonb not null,                     -- full receipt data at time of generation
    
    -- Calculated values
    gross_amount_cents      bigint not null,
    fmv_cents               bigint not null default 0,          -- fair market value of premiums
    deductible_cents        bigint not null,                    -- gross - fmv
    
    -- Correction chain
    supersedes_id           uuid,                               -- FK to tax_documents (for corrections)
    superseded_at           timestamptz,                        -- when this doc was superseded
    
    -- Metadata
    generated_at            timestamptz not null default now(),
    created_at              timestamptz not null default now()
    -- No updated_at or deleted_at: immutable by design
);

-- ----------------------------------------------------------------------------
-- email_log: Sent email tracking (for dispute resolution)
-- ----------------------------------------------------------------------------
create table email_log (
    id                      uuid primary key default gen_random_uuid(),
    station_id              uuid not null,                      -- FK added in phase 002
    donor_id                uuid,                               -- FK added in phase 002 (null for system emails)
    donation_id             uuid,                               -- FK added in phase 002 (if donation-related)
    
    -- Email details
    template_name           text not null,                      -- 'donation_receipt', 'welcome', 'payment_failed'
    template_version        text,                               -- 'v3'
    recipient_email         text not null,
    subject                 text,
    
    -- External tracking
    external_id             text,                               -- Resend message ID
    
    -- Status
    status                  text not null default 'pending',    -- pending, sent, delivered, bounced, failed
    status_detail           text,                               -- error message if failed
    
    sent_at                 timestamptz,
    delivered_at            timestamptz,
    created_at              timestamptz not null default now()
    -- No updated_at/deleted_at: append-only log
);

-- Email log status constraint
alter table email_log
    add constraint email_log_status_check
    check (status in ('pending', 'sent', 'delivered', 'bounced', 'failed'));

-- ----------------------------------------------------------------------------
-- audit_log: Who changed what (immutable, field-level diffs)
-- ----------------------------------------------------------------------------
create table audit_log (
    id                      uuid primary key default gen_random_uuid(),
    station_id              uuid,                               -- FK added in phase 002 (null for system-wide)
    user_id                 uuid,                               -- FK to profiles (null for system actions)
    
    -- What changed
    action                  text not null,                      -- insert, update, delete, login, export, etc.
    table_name              text not null,
    record_id               uuid,                               -- PK of affected record
    
    -- Before/after snapshots (field-level diffs)
    old_data                jsonb,
    new_data                jsonb,
    
    -- Context
    ip_address              inet,
    user_agent              text,
    
    created_at              timestamptz not null default now()
    -- Immutable: no updated_at or deleted_at
);

-- ----------------------------------------------------------------------------
-- system_events: Webhook/automation logs (append-only, idempotent)
-- ----------------------------------------------------------------------------
create table system_events (
    id                      uuid primary key default gen_random_uuid(),
    
    -- Event identification
    event_type              text not null,                      -- stripe.checkout.session.completed, etc.
    source                  text not null,                      -- stripe, n8n, manual_import, ghost
    idempotency_key         text not null unique,               -- Stripe event.id or custom key
    
    -- Payload (nullable to allow summary-only retention after aging)
    payload                 jsonb default '{}',                 -- full webhook payload; nullable for retention
    payload_summary         text,                               -- brief summary for debugging after payload purged
    
    -- Processing status
    status                  text not null default 'pending',    -- pending, processing, completed, failed, skipped
    error_message           text,
    attempts                integer not null default 0,
    
    -- Timestamps
    processed_at            timestamptz,
    created_at              timestamptz not null default now()
    -- Append-only: no updated_at or deleted_at
);

-- System events status constraint
alter table system_events
    add constraint system_events_status_check
    check (status in ('pending', 'processing', 'completed', 'failed', 'skipped'));

-- ============================================================================
-- End of Phase 001
-- Next: 002_m0_fks_indexes.sql (foreign keys + indexes)
-- ============================================================================
