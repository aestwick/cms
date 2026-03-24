-- Migration 071: Event-Donation Bridge
-- ============================================================================
-- Adds infrastructure for bridging event ticket revenue into the donations
-- system. When a paid event order completes, a bridge donation row is created
-- so that event revenue shows up in donor profiles, campaign stats, CSV
-- exports, and dashboard totals.
--
-- Changes:
--   1. Add event_order_id column to donations (FK → event_orders)
--   2. Add unique index on event_order_id (one bridge donation per order)
--   3. Index for fast lookup of bridge donations
--
-- Notes:
--   - donations.source_type has no CHECK constraint (plain text column),
--     so 'event' value works without constraint modification.
--   - The 'cancelled' ticket status is already handled by the
--     decrement_ticket_sold_count trigger (migration 052).
--   - Bridge donations are created with source_type='event' so they can
--     be filtered in/out of the donations list as needed.
-- ============================================================================

-- 1. Add event_order_id column to donations table.
-- Links a bridge donation to its source event order.
-- Nullable because most donations aren't from events.
ALTER TABLE donations
  ADD COLUMN IF NOT EXISTS event_order_id uuid REFERENCES event_orders(id);

-- 2. Unique index — one bridge donation per event order.
-- Prevents duplicate bridge rows if the creation logic runs twice.
CREATE UNIQUE INDEX IF NOT EXISTS idx_donations_event_order_id_unique
  ON donations (event_order_id) WHERE event_order_id IS NOT NULL;

-- 3. Partial index for fast queries filtering bridge donations.
-- Used by refund cascade (find bridge donation by event_order_id)
-- and by report queries that want to include/exclude event revenue.
CREATE INDEX IF NOT EXISTS idx_donations_source_type_event
  ON donations (source_type) WHERE source_type = 'event';

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
