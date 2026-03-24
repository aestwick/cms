-- Migration 061: Sponsorship reference tables
--
-- Creates the four core reference tables for the sponsorship & underwriting system:
--   sponsor_channels    — promotional channels KPFK offers (on-air, email, social, etc.)
--   sponsor_tiers       — internal media sponsorship pricing tiers (Diamond/Platinum/Gold/Silver)
--   sponsor_logos       — social proof logos of past/current partners
--   sponsor_category_tags — predefined categories for tagging inquiries and accounts
--
-- These tables have no cross-dependencies and are the foundation the rest of
-- the sponsorship system builds on (inquiries, event tiers, accounts, etc.).
--
-- All statements are idempotent (IF NOT EXISTS / DO $$ guards).


-- ============================================================================
-- 1. sponsor_channels — promotional channels KPFK offers to sponsors
-- ============================================================================
-- Each row = one channel shown on the public sponsor page and used in the
-- intake form checkboxes. Admin can add/edit/deactivate channels without code.
-- Public (anon) can read active channels for the page and form.

CREATE TABLE IF NOT EXISTS public.sponsor_channels (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    station_id      uuid        NOT NULL REFERENCES public.stations(id),
    -- Channel name shown on public page and in form checkboxes
    name            text        NOT NULL,
    -- Public-facing description of what this channel includes
    description     text        NOT NULL,
    -- Icon identifier — emoji, icon name, or storage path (nullable, cosmetic)
    icon            text,
    -- Controls display order on the public page (lower = higher)
    sort_order      integer     NOT NULL DEFAULT 0,
    -- When false, channel is hidden from the public page and form
    is_active       boolean     NOT NULL DEFAULT true,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);

-- Composite index for the most common query: "active channels for this station, sorted"
CREATE INDEX IF NOT EXISTS sponsor_channels_station_sort_idx
    ON public.sponsor_channels(station_id, sort_order);

-- Auto-update updated_at on changes
-- Using DO block so the trigger creation is idempotent
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'set_sponsor_channels_updated_at'
    ) THEN
        CREATE TRIGGER set_sponsor_channels_updated_at
            BEFORE UPDATE ON public.sponsor_channels
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at();
    END IF;
END $$;

-- RLS: public can read active channels, admin writes via service role
ALTER TABLE public.sponsor_channels ENABLE ROW LEVEL SECURITY;

-- Anon can see active channels (public page + form)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'sponsor_channels' AND policyname = 'sponsor_channels_anon_select'
    ) THEN
        CREATE POLICY sponsor_channels_anon_select
            ON public.sponsor_channels FOR SELECT TO anon
            USING (is_active = true);
    END IF;
END $$;

-- Authenticated staff can see all channels (including inactive, for admin)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'sponsor_channels' AND policyname = 'sponsor_channels_authenticated_select'
    ) THEN
        CREATE POLICY sponsor_channels_authenticated_select
            ON public.sponsor_channels FOR SELECT TO authenticated
            USING (true);
    END IF;
END $$;


-- ============================================================================
-- 2. sponsor_tiers — internal media sponsorship pricing tiers
-- ============================================================================
-- Station-wide tiers (Diamond, Platinum, Gold, Silver). Pricing is INTERNAL
-- ONLY — never exposed on the public page. Staff uses these for quoting.
-- The public page says "inquiry-based" and doesn't show prices.

CREATE TABLE IF NOT EXISTS public.sponsor_tiers (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    station_id          uuid        NOT NULL REFERENCES public.stations(id),
    -- Tier name: Diamond, Platinum, Gold, Silver (or custom)
    name                text        NOT NULL,
    -- Internal pricing in cents — never shown publicly
    price_cents         bigint      NOT NULL CHECK (price_cents >= 0),
    -- Array of benefit description strings, e.g. ["All 6 channels", "Priority scheduling"]
    benefits            jsonb       NOT NULL DEFAULT '[]'::jsonb,
    -- Array of sponsor_channel UUIDs included in this tier
    channels_included   jsonb       NOT NULL DEFAULT '[]'::jsonb,
    -- true = on-air spots included in the tier price; false = available as add-on
    on_air_included     boolean     NOT NULL DEFAULT false,
    -- Controls display order in admin views (lower = higher tier)
    sort_order          integer     NOT NULL DEFAULT 0,
    -- Soft toggle — deactivated tiers are hidden but not deleted
    is_active           boolean     NOT NULL DEFAULT true,
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now()
);

