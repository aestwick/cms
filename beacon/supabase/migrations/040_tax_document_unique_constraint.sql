-- Prevent duplicate tax documents for the same donation + document type.
-- Webhook retries could previously create duplicates since there was no
-- uniqueness check on (donation_id, document_type). This constraint makes
-- duplicate inserts fail with a 23505 error that callers can handle gracefully.
--
-- Only applies to non-null donation_id (some tax docs may be standalone).

CREATE UNIQUE INDEX IF NOT EXISTS idx_tax_documents_donation_type_unique
  ON tax_documents (donation_id, document_type)
  WHERE donation_id IS NOT NULL;

-- PostgREST caches the schema — tell it to reload so the new constraint is visible
NOTIFY pgrst, 'reload schema';
