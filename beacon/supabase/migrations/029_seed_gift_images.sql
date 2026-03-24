-- 029_seed_gift_images.sql
-- Seed gift records with image URLs for items that already have images
-- in public/images/ but no database records yet.
--
-- Applied: 2026-02-19
-- Notes:
--   - FMV, minimums, and descriptions are placeholder/zero — update later
--   - station_id is looked up dynamically (KPFK station uses gen_random_uuid)
--   - static_id set for stable references from form code
--   - ON CONFLICT on static_id so this migration is safe to re-run

-- ============================================================================
-- MERCHANDISE
-- ============================================================================

INSERT INTO gifts (station_id, name, category, image_url, static_id, fulfillment_method, sort_order)
VALUES
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK T-Shirt', 'merch', '/images/kpfk-shirt.jpg', 'kpfk-shirt', 'ship', 10),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK Tote Bag', 'merch', '/images/kpfk-tote.jpg', 'kpfk-tote', 'ship', 20),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'QR T-Shirt', 'merch', '/images/qr-shirt.jpg', 'qr-shirt', 'ship', 30),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'QR Tote Bag', 'merch', '/images/qr-tote.jpg', 'qr-tote', 'ship', 40),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Bumper Sticker', 'merch', '/images/bumper sticker.jpeg', 'bumper-sticker', 'ship', 50),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'SB Bumper Sticker', 'merch', '/images/SB bumper sticker.png', 'sb-bumper-sticker', 'ship', 60)
ON CONFLICT (static_id) DO UPDATE SET image_url = EXCLUDED.image_url;

-- ============================================================================
-- BOOKS
-- ============================================================================

INSERT INTO gifts (station_id, name, category, image_url, static_id, fulfillment_method, sort_order)
VALUES
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Amy Goodman', 'book', '/images/amy-goodman.jpg', 'amy-goodman', 'ship', 100),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Foreign Agents', 'book', '/images/foreign-agents.jpg', 'foreign-agents', 'ship', 110),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Genocide Foretold', 'book', '/images/genocide-foretold.jpg', 'genocide-foretold', 'ship', 120),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'The Inheritance (JFK)', 'book', '/images/inheritance-jfk.jpg', 'inheritance-jfk', 'ship', 130),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Higher Self Mastery', 'book', '/images/higher-self-mastery.jpeg', 'higher-self-mastery', 'ship', 140),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'The Last American', 'book', '/images/lastamerican.jpeg', 'lastamerican', 'ship', 150),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Road of Thorns', 'book', '/images/road-of-thorns.jpg', 'road-of-thorns', 'ship', 160),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Trillion Dollar War Machine', 'book', '/images/trillion-dollar-war-machine.jpg', 'trillion-dollar-war-machine', 'ship', 170),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Apartheid to Democracy', 'book', '/images/apartheid-to-democracy.jpg', 'apartheid-to-democracy', 'ship', 180),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Red Light Therapy', 'book', '/images/red-light-therapy.jpg', 'red-light-therapy', 'ship', 190),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Levine Spider', 'book', '/images/levine-spider.jpeg', 'levine-spider', 'ship', 200)
ON CONFLICT (static_id) DO UPDATE SET image_url = EXCLUDED.image_url;

-- ============================================================================
-- MUSIC / MEDIA
-- ============================================================================

INSERT INTO gifts (station_id, name, category, image_url, static_id, fulfillment_method, sort_order)
VALUES
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Buena Vista Social Club', 'music', '/images/buenavista.jpg', 'buenavista', 'ship', 300),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'DownBeat Magazine', 'music', '/images/downbeat-mag.jpg', 'downbeat-mag', 'ship', 310),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Dylan Bootleg Series', 'music', '/images/dylan-bootleg.webp', 'dylan-bootleg', 'ship', 320),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Dylan PRA', 'music', '/images/dylan-pra.jpg', 'dylan-pra', 'ship', 330),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Ella & Louis', 'music', '/images/ella-louis.jpg', 'ella-louis', 'ship', 340),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Foreigner 4', 'music', '/images/foreigner-4.webp', 'foreigner-4', 'ship', 350),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Le Pique Roti', 'music', '/images/lepique-roti.jpeg', 'lepique-roti', 'ship', 360)
ON CONFLICT (static_id) DO UPDATE SET image_url = EXCLUDED.image_url;
