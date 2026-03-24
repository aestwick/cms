-- ============================================================================
-- PHASE 004: M1 Base Tables (Staff CRM)
-- ============================================================================
-- Creates tables for "Operator View" milestone: auth, donor management,
-- fulfillment queue, and tagging.
--
-- Tables: profiles, addresses, gift_variants, fulfillment_items, 
--         donor_notes, donor_tags
--
-- Run AFTER 003_m0_rls_policies.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- profiles: User accounts linked to Supabase Auth
-- ----------------------------------------------------------------------------
-- Maps auth.users to our application roles and station scoping.
-- Created automatically via trigger on auth.users insert (see Phase 005).
-- ----------------------------------------------------------------------------
create table profiles (
    id              uuid primary key,                           -- = auth.users.id
    
    -- Role & access
    role            text not null default 'volunteer',          -- super_admin, admin, ops, volunteer, donor
    station_id      uuid,                                       -- FK added in phase 005; null for super_admin
    
    -- Link to donor record (for donor role self-service)
    donor_id        uuid,                                       -- FK added in phase 005
    
    -- Profile info
    display_name    text,
    email           text not null,                              -- copied from auth.users
    phone           text,
    avatar_url      text,
    
    -- Security
    requires_2fa    boolean not null default false,             -- true for super_admin
    last_login_at   timestamptz,
    
    -- Status
    is_active       boolean not null default true,
    
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz
);

-- Role constraint
alter table profiles
    add constraint profiles_role_check
    check (role in ('super_admin', 'admin', 'ops', 'volunteer', 'donor'));

-- ----------------------------------------------------------------------------
-- addresses: Donor address book
-- ----------------------------------------------------------------------------
-- Supports multiple addresses per donor (billing, shipping, gift recipient).
-- Gift recipients may not yet be donors themselves.
-- ----------------------------------------------------------------------------
create table addresses (
    id              uuid primary key default gen_random_uuid(),
    donor_id        uuid not null,                              -- FK added in phase 005
    
    -- Address type
    address_type    text not null default 'shipping',           -- billing, shipping, gift_recipient
    label           text,                                       -- "Home", "Office", "Mom's house"
    
    -- Recipient (for gift addresses, may differ from donor)
    recipient_name  text,
    recipient_email text,
    recipient_phone text,
    
    -- Address fields
    street_line_1   text not null,
    street_line_2   text,
    city            text not null,
    state           text not null,                              -- state/province code
    postal_code     text not null,
    country         text not null default 'US',
    
    -- Defaults (only one of each type can be default)
    is_default      boolean not null default false,
    
    -- Validation
    is_verified     boolean not null default false,
    verified_at     timestamptz,
    
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz
);

-- Address type constraint
alter table addresses
    add constraint addresses_type_check
    check (address_type in ('billing', 'shipping', 'gift_recipient'));

-- ----------------------------------------------------------------------------
-- gift_variants: Sizes/colors per gift (premium variants)
-- ----------------------------------------------------------------------------
create table gift_variants (
    id              uuid primary key default gen_random_uuid(),
    gift_id         uuid not null,                              -- FK added in phase 005
    
    -- Variant details
    name            text not null,                              -- "Large", "Blue", "Hardcover"
    sku             text,                                       -- for inventory tracking
    
    -- Inventory (null = unlimited, e.g., digital goods)
    inventory_count integer,                                    -- current stock; null = unlimited
    low_stock_threshold integer,                                -- alert when below this
    
    -- Display
    sort_order      integer not null default 0,
    is_active       boolean not null default true,
    
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz
);

-- ----------------------------------------------------------------------------
-- fulfillment_items: Shipping/delivery queue
-- ----------------------------------------------------------------------------
-- Tracks physical premium fulfillment. One row per gift in a donation.
-- Status workflow: pending → assigned → processing → shipped → delivered
-- (or: pending → cancelled)
-- ----------------------------------------------------------------------------
create table fulfillment_items (
    id                  uuid primary key default gen_random_uuid(),
    donation_id         uuid not null,                          -- FK added in phase 005
    gift_variant_id     uuid not null,                          -- FK added in phase 005
    
    -- Quantity
    quantity            integer not null default 1,
    
    -- Shipping address (snapshot at time of donation, or FK to addresses)
    address_id          uuid,                                   -- FK added in phase 005
    address_snapshot    jsonb,                                  -- fallback if no address_id
    
    -- Assignment
    assigned_to         uuid,                                   -- FK to profiles
    assigned_at         timestamptz,
    
    -- Status workflow
    status              text not null default 'pending',        -- pending, assigned, processing, shipped, delivered, cancelled
    
    -- Shipping details
    carrier             text,                                   -- 'usps', 'ups', 'fedex', 'hand_delivery'
    tracking_number     text,
    tracking_url        text,
    
    -- Status timestamps
    processing_at       timestamptz,
    shipped_at          timestamptz,
    delivered_at        timestamptz,
    cancelled_at        timestamptz,
    cancellation_reason text,
    
    -- Notes
    internal_notes      text,
    
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),
    deleted_at          timestamptz
);

-- Status constraint
alter table fulfillment_items
    add constraint fulfillment_items_status_check
    check (status in ('pending', 'assigned', 'processing', 'shipped', 'delivered', 'cancelled'));

-- ----------------------------------------------------------------------------
-- donor_notes: Notes on donor records
-- ----------------------------------------------------------------------------
-- Both internal staff notes and donor-visible notes.
-- Append-only recommended; edits create new notes with supersedes_id.
-- ----------------------------------------------------------------------------
create table donor_notes (
    id              uuid primary key default gen_random_uuid(),
    donor_id        uuid not null,                              -- FK added in phase 005
    author_id       uuid,                                       -- FK to profiles (null for system notes)
    
    -- Note content
    note_type       text not null default 'internal',           -- internal, donor_visible, system
    subject         text,
    body            text not null,
    
    -- For corrections/edits
    supersedes_id   uuid,                                       -- FK to donor_notes (previous version)
    
    -- Flags
    is_pinned       boolean not null default false,
    
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz
);

-- Note type constraint
alter table donor_notes
    add constraint donor_notes_type_check
    check (note_type in ('internal', 'donor_visible', 'system'));

-- ----------------------------------------------------------------------------
-- donor_tags: Tags for donor segmentation
-- ----------------------------------------------------------------------------
-- Freeform labels for filtering and outreach segmentation.
-- Examples: "major_donor", "student", "la_local", "board_member", "do_not_solicit"
-- ----------------------------------------------------------------------------
create table donor_tags (
    id              uuid primary key default gen_random_uuid(),
    donor_id        uuid not null,                              -- FK added in phase 005
    
    -- Tag content
    tag             text not null,                              -- lowercase, normalized
    
    -- Who applied it
    applied_by      uuid,                                       -- FK to profiles (null for imports)
    
    created_at      timestamptz not null default now(),
    deleted_at      timestamptz
    -- No updated_at: tags are add/remove only
    -- Unique constraint enforced via partial unique index in 005
);

-- ============================================================================
-- End of Phase 004
-- Next: 005_m1_fks_indexes_rls.sql (FKs, indexes, RLS, and triggers)
-- ============================================================================
