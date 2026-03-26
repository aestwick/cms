/**
 * Confessor (broadcast schedule) API client.
 * Read-only — fetches show schedule data from the legacy PHP system.
 * Always uses &json=1 for JSON responses.
 *
 * Confessor API docs: beacon/OTIS/legacy.md
 */

const CONFESSOR_API_URL =
  process.env.CONFESSOR_API_URL ||
  (process.env.CONFESSOR_API_BASE_URL
    ? `${process.env.CONFESSOR_API_BASE_URL}/_nu_do_api.php`
    : "https://confessor.kpfk.org/_nu_do_api.php");

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface ConfessorShow {
  sh_id: number;
  sh_altid: string; // slug — maps to cms_shows.program_slug
  sh_name: string;
  sh_djname: string;
  sh_stime: string; // "HH:MM:SS"
  sh_ends: string; // "HH:MM:SS"
  sh_ampm: string;
  sh_ampm_ends: string;
  sh_shour: number; // seconds since midnight
  sh_len: number; // duration in seconds
  sh_days: string; // "Mon Tue Wed ..."
  sh_info: number; // bitmask
  sh_desc: string;
  sh_email: string;
  sh_url: string;
  sh_photo: string;
  ca_name: string;
  ca_color: string;
  ca_bgcolor: string;
}

// Bit flags from sh_info that we care about
export const SH_INVISIBLE = 0x08;
export const SH_GONE = 0x8000;

// ---------------------------------------------------------------------------
// Cache
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
// Fetch helpers
// ---------------------------------------------------------------------------

async function confessorFetch<T>(params: string): Promise<T | null> {
  try {
    const url = `${CONFESSOR_API_URL}?${params}&json=1`;
    const res = await fetch(url, { next: { revalidate: 3600 } });
    if (!res.ok) {
      console.error(`[Confessor] HTTP ${res.status} from ${url}`);
      return null;
    }
    return (await res.json()) as T;
  } catch (err) {
    console.error(`[Confessor] Fetch failed for ${CONFESSOR_API_URL}?${params}:`, err);
    return null;
  }
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

const SCHEDULE_CACHE_KEY = "confessor:schedule:weekly";
const SCHEDULE_TTL_MS = 60 * 60 * 1000; // 1 hour

/**
 * Get the full weekly schedule from Confessor.
 * Returns an object keyed by day number (0-6), each containing an array of shows.
 */
export async function getWeeklySchedule(): Promise<Record<
  string,
  ConfessorShow[]
> | null> {
  const cached = getCached<Record<string, ConfessorShow[]>>(SCHEDULE_CACHE_KEY);
  if (cached) return cached;

  const data = await confessorFetch<Record<string, ConfessorShow[]>>(
    "req=getshows&before=1&after=1"
  );
  if (!data) return null;

  setCache(SCHEDULE_CACHE_KEY, data, SCHEDULE_TTL_MS);
  return data;
}

/**
 * Get all shows for a specific day (0=Sunday .. 6=Saturday).
 */
export async function getDaySchedule(
  day: number
): Promise<ConfessorShow[] | null> {
  return confessorFetch<ConfessorShow[]>(`req=getday&day=${day}`);
}

/**
 * Filter out invisible and discontinued shows.
 */
export function isVisibleShow(show: ConfessorShow): boolean {
  return (
    (show.sh_info & SH_GONE) === 0 && (show.sh_info & SH_INVISIBLE) === 0
  );
}

/**
 * Convert Confessor time "HH:MM:SS" to schedule slot "HH:MM" format.
 */
export function confessorTimeToSlotTime(time: string): string {
  return time.substring(0, 5);
}

/**
 * Parse Confessor day string ("Mon Tue Wed") into day-of-week numbers (0-6).
 */
export function parseDayString(dayStr: string): number[] {
  const map: Record<string, number> = {
    Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6,
  };
  return dayStr
    .split(/\s+/)
    .map((d) => map[d])
    .filter((n) => n !== undefined);
}
