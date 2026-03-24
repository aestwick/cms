-- ============================================================================
-- Migration 052: M3 Events & Tickets — Full Schema
-- ============================================================================
-- Evolves the simple M3 event tables (migration 006) to match the finalized
-- spec at build plans/beacon_m3_events_tickets_spec.md.
--
-- Migration 006 created 5 basic tables: events, ticket_types, promo_codes,
-- event_registrations, event_registration_gifts. Those tables exist in the
-- live database but contain NO data (M3 hasn't launched).
--
-- This migration:
--   A. Creates 10 new tables (venues, event_series, event_orders, etc.)
--   B. Alters events, ticket_types, promo_codes to match the full spec
--   C. Drops event_registrations + event_registration_gifts (replaced by
--      event_orders + event_order_items + event_tickets)
--   D. Adds member_ticket_discount_pct to stations
--   E. Adds event_manager to profiles role enum
--   F. Creates triggers for sold_count, promo usage, auto-completion
--   G. Creates reporting views
--
-- Run AFTER 051_fix_events_show_id_fk_and_timezone.sql
-- ============================================================================


-- ============================================================================
-- PART A: New tables (create before altering existing, since FKs reference these)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- A1. venues — Reusable venue records
-- ----------------------------------------------------------------------------
CREATE TABLE venues (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    station_id      uuid NOT NULL REFERENCES stations(id),
    name            text NOT NULL,
    address_street  text,
    address_street2 text,
    address_city    text,
    address_state   text,
    address_zip     text,
    address_country text NOT NULL DEFAULT 'US',
    latitude        numeric(10, 7),
    longitude       numeric(10, 7),
    capacity        integer,
    venue_type      text NOT NULL DEFAULT 'physical',
    virtual_url     text,
    accessibility_info text,
    notes           text,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    deleted_at      timestamptz,

    CONSTRAINT venues_venue_type_check CHECK (
        venue_type = ANY (ARRAY['physical', 'virtual', 'hybrid'])
    ),
    CONSTRAINT venues_capacity_check CHECK (capacity IS NULL OR capacity > 0)
);

CREATE INDEX venues_station_id_idx ON venues(station_id)
    WHERE deleted_at IS NULL;

CREATE TRIGGER set_venues_updated_at BEFORE UPDATE ON venues
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS: staff can manage venues for their station
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "venues_anon_select"
    ON venues FOR SELECT TO anon
    USING (deleted_at IS NULL);

CREATE POLICY "venues_authenticated_select"
    ON venues FOR SELECT TO authenticated
    USING (deleted_at IS NULL);

CREATE POLICY "venues_service_role_all"
    ON venues FOR ALL TO service_role
    USING (true) WITH CHECK (true);


-- ----------------------------------------------------------------------------
-- A2. event_series — Parent for recurring events
-- ----------------------------------------------------------------------------
CREATE TABLE event_series (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    station_id      uuid NOT NULL REFERENCES stations(id),
    name            text NOT NULL,
    description     text,
    recurrence_rule text,   -- RFC 5545 RRULE format, for display only
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    deleted_at      timestamptz
);

CREATE INDEX event_series_station_id_idx ON event_series(station_id)
    WHERE deleted_at IS NULL;

CREATE TRIGGER set_event_series_updated_at BEFORE UPDATE ON event_series
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE event_series ENABLE ROW LEVEL SECURITY;

CREATE POLICY "event_series_authenticated_select"
    ON event_series FOR SELECT TO authenticated
    USING (deleted_at IS NULL);

CREATE POLICY "event_series_service_role_all"
    ON event_series FOR ALL TO service_role
    USING (true) WITH CHECK (true);


-- ============================================================================
-- PART B: Alter existing tables to match full spec
-- ============================================================================

-- ----------------------------------------------------------------------------
-- B1. ALTER events — rename name→title, add spec columns, drop old columns,
--     update constraints
-- ----------------------------------------------------------------------------

-- Rename name → title (spec uses title)
ALTER TABLE events RENAME COLUMN name TO title;

-- Add new columns from the spec
ALTER TABLE events
    ADD COLUMN IF NOT EXISTS series_id          uuid REFERENCES event_series(id),
    ADD COLUMN IF NOT EXISTS venue_id           uuid REFERENCES venues(id),
    ADD COLUMN IF NOT EXISTS short_description  text,
    ADD COLUMN IF NOT EXISTS host_name          text,
    ADD COLUMN IF NOT EXISTS banner_desktop_url text,
    ADD COLUMN IF NOT EXISTS banner_mobile_url  text,
    ADD COLUMN IF NOT EXISTS theme              jsonb NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS translations       jsonb NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS refund_policy      text NOT NULL DEFAULT 'no_refunds',
    ADD COLUMN IF NOT EXISTS refund_cutoff_days integer,
    ADD COLUMN IF NOT EXISTS venue_capacity_cap integer,
    ADD COLUMN IF NOT EXISTS accessibility_info text,
    ADD COLUMN IF NOT EXISTS public_access_at   timestamptz,
    ADD COLUMN IF NOT EXISTS member_access_at   timestamptz,
    ADD COLUMN IF NOT EXISTS created_by         uuid REFERENCES profiles(id);

-- Drop old inline venue columns (replaced by venue_id FK)
ALTER TABLE events
    DROP COLUMN IF EXISTS venue_name,
    DROP COLUMN IF EXISTS venue_address,
    DROP COLUMN IF EXISTS venue_city,
    DROP COLUMN IF EXISTS venue_state,
    DROP COLUMN IF EXISTS venue_postal,
    DROP COLUMN IF EXISTS is_virtual,
    DROP COLUMN IF EXISTS virtual_url;

-- Drop old columns superseded by spec fields
ALTER TABLE events
    DROP COLUMN IF EXISTS total_capacity,       -- replaced by venue_capacity_cap
    DROP COLUMN IF EXISTS published_at,         -- not in spec
    DROP COLUMN IF EXISTS registration_opens_at, -- replaced by public_access_at
    DROP COLUMN IF EXISTS registration_closes_at, -- replaced by member_access_at logic
    DROP COLUMN IF EXISTS allow_waitlist,        -- waitlist is implicit via event_waitlist table
    DROP COLUMN IF EXISTS image_url;             -- replaced by banner_desktop/mobile_url

-- Make ends_at NOT NULL (spec requires it)
-- First set any NULL values to starts_at + 2 hours as a safe default
UPDATE events SET ends_at = starts_at + interval '2 hours' WHERE ends_at IS NULL;
ALTER TABLE events ALTER COLUMN ends_at SET NOT NULL;

-- Update status constraint to add sold_out and archived
ALTER TABLE events DROP CONSTRAINT IF EXISTS events_status_check;
ALTER TABLE events ADD CONSTRAINT events_status_check CHECK (
    status = ANY (ARRAY[
        'draft', 'published', 'sold_out', 'cancelled', 'completed', 'archived'
    ])
);

-- Add refund policy constraint
ALTER TABLE events ADD CONSTRAINT events_refund_policy_check CHECK (
    refund_policy = ANY (ARRAY[
        'no_refunds', 'refund_before_event', 'refund_until_X_days'
    ])
);

-- Add dates ordering constraint
ALTER TABLE events ADD CONSTRAINT events_dates_check CHECK (ends_at > starts_at);

-- Add slug format constraint
ALTER TABLE events ADD CONSTRAINT events_slug_format CHECK (
    slug ~ '^[a-z0-9][a-z0-9-]*[a-z0-9]$'
);

-- New indexes for the added columns
CREATE INDEX IF NOT EXISTS events_series_id_idx ON events(series_id)
    WHERE series_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS events_venue_id_idx ON events(venue_id)
    WHERE venue_id IS NOT NULL AND deleted_at IS NULL;


-- ----------------------------------------------------------------------------
-- B2. ALTER ticket_types — add spec columns, update constraints
-- ----------------------------------------------------------------------------

-- Add new columns from the spec
ALTER TABLE ticket_types
    ADD COLUMN IF NOT EXISTS image_url          text,
    ADD COLUMN IF NOT EXISTS member_price_cents  integer,
    ADD COLUMN IF NOT EXISTS sold_count          integer NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS min_per_order       integer NOT NULL DEFAULT 1,
    ADD COLUMN IF NOT EXISTS max_per_order       integer NOT NULL DEFAULT 10,
    ADD COLUMN IF NOT EXISTS public_access_at    timestamptz,
    ADD COLUMN IF NOT EXISTS member_access_at    timestamptz,
    ADD COLUMN IF NOT EXISTS is_member_only      boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS tier_required        text,
    ADD COLUMN IF NOT EXISTS is_pwyc             boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS includes_gifts       jsonb NOT NULL DEFAULT '[]',
    ADD COLUMN IF NOT EXISTS translations         jsonb NOT NULL DEFAULT '{}';

-- Drop old columns superseded by spec fields
ALTER TABLE ticket_types
    DROP COLUMN IF EXISTS is_sliding_scale,      -- replaced by is_pwyc
    DROP COLUMN IF EXISTS suggested_price_cents,  -- not in spec
    DROP COLUMN IF EXISTS available_from,         -- replaced by public_access_at
    DROP COLUMN IF EXISTS available_until;        -- replaced by member_access_at logic

-- Allow price_cents to be NULL for PWYC tickets
ALTER TABLE ticket_types ALTER COLUMN price_cents DROP NOT NULL;
ALTER TABLE ticket_types ALTER COLUMN price_cents DROP DEFAULT;

-- Change amount columns from bigint to integer for consistency with spec
-- (safe since no data exists)
ALTER TABLE ticket_types ALTER COLUMN price_cents TYPE integer USING price_cents::integer;
ALTER TABLE ticket_types ALTER COLUMN fmv_cents TYPE integer USING fmv_cents::integer;
ALTER TABLE ticket_types ALTER COLUMN min_price_cents TYPE integer USING min_price_cents::integer;
ALTER TABLE ticket_types ALTER COLUMN max_price_cents TYPE integer USING max_price_cents::integer;

-- Add spec constraints
ALTER TABLE ticket_types ADD CONSTRAINT ticket_types_price_check CHECK (
    (is_pwyc = true AND price_cents IS NULL AND min_price_cents IS NOT NULL)
    OR (is_pwyc = false AND price_cents IS NOT NULL AND price_cents > 0)
);
ALTER TABLE ticket_types ADD CONSTRAINT ticket_types_pwyc_min_check CHECK (
    min_price_cents IS NULL OR min_price_cents >= 0
);
ALTER TABLE ticket_types ADD CONSTRAINT ticket_types_pwyc_max_check CHECK (
    max_price_cents IS NULL OR max_price_cents >= min_price_cents
);
ALTER TABLE ticket_types ADD CONSTRAINT ticket_types_fmv_check CHECK (fmv_cents >= 0);
ALTER TABLE ticket_types ADD CONSTRAINT ticket_types_capacity_check CHECK (
    capacity IS NULL OR capacity > 0
);
ALTER TABLE ticket_types ADD CONSTRAINT ticket_types_sold_count_check CHECK (sold_count >= 0);
ALTER TABLE ticket_types ADD CONSTRAINT ticket_types_min_max_order_check CHECK (
    max_per_order >= min_per_order
);


-- ----------------------------------------------------------------------------
-- B3. ALTER promo_codes — add spec columns, rename times_used → use_count,
--     consolidate discount columns
-- ----------------------------------------------------------------------------

-- Add new columns
ALTER TABLE promo_codes
    ADD COLUMN IF NOT EXISTS code_normalized  text,
    ADD COLUMN IF NOT EXISTS discount_value   integer,
    ADD COLUMN IF NOT EXISTS applies_to       text NOT NULL DEFAULT 'per_ticket',
    ADD COLUMN IF NOT EXISTS no_stacking      boolean NOT NULL DEFAULT true;

-- Rename times_used → use_count
ALTER TABLE promo_codes RENAME COLUMN times_used TO use_count;

-- Populate code_normalized from existing codes
UPDATE promo_codes SET code_normalized = UPPER(TRIM(code)) WHERE code_normalized IS NULL;
ALTER TABLE promo_codes ALTER COLUMN code_normalized SET NOT NULL;

-- Migrate discount data: consolidate discount_percent/discount_cents into discount_value
UPDATE promo_codes SET discount_value = COALESCE(discount_percent, 0)
    WHERE discount_type = 'percent' AND discount_value IS NULL;
UPDATE promo_codes SET discount_value = COALESCE(discount_cents::integer, 0)
    WHERE discount_type IN ('fixed_amount', 'free') AND discount_value IS NULL;
-- Default any remaining nulls to 0 (shouldn't happen with non-empty tables)
UPDATE promo_codes SET discount_value = 0 WHERE discount_value IS NULL;
ALTER TABLE promo_codes ALTER COLUMN discount_value SET NOT NULL;

-- Drop old discount columns (replaced by unified discount_value)
ALTER TABLE promo_codes
    DROP COLUMN IF EXISTS discount_percent,
    DROP COLUMN IF EXISTS discount_cents,
    DROP COLUMN IF EXISTS min_purchase_cents,          -- not in spec
    DROP COLUMN IF EXISTS applicable_ticket_type_ids;  -- replaced by junction table

-- Update discount_type constraint (remove 'free' and 'fixed_amount', add 'fixed')
-- First migrate 'fixed_amount' → 'fixed' in existing data
UPDATE promo_codes SET discount_type = 'fixed' WHERE discount_type = 'fixed_amount';
-- For 'free' codes, convert to 'percent' with discount_value = 100
UPDATE promo_codes SET discount_type = 'percent', discount_value = 100 WHERE discount_type = 'free';

ALTER TABLE promo_codes DROP CONSTRAINT IF EXISTS promo_codes_discount_type_check;
ALTER TABLE promo_codes ADD CONSTRAINT promo_codes_discount_type_check CHECK (
    discount_type = ANY (ARRAY['percent', 'fixed'])
);

-- Add remaining spec constraints
ALTER TABLE promo_codes ADD CONSTRAINT promo_codes_discount_value_check CHECK (discount_value > 0);
ALTER TABLE promo_codes ADD CONSTRAINT promo_codes_percent_max_check CHECK (
    discount_type != 'percent' OR discount_value <= 100
);
ALTER TABLE promo_codes ADD CONSTRAINT promo_codes_applies_to_check CHECK (
    applies_to = ANY (ARRAY['per_ticket', 'per_order'])
);
ALTER TABLE promo_codes ADD CONSTRAINT promo_codes_use_count_check CHECK (use_count >= 0);

-- Replace old unique indexes with spec's code_normalized-based ones
DROP INDEX IF EXISTS promo_codes_station_code_idx;
DROP INDEX IF EXISTS promo_codes_event_code_idx;
CREATE UNIQUE INDEX promo_codes_station_code_norm_idx
    ON promo_codes(station_id, code_normalized)
    WHERE deleted_at IS NULL;


-- ============================================================================
-- PART C: Drop old tables replaced by spec architecture
-- ============================================================================
-- event_registrations → replaced by event_orders + event_order_items + event_tickets
-- event_registration_gifts → replaced by ticket_types.includes_gifts JSONB

-- Drop RLS policies first, then indexes, then tables
-- (CASCADE handles FKs but be explicit for clarity)

-- event_registration_gifts (depends on event_registrations)
DROP TABLE IF EXISTS event_registration_gifts CASCADE;

-- event_registrations
DROP TABLE IF EXISTS event_registrations CASCADE;


-- ============================================================================
-- PART D: Create new spec tables (depend on altered events/ticket_types)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- D1. promo_code_ticket_types — Junction: which ticket types a promo applies to
-- ----------------------------------------------------------------------------
CREATE TABLE promo_code_ticket_types (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    promo_code_id   uuid NOT NULL REFERENCES promo_codes(id) ON DELETE CASCADE,
    ticket_type_id  uuid NOT NULL REFERENCES ticket_types(id) ON DELETE CASCADE,
    created_at      timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT promo_code_ticket_types_unique UNIQUE (promo_code_id, ticket_type_id)
);

CREATE INDEX promo_code_ticket_types_promo_idx ON promo_code_ticket_types(promo_code_id);
CREATE INDEX promo_code_ticket_types_ticket_idx ON promo_code_ticket_types(ticket_type_id);

ALTER TABLE promo_code_ticket_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "promo_code_ticket_types_service_role_all"
    ON promo_code_ticket_types FOR ALL TO service_role
    USING (true) WITH CHECK (true);

CREATE POLICY "promo_code_ticket_types_authenticated_select"
    ON promo_code_ticket_types FOR SELECT TO authenticated
    USING (true);


-- ----------------------------------------------------------------------------
-- D2. event_orders — Checkout transactions (replaces event_registrations)
-- ----------------------------------------------------------------------------
CREATE TABLE event_orders (
    id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    station_id              uuid NOT NULL REFERENCES stations(id),
    event_id                uuid NOT NULL REFERENCES events(id),
    donor_id                uuid NOT NULL REFERENCES donors(id),
    donation_id             uuid REFERENCES donations(id),       -- optional add-on donation
    promo_code_id           uuid REFERENCES promo_codes(id),     -- applied promo code
    operator_id             uuid REFERENCES profiles(id),        -- set for at-door/phone sales

    -- Order identifiers
    order_number            text NOT NULL,                       -- e.g., 'EVT-000042'
    confirmation_code       text NOT NULL,                       -- e.g., 'KPFK-A3X9'

    -- Totals (all in cents)
    subtotal_cents          integer NOT NULL,
    discount_cents          integer NOT NULL DEFAULT 0,
    total_cents             integer NOT NULL,
    donation_cents          integer NOT NULL DEFAULT 0,          -- add-on donation amount
    currency                text NOT NULL DEFAULT 'usd',

    -- Payment
    payment_provider        text NOT NULL,                       -- stripe, cash, check, comp
    payment_method_type     text,                                -- card, card_present, apple_pay
    stripe_payment_intent_id text,
    check_number            text,

    -- Source
    source_type             text NOT NULL DEFAULT 'web',         -- web, phone, walk_in

    -- Status
    status                  text NOT NULL DEFAULT 'pending',

    -- Tax receipt link
    tax_document_id         uuid REFERENCES tax_documents(id),

    -- UTM tracking
    utm_source              text,
    utm_medium              text,
    utm_campaign            text,
    referrer_url            text,

    -- Timestamps
    completed_at            timestamptz,
    refunded_at             timestamptz,
    cancelled_at            timestamptz,
    created_at              timestamptz NOT NULL DEFAULT now(),
    updated_at              timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT event_orders_status_check CHECK (
        status = ANY (ARRAY[
            'pending', 'completed', 'refunded', 'partially_refunded', 'cancelled'
        ])
    ),
    CONSTRAINT event_orders_source_type_check CHECK (
        source_type = ANY (ARRAY['web', 'phone', 'walk_in'])
    ),
    CONSTRAINT event_orders_payment_provider_check CHECK (
        payment_provider = ANY (ARRAY['stripe', 'cash', 'check', 'comp'])
    ),
    CONSTRAINT event_orders_total_check CHECK (total_cents >= 0),
    CONSTRAINT event_orders_currency_check CHECK (currency = 'usd')
);

CREATE UNIQUE INDEX event_orders_order_number_idx ON event_orders(station_id, order_number);
CREATE UNIQUE INDEX event_orders_confirmation_code_idx ON event_orders(confirmation_code);
CREATE INDEX event_orders_event_id_idx ON event_orders(event_id);
CREATE INDEX event_orders_donor_id_idx ON event_orders(donor_id);
CREATE INDEX event_orders_status_idx ON event_orders(event_id, status);
CREATE INDEX event_orders_stripe_pi_idx ON event_orders(stripe_payment_intent_id)
    WHERE stripe_payment_intent_id IS NOT NULL;
CREATE INDEX event_orders_donation_id_idx ON event_orders(donation_id)
    WHERE donation_id IS NOT NULL;

CREATE TRIGGER set_event_orders_updated_at BEFORE UPDATE ON event_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE event_orders ENABLE ROW LEVEL SECURITY;

-- Staff can see orders for events in their station
CREATE POLICY "event_orders_staff_select"
    ON event_orders FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.deleted_at IS NULL
            AND p.is_active = true
            AND (p.role = 'super_admin' OR p.station_id = event_orders.station_id)
            AND p.role IN ('super_admin', 'admin', 'ops', 'event_manager', 'volunteer')
        )
    );

