-- Migration 006: CMS Events
-- Community events, sponsored events, protests, meetings.
-- KPFK-produced ticketed events come from Beacon API — not stored here.

CREATE TABLE IF NOT EXISTS cms_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id uuid NOT NULL REFERENCES cms_stations(id),
  title text NOT NULL,
  slug text NOT NULL,
  description text,
  category text NOT NULL DEFAULT 'community'
    CHECK (category IN ('community', 'sponsored', 'fundraising', 'meeting', 'protest', 'other')),
  venue_name text,
  venue_address text,
  event_url text,
  image_path text,
  price_text text,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz,
  is_all_day boolean NOT NULL DEFAULT false,
  is_highlighted boolean NOT NULL DEFAULT false,
  created_by uuid NOT NULL REFERENCES cms_profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Unique slug per station (active records only)
CREATE UNIQUE INDEX idx_cms_events_station_slug
  ON cms_events(station_id, slug)
  WHERE deleted_at IS NULL;

-- Filter by category
CREATE INDEX idx_cms_events_station_category
  ON cms_events(station_id, category);

-- Date-based queries (upcoming events)
CREATE INDEX idx_cms_events_station_starts_at
  ON cms_events(station_id, starts_at)
  WHERE deleted_at IS NULL;

-- Highlighted/featured events
CREATE INDEX idx_cms_events_station_highlighted
  ON cms_events(station_id, is_highlighted)
  WHERE deleted_at IS NULL;

CREATE TRIGGER cms_events_updated_at
  BEFORE UPDATE ON cms_events
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
