/**
 * Shared formatting and display utilities for the CMS.
 */

const SUPABASE_STORAGE_URL =
  "https://czjhwhfqohpmwprhasve.supabase.co/storage/v1/object/public";

/**
 * Resolve a Supabase Storage path to a full URL.
 * Passes through absolute URLs unchanged.
 */
export function resolveImageUrl(path: string): string {
  if (path.startsWith("http://") || path.startsWith("https://")) return path;
  return `${SUPABASE_STORAGE_URL}/${path}`;
}

/**
 * Format an ISO date string for display.
 * All dates rendered in America/Los_Angeles timezone.
 */
export function formatDate(
  iso: string,
  options?: Intl.DateTimeFormatOptions
): string {
  return new Date(iso).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    timeZone: "America/Los_Angeles",
    ...options,
  });
}

/**
 * Format an ISO date string to time only.
 */
export function formatTime(iso: string): string {
  return new Date(iso).toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    timeZone: "America/Los_Angeles",
  });
}

/**
 * Format a 24h time string (HH:mm) to 12h display.
 */
export function formatTime24(t: string): string {
  const [h, m] = t.split(":");
  const hour = parseInt(h);
  const ampm = hour >= 12 ? "PM" : "AM";
  const h12 = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
  return `${h12}:${m} ${ampm}`;
}
