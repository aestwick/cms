-- Migration 002: Shows and Show Hosts
-- Core content tables for the show page system

-- ============================================================
-- cms_shows — One row per show. Replaces Aiir page-per-show model.
-- ============================================================
CREATE TABLE IF NOT EXISTS cms_shows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id uuid NOT NULL REFERENCES cms_stations(id),
  title text NOT NULL,
  slug text NOT NULL,
  tagline text,
  description text,
  history text,
  show_type text NOT NULL DEFAULT 'talk' CHECK (show_type IN ('talk', 'music', 'mixed')),
  program_slug text,
  logo_path text,
  banner_path text,
  contact_preference text NOT NULL DEFAULT 'form' CHECK (contact_preference IN ('form', 'email', 'both', 'none')),
  contact_email text,
  website_url text,
  rss_url text,
  social_links jsonb NOT NULL DEFAULT '{}',
  is_active boolean NOT NULL DEFAULT true,
  is_claimed boolean NOT NULL DEFAULT false,
  claimed_at timestamptz,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Unique slug per station (only among non-deleted)
CREATE UNIQUE INDEX idx_cms_shows_station_slug
  ON cms_shows(station_id, slug) WHERE deleted_at IS NULL;

CREATE INDEX idx_cms_shows_station_program_slug
  ON cms_shows(station_id, program_slug);

CREATE INDEX idx_cms_shows_station_active
  ON cms_shows(station_id, is_active) WHERE deleted_at IS NULL;

CREATE TRIGGER cms_shows_updated_at
  BEFORE UPDATE ON cms_shows
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- cms_show_hosts — Junction table linking hosts to shows
-- ============================================================
CREATE TABLE IF NOT EXISTS cms_show_hosts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  show_id uuid NOT NULL REFERENCES cms_shows(id) ON DELETE CASCADE,
  profile_id uuid REFERENCES cms_profiles(id),
  name text NOT NULL,
  bio text,
  photo_path text,
  email text,
  is_primary boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_cms_show_hosts_show_id ON cms_show_hosts(show_id);
CREATE INDEX idx_cms_show_hosts_profile_id ON cms_show_hosts(profile_id);

CREATE TRIGGER cms_show_hosts_updated_at
  BEFORE UPDATE ON cms_show_hosts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