-- Donors can see their own orders
CREATE POLICY "event_orders_donor_self_select"
    ON event_orders FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.donor_id = event_orders.donor_id
        )
    );

CREATE POLICY "event_orders_service_role_all"
    ON event_orders FOR ALL TO service_role
    USING (true) WITH CHECK (true);


-- ----------------------------------------------------------------------------
-- D3. event_order_items — Line items per order
-- ----------------------------------------------------------------------------
CREATE TABLE event_order_items (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id            uuid NOT NULL REFERENCES event_orders(id) ON DELETE CASCADE,
    ticket_type_id      uuid NOT NULL REFERENCES ticket_types(id),
    quantity            integer NOT NULL,
    unit_price_cents    integer NOT NULL,           -- price actually charged per ticket
    original_price_cents integer NOT NULL,           -- list price before discount
    discount_type       text,                        -- 'member', 'promo', or NULL
    discount_description text,                       -- e.g., '10% member discount'
    fmv_cents           integer NOT NULL DEFAULT 0,  -- per ticket, snapshot from ticket_type
    created_at          timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT event_order_items_quantity_check CHECK (quantity > 0),
    CONSTRAINT event_order_items_price_check CHECK (unit_price_cents >= 0)
);

CREATE INDEX event_order_items_order_id_idx ON event_order_items(order_id);
CREATE INDEX event_order_items_ticket_type_id_idx ON event_order_items(ticket_type_id);

