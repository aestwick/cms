-- Migration 035: Add missing columns to donations table
-- These columns were created via the Supabase dashboard during development
-- but never captured in a migration file. The seed data (033) needs them,
-- and the app code references them for phone pledges and donor tracking.

-- is_first_donation: flags whether this was the donor's first-ever donation
-- Used in the donations list and donor detail views
ALTER TABLE donations
  ADD COLUMN IF NOT EXISTS is_first_donation boolean DEFAULT false;

-- pledged_at: when a phone pledge was made (before payment collected)
-- Used for bill-me pledges where payment comes later
ALTER TABLE donations
  ADD COLUMN IF NOT EXISTS pledged_at timestamptz;

-- payment_due_at: deadline for bill-me pledge payment
-- Shown in the donations list to flag overdue pledges
ALTER TABLE donations
  ADD COLUMN IF NOT EXISTS payment_due_at timestamptz;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
