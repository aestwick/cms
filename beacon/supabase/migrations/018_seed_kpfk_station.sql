-- ============================================================================
-- Migration 018: Seed KPFK Station (Required for Checkout)
--
-- The DO block in migration 009 can fail silently. This migration ensures
-- the KPFK station exists using a simple INSERT with ON CONFLICT.
-- ============================================================================

-- Ensure KPFK station exists (required for checkout API)
INSERT INTO stations (code, call_sign, name, timezone)
VALUES ('kpfk', 'KPFK', 'KPFK 90.7 FM Los Angeles', 'America/Los_Angeles')
ON CONFLICT (code) DO NOTHING;
