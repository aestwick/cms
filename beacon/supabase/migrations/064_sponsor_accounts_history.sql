-- Migration 064: Sponsor accounts + sponsorship history (renewal pipeline)
--
-- Schema ships now, UI deferred to M5. These tables enable:
--   - Tracking organizations that have completed sponsorships
--   - Renewal reminders when renewal_due_at approaches
--   - Lifetime value and relationship history
--   - Deal-level tracking (amount, tier, dates, status)
--
-- sponsor_accounts are created when an inquiry converts to a completed deal
-- (manually by staff or auto on status → "completed").
-- sponsorship_history records individual deals linked to an account.
--
-- All statements are idempotent.


-- ============================================================================
-- 1. sponsor_accounts — organizations with completed sponsorships
-- ============================================================================
-- Tracks the relationship with an organization across multiple deals.
-- Aggregated metrics (lifetime_value, total_sponsorships) are recomputed
-- by application code when sponsorship_history records change.

CREATE TABLE IF NOT EXISTS public.sponsor_accounts (
    id                      uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    station_id              uuid        NOT NULL REFERENCES public.stations(id),

    -- Organization identity
    org_name                text        NOT NULL,
    org_type                text        NOT NULL CHECK (org_type IN ('501c3', '501c4', 'for_profit', 'government', 'other')),
    contact_name            text        NOT NULL,
    contact_email           text        NOT NULL,
    contact_phone           text,
    website                 text,

    -- Categorization — same tag system as inquiries
    tags                    jsonb       NOT NULL DEFAULT '[]'::jsonb,

    -- ---- Aggregated metrics (recomputed from sponsorship_history) ----
    -- Total cash value of all completed deals
    lifetime_value_cents    bigint      NOT NULL DEFAULT 0,
    -- Count of completed deals
    total_sponsorships      integer     NOT NULL DEFAULT 0,
    -- When their first and most recent deals were
    first_sponsorship_at    timestamptz,
    last_sponsorship_at     timestamptz,

    -- ---- Renewal pipeline ----
    -- When this account's next sponsorship renewal is expected
    renewal_due_at          timestamptz,
    -- Where they are in the renewal cycle
    renewal_status          text        CHECK (renewal_status IS NULL OR renewal_status IN ('upcoming', 'due', 'overdue', 'renewed', 'lost')),

    created_at              timestamptz NOT NULL DEFAULT now(),
    updated_at              timestamptz NOT NULL DEFAULT now()
);

-- Common query indexes
CREATE INDEX IF NOT EXISTS sponsor_accounts_station_id_idx
    ON public.sponsor_accounts(station_id);

CREATE INDEX IF NOT EXISTS sponsor_accounts_renewal_due_at_idx
    ON public.sponsor_accounts(renewal_due_at)
    WHERE renewal_due_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS sponsor_accounts_renewal_status_idx
    ON public.sponsor_accounts(renewal_status)
    WHERE renewal_status IS NOT NULL;

CREATE INDEX IF NOT EXISTS sponsor_accounts_org_name_idx
    ON public.sponsor_accounts(org_name);

-- Auto-update updated_at
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'set_sponsor_accounts_updated_at'
    ) THEN
        CREATE TRIGGER set_sponsor_accounts_updated_at
            BEFORE UPDATE ON public.sponsor_accounts
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at();
    END IF;
END $$;

-- RLS: no public read (business-sensitive). Admin read/write via service role.
ALTER TABLE public.sponsor_accounts ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'sponsor_accounts' AND policyname = 'sponsor_accounts_authenticated_select'
    ) THEN
        CREATE POLICY sponsor_accounts_authenticated_select
            ON public.sponsor_accounts FOR SELECT TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM public.profiles
                    WHERE profiles.id = auth.uid()
                    AND profiles.role IN ('super_admin', 'admin', 'ops')
                    AND profiles.is_active = true
                    AND (profiles.role = 'super_admin' OR profiles.station_id = sponsor_accounts.station_id)
                )
            );
    END IF;
