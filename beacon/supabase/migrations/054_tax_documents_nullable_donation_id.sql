-- Migration 054: Make tax_documents.donation_id nullable for event order receipts
--
-- WHY: Event ticket purchases create tax documents that link to event_orders
-- (via event_orders.tax_document_id) rather than to donations. The original
-- schema assumed all receipts would be donation-linked, but M3 events changed
-- that. Making donation_id nullable lets us create receipts for event orders
-- without a fake donation reference.
--
-- SAFETY: Existing donation receipts already have donation_id set, so this
-- change doesn't affect any existing rows. Only new event order receipts
-- will insert NULL here.

ALTER TABLE tax_documents
  ALTER COLUMN donation_id DROP NOT NULL;

-- Also drop the unique constraint on (donation_id, document_type) since
-- donation_id can now be NULL and NULLs don't participate in unique checks.
-- We'll add a partial unique index that covers both cases:
--   - For donation receipts: unique on (donation_id, document_type) WHERE donation_id IS NOT NULL
--   - Event order receipts are deduplicated by the event_orders.tax_document_id FK
--     (one tax doc per order, enforced in application code)

-- Check if the old unique index exists before attempting to drop it
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE indexname = 'idx_tax_documents_donation_type_unique'
  ) THEN
    DROP INDEX idx_tax_documents_donation_type_unique;
  END IF;
END $$;

-- Re-create as a partial index that only applies to donation-linked receipts
-- (tax_documents are immutable — no deleted_at column, superseded docs use superseded_at)
CREATE UNIQUE INDEX idx_tax_documents_donation_type_unique
  ON tax_documents (donation_id, document_type)
  WHERE donation_id IS NOT NULL;

-- Add a comment explaining the nullable donation_id
COMMENT ON COLUMN tax_documents.donation_id IS
  'FK to donations. NULL for event order receipts (linked via event_orders.tax_document_id instead).';

-- Notify PostgREST to reload the schema so it sees the nullable change
NOTIFY pgrst, 'reload schema';
