-- Add address columns to donors table
-- The live board and reports need city/state/zip to display donor locations.
-- Previously, address data was only stored in JSONB snapshots on checkout_sessions
-- and fulfillment_items, making it unavailable for donor-level queries.

ALTER TABLE donors
  ADD COLUMN IF NOT EXISTS city text,
  ADD COLUMN IF NOT EXISTS state text,
  ADD COLUMN IF NOT EXISTS zip text;

-- Index on city for location-based queries and reports
CREATE INDEX IF NOT EXISTS idx_donors_city ON donors (city) WHERE city IS NOT NULL AND deleted_at IS NULL;

-- Let PostgREST know the schema changed
NOTIFY pgrst, 'reload schema';
