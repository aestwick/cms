-- ============================================================================
-- Migration 025: Grant Permissions for Press Passes Tables
-- ============================================================================
-- Migration 024 created press_passes and verification_logs with RLS policies,
-- but forgot to GRANT table-level access to the Postgres roles. Without these
-- GRANTs, all queries fail with error 42501 "permission denied for table
-- press_passes" — even though the RLS policies would allow the access.
--
-- Postgres permission model: GRANTs control table-level access, RLS controls
-- row-level access. You need both.
-- ============================================================================

-- ============================================================================
-- SERVICE_ROLE: Full access (used by admin API routes, bypasses RLS)
-- ============================================================================
GRANT ALL ON TABLE press_passes TO service_role;
GRANT ALL ON TABLE verification_logs TO service_role;

-- ============================================================================
-- AUTHENTICATED: Staff users (RLS policies control which rows they see)
-- ============================================================================
-- Staff can read press passes for their station (RLS enforces station scope)
GRANT SELECT ON TABLE press_passes TO authenticated;

-- Staff can read and insert verification logs (RLS enforces station scope for reads)
GRANT SELECT, INSERT ON TABLE verification_logs TO authenticated;

-- ============================================================================
-- ANON: Public verification access (no auth required to check a pass)
-- ============================================================================
-- Anon can read press passes for verification (RLS filters to non-deleted only)
GRANT SELECT ON TABLE press_passes TO anon;

-- Anon can insert verification logs (to record lookup attempts from public page)
GRANT INSERT ON TABLE verification_logs TO anon;

-- ============================================================================
-- End of Migration 025
-- ============================================================================
