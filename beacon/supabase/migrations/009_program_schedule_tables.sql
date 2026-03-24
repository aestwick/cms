-- ============================================================================
-- PHASE 009: Program Schedule Reference Tables
-- ============================================================================
-- Creates reference tables for KPFK program schedule data to enable:
--   - Normalized storage of program/host/category relationships
--   - Tracking which programs inspired donations
--   - Easy schedule updates without code changes
--   - Reporting on program-driven donations
--
-- Source: KPFK Schedule Week of Sun 12-14-25
-- ============================================================================

-- ----------------------------------------------------------------------------
-- program_categories: Content categories for programs
-- ----------------------------------------------------------------------------
create table program_categories (
    id              uuid primary key default gen_random_uuid(),
    station_id      uuid not null references stations(id),
    name            text not null,                              -- 'Music', 'News', 'Español'
    slug            text not null,                              -- 'music', 'news', 'espanol'
    sort_order      integer not null default 0,
    is_active       boolean not null default true,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz,

    unique (station_id, slug)
);

-- ----------------------------------------------------------------------------
-- program_hosts: Host directory
-- ----------------------------------------------------------------------------
create table program_hosts (
    id              uuid primary key default gen_random_uuid(),
    station_id      uuid not null references stations(id),
    name            text not null,                              -- 'Amy Goodman', 'Ian Masters'
    slug            text not null,                              -- 'amy-goodman', 'ian-masters'
    bio             text,
    photo_url       text,
    is_active       boolean not null default true,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz,

    unique (station_id, slug)
);

-- ----------------------------------------------------------------------------
-- programs: Radio programs/shows
-- ----------------------------------------------------------------------------
create table programs (
    id              uuid primary key default gen_random_uuid(),
    station_id      uuid not null references stations(id),
    category_id     uuid references program_categories(id),
    name            text not null,                              -- 'Democracy Now!'
    slug            text not null,                              -- 'democracy-now'
    description     text,
    notes           text,                                       -- 'Host varies by day', 'Syndicated'
    website_url     text,
    is_active       boolean not null default true,
    sort_order      integer not null default 0,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz,

    unique (station_id, slug)
);

-- ----------------------------------------------------------------------------
-- program_host_assignments: Many-to-many between programs and hosts
-- ----------------------------------------------------------------------------
create table program_host_assignments (
    id              uuid primary key default gen_random_uuid(),
    program_id      uuid not null references programs(id) on delete cascade,
    host_id         uuid not null references program_hosts(id) on delete cascade,
    is_primary      boolean not null default true,              -- primary vs co-host/guest
    created_at      timestamptz not null default now(),

    unique (program_id, host_id)
);

