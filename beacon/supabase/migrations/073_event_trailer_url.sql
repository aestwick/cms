-- Add trailer_url column to events table
-- Stores a YouTube or Vimeo URL for screening events.
-- Displayed as an embedded video on the public event detail page
-- between the description and the policies section.

ALTER TABLE events
  ADD COLUMN IF NOT EXISTS trailer_url text DEFAULT NULL;

-- Let PostgREST know the schema changed
NOTIFY pgrst, 'reload schema';
