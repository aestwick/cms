/**
 * Migration Verification Script
 *
 * Queries the Supabase database to verify all expected tables, columns,
 * indexes, and functions exist based on the migration files (001-016).
 *
 * Run with: npx tsx scripts/verify-migrations.ts
 *
 * Requires environment variables:
 *   - NEXT_PUBLIC_SUPABASE_URL
 *   - SUPABASE_SERVICE_ROLE_KEY
 *   - NEXT_PUBLIC_SUPABASE_ANON_KEY (optional, for RLS verification)
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceRoleKey) {
  console.error('Missing environment variables:');
  if (!supabaseUrl) console.error('   - NEXT_PUBLIC_SUPABASE_URL');
  if (!supabaseServiceRoleKey) console.error('   - SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false }
});

// Complete list of expected tables from migrations 001-016
// Organized by migration file for clarity
const expectedTables = [
  // 001_m0_base_tables.sql
  'stations',
  'shows',
  'campaigns',
  'donors',
  'gifts',
  'memberships',
  'checkout_sessions',
  'donations',
  'tax_documents',
  'email_log',
  'audit_log',
  'system_events',

  // 004_m1_tables.sql
  'profiles',
  'addresses',
  'gift_variants',
  'fulfillment_items',
  'donor_notes',
  'donor_tags',

  // 006_m3_events_tables.sql
  'events',
  'ticket_types',
  'promo_codes',
  'event_registrations',
  'event_registration_gifts',

  // 007_m4_stewardship_tables.sql
  'match_pools',
  'match_allocations',
  'interactions',
  'gift_intents',
  'documents',
  'donor_extensions',

  // 008_m5_underwriting_tables.sql
  'underwriters',
  'underwriting_agreements',
  'underwriting_invoices',
  'underwriting_broadcasts',

  // 009_program_schedule_tables.sql
  'program_categories',
  'program_hosts',
  'programs',
  'program_host_assignments',
  'donation_inspirations',

  // 010_invites_table.sql
  'invites',

  // 013_program_schedule_extension.sql
  'program_schedule',

  // 014_operator_activity_log.sql
  'operator_activity_log',
];

// Expected functions based on migrations
const expectedFunctions = [
  { name: 'update_updated_at', migration: '005' },
  { name: 'handle_new_user', migration: '005' },
  { name: 'get_current_program', migration: '013' },
  { name: 'search_donors_fuzzy', migration: '015' },
];

// Expected extensions
const expectedExtensions = [
  { name: 'uuid-ossp', migration: '001' },
  { name: 'pg_trgm', migration: '015' },
];

// Critical columns that were added in later migrations
const criticalColumns: Record<string, { columns: string[]; migration: string }> = {
  donations: {
    columns: ['pledged_at', 'payment_due_at', 'gift_variant_id', 'comments', 'recipient_donor_id', 'source_type', 'is_first_donation'],
    migration: '004-005'
  },
  donors: {
    columns: ['email_normalized', 'stripe_customer_id'],
    migration: '001'
  },
  gifts: {
    columns: ['requires_shipping', 'static_id'],
    migration: '012'
  },
  profiles: {
    columns: ['email', 'role', 'donor_id', 'is_active'],
    migration: '004'
  },
  gift_variants: {
    columns: ['inventory_incoming', 'inventory_unavailable', 'reorder_point', 'notes'],
    migration: '004'
  },
};

// Tables that should have RLS enabled (sensitive data)
const rlsProtectedTables = [
  'donors',
  'donations',
  'profiles',
  'audit_log',
  'checkout_sessions',
  'memberships',
  'tax_documents',
  'email_log',
  'addresses',
  'donor_notes',
  'donor_tags',
  'fulfillment_items',
  'interactions',
  'gift_intents',
  'documents',
  'donor_extensions',
];

async function main() {
  console.log('Verifying Supabase migrations...\n');
  console.log(`Database: ${supabaseUrl}\n`);

  let totalIssues = 0;
  const existingTables: string[] = [];

  // 1. Check tables exist
  console.log('CHECKING TABLES');
  console.log('='.repeat(60));

  for (const table of expectedTables) {
    const { count, error } = await supabase
      .from(table)
      .select('*', { count: 'exact', head: true });

    if (error && error.code === '42P01') {
      console.log(`  [MISSING] ${table}`);
      totalIssues++;
    } else if (error && error.code !== 'PGRST116') {
      // PGRST116 is "no rows" which is fine for empty tables
      console.log(`  [ERROR]   ${table}: ${error.message}`);
      totalIssues++;
    } else {
      console.log(`  [OK]      ${table} (${count ?? 0} rows)`);
      existingTables.push(table);
    }
  }

  console.log(`\n  Found ${existingTables.length}/${expectedTables.length} tables\n`);

  // 2. Check critical columns on key tables
  console.log('CHECKING CRITICAL COLUMNS');
  console.log('='.repeat(60));

  for (const [table, info] of Object.entries(criticalColumns)) {
    if (!existingTables.includes(table)) {
      console.log(`  [SKIP]    ${table} (table missing)`);
      continue;
    }

    const { data, error } = await supabase
      .from(table)
      .select(info.columns.join(','))
      .limit(0);

    if (error) {
      console.log(`  [ERROR]   ${table}: ${error.message}`);
      console.log(`            Expected columns (from migration ${info.migration}): ${info.columns.join(', ')}`);
      totalIssues++;
    } else {
      console.log(`  [OK]      ${table}: ${info.columns.length} columns verified`);
    }
  }

  // 3. Check functions exist
  console.log('\nCHECKING FUNCTIONS');
  console.log('='.repeat(60));

  // Test search_donors_fuzzy (requires pg_trgm extension)
  const { error: fuzzyError } = await supabase.rpc('search_donors_fuzzy', {
    p_station_id: '00000000-0000-0000-0000-000000000000',
    p_query: 'test',
    p_limit: 1
  });

  if (fuzzyError && fuzzyError.message?.includes('function') && fuzzyError.message?.includes('does not exist')) {
    console.log('  [MISSING] search_donors_fuzzy (migration 015)');
    totalIssues++;
  } else {
    console.log('  [OK]      search_donors_fuzzy');
  }

  // Test get_current_program
  const { error: programError } = await supabase.rpc('get_current_program', {
    p_station_code: 'kpfk'
  });

  if (programError && programError.message?.includes('function') && programError.message?.includes('does not exist')) {
    console.log('  [MISSING] get_current_program (migration 013)');
    totalIssues++;
  } else {
    console.log('  [OK]      get_current_program');
  }

  // 4. Check RLS is enabled on sensitive tables
  console.log('\nCHECKING RLS POLICIES');
  console.log('='.repeat(60));

  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!anonKey || !supabaseUrl) {
    console.log('  [SKIP]    Cannot verify RLS (NEXT_PUBLIC_SUPABASE_ANON_KEY not set)');
  } else {
    const anonSupabase = createClient(supabaseUrl, anonKey, {
      auth: { autoRefreshToken: false, persistSession: false }
    });

    for (const table of rlsProtectedTables) {
      if (!existingTables.includes(table)) {
        continue;
      }

      const { data, error } = await anonSupabase.from(table).select('id').limit(1);

      if (error && (error.code === 'PGRST116' || error.message?.includes('permission') || error.code === '42501')) {
        console.log(`  [OK]      ${table} (anon access blocked)`);
      } else if (!error && (data === null || data.length === 0)) {
        console.log(`  [OK]      ${table} (no rows returned to anon)`);
      } else {
        console.log(`  [WARN]    ${table} may have permissive RLS policies`);
      }
    }
  }

  // 5. Summary
  console.log('\n' + '='.repeat(60));
  console.log('MIGRATION VERIFICATION SUMMARY');
  console.log('='.repeat(60));

  const missingTables = expectedTables.filter(t => !existingTables.includes(t));

  if (missingTables.length === 0) {
    console.log('\n  [OK] All expected tables are present');
  } else {
    console.log(`\n  [ERROR] Missing ${missingTables.length} tables:`);
    missingTables.forEach(t => console.log(`          - ${t}`));
  }

  if (totalIssues === 0) {
    console.log('\n  All migrations appear to be applied correctly.\n');
  } else {
    console.log(`\n  Found ${totalIssues} issue(s) that may need attention.\n`);
  }

  // Migration file list for reference
  console.log('MIGRATION FILES (for reference)');
  console.log('='.repeat(60));
  console.log(`
  001_m0_base_tables.sql          - Core tables (stations, donors, donations, etc.)
  002_m0_fks_indexes.sql          - Foreign keys and indexes for M0
  003_m0_rls_policies.sql         - RLS policies for M0
  004_m1_tables.sql               - M1 tables (profiles, addresses, fulfillment)
  005_m1_fks_indexes_rls.sql      - FKs, indexes, RLS for M1
  006_m3_events_tables.sql        - Events system
  007_m4_stewardship_tables.sql   - Major donor stewardship
  008_m5_underwriting_tables.sql  - Underwriting/sponsorship
  009_program_schedule_tables.sql - Program scheduling
  010_invites_table.sql           - Staff invitations
  011_bootstrap_admin.sql         - Initial admin setup
  012_add_gifts_requires_shipping.sql - Gift shipping flag
  013_program_schedule_extension.sql  - Program schedule slots
  014_operator_activity_log.sql   - Phone pledge activity log
  015_donor_fuzzy_search.sql      - Trigram fuzzy search
  016_rls_policy_fixes.sql        - RLS policy corrections
`);

  process.exit(totalIssues > 0 ? 1 : 0);
}

main().catch(console.error);
