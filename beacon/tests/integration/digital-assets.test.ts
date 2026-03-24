// Tests for the digital asset library feature:
// - Library list endpoint never exposes raw content URLs
// - Access endpoint requires entitlement
// - Access endpoint returns URL when entitled
// - Access log is written on successful access
//
// These tests mock the Supabase client at the module level and test
// the API route handlers directly. Each test resets the mock state.

import { describe, it, expect, vi, beforeEach } from 'vitest';

// =============================================================================
// Test data
// =============================================================================

const DONOR_ID = 'aaaaaaaa-1111-1111-1111-111111111111';
const ASSET_ID = 'bbbbbbbb-2222-2222-2222-222222222222';
const DONATION_ID = 'cccccccc-3333-3333-3333-333333333333';
const GIFT_ID = 'dddddddd-4444-4444-4444-444444444444';
const ENTITLEMENT_ID = 'eeeeeeee-5555-5555-5555-555555555555';
const STATION_ID = 'ffffffff-6666-6666-6666-666666666666';

// =============================================================================
// Track what the access log receives
// =============================================================================

let accessLogInserts: Record<string, unknown>[] = [];

// =============================================================================
// Mock Supabase — table-aware chainable builder
//
// Each table has its own result set. The mock tracks which table was
// queried via .from() and returns the corresponding result.
// =============================================================================

const tableData = new Map<string, { data: unknown; error: unknown }>();

function setTable(name: string, data: unknown, error: unknown = null) {
  tableData.set(name, { data, error });
}

function makeChain(table: string) {
  const result = () => tableData.get(table) || { data: null, error: null };

  // Recursive proxy — every method call returns the same proxy,
  // except 'single' which resolves, and 'then' which resolves the array result
  const handler: ProxyHandler<object> = {
    get(_target, prop) {
      if (prop === 'single') {
        return () => {
          const r = result();
          const d = Array.isArray(r.data) ? r.data[0] ?? null : r.data;
          return Promise.resolve({ data: d, error: r.error });
        };
      }
      if (prop === 'then') {
        // Makes the chain awaitable — returns the full array result
        return (resolve: (v: unknown) => void) => {
          resolve(result());
        };
      }
      if (prop === 'insert') {
        return (data: unknown) => {
          if (table === 'digital_asset_access_log') {
            accessLogInserts.push(data as Record<string, unknown>);
          }
          return Promise.resolve({ error: null });
        };
      }
      // All other methods (select, eq, in, is, order, limit) return the proxy
      return () => new Proxy({}, handler);
    },
  };

  return new Proxy({}, handler);
}

vi.mock('@/lib/supabase-admin', () => ({
  getSupabaseAdmin: () => ({
    from: (table: string) => makeChain(table),
  }),
}));

// =============================================================================
// Mock portal auth
// =============================================================================

let portalAuthResponse: unknown = {
  success: true,
  donorId: DONOR_ID,
  profileId: 'profile-1',
  email: 'donor@test.com',
  stationId: STATION_ID,
  isImpersonating: false,
};

vi.mock('@/lib/portal-auth', () => ({
  authenticatePortalRequest: () => Promise.resolve(portalAuthResponse),
}));

// =============================================================================
// Helpers
// =============================================================================

function makeRequest(method = 'GET', path = '/api/portal/library'): Request {
  return new Request(`http://localhost:3000${path}`, { method });
}

// =============================================================================
// GET /api/portal/library — library list
// =============================================================================

describe('GET /api/portal/library', () => {
  beforeEach(() => {
    tableData.clear();
    accessLogInserts = [];
    portalAuthResponse = {
      success: true,
      donorId: DONOR_ID,
      profileId: 'profile-1',
      email: 'donor@test.com',
      stationId: STATION_ID,
      isImpersonating: false,
    };
  });

  it('returns 401 when not authenticated', async () => {
    portalAuthResponse = { success: false, error: 'Authentication required', status: 401 };

    const { GET } = await import('@/app/api/portal/library/route');
    const res = await GET(makeRequest() as never);

    expect(res.status).toBe(401);
  });

  it('returns empty assets when donor has no donations', async () => {
    setTable('donations', []);

    const { GET } = await import('@/app/api/portal/library/route');
    const res = await GET(makeRequest() as never);
    const body = await res.json();

    expect(res.status).toBe(200);
    expect(body.assets).toEqual([]);
  });

  it('returns empty assets when no entitlements match', async () => {
    setTable('donations', [{ id: DONATION_ID, received_at: '2025-11-20T00:00:00Z' }]);
    setTable('fulfillment_items', [{
      donation_id: DONATION_ID,
      gift_variant_id: 'v1',
      gift_variants: { gift_id: GIFT_ID, gifts: { id: GIFT_ID, name: 'Test Gift' } },
    }]);
    setTable('digital_asset_entitlements', []);

    const { GET } = await import('@/app/api/portal/library/route');
    const res = await GET(makeRequest() as never);
    const body = await res.json();

    expect(res.status).toBe(200);
    expect(body.assets).toEqual([]);
  });

  it('returns asset metadata without the raw URL', async () => {
    setTable('donations', [{ id: DONATION_ID, received_at: '2025-11-20T00:00:00Z' }]);
    setTable('fulfillment_items', [{
      donation_id: DONATION_ID,
      gift_variant_id: 'v1',
      gift_variants: { gift_id: GIFT_ID, gifts: { id: GIFT_ID, name: 'Town Hall Recording' } },
    }]);
    setTable('digital_asset_entitlements', [{
      id: ENTITLEMENT_ID,
      digital_asset_id: ASSET_ID,
      gift_id: GIFT_ID,
    }]);
    setTable('digital_assets', [{
      id: ASSET_ID,
      title: 'Dr. Cornel West — KPFK Town Hall',
      asset_type: 'video',
      thumbnail_url: 'https://img.youtube.com/thumb.jpg',
      metadata: { speakers: ['Dr. Cornel West'], duration_minutes: 90 },
      created_at: '2025-11-01T00:00:00Z',
      // This is in the DB but must NOT appear in response
      url: 'https://youtube.com/watch?v=SECRET',
    }]);

    const { GET } = await import('@/app/api/portal/library/route');
    const res = await GET(makeRequest() as never);
    const body = await res.json();

    expect(res.status).toBe(200);
    expect(body.assets).toHaveLength(1);

    const asset = body.assets[0];
    expect(asset.title).toBe('Dr. Cornel West — KPFK Town Hall');
    expect(asset.asset_type).toBe('video');
    expect(asset.thumbnail_url).toBe('https://img.youtube.com/thumb.jpg');
    expect(asset.donation_id).toBe(DONATION_ID);
    expect(asset.entitlement_id).toBe(ENTITLEMENT_ID);
    expect(asset.gift_name).toBe('Town Hall Recording');
    // Critical: URL must never be in the library list response
    expect(asset).not.toHaveProperty('url');
  });
});

