-- Migration 047: Every.org stock donation webhook support
--
-- Adds infrastructure for receiving stock donation notifications from Every.org.
-- Every.org handles stock liquidation and sends a webhook with the converted
-- USD amount when the donation completes. No Stripe involvement.
--
-- Changes:
-- 1. Add 'every_org' to donations.payment_provider CHECK constraint
-- 2. Add every_org_charge_id column for idempotent dedup
-- 3. Add index on every_org_charge_id for fast lookups
-- 4. Add private_note column to donations for Every.org private notes

-- ============================================================================
-- 1. Expand payment_provider to include 'every_org'
-- ============================================================================
-- Every.org is a third-party donation platform that handles stock liquidation
-- and forwards the USD proceeds to the nonprofit via webhook.

ALTER TABLE public.donations
    DROP CONSTRAINT IF EXISTS donations_payment_provider_check;

ALTER TABLE public.donations
    ADD CONSTRAINT donations_payment_provider_check
    CHECK (payment_provider = ANY(ARRAY[
        'stripe'::text,
        'check'::text,
        'cash'::text,
        'every_org'::text
    ]));

-- ============================================================================
-- 2. Add every_org_charge_id for webhook idempotency
-- ============================================================================
-- Every.org sends a chargeId with each webhook. We store it here so we can
-- detect duplicate deliveries (Every.org doesn't guarantee exactly-once).

ALTER TABLE public.donations
    ADD COLUMN IF NOT EXISTS every_org_charge_id text;

-- Unique index for fast dedup lookups — only non-null values indexed
CREATE UNIQUE INDEX IF NOT EXISTS donations_every_org_charge_id_unique
    ON public.donations(every_org_charge_id)
    WHERE every_org_charge_id IS NOT NULL;

-- ============================================================================
-- 3. Add private_note for donor notes from Every.org
-- ============================================================================
-- Every.org lets donors send a private note to the nonprofit.
-- This is different from the public testimony (which we store in comments).

ALTER TABLE public.donations
    ADD COLUMN IF NOT EXISTS private_note text;

-- ============================================================================
-- Notify PostgREST to pick up schema changes
-- ============================================================================
NOTIFY pgrst, 'reload schema';
