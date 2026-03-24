-- Migration 062: Sponsorship inquiries + notes
--
-- The main pipeline table for sponsorship/underwriting inquiries.
-- All three paths (media sponsorship, event sponsorship, trade) land here.
-- Notes are a separate append-only table (not JSONB arrays) to avoid
-- race conditions when multiple staff members add notes simultaneously.
--
-- All statements are idempotent.


-- ============================================================================
-- 1. sponsorship_inquiries — the main pipeline table
-- ============================================================================
-- One row per inquiry, regardless of type. Staff triages from admin.kpfk.org.
-- Auto-scored on submission (qualification_score + suggested_tier).

CREATE TABLE IF NOT EXISTS public.sponsorship_inquiries (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    station_id          uuid        NOT NULL REFERENCES public.stations(id),

    -- Which of the three paths this inquiry came from
    inquiry_type        text        NOT NULL CHECK (inquiry_type IN ('media_sponsorship', 'event_sponsorship', 'trade')),

    -- Pipeline status — tracks where this inquiry is in the sales process
    -- new:       just submitted, not yet reviewed
    -- reviewing: staff is looking at it
    -- quoted:    custom quote sent to prospect
    -- approved:  deal agreed, awaiting payment or setup
    -- declined:  not a fit, or prospect declined
    -- completed: fully paid and delivered
    status              text        NOT NULL DEFAULT 'new'
                                    CHECK (status IN ('new', 'reviewing', 'quoted', 'approved', 'declined', 'completed')),

    -- Unique reference number: SP-26-XXXXXX (year prefix + random 6 alphanumeric)
    -- Generated server-side, collision-checked before insert
    reference_number    text        NOT NULL,

    -- ---- Organization info (common to all paths) ----
    org_name            text        NOT NULL,
    org_type            text        NOT NULL CHECK (org_type IN ('501c3', '501c4', 'for_profit', 'government', 'other')),
    contact_name        text        NOT NULL,
    contact_title       text,
    contact_email       text        NOT NULL,
    contact_phone       text        NOT NULL,
    website             text,
    how_heard           text,

    -- ---- Type-specific details (only one is populated per inquiry) ----
    -- Media sponsorship: event info, channels requested, attendance, promo copy, dates
    media_details       jsonb,
    -- Event sponsorship: event_id, tier_interest, contribution_type, in_kind_desc, motivation
    event_details       jsonb,
    -- Trade: event info, what they offer, their reach, channels requested
    trade_details       jsonb,

    -- ---- File attachments ----
    -- Array of {filename, storage_path, mime_type, size_bytes, upload_status}
    attachments         jsonb       NOT NULL DEFAULT '[]'::jsonb,

    -- ---- Lead qualification (auto-computed on submission) ----
    -- Score 1-5: how strong a fit this inquiry is (based on channels, attendance, org type, reach)
    qualification_score integer     CHECK (qualification_score IS NULL OR (qualification_score >= 1 AND qualification_score <= 5)),
    -- Auto-suggested tier name (e.g., "Diamond") based on scoring factors
    suggested_tier      text,

    -- ---- Categorization ----
    -- Mix of predefined category names (from sponsor_category_tags) and custom freeform strings
    tags                jsonb       NOT NULL DEFAULT '[]'::jsonb,

    -- ---- Assignment ----
    -- Staff member handling this inquiry
    assigned_to         uuid        REFERENCES public.profiles(id),

    -- ---- Timestamps ----
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now()
);

-- Reference number must be unique across all inquiries
-- Using a DO block because CREATE UNIQUE INDEX IF NOT EXISTS handles the idempotency
CREATE UNIQUE INDEX IF NOT EXISTS sponsorship_inquiries_reference_number_idx
    ON public.sponsorship_inquiries(reference_number);

-- Common query indexes for the admin list view with filters
CREATE INDEX IF NOT EXISTS sponsorship_inquiries_station_id_idx
    ON public.sponsorship_inquiries(station_id);

CREATE INDEX IF NOT EXISTS sponsorship_inquiries_status_idx
    ON public.sponsorship_inquiries(status);

CREATE INDEX IF NOT EXISTS sponsorship_inquiries_inquiry_type_idx
    ON public.sponsorship_inquiries(inquiry_type);

CREATE INDEX IF NOT EXISTS sponsorship_inquiries_created_at_idx
    ON public.sponsorship_inquiries(created_at);

CREATE INDEX IF NOT EXISTS sponsorship_inquiries_assigned_to_idx
    ON public.sponsorship_inquiries(assigned_to);