ALTER TABLE event_order_items ENABLE ROW LEVEL SECURITY;

-- Follows order access
CREATE POLICY "event_order_items_staff_select"
    ON event_order_items FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM event_orders eo
            JOIN profiles p ON (p.role = 'super_admin' OR p.station_id = eo.station_id)
            WHERE eo.id = event_order_items.order_id
            AND p.id = auth.uid()
            AND p.deleted_at IS NULL
            AND p.is_active = true
            AND p.role IN ('super_admin', 'admin', 'ops', 'event_manager', 'volunteer')
        )
    );

CREATE POLICY "event_order_items_donor_self_select"
    ON event_order_items FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM event_orders eo
            JOIN profiles p ON p.donor_id = eo.donor_id
            WHERE eo.id = event_order_items.order_id
            AND p.id = auth.uid()
        )
    );

CREATE POLICY "event_order_items_service_role_all"
    ON event_order_items FOR ALL TO service_role
    USING (true) WITH CHECK (true);


-- ----------------------------------------------------------------------------
-- D4. event_tickets — Individual issued tickets with QR codes
-- ----------------------------------------------------------------------------
CREATE TABLE event_tickets (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id            uuid NOT NULL REFERENCES event_orders(id) ON DELETE CASCADE,
    order_item_id       uuid NOT NULL REFERENCES event_order_items(id),
    event_id            uuid NOT NULL REFERENCES events(id),        -- denormalized for check-in
    ticket_type_id      uuid NOT NULL REFERENCES ticket_types(id),  -- denormalized
    donor_id            uuid NOT NULL REFERENCES donors(id),        -- buyer, denormalized

    -- Identification
    ticket_number       text NOT NULL,              -- e.g., 'TKT-001234'
    qr_token            text NOT NULL,              -- signed JWT for offline validation
    qr_token_hash       text NOT NULL,              -- SHA-256 hash for DB lookup

    -- Attendee (optional, for named tickets)
    attendee_name       text,
    attendee_email      text,

    -- Delivery
    delivery_method     text NOT NULL DEFAULT 'email',
    printed_at          timestamptz,

    -- Check-in
    checked_in_at       timestamptz,
    checked_in_by       uuid REFERENCES profiles(id),
    check_in_method     text,                       -- qr_scan, manual_search, bulk_checkin

    -- Status
    status              text NOT NULL DEFAULT 'active',
    refunded_at         timestamptz,
    transferred_at      timestamptz,

    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT event_tickets_status_check CHECK (
        status = ANY (ARRAY['active', 'used', 'refunded', 'cancelled', 'transferred'])
    ),
    CONSTRAINT event_tickets_delivery_check CHECK (
        delivery_method = ANY (ARRAY['email', 'physical', 'will_call'])
    )
);