-- Index for admin queries: "tiers for this station, sorted"
CREATE INDEX IF NOT EXISTS sponsor_tiers_station_sort_idx
    ON public.sponsor_tiers(station_id, sort_order);

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'set_sponsor_tiers_updated_at'
    ) THEN
        CREATE TRIGGER set_sponsor_tiers_updated_at
            BEFORE UPDATE ON public.sponsor_tiers
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at();
    END IF;
END $$;

-- RLS: NO public read (internal pricing). Admin read/write via service role.
ALTER TABLE public.sponsor_tiers ENABLE ROW LEVEL SECURITY;

-- Only authenticated staff can view tiers (admin panel)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'sponsor_tiers' AND policyname = 'sponsor_tiers_authenticated_select'
    ) THEN
        CREATE POLICY sponsor_tiers_authenticated_select
            ON public.sponsor_tiers FOR SELECT TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM public.profiles
                    WHERE profiles.id = auth.uid()
                    AND profiles.role IN ('super_admin', 'admin')
                    AND profiles.is_active = true
                    AND (profiles.role = 'super_admin' OR profiles.station_id = sponsor_tiers.station_id)
                )
            );
    END IF;
END $$;


-- ============================================================================
-- 3. sponsor_logos — social proof logos of past/current partners
-- ============================================================================
-- Logo grid on the public sponsor page. Each logo is uploaded via admin and
-- stored in Supabase Storage (sponsor-logos bucket). Optional link to partner site.

CREATE TABLE IF NOT EXISTS public.sponsor_logos (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    station_id      uuid        NOT NULL REFERENCES public.stations(id),
    -- Partner organization name (alt text for accessibility)
    name            text        NOT NULL,
    -- Path in Supabase Storage sponsor-logos bucket
    image_path      text        NOT NULL,
    -- Optional link to partner's website
    url             text,
    -- Display order on the public page (lower = first)
    sort_order      integer     NOT NULL DEFAULT 0,
    -- When false, logo is hidden from the public page
    is_active       boolean     NOT NULL DEFAULT true,
    created_at      timestamptz NOT NULL DEFAULT now()
);

-- Index for the common query: "active logos for this station, sorted"
CREATE INDEX IF NOT EXISTS sponsor_logos_station_sort_idx
    ON public.sponsor_logos(station_id, sort_order);

-- RLS: public can see active logos, admin writes via service role
ALTER TABLE public.sponsor_logos ENABLE ROW LEVEL SECURITY;

-- Anon can see active logos (public page)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'sponsor_logos' AND policyname = 'sponsor_logos_anon_select'
    ) THEN
        CREATE POLICY sponsor_logos_anon_select
            ON public.sponsor_logos FOR SELECT TO anon
            USING (is_active = true);
    END IF;
END $$;

-- Authenticated staff can see all logos (including inactive, for admin)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'sponsor_logos' AND policyname = 'sponsor_logos_authenticated_select'
    ) THEN
        CREATE POLICY sponsor_logos_authenticated_select
            ON public.sponsor_logos FOR SELECT TO authenticated
            USING (true);
    END IF;
END $$;


-- ============================================================================
-- 4. sponsor_category_tags — predefined categories for tagging
-- ============================================================================
-- Official tag vocabulary for consistent categorization across inquiries and
-- sponsor accounts. Custom tags are freeform strings stored directly in JSONB
-- arrays on the parent table; this table defines the "official" set that
-- appears in dropdowns.

CREATE TABLE IF NOT EXISTS public.sponsor_category_tags (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    station_id      uuid        NOT NULL REFERENCES public.stations(id),
    -- Tag name: arts, activism, education, etc.
    name            text        NOT NULL,
    -- Display order in dropdowns (lower = first)
    sort_order      integer     NOT NULL DEFAULT 0,
    -- Soft toggle — deactivated tags are hidden from dropdowns but kept for history
    is_active       boolean     NOT NULL DEFAULT true,
    created_at      timestamptz NOT NULL DEFAULT now()
);

-- Index for dropdown queries: "active tags for this station, sorted"
CREATE INDEX IF NOT EXISTS sponsor_category_tags_station_sort_idx
    ON public.sponsor_category_tags(station_id, sort_order);

-- RLS: staff can read (for dropdowns in admin), admin writes via service role
ALTER TABLE public.sponsor_category_tags ENABLE ROW LEVEL SECURITY;