CREATE INDEX IF NOT EXISTS sponsorship_inquiries_qualification_score_idx
    ON public.sponsorship_inquiries(qualification_score);

-- Auto-update updated_at
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'set_sponsorship_inquiries_updated_at'
    ) THEN
        CREATE TRIGGER set_sponsorship_inquiries_updated_at
            BEFORE UPDATE ON public.sponsorship_inquiries
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at();
    END IF;
END $$;

-- RLS: No public read (sensitive business data). Admin read/write via service role.
-- Anon INSERT is allowed (public form submission) — rate-limited at API layer.
ALTER TABLE public.sponsorship_inquiries ENABLE ROW LEVEL SECURITY;

-- Staff can read inquiries for their station
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'sponsorship_inquiries' AND policyname = 'sponsorship_inquiries_authenticated_select'
    ) THEN
        CREATE POLICY sponsorship_inquiries_authenticated_select
            ON public.sponsorship_inquiries FOR SELECT TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM public.profiles
                    WHERE profiles.id = auth.uid()
                    AND profiles.role IN ('super_admin', 'admin', 'ops')
                    AND profiles.is_active = true
                    AND (profiles.role = 'super_admin' OR profiles.station_id = sponsorship_inquiries.station_id)
                )
            );
    END IF;
END $$;

-- Anon can insert (public form submission — rate-limited at API layer)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'sponsorship_inquiries' AND policyname = 'sponsorship_inquiries_anon_insert'
    ) THEN
        CREATE POLICY sponsorship_inquiries_anon_insert
            ON public.sponsorship_inquiries FOR INSERT TO anon
            WITH CHECK (true);
    END IF;
END $$;


-- ============================================================================
-- 2. sponsorship_notes — append-only notes on inquiries
-- ============================================================================
-- Separate table instead of JSONB array on the inquiry row.
-- Why: avoids race conditions when two staff members add notes at the same time
-- (JSONB read-modify-write would lose one note). Also easier to query by author
-- or date, and matches the feedback_notes pattern already in the codebase.

CREATE TABLE IF NOT EXISTS public.sponsorship_notes (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Which inquiry this note belongs to
    inquiry_id      uuid        NOT NULL REFERENCES public.sponsorship_inquiries(id) ON DELETE CASCADE,
    -- Who wrote this note
    author_id       uuid        NOT NULL REFERENCES public.profiles(id),
    -- The note text (max enforced at API layer, not DB — keeps constraint simple)
    content         text        NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now()
);

-- Index for the most common query: "all notes for this inquiry, newest first"
CREATE INDEX IF NOT EXISTS sponsorship_notes_inquiry_id_idx
    ON public.sponsorship_notes(inquiry_id);

-- Index for "all notes by this author" (admin reporting)
CREATE INDEX IF NOT EXISTS sponsorship_notes_author_id_idx
    ON public.sponsorship_notes(author_id);

-- RLS: staff can read/write notes for inquiries in their station
ALTER TABLE public.sponsorship_notes ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'sponsorship_notes' AND policyname = 'sponsorship_notes_authenticated_select'
    ) THEN
        CREATE POLICY sponsorship_notes_authenticated_select
            ON public.sponsorship_notes FOR SELECT TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM public.sponsorship_inquiries si
                    JOIN public.profiles p ON p.id = auth.uid()
                    WHERE si.id = sponsorship_notes.inquiry_id
                    AND p.is_active = true
                    AND p.role IN ('super_admin', 'admin', 'ops')
                    AND (p.role = 'super_admin' OR p.station_id = si.station_id)
                )
            );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'sponsorship_notes' AND policyname = 'sponsorship_notes_authenticated_insert'
    ) THEN
        CREATE POLICY sponsorship_notes_authenticated_insert
            ON public.sponsorship_notes FOR INSERT TO authenticated
            WITH CHECK (
                EXISTS (
                    SELECT 1 FROM public.sponsorship_inquiries si
                    JOIN public.profiles p ON p.id = auth.uid()
                    WHERE si.id = sponsorship_notes.inquiry_id
                    AND p.is_active = true
                    AND p.role IN ('super_admin', 'admin', 'ops')
                    AND (p.role = 'super_admin' OR p.station_id = si.station_id)
                )
            );
    END IF;
END $$;


-- ============================================================================
-- 3. Notify PostgREST to reload schema cache
-- ============================================================================
NOTIFY pgrst, 'reload schema';
