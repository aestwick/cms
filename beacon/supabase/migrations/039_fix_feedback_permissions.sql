-- ============================================================================
-- Migration 039: Fix feedback_responses Table Permissions
-- ============================================================================
-- Fixes "permission denied for table feedback_responses" error on the admin
-- feedback dashboard. This is the same class of bug that hit press_passes
-- (fixed in migration 025) — migration 034 created the table with RLS but
-- no explicit GRANTs, and migration 038 bundled the GRANTs with a constraint
-- change that may not have applied cleanly.
--
-- This migration applies ONLY the GRANT statements, isolated from any schema
-- changes, to guarantee they take effect.
--
-- GRANTs are idempotent — re-granting permissions that already exist is a no-op.
-- ============================================================================

-- SERVICE_ROLE: Full access (used by admin API routes via getSupabaseAdmin)
GRANT ALL ON TABLE feedback_responses TO service_role;

-- AUTHENTICATED: Read access (used by RLS-gated queries if any route
-- ever uses the publishable key client instead of service role)
GRANT SELECT ON TABLE feedback_responses TO authenticated;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
