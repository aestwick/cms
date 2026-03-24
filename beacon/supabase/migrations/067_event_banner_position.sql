-- Migration 067: Add banner_position to events
-- Lets admins override the CSS background-position per event so images
-- are cropped to the focal point instead of always centering.
-- Default 'center center' preserves existing behavior.

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS banner_position text NOT NULL DEFAULT 'center center';

COMMENT ON COLUMN public.events.banner_position IS
  'CSS background-position value for banner images. Allows admins to shift the focal point (e.g., "top center", "center 30%"). Default "center center".';

-- Let PostgREST pick up the new column
NOTIFY pgrst, 'reload schema';
