-- Remove is_primary from cms_show_hosts: not every show has a primary host.
-- Display order is determined by sort_order instead.
ALTER TABLE cms_show_hosts DROP COLUMN IF EXISTS is_primary;

-- Remove per-show donation URL override: all shows use the station donate link.
ALTER TABLE cms_shows DROP COLUMN IF EXISTS donation_cta_url;
