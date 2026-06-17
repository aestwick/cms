-- Migration 026: Flipbook — homepage promo carousel
-- The flipbook is the rotating hero on the public homepage: scheduled
-- promo panels (events, fund drive, features) with artwork, a caption,
-- and a CTA. Staff-managed (admin/editor) via the Flipbook editor.
--
-- Panel status (live / scheduled / expired) is COMPUTED from starts_at /
-- expires_at at read time — not stored. Station-level flipbook settings
-- (show count, randomize, auto-hide expired) live in cms_stations.settings
-- under the "flipbook" key, so no extra table is needed for them.

CREATE TABLE IF NOT EXISTS cms_flipbook_panels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id uuid NOT NULL REFERENCES cms_stations(id),
  title text NOT NULL,
  caption text,
  cta_label text,
  link_url text,
  opens_new_tab boolean NOT NULL DEFAULT true,
  -- Artwork (Supabase Storage path or absolute URL). accent_color is the
  -- tint shown when no artwork is set (and the preview stand-in).
  image_path text,
  accent_color text,
  -- Scheduling window. NULL starts_at = live immediately; NULL expires_at
  -- = never expires.
  starts_at timestamptz,
  expires_at timestamptz,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Homepage read path: a station's panels in display order.
CREATE INDEX IF NOT EXISTS idx_cms_flipbook_panels_station_order
  ON cms_flipbook_panels (station_id, sort_order)
  WHERE deleted_at IS NULL;

CREATE TRIGGER cms_flipbook_panels_updated_at
  BEFORE UPDATE ON cms_flipbook_panels
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Seed default flipbook settings into the station's settings bag (only if
-- the "flipbook" key isn't already present).
UPDATE cms_stations
SET settings = jsonb_set(
  settings,
  '{flipbook}',
  '{"show_count": 20, "randomize": false, "auto_hide_expired": true}'::jsonb,
  true
)
WHERE NOT (settings ? 'flipbook');
