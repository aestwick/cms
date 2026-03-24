-- Migration 071: Consolidate event question systems
--
-- Merges the separate event_questions/event_question_responses system into
-- the unified feedback_forms/feedback_responses system. After this migration,
-- all question responses (checkout, ticket page, QR code, email link) flow
-- into feedback_responses with a `source` field indicating where they came from.
--
-- Changes:
--   1. Add `source` column to feedback_responses — tells you HOW the response
--      was submitted (checkout, ticket_page, qr_standalone, email_link)
--   2. Add `surfaces` column to feedback_forms — controls WHERE the form appears
--      (checkout, ticket_page, qr_standalone, email_link)
--   3. Backfill existing feedback_responses with appropriate source values
--   4. Widen placement CHECK to include 'checkout' value
--
-- The old event_questions and event_question_responses tables are NOT dropped —
-- they remain for historical data. New responses go to feedback_responses only.

-- ============================================================================
-- 1. Add `source` to feedback_responses
-- ============================================================================

-- Source tells you which surface/entry point generated this response.
-- Different from `placement` which describes the lifecycle stage (post_event, etc.)
ALTER TABLE public.feedback_responses
  ADD COLUMN IF NOT EXISTS source text;

-- Backfill existing rows: event_feedback → qr_standalone (the original entry point),
-- all other form_types keep null (they predate the source concept)
UPDATE public.feedback_responses
SET source = 'qr_standalone'
WHERE form_type = 'event_feedback'
  AND source IS NULL;

-- Index for filtering by source in dashboards
CREATE INDEX IF NOT EXISTS idx_feedback_responses_source
  ON public.feedback_responses (source) WHERE source IS NOT NULL;

-- ============================================================================
-- 2. Add `surfaces` to feedback_forms
-- ============================================================================

-- Controls where this form is shown. A form can appear on multiple surfaces.
-- Stored as a JSONB array: ["checkout", "ticket_page", "qr_standalone", "email_link"]
-- Default is ["qr_standalone"] — the original behavior for existing forms.
ALTER TABLE public.feedback_forms
  ADD COLUMN IF NOT EXISTS surfaces jsonb NOT NULL DEFAULT '["qr_standalone"]'::jsonb;

-- Backfill existing forms to keep them on qr_standalone only
UPDATE public.feedback_forms
SET surfaces = '["qr_standalone"]'::jsonb
WHERE surfaces IS NULL OR surfaces = '[]'::jsonb;

-- ============================================================================
-- 3. Widen placement CHECK to include 'checkout' and 'ticket_page'
-- ============================================================================

-- Drop and re-add the placement CHECK constraint to include new values
DO $$
BEGIN
  ALTER TABLE public.feedback_responses DROP CONSTRAINT IF EXISTS feedback_responses_placement_check;
  ALTER TABLE public.feedback_responses
    ADD CONSTRAINT feedback_responses_placement_check
    CHECK (placement IN (
      'during_donation', 'post_donation', 'post_fulfillment',
      'post_cancellation', 'standalone', 'post_event',
      'checkout', 'ticket_page'
    ));
EXCEPTION WHEN OTHERS THEN
  NULL;
END
$$;

-- ============================================================================
-- 4. Widen form_type CHECK to include 'checkout_questions'
-- ============================================================================

DO $$
BEGIN
  ALTER TABLE public.feedback_responses DROP CONSTRAINT IF EXISTS feedback_responses_form_type_check;
  -- Also drop the legacy constraint name if it exists
  ALTER TABLE public.feedback_responses DROP CONSTRAINT IF EXISTS feedback_form_type_check;
  ALTER TABLE public.feedback_responses
    ADD CONSTRAINT feedback_responses_form_type_check
    CHECK (form_type IN (
      'donation_experience', 'fulfillment_satisfaction', 'cancellation',
      'general', 'staff', 'donation_comment', 'event_feedback',
      'checkout_questions'
    ));
EXCEPTION WHEN OTHERS THEN
  NULL;
END
$$;

-- ============================================================================
-- 5. Notify PostgREST to reload schema
-- ============================================================================

NOTIFY pgrst, 'reload schema';
