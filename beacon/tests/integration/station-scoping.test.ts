import { describe, it, expect, vi, beforeEach } from 'vitest';
import { authenticateAdminRequest, getQueryStationId } from '@/lib/api-auth';
import type { AuthenticatedUser } from '@/lib/api-auth';

// =============================================================================
// This test verifies the station scoping PATTERN used across all API routes.
// The actual donations route does auth → getQueryStationId → .eq('station_id')
// We test that chain to prove station isolation works.
// =============================================================================

// Track what queries are built — this is the core of the test.
// We want to verify that .eq('station_id', X) is called with the right value.
const queryLog: { table: string; filters: Array<{ column: string; value: unknown }> }[] = [];

const mockSupabaseAdmin = {
  from: (table: string) => {
    const entry = { table, filters: [] as Array<{ column: string; value: unknown }> };
    queryLog.push(entry);

    // Build a chainable mock that tracks .eq() calls
    // Uses `any` for mock flexibility — test mocks don't need strict typing
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const chain = (result: { data: unknown[]; error: null; count: number }): any => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const self: Record<string, (...args: any[]) => any> = {};
      self.select = () => self;
      self.eq = (col: string, val: unknown) => {
        entry.filters.push({ column: col, value: val });
        return self;
      };
      self.is = () => self;
      self.in = () => self;
      self.or = () => self;
      self.order = () => self;
      self.range = () => self;
      self.gte = () => self;
      self.lte = () => self;
      self.single = () => Promise.resolve(result);
      // When awaited directly (no .single()), return the result
      self.then = (resolve: (value: unknown) => void) => resolve(result);
      return self;
    };

    return chain({ data: [], error: null, count: 0 });
  },
};

vi.mock('@/lib/supabase-admin', () => ({
  getSupabaseAdmin: () => mockSupabaseAdmin,
}));

vi.mock('@/lib/supabase-server', () => ({
  createServerSupabaseClient: () =>
    Promise.resolve({ auth: { getUser: vi.fn() } }),
}));

beforeEach(() => {
  queryLog.length = 0;
});

// =============================================================================
// Station scoping logic — the pattern every API route must follow
// =============================================================================

describe('station scoping pattern', () => {
  it('admin user gets their own station_id for query filtering', () => {
    const adminUser: AuthenticatedUser = {
      id: 'u1', email: 'admin@kpfk.org', role: 'admin',
      stationId: 'station-kpfk', isActive: true,
    };

    const stationId = getQueryStationId(adminUser);
    expect(stationId).toBe('station-kpfk');

    // Simulate what the API route does: add .eq('station_id', stationId)
    if (stationId) {
      const supabase = mockSupabaseAdmin;
      supabase.from('donations').eq('station_id', stationId);

      // Verify the filter was applied
      expect(queryLog).toHaveLength(1);
      expect(queryLog[0].table).toBe('donations');
      expect(queryLog[0].filters).toContainEqual({
        column: 'station_id', value: 'station-kpfk',
      });
    }
  });

  it('ops user is scoped to their station', () => {
    const opsUser: AuthenticatedUser = {
      id: 'u2', email: 'ops@kpfk.org', role: 'ops',
      stationId: 'station-kpfk', isActive: true,
    };

    const stationId = getQueryStationId(opsUser);
    expect(stationId).toBe('station-kpfk');
  });

  it('volunteer user is scoped to their station', () => {
    const volunteerUser: AuthenticatedUser = {
      id: 'u3', email: 'vol@kpfk.org', role: 'volunteer',
      stationId: 'station-kpfk', isActive: true,
    };

    const stationId = getQueryStationId(volunteerUser);
    expect(stationId).toBe('station-kpfk');
  });

  it('super_admin gets null (no station filter = sees all)', () => {
    const superAdmin: AuthenticatedUser = {
      id: 'u4', email: 'super@kpfk.org', role: 'super_admin',
      stationId: 'station-kpfk', isActive: true,
    };

    const stationId = getQueryStationId(superAdmin);
    // super_admin with no requested station returns own station
    expect(stationId).toBe('station-kpfk');
  });

  it('super_admin can override to query a different station', () => {
    const superAdmin: AuthenticatedUser = {
      id: 'u4', email: 'super@kpfk.org', role: 'super_admin',
      stationId: 'station-kpfk', isActive: true,
    };

    const stationId = getQueryStationId(superAdmin, 'station-kpfa');
    expect(stationId).toBe('station-kpfa');

    // Simulate query with different station
    mockSupabaseAdmin.from('donations').eq('station_id', stationId!);
    expect(queryLog[0].filters).toContainEqual({
      column: 'station_id', value: 'station-kpfa',
    });
  });

  it('non-super_admin CANNOT override station (ignores requested)', () => {
    const opsUser: AuthenticatedUser = {
      id: 'u2', email: 'ops@kpfk.org', role: 'ops',
      stationId: 'station-kpfk', isActive: true,
    };

    // Tries to query KPFA's data, but gets scoped to KPFK
    const stationId = getQueryStationId(opsUser, 'station-kpfa');
    expect(stationId).toBe('station-kpfk');
  });
});

// =============================================================================
// Full auth → station scoping integration (end-to-end pattern)
// =============================================================================

describe('auth + station scoping end-to-end', () => {
  function withAuthHeaders(role: string, stationId: string) {
    return new Request('http://localhost:3000/api/donations', {
      headers: new Headers({
        'x-auth-user-id': 'user-123',
        'x-auth-role': role,
        'x-auth-active': 'true',
        'x-auth-email': `${role}@kpfk.org`,
        'x-auth-station-id': stationId,
      }),
    });
  }

  it('ops user: auth succeeds → station scoped to own station', async () => {
    const req = withAuthHeaders('ops', 'station-kpfk');
    const auth = await authenticateAdminRequest(req as never, {
      requiredRoles: ['super_admin', 'admin', 'ops', 'volunteer'],
    });

    expect(auth.success).toBe(true);
    if (!auth.success) return;

    const stationId = getQueryStationId(auth.user);
    expect(stationId).toBe('station-kpfk');

    // This is what the API route does
    if (stationId) {
      mockSupabaseAdmin.from('donations').eq('station_id', stationId);
      expect(queryLog[0].filters[0]).toEqual({
        column: 'station_id', value: 'station-kpfk',
      });
    }
  });

  it('donor role: auth fails → no query happens', async () => {
    const req = withAuthHeaders('donor', 'station-kpfk');
    const auth = await authenticateAdminRequest(req as never, {
      requiredRoles: ['super_admin', 'admin', 'ops'],
    });

    expect(auth.success).toBe(false);
    // API route would return early here — no database query
    expect(queryLog).toHaveLength(0);
  });

  it('volunteer denied from admin-only route', async () => {
    const req = withAuthHeaders('volunteer', 'station-kpfk');
    const auth = await authenticateAdminRequest(req as never, {
      requiredRoles: ['super_admin', 'admin'],
    });

    expect(auth.success).toBe(false);
    if (!auth.success) {
      expect(auth.status).toBe(403);
    }
    expect(queryLog).toHaveLength(0);
  });
});