CREATE UNIQUE INDEX event_tickets_ticket_number_idx ON event_tickets(ticket_number);
CREATE UNIQUE INDEX event_tickets_qr_token_hash_idx ON event_tickets(qr_token_hash);
CREATE INDEX event_tickets_order_id_idx ON event_tickets(order_id);
CREATE INDEX event_tickets_event_id_idx ON event_tickets(event_id);
CREATE INDEX event_tickets_donor_id_idx ON event_tickets(donor_id);
CREATE INDEX event_tickets_event_status_idx ON event_tickets(event_id, status)
    WHERE status = 'active';
CREATE INDEX event_tickets_checkin_idx ON event_tickets(event_id, checked_in_at)
    WHERE checked_in_at IS NOT NULL;

CREATE TRIGGER set_event_tickets_updated_at BEFORE UPDATE ON event_tickets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE event_tickets ENABLE ROW LEVEL SECURITY;

-- Staff can see tickets for events in their station
CREATE POLICY "event_tickets_staff_select"
    ON event_tickets FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM events e
            JOIN profiles p ON (p.role = 'super_admin' OR p.station_id = e.station_id)
            WHERE e.id = event_tickets.event_id
            AND p.id = auth.uid()
            AND p.deleted_at IS NULL
            AND p.is_active = true
            AND p.role IN ('super_admin', 'admin', 'ops', 'event_manager', 'volunteer')
        )
    );

