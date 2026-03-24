-- Rename donor address columns to billing_* prefix so they aren't confused
-- with mailing addresses. The old city/state/zip columns (migration 039) were
-- populated from Stripe's billing_address_collection but had generic names.
-- Also adds line1/line2/country which were previously discarded.

-- Rename existing columns to billing_ prefix
ALTER TABLE donors RENAME COLUMN city TO billing_city;
ALTER TABLE donors RENAME COLUMN state TO billing_state;
ALTER TABLE donors RENAME COLUMN zip TO billing_zip;

-- Add new billing address fields that were previously discarded
ALTER TABLE donors
  ADD COLUMN IF NOT EXISTS billing_line1 text,
  ADD COLUMN IF NOT EXISTS billing_line2 text,
  ADD COLUMN IF NOT EXISTS billing_country text DEFAULT 'US';

-- Update the index to use the new column name (drop old, create new)
DROP INDEX IF EXISTS idx_donors_city;
CREATE INDEX IF NOT EXISTS idx_donors_billing_city ON donors (billing_city) WHERE billing_city IS NOT NULL AND deleted_at IS NULL;

-- Let PostgREST know the schema changed
NOTIFY pgrst, 'reload schema';
