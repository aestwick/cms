/**
 * RLS Policy Verification Tests
 *
 * This script tests that Row Level Security policies are correctly configured.
 * It creates test users with different roles and verifies they can only access
 * data they're authorized to see.
 *
 * Prerequisites:
 *   - Supabase local dev running (supabase start)
 *   - Migrations applied (supabase db reset)
 *   - Environment variables set in .env.local
 *
 * Usage:
 *   npx tsx scripts/test-rls.ts
 *
 * What this tests:
 *   1. Anonymous users cannot access PII tables
 *   2. Staff can only see data in their station
 *   3. super_admin can see all stations
 *   4. Donors can only see their own data
 *   5. audit_log is restricted to super_admin only
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';

// Test configuration - uses local Supabase
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL || 'http://127.0.0.1:54321';
const SUPABASE_PUBLISHABLE_KEY = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY || '';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

interface TestResult {
  name: string;
  passed: boolean;
  details?: string;
}

interface TestUser {
  id: string;
  email: string;
  role: string;
  stationId: string | null;
  donorId?: string;
}

const results: TestResult[] = [];

function log(message: string) {
  console.log(`  ${message}`);
}

function pass(name: string, details?: string) {
  results.push({ name, passed: true, details });
  console.log(`  ✓ ${name}`);
}

function fail(name: string, details?: string) {
  results.push({ name, passed: false, details });
  console.log(`  ✗ ${name}${details ? `: ${details}` : ''}`);
}

// Create admin client that bypasses RLS
function getAdminClient(): SupabaseClient {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false }
  });
}

// Create anon client (no auth)
function getAnonClient(): SupabaseClient {
  return createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false }
  });
}

// Create authenticated client for a specific user
async function getAuthenticatedClient(email: string, password: string): Promise<SupabaseClient> {
  const client = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false }
  });

  const { error } = await client.auth.signInWithPassword({ email, password });
  if (error) throw new Error(`Failed to sign in as ${email}: ${error.message}`);

  return client;
}

// ============================================================================
// Test Setup: Create test data
// ============================================================================

async function setupTestData(admin: SupabaseClient): Promise<{
  stations: { kpfk: string; kpfa: string };
  users: { [key: string]: TestUser };
  donors: { kpfkDonor: string; kpfaDonor: string };
  donations: { kpfkDonation: string; kpfaDonation: string };
}> {
  console.log('\n📦 Setting up test data...');

  // Clean up any existing test data
  await admin.from('audit_log').delete().like('table_name', 'test_%');
  await admin.from('donations').delete().like('source_detail', 'rls_test%');
  await admin.from('donors').delete().like('email', '%@rlstest.local');
  await admin.from('profiles').delete().like('email', '%@rlstest.local');
  await admin.auth.admin.listUsers().then(async ({ data }) => {
    for (const user of data?.users || []) {
      if (user.email?.includes('@rlstest.local')) {
        await admin.auth.admin.deleteUser(user.id);
      }
    }
  });

  // Get or create test stations
  const { data: stations } = await admin.from('stations').select('id, call_sign').in('call_sign', ['KPFK', 'KPFA']);

  let kpfkId: string, kpfaId: string;

  if (!stations || stations.length < 2) {
    // Create test stations if they don't exist
    const { data: newStations, error } = await admin.from('stations').insert([
      { call_sign: 'KPFK', name: 'KPFK 90.7 FM', city: 'Los Angeles', state: 'CA', timezone: 'America/Los_Angeles' },
      { call_sign: 'KPFA', name: 'KPFA 94.1 FM', city: 'Berkeley', state: 'CA', timezone: 'America/Los_Angeles' }
    ]).select();

    if (error) throw new Error(`Failed to create stations: ${error.message}`);
    kpfkId = newStations?.find(s => s.call_sign === 'KPFK')?.id;
    kpfaId = newStations?.find(s => s.call_sign === 'KPFA')?.id;
  } else {
    kpfkId = stations.find(s => s.call_sign === 'KPFK')?.id;
    kpfaId = stations.find(s => s.call_sign === 'KPFA')?.id;
  }

  if (!kpfkId || !kpfaId) throw new Error('Failed to get station IDs');

  log(`Stations: KPFK=${kpfkId.slice(0,8)}..., KPFA=${kpfaId.slice(0,8)}...`);

  // Create test donors (one per station)
  const { data: newDonors, error: donorError } = await admin.from('donors').insert([
    { station_id: kpfkId, email: 'kpfk.donor@rlstest.local', email_normalized: 'kpfk.donor@rlstest.local', first_name: 'KPFK', last_name: 'Donor' },
    { station_id: kpfaId, email: 'kpfa.donor@rlstest.local', email_normalized: 'kpfa.donor@rlstest.local', first_name: 'KPFA', last_name: 'Donor' }
  ]).select();

  if (donorError) throw new Error(`Failed to create donors: ${donorError.message}`);

  const kpfkDonorId = newDonors?.find(d => d.email.includes('kpfk'))?.id;
  const kpfaDonorId = newDonors?.find(d => d.email.includes('kpfa'))?.id;

  log(`Donors created: KPFK donor, KPFA donor`);

  // Create test donations
  const { data: newDonations, error: donationError } = await admin.from('donations').insert([
    { station_id: kpfkId, donor_id: kpfkDonorId, amount_cents: 5000, source_type: 'web', source_detail: 'rls_test_kpfk', status: 'succeeded' },
    { station_id: kpfaId, donor_id: kpfaDonorId, amount_cents: 7500, source_type: 'web', source_detail: 'rls_test_kpfa', status: 'succeeded' }
  ]).select();

  if (donationError) throw new Error(`Failed to create donations: ${donationError.message}`);

  log(`Donations created: $50 (KPFK), $75 (KPFA)`);

  // Create audit log entries for testing
  await admin.from('audit_log').insert([
    { table_name: 'test_donors', record_id: kpfkDonorId, action: 'INSERT', new_data: { test: true } },
    { table_name: 'test_donations', record_id: newDonations?.[0]?.id, action: 'INSERT', new_data: { test: true } }
  ]);

  log(`Audit log entries created`);

  // Create test users with different roles
  const testUsers: { [key: string]: TestUser } = {};
  const password = 'TestPassword123!';

  const userConfigs = [
    { key: 'superAdmin', email: 'super.admin@rlstest.local', role: 'super_admin', stationId: null },
    { key: 'kpfkAdmin', email: 'kpfk.admin@rlstest.local', role: 'admin', stationId: kpfkId },
    { key: 'kpfkOps', email: 'kpfk.ops@rlstest.local', role: 'ops', stationId: kpfkId },
    { key: 'kpfkVolunteer', email: 'kpfk.volunteer@rlstest.local', role: 'volunteer', stationId: kpfkId },
    { key: 'kpfaDonor', email: 'portal.donor@rlstest.local', role: 'donor', stationId: null, donorId: kpfaDonorId },
    { key: 'kpfaOps', email: 'kpfa.ops@rlstest.local', role: 'ops', stationId: kpfaId }
  ];

  for (const config of userConfigs) {
    // Create auth user
    const { data: authUser, error: authError } = await admin.auth.admin.createUser({
      email: config.email,
      password,
      email_confirm: true
    });

    if (authError) throw new Error(`Failed to create user ${config.email}: ${authError.message}`);

    // Update the auto-created profile with role and station
    const { error: profileError } = await admin.from('profiles')
      .update({
        role: config.role,
        station_id: config.stationId,
        donor_id: config.donorId || null,
        is_active: true
      })
      .eq('id', authUser.user.id);

    if (profileError) throw new Error(`Failed to update profile for ${config.email}: ${profileError.message}`);

    testUsers[config.key] = {
      id: authUser.user.id,
      email: config.email,
      role: config.role,
      stationId: config.stationId,
      donorId: config.donorId
    };

    log(`User created: ${config.role} (${config.email.split('@')[0]})`);
  }

  return {
    stations: { kpfk: kpfkId, kpfa: kpfaId },
    users: testUsers,
    donors: { kpfkDonor: kpfkDonorId!, kpfaDonor: kpfaDonorId! },
    donations: { kpfkDonation: newDonations![0].id, kpfaDonation: newDonations![1].id }
  };
}

// ============================================================================
// Test Cases
// ============================================================================

async function testAnonAccess() {
  console.log('\n🔒 Testing Anonymous Access (should be denied)...');

  const anon = getAnonClient();

  // Test PII tables - should all return 0 rows or error
  const piiTables = ['donors', 'donations', 'checkout_sessions', 'memberships', 'tax_documents', 'email_log', 'audit_log'];

  for (const table of piiTables) {
    const { data, error } = await anon.from(table).select('id').limit(1);

    if (error || !data || data.length === 0) {
      pass(`Anon cannot access ${table}`);
    } else {
      fail(`Anon CAN access ${table}`, `Got ${data.length} rows`);
    }
  }

  // Test public tables - should be accessible
  const publicTables = ['stations', 'campaigns', 'shows', 'gifts'];

  for (const table of publicTables) {
    const { error } = await anon.from(table).select('id').limit(1);

    if (!error) {
      pass(`Anon can read public table ${table}`);
    } else {
      fail(`Anon cannot read public table ${table}`, error.message);
    }
  }
}

async function testStationScoping(
  testData: Awaited<ReturnType<typeof setupTestData>>
) {
  console.log('\n🏢 Testing Station Scoping...');

  const password = 'TestPassword123!';

  // KPFK ops should only see KPFK data
  const kpfkOpsClient = await getAuthenticatedClient(testData.users.kpfkOps.email, password);

  // Test donors
  const { data: kpfkOpsDonors } = await kpfkOpsClient.from('donors').select('station_id');
  const allKpfkDonors = kpfkOpsDonors?.every(d => d.station_id === testData.stations.kpfk);

  if (allKpfkDonors && kpfkOpsDonors && kpfkOpsDonors.length > 0) {
    pass(`KPFK ops can only see KPFK donors (${kpfkOpsDonors.length} rows)`);
  } else if (!kpfkOpsDonors || kpfkOpsDonors.length === 0) {
    fail(`KPFK ops cannot see any donors`);
  } else {
    fail(`KPFK ops can see non-KPFK donors`);
  }

  // Test donations
  const { data: kpfkOpsDonations } = await kpfkOpsClient.from('donations').select('station_id');
  const allKpfkDonations = kpfkOpsDonations?.every(d => d.station_id === testData.stations.kpfk);

  if (allKpfkDonations && kpfkOpsDonations && kpfkOpsDonations.length > 0) {
    pass(`KPFK ops can only see KPFK donations (${kpfkOpsDonations.length} rows)`);
  } else if (!kpfkOpsDonations || kpfkOpsDonations.length === 0) {
    fail(`KPFK ops cannot see any donations`);
  } else {
    fail(`KPFK ops can see non-KPFK donations`);
  }

  // KPFA ops should only see KPFA data
  const kpfaOpsClient = await getAuthenticatedClient(testData.users.kpfaOps.email, password);

  const { data: kpfaOpsDonors } = await kpfaOpsClient.from('donors').select('station_id');
  const allKpfaDonors = kpfaOpsDonors?.every(d => d.station_id === testData.stations.kpfa);

  if (allKpfaDonors && kpfaOpsDonors && kpfaOpsDonors.length > 0) {
    pass(`KPFA ops can only see KPFA donors (${kpfaOpsDonors.length} rows)`);
  } else if (!kpfaOpsDonors || kpfaOpsDonors.length === 0) {
    fail(`KPFA ops cannot see any donors`);
  } else {
    fail(`KPFA ops can see non-KPFA donors`);
  }
}

async function testSuperAdminAccess(
  testData: Awaited<ReturnType<typeof setupTestData>>
) {
  console.log('\n👑 Testing super_admin Access...');

  const password = 'TestPassword123!';
  const superAdminClient = await getAuthenticatedClient(testData.users.superAdmin.email, password);

  // super_admin should see donors from both stations
  const { data: allDonors } = await superAdminClient.from('donors').select('station_id');
  const stationIds = new Set(allDonors?.map(d => d.station_id));

  if (stationIds.size >= 2) {
    pass(`super_admin can see donors from multiple stations (${stationIds.size} stations)`);
  } else {
    fail(`super_admin can only see donors from ${stationIds.size} station(s)`);
  }

  // super_admin should see donations from both stations
  const { data: allDonations } = await superAdminClient.from('donations').select('station_id');
  const donationStations = new Set(allDonations?.map(d => d.station_id));

  if (donationStations.size >= 2) {
    pass(`super_admin can see donations from multiple stations (${donationStations.size} stations)`);
  } else {
    fail(`super_admin can only see donations from ${donationStations.size} station(s)`);
  }

  // super_admin should see audit_log
  const { data: auditLogs, error: auditError } = await superAdminClient.from('audit_log').select('id').limit(5);

  if (!auditError && auditLogs && auditLogs.length > 0) {
    pass(`super_admin can access audit_log (${auditLogs.length} rows)`);
  } else {
    fail(`super_admin cannot access audit_log`, auditError?.message);
  }
}

async function testAuditLogRestriction(
  testData: Awaited<ReturnType<typeof setupTestData>>
) {
  console.log('\n📋 Testing audit_log Restriction (super_admin only)...');

  const password = 'TestPassword123!';

  // Test that non-super_admin users cannot see audit_log
  const nonSuperAdminUsers = [
    { key: 'kpfkAdmin', label: 'admin' },
    { key: 'kpfkOps', label: 'ops' },
    { key: 'kpfkVolunteer', label: 'volunteer' },
    { key: 'kpfaDonor', label: 'donor' }
  ];

  for (const { key, label } of nonSuperAdminUsers) {
    const client = await getAuthenticatedClient(testData.users[key].email, password);
    const { data, error } = await client.from('audit_log').select('id').limit(1);

    if (error || !data || data.length === 0) {
      pass(`${label} cannot access audit_log`);
    } else {
      fail(`${label} CAN access audit_log`, `Got ${data.length} rows`);
    }
  }
}

async function testDonorSelfAccess(
  testData: Awaited<ReturnType<typeof setupTestData>>
) {
  console.log('\n👤 Testing Donor Self-Access...');

  const password = 'TestPassword123!';
  const donorClient = await getAuthenticatedClient(testData.users.kpfaDonor.email, password);

  // Donor should see their own donor record
  const { data: ownDonor } = await donorClient.from('donors').select('id').eq('id', testData.donors.kpfaDonor);

  if (ownDonor && ownDonor.length === 1) {
    pass(`Donor can see their own donor record`);
  } else {
    fail(`Donor cannot see their own donor record`);
  }

  // Donor should NOT see other donors
  const { data: otherDonor } = await donorClient.from('donors').select('id').eq('id', testData.donors.kpfkDonor);

  if (!otherDonor || otherDonor.length === 0) {
    pass(`Donor cannot see other donors`);
  } else {
    fail(`Donor CAN see other donors`);
  }

  // Donor should see their own donations
  const { data: ownDonations } = await donorClient.from('donations').select('id, donor_id');
  const allOwn = ownDonations?.every(d => d.donor_id === testData.donors.kpfaDonor);

  if (allOwn && ownDonations && ownDonations.length > 0) {
    pass(`Donor can see their own donations (${ownDonations.length} rows)`);
  } else if (!ownDonations || ownDonations.length === 0) {
    // This might be expected if the donor profile isn't linked correctly
    fail(`Donor cannot see any donations (may need donor_id link in profile)`);
  } else {
    fail(`Donor can see other donors' donations`);
  }
}

async function testVolunteerRestrictions(
  testData: Awaited<ReturnType<typeof setupTestData>>
) {
  console.log('\n🙋 Testing Volunteer Restrictions...');

  const password = 'TestPassword123!';
  const volunteerClient = await getAuthenticatedClient(testData.users.kpfkVolunteer.email, password);

  // Volunteer should see donors in their station
  const { data: donors } = await volunteerClient.from('donors').select('station_id');

  if (donors && donors.length > 0) {
    pass(`Volunteer can see donors (${donors.length} rows)`);
  } else {
    fail(`Volunteer cannot see any donors`);
  }

  // Volunteer should see donations in their station
  const { data: donations } = await volunteerClient.from('donations').select('station_id');

  if (donations && donations.length > 0) {
    pass(`Volunteer can see donations (${donations.length} rows)`);
  } else {
    fail(`Volunteer cannot see any donations`);
  }

  // Volunteer should NOT see audit_log (tested above)
  // Volunteer should be station-scoped
  const allCorrectStation = donors?.every(d => d.station_id === testData.stations.kpfk);

  if (allCorrectStation) {
    pass(`Volunteer is correctly station-scoped`);
  } else {
    fail(`Volunteer can see donors from other stations`);
  }
}

async function testWriteRestrictions(
  testData: Awaited<ReturnType<typeof setupTestData>>
) {
  console.log('\n✏️ Testing Write Restrictions (mutations via service_role only)...');

  const password = 'TestPassword123!';
  const adminClient = await getAuthenticatedClient(testData.users.kpfkAdmin.email, password);

  // Admin should NOT be able to insert donors directly
  const { error: insertError } = await adminClient.from('donors').insert({
    station_id: testData.stations.kpfk,
    email: 'should.fail@rlstest.local',
    email_normalized: 'should.fail@rlstest.local',
    first_name: 'Should',
    last_name: 'Fail'
  });

  if (insertError) {
    pass(`Admin cannot insert donors directly (uses service_role)`);
  } else {
    fail(`Admin CAN insert donors directly - policy violation!`);
    // Clean up
    const admin = getAdminClient();
    await admin.from('donors').delete().eq('email', 'should.fail@rlstest.local');
  }

  // Admin should NOT be able to update donors directly
  const { error: updateError } = await adminClient.from('donors')
    .update({ first_name: 'Hacked' })
    .eq('id', testData.donors.kpfkDonor);

  if (updateError) {
    pass(`Admin cannot update donors directly (uses service_role)`);
  } else {
    fail(`Admin CAN update donors directly - policy violation!`);
  }

  // Admin should NOT be able to delete donors
  const { error: deleteError } = await adminClient.from('donors')
    .delete()
    .eq('id', testData.donors.kpfkDonor);

  if (deleteError) {
    pass(`Admin cannot delete donors directly (uses soft delete via service_role)`);
  } else {
    fail(`Admin CAN delete donors directly - policy violation!`);
  }
}

// ============================================================================
// Cleanup
// ============================================================================

async function cleanup(admin: SupabaseClient) {
  console.log('\n🧹 Cleaning up test data...');

  // Delete test users
  const { data: users } = await admin.auth.admin.listUsers();
  for (const user of users?.users || []) {
    if (user.email?.includes('@rlstest.local')) {
      await admin.auth.admin.deleteUser(user.id);
    }
  }

  // Delete test data (cascade should handle most)
  await admin.from('audit_log').delete().like('table_name', 'test_%');
  await admin.from('donations').delete().like('source_detail', 'rls_test%');
  await admin.from('donors').delete().like('email', '%@rlstest.local');

  log('Test data cleaned up');
}

// ============================================================================
// Main
// ============================================================================

async function main() {
  console.log('╔════════════════════════════════════════════════════════════════╗');
  console.log('║              RLS Policy Verification Tests                     ║');
  console.log('╚════════════════════════════════════════════════════════════════╝');

  // Validate environment
  if (!SUPABASE_SERVICE_ROLE_KEY) {
    console.error('\n❌ Missing SUPABASE_SERVICE_ROLE_KEY environment variable');
    console.error('   Make sure .env.local is configured or run with environment vars set');
    process.exit(1);
  }

  if (!SUPABASE_PUBLISHABLE_KEY) {
    console.error('\n❌ Missing NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY environment variable');
    process.exit(1);
  }

  const admin = getAdminClient();

  try {
    // Setup
    const testData = await setupTestData(admin);

    // Run tests
    await testAnonAccess();
    await testStationScoping(testData);
    await testSuperAdminAccess(testData);
    await testAuditLogRestriction(testData);
    await testDonorSelfAccess(testData);
    await testVolunteerRestrictions(testData);
    await testWriteRestrictions(testData);

    // Cleanup
    await cleanup(admin);

  } catch (error) {
    console.error('\n❌ Test setup failed:', error);

    // Try to cleanup anyway
    try {
      await cleanup(admin);
    } catch {
      // Ignore cleanup errors
    }

    process.exit(1);
  }

  // Summary
  console.log('\n════════════════════════════════════════════════════════════════');
  console.log('                         SUMMARY');
  console.log('════════════════════════════════════════════════════════════════');

  const passed = results.filter(r => r.passed).length;
  const failed = results.filter(r => !r.passed).length;

  console.log(`  Total:  ${results.length}`);
  console.log(`  Passed: ${passed} ✓`);
  console.log(`  Failed: ${failed} ✗`);

  if (failed > 0) {
    console.log('\n  Failed tests:');
    results.filter(r => !r.passed).forEach(r => {
      console.log(`    - ${r.name}${r.details ? `: ${r.details}` : ''}`);
    });
    console.log('\n❌ RLS verification FAILED');
    process.exit(1);
  } else {
    console.log('\n✅ All RLS policies verified successfully!');
    process.exit(0);
  }
}

main();
