-- Migration 042: Add tags array to gifts for multi-label categorization
-- Tags are freeform strings managed by admins (e.g., "new arrival", "limited edition", "holiday")
-- Enables filtering and sorting premiums like a product catalog

ALTER TABLE public.gifts
  ADD COLUMN tags text[] NOT NULL DEFAULT '{}';

-- GIN index for fast array containment queries (@>, &&, ANY)
-- Partial index: only index non-deleted gifts since that's what we query
CREATE INDEX gifts_tags_idx ON public.gifts USING GIN (tags)
  WHERE deleted_at IS NULL;

-- Let PostgREST pick up the schema change
NOTIFY pgrst, 'reload schema';
