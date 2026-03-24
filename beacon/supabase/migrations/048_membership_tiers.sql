-- Phase 3C: Membership tier infrastructure
-- Tiers are station-configurable thresholds (e.g., "Supporter", "Sustainer Circle", "Champion")
-- based on annual giving. The portal dashboard uses these to show the donor their current tier
-- and proximity to the next one. Ships dark — if no rows exist, the feature is invisible.

CREATE TABLE IF NOT EXISTS membership_tiers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id uuid REFERENCES stations(id),
  name text NOT NULL,
  min_annual_cents integer NOT NULL,
  display_order integer NOT NULL DEFAULT 0,
  benefits jsonb DEFAULT '[]'::jsonb,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  deleted_at timestamptz
);

-- Index for querying active tiers by station
CREATE INDEX IF NOT EXISTS membership_tiers_station_active_idx
  ON membership_tiers(station_id) WHERE is_active = true AND deleted_at IS NULL;

-- RLS: donors can read active tiers for their station (needed for portal dashboard)
ALTER TABLE membership_tiers ENABLE ROW LEVEL SECURITY;

CREATE POLICY membership_tiers_read_policy ON membership_tiers
  FOR SELECT
  USING (is_active = true AND deleted_at IS NULL);

-- Let PostgREST know about the new table
NOTIFY pgrst, 'reload schema';
