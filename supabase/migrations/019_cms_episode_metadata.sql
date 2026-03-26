-- Episode metadata — CMS-owned rich data joined to Confessor audio
create table cms_episode_metadata (
  id uuid primary key default gen_random_uuid(),
  station_id uuid not null references cms_stations(id),
  show_id uuid not null references cms_shows(id),
  program_slug text not null,
  air_date date not null,
  title text,
  description text,
  transcript_url text,
  segments jsonb,
  is_published boolean not null default true,
  created_by uuid references cms_profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index idx_cms_episode_metadata_slug_date
  on cms_episode_metadata(station_id, program_slug, air_date);

create index idx_cms_episode_metadata_show_date
  on cms_episode_metadata(show_id, air_date desc);

create index idx_cms_episode_metadata_station_date
  on cms_episode_metadata(station_id, air_date desc);

create trigger trg_cms_episode_metadata_updated_at
  before update on cms_episode_metadata
  for each row execute function update_updated_at();
