-- Migration 066: Events platform schema additions
-- Adds columns and tables needed for the events platform build (Chunk 1).
--
-- Changes:
--   1. ticket_types.attendees_per_ticket — how many people one ticket admits (default 1, VIP Pair = 2)
--   2. events.member_pricing_enabled — per-event toggle to disable automatic member discounts
--   3. event_orders.comp_reason — why a comp was issued (press, staff, donor guest, etc.)
--   4. event_email_ticket_types — join table so emails can target specific ticket type holders
--   5. event_emails.email_type CHECK — add 'vip_confirmation' for dedicated VIP confirmation emails

-- ============================================================================
-- 1. attendees_per_ticket on ticket_types
-- ============================================================================
-- A "VIP Pair" ticket admits 2 people but is purchased as 1 ticket.
-- This multiplier is used in capacity math: venue_capacity_cap and
-- ticket_type capacity both need to deduct the real headcount, not
-- the ticket count. Default 1 so existing tickets behave unchanged.

ALTER TABLE public.ticket_types
  ADD COLUMN IF NOT EXISTS attendees_per_ticket integer NOT NULL DEFAULT 1;

ALTER TABLE public.ticket_types
  ADD CONSTRAINT ticket_types_attendees_per_ticket_check
    CHECK (attendees_per_ticket >= 1);

COMMENT ON COLUMN public.ticket_types.attendees_per_ticket IS
  'Number of people admitted per ticket (e.g., 2 for a pair ticket). Used in capacity calculations.';

-- ============================================================================
-- 2. member_pricing_enabled on events
-- ============================================================================
-- When false, the checkout route skips automatic member discounts for this
-- event. Useful when sustainer perks are handled via promo codes or
-- priority seating instead. Default true preserves existing behavior.

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS member_pricing_enabled boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.events.member_pricing_enabled IS
  'When false, automatic member ticket discounts are disabled for this event.';

-- ============================================================================
-- 3. comp_reason on event_orders
-- ============================================================================
-- When payment_provider = 'comp', this records WHY the ticket was comped.
-- Important for audit trail and reporting (how many press vs staff vs guest comps).

ALTER TABLE public.event_orders
  ADD COLUMN IF NOT EXISTS comp_reason text;

COMMENT ON COLUMN public.event_orders.comp_reason IS
  'Reason for comp (e.g., press, staff, donor_guest, volunteer). Only set when payment_provider = comp.';

-- ============================================================================
-- 4. event_email_ticket_types join table
-- ============================================================================
-- Scopes an email sequence entry to specific ticket types. When rows exist
-- for an event_email, only buyers holding those ticket types receive the
-- email. When no rows exist, all buyers receive it (unscoped = send to all).

CREATE TABLE IF NOT EXISTS public.event_email_ticket_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_email_id uuid NOT NULL REFERENCES public.event_emails(id) ON DELETE CASCADE,
  ticket_type_id uuid NOT NULL REFERENCES public.ticket_types(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),

  -- Each ticket type can only be linked once per email
  UNIQUE (event_email_id, ticket_type_id)
);

CREATE INDEX IF NOT EXISTS event_email_tt_email_id_idx
  ON public.event_email_ticket_types (event_email_id);

CREATE INDEX IF NOT EXISTS event_email_tt_ticket_type_id_idx
  ON public.event_email_ticket_types (ticket_type_id);

-- RLS: staff can read, service_role can do everything
ALTER TABLE public.event_email_ticket_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY event_email_tt_staff_select ON public.event_email_ticket_types
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.is_active = true
        AND p.deleted_at IS NULL
        AND p.role IN ('super_admin', 'admin', 'ops', 'event_manager')
    )
  );

CREATE POLICY event_email_tt_service_role_all ON public.event_email_ticket_types
  FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);

-- Grant access matching other event tables (migration 056 pattern)
GRANT ALL ON public.event_email_ticket_types TO postgres, service_role, authenticated, anon;

-- ============================================================================
-- 5. Add 'vip_confirmation' to event_emails email_type CHECK
-- ============================================================================
-- The unique constraint on (event_id, email_type) means we can't have two
-- 'confirmation' rows for the same event. Adding a dedicated type for VIP
-- confirmations is simpler than rearchitecting the email system.

ALTER TABLE public.event_emails
  DROP CONSTRAINT IF EXISTS event_emails_type_check;

ALTER TABLE public.event_emails
  ADD CONSTRAINT event_emails_type_check
    CHECK (email_type = ANY (ARRAY[
      'confirmation',
      'vip_confirmation',
      'reminder_1',
      'reminder_2',
      'reminder_3',
      'followup',
      'cancellation',
      'reschedule'
    ]));

-- ============================================================================
-- Notify PostgREST to reload schema
-- ============================================================================
NOTIFY pgrst, 'reload schema';