-- Donors can see their own tickets
CREATE POLICY "event_tickets_donor_self_select"
    ON event_tickets FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.donor_id = event_tickets.donor_id
        )
    );

CREATE POLICY "event_tickets_service_role_all"
    ON event_tickets FOR ALL TO service_role
    USING (true) WITH CHECK (true);


-- ----------------------------------------------------------------------------
-- D5. event_questions — Custom questions asked at checkout
-- ----------------------------------------------------------------------------
CREATE TABLE event_questions (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id        uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    question_text   text NOT NULL,
    question_type   text NOT NULL DEFAULT 'text',
    options         jsonb,                          -- for select/multi_select
    is_required     boolean NOT NULL DEFAULT false,
    sort_order      integer NOT NULL DEFAULT 0,
    translations    jsonb NOT NULL DEFAULT '{}',
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    deleted_at      timestamptz,

    CONSTRAINT event_questions_type_check CHECK (
        question_type = ANY (ARRAY['text', 'select', 'multi_select'])
    )
);

CREATE INDEX event_questions_event_id_idx ON event_questions(event_id)
    WHERE deleted_at IS NULL;

CREATE TRIGGER set_event_questions_updated_at BEFORE UPDATE ON event_questions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE event_questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "event_questions_anon_select"
    ON event_questions FOR SELECT TO anon
    USING (
        deleted_at IS NULL
        AND EXISTS (
            SELECT 1 FROM events e
            WHERE e.id = event_questions.event_id
            AND e.status IN ('published', 'sold_out')
            AND e.deleted_at IS NULL
        )
    );

