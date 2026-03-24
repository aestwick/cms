-- Migration 059: Recurring Gift Hold
--
-- Adds columns to hold fulfillment of gifts associated with recurring donations
-- until the donor has paid enough to cover the gift's fair market value (FMV).
--
-- Example: Donor pledges $10/month and selects a gift with $35 FMV.
-- The gift should not ship until cumulative payments >= max(FMV, 3 × monthly amount).
-- In this case: max($35, $30) = $35, so gift ships after 4th payment ($40 >= $35).
--
-- The hold is tracked on the fulfillment_item itself:
--   hold_threshold_cents: target cumulative payment amount before release
--   hold_cumulative_cents: running total of payments received (updated by invoicePaid webhook)
--   hold_membership_id: which membership to track payments for
--
-- Additionally, donations.membership_id links recurring payments back to the membership
-- that generated them, making it easy to sum cumulative payments.

-- ============================================================================
-- 1. Add hold columns to fulfillment_items
-- ============================================================================

-- Target cumulative payment amount before the item can ship.
-- NULL means no hold (standard one-time donation or no-FMV gift).
ALTER TABLE public.fulfillment_items
  ADD COLUMN hold_threshold_cents bigint;

-- Running total of cumulative payments received toward the threshold.
-- Updated by the invoicePaid webhook handler after each recurring payment.
ALTER TABLE public.fulfillment_items
  ADD COLUMN hold_cumulative_cents bigint NOT NULL DEFAULT 0;

-- Which membership generates the payments we're tracking.
-- Used by invoicePaid to find held fulfillment items for a given subscription.
ALTER TABLE public.fulfillment_items
  ADD COLUMN hold_membership_id uuid REFERENCES public.memberships(id);

-- ============================================================================
-- 2. Add membership_id to donations
-- ============================================================================

-- Links each recurring payment (donation) back to the membership that created it.
-- The first donation is also linked (set in checkoutCompleted after membership creation).
-- This makes summing cumulative payments for a membership straightforward.
ALTER TABLE public.donations
  ADD COLUMN membership_id uuid REFERENCES public.memberships(id);

CREATE INDEX idx_donations_membership_id
  ON public.donations(membership_id)
  WHERE membership_id IS NOT NULL;

-- ============================================================================
-- 3. Index for finding held fulfillment items by membership
-- ============================================================================

CREATE INDEX idx_fulfillment_items_hold_membership
  ON public.fulfillment_items(hold_membership_id)
  WHERE hold_membership_id IS NOT NULL AND hold_threshold_cents IS NOT NULL;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
