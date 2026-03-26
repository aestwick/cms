-- Migration 009: Add per-show donation CTA override fields
-- Allows shows to customize the sidebar donation call-to-action

ALTER TABLE cms_shows
  ADD COLUMN IF NOT EXISTS donation_cta_heading text,
  ADD COLUMN IF NOT EXISTS donation_cta_body text,
  ADD COLUMN IF NOT EXISTS donation_cta_url text;

COMMENT ON COLUMN cms_shows.donation_cta_heading IS 'Override heading for sidebar donate CTA. Falls back to "Support {title}"';
COMMENT ON COLUMN cms_shows.donation_cta_body IS 'Override body text for sidebar donate CTA. Falls back to generic copy';
COMMENT ON COLUMN cms_shows.donation_cta_url IS 'Override donate URL. Falls back to https://donate.kpfk.org';
