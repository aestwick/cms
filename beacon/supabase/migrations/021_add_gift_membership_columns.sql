-- ============================================================================
-- Migration 021: Add gift membership columns
-- ============================================================================
-- Gift memberships allow one donor to purchase a membership for another donor.
-- This requires:
-- 1. donations.recipient_donor_id - links to the recipient of a gift donation
-- 2. memberships.donation_id - links gift membership to the donation (idempotency)
-- 3. memberships.ends_at - expiration date for gift memberships (1 year)
-- ============================================================================

-- Add recipient_donor_id to donations (for gift memberships where payer != recipient)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'donations' AND column_name = 'recipient_donor_id'
    ) THEN
        ALTER TABLE donations ADD COLUMN recipient_donor_id uuid REFERENCES donors(id);
        CREATE INDEX IF NOT EXISTS idx_donations_recipient_donor ON donations(recipient_donor_id) WHERE recipient_donor_id IS NOT NULL;
    END IF;
END $$;

-- Add donation_id to memberships (links gift membership to the donation that created it)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'memberships' AND column_name = 'donation_id'
    ) THEN
        ALTER TABLE memberships ADD COLUMN donation_id uuid REFERENCES donations(id);
        CREATE INDEX IF NOT EXISTS idx_memberships_donation ON memberships(donation_id) WHERE donation_id IS NOT NULL;
    END IF;
END $$;

-- Add ends_at to memberships (expiration for gift memberships - 1 year from started_at)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'memberships' AND column_name = 'ends_at'
    ) THEN
        ALTER TABLE memberships ADD COLUMN ends_at timestamptz;
    END IF;
END $$;

-- ============================================================================
-- End of Migration 021
-- ============================================================================
