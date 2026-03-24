-- Migration 063: Event sponsorship — events table additions + event_sponsor_tiers
--
-- Adds sponsorship support to the existing M3 events table:
--   - sponsor_content    (JSONB) — per-event sponsor page content (story, stats, terms addendum)
--   - sponsorship_enabled (bool) — whether this event appears in the sponsor form dropdown
--   - sponsor_token      (text)  — nanoid for the non-guessable sponsor page URL
--
-- Creates event_sponsor_tiers — per-event tiers with pricing (shown publicly on
-- event sponsor pages, unlike the station-wide sponsor_tiers which are internal).
--
-- All statements are idempotent.


-- ============================================================================
-- 1. Add sponsorship columns to the existing events table
-- ============================================================================

-- sponsor_content: rich JSONB blob for the event sponsor page
-- Contains: event_story_html, past_event_stats, terms_addendum_html, page overrides
-- null = sponsorship not enabled / no custom content for this event
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'events' AND column_name = 'sponsor_content'
    ) THEN
        ALTER TABLE public.events ADD COLUMN sponsor_content jsonb;
        COMMENT ON COLUMN public.events.sponsor_content IS
            'Per-event sponsor page content: story HTML, past stats, terms addendum. null = no custom sponsor content.';
    END IF;
END $$;

-- sponsorship_enabled: controls whether the event shows in the sponsor form dropdown
-- and whether the event sponsor page is accessible
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'events' AND column_name = 'sponsorship_enabled'
    ) THEN
        ALTER TABLE public.events ADD COLUMN sponsorship_enabled boolean NOT NULL DEFAULT false;
        COMMENT ON COLUMN public.events.sponsorship_enabled IS
            'When true, event appears in sponsor form dropdown and has a public sponsor page.';
    END IF;
END $$;

-- sponsor_token: nanoid (10-12 chars) used in the non-guessable URL
-- events.kpfk.org/sponsor/e/{sponsor_token}
-- Generated when sponsorship_enabled is set to true, cleared when disabled
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'events' AND column_name = 'sponsor_token'
    ) THEN
        ALTER TABLE public.events ADD COLUMN sponsor_token text;
        COMMENT ON COLUMN public.events.sponsor_token IS
            'Nanoid token for the non-guessable event sponsor page URL. Set when sponsorship enabled.';
    END IF;
END $$;

-- Unique index on sponsor_token — two events can't share the same token
-- Only indexes non-null values (partial index), so multiple events can have null
CREATE UNIQUE INDEX IF NOT EXISTS events_sponsor_token_unique_idx
    ON public.events(sponsor_token)
    WHERE sponsor_token IS NOT NULL;


-- ============================================================================
-- 2. event_sponsor_tiers — per-event sponsorship tiers with pricing
-- ============================================================================
-- Unlike station-wide sponsor_tiers (internal pricing), event tier prices
-- ARE shown publicly on the event sponsor page — these are pitch tools
-- sent to warm leads where showing pricing reduces friction.

CREATE TABLE IF NOT EXISTS public.event_sponsor_tiers (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Which event this tier belongs to
    event_id            uuid        NOT NULL REFERENCES public.events(id),
    -- Station for scoping (denormalized from events for simpler RLS/queries)
    station_id          uuid        NOT NULL REFERENCES public.stations(id),
    -- Tier name: Presenting, Supporting, Community, In-Kind (or custom per event)
    name                text        NOT NULL,
    -- Price in cents — null for in-kind/negotiated tiers
    price_cents         bigint      CHECK (price_cents IS NULL OR price_cents >= 0),
    -- Array of benefit description strings for this tier
    benefits            jsonb       NOT NULL DEFAULT '[]'::jsonb,
    -- How many sponsors can take this tier (null = unlimited)
    availability_limit  integer,
    -- Human-readable availability label: "1 per event", "Limited", "Open"
    availability_label  text,
    -- Display order on the event sponsor page (lower = top/most premium)
    sort_order          integer     NOT NULL DEFAULT 0,
    -- Soft toggle — deactivated tiers are hidden from the public page
    is_active           boolean     NOT NULL DEFAULT true,
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now()
);

-- Common query: "tiers for this event, sorted" (public page)
CREATE INDEX IF NOT EXISTS event_sponsor_tiers_event_sort_idx
    ON public.event_sponsor_tiers(event_id, sort_order);

-- Station scoping queries
CREATE INDEX IF NOT EXISTS event_sponsor_tiers_station_id_idx
    ON public.event_sponsor_tiers(station_id);

-- Auto-update updated_at
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'set_event_sponsor_tiers_updated_at'
    ) THEN
        CREATE TRIGGER set_event_sponsor_tiers_updated_at
            BEFORE UPDATE ON public.event_sponsor_tiers
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at();
    END IF;
END $$;

-- RLS: public can read active tiers (event sponsor pages show pricing),
-- admin writes via service role
ALTER TABLE public.event_sponsor_tiers ENABLE ROW LEVEL SECURITY;

-- Anon can see active tiers for events that have sponsorship enabled
-- (tier names, benefits, prices, availability — all intentionally public)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'event_sponsor_tiers' AND policyname = 'event_sponsor_tiers_anon_select'
    ) THEN
        CREATE POLICY event_sponsor_tiers_anon_select
            ON public.event_sponsor_tiers FOR SELECT TO anon
            USING (
                is_active = true
                AND EXISTS (
                    SELECT 1 FROM public.events e
                    WHERE e.id = event_sponsor_tiers.event_id
                    AND e.sponsorship_enabled = true
                    AND e.deleted_at IS NULL
                )
            );
    END IF;
END $$;

-- Authenticated staff can see all tiers (including inactive, for admin)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'event_sponsor_tiers' AND policyname = 'event_sponsor_tiers_authenticated_select'
    ) THEN
        CREATE POLICY event_sponsor_tiers_authenticated_select
            ON public.event_sponsor_tiers FOR SELECT TO authenticated
            USING (true);
    END IF;
END $$;


-- ============================================================================
-- 3. Notify PostgREST to reload schema cache
-- ============================================================================
NOTIFY pgrst, 'reload schema';
