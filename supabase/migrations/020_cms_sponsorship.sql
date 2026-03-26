-- Sponsorship placements, creatives, and impression tracking

-- Placement zones (where sponsored content can appear)
create table cms_sponsorship_placements (
  id uuid primary key default gen_random_uuid(),
  station_id uuid not null references cms_stations(id),
  zone text not null,
  name text not null,
  max_items integer not null default 3,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index idx_cms_sponsorship_placements_zone
  on cms_sponsorship_placements(station_id, zone);

create trigger trg_cms_sponsorship_placements_updated_at
  before update on cms_sponsorship_placements
  for each row execute function update_updated_at();

-- Seed default placement zones
do $$
declare
  sid uuid;
begin
  select id into sid from cms_stations where slug = 'kpfk';
  insert into cms_sponsorship_placements (station_id, zone, name, max_items) values
    (sid, 'homepage_hero', 'Homepage Hero Carousel', 5),
    (sid, 'homepage_sidebar', 'Homepage Sidebar', 3),
    (sid, 'show_page_banner', 'Show Page Banner', 3),
    (sid, 'show_page_sidebar', 'Show Page Sidebar', 3),
    (sid, 'archive_banner', 'Archive Page Banner', 2),
    (sid, 'blog_interstitial', 'Blog Interstitial', 2),
    (sid, 'sitewide_banner', 'Sitewide Banner', 1)
  on conflict do nothing;
end $$;

-- Creative assets assigned to placement zones
create table cms_sponsorship_creatives (
  id uuid primary key default gen_random_uuid(),
  station_id uuid not null references cms_stations(id),
  placement_id uuid not null references cms_sponsorship_placements(id),
  title text not null,
  creative_type text not null default 'image' check (creative_type in ('image', 'html')),
  image_path text,
  html_content text,
  click_url text,
  alt_text text,
  weight integer not null default 1,
  is_pinned boolean not null default false,
  pin_position integer,
  starts_at timestamptz,
  ends_at timestamptz,
  is_active boolean not null default true,
  created_by uuid references cms_profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index idx_cms_sponsorship_creatives_placement
  on cms_sponsorship_creatives(placement_id, is_active)
  where deleted_at is null;

create index idx_cms_sponsorship_creatives_schedule
  on cms_sponsorship_creatives(station_id, starts_at, ends_at)
  where deleted_at is null;

create trigger trg_cms_sponsorship_creatives_updated_at
  before update on cms_sponsorship_creatives
  for each row execute function update_updated_at();

-- Impression/click tracking (daily aggregation)
create table cms_sponsorship_impressions (
  id uuid primary key default gen_random_uuid(),
  creative_id uuid not null references cms_sponsorship_creatives(id),
  date date not null,
  impressions bigint not null default 0,
  clicks bigint not null default 0,
  unique (creative_id, date)
);

create index idx_cms_sponsorship_impressions_creative_date
  on cms_sponsorship_impressions(creative_id, date);
