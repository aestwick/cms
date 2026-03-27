-- Migration 021: Map CMS shows to Confessor program slugs
-- Sets program_slug on cms_shows to match Confessor sh_altid values.
-- This enables the schedule import to link Confessor slots to CMS show pages.
--
-- 88 shows mapped. Shows only in Confessor (Background Briefing, Law and
-- Disorder, Pacifica Evening News, Planting Medicine, Visionary Activist,
-- Radio Maiz) are intentionally skipped — create them in the CMS when ready.
--
-- Something's Happening has 6 Confessor keys but 1 CMS show page.
-- Only the primary key (somethingshappening) is stored here; the other 5
-- are resolved via SLUG_ALIASES in src/lib/confessor.ts at the app layer.

DO $$
DECLARE
  kpfk_station_id uuid;
  updated_count integer;
BEGIN
  SELECT id INTO kpfk_station_id FROM cms_stations WHERE slug = 'kpfk';
  IF kpfk_station_id IS NULL THEN
    RAISE EXCEPTION 'KPFK station not found. Run foundation seed first.';
  END IF;

  -- A
  UPDATE cms_shows SET program_slug = 'afrodicia' WHERE slug = 'afrodicia1' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'alanwatts' WHERE slug = 'alan-watts2' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'allabove' WHERE slug = 'all-of-the-above' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'alterradioar' WHERE slug = 'alternative-radio' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'americanindian' WHERE slug = 'american-indian-airwaves' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'artsinreview' WHERE slug = 'arts-in-review' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'awakenings' WHERE slug = 'awakenings' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'aware' WHERE slug = 'aware-show' AND station_id = kpfk_station_id;

  -- B
  UPDATE cms_shows SET program_slug = 'nativenationsreport' WHERE slug = 'be-a-better-relative' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'bts_friday' WHERE slug = 'beneath-the-surface' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'bibliocracy' WHERE slug = 'bibliocracy' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'friedman' WHERE slug = 'bradcast-with-brad-friedman' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'breakbeats' WHERE slug = 'breakbeats-and-rhymes' AND station_id = kpfk_station_id;

  -- C
  UPDATE cms_shows SET program_slug = 'solartopia' WHERE slug = 'california-solartopia' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'cantossin' WHERE slug = 'canto-sin-fronteras' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'cantotropical' WHERE slug = 'canto-tropical' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'covidraceanddemocr' WHERE slug = 'capitalism-race-and-democracy' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'carshow' WHERE slug = 'car-show-the' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'caryharrisfiles' WHERE slug = 'the-cary-harrison-files' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'cinemascore' WHERE slug = 'cinemascore' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'codepinradio' WHERE slug = 'codepink-radio' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'contactoancestral' WHERE slug = 'contacto-ancestral' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'golpe' WHERE slug = 'contragolpe' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'conversatpiece' WHERE slug = 'conversation-piece' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'mornimixcutchasewsylveriver' WHERE slug = 'cut-to-the-chase' AND station_id = kpfk_station_id;

  -- D
  UPDATE cms_shows SET program_slug = 'darkstardeadmusic' WHERE slug = 'dark-star-dead-and-music' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'dn' WHERE slug = 'democracy-now' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'medianoche' WHERE slug = 'dialogos-de-media-noche' AND station_id = kpfk_station_id;

  -- E
  UPDATE cms_shows SET program_slug = 'ecojustiradio' WHERE slug = 'eco-justice-radio' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'gospelclassics' WHERE slug = 'edna-tatums-gospel-classics' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'luke' WHERE slug = 'encuentros' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'enfoque' WHERE slug = 'enfoque-latino-con-ruben-tapia' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'ivmon' WHERE slug = 'expansion-zone' AND station_id = kpfk_station_id;

  -- F
  UPDATE cms_shows SET program_slug = 'femmag' WHERE slug = 'feminist-magazine' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'folkscene' WHERE slug = 'folkscene' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'freedomnow' WHERE slug = 'freedom-now' AND station_id = kpfk_station_id;

  -- G
  UPDATE cms_shows SET program_slug = 'gv_derek' WHERE slug = 'global-village-mondays' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'gv_tue' WHERE slug = 'global-village-tuesdays' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'gv_yatrika' WHERE slug = 'global-village-wednesdays' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'gv_john' WHERE slug = 'global-village-thursdays-w-john-schneider' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'gv_sergio' WHERE slug = 'global-village-fridays-w-sergio-mielniczenko' AND station_id = kpfk_station_id;

  -- H
  UPDATE cms_shows SET program_slug = 'hablanddesudamer' WHERE slug = 'hablando-de-sudamerica' AND station_id = kpfk_station_id;

  -- I
  UPDATE cms_shows SET program_slug = 'imru' WHERE slug = 'imru' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'realrockriffsamprhyth' WHERE slug = 'in-the-cut-radio' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'infopac' WHERE slug = 'informativo-pacifica' AND station_id = kpfk_station_id;

  -- J
  UPDATE cms_shows SET program_slug = 'johnwiener' WHERE slug = 'jon-wiener' AND station_id = kpfk_station_id;

  -- L
  UPDATE cms_shows SET program_slug = 'latw' WHERE slug = 'l-a-theatre-works' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'morningmradiojaguar' WHERE slug = 'la-raza-radio' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'larb' WHERE slug = 'la-review-of-books' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'lawyersguild' WHERE slug = 'lawyers-guild' AND station_id = kpfk_station_id;

  -- M
  UPDATE cms_shows SET program_slug = 'meif' WHERE slug = 'middle-east-in-focus' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'deepend' WHERE slug = 'midnight-snack' AND station_id = kpfk_station_id;

  -- N
  UPDATE cms_shows SET program_slug = 'lstation' WHERE slug = 'nightscapes' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'nuestravoz' WHERE slug = 'nuestra-voz' AND station_id = kpfk_station_id;

  -- O
  UPDATE cms_shows SET program_slug = 'onconta' WHERE slug = 'on-contact' AND station_id = kpfk_station_id;

  -- P
  UPDATE cms_shows SET program_slug = 'pperf' WHERE slug = 'pacifica-performance-showcase' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'perspectiva' WHERE slug = 'perspectiva-de-las-americas' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'philandtedrsqsexyboomershow' WHERE slug = 'phil-and-teds-sexy-boomer-show' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'pocho' WHERE slug = 'pocho-hour-of-power' AND station_id = kpfk_station_id;

  -- Q
  UPDATE cms_shows SET program_slug = 'qrcode' WHERE slug = 'qr-code' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'iquestpasaenlosangele' WHERE slug = 'que-pasa-en-los-angeles' AND station_id = kpfk_station_id;

  -- R
  UPDATE cms_shows SET program_slug = 'radiobilingu' WHERE slug = 'radio-bilingue' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'radioinsurgencia' WHERE slug = 'radio-insurgencia-femenina' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'nader' WHERE slug = 'ralph-nader-radio-hour' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'reggaecent' WHERE slug = 'reggae-central' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'ladiverylainclu' WHERE slug = 'revolucion-arcoiris' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'rhapsody' WHERE slug = 'rhapsody-in-black' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'risingup' WHERE slug = 'sonali-kolhatkar' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'aliveandpicking' WHERE slug = 'roots-music-and-beyond' AND station_id = kpfk_station_id;

  -- S
  UPDATE cms_shows SET program_slug = 'marmoudian' WHERE slug = 'scholars-circle' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'sendedeoaxacoasiesnuestcultu' WHERE slug = 'senderos-de-oaxaca' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'signal' WHERE slug = 'the-signal' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'sojourner' WHERE slug = 'sojourner-truth' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'somethingshappening' WHERE slug = 'somethings-happening-a-hour-1-honoring-roy-of-hollywood' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'soulrebel' WHERE slug = 'soul-rebel-radio' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'soundwaves' WHERE slug = 'soundwaves' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'special' WHERE slug = 'special-programming' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'musicmix' WHERE slug = 'stairway-to-heaven' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'suplemento' WHERE slug = 'suplemento-comunitario' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'rintifada' WHERE slug = 'swana-region-radio' AND station_id = kpfk_station_id;

  -- T
  UPDATE cms_shows SET program_slug = 'prisonrights' WHERE slug = 'think-outside-the-cage' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'thiswayout' WHERE slug = 'this-way-out' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'hartmann' WHERE slug = 'thom-hartmann' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'traveltips' WHERE slug = 'travel-tips-for-aztlan' AND station_id = kpfk_station_id;

  -- V
  UPDATE cms_shows SET program_slug = 'vocesdelibertad' WHERE slug = 'voces-de-libertad' AND station_id = kpfk_station_id;

  -- W
  UPDATE cms_shows SET program_slug = 'wayoutwest' WHERE slug = 'way-out-west' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'potira' WHERE slug = 'dj-potira' AND station_id = kpfk_station_id;
  UPDATE cms_shows SET program_slug = 'workingvoices' WHERE slug = 'working-voices' AND station_id = kpfk_station_id;

  -- Report
  SELECT count(*) INTO updated_count
    FROM cms_shows
    WHERE station_id = kpfk_station_id
      AND program_slug IS NOT NULL;

  RAISE NOTICE 'Mapped % CMS shows to Confessor program_slug values', updated_count;
END $$;
