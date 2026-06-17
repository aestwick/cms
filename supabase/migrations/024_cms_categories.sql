-- Migration 024: Coverage-area categories
-- Phase 2a: editorial taxonomy for Stories. A station-scoped tree
-- (coverage areas + sub-categories) with a Voice color, optional nav
-- placement, and a description. Does NOT touch cms_posts — linking
-- stories to a category is a later chunk.

-- ============================================================
-- cms_categories — station-scoped coverage-area tree
-- ============================================================
CREATE TABLE IF NOT EXISTS cms_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id uuid NOT NULL REFERENCES cms_stations(id),
  parent_id uuid REFERENCES cms_categories(id) ON DELETE CASCADE,
  name text NOT NULL,
  slug text NOT NULL,
  description text,
  -- One of the five Voices, used for category-coding in the UI.
  color text CHECK (color IS NULL OR color IN ('news', 'music', 'culture', 'community', 'talk')),
  show_in_nav boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Unique slug per station (soft-delete aware)
CREATE UNIQUE INDEX IF NOT EXISTS idx_cms_categories_station_slug
  ON cms_categories (station_id, slug)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_cms_categories_parent
  ON cms_categories (parent_id)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_cms_categories_station_nav
  ON cms_categories (station_id, show_in_nav)
  WHERE deleted_at IS NULL AND show_in_nav = true;

CREATE TRIGGER cms_categories_updated_at
  BEFORE UPDATE ON cms_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- Seed the four coverage areas + a few sub-categories.
-- Idempotent: only inserts when the slug is absent for the station.
-- ============================================================
DO $$
DECLARE
  v_station uuid;
  v_news uuid;
  v_gov uuid;
BEGIN
  SELECT id INTO v_station FROM cms_stations ORDER BY created_at LIMIT 1;
  IF v_station IS NULL THEN
    RETURN;
  END IF;

  -- Top-level coverage areas
  INSERT INTO cms_categories (station_id, name, slug, color, show_in_nav, sort_order)
  SELECT v_station, 'News', 'news', 'news', true, 1
  WHERE NOT EXISTS (SELECT 1 FROM cms_categories WHERE station_id = v_station AND slug = 'news' AND deleted_at IS NULL);

  INSERT INTO cms_categories (station_id, name, slug, color, show_in_nav, sort_order)
  SELECT v_station, 'Sports', 'sports', 'culture', true, 2
  WHERE NOT EXISTS (SELECT 1 FROM cms_categories WHERE station_id = v_station AND slug = 'sports' AND deleted_at IS NULL);

  INSERT INTO cms_categories (station_id, name, slug, color, show_in_nav, sort_order)
  SELECT v_station, 'Station Updates', 'station-updates', 'community', true, 3
  WHERE NOT EXISTS (SELECT 1 FROM cms_categories WHERE station_id = v_station AND slug = 'station-updates' AND deleted_at IS NULL);

  INSERT INTO cms_categories (station_id, name, slug, color, show_in_nav, sort_order)
  SELECT v_station, 'Governance & Finance', 'governance-finance', 'talk', true, 4
  WHERE NOT EXISTS (SELECT 1 FROM cms_categories WHERE station_id = v_station AND slug = 'governance-finance' AND deleted_at IS NULL);

  -- Sub-categories
  SELECT id INTO v_news FROM cms_categories WHERE station_id = v_station AND slug = 'news' AND deleted_at IS NULL;
  SELECT id INTO v_gov FROM cms_categories WHERE station_id = v_station AND slug = 'governance-finance' AND deleted_at IS NULL;

  INSERT INTO cms_categories (station_id, parent_id, name, slug, color, sort_order)
  SELECT v_station, v_news, 'Local', 'news-local', 'news', 1
  WHERE v_news IS NOT NULL AND NOT EXISTS (SELECT 1 FROM cms_categories WHERE station_id = v_station AND slug = 'news-local' AND deleted_at IS NULL);

  INSERT INTO cms_categories (station_id, parent_id, name, slug, color, sort_order)
  SELECT v_station, v_news, 'National', 'news-national', 'news', 2
  WHERE v_news IS NOT NULL AND NOT EXISTS (SELECT 1 FROM cms_categories WHERE station_id = v_station AND slug = 'news-national' AND deleted_at IS NULL);

  INSERT INTO cms_categories (station_id, parent_id, name, slug, color, sort_order)
  SELECT v_station, v_gov, 'Board', 'governance-board', 'talk', 1
  WHERE v_gov IS NOT NULL AND NOT EXISTS (SELECT 1 FROM cms_categories WHERE station_id = v_station AND slug = 'governance-board' AND deleted_at IS NULL);

  INSERT INTO cms_categories (station_id, parent_id, name, slug, color, sort_order)
  SELECT v_station, v_gov, 'Budget', 'governance-budget', 'talk', 2
  WHERE v_gov IS NOT NULL AND NOT EXISTS (SELECT 1 FROM cms_categories WHERE station_id = v_station AND slug = 'governance-budget' AND deleted_at IS NULL);
END $$;
