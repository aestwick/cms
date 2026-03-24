-- 036_seed_cdn_gift_images.sql
-- Upsert gift records with CDN image URLs from mmo.aiircdn.com
--
-- Applied: 2026-02-20
-- Notes:
--   - 66 gifts with CDN-hosted product images
--   - Uses static_id for conflict resolution (unique constraint)
--   - ON CONFLICT updates name and image_url so this is safe to re-run
--   - FMV and minimums are placeholder/zero — update when pricing is finalized
--   - Categorized as: music, books, merch, events

-- ============================================================================
-- MUSIC / MEDIA
-- ============================================================================

INSERT INTO gifts (station_id, name, category, image_url, static_id, fulfillment_method, sort_order)
VALUES
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Back Beat - Singles from the Island Vaults 1962 3-CD Set', 'music', 'https://mmo.aiircdn.com/237/6998dd1ea3a32.jpg', 'back-beat-island-vaults-3cd', 'ship', 300),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Buena Vista Social Club - Original Broadway Cast Recording CD', 'music', 'https://mmo.aiircdn.com/237/6998dd1c8ba20.jpg', 'buena-vista-cd', 'ship', 301),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Bruce Springsteen - Lost and Found Selections from the Lost Albums CD', 'music', 'https://mmo.aiircdn.com/237/6998dd1d49646.jpg', 'springsteen-lost-found-cd', 'ship', 302),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Bruce Springsteen - Lost and Found Selections from the Lost Albums LPs', 'music', 'https://mmo.aiircdn.com/237/6998dd1cb4a03.jpg', 'springsteen-lost-found-lp', 'ship', 303),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Candido - Afro Cuban Jazz Sound 3-CD Set', 'music', 'https://mmo.aiircdn.com/237/6998dd1bc811d.jpg', 'candido-afro-cuban-3cd', 'ship', 304),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Buena Vista Social Club - Original Broadway Cast Recording LP', 'music', 'https://mmo.aiircdn.com/237/6998dd1bc8199.jpg', 'buena-vista-lp', 'ship', 305),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Cathy Fink and Marcy Marxer - From China to Appalachia CD', 'music', 'https://mmo.aiircdn.com/237/6998dd1af3ca2.jpg', 'fink-marxer-china-appalachia', 'ship', 306),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Clinton Davis - Ever Returning CD', 'music', 'https://mmo.aiircdn.com/237/6998dd1a24216.jpg', 'clinton-davis-ever-returning', 'ship', 307),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Ella Fitzgerald and Louis Armstrong - The Definitive Ella and Louis 3-CD Set', 'music', 'https://mmo.aiircdn.com/237/6998dd1926566.jpg', 'ella-louis-definitive-3cd', 'ship', 308),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Doc Watson and Gaither Carlton CD', 'music', 'https://mmo.aiircdn.com/237/6998dd194b650.jpg', 'doc-watson-gaither-carlton', 'ship', 309),
  ((SELECT id FROM stations WHERE code = 'kpfk'), '100 Golden Oldies 4-CD Set', 'music', 'https://mmo.aiircdn.com/237/6998dd14d060f.jpg', '100-golden-oldies-4cd', 'ship', 310),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Grateful Dead - The Warfield San Francisco 1980 2-CD Set', 'music', 'https://mmo.aiircdn.com/237/6998dd1577bea.jpg', 'grateful-dead-warfield-2cd', 'ship', 311),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Alison Brown and Steve Martin - Safe Sensible and Sane CD', 'music', 'https://mmo.aiircdn.com/237/6998dd1501137.jpg', 'brown-martin-safe-sensible', 'ship', 312),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Alice Howe and Freebo Live CD', 'music', 'https://mmo.aiircdn.com/237/6998dd1476a36.jpg', 'alice-howe-freebo-live', 'ship', 313),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFA Chris Hedges Digital Speech Collection', 'music', 'https://mmo.aiircdn.com/237/6998dc137770e.jpg', 'kpfa-hedges-digital-speech', 'digital', 314),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK Black History Dynamic Womens CD Pack (Collage 1)', 'music', 'https://mmo.aiircdn.com/237/6998dc124cdaf.jpg', 'kpfk-bhm-womens-cd-collage', 'ship', 315),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK Black History Dynamic Womens CD Pack (Billie Holiday)', 'music', 'https://mmo.aiircdn.com/237/6998dc1259473.jpg', 'kpfk-bhm-womens-cd-billie', 'ship', 316),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK Black History Dynamic Womens CD Pack (Ella Fitzgerald)', 'music', 'https://mmo.aiircdn.com/237/6998dc11cb3e2.jpg', 'kpfk-bhm-womens-cd-ella', 'ship', 317),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK Black History Dynamic Womens CD Pack (Nina Simone)', 'music', 'https://mmo.aiircdn.com/237/6998dc115dc59.jpg', 'kpfk-bhm-womens-cd-nina', 'ship', 318),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK BHM Centennial Flagship Collection USB Drive', 'music', 'https://mmo.aiircdn.com/237/6998dc12d064a.jpg', 'kpfk-bhm-centennial-usb', 'ship', 319),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK Blues and Jazz Queens Collection', 'music', 'https://mmo.aiircdn.com/237/6998dc10c561c.jpg', 'kpfk-blues-jazz-queens', 'ship', 320),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK Paul Robeson Collection CDs and Book', 'music', 'https://mmo.aiircdn.com/237/6998dc0e0c8bd.jpg', 'kpfk-robeson-collection', 'ship', 321),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK South African Freedom Songs Pack', 'music', 'https://mmo.aiircdn.com/237/6998dc0bcc550.jpg', 'kpfk-sa-freedom-songs', 'ship', 322),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Lesterfari Kings Music - Stolen Legacy CD', 'music', 'https://mmo.aiircdn.com/237/6998dc09f33a3.jpg', 'lesterfari-stolen-legacy', 'ship', 323),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'McCartney Wings On the Run Pack', 'music', 'https://mmo.aiircdn.com/237/6998dc083028d.jpg', 'mccartney-wings-on-run', 'ship', 324),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'LL Cool J - All World Double LP', 'music', 'https://mmo.aiircdn.com/237/6998dc09677e0.jpg', 'll-cool-j-all-world-lp', 'ship', 325),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Paul Robeson - On My Journey Independent Recordings CD', 'music', 'https://mmo.aiircdn.com/237/6998dc076831b.jpg', 'robeson-on-my-journey', 'ship', 326),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'PRA Public Radio Anthology USB Drive', 'music', 'https://mmo.aiircdn.com/237/6998dc067fb39.jpg', 'pra-anthology-usb', 'ship', 327),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Poncho Sanchez - Live at the Belly Up Tavern CD', 'music', 'https://mmo.aiircdn.com/237/6998dc0684963.jpg', 'poncho-sanchez-belly-up', 'ship', 328),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Judy Collins - Now Playing LP', 'music', 'https://mmo.aiircdn.com/237/6998dc0239b2d.jpg', 'judy-collins-now-playing-lp', 'ship', 329),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Silvio Rodriguez - Rabo de Nube Tail of a Tornado CD', 'music', 'https://mmo.aiircdn.com/237/6998dc058e8f8.jpg', 'silvio-rodriguez-rabo-de-nube', 'ship', 330),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'The Very Best of Doo-Wop 2-CD Set', 'music', 'https://mmo.aiircdn.com/237/6998dc03af63e.jpg', 'very-best-doo-wop-2cd', 'ship', 331),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Im With Her - Wild and Clear and Blue CD', 'music', 'https://mmo.aiircdn.com/237/6998dc01b5d30.jpg', 'im-with-her-wild-clear-blue', 'ship', 332),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'John Coltrane - A Love Supreme Legacy Pack', 'music', 'https://mmo.aiircdn.com/237/6998dc013db0c.jpg', 'coltrane-love-supreme-pack', 'ship', 333),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Maher Publications - DownBeat Magazine Subscription', 'music', 'https://mmo.aiircdn.com/237/6998dc0969f89.jpg', 'downbeat-magazine-sub', 'digital', 334)