-- Authenticated staff can read all tags
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'sponsor_category_tags' AND policyname = 'sponsor_category_tags_authenticated_select'
    ) THEN
        CREATE POLICY sponsor_category_tags_authenticated_select
            ON public.sponsor_category_tags FOR SELECT TO authenticated
            USING (true);
    END IF;
END $$;


-- ============================================================================
-- 5. Seed data — KPFK's initial channels, tiers, and category tags
-- ============================================================================
-- Uses INSERT ... ON CONFLICT DO NOTHING so re-running is safe.
-- We create a deterministic UUID for each seed row so the same migration
-- can run multiple times without duplicating data.

-- We need KPFK's station_id. If the stations table has a row, use it.
-- If not, the INSERTs will simply fail on the FK constraint (safe — no crash).

DO $$
DECLARE
    v_station_id uuid;
BEGIN
    -- Get the first (and likely only) station ID
    SELECT id INTO v_station_id FROM public.stations LIMIT 1;

    -- If no station exists yet, skip seeding (FK would fail anyway)
    IF v_station_id IS NULL THEN
        RAISE NOTICE 'No station found — skipping sponsorship seed data';
        RETURN;
    END IF;

    -- ----- Channels (6 promotional channels from the spec) -----
    INSERT INTO public.sponsor_channels (id, station_id, name, description, icon, sort_order) VALUES
        (gen_random_uuid(), v_station_id, 'On-Air Promotion',       'Promo spots during drive time and weekends',                        '📻', 1),
        (gen_random_uuid(), v_station_id, 'Website Calendar Listing','Featured listing on kpfk.org 4–6 weeks before your event',          '📅', 2),
        (gen_random_uuid(), v_station_id, 'Homepage Banner',         'Featured banner placement on kpfk.org 10–14 days before event',     '🖼️', 3),
        (gen_random_uuid(), v_station_id, 'Featured Events Section', 'Premium listing in the Featured Events section on kpfk.org',        '⭐', 4),
        (gen_random_uuid(), v_station_id, 'Email Dispatch',          'Inclusion in weekly email to 18,000+ subscribers',                   '📧', 5),
        (gen_random_uuid(), v_station_id, 'Social Media',            'Posts across Facebook, Instagram, and X',                            '📱', 6)
    ON CONFLICT DO NOTHING;

    -- ----- Tiers (4 media sponsorship tiers — internal pricing) -----
    -- Note: channels_included will be populated by admin after channels are created
    -- (the channel UUIDs are random, so we can't hardcode them here)
    INSERT INTO public.sponsor_tiers (id, station_id, name, price_cents, benefits, on_air_included, sort_order) VALUES
        (gen_random_uuid(), v_station_id, 'Diamond',  225000, '["All 6 promotional channels", "Priority scheduling", "Premium placement"]'::jsonb, true,  1),
        (gen_random_uuid(), v_station_id, 'Platinum', 150000, '["4–5 promotional channels", "Preferred scheduling"]'::jsonb,                       false, 2),
        (gen_random_uuid(), v_station_id, 'Gold',     100000, '["3 promotional channels (calendar + social + email)"]'::jsonb,                      false, 3),
        (gen_random_uuid(), v_station_id, 'Silver',    65000, '["1–2 promotional channels (calendar + social)"]'::jsonb,                            false, 4)
    ON CONFLICT DO NOTHING;

    -- ----- Category tags (10 predefined categories from the spec) -----
    INSERT INTO public.sponsor_category_tags (id, station_id, name, sort_order) VALUES
        (gen_random_uuid(), v_station_id, 'Arts',        1),
        (gen_random_uuid(), v_station_id, 'Activism',    2),
        (gen_random_uuid(), v_station_id, 'Education',   3),
        (gen_random_uuid(), v_station_id, 'Film',        4),
        (gen_random_uuid(), v_station_id, 'Labor',       5),
        (gen_random_uuid(), v_station_id, 'Health',      6),
        (gen_random_uuid(), v_station_id, 'Environment', 7),
        (gen_random_uuid(), v_station_id, 'Faith',       8),
        (gen_random_uuid(), v_station_id, 'Tech',        9),
        (gen_random_uuid(), v_station_id, 'Government',  10)
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Sponsorship seed data inserted for station %', v_station_id;
END $$;


-- ============================================================================
-- 6. Notify PostgREST to reload schema cache
-- ============================================================================
NOTIFY pgrst, 'reload schema';
