-- Migration 015: Show photo gallery
-- Adds a gallery table for show-specific photo galleries (carousel, grid, etc.)
-- Seeded with Rhapsody in Black's carousel photos from the Aiir scrape.

-- ============================================================
-- cms_show_gallery — Photos linked to a show, with captions
-- ============================================================
CREATE TABLE IF NOT EXISTS cms_show_gallery (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  show_id uuid NOT NULL REFERENCES cms_shows(id) ON DELETE CASCADE,
  image_path text NOT NULL,
  alt_text text,
  caption text,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_cms_show_gallery_show_id
  ON cms_show_gallery(show_id, sort_order);

CREATE TRIGGER cms_show_gallery_updated_at
  BEFORE UPDATE ON cms_show_gallery
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- Seed: Rhapsody in Black gallery photos (from Aiir carousel)
-- ============================================================
DO $$
DECLARE
  kpfk_id uuid;
  v_show_id uuid;
BEGIN
  SELECT id INTO kpfk_id FROM cms_stations WHERE slug = 'kpfk';
  SELECT id INTO v_show_id FROM cms_shows
    WHERE station_id = kpfk_id AND slug = 'rhapsody-in-black' AND deleted_at IS NULL;

  IF v_show_id IS NOT NULL THEN
    -- Clear existing gallery for idempotent re-run
    DELETE FROM cms_show_gallery WHERE show_id = v_show_id;

    INSERT INTO cms_show_gallery (show_id, image_path, alt_text, caption, sort_order)
    VALUES
      (v_show_id,
       'https://mmo.aiircdn.com/237/68ace8f519fad.jpg',
       'N.W.A with Jim Dawson',
       'N.W.A with Dr. Dre and Eazy-E, joined by host Jim Dawson, writer Dane Webb and MC Ren',
       0),
      (v_show_id,
       'https://mmo.aiircdn.com/237/67cdeb770e93e.jpg',
       'Jim Dawson with Anthony Gonzalez and Ray Regalado',
       'Jim Dawson with Anthony Gonzalez and Ray Regalado, frequent guests on the show',
       1),
      (v_show_id,
       'https://mmo.aiircdn.com/237/697297d9b304b.jpg',
       'Bill Gardner, Joe Houston, and Jim Dawson',
       'Former host Bill Gardner with saxophonist Joe Houston, Jim Dawson behind them',
       2);
  END IF;
END $$;
