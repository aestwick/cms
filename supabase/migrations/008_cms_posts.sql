-- Migration 008: Blog posts
-- Phase 4: Blog + Pages

CREATE TABLE cms_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id uuid NOT NULL REFERENCES cms_stations(id),
  show_id uuid REFERENCES cms_shows(id),
  author_id uuid NOT NULL REFERENCES cms_profiles(id),
  title text NOT NULL,
  slug text NOT NULL,
  body text NOT NULL DEFAULT '',
  excerpt text,
  featured_image_path text,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published')),
  published_at timestamptz,
  is_featured boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Unique slug per station (soft-delete aware)
CREATE UNIQUE INDEX idx_cms_posts_station_slug
  ON cms_posts (station_id, slug)
  WHERE deleted_at IS NULL;

-- Feed queries: published posts ordered by date
CREATE INDEX idx_cms_posts_feed
  ON cms_posts (station_id, status, published_at DESC)
  WHERE deleted_at IS NULL;

-- Show-scoped posts
CREATE INDEX idx_cms_posts_show
  ON cms_posts (show_id)
  WHERE deleted_at IS NULL;

-- Featured posts
CREATE INDEX idx_cms_posts_featured
  ON cms_posts (station_id, is_featured)
  WHERE deleted_at IS NULL AND is_featured = true;

-- Updated at trigger
CREATE TRIGGER cms_posts_updated_at
  BEFORE UPDATE ON cms_posts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
