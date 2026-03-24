-- Migration 045: Bill-me pledges, check payments, cash entry, and phone pledge settings
--
-- Adds infrastructure for three new payment methods on the phone pledge form:
-- 1. Bill Me Later — donor pledges now, pays by card later (30-day window)
-- 2. Check — donor reads check number over the phone, mails check
-- 3. Cash — walk-in or mailed cash donations (recorded offline)
--
-- Also adds a station_settings table for configurable phone pledge behavior
-- (bill-me due days, reminder schedule, enabled payment methods).

-- ============================================================================
-- 1. station_settings — per-station configurable settings (JSONB)
-- ============================================================================
-- One row per station. JSONB is flexible for adding new setting categories
-- without migrations (e.g., email settings, fulfillment defaults).
--
-- Default phone_pledge settings:
--   bill_me_due_days: 30
--   reminder_days: [7, 21, 30]
--   enabled_methods: ['card', 'bill_me', 'check']

CREATE TABLE IF NOT EXISTS public.station_settings (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    station_id      uuid NOT NULL REFERENCES public.stations(id),
    -- JSONB blob for all settings, grouped by category
    -- Structure: { phone_pledge: { ... }, email: { ... }, ... }
    settings        jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    -- One settings row per station — enforced by unique constraint
    CONSTRAINT station_settings_station_id_unique UNIQUE (station_id)
);

-- Index on station_id is covered by the unique constraint above
CREATE INDEX IF NOT EXISTS station_settings_station_id_idx
    ON public.station_settings(station_id);

-- Auto-update the updated_at timestamp on changes
CREATE TRIGGER set_station_settings_updated_at
    BEFORE UPDATE ON public.station_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- RLS — admin API routes use service role (bypasses RLS), but adding
-- basic policies for defense-in-depth
ALTER TABLE public.station_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY station_settings_select_staff ON public.station_settings
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('super_admin', 'admin')
            AND profiles.is_active = true
            AND (profiles.role = 'super_admin' OR profiles.station_id = station_settings.station_id)
        )
    );

CREATE POLICY station_settings_update_admin ON public.station_settings
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('super_admin', 'admin')
            AND profiles.is_active = true
            AND (profiles.role = 'super_admin' OR profiles.station_id = station_settings.station_id)
        )
    );

CREATE POLICY station_settings_insert_admin ON public.station_settings
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('super_admin', 'admin')
            AND profiles.is_active = true
            AND (profiles.role = 'super_admin' OR profiles.station_id = station_settings.station_id)
        )
    );

-- ============================================================================
-- 2. New columns on donations for check payment details
-- ============================================================================
-- check_number already exists (added in base migration).
-- These new fields track the full check lifecycle:
--   pledge time → check_date (date on the check)
--   settlement  → check_settlement_date, check_deposit_reference, check_settled_by

-- Date written on the check (entered by operator at pledge time)
ALTER TABLE public.donations
    ADD COLUMN IF NOT EXISTS check_date date;

-- Date the check cleared at the bank (entered at settlement)
ALTER TABLE public.donations
    ADD COLUMN IF NOT EXISTS check_settlement_date date;

-- Bank deposit batch/slip number — audit trail for reconciliation
ALTER TABLE public.donations
    ADD COLUMN IF NOT EXISTS check_deposit_reference text;

-- Staff member who confirmed the check cleared (or bounced)
ALTER TABLE public.donations
    ADD COLUMN IF NOT EXISTS check_settled_by uuid REFERENCES public.profiles(id);

-- ============================================================================
-- 3. Indexes for new query patterns
-- ============================================================================

-- Unsettled checks queue — operators need to see checks awaiting clearance
CREATE INDEX IF NOT EXISTS donations_check_pending_idx
    ON public.donations(station_id, created_at DESC)
    WHERE payment_provider = 'check'
    AND status = 'pending'
    AND deleted_at IS NULL;

-- Bill-me pledges queue — donations awaiting payment collection
CREATE INDEX IF NOT EXISTS donations_bill_me_pledged_idx
    ON public.donations(station_id, payment_due_at)
    WHERE status = 'pledged'
    AND deleted_at IS NULL;

-- Check settled_by FK index
CREATE INDEX IF NOT EXISTS donations_check_settled_by_idx
    ON public.donations(check_settled_by)
    WHERE check_settled_by IS NOT NULL;

-- ============================================================================
-- 4. Comments for documentation
-- ============================================================================

COMMENT ON TABLE public.station_settings IS 'Per-station configurable settings stored as JSONB. Categories: phone_pledge (bill-me days, reminders, payment methods), email, etc.';
COMMENT ON COLUMN public.station_settings.settings IS 'JSONB settings grouped by category. phone_pledge: { bill_me_due_days, reminder_days, enabled_methods }';

COMMENT ON COLUMN public.donations.check_date IS 'Date written on the check (entered at pledge time for phone check payments)';
COMMENT ON COLUMN public.donations.check_settlement_date IS 'Date the check cleared at the bank (entered at settlement confirmation)';
COMMENT ON COLUMN public.donations.check_deposit_reference IS 'Bank deposit batch/slip number for reconciliation audit trail';
COMMENT ON COLUMN public.donations.check_settled_by IS 'Staff member (profile UUID) who confirmed check clearance or bounce';

-- Tell PostgREST to reload schema so it sees new table and columns
NOTIFY pgrst, 'reload schema';