ON CONFLICT (static_id) DO UPDATE SET
  name = EXCLUDED.name,
  image_url = EXCLUDED.image_url;

-- ============================================================================
-- BOOKS
-- ============================================================================

INSERT INTO gifts (station_id, name, category, image_url, static_id, fulfillment_method, sort_order)
VALUES
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Chris Hedges - A Genocide Foretold Book', 'books', 'https://mmo.aiircdn.com/237/6998dd1a57823.jpg', 'hedges-genocide-foretold', 'ship', 400),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Charles Derber - Fighting Oligarchy Book', 'books', 'https://mmo.aiircdn.com/237/6998dd1ad6a94.jpg', 'derber-fighting-oligarchy', 'ship', 401),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'George McCalman - Illustrated Black History Book', 'books', 'https://mmo.aiircdn.com/237/6998dd1876e06.jpg', 'mccalman-illustrated-bh', 'ship', 402),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Gerald Horne - Acknowledging Radical Histories', 'books', 'https://mmo.aiircdn.com/237/6998dd1821a3c.jpg', 'horne-radical-histories', 'ship', 403),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Gerald Horne - I Dare Say A Gerald Horne Reader', 'books', 'https://mmo.aiircdn.com/237/6998dd17c8191.jpg', 'horne-i-dare-say', 'ship', 404),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Gerald Horne - Paul Robeson The Artist as Revolutionary Signed Book', 'books', 'https://mmo.aiircdn.com/237/6998dd17778da.jpg', 'horne-robeson-signed', 'ship', 405),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Gerald Horne 3-Book Pack', 'books', 'https://mmo.aiircdn.com/237/6998dd163cb2d.jpg', 'horne-3-book-pack', 'ship', 406),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Howard Bryant - Kings and Pawns Jackie Robinson and Paul Robeson Book', 'books', 'https://mmo.aiircdn.com/237/6998dd1557047.jpg', 'bryant-kings-pawns', 'ship', 407),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Kelly Sullivan Walden - Dreamifesting Book', 'books', 'https://mmo.aiircdn.com/237/6998dc13d27f9.jpg', 'walden-dreamifesting', 'ship', 408),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK Angela Davis Constant Struggle Pack Book Audio', 'books', 'https://mmo.aiircdn.com/237/6998dc1346984.jpg', 'kpfk-angela-davis-pack', 'ship', 409),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK Black Panther Party Collection', 'books', 'https://mmo.aiircdn.com/237/6998dc10e2a4a.jpg', 'kpfk-bpp-collection', 'ship', 410),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK Malcolm X Autobiography Pack', 'books', 'https://mmo.aiircdn.com/237/6998dc0e62260.jpg', 'kpfk-malcolm-x-auto-pack', 'ship', 411),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK James Baldwin Fire Next Time Pack', 'books', 'https://mmo.aiircdn.com/237/6998dc0f01ad7.jpg', 'kpfk-baldwin-fire-next-time', 'ship', 412),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK Women of Black History Collection', 'books', 'https://mmo.aiircdn.com/237/6998dc0bce6f0.jpg', 'kpfk-women-bh-collection', 'ship', 413),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Les and Tamara Payne - The Dead Are Arising The Life of Malcolm X Book', 'books', 'https://mmo.aiircdn.com/237/6998dc0a62725.jpg', 'payne-dead-are-arising', 'ship', 414),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Laura K Field - Furious Minds The Making of the MAGA New Right Book', 'books', 'https://mmo.aiircdn.com/237/6998dc0a80a90.jpg', 'field-furious-minds', 'ship', 415),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Michelle Alexander - The New Jim Crow Book Audio Pack', 'books', 'https://mmo.aiircdn.com/237/6998dc080c2c8.jpg', 'alexander-new-jim-crow', 'ship', 416),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Muir and Finch - Cop Cop Breaking the Fixed System of American Policing Book', 'books', 'https://mmo.aiircdn.com/237/6998dc0780141.jpg', 'muir-finch-cop-cop', 'ship', 417),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Mann and Hotez - Science Under Siege Book', 'books', 'https://mmo.aiircdn.com/237/6998dc087ce82.jpg', 'mann-hotez-science-siege', 'ship', 418),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Sasha Abramsky - American Carnage Book', 'books', 'https://mmo.aiircdn.com/237/6998dc0594c58.jpg', 'abramsky-american-carnage', 'ship', 419),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Sim Kern - Genocide Bad Book', 'books', 'https://mmo.aiircdn.com/237/6998dc03b1906.jpg', 'kern-genocide-bad', 'ship', 420),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Tom Zoellner - The Road Was Full of Thorns Book', 'books', 'https://mmo.aiircdn.com/237/6998dc02451dc.jpg', 'zoellner-road-of-thorns', 'ship', 421),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Thom Hartmann - The Last American President Book', 'books', 'https://mmo.aiircdn.com/237/6998dc02c8f3d.jpg', 'hartmann-last-american-pres', 'ship', 422)
ON CONFLICT (static_id) DO UPDATE SET
  name = EXCLUDED.name,
  image_url = EXCLUDED.image_url;

