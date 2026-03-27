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
// HTML entity decoding — Confessor returns HTML-encoded strings
// ---------------------------------------------------------------------------

const HTML_ENTITIES: Record<string, string> = {
  "&amp;": "&",
  "&lt;": "<",
  "&gt;": ">",
  "&quot;": '"',
  "&#039;": "'",
  "&apos;": "'",
  "&ndash;": "\u2013",
  "&mdash;": "\u2014",
  "&ldquo;": "\u201C",
  "&rdquo;": "\u201D",
  "&lsquo;": "\u2018",
  "&rsquo;": "\u2019",
  "&iquest;": "\u00BF",
  "&iexcl;": "\u00A1",
  "&ntilde;": "\u00F1",
  "&Ntilde;": "\u00D1",
  "&Aacute;": "\u00C1",
  "&aacute;": "\u00E1",
  "&Eacute;": "\u00C9",
  "&eacute;": "\u00E9",
  "&Iacute;": "\u00CD",
  "&iacute;": "\u00ED",
  "&Oacute;": "\u00D3",
  "&oacute;": "\u00F3",
  "&Uacute;": "\u00DA",
  "&uacute;": "\u00FA",
  "&uuml;": "\u00FC",
  "&Uuml;": "\u00DC",
  "&nbsp;": " ",
};