// =============================================================================
// POST /api/portal/library/:assetId/access — gated content access
// =============================================================================

describe('POST /api/portal/library/:assetId/access', () => {
  beforeEach(() => {
    tableData.clear();
    accessLogInserts = [];
    portalAuthResponse = {
      success: true,
      donorId: DONOR_ID,
      profileId: 'profile-1',
      email: 'donor@test.com',
      stationId: STATION_ID,
      isImpersonating: false,
    };
  });

  it('returns 401 when not authenticated', async () => {
    portalAuthResponse = { success: false, error: 'Authentication required', status: 401 };

    const { POST } = await import('@/app/api/portal/library/[assetId]/access/route');
    const req = makeRequest('POST', `/api/portal/library/${ASSET_ID}/access`);
    const res = await POST(req as never, { params: Promise.resolve({ assetId: ASSET_ID }) });

    expect(res.status).toBe(401);
  });

  it('returns 400 for invalid UUID format', async () => {
    const { POST } = await import('@/app/api/portal/library/[assetId]/access/route');
    const req = makeRequest('POST', '/api/portal/library/bad-id/access');
    const res = await POST(req as never, { params: Promise.resolve({ assetId: 'bad-id' }) });

    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toBe('Invalid asset ID');
  });

  it('returns 404 when asset does not exist', async () => {
    // .single() on digital_assets returns null + error
    setTable('digital_assets', null, { code: 'PGRST116', message: 'not found' });

    const { POST } = await import('@/app/api/portal/library/[assetId]/access/route');
    const req = makeRequest('POST', `/api/portal/library/${ASSET_ID}/access`);
    const res = await POST(req as never, { params: Promise.resolve({ assetId: ASSET_ID }) });

    expect(res.status).toBe(404);
  });

  it('returns 403 when donor has no succeeded donations', async () => {
    setTable('digital_assets', [{ id: ASSET_ID, url: 'https://youtube.com/test', station_id: STATION_ID }]);
    setTable('donations', []);

    const { POST } = await import('@/app/api/portal/library/[assetId]/access/route');
    const req = makeRequest('POST', `/api/portal/library/${ASSET_ID}/access`);
    const res = await POST(req as never, { params: Promise.resolve({ assetId: ASSET_ID }) });

    expect(res.status).toBe(403);
    const body = await res.json();
    expect(body.error).toBe('Not entitled to this asset');
  });

  it('returns URL and logs access when entitled', async () => {
    const secretUrl = 'https://www.youtube.com/watch?v=SECRET123';
    setTable('digital_assets', [{ id: ASSET_ID, url: secretUrl, station_id: STATION_ID }]);
    setTable('donations', [{ id: DONATION_ID }]);
    setTable('fulfillment_items', [{
      donation_id: DONATION_ID,
      gift_variants: { gift_id: GIFT_ID },
    }]);
    setTable('digital_asset_entitlements', [{
      id: ENTITLEMENT_ID,
      gift_id: GIFT_ID,
    }]);

    const { POST } = await import('@/app/api/portal/library/[assetId]/access/route');
    const req = makeRequest('POST', `/api/portal/library/${ASSET_ID}/access`);
    const res = await POST(req as never, { params: Promise.resolve({ assetId: ASSET_ID }) });
    const body = await res.json();

    expect(res.status).toBe(200);
    expect(body.url).toBe(secretUrl);

    // Wait for the non-blocking access log insert
    await new Promise(r => setTimeout(r, 50));

    // Verify access was logged with full traceability
    expect(accessLogInserts).toHaveLength(1);
    const log = accessLogInserts[0];
    expect(log.digital_asset_id).toBe(ASSET_ID);
    expect(log.donor_id).toBe(DONOR_ID);
    expect(log.station_id).toBe(STATION_ID);
    expect(log.donation_id).toBe(DONATION_ID);
    expect(log.entitlement_id).toBe(ENTITLEMENT_ID);
  });
});
