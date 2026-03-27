-- Migration 022: Add category column to cms_shows and populate from Confessor
-- Categories and colors sourced from Confessor's show directory.
-- Category is set via program_slug (set in migration 021).

ALTER TABLE cms_shows ADD COLUMN IF NOT EXISTS category text;

ALTER TABLE cms_shows ADD CONSTRAINT cms_shows_category_check
  CHECK (category IS NULL OR category IN (
    'Arts & Entertainment',
    'Español',
    'Health & Spirituality',
    'Music',
    'News',
    'Public Affairs - Local',
    'Public Affairs - National+Syndicated',
    'Special Program'
  ));

CREATE INDEX IF NOT EXISTS idx_cms_shows_category ON cms_shows (station_id, category);

-- Populate categories using program_slug (Confessor altid) as the key.
-- Data sourced from Confessor show directory export.
DO $$
DECLARE
  kpfk_station_id uuid;
  updated_count integer;
BEGIN
  SELECT id INTO kpfk_station_id FROM cms_stations WHERE slug = 'kpfk';
  IF kpfk_station_id IS NULL THEN
    RAISE EXCEPTION 'KPFK station not found. Run foundation seed first.';
  END IF;

  -- Arts & Entertainment (cat 12, #96A8FF)
  UPDATE cms_shows SET category = 'Arts & Entertainment'
    WHERE program_slug IN (
      'artsinreview',        -- Arts In Review
      'bibliocracy',         -- Bibliocracy
      'larb',                -- LA Review Of Books
      'latw',                -- LA Theater Works
      'pperf',               -- Pacifica Performance Showcase
      'philandtedrsqsexyboomershow', -- Phil & Ted's Sexy Boomer Show
      'rockprofile'          -- Profiles w/ Maggie LePique
    ) AND station_id = kpfk_station_id;

  -- Español (cat 10, #FFE2BD)
  UPDATE cms_shows SET category = 'Español'
    WHERE program_slug IN (
      'casc',                -- Centroamerica Sin Censura
      'contactoancestral',   -- Contacto Ancestral
      'golpe',               -- Contragolpe
      'medianoche',          -- Dialogos de Media Noche
      'elnotici',            -- El Noticiero
      'luke',                -- Encuentros con Gregorio Luke
      'enfoque',             -- Enfoque Latino
      'hablanddesudamer',    -- Hablando de Sudamerica
      'infopac',             -- Informativo Pacifica
      'musiqueyjuventu',     -- MUSIQUEROS Y JUVENTUD
      'nuestravoz',          -- Nuestra Voz
      'perspectiva',         -- Perspectiva de Las Americas
      'iquestpasaenlosangele', -- ¿Que Pasa En Los Angeles?
      'radiobilingu',        -- Radio Bilingue
      'radioinsurgencia',    -- Insurgencia Feminina
      'ladiverylainclu',     -- Revolucion Arcoiris
      'sendedeoaxacoasiesnuestcultu', -- Senderos de Oaxaca
      'suplemento',          -- Suplemento Comunitario
      'vocesdelibertad'      -- Voces de Libertad
    ) AND station_id = kpfk_station_id;

  -- Health & Spirituality (cat 11, #FFEB87)
  UPDATE cms_shows SET category = 'Health & Spirituality'
    WHERE program_slug IN (
      'alanwatts',           -- Alan Watts
      'aware',               -- Aware Show, The
      'ivmon'                -- Expansion Zone
    ) AND station_id = kpfk_station_id;

  -- Music (cat 4, #FFD9E4)
  UPDATE cms_shows SET category = 'Music'
    WHERE program_slug IN (
      'afrodicia',           -- Afro-Dicia
      'allabove',            -- All Of The Above
      'awakenings',          -- Awakenings
      'breakbeats',          -- Breakbeats And Rhymes
      'cantossin',           -- Canto Sin Fronteras
      'cantotropical',       -- Canto Tropical
      'cinemascore',         -- CinemaScore
      'darkstardeadmusic',   -- Dark Star, Dead & Music
      'deepend',             -- Midnight Snack
      'folkscene',           -- Folk Scene
      'gospelclassics',      -- Gospel Classics
      'gv_derek',            -- Global Village - Mon
      'gv_john',             -- Global Village - Thurs
      'gv_sergio',           -- Global Village - Fri
      'gv_tue',              -- Global Village - Tuesday
      'gv_yatrika',          -- Global Village - Weds
      'lstation',            -- Nightscapes
      'musicmix',            -- Stairway To Heaven
      'potira',              -- World Massive
      'realrockriffsamprhyth', -- In The Cut Radio
      'reggaecent',          -- Reggae Central
      'rhapsody',            -- Rhapsody In Black
      'rise',                -- Jazz Sessions
      'aliveandpicking',     -- Roots Music and Beyond
      'soundwaves',          -- Soundwaves
      'traveltips',          -- Travel Tips For Aztlan
      'wayoutwest'           -- Way Out West
    ) AND station_id = kpfk_station_id;

  -- News (cat 6, #E8FFEA)
  -- Pacifica Evening News (kpfknews) is Confessor-only, no CMS show yet

  -- Public Affairs - Local (cat 3, #E5D9FF)
  UPDATE cms_shows SET category = 'Public Affairs - Local'
    WHERE program_slug IN (
      'americanindian',      -- American Indian Airwaves
      'nativenationsreport', -- Be a Better Relative
      'bts_friday',          -- Beneath The Surface
      'biketalka',           -- Bike Talk
      'friedman',            -- Brad Friedman's BradCast
      'solartopia',          -- California Solartopia
      'calstalacommunnewshour', -- CalState LA Community News Hour
      'carshow',             -- Car Show, The
      'conversatpiece',      -- Conversation Piece
      'mornimixcutchasewsylveriver', -- Cut to the Chase
      'ecojustiradio',       -- Eco-Justice Radio
      'femmag',              -- Feminist Magazine
      'freedomnow',          -- Freedom Now
      'imru',                -- IMRU - LGBT Issues
      'johnwiener',          -- Living In The USA
      'morningmradiojaguar', -- La Raza Radio
      'lawyersguild',        -- Lawyers Guild, The
      'marmoudian',          -- Scholars Circle
      'pocho',               -- Pocho Hour Of Power
      'signal',              -- The Signal
      'somethingshappening', -- Something's Happening A hour 1
      'soulrebel',           -- Soul Rebel Radio
      'prisonrights',        -- Think Outside The Cage
      'workingvoices'        -- Working Voices
    ) AND station_id = kpfk_station_id;

  -- Public Affairs - National+Syndicated (cat 9, #CABFE0)
  UPDATE cms_shows SET category = 'Public Affairs - National+Syndicated'
    WHERE program_slug IN (
      'alterradioar',        -- Alternative Radio
      'covidraceanddemocr',  -- Capitalism, Race and Democracy
      'caryharrisfiles',     -- Cary Harrison Files
      'onconta',             -- Chris Hedges Report
      'codepinradio',        -- CodePINK Radio
      'dn',                  -- Democracy Now!
      'econ',                -- Economic Update w/Richard Wolff
      'hartmann',            -- Thom Hartmann Program
      'meif',                -- Middle East In Focus
      'nader',               -- Ralph Nader Hour
      'qrcode',              -- QR Code
      'rintifada',           -- Radio Intifada (SWANA Region Radio)
      'risingup',            -- Rising Up
      'sojourner',           -- Sojourner Truth
      'thiswayout'           -- This Way Out
    ) AND station_id = kpfk_station_id;

  -- Special Program (cat 14, #FF757A)
  UPDATE cms_shows SET category = 'Special Program'
    WHERE program_slug IN (
      'special'              -- Special Programming
    ) AND station_id = kpfk_station_id;

  -- Report
  SELECT count(*) INTO updated_count
    FROM cms_shows
    WHERE station_id = kpfk_station_id
      AND category IS NOT NULL;

  RAISE NOTICE 'Set category on % CMS shows', updated_count;
END $$;
