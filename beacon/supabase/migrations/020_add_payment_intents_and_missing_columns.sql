-- ============================================================================
-- Migration 020: Add payment_intents table and missing donation columns
-- ============================================================================
-- The phone pledge flow requires:
-- 1. payment_intents table - tracks Stripe PaymentIntents for phone pledges
-- 2. donations.comments - operator notes on the pledge
-- 3. donations.source_type - distinguishes 'phone' vs 'web' donations
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CREATE payment_intents TABLE
-- Used by phone pledge flow to track PaymentIntents before donation is created
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS payment_intents (
    id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    station_id              uuid NOT NULL REFERENCES stations(id),
    donor_id                uuid REFERENCES donors(id),
    checkout_session_id     uuid REFERENCES checkout_sessions(id),
    donation_id             uuid REFERENCES donations(id),

    -- Stripe identifiers
    stripe_payment_intent_id    text NOT NULL UNIQUE,
    stripe_payment_method_id    text,

    -- Payment details
    amount_cents            integer NOT NULL CHECK (amount_cents > 0),
    fee_coverage_cents      integer NOT NULL DEFAULT 0 CHECK (fee_coverage_cents >= 0),
    currency                text NOT NULL DEFAULT 'usd' CHECK (currency = 'usd'),

    -- Status tracking
    status                  text NOT NULL DEFAULT 'requires_payment_method',
    source_type             text NOT NULL DEFAULT 'phone',

    -- Operator who created the payment intent (for phone pledges)
    operator_id             uuid REFERENCES profiles(id),

    -- Additional metadata (gift selections, campaign, etc.)
    metadata                jsonb NOT NULL DEFAULT '{}',

    -- Lifecycle timestamps
    succeeded_at            timestamptz,
    created_at              timestamptz NOT NULL DEFAULT now(),
    updated_at              timestamptz NOT NULL DEFAULT now()
);

-- Indexes for payment_intents
CREATE INDEX IF NOT EXISTS idx_payment_intents_station ON payment_intents(station_id);
CREATE INDEX IF NOT EXISTS idx_payment_intents_donor ON payment_intents(donor_id) WHERE donor_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_payment_intents_checkout_session ON payment_intents(checkout_session_id) WHERE checkout_session_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_payment_intents_donation ON payment_intents(donation_id) WHERE donation_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_payment_intents_status ON payment_intents(status) WHERE status != 'succeeded';

-- RLS for payment_intents
ALTER TABLE payment_intents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "payment_intents_service_role_all"
    ON payment_intents FOR ALL TO service_role
    USING (true) WITH CHECK (true);

CREATE POLICY "payment_intents_authenticated_select"
    ON payment_intents FOR SELECT TO authenticated
    USING (EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid()));

CREATE POLICY "payment_intents_authenticated_insert"
    ON payment_intents FOR INSERT TO authenticated
    WITH CHECK (EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid()));

CREATE POLICY "payment_intents_authenticated_update"
    ON payment_intents FOR UPDATE TO authenticated
    USING (EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid()));

-- Grants for payment_intents
GRANT ALL ON TABLE payment_intents TO service_role;
GRANT ALL ON TABLE payment_intents TO authenticated;

-- ----------------------------------------------------------------------------
-- ADD MISSING COLUMNS TO donations TABLE
-- ----------------------------------------------------------------------------

-- Add comments column (operator notes on the pledge)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'donations' AND column_name = 'comments'
    ) THEN
        ALTER TABLE donations ADD COLUMN comments text;
    END IF;
END $$;

-- Add source_type column (distinguishes 'phone' vs 'web' donations)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'donations' AND column_name = 'source_type'
    ) THEN
        ALTER TABLE donations ADD COLUMN source_type text DEFAULT 'web';
    END IF;
END $$;

-- Add gift_variant_id column (links to specific gift variant selected)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'donations' AND column_name = 'gift_variant_id'
    ) THEN
        ALTER TABLE donations ADD COLUMN gift_variant_id uuid REFERENCES gift_variants(id);
        CREATE INDEX IF NOT EXISTS idx_donations_gift_variant ON donations(gift_variant_id) WHERE gift_variant_id IS NOT NULL;
    END IF;
END $$;

-- ============================================================================
-- End of Migration 020
-- ============================================================================
