-- Migration 072: Page views analytics table
-- Lightweight, privacy-friendly page view tracking.
-- No cookies, no PII stored. IP is used only for geo lookup, then discarded.

CREATE TABLE IF NOT EXISTS page_views (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  -- What page was visited
  page_url text NOT NULL,
  page_path text NOT NULL,              -- just the path portion, e.g. /events/my-event
  -- Where the visitor came from
  referrer text,                         -- full referrer URL
  referrer_domain text,                  -- extracted domain, e.g. "instagram.com"
  -- Device info (parsed from user-agent server-side)
  device_type text CHECK (device_type IN ('desktop', 'mobile', 'tablet', 'unknown')),
  browser text,                          -- e.g. "Chrome", "Safari"
  os text,                               -- e.g. "iOS", "Windows"
  -- Geography (derived from IP server-side, IP itself is NOT stored)
  country text,
  region text,                           -- state/province
  city text,
  -- Time on page (updated via a second "leaving" ping)
  time_on_page_seconds integer,
  -- Session tracking (anonymous hash, not tied to any user)
  visitor_hash text,                     -- hash of IP + user-agent + date (daily unique, not trackable across days)
  -- Metadata
  station_id uuid REFERENCES stations(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes for common analytics queries
CREATE INDEX idx_page_views_created_at ON page_views (created_at DESC);
CREATE INDEX idx_page_views_page_path ON page_views (page_path);
CREATE INDEX idx_page_views_station_id ON page_views (station_id) WHERE station_id IS NOT NULL;
CREATE INDEX idx_page_views_referrer_domain ON page_views (referrer_domain) WHERE referrer_domain IS NOT NULL;

-- RLS: only service role (admin client) writes page views
ALTER TABLE page_views ENABLE ROW LEVEL SECURITY;

-- Service role needs explicit permission even with bypassrls —
-- some Supabase configurations require an explicit policy
CREATE POLICY "Service role full access"
  ON page_views
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

COMMENT ON TABLE page_views IS 'Privacy-friendly page view analytics. No cookies, no PII. IP used for geo lookup then discarded.';

-- ================================================================
-- RPC functions for the analytics dashboard
-- These run server-side aggregations so the API route just calls them.
-- ================================================================

-- Count unique daily visitors (distinct visitor_hash values)
CREATE OR REPLACE FUNCTION count_unique_visitors(since_date timestamptz)
RETURNS TABLE(count bigint) AS $$
  SELECT COUNT(DISTINCT visitor_hash) AS count
  FROM page_views
  WHERE created_at >= since_date;
$$ LANGUAGE sql STABLE;

-- Top pages by view count
CREATE OR REPLACE FUNCTION top_pages(since_date timestamptz, max_results integer DEFAULT 20)
RETURNS TABLE(page_path text, views bigint, unique_visitors bigint, avg_time_seconds numeric) AS $$
  SELECT
    page_path,
    COUNT(*) AS views,
    COUNT(DISTINCT visitor_hash) AS unique_visitors,
    ROUND(AVG(time_on_page_seconds) FILTER (WHERE time_on_page_seconds IS NOT NULL), 1) AS avg_time_seconds
  FROM page_views
  WHERE created_at >= since_date
  GROUP BY page_path
  ORDER BY views DESC
  LIMIT max_results;
$$ LANGUAGE sql STABLE;

-- Top referrer domains
CREATE OR REPLACE FUNCTION top_referrers(since_date timestamptz, max_results integer DEFAULT 15)
RETURNS TABLE(referrer_domain text, views bigint) AS $$
  SELECT
    COALESCE(referrer_domain, 'Direct / None') AS referrer_domain,
    COUNT(*) AS views
  FROM page_views
  WHERE created_at >= since_date
  GROUP BY referrer_domain
  ORDER BY views DESC
  LIMIT max_results;
$$ LANGUAGE sql STABLE;

-- Device type breakdown
CREATE OR REPLACE FUNCTION device_breakdown(since_date timestamptz)
RETURNS TABLE(device_type text, views bigint) AS $$
  SELECT
    COALESCE(device_type, 'unknown') AS device_type,
    COUNT(*) AS views
  FROM page_views
  WHERE created_at >= since_date
  GROUP BY device_type
  ORDER BY views DESC;
$$ LANGUAGE sql STABLE;

-- Browser breakdown
CREATE OR REPLACE FUNCTION browser_breakdown(since_date timestamptz)
RETURNS TABLE(browser text, views bigint) AS $$
  SELECT
    COALESCE(browser, 'Unknown') AS browser,
    COUNT(*) AS views
  FROM page_views
  WHERE created_at >= since_date
  GROUP BY browser
  ORDER BY views DESC;
$$ LANGUAGE sql STABLE;

-- Country breakdown
CREATE OR REPLACE FUNCTION country_breakdown(since_date timestamptz, max_results integer DEFAULT 15)
RETURNS TABLE(country text, views bigint) AS $$
  SELECT
    COALESCE(country, 'Unknown') AS country,
    COUNT(*) AS views
  FROM page_views
  WHERE created_at >= since_date
  GROUP BY country
  ORDER BY views DESC
  LIMIT max_results;
$$ LANGUAGE sql STABLE;

-- Daily view counts for the chart
CREATE OR REPLACE FUNCTION daily_views(since_date timestamptz)
RETURNS TABLE(date date, views bigint, unique_visitors bigint) AS $$
  SELECT
    (created_at AT TIME ZONE 'America/Los_Angeles')::date AS date,
    COUNT(*) AS views,
    COUNT(DISTINCT visitor_hash) AS unique_visitors
  FROM page_views
  WHERE created_at >= since_date
  GROUP BY date
  ORDER BY date ASC;
$$ LANGUAGE sql STABLE;

-- Average time on page (overall)
CREATE OR REPLACE FUNCTION avg_time_on_page(since_date timestamptz)
RETURNS TABLE(avg_seconds numeric) AS $$
  SELECT ROUND(AVG(time_on_page_seconds), 1) AS avg_seconds
  FROM page_views
  WHERE created_at >= since_date
    AND time_on_page_seconds IS NOT NULL
    AND time_on_page_seconds > 0;
$$ LANGUAGE sql STABLE;

NOTIFY pgrst, 'reload schema';
