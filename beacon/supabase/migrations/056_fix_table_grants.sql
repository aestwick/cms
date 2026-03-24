-- Migration 056: Fix missing table-level GRANT privileges
--
-- Problem: Migrations 045-055 were applied by pasting SQL into the Supabase
-- SQL Editor instead of using `supabase db push`. The SQL Editor runs as the
-- `postgres` role, which owns the tables, but doesn't automatically set up
-- the default GRANT privileges that `supabase db push` applies. This means
-- the `service_role` (used by all admin API routes) can't read/write these
-- tables, causing "Failed to save settings" and similar errors.
--
-- Fix: Explicitly GRANT ALL on every table created in migrations 045-055
-- to the four standard Supabase roles.

-- ============================================================================
-- Tables from migration 045 (bill-me, check, cash, station settings)
-- ============================================================================
GRANT ALL ON public.station_settings TO postgres, service_role, authenticated, anon;

-- ============================================================================
-- Tables from migration 046 (feedback status and notes)
-- ============================================================================
GRANT ALL ON public.feedback_notes TO postgres, service_role, authenticated, anon;

-- ============================================================================
-- Tables from migration 048 (membership tiers)
-- ============================================================================
GRANT ALL ON public.membership_tiers TO postgres, service_role, authenticated, anon;

-- ============================================================================
-- Tables from migration 050 (digital assets)
-- ============================================================================
GRANT ALL ON public.digital_assets TO postgres, service_role, authenticated, anon;
GRANT ALL ON public.digital_asset_entitlements TO postgres, service_role, authenticated, anon;
GRANT ALL ON public.digital_asset_access_log TO postgres, service_role, authenticated, anon;

-- ============================================================================
-- Tables from migration 052 (M3 events)
-- ============================================================================
GRANT ALL ON public.venues TO postgres, service_role, authenticated, anon;
GRANT ALL ON public.event_series TO postgres, service_role, authenticated, anon;
GRANT ALL ON public.promo_code_ticket_types TO postgres, service_role, authenticated, anon;
GRANT ALL ON public.event_orders TO postgres, service_role, authenticated, anon;
GRANT ALL ON public.event_order_items TO postgres, service_role, authenticated, anon;
GRANT ALL ON public.event_tickets TO postgres, service_role, authenticated, anon;
GRANT ALL ON public.event_questions TO postgres, service_role, authenticated, anon;
GRANT ALL ON public.event_question_responses TO postgres, service_role, authenticated, anon;
GRANT ALL ON public.event_emails TO postgres, service_role, authenticated, anon;
GRANT ALL ON public.event_waitlist TO postgres, service_role, authenticated, anon;

-- ============================================================================
-- Reload PostgREST schema cache
-- ============================================================================
NOTIFY pgrst, 'reload schema';
