-- Add deleted_at column to access_requests table
-- The API code (GET, DELETE handlers) already filters on deleted_at for soft-delete
-- support, but the original migration (041) didn't include the column — causing
-- "Failed to fetch access requests" errors on the Requests tab.

ALTER TABLE public.access_requests
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- Index for queries that filter on deleted_at (most queries exclude soft-deleted rows)
CREATE INDEX IF NOT EXISTS idx_access_requests_deleted_at
  ON public.access_requests(deleted_at)
  WHERE deleted_at IS NULL;

-- Tell PostgREST to reload schema so it sees the new column
NOTIFY pgrst, 'reload schema';
