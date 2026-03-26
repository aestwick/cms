-- Newsletter subscribers
-- Supports general + show-specific subscriptions

create table cms_newsletter_subscribers (
  id uuid primary key default gen_random_uuid(),
  station_id uuid not null references cms_stations(id),
  email text not null,
  confirmed_at timestamptz,
  confirmation_token uuid default gen_random_uuid(),
  unsubscribed_at timestamptz,
  source text not null default 'website',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create unique index idx_cms_newsletter_subscribers_email
  on cms_newsletter_subscribers(station_id, email)
  where deleted_at is null and unsubscribed_at is null;

create trigger trg_cms_newsletter_subscribers_updated_at
  before update on cms_newsletter_subscribers
  for each row execute function update_updated_at();

-- Show-specific subscriptions (optional, a subscriber can follow specific shows)
create table cms_newsletter_subscriptions (
  id uuid primary key default gen_random_uuid(),
  subscriber_id uuid not null references cms_newsletter_subscribers(id) on delete cascade,
  show_id uuid not null references cms_shows(id) on delete cascade,
  created_at timestamptz not null default now()
);

create unique index idx_cms_newsletter_subscriptions_unique
  on cms_newsletter_subscriptions(subscriber_id, show_id);
