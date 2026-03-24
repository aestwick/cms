-- Migration 001: CMS Foundation
-- Creates core tables: cms_stations, cms_profiles
-- Creates shared utility: update_updated_at() trigger function (if not exists)

-- ============================================================
-- Shared utility function (may already exist from QIR/Beacon)
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- cms_stations — Station configuration (one row per station)
-- ============================================================
CREATE TABLE IF NOT EXISTS cms_stations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  tagline text,
  timezone text NOT NULL DEFAULT 'America/Los_Angeles',
  stream_url text,
  beacon_api_url text,
  confessor_api_url text,
  analytics_site_id text,
  settings jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER cms_stations_updated_at
  BEFORE UPDATE ON cms_stations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- cms_profiles — CMS user accounts (separate from Beacon)
-- ============================================================
CREATE TABLE IF NOT EXISTS cms_profiles (
  id uuid PRIMARY KEY,  -- = Supabase Auth user ID
  station_id uuid NOT NULL REFERENCES cms_stations(id),
  role text NOT NULL CHECK (role IN ('admin', 'editor', 'host')),
  display_name text,
  email text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX idx_cms_profiles_station_id ON cms_profiles(station_id);
CREATE INDEX idx_cms_profiles_role ON cms_profiles(role);

CREATE TRIGGER cms_profiles_updated_at
  BEFORE UPDATE ON cms_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- Seed: KPFK station record
-- ============================================================
INSERT INTO cms_stations (name, slug, tagline, timezone, stream_url, beacon_api_url, confessor_api_url, settings)
VALUES (
  'KPFK 90.7 FM',
  'kpfk',
  'Pacifica Foundation Community Radio — Los Angeles',
  'America/Los_Angeles',
  'https://kpfk.streamguys1.com/kpfk-aac',
  'https://donate.kpfk.org/api',
  'https://confessor.kpfk.org',
  '{
    "fund_drive_active": false,
    "default_contact_email": "info@kpfk.org",
    "social_links": {
      "facebook": "https://facebook.com/kpfk",
      "twitter": "https://twitter.com/kpfk",
      "instagram": "https://instagram.com/kpfk907fm"
    }
  }'::jsonb
)
ON CONFLICT (slug) DO NOTHING;
