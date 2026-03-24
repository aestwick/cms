-- ============================================================================
-- Migration 019: Grant Role Permissions
-- ============================================================================
-- Supabase normally handles these grants automatically, but if the database
-- is dropped and rebuilt, they may be missing. This migration ensures all
-- roles have proper table access.
--
-- Roles:
--   - service_role: Backend/webhooks (full access, bypasses RLS)
--   - authenticated: Logged-in staff users (controlled by RLS)
--   - anon: Public/unauthenticated (read-only on public tables)
-- ============================================================================

-- ============================================================================
-- SERVICE_ROLE: Full access to all tables (used by backend API routes)
-- ============================================================================

GRANT ALL ON TABLE stations TO service_role;
GRANT ALL ON TABLE shows TO service_role;
GRANT ALL ON TABLE campaigns TO service_role;
GRANT ALL ON TABLE donors TO service_role;
GRANT ALL ON TABLE donations TO service_role;
GRANT ALL ON TABLE memberships TO service_role;
GRANT ALL ON TABLE checkout_sessions TO service_role;
GRANT ALL ON TABLE gifts TO service_role;
GRANT ALL ON TABLE gift_variants TO service_role;
GRANT ALL ON TABLE fulfillment_items TO service_role;
GRANT ALL ON TABLE tax_documents TO service_role;
GRANT ALL ON TABLE email_log TO service_role;
GRANT ALL ON TABLE audit_log TO service_role;
GRANT ALL ON TABLE system_events TO service_role;
GRANT ALL ON TABLE profiles TO service_role;
GRANT ALL ON TABLE addresses TO service_role;
GRANT ALL ON TABLE donor_notes TO service_role;
GRANT ALL ON TABLE donor_tags TO service_role;
GRANT ALL ON TABLE invites TO service_role;

-- M3 Events tables (if they exist)
DO $$ BEGIN
    GRANT ALL ON TABLE events TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT ALL ON TABLE ticket_types TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT ALL ON TABLE event_registrations TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT ALL ON TABLE promo_codes TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

-- M4 Stewardship tables (if they exist)
DO $$ BEGIN
    GRANT ALL ON TABLE match_pools TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT ALL ON TABLE match_allocations TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT ALL ON TABLE thank_you_calls TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

-- M5 Underwriting tables (if they exist)
DO $$ BEGIN
    GRANT ALL ON TABLE underwriters TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT ALL ON TABLE underwriting_contracts TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT ALL ON TABLE underwriting_spots TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT ALL ON TABLE underwriting_invoices TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

-- Program schedule tables (if they exist)
DO $$ BEGIN
    GRANT ALL ON TABLE programs TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT ALL ON TABLE program_categories TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT ALL ON TABLE program_hosts TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT ALL ON TABLE program_host_assignments TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT ALL ON TABLE program_schedule TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT ALL ON TABLE donation_inspirations TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

-- Operator activity log (if exists)
DO $$ BEGIN
    GRANT ALL ON TABLE operator_activity_log TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

-- Station sequences (if exists)
DO $$ BEGIN
    GRANT ALL ON TABLE station_sequences TO service_role;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

-- ============================================================================
-- AUTHENTICATED: Staff user access (RLS controls row-level access)
-- ============================================================================

-- Core tables - full access for staff operations
GRANT ALL ON TABLE donors TO authenticated;
GRANT ALL ON TABLE donations TO authenticated;
GRANT ALL ON TABLE memberships TO authenticated;
GRANT ALL ON TABLE checkout_sessions TO authenticated;
GRANT ALL ON TABLE fulfillment_items TO authenticated;
GRANT ALL ON TABLE addresses TO authenticated;
GRANT ALL ON TABLE donor_notes TO authenticated;
GRANT ALL ON TABLE donor_tags TO authenticated;
GRANT ALL ON TABLE tax_documents TO authenticated;
GRANT ALL ON TABLE email_log TO authenticated;
GRANT ALL ON TABLE audit_log TO authenticated;

-- Reference tables - read access
GRANT SELECT ON TABLE stations TO authenticated;
GRANT SELECT ON TABLE shows TO authenticated;
GRANT SELECT ON TABLE campaigns TO authenticated;
GRANT SELECT ON TABLE gifts TO authenticated;
GRANT SELECT ON TABLE gift_variants TO authenticated;
GRANT SELECT ON TABLE profiles TO authenticated;
GRANT SELECT ON TABLE invites TO authenticated;
GRANT SELECT ON TABLE system_events TO authenticated;

-- Admin tables - full access (RLS will restrict by role)
GRANT ALL ON TABLE campaigns TO authenticated;
GRANT ALL ON TABLE shows TO authenticated;
GRANT ALL ON TABLE gifts TO authenticated;
GRANT ALL ON TABLE gift_variants TO authenticated;
GRANT ALL ON TABLE profiles TO authenticated;
GRANT ALL ON TABLE invites TO authenticated;

-- Program schedule tables
DO $$ BEGIN
    GRANT SELECT ON TABLE programs TO authenticated;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT SELECT ON TABLE program_categories TO authenticated;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT SELECT ON TABLE program_hosts TO authenticated;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT SELECT ON TABLE program_schedule TO authenticated;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT ALL ON TABLE donation_inspirations TO authenticated;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

-- Operator activity log
DO $$ BEGIN
    GRANT ALL ON TABLE operator_activity_log TO authenticated;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

-- ============================================================================
-- ANON: Public read access (for donation forms, widgets, etc.)
-- ============================================================================

GRANT SELECT ON TABLE stations TO anon;
GRANT SELECT ON TABLE shows TO anon;
GRANT SELECT ON TABLE campaigns TO anon;
GRANT SELECT ON TABLE gifts TO anon;
GRANT SELECT ON TABLE gift_variants TO anon;

-- Program schedule - public read for website
DO $$ BEGIN
    GRANT SELECT ON TABLE programs TO anon;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT SELECT ON TABLE program_categories TO anon;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT SELECT ON TABLE program_hosts TO anon;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
    GRANT SELECT ON TABLE program_schedule TO anon;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

-- ============================================================================
-- SEQUENCE PERMISSIONS (for INSERT with auto-generated IDs)
-- ============================================================================

-- Grant usage on all sequences to roles that need to insert
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ============================================================================
-- End of Migration 019
-- ============================================================================