/** Decode HTML entities commonly found in Confessor strings. */
export function decodeHtmlEntities(str: string): string {
  // Named entities
  let result = str.replace(/&[a-zA-Z]+;/g, (match) => HTML_ENTITIES[match] ?? match);
  // Numeric entities: &#123; or &#x1F;
  result = result.replace(/&#(\d+);/g, (_, code) => String.fromCharCode(parseInt(code, 10)));
  result = result.replace(/&#x([0-9a-fA-F]+);/g, (_, code) => String.fromCharCode(parseInt(code, 16)));
  // Strip any remaining HTML tags (e.g. <br>)
  result = result.replace(/<[^>]*>/g, "");
  return result;
}

// ---------------------------------------------------------------------------
// Slug aliases — multiple Confessor altids that map to a single CMS show.
// Confessor splits some shows into multiple hour-keys; the CMS has one page.
// ---------------------------------------------------------------------------

const SLUG_ALIASES: Record<string, string> = {
  // Something's Happening: 6 Confessor keys → 1 CMS show (program_slug = "somethingshappening")
  somethihappenihour: "somethingshappening",
  somethihappenihoura: "somethingshappening",
  somethingshappeningb: "somethingshappening",
  somethihappenibhour: "somethingshappening",
  somethihappenibhoura: "somethingshappening",
};

/**
 * Resolve a Confessor sh_altid to its canonical program_slug.
 * Returns the alias target if one exists, otherwise returns the altid as-is.
 */
export function resolveAltid(altid: string): string {
  return SLUG_ALIASES[altid] ?? altid;
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface ConfessorShow {
  sh_id: number;
  sh_altid: string; // slug — maps to cms_shows.program_slug
  sh_name: string;
  sh_djname: string;
  sh_stime?: string; // "HH:MM:SS" — may not be present in getshows response
  sh_ends?: string; // "HH:MM:SS" — may not be present in getshows response
  starts: string; // "1:00 AM" — human-readable start time
  ends: string; // "2:00 AM" — human-readable end time
  sh_ampm?: string;
  sh_ampm_ends?: string;
  sh_shour?: number; // seconds since midnight
  sh_start_time: number; // unix timestamp of this airing
  sh_len: number; // duration in seconds
  sh_days?: string; // "Mon Tue Wed ..."
  sh_info: number; // bitmask
  sh_desc: string;
  sh_email: string;
  sh_url: string;
  sh_photo: string;
  type?: string; // "Talk" | "Music" — category type
  ca_name?: string;
  ca_color?: string;
  ca_bgcolor?: string;
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

const CONFESSOR_TIMEOUT_MS = 30_000; // 30 seconds — legacy PHP can be slow

async function confessorFetch<T>(params: string): Promise<T | null> {
  const abort = new AbortController();
  const timer = setTimeout(() => abort.abort(), CONFESSOR_TIMEOUT_MS);
  try {
    const url = `${CONFESSOR_API_URL}?${params}&json=1`;
    const res = await fetch(url, {
      signal: abort.signal,
      next: { revalidate: 3600 },
    });
    if (!res.ok) {
      console.error(`[Confessor] HTTP ${res.status} from ${url}`);
      return null;
    }
    return (await res.json()) as T;
  } catch (err) {
    if (err instanceof DOMException && err.name === "AbortError") {
      console.error(`[Confessor] Timeout after ${CONFESSOR_TIMEOUT_MS}ms for ${params}`);
    } else {
      console.error(`[Confessor] Fetch failed for ${CONFESSOR_API_URL}?${params}:`, err);
    }
    return null;
  } finally {
    clearTimeout(timer);
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
/**
 * Raw schedule data from Confessor — each day can be an array or an object
 * keyed by index (the getshows endpoint returns objects, not arrays).
 */
export type ConfessorScheduleData = Record<
  string,
  ConfessorShow[] | Record<string, ConfessorShow>
>;

export async function getWeeklySchedule(): Promise<ConfessorScheduleData | null> {
  const cached = getCached<ConfessorScheduleData>(SCHEDULE_CACHE_KEY);
  if (cached) return cached;

  const data = await confessorFetch<ConfessorScheduleData>(
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
 * Convert Confessor time to schedule slot "HH:MM" format.
 * Handles both "HH:MM:SS" (from getday) and "1:00 AM" (from getshows).
 */
export function confessorTimeToSlotTime(time: string): string {
  // If already in HH:MM:SS format
  if (/^\d{2}:\d{2}:\d{2}$/.test(time)) {
    return time.substring(0, 5);
  }
  // If in HH:MM format already
  if (/^\d{2}:\d{2}$/.test(time)) {
    return time;
  }
  // Parse "1:00 AM" / "12:00 PM" format
  return ampmTo24(time);
}

/**
 * Convert "1:00 AM" or "12:00 PM" to "01:00" or "12:00" (24-hour HH:MM).
 */
export function ampmTo24(time: string): string {
  const match = time.match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/i);
  if (!match) {
    console.warn(`[Confessor] Could not parse time "${time}", defaulting to 00:00`);
    return "00:00";
  }
  let hours = parseInt(match[1], 10);
  const minutes = match[2];
  const period = match[3].toUpperCase();
  if (period === "AM" && hours === 12) hours = 0;
  if (period === "PM" && hours !== 12) hours += 12;
  return `${hours.toString().padStart(2, "0")}:${minutes}`;
}

/**
 * Get start time from a ConfessorShow in HH:MM format.
 * Prefers sh_stime if available, falls back to starts (AM/PM format).
 */
export function showStartTime(show: ConfessorShow): string {
  if (show.sh_stime) return confessorTimeToSlotTime(show.sh_stime);
  return confessorTimeToSlotTime(show.starts);
}

/**
 * Get end time from a ConfessorShow in HH:MM format.
 * Prefers sh_ends if available, falls back to ends (AM/PM format).
 */
export function showEndTime(show: ConfessorShow): string {
  if (show.sh_ends) return confessorTimeToSlotTime(show.sh_ends);
  return confessorTimeToSlotTime(show.ends);
}

/**
 * Normalize Confessor day data to an array.
 * The getshows API returns shows as an object keyed by index, not an array.
 */
export function normalizeDayShows(
  shows: ConfessorShow[] | Record<string, ConfessorShow>
): ConfessorShow[] {
  if (Array.isArray(shows)) return shows;
  return Object.values(shows);
}

/**
 * Deduplicate shows across weeks for a single day.
 * The getshows?before=1&after=1 endpoint returns 3 weeks of data.
 * We keep only the first occurrence per (altid + start_time_of_day).
 */
export function deduplicateDayShows(shows: ConfessorShow[]): ConfessorShow[] {
  const seen = new Set<string>();
  const result: ConfessorShow[] = [];
  for (const show of shows) {
    const startTime = showStartTime(show);
    const key = `${show.sh_altid}:${startTime}`;
    if (seen.has(key)) continue;
    seen.add(key);
    result.push(show);
  }
  return result;
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
