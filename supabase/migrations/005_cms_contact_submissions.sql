-- Migration 005: Contact Submissions
-- Append-only log of contact form submissions (no soft delete).

CREATE TABLE IF NOT EXISTS cms_contact_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id uuid NOT NULL REFERENCES cms_stations(id),
  show_id uuid REFERENCES cms_shows(id) ON DELETE SET NULL,
  sender_name text NOT NULL,
  sender_email text NOT NULL,
  subject text NOT NULL,
  message text NOT NULL,
  ip_address inet,
  turnstile_token text,
  emailed_to text[],
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Index for listing submissions by station
CREATE INDEX idx_cms_contact_submissions_station_created
  ON cms_contact_submissions(station_id, created_at DESC);

-- Index for show-scoped submission lookups
CREATE INDEX idx_cms_contact_submissions_show_id
  ON cms_contact_submissions(show_id)
  WHERE show_id IS NOT NULL;
