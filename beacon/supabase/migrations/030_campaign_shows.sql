-- campaign_shows: Links campaigns to shows with optional per-show goals
-- Enables tracking "Uprising raised $5k during Fall Drive" by letting
-- admins set show-level fundraising goals within a campaign.
-- station_id is denormalized for fast query scoping.

CREATE TABLE campaign_shows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid NOT NULL REFERENCES campaigns(id),
  show_id uuid NOT NULL REFERENCES shows(id),
  goal_cents bigint CHECK (goal_cents >= 0),
  station_id uuid NOT NULL REFERENCES stations(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(campaign_id, show_id)
);

-- Indexes for common query patterns
CREATE INDEX idx_campaign_shows_campaign ON campaign_shows(campaign_id);
CREATE INDEX idx_campaign_shows_show ON campaign_shows(show_id);
CREATE INDEX idx_campaign_shows_station ON campaign_shows(station_id);

-- RLS policies
ALTER TABLE campaign_shows ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read campaign_shows
CREATE POLICY campaign_shows_select ON campaign_shows
  FOR SELECT TO authenticated
  USING (true);

-- Service role gets full access (admin API routes use service role)
CREATE POLICY campaign_shows_service_all ON campaign_shows
  FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);