END $$;


-- ============================================================================
-- 2. sponsorship_history — individual deals linked to a sponsor account
-- ============================================================================
-- Each row = one sponsorship deal (paid, trade, or in-kind).
-- Creating or updating a record should trigger recomputation of the parent
-- sponsor_account's aggregated metrics (done in application code, not triggers,
-- to keep the logic visible and testable).

CREATE TABLE IF NOT EXISTS public.sponsorship_history (
    id                      uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    station_id              uuid        NOT NULL REFERENCES public.stations(id),
    -- Which sponsor account this deal belongs to
    sponsor_account_id      uuid        NOT NULL REFERENCES public.sponsor_accounts(id),
    -- Link back to the original inquiry (if the deal came through the form)
    inquiry_id              uuid        REFERENCES public.sponsorship_inquiries(id),
    -- For event sponsorships — which event was sponsored
    event_id                uuid        REFERENCES public.events(id),

    -- What kind of deal this was
    deal_type               text        NOT NULL CHECK (deal_type IN ('media_sponsorship', 'event_sponsorship', 'trade')),
    -- Which tier they purchased (e.g., "Diamond", "Presenting")
    tier_name               text,
    -- Cash amount in cents (0 for pure trade deals)
    amount_cents            bigint      NOT NULL DEFAULT 0,
    -- Assessed value of in-kind contributions (for trade deals)
    in_kind_value_cents     bigint      NOT NULL DEFAULT 0,
    -- Description of what they provided in-kind
    in_kind_description     text,

    -- ---- Promotional period ----
    promo_start_date        date,
    promo_end_date          date,

    -- Deal status
    status                  text        NOT NULL CHECK (status IN ('active', 'completed', 'cancelled')),

    -- Categorization
    tags                    jsonb       NOT NULL DEFAULT '[]'::jsonb,

    created_at              timestamptz NOT NULL DEFAULT now(),
    updated_at              timestamptz NOT NULL DEFAULT now()
);

-- Common query indexes
CREATE INDEX IF NOT EXISTS sponsorship_history_station_id_idx
    ON public.sponsorship_history(station_id);

CREATE INDEX IF NOT EXISTS sponsorship_history_sponsor_account_id_idx
    ON public.sponsorship_history(sponsor_account_id);

CREATE INDEX IF NOT EXISTS sponsorship_history_event_id_idx
    ON public.sponsorship_history(event_id)
    WHERE event_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS sponsorship_history_deal_type_idx
    ON public.sponsorship_history(deal_type);

CREATE INDEX IF NOT EXISTS sponsorship_history_status_idx
    ON public.sponsorship_history(status);

CREATE INDEX IF NOT EXISTS sponsorship_history_created_at_idx
    ON public.sponsorship_history(created_at);

-- Auto-update updated_at
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'set_sponsorship_history_updated_at'
    ) THEN
        CREATE TRIGGER set_sponsorship_history_updated_at
            BEFORE UPDATE ON public.sponsorship_history
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at();
    END IF;
END $$;

-- RLS: no public read. Admin read/write via service role.
ALTER TABLE public.sponsorship_history ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'sponsorship_history' AND policyname = 'sponsorship_history_authenticated_select'
    ) THEN
        CREATE POLICY sponsorship_history_authenticated_select
            ON public.sponsorship_history FOR SELECT TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM public.profiles
                    WHERE profiles.id = auth.uid()
                    AND profiles.role IN ('super_admin', 'admin', 'ops')
                    AND profiles.is_active = true
                    AND (profiles.role = 'super_admin' OR profiles.station_id = sponsorship_history.station_id)
                )
            );
    END IF;
END $$;


-- ============================================================================
-- 3. Notify PostgREST to reload schema cache
-- ============================================================================
NOTIFY pgrst, 'reload schema';
