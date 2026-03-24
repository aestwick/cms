-- Migration 068: Event Categories
-- Adds event_categories table and category_id FK on events table.
-- Allows admins to categorize events (Screening, Rally, Workshop, etc.)
-- and public visitors to filter events by category on the landing page.

-- 1. Create event_categories table
CREATE TABLE IF NOT EXISTS public.event_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id uuid NOT NULL REFERENCES public.stations(id),
  name text NOT NULL,
  slug text NOT NULL,
  description text,
  sort_order integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Unique slug per station (soft-delete aware)
CREATE UNIQUE INDEX event_categories_station_slug_idx
  ON public.event_categories(station_id, slug)
  WHERE deleted_at IS NULL;

-- Index for listing active categories
CREATE INDEX event_categories_station_active_idx
  ON public.event_categories(station_id, is_active)
  WHERE deleted_at IS NULL;

-- 2. Add category_id to events table
ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS category_id uuid REFERENCES public.event_categories(id);

-- Index for filtering events by category
CREATE INDEX events_category_id_idx ON public.events(category_id)
  WHERE deleted_at IS NULL;

-- 3. Seed initial categories for KPFK
-- Uses the KPFK station_id from the stations table
INSERT INTO public.event_categories (station_id, name, slug, sort_order)
SELECT
  s.id,
  cat.name,
  cat.slug,
  cat.sort_order
FROM public.stations s
CROSS JOIN (VALUES
  ('Screening', 'screening', 1),
  ('Rally', 'rally', 2),
  ('Book Talk / Signing', 'book-talk-signing', 3),
  ('Workshop', 'workshop', 4),
  ('Concert', 'concert', 5),
  ('Fundraiser', 'fundraiser', 6),
  ('Community Meeting', 'community-meeting', 7),
  ('Other', 'other', 8)
) AS cat(name, slug, sort_order)
WHERE s.call_sign = 'KPFK'
ON CONFLICT DO NOTHING;

-- 4. RLS policies — admin routes use service role so these are for safety
ALTER TABLE public.event_categories ENABLE ROW LEVEL SECURITY;

-- Allow public read access (needed for public landing page filters)
CREATE POLICY "event_categories_public_read"
  ON public.event_categories
  FOR SELECT
  USING (deleted_at IS NULL AND is_active = true);

-- Allow authenticated users to manage (admin routes use service role anyway)
CREATE POLICY "event_categories_authenticated_all"
  ON public.event_categories
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Notify PostgREST to reload schema so it sees the new table and column
NOTIFY pgrst, 'reload schema';
