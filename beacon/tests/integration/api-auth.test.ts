import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  authenticateAdminRequest,
  canAccessStation,
  getQueryStationId,
} from '@/lib/api-auth';
import type { AuthenticatedUser } from '@/lib/api-auth';

// =============================================================================
// Mock Supabase — we only need it for the slow path (profile lookup)
// =============================================================================

const mockSingle = vi.fn();
const mockSupabaseAdmin = {
  from: () => ({
    select: () => ({
      eq: () => ({
        is: () => ({
          single: mockSingle,
        }),
      }),
    }),
  }),
};

vi.mock('@/lib/supabase-admin', () => ({
  getSupabaseAdmin: () => mockSupabaseAdmin,
}));

// Mock the slow-path session client (dynamic import of supabase-server)
const mockGetUser = vi.fn();
vi.mock('@/lib/supabase-server', () => ({
  createServerSupabaseClient: () =>
    Promise.resolve({
      auth: { getUser: mockGetUser },
    }),
}));

// =============================================================================
// Helper: build a fake NextRequest with auth headers
// =============================================================================

function fakeRequest(headers: Record<string, string> = {}): Request {
  const h = new Headers(headers);
  const url = 'http://localhost:3000/api/test';
  // NextRequest constructor accepts a standard Request
  return new Request(url, { headers: h });
}

function withAuthHeaders(
  role: string,
  opts: { userId?: string; email?: string; stationId?: string; active?: string } = {}
) {
  return fakeRequest({
    'x-auth-user-id': opts.userId || 'user-uuid-123',
    'x-auth-role': role,
    'x-auth-active': opts.active ?? 'true',
    'x-auth-email': opts.email || 'staff@kpfk.org',
    'x-auth-station-id': opts.stationId || 'station-uuid-kpfk',
  });
}

// =============================================================================
// authenticateAdminRequest — FAST PATH (middleware headers present)
// =============================================================================

describe('authenticateAdminRequest — fast path', () => {
  it('authenticates admin with valid headers', async () => {
    const req = withAuthHeaders('admin');
    const result = await authenticateAdminRequest(req as never);
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.user.role).toBe('admin');
      expect(result.user.id).toBe('user-uuid-123');
      expect(result.user.stationId).toBe('station-uuid-kpfk');
    }
  });

  it('authenticates ops role', async () => {
    const req = withAuthHeaders('ops');
    const result = await authenticateAdminRequest(req as never);
    expect(result.success).toBe(true);
  });

  it('authenticates volunteer role', async () => {
    const req = withAuthHeaders('volunteer');
    const result = await authenticateAdminRequest(req as never);
    expect(result.success).toBe(true);
  });

  it('authenticates super_admin role', async () => {
    const req = withAuthHeaders('super_admin');
    const result = await authenticateAdminRequest(req as never);
    expect(result.success).toBe(true);
  });

  it('rejects donor role (not staff)', async () => {
    const req = withAuthHeaders('donor');
    const result = await authenticateAdminRequest(req as never);
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.status).toBe(403);
      expect(result.error).toContain('Staff');
    }
  });

  it('rejects unknown role', async () => {
    const req = withAuthHeaders('hacker');
    const result = await authenticateAdminRequest(req as never);
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.status).toBe(403);
    }
  });

  it('rejects inactive user (x-auth-active = false)', async () => {
    // When active is not 'true', fast path doesn't match — falls to slow path.
    // Slow path will also reject because mockGetUser returns no user by default.
    const req = withAuthHeaders('admin', { active: 'false' });
    mockGetUser.mockResolvedValueOnce({ data: { user: null }, error: { message: 'No session' } });
    const result = await authenticateAdminRequest(req as never);
    expect(result.success).toBe(false);
  });
});

// =============================================================================
// authenticateAdminRequest — requiredRoles option
// =============================================================================

describe('authenticateAdminRequest — requiredRoles', () => {
  it('allows role in required list', async () => {
    const req = withAuthHeaders('admin');
    const result = await authenticateAdminRequest(req as never, {
      requiredRoles: ['super_admin', 'admin'],
    });
    expect(result.success).toBe(true);
  });

  it('rejects role NOT in required list', async () => {
    const req = withAuthHeaders('volunteer');
    const result = await authenticateAdminRequest(req as never, {
      requiredRoles: ['super_admin', 'admin'],
    });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.status).toBe(403);
      expect(result.error).toContain('super_admin');
      expect(result.error).toContain('admin');
    }
  });
});

// =============================================================================
// authenticateAdminRequest — minRole option (role hierarchy)
// =============================================================================

describe('authenticateAdminRequest — minRole hierarchy', () => {
  it('admin meets minRole=ops (admin > ops)', async () => {
    const req = withAuthHeaders('admin');
    const result = await authenticateAdminRequest(req as never, { minRole: 'ops' });
    expect(result.success).toBe(true);
  });

  it('volunteer fails minRole=ops (volunteer < ops)', async () => {
    const req = withAuthHeaders('volunteer');
    const result = await authenticateAdminRequest(req as never, { minRole: 'ops' });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.status).toBe(403);
      expect(result.error).toContain('ops or higher');
    }
  });

  it('super_admin meets any minRole', async () => {
    const req = withAuthHeaders('super_admin');
    const result = await authenticateAdminRequest(req as never, { minRole: 'admin' });
    expect(result.success).toBe(true);
  });
});