CREATE POLICY "event_questions_authenticated_select"
    ON event_questions FOR SELECT TO authenticated
    USING (deleted_at IS NULL);

CREATE POLICY "event_questions_service_role_all"
    ON event_questions FOR ALL TO service_role
    USING (true) WITH CHECK (true);


-- ----------------------------------------------------------------------------
-- D6. event_question_responses — Answers to custom questions
-- ----------------------------------------------------------------------------
CREATE TABLE event_question_responses (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id     uuid NOT NULL REFERENCES event_questions(id) ON DELETE CASCADE,
    order_id        uuid NOT NULL REFERENCES event_orders(id) ON DELETE CASCADE,
    response_text   text NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX event_question_responses_question_idx ON event_question_responses(question_id);
CREATE INDEX event_question_responses_order_idx ON event_question_responses(order_id);

ALTER TABLE event_question_responses ENABLE ROW LEVEL SECURITY;

-- Follows order access pattern
CREATE POLICY "event_question_responses_staff_select"
    ON event_question_responses FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM event_orders eo
            JOIN profiles p ON (p.role = 'super_admin' OR p.station_id = eo.station_id)
            WHERE eo.id = event_question_responses.order_id
            AND p.id = auth.uid()
            AND p.deleted_at IS NULL
            AND p.is_active = true
            AND p.role IN ('super_admin', 'admin', 'ops', 'event_manager')
        )
    );

CREATE POLICY "event_question_responses_service_role_all"
    ON event_question_responses FOR ALL TO service_role
    USING (true) WITH CHECK (true);


-- ----------------------------------------------------------------------------
-- D7. event_emails — Configured email sequences per event
-- ----------------------------------------------------------------------------
CREATE TABLE event_emails (
    id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id                uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    email_type              text NOT NULL,
    subject                 text NOT NULL,
    body                    text NOT NULL,          -- HTML with {{variable}} interpolation
    is_enabled              boolean NOT NULL DEFAULT true,
    send_at_offset_hours    integer,                -- hours relative to event start
    translations            jsonb NOT NULL DEFAULT '{}',
    created_at              timestamptz NOT NULL DEFAULT now(),
    updated_at              timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT event_emails_type_check CHECK (
        email_type = ANY (ARRAY[
            'confirmation', 'reminder_1', 'reminder_2', 'reminder_3',
            'followup', 'cancellation', 'reschedule'
        ])
    )
);

CREATE INDEX event_emails_event_id_idx ON event_emails(event_id);
CREATE UNIQUE INDEX event_emails_event_type_idx ON event_emails(event_id, email_type);

CREATE TRIGGER set_event_emails_updated_at BEFORE UPDATE ON event_emails
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE event_emails ENABLE ROW LEVEL SECURITY;

