-- ============================================================================
-- Migration 046: Feedback Status Workflow + Internal Notes
-- ============================================================================
-- Adds two features to the feedback system:
--
-- 1. STATUS WORKFLOW — a simple status column on feedback_responses so staff
--    can mark items as new → reviewed → resolved (or dismissed). This lets
--    the list view filter by what still needs attention.
--
-- 2. INTERNAL NOTES — a separate append-only table (feedback_notes) where
--    staff can log what they did about a feedback item. Multiple staff might
--    touch the same item, so each note has author attribution + timestamp.
--
-- Why a separate table instead of a JSONB array on feedback_responses?
--   - Append-only is cleaner with individual rows (no read-modify-write race)
--   - Each note gets its own UUID, timestamp, and author FK
--   - Easier to query ("show me all notes by this staff member")
--   - Follows the audit_log pattern already in the codebase
-- ============================================================================

-- ─── Part 1: Add status column to feedback_responses ────────────────────────

-- Default 'new' so all existing rows automatically get the right status
ALTER TABLE feedback_responses
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'new';

-- Track who last changed the status and when
ALTER TABLE feedback_responses
  ADD COLUMN IF NOT EXISTS status_changed_at timestamptz;

ALTER TABLE feedback_responses
  ADD COLUMN IF NOT EXISTS status_changed_by uuid REFERENCES profiles(id);

-- Constrain to the three valid statuses
-- (Using a CHECK constraint rather than an enum so we can add states later
--  without a migration — just ALTER the CHECK)
ALTER TABLE feedback_responses
  ADD CONSTRAINT feedback_status_check CHECK (
    status IN ('new', 'reviewed', 'resolved', 'dismissed')
  );

-- Index for the dashboard's most common query: "show me all new/open feedback"
CREATE INDEX IF NOT EXISTS idx_feedback_status
  ON feedback_responses(station_id, status, created_at DESC)
  WHERE deleted_at IS NULL;

-- ─── Part 2: Create feedback_notes table ────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.feedback_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  feedback_id uuid NOT NULL REFERENCES feedback_responses(id),
  author_id uuid NOT NULL REFERENCES profiles(id),

  -- The note itself — plain text, no formatting needed
  content text NOT NULL,

  -- Timestamps — append-only, so no updated_at needed
  created_at timestamptz NOT NULL DEFAULT now(),

  -- Soft delete — follows Beacon convention
  deleted_at timestamptz
);

-- Index: fetch all notes for a feedback item, newest first
CREATE INDEX IF NOT EXISTS idx_feedback_notes_by_feedback
  ON feedback_notes(feedback_id, created_at DESC)
  WHERE deleted_at IS NULL;

-- Index: find all notes by a specific staff member (useful for auditing)
CREATE INDEX IF NOT EXISTS idx_feedback_notes_by_author
  ON feedback_notes(author_id, created_at DESC)
  WHERE deleted_at IS NULL;

-- ─── Part 3: Permissions ────────────────────────────────────────────────────

-- RLS on feedback_notes — same pattern as feedback_responses
ALTER TABLE feedback_notes ENABLE ROW LEVEL SECURITY;

-- Service role gets full access (used by admin API routes)
GRANT ALL ON TABLE feedback_notes TO service_role;

-- Authenticated users get read access (defense in depth — API routes use service role)
GRANT SELECT ON TABLE feedback_notes TO authenticated;

-- Staff can read notes for feedback in their station
DROP POLICY IF EXISTS "feedback_notes_staff_read" ON feedback_notes;
CREATE POLICY "feedback_notes_staff_read" ON feedback_notes
  FOR SELECT TO authenticated
  USING (
    feedback_id IN (
      SELECT fr.id FROM feedback_responses fr
      JOIN profiles p ON p.id = auth.uid()
      WHERE fr.station_id = p.station_id
        AND p.role IN ('super_admin', 'admin', 'ops')
        AND p.deleted_at IS NULL
    )
  );

-- Super admin can read all notes
DROP POLICY IF EXISTS "feedback_notes_super_admin_read" ON feedback_notes;
CREATE POLICY "feedback_notes_super_admin_read" ON feedback_notes
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND role = 'super_admin'
        AND deleted_at IS NULL
    )
  );

-- Also need UPDATE permission on feedback_responses for status changes
-- (service_role already has ALL, but add explicit GRANT for authenticated
--  in case any future code path uses the publishable key client)
GRANT UPDATE ON TABLE feedback_responses TO service_role;

-- ─── Notify PostgREST ───────────────────────────────────────────────────────

NOTIFY pgrst, 'reload schema';
