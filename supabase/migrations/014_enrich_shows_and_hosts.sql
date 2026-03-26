-- Migration 014: Enrich shows with template data and insert hosts
-- Updates 28 template shows with taglines and logos.
-- Updates all 99 shows with image_url references for future logo upload.
-- Inserts cms_show_hosts rows for 28 template shows.

DO $$
DECLARE
  kpfk_id uuid;
  v_show_id uuid;
BEGIN
  SELECT id INTO kpfk_id FROM cms_stations WHERE slug = 'kpfk';
  IF kpfk_id IS NULL THEN
    RAISE EXCEPTION 'KPFK station not found.';
  END IF;

  -- ============================================
  -- Part 1: Update template shows with taglines
  -- ============================================
  UPDATE cms_shows SET tagline = 'A journey into the music and spiritual legacy of John and Alice Coltrane'
    WHERE station_id = kpfk_id AND slug = 'awakenings';
  UPDATE cms_shows SET tagline = 'In-depth conversations on politics, economics, and movements — cutting past headlines to what really matters.', logo_path = 'https://mmo.aiircdn.com/237/68c5ee850deeb.jpg'
    WHERE station_id = kpfk_id AND slug = 'beneath-the-surface';
  UPDATE cms_shows SET tagline = 'Bikes first — people-powered transportation for all.', logo_path = 'https://mmo.aiircdn.com/237/6915782ad4f0f.jpg'
    WHERE station_id = kpfk_id AND slug = 'bike-talk';
  UPDATE cms_shows SET tagline = 'Relentless activism for a thriving planet.', logo_path = 'https://mmo.aiircdn.com/237/68a36a5aa0b27.jpg'
    WHERE station_id = kpfk_id AND slug = 'california-solartopia';
  UPDATE cms_shows SET tagline = 'Pacifica''s national magazine show connecting labor, race, and democracy struggles across the U.S. and the world.', logo_path = 'https://placehold.co/280x280/e3f2fd/1565c0?text=CRD'
    WHERE station_id = kpfk_id AND slug = 'capitalism-race-and-democracy';
  UPDATE cms_shows SET tagline = 'Where News Gets Undressed - and Truth Comes Out Wrinkled', logo_path = 'https://mmo.aiircdn.com/237/68f1a46b3e47d.jpg'
    WHERE station_id = kpfk_id AND slug = 'the-cary-harrison-files';
  UPDATE cms_shows SET tagline = 'Voices for peace, justice, and resistance worldwide.', logo_path = 'https://mmo.aiircdn.com/237/696b1d1a1f409.jpg'
    WHERE station_id = kpfk_id AND slug = 'codepink-radio';
  UPDATE cms_shows SET tagline = 'Dialogues for justice, solutions, and change.', logo_path = 'https://mmo.aiircdn.com/237/688c736b50875.jpg'
    WHERE station_id = kpfk_id AND slug = 'cut-to-the-chase';
  UPDATE cms_shows SET tagline = 'A show devoted to Grateful Dead and beyond', logo_path = 'https://mmo.aiircdn.com/237/67cde1b432099.jpeg'
    WHERE station_id = kpfk_id AND slug = 'dark-star-dead-and-music';
  UPDATE cms_shows SET tagline = 'Su programa para derrotar la Indiferencia'
    WHERE station_id = kpfk_id AND slug = 'enfoque-latino-con-ruben-tapia';
  UPDATE cms_shows SET tagline = 'Playing the best in Folk, Roots, and Americana for over half a century.', logo_path = 'https://mmo.aiircdn.com/237/68dc5afe98f33.jpg'
    WHERE station_id = kpfk_id AND slug = 'folkscene';
  UPDATE cms_shows SET tagline = 'Serving the voices of the Queer Community — Out Loud and Out Proud since 1974', logo_path = 'https://mmo.aiircdn.com/237/68abf78ecac9b.jpg'
    WHERE station_id = kpfk_id AND slug = 'imru';
  UPDATE cms_shows SET tagline = 'Noticias con consciencia. Voice for the people.'
    WHERE station_id = kpfk_id AND slug = 'informativo-pacifica';
  UPDATE cms_shows SET tagline = 'Literature, culture, and conversation from the heart of Los Angeles.', logo_path = 'https://mmo.aiircdn.com/237/681a795c4ae68.jpg'
    WHERE station_id = kpfk_id AND slug = 'la-review-of-books';
  UPDATE cms_shows SET tagline = 'Radio for la raza, la causa, la gente de Aztlan', logo_path = 'https://mmo.aiircdn.com/237/65f30902cde19.jpg'
    WHERE station_id = kpfk_id AND slug = 'la-raza-radio';
  UPDATE cms_shows SET tagline = 'Where movement leaders speak and truth is aired', logo_path = 'https://mmo.aiircdn.com/237/68dc6d96b839b.png'
    WHERE station_id = kpfk_id AND slug = 'lawyers-guild';
  UPDATE cms_shows SET tagline = 'News and views on the Middle East and relevant U.S. foreign policy.', logo_path = 'https://mm.aiircdn.com/427/5c246c52dff85.jpg'
    WHERE station_id = kpfk_id AND slug = 'middle-east-in-focus';
  UPDATE cms_shows SET tagline = 'The music, artistry, and legacies of the artists who defined an era.', logo_path = 'https://mmo.aiircdn.com/237/69728b1716ca2.jpg'
    WHERE station_id = kpfk_id AND slug = 'profiles';
  UPDATE cms_shows SET tagline = 'Culture. Opinions. Dialogue. Entertainment.', logo_path = 'https://mmo.aiircdn.com/237/684fbf6ba6983.jpg'
    WHERE station_id = kpfk_id AND slug = 'qr-code';
  UPDATE cms_shows SET tagline = 'Resisting corporate power and defending democracy', logo_path = 'https://mm.aiircdn.com/427/5a0a33de13ec1.jpg'
    WHERE station_id = kpfk_id AND slug = 'ralph-nader-radio-hour';
  UPDATE cms_shows SET tagline = 'Truth & Fire — Verdad y Fuego', logo_path = 'https://mmo.aiircdn.com/237/69b2e96de003c.jpeg'
    WHERE station_id = kpfk_id AND slug = 'revolucion-arcoiris';
  UPDATE cms_shows SET tagline = 'A celebration of classic blues, R&B, and group harmony from the 1930s to the ''60s.', logo_path = 'https://mmo.aiircdn.com/237/68acea2048fbb.jpg'
    WHERE station_id = kpfk_id AND slug = 'rhapsody-in-black';
  UPDATE cms_shows SET tagline = 'Solutions Journalism for Social Justice', logo_path = 'https://mmo.aiircdn.com/237/68de28fd950f1.png'
    WHERE station_id = kpfk_id AND slug = 'sonali-kolhatkar';
  UPDATE cms_shows SET tagline = 'News, Information & Analysis with Dino — from Los Angeles to the world.', logo_path = 'https://mmo.aiircdn.com/237/68c4b5d36b764.jpg'
    WHERE station_id = kpfk_id AND slug = 'the-signal';
  UPDATE cms_shows SET tagline = 'Uncompromising voices. Ground-level truth.', logo_path = 'https://mmo.aiircdn.com/237/685e891465c49.png'
    WHERE station_id = kpfk_id AND slug = 'sojourner-truth';
  UPDATE cms_shows SET tagline = 'News specials, live forums, archival broadcasts & more.', logo_path = 'https://mm.aiircdn.com/427/5a42caecdc3c1.jpg'
    WHERE station_id = kpfk_id AND slug = 'special-programming';
  UPDATE cms_shows SET tagline = 'The International LGBTQ Radio Magazine', logo_path = 'https://mmo.aiircdn.com/237/68aadc1639fe7.jpg'
    WHERE station_id = kpfk_id AND slug = 'this-way-out';
  UPDATE cms_shows SET tagline = 'Jazz, Blues, and Beyond — West Coast Sounds', logo_path = 'https://mmo.aiircdn.com/237/68aaa248f3f57.jpg'
    WHERE station_id = kpfk_id AND slug = 'way-out-west';

  -- ============================================
  -- Part 2: Set logo_path for freeform shows from scrape image_url
  -- ============================================
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a26fd9ca6f0d.jpg'
    WHERE station_id = kpfk_id AND slug = 'afrodicia1' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a04d050d0a12.jpg'
    WHERE station_id = kpfk_id AND slug = 'alan-watts2' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'http://www.aotaradio.com/wp-content/uploads/2015/07/AOTA-HEADER-IMAGE.jpg'
    WHERE station_id = kpfk_id AND slug = 'all-of-the-above' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mmo.aiircdn.com/237/6567bc3a71500.jpg'
    WHERE station_id = kpfk_id AND slug = 'alternative-radio' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT7nr2rDFoippHH2T3ewp_AJo3PVSDj3-mnhw&usqp=CAU'
    WHERE station_id = kpfk_id AND slug = 'american-indian-airwaves' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5ca2419cb27be.jpg'
    WHERE station_id = kpfk_id AND slug = 'arts-in-review' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a03674a0237e.jpg'
    WHERE station_id = kpfk_id AND slug = 'aware-show' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a2f19fe63c55.jpg'
    WHERE station_id = kpfk_id AND slug = 'beautiful-struggle' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mmo.aiircdn.com/237/67a1077f60e65.png'
    WHERE station_id = kpfk_id AND slug = 'bibliocracy' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'http://bradblog.com/images/BradCast_Logo7_Progressive_BradKPFK_300.png'
    WHERE station_id = kpfk_id AND slug = 'bradcast-with-brad-friedman' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5c141c7d9b190.jpg'
    WHERE station_id = kpfk_id AND slug = 'breakbeats-and-rhymes' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mmo.aiircdn.com/237/630520079ebe1.jpg'
    WHERE station_id = kpfk_id AND slug = 'cal-state-la-community-news-hour' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a7b4acf48205.jpg'
    WHERE station_id = kpfk_id AND slug = 'canto-sin-fronteras' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5bea9163b1589.png'
    WHERE station_id = kpfk_id AND slug = 'on-contact' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'http://www.kpfk.org/images/stories/programs/contactoancestral2.jpg'
    WHERE station_id = kpfk_id AND slug = 'contacto-ancestral' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5d826ba176123.jpg'
    WHERE station_id = kpfk_id AND slug = 'contragolpe' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a03779d32d5a.png'
    WHERE station_id = kpfk_id AND slug = 'democracy-now' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mmo.aiircdn.com/237/60106ddf0353a.jpg'
    WHERE station_id = kpfk_id AND slug = 'dialogos-de-media-noche' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mmo.aiircdn.com/237/6049121b64656.jpg'
    WHERE station_id = kpfk_id AND slug = 'eco-justice-radio' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a64ef0f153a7.jpeg'
    WHERE station_id = kpfk_id AND slug = 'economic-update' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a42c73996c18.jpg'
    WHERE station_id = kpfk_id AND slug = 'edna-tatums-gospel-classics' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a0374aadf6fb.jpg'
    WHERE station_id = kpfk_id AND slug = 'encuentros' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5b1cae0b84a3b.jpg'
    WHERE station_id = kpfk_id AND slug = 'expansion-zone' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a0a14a79c0aa.jpg'
    WHERE station_id = kpfk_id AND slug = 'feminist-magazine' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5dd2f46b3e2f6.jpg'
    WHERE station_id = kpfk_id AND slug = 'freedom-now' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5d715e4ea6b0c.jpg'
    WHERE station_id = kpfk_id AND slug = 'global-village-mondays' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mmo.aiircdn.com/237/60469b2883953.jpg'
    WHERE station_id = kpfk_id AND slug = 'global-village-tuesdays' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a037a35bff1a.jpg'
    WHERE station_id = kpfk_id AND slug = 'global-village-thursdays-w-john-schneider' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a037a9a6dbac.jpg'
    WHERE station_id = kpfk_id AND slug = 'global-village-fridays-w-sergio-mielniczenko' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mmo.aiircdn.com/237/61c0d6d7c1db9.jpg'
    WHERE station_id = kpfk_id AND slug = 'in-the-cut-radio' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mmo.aiircdn.com/237/6318340393847.jpg'
    WHERE station_id = kpfk_id AND slug = 'jazz-sessions' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a0a3e7db737f.jpg'
    WHERE station_id = kpfk_id AND slug = 'l-a-theatre-works' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mmo.aiircdn.com/237/6009c79a53c9f.png'
    WHERE station_id = kpfk_id AND slug = 'jon-wiener' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mmo.aiircdn.com/237/62c495af1280b.jpg'
    WHERE station_id = kpfk_id AND slug = 'midnight-snack' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5aafecccdedff.jpg'
    WHERE station_id = kpfk_id AND slug = 'nightscapes' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a42c21624e01.jpg'
    WHERE station_id = kpfk_id AND slug = 'nuestra-voz' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a57d896347d4.jpg'
    WHERE station_id = kpfk_id AND slug = 'the-out-agenda' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5bbcee2968f35.jpg'
    WHERE station_id = kpfk_id AND slug = 'pacifica-performance-showcase' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mmo.aiircdn.com/237/630da42cf02e6.jpg'
    WHERE station_id = kpfk_id AND slug = 'phil-and-teds-sexy-boomer-show' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5b623f644c74f.jpg'
    WHERE station_id = kpfk_id AND slug = 'pocho-hour-of-power' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mmo.aiircdn.com/237/61b10aa5a3cb9.jpg'
    WHERE station_id = kpfk_id AND slug = 'radio-insurgencia-femenina' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5d71f8133b162.jpg'
    WHERE station_id = kpfk_id AND slug = 'reggae-central' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5cb4c953c4579.jpg'
    WHERE station_id = kpfk_id AND slug = 'roots-music-and-beyond' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mmo.aiircdn.com/237/62c9b51199724.png'
    WHERE station_id = kpfk_id AND slug = 'scholars-circle' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a2b0ee240f00.jpg'
    WHERE station_id = kpfk_id AND slug = 'soul-rebel-radio' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mmo.aiircdn.com/237/651b1fa5620f8.png'
    WHERE station_id = kpfk_id AND slug = 'soundwaves' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5cd5c40a9797d.jpg'
    WHERE station_id = kpfk_id AND slug = 'stairway-to-heaven' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5c100ad197e38.jpg'
    WHERE station_id = kpfk_id AND slug = 'suplemento-comunitario' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5b1eaecf38487.jpg'
    WHERE station_id = kpfk_id AND slug = 'swana-region-radio' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mmo.aiircdn.com/237/5e399dba4159c.jpg'
    WHERE station_id = kpfk_id AND slug = 'think-outside-the-cage' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5b8858fbd6378.png'
    WHERE station_id = kpfk_id AND slug = 'thom-hartmann' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a0b58da4ef24.jpg'
    WHERE station_id = kpfk_id AND slug = 'travel-tips-for-aztlan' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mm.aiircdn.com/427/5a0a2d0013d00.jpg'
    WHERE station_id = kpfk_id AND slug = 'voces-de-libertad' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mmo.aiircdn.com/237/67e8abec95351.jpg'
    WHERE station_id = kpfk_id AND slug = 'working-voices' AND logo_path IS NULL;
  UPDATE cms_shows SET logo_path = 'https://mmo.aiircdn.com/237/60668c9683190.jpg'
    WHERE station_id = kpfk_id AND slug = 'dj-potira' AND logo_path IS NULL;

  -- ============================================
  -- Part 3: Insert hosts for template shows
  -- ============================================

  -- Beneath the Surface with Suzi Weissman (beneath-the-surface)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'beneath-the-surface' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Suzi Weissman', 'Host and creator of Beneath the Surface, Suzi is a journalist, scholar, and award-winning broadcaster. She edits Against the Current and Critique, and is the author of Victor Serge: The Course is Set on Hope. Her interviews bring clarity and urgency to global political debates.', NULL, true, 0),
      (v_show_id, 'Robert Brenner', 'Executive Producer. Director of UCLA''s Center for Social Theory and Comparative History and a leading historian of political economy. His books include The Boom and the Bubble, Merchants and Revolution, and The Economics of Global Turbulence. He also co-edited Rebel Rank and File and helps shape the program''s big-picture analysis.', NULL, false, 1),
      (v_show_id, 'Alan Minsky', 'Producer of Beneath the Surface and Executive Director of Progressive Democrats of America (PDA). Former Program Director at KPFK, he produced The Ralph Nader Radio Hour and the Nation Magazine podcast Start Making Sense. He is also a co-founder of the Los Angeles Independent Media Center.', NULL, false, 2);
  END IF;

  -- Bike Talk (bike-talk)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'bike-talk' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Nick Richert', 'Nick Richert launched Bike Talk in 2008 to amplify LA''s rising bike movement and bring real conversations about streets, justice, and community to the airwaves. He''s been a steady voice for people-powered change, connecting with riders, mechanics, and everyday advocates who believe in a city that moves differently. Nick''s strength is finding the humanity and hope in every bike story—because for him, bikes aren''t just a topic; they''re a tool for building community.', NULL, true, 0),
      (v_show_id, 'Taylor Nichols', 'Taylor Nichols jumped into bike advocacy when his daughters started rolling through the neighborhood, sparking his mission for safer streets. Embedded in local organizing—from the Mid City West Neighborhood Council to the LA Bicycle Advisory Committee—Taylor brings the stories and struggles of everyday Angelenos fighting for mobility justice. He rides, listens, and pushes for roads that work for all, carrying both a parent''s heart and an activist''s drive into every show.', NULL, false, 1);
  END IF;

  -- California Solartopia (california-solartopia)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'california-solartopia' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Harvey Wasserman', 'Harvey Wasserman is a veteran journalist, activist, and organizer with deep roots in California''s anti-nuclear and grassroots clean energy movements. He''s been fighting for ecological justice and people-powered solutions for decades, bringing local stories and global urgency together on and off the airwaves. Harvey''s voice stands with communities demanding a just, sustainable future—no nukes, no compromise.', NULL, true, 0),
      (v_show_id, 'Myla Reson', 'Myla Reson is a longtime environmental advocate and on-the-ground organizer whose work bridges neighborhoods, natural spaces, and frontline movements across the Southwest. Whether working for Los Angeles to divest from Arizona''s Palo Verde nuclear power plant or campaigning to save the Ballona Wetlands, Myla connects with listeners as a neighbor in the fight for healthy, just communities. She inspires steady resistance and shares hope in every battle.', NULL, false, 1),
      (v_show_id, 'Tatanka Bricca', 'Tatanka Bricca is a lifelong nonviolent activist whose journey spans from Vietnam draft resistance and UFW boycott organizing to co-founding Amnesty International West Coast with Joan Baez. A Métis Medicine Wheel teacher, Sundancer, and jazz pianist, Tatanka has worked alongside leaders from Ben & Jerry to Mikhail Gorbachev. His decades in solar energy and deep roots in community radio embody the intersection of ecological action and cultural wisdom that powers California Solartopia.', NULL, false, 2);
  END IF;

  -- The Cary Harrison Files (the-cary-harrison-files)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'the-cary-harrison-files' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Cary Harrison', 'Award-winning global correspondent and story sleuth, Cary blends fearless journalism with biting satire to host The Cary Harrison Files. His accolades include Vanderbilt University''s Siegenthaler Award for integrity and courage in journalism, the Sigma Delta Chi Award from the Society of Professional Journalists (two years running), honors from American Women in Radio & Television for investigative reporting, AP''s 1st place for Best Commentary, UN recognition for environmental and peace work, and an Edward R. Murrow Award nomination.', NULL, true, 0),
      (v_show_id, 'Renèe Yaworski', 'Director and Producer at Cosmos Creative TV, with legal training at Oxford and reporting experience with Impunity Watch. Renèe supports research and production for the show.', NULL, false, 1);
  END IF;

  -- CODEPINK Radio (codepink-radio)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'codepink-radio' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Marcy Winograd', 'Marcy Winograd volunteers as a co-producer of CODEPINK Radio and Empire on the Rocks podcast, co-anchoring the twice-monthly podcast with Medea Benjamin. A retired English and government teacher, Marcy also coordinates CODEPINK''s Drop the ADL campaign and mobilizes for Palestinian rights within teachers'' unions, including United Teachers of Los Angeles and California Teachers Association (CTA). In 2010, Marcy mobilized 41% of the vote in her primary congressional peace challenge to then incumbent Jane Harman. Her activism began in high school when she marched against the Vietnam War and later joined the defense team of Pentagon Papers whistleblower Daniel Ellsberg.
 Full bio', 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/svgs/solid/arrow-up-right-from-square.svg', true, 0),
      (v_show_id, 'Medea Benjamin', 'Medea Benjamin is a cofounder of both CODEPINK and the international human rights organization Global Exchange. She is the author of 11 books, including Drone Warfare: Killing by Remote Control, Inside Iran, and War in Ukraine. Described as "one of America''s most committed—and most effective—fighters for human rights" by New York Newsday, she was one of 1,000 exemplary women nominated to receive the Nobel Peace Prize. In 2010 she received the Martin Luther King, Jr. Peace Prize from the Fellowship of Reconciliation.
 Full bio', 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/svgs/solid/arrow-up-right-from-square.svg', false, 1),
      (v_show_id, 'Jodie Evans', 'Jodie Evans is the co-founder of CODEPINK and the after-school writing program 826LA, and serves on the CODEPINK Board of Directors. As Director of Administration in California Governor Jerry Brown''s first administration, Jodie championed environmental causes, resulting in breakthroughs in wind and solar technology. She has produced several documentary films including the Oscar-nominated The Square and climate change documentary This Changes Everything. Jodie is the co-editor of Twilight of Empire and Stop the Next War Now.
 Full bio', 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/svgs/solid/arrow-up-right-from-square.svg', false, 2),
      (v_show_id, 'Michelle Ellner', 'Michelle is a Latin America campaign coordinator of CODEPINK and producer of CODEPINK Radio and Empire on the Rocks podcast. Born in Venezuela, she holds a bachelor''s degree in languages and international affairs from the University La Sorbonne Paris IV. She worked for an international scholarship program and was sent to Haiti, Cuba, The Gambia, and other countries. Subsequently, she worked with community-based programs in Venezuela and served as an analyst of U.S.-Venezuela relations.
 Full bio', 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/svgs/solid/arrow-up-right-from-square.svg', false, 3),
      (v_show_id, 'Danaka Katovich', 'Danaka Katovich is CODEPINK''s National Co-Director. She graduated from DePaul University with a bachelor''s degree in Political Science in November 2020. Since 2018 she has been working towards ending US participation in the war in Yemen. At CODEPINK, she oversees all advocacy campaigns and facilitates local organizing in the Midwest and in Europe. Her writing can be found in Jacobin, Salon, Truthout, CommonDreams, and more.
 Full bio', 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/svgs/solid/arrow-up-right-from-square.svg', false, 4),
      (v_show_id, 'Jenin', 'Jenin is CODEPINK''s Palestine Campaigner. She graduated with a bachelor''s degree in Public Policy from the University of Illinois at Chicago in December of 2023. For over five years, Jenin has been a community organizer focused on the Palestinian movement through advocacy, digital storytelling, and grassroots mobilization. She is a firm believer in intertwined struggle and liberation for all.
 Full bio', 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/svgs/solid/arrow-up-right-from-square.svg', false, 5),
      (v_show_id, 'Megan Russell', 'Megan Russell is CODEPINK''s China is Not Our Enemy Campaign Coordinator. She graduated from the London School of Economics with a Master''s Degree in Conflict Studies, and attended NYU studying Conflict, Culture, and International Law. Megan spent one year studying in Shanghai, and over eight years studying Chinese Mandarin. Her research focuses on the intersection between US-China affairs, peacebuilding, and international development.
 Full bio', 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/svgs/solid/arrow-up-right-from-square.svg', false, 6),
      (v_show_id, 'Aaron', 'Aaron is CODEPINK''s War is Not Green Campaigner and East Coast Regional Organizer. Based in Brooklyn, NY, Aaron (they/he) holds an M.A. in Community Development and Planning from Clark University. They worked on internationalist climate justice organizing and Palestine, tenant, and abolitionist organizing. They continue to do this work nationally to combat militarized university repression and produce new modes of solidarity.
 Full bio', 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/svgs/solid/arrow-up-right-from-square.svg', false, 7),
      (v_show_id, 'Nuvpreet', 'Nuvpreet is CODEPINK''s Digital Content Producer & Bases Off Cyprus Campaign Coordinator, based in London, England. She completed a Bachelor''s in Politics & Sociology at the University of Cambridge, and an MA in Internet Equalities at the University of the Arts London. Her studies focused on racialised surveillance capitalism, with a focus on Artificial Intelligence as a weapon of war and settler colonialism.
 Full bio', 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/svgs/solid/arrow-up-right-from-square.svg', false, 8),
      (v_show_id, 'Ryan Wentz', 'Ryan Wentz is CODEPINK''s West Coast Organizer. He graduated from University of Colorado Boulder with a bachelor''s degree in Political Science in May 2017. After graduating, he spent six months in Occupied Palestine, doing research on the international weapons trade. He has been active in the antiwar, healthcare justice, and labor movements, and has produced for MintPress News and Empire Files.
 Full bio', 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/svgs/solid/arrow-up-right-from-square.svg', false, 9),
      (v_show_id, 'Makayla Heiser', 'Makayla Heiser is CODEPINK''s Digital Organizing Assistant. She graduated from Gonzaga University in December 2022 with a bachelor''s in Political Science and double minors in Critical Race Theory and Women''s and Gender studies. Through student organizing with United Students Against Sweatshops, she began to understand the global power of solidarity within the working class and the importance of collective liberation.
 Full bio', 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/svgs/solid/arrow-up-right-from-square.svg', false, 10),
      (v_show_id, 'Jasmine Butler', 'Jasmine Butler is CODEPINK''s Member & Youth Coordinator. Jasmine (they/them) was born and raised in Memphis by way of deep Mississippi roots. They''re a Black queer writer, cultural worker, and afrofuturist-abolitionist deeply committed to collective liberation through mutual care and education. They are growing as a principled network weaver, educator, historian, and archivist. Jasmine received a B.A. in Geography from Dartmouth College in 2021.
 Full bio', 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/svgs/solid/arrow-up-right-from-square.svg', false, 11);
  END IF;

  -- Cut To The Chase (cut-to-the-chase)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'cut-to-the-chase' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Sylvester (Sly) Rivers', 'Sylvester "Sly" Rivers is a veteran radio producer, activist, and trusted community voice. With decades spent building movements and lifting up underrepresented stories, Sly brings sharp insight and lived experience to every broadcast. His roots in local organizing and deep commitment to justice shape Cut To The Chase into a direct, people-first conversation every Friday morning—right from the heart of the community he serves.', NULL, true, 0);
  END IF;

  -- Dark Star, Dead & Music (dark-star-dead-and-music)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'dark-star-dead-and-music' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Arnella Barbara (Dark Star Gurl)', 'Arnella Barbara, known on air as Dark Star Gurl, is a creative force rooted in Los Angeles—radio host, DJ, production designer, opera singer, and lifelong Deadhead. She''s spent decades building community at the crossroads of art, music, and healing, always with the Grateful Dead as her North Star. Through Dark Star, Dead & Music, Arnella weaves rare grooves, personal stories, and the spirit of unity into a Sunday ritual for dreamers, listeners, and seekers across KPFK''s airwaves.', NULL, true, 0);
  END IF;

  -- FolkScene (folkscene)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'folkscene' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Allen Larman', 'Allen has dedicated decades to sharing the sounds that shape our lives, drawing from deep roots in both music and radio. Raised in the Southern California folk scene, he carries on the tradition begun by Howard and Roz Larman. His on-air warmth and passion connect listeners to the soul of the community and champion independent voices.', NULL, true, 0),
      (v_show_id, 'Kat Griffin', 'Kat brings a love for storytelling and a keen ear for the heart in every song. As a musician, activist, and longtime radio host rooted in LA''s folk circles, she''s tuned in to the everyday struggles and celebrations of real people—a spirit she brings to FolkScene every week.', NULL, false, 1);
  END IF;

  -- IMRU Radio (imru)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'imru' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Michael Taylor Gray', 'Michael Taylor Gray is a storyteller, producer, and longtime community advocate. An award-winning actor and original cast member of the GLAAD-recognized "Southern Baptist Sissies," Michael uses the mic to amplify authentic queer voices and honor IMRU''s radical legacy each week.', NULL, true, 0),
      (v_show_id, 'Contributors & Community Reporters', 'IMRU is built with community: rotating contributors, citizen journalists, and cultural workers who bring on-the-ground reporting, short features, and interviews from across queer life in Southern California and beyond.', NULL, false, 1);
  END IF;

  -- Informativo Pacifica (informativo-pacifica)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'informativo-pacifica' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Norma Martinez Velazquez', 'A journalist and activist dedicated to immigrant rights and human rights advocacy. Norma leads every episode with sharp analysis, compassion, and an unyielding commitment to truth.', NULL, true, 0);
  END IF;

  -- LA Review of Books (LARB) (la-review-of-books)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'la-review-of-books' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Medaya Ocher', 'Medaya Ocher brings sharp insight and genuine warmth to every conversation, connecting L.A.''s creative scene through bold, searching interviews.', NULL, true, 0),
      (v_show_id, 'Eric Newman', 'An Editor-at-Large for LARB and scholar of literature and queer theory, Eric''s interviews often explore identity, politics, and the shifting landscape of cultural power.', NULL, false, 1),
      (v_show_id, 'Kate Wolf', 'Also an Editor-at-Large at LARB, Kate''s background as a critic and artist shapes her keen attention to aesthetics, voice, and the inner lives of her guests.', NULL, false, 2);
  END IF;

  -- La Raza Radio (la-raza-radio)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'la-raza-radio' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Matt Sedillo', 'Matt Sedillo is an internationally renowned poet who has read in 15 countries and been translated into 9 languages. He''s been called the best political poet in America by investigative journalist Greg Palast and the "poet laureate of struggle" by historian Paul Ortiz. Matt has spoken at the San Francisco International Poetry Festival, the Texas Book Festival, and Casa de las Americas in Havana. He runs a weekly writers workshop at Re/Arte Centro Literario in Boyle Heights and is the literary director at dA Center for the Arts in Pomona.', NULL, true, 0),
      (v_show_id, 'Gary Baca', 'Gary Baca has over 20 years in radio, starting at Laney College in 1988 before moving to KALX Berkeley and then KPFK Los Angeles. He''s interviewed everyone from James Brown and Carlos Santana to Gil Scott-Heron and Ice Cube—plus deep archive conversations with artists like Maurice White, Rick James, and Teena Marie. As a kid, he''d wait for hours hoping to hear his favorite artists get interviewed. He never did, so he started doing it himself.', NULL, false, 1);
  END IF;

  -- The Lawyer's Guild with Jim Lafferty (lawyers-guild)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'lawyers-guild' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Jim Lafferty', 'Jim Lafferty is a lifelong activist and the Executive Director Emeritus of the National Lawyers Guild in Los Angeles. From marches against the Vietnam War to fighting for justice today, Jim''s leadership has shaped the city''s legal and social justice landscape for decades. He brings hard-won perspective and deep roots in Los Angeles movements to every conversation, connecting listeners to history and ongoing struggles.', NULL, true, 0),
      (v_show_id, 'Maria Hall', 'Maria Hall is a civil rights attorney, past co-chair of the National Lawyers Guild in Los Angeles, and director of the Los Angeles Incubator Consortium, supporting solo community lawyers. Maria brings a frontline focus to every show — sharing real stories from her work in the city''s neighborhoods and always centering people and movements driving change.', NULL, false, 1);
  END IF;

  -- Middle East in Focus (middle-east-in-focus)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'middle-east-in-focus' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Estee Chandler', 'Estee Chandler grew up in Southern California where her work in the film industry, on both sides of the camera, spans more than thirty years. Her political and civic work took on a new urgency in 2001 after the US Supreme Court ruled that the state of Florida must stop counting the votes in their 2000 Presidential election. In 2010 she launched a Los Angeles chapter of Jewish Voice for Peace (JVP), which is the largest progressive, Jewish, anti-Zionist organization in the world. JVP organizes our grassroots, multiracial, cross-class, intergenerational movement of U.S. based Jews into solidarity with the Palestinian freedom struggle, guided by a vision of justice, equality, and dignity for all people. She currently serves as the Board Chair of JVP''s sister organization JVP Action.', NULL, true, 0),
      (v_show_id, 'Nagwa Ibrahim', 'Nagwa Ibrahim is an attorney and filmmaker whose life''s work centers on defending human rights and telling the multidimensional stories of humanity to connect us beyond borders. She is currently the Legal Director at a national nonprofit organization that represents survivors of human trafficking, where she leads a team of attorneys providing direct legal services to the largest number of survivors of human trafficking in the United States, as well as training and technical assistance on human trafficking cases nationwide. Prior to this role, Nagwa was in private practice with a focus on immigration law and criminal defense, and has also worked as a civil and human rights attorney handling Guantánamo and other prisoner rights cases. Nagwa graduated from UCLA School of Law with a specialization in Critical Race Studies. Deeply connected to struggles both at home and abroad, Nagwa brings humanity, curiosity, and a global perspective to every conversation on Middle East in Focus.', NULL, false, 1);
  END IF;

  -- Profiles with Maggie LePique (profiles)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'profiles' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Maggie LePique', 'Maggie LePique has been on the radio since the 1980s, when she was spinning bebop and Kansas City jazz on KCUR in the midwest. She moved to LA and became a traffic reporter, winning an LA Broadcaster''s Award for her live coverage of the 1992 uprising. She was a regular on The Real Don Steele show on K-Earth 101. Maggie returned to music as KPFK''s music director, hosted Global Village from 2003–2009, and now serves as the station''s interim General Manager, Music Director, and Promotions Director. Profiles is her latest project—an in-depth look at the artists who shaped a uniquely creative era.', NULL, true, 0),
      (v_show_id, 'Andrea Love', 'Andrea Love is a rock turntablist and media producer based in Los Angeles. She got her start at WWBN in Flint, Michigan, then hosted "Real Rock Radio" on KPFK. Andrea trained at the Beat Junkie Institute of Sound and now mixes, scratches, and loops at venues like The Whisky A Go Go and The Viper Room—she''s even opened for Robby Krieger of The Doors. As producer of Profiles, she''s helped bring interviews with Serj Tankian, Stanley Clarke, and Jackson Browne to air.', 'https://mmo.aiircdn.com/237/69728f983a912.jpg', false, 1);
  END IF;

  -- QR Code (qr-code)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'qr-code' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Q Ward', 'Q Ward is a community organizer, educator, and public speaker known for fostering honest conversations around race, identity, and equity. With a calm, thoughtful presence, Q creates space for people to share their stories and connect across divides.

 @iamqward', 'https://cdn.simpleicons.org/instagram/666666', true, 0),
      (v_show_id, 'Ramses Ja', 'Ramses Ja is a DJ, activist, and media strategist who believes in the power of storytelling to shift culture. His work centers on media literacy, racial justice, and uplifting voices that are often left out of the mainstream narrative.

 @ramsesja', 'https://cdn.simpleicons.org/instagram/666666', false, 1);
  END IF;

  -- Ralph Nader Radio Hour (ralph-nader-radio-hour)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'ralph-nader-radio-hour' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Ralph Nader', 'Ralph Nader is a lifelong advocate for justice whose work has saved lives and transformed laws. From the factory floor to the halls of Congress, he''s empowered everyday people to challenge corporate abuse and defend their communities. Ralph brings seventy years of unyielding citizen action and inspiration to every conversation.', NULL, true, 0),
      (v_show_id, 'Steve Skrovan', 'With roots in Los Angeles and a sharp eye honed as an Emmy-winning comedy writer, Steve Skrovan brings clarity, heart, and humor to tough topics. He has a deep connection to the show''s mission—having chronicled Ralph Nader''s life in "An Unreasonable Man"—and relishes making complex issues personal and real.', NULL, false, 1);
  END IF;

  -- Revolucion Arcoiris (revolucion-arcoiris)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'revolucion-arcoiris' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Marylin Cavanaugh', 'Program Director, Host & Producer of Revolución Arcoíris. Marylin is a licensed educator with a Ph.D. in Education and a Master''s in Educational Psychology, with professional experience spanning teaching, special education, and school administration. Beyond the classroom, she is an advocate for LGBTQ+ rights, migrant communities, and social justice — bringing those perspectives to the airwaves every week on KPFK.', NULL, true, 0);
  END IF;

  -- Rhapsody in Black (rhapsody-in-black)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'rhapsody-in-black' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Jim Dawson', 'Jim Dawson grew up in West Virginia in the 1950s listening to R&B and rock ''n'' roll, and never stopped. Since moving to Los Angeles in 1977, he''s interviewed dozens of Black recording artists and their families, written liner notes for at least 100 blues and R&B albums, and authored books including "What Was the First Rock ''n'' Roll Record?" He''s managed and produced artists like saxophonist Big Jay McNeely, blues pianist Willie Egan, and singers Richard Berry and Thurston Harris.', NULL, true, 0);
  END IF;

  -- Rising Up with Sonali (sonali-kolhatkar)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'sonali-kolhatkar' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Sonali Kolhatkar', 'Sonali is the host, creator, and executive producer of Rising Up With Sonali. She previously created and hosted Uprising, which became the longest-running drive-time show on KPFK hosted by a woman. An award-winning journalist recognized by the Los Angeles Press Club, Sonali is also the author of Rising Up: The Power of Narrative in Pursuing Racial Justice (2023) and Talking About Abolition: A Police-Free World is Possible (2025).
She serves as Senior Editor at YES! Magazine, Senior Correspondent for the Independent Media Institute''s Economy for All project, and is a longtime Pacifica broadcaster.
Acknowledgements: With thanks to Anna Buss (Senior Producer & Technical Director) and James Ingalls (Technical Support).', NULL, true, 0);
  END IF;

  -- The Signal (the-signal)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'the-signal' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Armando "Dino" Gudiño', 'Journalist, policy advocate, and nonprofit leader with 30+ years in public policy, legislation, and community organizing. Dino has worked across 30+ countries on issues from human rights to international relations. On The Signal, he brings a global lens, sharp reporting, and a deep commitment to justice.', NULL, true, 0);
  END IF;

  -- Sojourner Truth (sojourner-truth)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'sojourner-truth' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Margaret Prescod', 'Journalist, organizer, and international activist, Margaret is the founder of the Black Coalition Fighting Back Serial Murders. She brings fearless, intersectional analysis to every broadcast, amplifying frontline voices worldwide.', NULL, true, 0),
      (v_show_id, 'Nana Gyamfi', 'Human rights attorney, professor, and Executive Director of Black Alliance for Just Immigration. Nana brings sharp legal insight and unwavering commitment to community power and global justice.', NULL, false, 1);
  END IF;

  -- This Way Out (this-way-out)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'this-way-out' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Brian DeShazor', 'Host of This Way Out, Brian also serves as CEO of Overnight Productions, the nonprofit behind the program. A longtime advocate for community media and former director of the Pacifica Radio Archives, he leads the team ensuring queer stories are heard and preserved worldwide.', NULL, true, 0),
      (v_show_id, 'Greg Gordon', 'This Way Out co-founder, coordinating producer, and NewsWrap writer. Greg is a pioneer in LGBTQ broadcast radio, with roots tracing back to the first broadcasts of IMRU on KPFK in 1974. He volunteered with the gay media collective and IMRU until 1984. He covered the Marches on Washington for Gay and Lesbian Rights, along with Lucia Chappelle, live for Pacifica Radio in 1979 and 1987, and he famously interviewed Harvey Milk in 1979, shortly before Milk''s assassination. He holds a bachelor''s degree in Radio–Television Production from UCLA.', NULL, false, 1),
      (v_show_id, 'Lucia Chappelle', 'Associate Producer and co-founder, Lucia has helped shape This Way Out''s voice since 1988. A former KPFK public affairs director and lifelong activist, she continues to guide the show''s editorial direction and mentor new generations of queer media makers.', NULL, false, 2);
  END IF;

  -- Way Out West (way-out-west)
  SELECT id INTO v_show_id FROM cms_shows WHERE station_id = kpfk_id AND slug = 'way-out-west' AND deleted_at IS NULL;
  IF v_show_id IS NOT NULL THEN
    -- Delete existing hosts to avoid duplicates on re-run
    DELETE FROM cms_show_hosts WHERE show_id = v_show_id;
    INSERT INTO cms_show_hosts (show_id, name, bio, photo_path, is_primary, sort_order)
    VALUES
      (v_show_id, 'Jerry Ough', 'Jerry Ough is the longest-running jazz radio journalist in Los Angeles, with over forty years behind the mic amplifying real artists and their stories. From his early days at KJAZ in the Bay Area to key reporting roles at KLON, KPFK, and beyond, Jerry brings deep roots and hard-won knowledge of California''s musical landscape. His approach is always people-first—connecting listeners to the communities, histories, and fresh sounds that keep jazz, blues, and boundary-pushing music alive.', NULL, true, 0);
  END IF;

END $$;
