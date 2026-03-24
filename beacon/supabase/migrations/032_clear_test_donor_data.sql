-- ============================================================================
-- Migration 032: Clear Test Donor Data
-- ============================================================================
-- Removes ALL donor records, donations, transaction data, and audit logs
-- so we can start fresh with real data. Everything in the DB up to this point
-- was test transactions with fake donors.
--
-- WHAT GETS CLEARED:
--   - Donors and all associated records (donations, memberships, addresses, etc.)
--   - Fulfillment items, tax documents, email logs
--   - Payment intents, checkout sessions
--   - Audit log (all entries)
--   - Station sequences (receipt number counters reset to 0)
--   - Donor CRM data (notes, tags, extensions, interactions, gift intents)
--   - Match allocations (donation-level, not pool config)
--   - Donation inspirations (program attribution per donation)
--   - Event registrations and registration gifts (M3 test data)
--   - Stewardship documents + underwriting chain (cascaded via donors FK)
--
-- WHAT STAYS:
--   - Stations, profiles (staff accounts)
--   - Gifts, gift variants (premium catalog)
--   - Programs, hosts, categories
--   - Campaigns, campaign_shows
--   - Gift-campaign and gift-program links
--   - Match pools (fund configuration)
--   - All RLS policies, functions, triggers
-- ============================================================================

-- Step 1: Null out any donor_id references in profiles
-- (staff profiles may be linked to donor records — preserve the profile, drop the link)
UPDATE profiles SET donor_id = NULL WHERE donor_id IS NOT NULL;

-- Step 2: Temporarily drop the FK from profiles → donors.
-- TRUNCATE checks constraints at the schema level even when all values are NULL,
-- and we can't include profiles in the TRUNCATE (we want to keep staff accounts).
ALTER TABLE profiles DROP CONSTRAINT profiles_donor_id_fkey;

-- Step 3: Truncate all donor/transaction tables in one atomic operation.
-- CASCADE automatically ripples to any table with an FK pointing at these
-- (e.g. documents → underwriting_agreements → invoices/broadcasts).
-- Safe because we already detached profiles (the only table we want to keep
-- that references donors), and no config tables have FKs to these tables.
TRUNCATE TABLE
    audit_log,
    donation_inspirations,
    match_allocations,
    interactions,
    gift_intents,
    donor_tags,
    donor_notes,
    donor_extensions,
    event_registration_gifts,
    event_registrations,
    fulfillment_items,
    email_log,
    tax_documents,
    payment_intents,
    checkout_sessions,
    donations,
    memberships,
    addresses,
    donors,
    station_sequences
RESTART IDENTITY CASCADE;

-- Step 4: Re-add the FK from profiles → donors so the relationship is intact going forward.
ALTER TABLE profiles
    ADD CONSTRAINT profiles_donor_id_fkey
    FOREIGN KEY (donor_id) REFERENCES donors(id);

-- Step 5: Tell PostgREST to reload its schema cache
-- (Required after any schema-affecting operation per CLAUDE.md rules)
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- End of Migration 032
-- ============================================================================
