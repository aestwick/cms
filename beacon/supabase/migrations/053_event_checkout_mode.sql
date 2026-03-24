-- Migration 053: Add 'event' mode to checkout_sessions
-- Needed for Phase 7: event ticket checkout via Stripe Checkout Sessions.
-- The existing checkout flow stores snapshots in checkout_sessions with mode='web'.
-- Event checkouts will use mode='event' so the webhook handler can distinguish
-- and route to the event-specific order creation logic.

-- Widen the CHECK constraint to include 'event' as a valid checkout mode
ALTER TABLE checkout_sessions
  DROP CONSTRAINT IF EXISTS checkout_sessions_mode_check;

ALTER TABLE checkout_sessions
  ADD CONSTRAINT checkout_sessions_mode_check
  CHECK (mode = ANY (ARRAY['web', 'phone_card', 'phone_check', 'phone_cash', 'event']));

-- Add an index on event_orders.confirmation_code for fast customer-facing lookups.
-- The confirmation code is what buyers use to find their order (e.g., KPFK-A3X9).
CREATE INDEX IF NOT EXISTS idx_event_orders_confirmation_code
  ON event_orders (confirmation_code);

-- Add a unique constraint on event_orders.order_number to prevent duplicates.
-- The order number is the sequential admin-facing identifier (e.g., EVT-000042).
CREATE UNIQUE INDEX IF NOT EXISTS idx_event_orders_order_number_unique
  ON event_orders (order_number);

-- Add index on event_tickets.qr_token_hash for check-in lookups.
-- At the door, QR scans look up tickets by the token hash.
CREATE INDEX IF NOT EXISTS idx_event_tickets_qr_token_hash
  ON event_tickets (qr_token_hash);

-- Add index on event_tickets by order for order detail lookups
CREATE INDEX IF NOT EXISTS idx_event_tickets_order_id
  ON event_tickets (order_id);

-- Add index on event_order_items by order for order detail lookups
CREATE INDEX IF NOT EXISTS idx_event_order_items_order_id
  ON event_order_items (order_id);

-- Add unique constraint on event_orders.stripe_payment_intent_id for idempotency.
-- Prevents duplicate orders from Stripe webhook retries that bypass higher-level
-- dedup layers (system_events + session status check). Matches the defense-in-depth
-- pattern used on the donations table (donations_stripe_pi_unique_idx).
-- Partial index: only for non-null values (free orders have no payment intent).
CREATE UNIQUE INDEX IF NOT EXISTS idx_event_orders_stripe_pi_unique
  ON event_orders (stripe_payment_intent_id)
  WHERE stripe_payment_intent_id IS NOT NULL;

-- Tell PostgREST to reload schema so it sees the new constraint
NOTIFY pgrst, 'reload schema';