-- ============================================================================
-- MERCHANDISE
-- ============================================================================

INSERT INTO gifts (station_id, name, category, image_url, static_id, fulfillment_method, sort_order)
VALUES
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Grateful Dead - The Music Never Stopped Promo Poster', 'merch', 'https://mmo.aiircdn.com/237/6998dd163c6bf.jpg', 'grateful-dead-poster', 'ship', 500),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK Bumper Sticker', 'merch', 'https://mmo.aiircdn.com/237/6998dc1049808.jpg', 'kpfk-bumper-sticker', 'ship', 501),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK Logo Mug', 'merch', 'https://mmo.aiircdn.com/237/6998dc0eedfea.jpg', 'kpfk-logo-mug', 'ship', 502),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK Grocery Bag Tote', 'merch', 'https://mmo.aiircdn.com/237/6998dc0fdf788.jpg', 'kpfk-grocery-tote', 'ship', 503),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK QR Code Canvas Tote Bag', 'merch', 'https://mmo.aiircdn.com/237/6998dc0d83d90.jpg', 'kpfk-qr-canvas-tote', 'ship', 504),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK QR Code Shirt - Medium', 'merch', 'https://mmo.aiircdn.com/237/6998dc0d5de59.jpg', 'kpfk-qr-shirt-medium', 'ship', 505),
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'KPFK Promotional 10005', 'merch', 'https://mmo.aiircdn.com/237/6998dc0dd738b.jpg', 'kpfk-promo-10005', 'ship', 506)
ON CONFLICT (static_id) DO UPDATE SET
  name = EXCLUDED.name,
  image_url = EXCLUDED.image_url;

