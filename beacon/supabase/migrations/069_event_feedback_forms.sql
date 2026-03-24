-- Migration 069: Event Feedback Forms
-- Adds configurable feedback forms that can be tied to events.
-- Staff create forms in the event detail panel, share a link like
-- feedback.kpfk.org/jazz-night, and responses flow into the existing
-- feedback_responses table with a new event linkage.
--
-- Tables:
--   feedback_forms          — form definitions (title, slug, status, event link)
--   feedback_form_questions — questions per form (rating, text, select, multi_select, yes_no)
--
-- Changes to existing tables:
--   feedback_responses      — new nullable FKs: feedback_form_id, event_id, event_order_id
--   feedback_responses      — new form_type value: 'event_feedback'
--   feedback_responses      — new placement value: 'post_event'
--   feedback_responses      — new JSONB column: answers (structured Q&A responses)

-- ============================================================================
-- 1. feedback_forms — form definitions
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.feedback_forms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id uuid NOT NULL REFERENCES public.stations(id),
  event_id uuid REFERENCES public.events(id) ON DELETE SET NULL,

  -- URL slug — used in feedback.kpfk.org/{slug}. Must be unique.
  slug text NOT NULL,
  title text NOT NULL,
  description text,

  -- Lifecycle: draft (not accepting), live (accepting), closed (done)
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'live', 'closed')),

  -- Optional open/close window — form auto-activates/deactivates
  opens_at timestamptz,
  closes_at timestamptz,

  -- Custom thank-you message shown after submission
  thank_you_message text,

  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,

  CONSTRAINT feedback_forms_slug_unique UNIQUE (slug)
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_feedback_forms_station ON public.feedback_forms (station_id);
CREATE INDEX IF NOT EXISTS idx_feedback_forms_event ON public.feedback_forms (event_id) WHERE event_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_feedback_forms_status ON public.feedback_forms (status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_feedback_forms_slug ON public.feedback_forms (slug) WHERE deleted_at IS NULL;

-- RLS
ALTER TABLE public.feedback_forms ENABLE ROW LEVEL SECURITY;

CREATE POLICY feedback_forms_staff_select ON public.feedback_forms
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.is_active = true
        AND p.deleted_at IS NULL
        AND p.role IN ('super_admin', 'admin', 'ops', 'event_manager')
    )
  );

CREATE POLICY feedback_forms_service_role_all ON public.feedback_forms
  FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);

GRANT ALL ON public.feedback_forms TO postgres, service_role, authenticated, anon;

-- ============================================================================
-- 2. feedback_form_questions — configurable questions per form
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.feedback_form_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  form_id uuid NOT NULL REFERENCES public.feedback_forms(id) ON DELETE CASCADE,

  -- Question text shown to the respondent
  question_text text NOT NULL,

  -- Type determines what input is rendered on the public form
  question_type text NOT NULL DEFAULT 'text'
    CHECK (question_type IN ('rating', 'text', 'select', 'multi_select', 'yes_no')),

  -- For select/multi_select: JSON array of option strings ["Good", "Fair", "Poor"]
  options jsonb,

  is_required boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_feedback_form_questions_form ON public.feedback_form_questions (form_id);

-- RLS
ALTER TABLE public.feedback_form_questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY ffq_staff_select ON public.feedback_form_questions
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.is_active = true
        AND p.deleted_at IS NULL
        AND p.role IN ('super_admin', 'admin', 'ops', 'event_manager')
    )
  );

CREATE POLICY ffq_service_role_all ON public.feedback_form_questions
  FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);

GRANT ALL ON public.feedback_form_questions TO postgres, service_role, authenticated, anon;

-- ============================================================================
-- 3. Extend feedback_responses — add event linkage + structured answers
-- ============================================================================

-- Link feedback responses to a specific form
ALTER TABLE public.feedback_responses
  ADD COLUMN IF NOT EXISTS feedback_form_id uuid REFERENCES public.feedback_forms(id);

-- Link feedback to an event (denormalized from form for fast filtering)
ALTER TABLE public.feedback_responses
  ADD COLUMN IF NOT EXISTS event_id uuid REFERENCES public.events(id);

-- Link feedback to a specific ticket order (if token-based)
ALTER TABLE public.feedback_responses
  ADD COLUMN IF NOT EXISTS event_order_id uuid REFERENCES public.event_orders(id);

-- Structured answers: [{ question_id, question_text, answer }]
-- Stores both the question text (snapshot) and the answer so we don't
-- lose context if the question is later edited or deleted
ALTER TABLE public.feedback_responses
  ADD COLUMN IF NOT EXISTS answers jsonb;

-- Indexes for event feedback queries
CREATE INDEX IF NOT EXISTS idx_feedback_responses_form
  ON public.feedback_responses (feedback_form_id) WHERE feedback_form_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_feedback_responses_event
  ON public.feedback_responses (event_id) WHERE event_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_feedback_responses_order
  ON public.feedback_responses (event_order_id) WHERE event_order_id IS NOT NULL;

-- ============================================================================
-- 4. Widen CHECK constraints on feedback_responses
-- ============================================================================

-- Add 'event_feedback' to form_type CHECK if it exists
-- (The CHECK might be a table-level constraint or on the column — drop and re-add)
DO $$
BEGIN
  -- Try to drop existing form_type constraint
  ALTER TABLE public.feedback_responses DROP CONSTRAINT IF EXISTS feedback_responses_form_type_check;
  -- Re-add with new value included
  ALTER TABLE public.feedback_responses
    ADD CONSTRAINT feedback_responses_form_type_check
    CHECK (form_type IN (
      'donation_experience', 'fulfillment_satisfaction', 'cancellation',
      'general', 'staff', 'donation_comment', 'event_feedback'
    ));
EXCEPTION WHEN OTHERS THEN
  -- If there's no constraint to drop, just add ours
  NULL;
END
$$;

-- Add 'post_event' to placement CHECK if it exists
DO $$
BEGIN
  ALTER TABLE public.feedback_responses DROP CONSTRAINT IF EXISTS feedback_responses_placement_check;
  ALTER TABLE public.feedback_responses
    ADD CONSTRAINT feedback_responses_placement_check
    CHECK (placement IN (
      'during_donation', 'post_donation', 'post_fulfillment',
      'post_cancellation', 'standalone', 'post_event'
    ));
EXCEPTION WHEN OTHERS THEN
  NULL;
END
$$;

-- ============================================================================
-- 5. Notify PostgREST to reload schema
-- ============================================================================

NOTIFY pgrst, 'reload schema';
