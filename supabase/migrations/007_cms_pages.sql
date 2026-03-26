-- Migration 007: Evergreen pages
-- Phase 4: Blog + Pages

CREATE TABLE cms_pages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id uuid NOT NULL REFERENCES cms_stations(id),
  parent_id uuid REFERENCES cms_pages(id),
  title text NOT NULL,
  slug text NOT NULL,
  body text NOT NULL DEFAULT '',
  meta_title text,
  meta_description text,
  sort_order integer NOT NULL DEFAULT 0,
  is_published boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Unique slug per station (soft-delete aware)
CREATE UNIQUE INDEX idx_cms_pages_station_slug
  ON cms_pages (station_id, slug)
  WHERE deleted_at IS NULL;

-- Hierarchy traversal
CREATE INDEX idx_cms_pages_parent
  ON cms_pages (parent_id)
  WHERE deleted_at IS NULL;

-- Published pages
CREATE INDEX idx_cms_pages_published
  ON cms_pages (station_id, is_published)
  WHERE deleted_at IS NULL;

-- Updated at trigger
CREATE TRIGGER cms_pages_updated_at
  BEFORE UPDATE ON cms_pages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
