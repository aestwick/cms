-- ============================================================================
-- Migration 031: Fix show_id FK and tax_documents constraint
-- ============================================================================
-- Two fixes:
--
-- 1. DROP donations.show_id FK to legacy "shows" table.
--    The actual show/program data now lives in the "programs" table (migration 009).
--    The old FK references "shows" which is the legacy M0 table. Phone pledge and
--    donation forms now send program UUIDs from the "programs" table, so the FK
--    to "shows" would reject valid program IDs. Rather than re-point the FK to
--    "programs" (which could break any existing rows referencing "shows" UUIDs),
--    we drop the constraint. Referential integrity is handled in application code.
--
-- 2. LOOSEN tax_documents.gross_amount_cents constraint for correction documents.
--    Full refunds create correction documents with gross_amount_cents = 0, but
--    the original constraint required > 0. We relax it to allow 0 specifically
--    for correction documents while keeping the > 0 check for regular receipts.
-- ============================================================================

-- 1. Drop the legacy FK from donations.show_id → shows(id)
ALTER TABLE donations DROP CONSTRAINT IF EXISTS donations_show_id_fkey;

-- 2. Fix tax_documents gross_amount_cents constraint
--    Old: gross_amount_cents > 0  (blocks correction docs with $0)
--    New: gross_amount_cents > 0 OR document_type = 'correction'
ALTER TABLE tax_documents DROP CONSTRAINT IF EXISTS tax_documents_gross_amount_cents_check;
ALTER TABLE tax_documents ADD CONSTRAINT tax_documents_gross_amount_cents_check
  CHECK (gross_amount_cents > 0 OR document_type = 'correction');

-- Tell PostgREST to pick up the schema changes (dropped FK, altered constraint)
NOTIFY pgrst, 'reload schema';