-- ----------------------------------------------------------------------------
-- donation_inspirations: Track which programs inspired donations
-- ----------------------------------------------------------------------------
-- Normalized junction table for donation -> program attribution.
-- Supplements the denormalized inspiration array in donation_snapshot.
-- ----------------------------------------------------------------------------
create table donation_inspirations (
    id              uuid primary key default gen_random_uuid(),
    donation_id     uuid not null references donations(id) on delete cascade,

    -- Either a program reference OR free-text (for hosts/categories selected directly)
    program_id      uuid references programs(id) on delete set null,
    host_id         uuid references program_hosts(id) on delete set null,
    category_id     uuid references program_categories(id) on delete set null,

    -- Free-text fallback for values not in reference tables
    raw_value       text not null,                              -- original selected value

    created_at      timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- Indexes for performance
-- ----------------------------------------------------------------------------
create index idx_programs_station on programs(station_id) where deleted_at is null;
create index idx_programs_category on programs(category_id) where deleted_at is null;
create index idx_program_hosts_station on program_hosts(station_id) where deleted_at is null;
create index idx_program_categories_station on program_categories(station_id) where deleted_at is null;
create index idx_program_host_assignments_program on program_host_assignments(program_id);
create index idx_program_host_assignments_host on program_host_assignments(host_id);
create index idx_donation_inspirations_donation on donation_inspirations(donation_id);
create index idx_donation_inspirations_program on donation_inspirations(program_id) where program_id is not null;
create index idx_donation_inspirations_host on donation_inspirations(host_id) where host_id is not null;

-- ============================================================================
-- SEED DATA: KPFK Programs, Hosts, and Categories
-- Source: KPFK Schedule Week of Sun 12-14-25
-- ============================================================================

-- Get or create KPFK station
do $$
declare
    v_station_id uuid;
begin
    -- Get KPFK station ID (assumes it exists from prior migrations)
    select id into v_station_id from stations where code = 'kpfk' limit 1;

    -- Create if doesn't exist
    if v_station_id is null then
        insert into stations (code, call_sign, name, timezone)
        values ('kpfk', 'KPFK', 'KPFK 90.7 FM Los Angeles', 'America/Los_Angeles')
        returning id into v_station_id;
    end if;

    -- Insert categories
    insert into program_categories (station_id, name, slug, sort_order) values
        (v_station_id, 'Arts & Entertainment', 'arts-entertainment', 1),
        (v_station_id, 'Español', 'espanol', 2),
        (v_station_id, 'Health & Spirituality', 'health-spirituality', 3),
        (v_station_id, 'Music', 'music', 4),
        (v_station_id, 'News', 'news', 5),
        (v_station_id, 'Public Affairs - Local', 'public-affairs-local', 6),
        (v_station_id, 'Public Affairs - National + Syndicated', 'public-affairs-national', 7),
        (v_station_id, 'Special Program', 'special-program', 8)
    on conflict (station_id, slug) do nothing;

    -- Insert hosts
    insert into program_hosts (station_id, name, slug) values
        (v_station_id, 'Alicia Ivonne Estrada', 'alicia-ivonne-estrada'),
        (v_station_id, 'Allen Larman', 'allen-larman'),
        (v_station_id, 'Amy Goodman', 'amy-goodman'),
        (v_station_id, 'Andrew Tonkovich', 'andrew-tonkovich'),
        (v_station_id, 'Angela Birdsong', 'angela-birdsong'),
        (v_station_id, 'Armando Gudino', 'armando-gudino'),
        (v_station_id, 'Arnella Barbara', 'arnella-barbara'),
        (v_station_id, 'Aura Gonzalez', 'aura-gonzalez'),
        (v_station_id, 'Ben Vera', 'ben-vera'),
        (v_station_id, 'Brad Friedman', 'brad-friedman'),
        (v_station_id, 'Brenda Martinez', 'brenda-martinez'),
        (v_station_id, 'Buzz', 'buzz'),
        (v_station_id, 'Caroline Casey', 'caroline-casey'),
        (v_station_id, 'Cary Harrison', 'cary-harrison'),
        (v_station_id, 'Cat Brooks', 'cat-brooks'),
        (v_station_id, 'Chris Hedges', 'chris-hedges'),
        (v_station_id, 'Chuck Foster', 'chuck-foster'),
        (v_station_id, 'D. Walker', 'd-walker'),
        (v_station_id, 'Dani Mamath', 'dani-mamath'),
        (v_station_id, 'David Barsamian', 'david-barsamian'),
        (v_station_id, 'DJ d.painter', 'dj-d-painter'),
        (v_station_id, 'DJ Nnamdi', 'dj-nnamdi'),
        (v_station_id, 'Django', 'django'),
        (v_station_id, 'Dr. Gerald Horne', 'dr-gerald-horne'),
        (v_station_id, 'Emiliano Lemus', 'emiliano-lemus'),
        (v_station_id, 'Enrique Sanchez', 'enrique-sanchez'),
        (v_station_id, 'Ernesto Ayala', 'ernesto-ayala'),
        (v_station_id, 'Estee Chandler', 'estee-chandler'),
        (v_station_id, 'F Martinez', 'f-martinez'),
        (v_station_id, 'Freya Rojo', 'freya-rojo'),
        (v_station_id, 'Gary Baca', 'gary-baca'),
        (v_station_id, 'Geri Silva', 'geri-silva'),
        (v_station_id, 'Gil Fears', 'gil-fears'),
        (v_station_id, 'Gregorio Luke', 'gregorio-luke'),
        (v_station_id, 'Hector Resendez', 'hector-resendez'),
        (v_station_id, 'Ian Masters', 'ian-masters'),
        (v_station_id, 'Jack Eidt', 'jack-eidt'),
        (v_station_id, 'jaz sawyer', 'jaz-sawyer'),
        (v_station_id, 'Jerry Ough', 'jerry-ough'),
        (v_station_id, 'Jesse Bliss', 'jesse-bliss'),
        (v_station_id, 'Jessica Aldridge', 'jessica-aldridge'),
        (v_station_id, 'Jillian Rise', 'jillian-rise'),
        (v_station_id, 'Jim Dawson', 'jim-dawson'),
        (v_station_id, 'Joe Ayala', 'joe-ayala'),
        (v_station_id, 'John Santana', 'john-santana'),
        (v_station_id, 'John Schneider', 'john-schneider'),
        (v_station_id, 'Jon Wiener', 'jon-wiener'),
        (v_station_id, 'Jose Benavides', 'jose-benavides'),
        (v_station_id, 'Julio Martinez', 'julio-martinez'),
        (v_station_id, 'Kat Griffin', 'kat-griffin'),
        (v_station_id, 'Kathy Diaz', 'kathy-diaz'),
        (v_station_id, 'Lalo Alcaraz', 'lalo-alcaraz'),
        (v_station_id, 'Larry Smith', 'larry-smith'),
        (v_station_id, 'Laura Flanders', 'laura-flanders'),
        (v_station_id, 'Lily Lopez', 'lily-lopez'),
        (v_station_id, 'Lisa Garr', 'lisa-garr'),
        (v_station_id, 'Luis Zambrano', 'luis-zambrano'),
        (v_station_id, 'Margaret Prescod', 'margaret-prescod'),
        (v_station_id, 'Maria Armoudian', 'maria-armoudian'),
        (v_station_id, 'Mark Coffield', 'mark-coffield'),
        (v_station_id, 'Mark Torres', 'mark-torres'),
        (v_station_id, 'Mark Vaughn', 'mark-vaughn'),
        (v_station_id, 'Matt Perez', 'matt-perez'),
        (v_station_id, 'Matt Sedillo', 'matt-sedillo'),
        (v_station_id, 'Michelle Coltrane', 'michelle-coltrane'),
        (v_station_id, 'Miguel Paredes', 'miguel-paredes'),
        (v_station_id, 'Nagwa Ibrahim', 'nagwa-ibrahim'),
        (v_station_id, 'Nana Gyamfi', 'nana-gyamfi'),
        (v_station_id, 'Nick Richert', 'nick-richert'),
        (v_station_id, 'Norma Martinez Velazquez', 'norma-martinez-velazquez'),
        (v_station_id, 'Oscar Ulloa', 'oscar-ulloa'),
        (v_station_id, 'Phil Proctor', 'phil-proctor'),
        (v_station_id, 'Polina Vasiliev', 'polina-vasiliev'),
        (v_station_id, 'Q Ward', 'q-ward'),
        (v_station_id, 'Ralph Nader', 'ralph-nader'),
        (v_station_id, 'Ramses Ja', 'ramses-ja'),
        (v_station_id, 'Renée Camila', 'renee-camila'),
        (v_station_id, 'Rodrigo Argueta', 'rodrigo-argueta'),
        (v_station_id, 'Rosario Vigil', 'rosario-vigil'),
        (v_station_id, 'Roy Tuckman', 'roy-tuckman'),
        (v_station_id, 'Ruben Tapia', 'ruben-tapia'),
        (v_station_id, 'Sergio Mielniczenko', 'sergio-mielniczenko'),
        (v_station_id, 'Sergio Serdio', 'sergio-serdio'),
        (v_station_id, 'Sonia Barrett', 'sonia-barrett'),
        (v_station_id, 'Sonali Kolhatkar', 'sonali-kolhatkar'),
        (v_station_id, 'Suzi Weissman', 'suzi-weissman'),
        (v_station_id, 'Sylvester Rivers', 'sylvester-rivers'),
        (v_station_id, 'Tanya Torres', 'tanya-torres'),
        (v_station_id, 'Ted Bonnitt', 'ted-bonnitt'),
        (v_station_id, 'Teddy Angelo Robinson', 'teddy-angelo-robinson'),
        (v_station_id, 'Tom Lutz', 'tom-lutz'),
        (v_station_id, 'Val Contreras', 'val-contreras'),
        (v_station_id, 'Vanessa Bustamante', 'vanessa-bustamante')
    on conflict (station_id, slug) do nothing;

    -- Insert programs
    insert into programs (station_id, name, slug) values
        (v_station_id, 'Afro-Dicia', 'afro-dicia'),
        (v_station_id, 'Alan Watts', 'alan-watts'),
        (v_station_id, 'All Of The Above', 'all-of-the-above'),
        (v_station_id, 'Alternative Radio', 'alternative-radio'),
        (v_station_id, 'American Indian Airwaves', 'american-indian-airwaves'),
        (v_station_id, 'Arts In Review', 'arts-in-review'),
        (v_station_id, 'Awakenings', 'awakenings'),
        (v_station_id, 'Aware Show, The', 'aware-show'),
        (v_station_id, 'Background Briefing', 'background-briefing'),
        (v_station_id, 'Beneath The Surface', 'beneath-the-surface'),
        (v_station_id, 'Bibliocracy', 'bibliocracy'),
        (v_station_id, 'Bike Talk', 'bike-talk'),
        (v_station_id, 'Brad Friedman''s BradCast', 'bradcast'),
        (v_station_id, 'Breakbeats And Rhymes', 'breakbeats-and-rhymes'),
        (v_station_id, 'Canto Sin Fronteras', 'canto-sin-fronteras'),
        (v_station_id, 'Canto Tropical', 'canto-tropical'),
        (v_station_id, 'Car Show, The', 'car-show'),
        (v_station_id, 'Cary Harrison Files, The', 'cary-harrison-files'),
        (v_station_id, 'Centroamerica Sin Censura', 'centroamerica-sin-censura'),
        (v_station_id, 'Chris Hedges Report', 'chris-hedges-report'),
        (v_station_id, 'CinemaScore', 'cinemascore'),
        (v_station_id, 'Contacto Ancestral', 'contacto-ancestral'),
        (v_station_id, 'Contragolpe', 'contragolpe'),
        (v_station_id, 'Conversation Piece', 'conversation-piece'),
        (v_station_id, 'Counterspin', 'counterspin'),
        (v_station_id, 'Cut to the Chase', 'cut-to-the-chase'),
        (v_station_id, 'Dark Star, Dead & Music', 'dark-star-dead-music'),
        (v_station_id, 'Democracy Now!', 'democracy-now'),
        (v_station_id, 'Dialogos de Media Noche', 'dialogos-de-media-noche'),
        (v_station_id, 'Eco-Justice Radio', 'eco-justice-radio'),
        (v_station_id, 'Encuentros con Gregorio Luke', 'encuentros-con-gregorio-luke'),
        (v_station_id, 'Enfoque Latino', 'enfoque-latino'),
        (v_station_id, 'Expansion Zone', 'expansion-zone'),
        (v_station_id, 'Folk Scene', 'folk-scene'),
        (v_station_id, 'Freedom Now', 'freedom-now'),
        (v_station_id, 'Global Village', 'global-village'),
        (v_station_id, 'Gospel Classics', 'gospel-classics'),
        (v_station_id, 'Hablando de Sudamerica', 'hablando-de-sudamerica'),
        (v_station_id, 'In The Cut Radio', 'in-the-cut-radio'),
        (v_station_id, 'Informativo Pacifica', 'informativo-pacifica'),
        (v_station_id, 'Insurgencia Feminina', 'insurgencia-feminina'),
        (v_station_id, 'Jazz Sessions', 'jazz-sessions'),
        (v_station_id, 'La Raza Radio', 'la-raza-radio'),
        (v_station_id, 'LA Review Of Books', 'la-review-of-books'),
        (v_station_id, 'LA Theater Works', 'la-theater-works'),
        (v_station_id, 'Laura Flanders and Friends', 'laura-flanders-and-friends'),
        (v_station_id, 'Law and Disorder', 'law-and-disorder'),
        (v_station_id, 'Living In The USA', 'living-in-the-usa'),
        (v_station_id, 'Middle East In Focus', 'middle-east-in-focus'),
        (v_station_id, 'Midnight Snack', 'midnight-snack'),
        (v_station_id, 'Musiqueros y Juventud', 'musiqueros-y-juventud'),
        (v_station_id, 'Nightscapes', 'nightscapes'),
        (v_station_id, 'Nuestra Voz', 'nuestra-voz'),
        (v_station_id, 'Pacifica Evening News', 'pacifica-evening-news'),
        (v_station_id, 'Pacifica Performance Showcase', 'pacifica-performance-showcase'),
        (v_station_id, 'Perspectiva de Las Americas', 'perspectiva-de-las-americas'),
        (v_station_id, 'Phil & Ted''s Sexy Boomer Show', 'phil-teds-sexy-boomer-show'),
        (v_station_id, 'Planting Medicine', 'planting-medicine'),
        (v_station_id, 'Pocho Hour Of Power', 'pocho-hour-of-power'),
        (v_station_id, '¿Que Pasa En Los Angeles?', 'que-pasa-en-los-angeles'),
        (v_station_id, 'QR Code', 'qr-code'),
        (v_station_id, 'Radio Bilingue', 'radio-bilingue'),
        (v_station_id, 'Radio Intifada (SWANA Region Radio)', 'radio-intifada'),
        (v_station_id, 'Radio Maiz / El Vuelo del Águila y el Condor / Radio Sudamerica', 'radio-maiz'),
        (v_station_id, 'Ralph Nader Hour', 'ralph-nader-hour'),
        (v_station_id, 'Reggae Central', 'reggae-central'),
        (v_station_id, 'Revolucion Arcoiris', 'revolucion-arcoiris'),
        (v_station_id, 'Rhapsody In Black', 'rhapsody-in-black'),
        (v_station_id, 'Rising Up', 'rising-up'),
        (v_station_id, 'Roots Music and Beyond', 'roots-music-and-beyond'),
        (v_station_id, 'Scholars Circle', 'scholars-circle'),
        (v_station_id, 'Senderos de Oaxaca / Asi Es Nuestra Cultura', 'senderos-de-oaxaca'),
        (v_station_id, 'Sojourner Truth', 'sojourner-truth'),
        (v_station_id, 'Something''s Happening', 'somethings-happening'),
        (v_station_id, 'Soul Rebel Radio', 'soul-rebel-radio'),
        (v_station_id, 'Soundwaves', 'soundwaves'),
        (v_station_id, 'Special Programming', 'special-programming'),
        (v_station_id, 'Stairway To Heaven', 'stairway-to-heaven'),
        (v_station_id, 'Suplemento Comunitario', 'suplemento-comunitario'),
        (v_station_id, 'The Signal', 'the-signal'),
        (v_station_id, 'The Visionary Activist', 'the-visionary-activist'),
        (v_station_id, 'Think Outside The Cage', 'think-outside-the-cage'),
        (v_station_id, 'Thom Hartmann Program', 'thom-hartmann-program'),
        (v_station_id, 'Travel Tips For Aztlan', 'travel-tips-for-aztlan'),
        (v_station_id, 'Voces de Libertad', 'voces-de-libertad'),
        (v_station_id, 'Way Out West', 'way-out-west'),
        (v_station_id, 'Working Voices', 'working-voices'),
        (v_station_id, 'World Massive', 'world-massive')
    on conflict (station_id, slug) do nothing;

end $$;

-- ============================================================================
-- End of Phase 009
-- ============================================================================
