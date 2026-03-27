/**
 * Beacon public API client.
 * Read-only — fetches events (and future: campaigns, programs) from Beacon.
 * Responses are cached in-memory with a configurable TTL.
 */

const BEACON_API_URL =
  process.env.BEACON_API_BASE_URL || "https://events.kpfk.org/api";

// ---------------------------------------------------------------------------
// In-memory cache
// ---------------------------------------------------------------------------

interface CacheEntry<T> {
  data: T;
  expiresAt: number;
}

const cache = new Map<string, CacheEntry<unknown>>();

function getCached<T>(key: string): T | null {
  const entry = cache.get(key) as CacheEntry<T> | undefined;
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    cache.delete(key);
    return null;
  }
  return entry.data;
}

function setCache<T>(key: string, data: T, ttlMs: number) {
  cache.set(key, { data, expiresAt: Date.now() + ttlMs });
}

// ---------------------------------------------------------------------------
// Beacon event shape (from /api/public/events/upcoming)
// ---------------------------------------------------------------------------

export interface BeaconEvent {
  id: string;
  title: string;
  slug: string;
  starts_at: string;
  ends_at?: string | null;
  venue?: string | null;
  image_url?: string | null;
  ticket_url?: string | null;
  description?: string | null;
}

// ---------------------------------------------------------------------------
// Fetch upcoming events — 15-minute cache
// ---------------------------------------------------------------------------

const EVENTS_CACHE_KEY = "beacon:events:upcoming";
const EVENTS_TTL_MS = 15 * 60 * 1000; // 15 minutes

export async function getBeaconEvents(): Promise<BeaconEvent[]> {
  const cached = getCached<BeaconEvent[]>(EVENTS_CACHE_KEY);
  if (cached) return cached;

  try {
    const res = await fetch(`${BEACON_API_URL}/public/events/upcoming`, {
      next: { revalidate: 900 }, // 15 min ISR cache
    });

    if (!res.ok) return [];

    const data: BeaconEvent[] = await res.json();
    setCache(EVENTS_CACHE_KEY, data, EVENTS_TTL_MS);
    return data;
  } catch {
    // Graceful degradation — Beacon down shouldn't break the CMS
    return [];
  }
}