CREATE POLICY "event_emails_staff_select"
    ON event_emails FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM events e
            JOIN profiles p ON (p.role = 'super_admin' OR p.station_id = e.station_id)
            WHERE e.id = event_emails.event_id
            AND p.id = auth.uid()
            AND p.deleted_at IS NULL
            AND p.is_active = true
            AND p.role IN ('super_admin', 'admin', 'ops', 'event_manager')
        )
    );

CREATE POLICY "event_emails_service_role_all"
    ON event_emails FOR ALL TO service_role
    USING (true) WITH CHECK (true);


-- ----------------------------------------------------------------------------
-- D8. event_waitlist — Queue for sold-out ticket types
-- ----------------------------------------------------------------------------
CREATE TABLE event_waitlist (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id        uuid NOT NULL REFERENCES events(id),
    ticket_type_id  uuid NOT NULL REFERENCES ticket_types(id),
    donor_id        uuid NOT NULL REFERENCES donors(id),
    email           text NOT NULL,                  -- denormalized for notification
    requested_at    timestamptz NOT NULL DEFAULT now(),
    notified_at     timestamptz,
    expired_at      timestamptz,
    claimed_at      timestamptz
);

CREATE INDEX event_waitlist_event_ticket_idx ON event_waitlist(event_id, ticket_type_id)
    WHERE claimed_at IS NULL AND expired_at IS NULL;
CREATE INDEX event_waitlist_donor_idx ON event_waitlist(donor_id);

ALTER TABLE event_waitlist ENABLE ROW LEVEL SECURITY;

-- Staff can see waitlist for their station's events
CREATE POLICY "event_waitlist_staff_select"
    ON event_waitlist FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM events e
            JOIN profiles p ON (p.role = 'super_admin' OR p.station_id = e.station_id)
            WHERE e.id = event_waitlist.event_id
            AND p.id = auth.uid()
            AND p.deleted_at IS NULL
            AND p.is_active = true
            AND p.role IN ('super_admin', 'admin', 'ops', 'event_manager')
        )
    );

-- Donors can see their own waitlist entries
CREATE POLICY "event_waitlist_donor_self_select"
    ON event_waitlist FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.donor_id = event_waitlist.donor_id
        )
    );

CREATE POLICY "event_waitlist_service_role_all"
    ON event_waitlist FOR ALL TO service_role
    USING (true) WITH CHECK (true);


-- ============================================================================
-- PART E: Alter stations and profiles for M3 requirements
-- ============================================================================

-- Add member ticket discount percentage to stations
ALTER TABLE stations
    ADD COLUMN IF NOT EXISTS member_ticket_discount_pct integer NOT NULL DEFAULT 10;

COMMENT ON COLUMN stations.member_ticket_discount_pct IS
    'Default % discount for active members on ticket purchases. Can be overridden per ticket_type.';

-- Add event_manager to profiles role enum
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check CHECK (
    role = ANY (ARRAY[
        'super_admin', 'admin', 'ops', 'event_manager', 'volunteer', 'donor'
    ])
);


-- ============================================================================
-- PART F: Triggers for automated counters
-- ============================================================================

-- F1. Increment ticket_types.sold_count when a ticket is created
CREATE FUNCTION increment_ticket_sold_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE ticket_types
    SET sold_count = sold_count + 1
    WHERE id = NEW.ticket_type_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ticket_sold_count_increment
    AFTER INSERT ON event_tickets
    FOR EACH ROW
    EXECUTE FUNCTION increment_ticket_sold_count();

-- F2. Decrement sold_count when a ticket is refunded or cancelled
CREATE FUNCTION decrement_ticket_sold_count()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status = 'active' AND NEW.status IN ('refunded', 'cancelled') THEN
        UPDATE ticket_types
        SET sold_count = GREATEST(0, sold_count - 1)
        WHERE id = NEW.ticket_type_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ticket_sold_count_decrement
    AFTER UPDATE OF status ON event_tickets
    FOR EACH ROW
    EXECUTE FUNCTION decrement_ticket_sold_count();

-- F3. Increment promo_codes.use_count when an order completes
CREATE FUNCTION increment_promo_use_count()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND NEW.promo_code_id IS NOT NULL THEN
        UPDATE promo_codes
        SET use_count = use_count + 1
        WHERE id = NEW.promo_code_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER promo_use_count_increment
    AFTER UPDATE OF status ON event_orders
    FOR EACH ROW
    WHEN (OLD.status != 'completed' AND NEW.status = 'completed')
    EXECUTE FUNCTION increment_promo_use_count();


-- ============================================================================
-- PART G: Reporting views
-- ============================================================================

