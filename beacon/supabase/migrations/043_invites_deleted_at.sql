-- ============================================================================
-- PHASE 043: Add deleted_at to invites table
-- ============================================================================
-- Adds soft-delete support so admins can remove invites from the list entirely.
-- Previously, "revoking" an invite just expired it, which still showed it as
-- "expired" in the list. Now we can properly hide deleted invites.
--
-- Run AFTER 042_add_gift_tags.sql
-- ============================================================================

-- Add the soft-delete column (null = not deleted, timestamptz = when deleted)
ALTER TABLE public.invites ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- Index to efficiently filter out deleted invites in queries
CREATE INDEX IF NOT EXISTS idx_invites_deleted_at ON public.invites(deleted_at)
    WHERE deleted_at IS NULL;

-- Tell PostgREST to reload schema so it sees the new column
NOTIFY pgrst, 'reload schema';
