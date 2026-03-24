-- Add allegiance_item_code to gifts table
-- This column stores the Allegiance inventory system item code (e.g. "10002", "58805D")
-- so staff can match Beacon premiums to Allegiance fulfillment items when importing/exporting
-- between the two systems. The code is entered manually when creating or editing a gift.

ALTER TABLE public.gifts
ADD COLUMN IF NOT EXISTS allegiance_item_code text NULL;

-- Index for lookups by allegiance code within a station (e.g. searching by code in gift catalog)
CREATE INDEX IF NOT EXISTS gifts_allegiance_item_code_idx
ON public.gifts (station_id, allegiance_item_code)
WHERE deleted_at IS NULL AND allegiance_item_code IS NOT NULL;

-- Let PostgREST know the schema changed
NOTIFY pgrst, 'reload schema';