-- G1. Event sales summary — overview stats per event
CREATE VIEW v_event_sales_summary AS
SELECT
    e.id AS event_id,
    e.title,
    e.starts_at,
    e.status,
    COUNT(DISTINCT eo.id) AS total_orders,
    COUNT(et.id) AS total_tickets,
    COUNT(et.id) FILTER (WHERE et.checked_in_at IS NOT NULL) AS checked_in_count,
    COALESCE(SUM(eo.total_cents), 0) AS total_revenue_cents,
    COALESCE(SUM(eo.donation_cents), 0) AS total_donation_cents,
    COUNT(DISTINCT eo.id) FILTER (WHERE eo.source_type = 'web') AS web_orders,
    COUNT(DISTINCT eo.id) FILTER (WHERE eo.source_type = 'walk_in') AS walk_in_orders,
    COUNT(DISTINCT eo.id) FILTER (WHERE eo.source_type = 'phone') AS phone_orders
FROM events e
LEFT JOIN event_orders eo ON eo.event_id = e.id
    AND eo.status IN ('completed', 'partially_refunded')
LEFT JOIN event_tickets et ON et.event_id = e.id
    AND et.status = 'active'
WHERE e.deleted_at IS NULL
GROUP BY e.id, e.title, e.starts_at, e.status;

-- G2. Ticket type sales breakdown — per-type stats within an event
CREATE VIEW v_ticket_type_sales AS
SELECT
    tt.id AS ticket_type_id,
    tt.event_id,
    tt.name,
    tt.price_cents,
    tt.capacity,
    tt.sold_count,
    CASE
        WHEN tt.capacity IS NOT NULL AND tt.capacity > 0
        THEN ROUND((tt.sold_count::numeric / tt.capacity) * 100, 1)
        ELSE NULL
    END AS percent_sold,
    COALESCE(SUM(eoi.unit_price_cents * eoi.quantity), 0) AS revenue_cents,
    COUNT(DISTINCT et.id) FILTER (WHERE et.checked_in_at IS NOT NULL) AS checked_in_count
FROM ticket_types tt
LEFT JOIN event_order_items eoi ON eoi.ticket_type_id = tt.id
LEFT JOIN event_orders eo ON eo.id = eoi.order_id
    AND eo.status IN ('completed', 'partially_refunded')
LEFT JOIN event_tickets et ON et.ticket_type_id = tt.id
    AND et.status = 'active'
WHERE tt.deleted_at IS NULL
GROUP BY tt.id, tt.event_id, tt.name, tt.price_cents, tt.capacity, tt.sold_count;


-- ============================================================================
-- PART H: Grant table-level permissions
-- ============================================================================
-- RLS policies (above) control which ROWS a role can see, but PostgreSQL
-- also requires table-level GRANT for the role to access the table at all.
-- Without these, service_role gets "permission denied for table venues"
-- even though it has a FOR ALL RLS policy.
--
-- GRANT is idempotent — re-running this migration won't error.
-- ============================================================================

-- SERVICE_ROLE: Full access (used by getSupabaseAdmin() in all API routes)
GRANT ALL ON TABLE venues TO service_role;
GRANT ALL ON TABLE event_series TO service_role;
GRANT ALL ON TABLE promo_code_ticket_types TO service_role;
GRANT ALL ON TABLE event_orders TO service_role;
GRANT ALL ON TABLE event_order_items TO service_role;
GRANT ALL ON TABLE event_tickets TO service_role;
GRANT ALL ON TABLE event_questions TO service_role;
GRANT ALL ON TABLE event_question_responses TO service_role;
GRANT ALL ON TABLE event_emails TO service_role;
GRANT ALL ON TABLE event_waitlist TO service_role;

-- AUTHENTICATED: Staff operations (RLS policies above control row-level access)
GRANT ALL ON TABLE venues TO authenticated;
GRANT ALL ON TABLE event_series TO authenticated;
GRANT ALL ON TABLE promo_code_ticket_types TO authenticated;
GRANT ALL ON TABLE event_orders TO authenticated;
GRANT ALL ON TABLE event_order_items TO authenticated;
GRANT ALL ON TABLE event_tickets TO authenticated;
GRANT ALL ON TABLE event_questions TO authenticated;
GRANT ALL ON TABLE event_question_responses TO authenticated;
GRANT ALL ON TABLE event_emails TO authenticated;
GRANT ALL ON TABLE event_waitlist TO authenticated;

-- ANON: Public event browsing + checkout
GRANT SELECT ON TABLE venues TO anon;
GRANT SELECT ON TABLE event_series TO anon;
GRANT SELECT ON TABLE promo_code_ticket_types TO anon;
GRANT SELECT, INSERT ON TABLE event_orders TO anon;
GRANT SELECT, INSERT ON TABLE event_order_items TO anon;
GRANT SELECT, INSERT ON TABLE event_tickets TO anon;
GRANT SELECT ON TABLE event_questions TO anon;
GRANT INSERT ON TABLE event_question_responses TO anon;
GRANT SELECT, INSERT ON TABLE event_waitlist TO anon;

-- Reporting views
GRANT SELECT ON v_event_sales_summary TO service_role;
GRANT SELECT ON v_event_sales_summary TO authenticated;
GRANT SELECT ON v_ticket_type_sales TO service_role;
GRANT SELECT ON v_ticket_type_sales TO authenticated;

-- Sequences (for INSERT with auto-generated UUIDs on new tables)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon;


-- ============================================================================
-- Tell PostgREST to pick up all schema changes
-- ============================================================================
NOTIFY pgrst, 'reload schema';
