-- Migration 011: Tags and Show Tags
-- Tag taxonomy for shows: topic, format, audience categories.

-- ============================================================
-- cms_tags — Station-scoped tag definitions
-- ============================================================
CREATE TABLE IF NOT EXISTS cms_tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id uuid NOT NULL REFERENCES cms_stations(id),
  name text NOT NULL,
  slug text NOT NULL,
  category text NOT NULL DEFAULT 'topic' CHECK (category IN ('topic', 'format', 'audience')),
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Unique slug per station
CREATE UNIQUE INDEX idx_cms_tags_station_slug
  ON cms_tags(station_id, slug);

CREATE INDEX idx_cms_tags_station_category
  ON cms_tags(station_id, category);

-- ============================================================
-- cms_show_tags — Junction table linking tags to shows
-- ============================================================
CREATE TABLE IF NOT EXISTS cms_show_tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  show_id uuid NOT NULL REFERENCES cms_shows(id) ON DELETE CASCADE,
  tag_id uuid NOT NULL REFERENCES cms_tags(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Each show can have a tag only once
CREATE UNIQUE INDEX idx_cms_show_tags_show_tag
  ON cms_show_tags(show_id, tag_id);

CREATE INDEX idx_cms_show_tags_tag_id
  ON cms_show_tags(tag_id);
