-- ============================================================================
-- RLS Policy Verification Script
-- ============================================================================
-- Run this in the Supabase SQL Editor to verify RLS policies are working.
--
-- This script:
--   1. Lists all tables with RLS enabled
--   2. Shows all active policies
--   3. Highlights any potential issues
--
-- For automated testing, use: npm run test:rls
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Check which tables have RLS enabled
-- ----------------------------------------------------------------------------
SELECT
    schemaname,
    tablename,
    rowsecurity as "RLS Enabled"
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- ----------------------------------------------------------------------------
-- 2. List all RLS policies with their definitions
-- ----------------------------------------------------------------------------
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual as "USING clause",
    with_check as "WITH CHECK clause"
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ----------------------------------------------------------------------------
-- 3. Summary: Count policies per table
-- ----------------------------------------------------------------------------
SELECT
    tablename,
    COUNT(*) as policy_count,
    COUNT(*) FILTER (WHERE cmd = 'SELECT') as select_policies,
    COUNT(*) FILTER (WHERE cmd = 'INSERT') as insert_policies,
    COUNT(*) FILTER (WHERE cmd = 'UPDATE') as update_policies,
    COUNT(*) FILTER (WHERE cmd = 'DELETE') as delete_policies,
    COUNT(*) FILTER (WHERE cmd = 'ALL') as all_policies
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- ----------------------------------------------------------------------------
-- 4. Check for tables without RLS (potential security issue)
-- ----------------------------------------------------------------------------
SELECT
    t.tablename as "Tables WITHOUT RLS"
FROM pg_tables t
LEFT JOIN (
    SELECT DISTINCT tablename
    FROM pg_policies
    WHERE schemaname = 'public'
) p ON t.tablename = p.tablename
WHERE t.schemaname = 'public'
AND t.rowsecurity = false
AND t.tablename NOT LIKE 'pg_%'
AND t.tablename NOT LIKE '_prisma_%'
ORDER BY t.tablename;

-- ----------------------------------------------------------------------------
-- 5. Verify critical policies exist
-- ----------------------------------------------------------------------------
-- Check that audit_log is restricted to super_admin
SELECT
    'audit_log super_admin restriction' as check_name,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM pg_policies
            WHERE tablename = 'audit_log'
            AND policyname = 'audit_log_super_admin_select'
        ) THEN '✓ PASS'
        ELSE '✗ FAIL - audit_log_super_admin_select policy not found'
    END as status;

-- Check that donors has station scoping
SELECT
    'donors station scoping' as check_name,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM pg_policies
            WHERE tablename = 'donors'
            AND policyname = 'donors_station_staff_select'
        ) THEN '✓ PASS'
        ELSE '✗ FAIL - donors_station_staff_select policy not found'
    END as status;

-- Check that donations has station scoping
SELECT
    'donations station scoping' as check_name,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM pg_policies
            WHERE tablename = 'donations'
            AND policyname = 'donations_station_staff_select'
        ) THEN '✓ PASS'
        ELSE '✗ FAIL - donations_station_staff_select policy not found'
    END as status;

-- Check for old placeholder policies (should NOT exist)
SELECT
    'old placeholder policies removed' as check_name,
    CASE
        WHEN NOT EXISTS (
            SELECT 1 FROM pg_policies
            WHERE policyname IN (
                'donors_authenticated_select',
                'donations_authenticated_select',
                'audit_log_authenticated_select'
            )
        ) THEN '✓ PASS'
        ELSE '✗ FAIL - Old placeholder policies still exist'
    END as status;

-- ============================================================================
-- End of verification script
-- ============================================================================