-- ============================================================================
-- EVENTS
-- ============================================================================

INSERT INTO gifts (station_id, name, category, image_url, static_id, fulfillment_method, sort_order)
VALUES
  ((SELECT id FROM stations WHERE code = 'kpfk'), 'Democracy Now - Brunch and Broadcast w Amy Goodman', 'events', 'https://mmo.aiircdn.com/237/6998dd199d6b6.jpg', 'democracy-now-brunch', 'will_call', 600)
ON CONFLICT (static_id) DO UPDATE SET
  name = EXCLUDED.name,
  image_url = EXCLUDED.image_url;

-- ============================================================================
-- Also update existing gifts from migration 029 that overlap with CDN items.
-- Match by partial name to update their image_url to the CDN version.
-- ============================================================================

-- "Buena Vista Social Club" from 029 → now has separate CD/LP entries above,
-- update the old record's image to the CD version
UPDATE gifts SET image_url = 'https://mmo.aiircdn.com/237/6998dd1c8ba20.jpg'
WHERE static_id = 'buenavista';

-- "Bumper Sticker" from 029 → matches "KPFK Bumper Sticker"
UPDATE gifts SET image_url = 'https://mmo.aiircdn.com/237/6998dc1049808.jpg'
WHERE static_id = 'bumper-sticker';

-- "Ella & Louis" from 029 → matches "Ella Fitzgerald and Louis Armstrong"
UPDATE gifts SET image_url = 'https://mmo.aiircdn.com/237/6998dd1926566.jpg'
WHERE static_id = 'ella-louis';

-- "Genocide Foretold" from 029 → matches "Chris Hedges - A Genocide Foretold Book"
UPDATE gifts SET image_url = 'https://mmo.aiircdn.com/237/6998dd1a57823.jpg'
WHERE static_id = 'genocide-foretold';

-- "Road of Thorns" from 029 → matches "Tom Zoellner - The Road Was Full of Thorns Book"
UPDATE gifts SET image_url = 'https://mmo.aiircdn.com/237/6998dc02451dc.jpg'
WHERE static_id = 'road-of-thorns';

-- "The Last American" from 029 → matches "Thom Hartmann - The Last American President Book"
UPDATE gifts SET image_url = 'https://mmo.aiircdn.com/237/6998dc02c8f3d.jpg'
WHERE static_id = 'lastamerican';

-- "DownBeat Magazine" from 029 → matches "Maher Publications - DownBeat Magazine Subscription"
UPDATE gifts SET image_url = 'https://mmo.aiircdn.com/237/6998dc0969f89.jpg'
WHERE static_id = 'downbeat-mag';

-- ============================================================================
-- Fix category mismatch: migration 029 used 'book' (singular) but the donate
-- form filters use 'books' (plural). Update old records to match.
-- ============================================================================

UPDATE gifts SET category = 'books' WHERE category = 'book';

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
