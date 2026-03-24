-- Migration 058: Live Board v2 features
-- Adds: daily goal overrides on campaigns, heartbeat tables for viewer counting
--
-- F3: daily_goal_overrides lets operators set manual daily goals during fund drives.
--     Auto-calculates from campaign goal / days remaining when no override exists.
-- F8: live_heartbeats tracks active viewers on donate.kpfk.org (privacy-forward,
--     hashed IPs only). page_view_snapshots stores 5-minute aggregate counts
--     for historical charting.

-- ============================================================================
-- F3: Daily goal overrides on campaigns
-- ============================================================================

-- JSONB column storing per-date overrides, e.g. {"2026-03-05": 45000}
-- Keys are date strings (station timezone), values are goal amounts in cents.
-- When no override exists for today, the live board auto-calculates:
--   daily_goal = campaign.goal_cents / days_remaining_in_campaign
ALTER TABLE campaigns
  ADD COLUMN IF NOT EXISTS daily_goal_overrides JSONB DEFAULT '{}';

-- ============================================================================
-- F8: Donation page viewer count (heartbeat system)
-- ============================================================================

-- Real-time heartbeat pings — upserted by hashed IP, pruned every 5 minutes.
-- No PII stored: ip_hash is a one-way SHA-256 of the IP address.
CREATE TABLE IF NOT EXISTS live_heartbeats (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  station_id UUID NOT NULL REFERENCES stations(id),
  ip_hash TEXT NOT NULL,
  page TEXT NOT NULL DEFAULT 'donate',
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Upsert index: one row per station + IP + page combination
CREATE UNIQUE INDEX IF NOT EXISTS live_heartbeats_station_ip_page_idx
  ON live_heartbeats (station_id, ip_hash, page);

-- Query index: count active viewers by station + page within time window
CREATE INDEX IF NOT EXISTS live_heartbeats_station_page_time_idx
  ON live_heartbeats (station_id, page, last_seen_at);

-- 5-minute aggregate snapshots for historical "viewers over time" charting.
-- A scheduled job snapshots the count from live_heartbeats, then prunes
-- heartbeat rows older than 5 minutes.
CREATE TABLE IF NOT EXISTS page_view_snapshots (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  station_id UUID NOT NULL REFERENCES stations(id),
  page TEXT NOT NULL DEFAULT 'donate',
  viewer_count INTEGER NOT NULL DEFAULT 0,
  snapshot_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS page_view_snapshots_station_page_time_idx
  ON page_view_snapshots (station_id, page, snapshot_at);

-- RLS: heartbeats are public-write (no auth on donate page), admin-read
ALTER TABLE live_heartbeats ENABLE ROW LEVEL SECURITY;
ALTER TABLE page_view_snapshots ENABLE ROW LEVEL SECURITY;

-- Service role bypasses RLS, so admin API routes work automatically.
-- No RLS policies needed for anon — the heartbeat endpoint uses the
-- service role client directly (same pattern as all admin API routes).

-- Tell PostgREST about the schema changes
NOTIFY pgrst, 'reload schema';