// =============================================================================
// authenticateAdminRequest — SLOW PATH (no middleware headers)
// =============================================================================

describe('authenticateAdminRequest — slow path', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('returns 401 when no session exists', async () => {
    const req = fakeRequest(); // No auth headers → slow path
    mockGetUser.mockResolvedValueOnce({ data: { user: null }, error: { message: 'No session' } });

    const result = await authenticateAdminRequest(req as never);
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.status).toBe(401);
      expect(result.error).toContain('Authentication required');
    }
  });

  it('returns 403 when profile not found', async () => {
    const req = fakeRequest();
    mockGetUser.mockResolvedValueOnce({ data: { user: { id: 'user-1', email: 'x@kpfk.org' } }, error: null });
    mockSingle.mockResolvedValueOnce({ data: null, error: { message: 'not found' } });

    const result = await authenticateAdminRequest(req as never);
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.status).toBe(403);
      expect(result.error).toContain('profile not found');
    }
  });

  it('returns 403 when user is inactive', async () => {
    const req = fakeRequest();
    mockGetUser.mockResolvedValueOnce({ data: { user: { id: 'user-1', email: 'x@kpfk.org' } }, error: null });
    mockSingle.mockResolvedValueOnce({ data: { role: 'admin', station_id: 'st-1', is_active: false }, error: null });

    const result = await authenticateAdminRequest(req as never);
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.status).toBe(403);
      expect(result.error).toContain('inactive');
    }
  });

  it('returns 403 for donor role on slow path', async () => {
    const req = fakeRequest();
    mockGetUser.mockResolvedValueOnce({ data: { user: { id: 'user-1', email: 'donor@gmail.com' } }, error: null });
    mockSingle.mockResolvedValueOnce({ data: { role: 'donor', station_id: null, is_active: true }, error: null });

    const result = await authenticateAdminRequest(req as never);
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.status).toBe(403);
      expect(result.error).toContain('Staff');
    }
  });

  it('succeeds for valid staff user on slow path', async () => {
    const req = fakeRequest();
    mockGetUser.mockResolvedValueOnce({ data: { user: { id: 'user-1', email: 'ops@kpfk.org' } }, error: null });
    mockSingle.mockResolvedValueOnce({ data: { role: 'ops', station_id: 'st-kpfk', is_active: true }, error: null });

    const result = await authenticateAdminRequest(req as never);
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.user.role).toBe('ops');
      expect(result.user.stationId).toBe('st-kpfk');
      expect(result.user.email).toBe('ops@kpfk.org');
    }
  });
});

// =============================================================================
// canAccessStation
// =============================================================================

describe('canAccessStation', () => {
  const adminUser: AuthenticatedUser = {
    id: 'u1', email: 'admin@kpfk.org', role: 'admin',
    stationId: 'station-kpfk', isActive: true,
  };
  const superAdmin: AuthenticatedUser = {
    id: 'u2', email: 'super@kpfk.org', role: 'super_admin',
    stationId: 'station-kpfk', isActive: true,
  };

  it('admin can access own station', () => {
    expect(canAccessStation(adminUser, 'station-kpfk')).toBe(true);
  });

  it('admin cannot access different station', () => {
    expect(canAccessStation(adminUser, 'station-kpfa')).toBe(false);
  });

  it('super_admin can access any station', () => {
    expect(canAccessStation(superAdmin, 'station-kpfa')).toBe(true);
    expect(canAccessStation(superAdmin, 'station-wbai')).toBe(true);
  });
});

// =============================================================================
// getQueryStationId
// =============================================================================

describe('getQueryStationId', () => {
  const opsUser: AuthenticatedUser = {
    id: 'u1', email: 'ops@kpfk.org', role: 'ops',
    stationId: 'station-kpfk', isActive: true,
  };
  const superAdmin: AuthenticatedUser = {
    id: 'u2', email: 'super@kpfk.org', role: 'super_admin',
    stationId: 'station-kpfk', isActive: true,
  };

  it('returns own station for non-super_admin', () => {
    expect(getQueryStationId(opsUser)).toBe('station-kpfk');
  });

  it('ignores requested station for non-super_admin', () => {
    expect(getQueryStationId(opsUser, 'station-kpfa')).toBe('station-kpfk');
  });

  it('super_admin can target a specific station', () => {
    expect(getQueryStationId(superAdmin, 'station-kpfa')).toBe('station-kpfa');
  });

  it('super_admin with no target returns own station', () => {
    expect(getQueryStationId(superAdmin)).toBe('station-kpfk');
  });

  it('super_admin with null target returns own station', () => {
    expect(getQueryStationId(superAdmin, null)).toBe('station-kpfk');
  });
});
