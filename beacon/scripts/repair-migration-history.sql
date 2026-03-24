-- ============================================================================
-- REPAIR SCRIPT: Sync Migration History
-- ============================================================================
-- Run this in the Supabase SQL Editor to fix the migration history table.
-- This marks migrations 001-009 as already applied (since they are).
--
-- After running this, supabase db push will only apply migrations 010+
-- ============================================================================

-- Create the schema_migrations table if it doesn't exist
-- (Supabase CLI normally creates this, but it may not exist if migrations were applied manually)
CREATE SCHEMA IF NOT EXISTS supabase_migrations;

CREATE TABLE IF NOT EXISTS supabase_migrations.schema_migrations (
    version text PRIMARY KEY,
    name text,
    statements text[]
);

-- Insert records for migrations that have already been applied
-- The version is the timestamp prefix of the migration file
-- Since we use numeric prefixes (001_, 002_, etc.), we'll use those as versions

INSERT INTO supabase_migrations.schema_migrations (version, name, statements)
VALUES
    ('001', '001_m0_base_tables.sql', NULL),
    ('002', '002_m0_fks_indexes.sql', NULL),
    ('003', '003_m0_rls_policies.sql', NULL),
    ('004', '004_m1_tables.sql', NULL),
    ('005', '005_m1_fks_indexes_rls.sql', NULL),
    ('006', '006_m3_events_tables.sql', NULL),
    ('007', '007_m4_stewardship_tables.sql', NULL),
    ('008', '008_m5_underwriting_tables.sql', NULL),
    ('009', '009_program_schedule_tables.sql', NULL)
ON CONFLICT (version) DO NOTHING;

-- Verify the records were inserted
SELECT * FROM supabase_migrations.schema_migrations ORDER BY version;

-- ============================================================================
-- After running this script:
-- 1. Go to GitHub Actions
-- 2. Run "Verify Supabase Migrations" with "Push migrations" checked
-- 3. It should now only apply migrations 010-017
-- ============================================================================
