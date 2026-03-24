-- Migration: Add donor tags and notes for CRM functionality
-- Part of M1 donor management feature

-- =============================================================================
-- TAGS TABLE
-- Global tags that can be applied to donors for segmentation
-- Tags are station-scoped but can be shared/cloned between stations later
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.tags (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  station_id uuid NOT NULL,
  name text NOT NULL,
  -- Color for visual distinction in UI (hex color code)
  color text NOT NULL DEFAULT '#6b7280',
  -- Optional description for what this tag means
  description text,
  -- Track usage
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,

  CONSTRAINT tags_pkey PRIMARY KEY (id),
  CONSTRAINT tags_station_id_fkey FOREIGN KEY (station_id) REFERENCES stations(id),
  CONSTRAINT tags_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id),
  -- Tag names must be unique within a station
  CONSTRAINT tags_name_check CHECK (length(trim(name)) > 0),
  CONSTRAINT tags_color_check CHECK (color ~ '^#[0-9a-fA-F]{6}$')
);

-- Unique tag names per station (only for non-deleted tags)
CREATE UNIQUE INDEX IF NOT EXISTS tags_station_name_unique_idx
  ON public.tags (station_id, lower(trim(name)))
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS tags_station_id_idx
  ON public.tags (station_id)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS tags_deleted_at_idx
  ON public.tags (deleted_at)
  WHERE deleted_at IS NULL;

-- =============================================================================
-- DONOR_TAGS JUNCTION TABLE
-- Links donors to tags (many-to-many relationship)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.donor_tags (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  donor_id uuid NOT NULL,
  tag_id uuid NOT NULL,
  -- Who applied this tag and when
  applied_by uuid,
  applied_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT donor_tags_pkey PRIMARY KEY (id),
  CONSTRAINT donor_tags_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES donors(id) ON DELETE CASCADE,
  CONSTRAINT donor_tags_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE,
  CONSTRAINT donor_tags_applied_by_fkey FOREIGN KEY (applied_by) REFERENCES profiles(id)
);

-- Each tag can only be applied once per donor
CREATE UNIQUE INDEX IF NOT EXISTS donor_tags_unique_idx
  ON public.donor_tags (donor_id, tag_id);

CREATE INDEX IF NOT EXISTS donor_tags_donor_id_idx
  ON public.donor_tags (donor_id);

CREATE INDEX IF NOT EXISTS donor_tags_tag_id_idx
  ON public.donor_tags (tag_id);

-- =============================================================================
-- DONOR_NOTES TABLE
-- Staff notes on donor records for internal CRM use
-- Notes are append-only by design - edits create new notes, old ones get soft-deleted
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.donor_notes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  donor_id uuid NOT NULL,
  station_id uuid NOT NULL,
  -- The note content (markdown supported)
  content text NOT NULL,
  -- Note type for filtering (general, call, email, issue, etc.)
  note_type text NOT NULL DEFAULT 'general',
  -- Who wrote the note
  created_by uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,

  CONSTRAINT donor_notes_pkey PRIMARY KEY (id),
  CONSTRAINT donor_notes_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES donors(id) ON DELETE CASCADE,
  CONSTRAINT donor_notes_station_id_fkey FOREIGN KEY (station_id) REFERENCES stations(id),
  CONSTRAINT donor_notes_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id),
  CONSTRAINT donor_notes_content_check CHECK (length(trim(content)) > 0),
  CONSTRAINT donor_notes_type_check CHECK (
    note_type = ANY (ARRAY['general', 'call', 'email', 'issue', 'followup', 'other'])
  )
);

CREATE INDEX IF NOT EXISTS donor_notes_donor_id_idx
  ON public.donor_notes (donor_id)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS donor_notes_station_id_idx
  ON public.donor_notes (station_id)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS donor_notes_created_by_idx
  ON public.donor_notes (created_by)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS donor_notes_created_at_idx
  ON public.donor_notes (donor_id, created_at DESC)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS donor_notes_deleted_at_idx
  ON public.donor_notes (deleted_at)
  WHERE deleted_at IS NULL;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Auto-update updated_at for tags
CREATE TRIGGER set_tags_updated_at
  BEFORE UPDATE ON tags
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Auto-update updated_at for donor_notes
CREATE TRIGGER set_donor_notes_updated_at
  BEFORE UPDATE ON donor_notes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- =============================================================================
-- RLS POLICIES
-- =============================================================================

-- Enable RLS
ALTER TABLE public.tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donor_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donor_notes ENABLE ROW LEVEL SECURITY;

-- Tags: Staff can read tags for their station
CREATE POLICY "tags_select_station" ON public.tags
  FOR SELECT
  USING (
    station_id IN (
      SELECT station_id FROM profiles WHERE id = auth.uid() AND deleted_at IS NULL
    )
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin' AND deleted_at IS NULL
    )
  );

-- Tags: Admin/ops can create tags
CREATE POLICY "tags_insert_staff" ON public.tags
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND (role IN ('super_admin', 'admin', 'ops'))
        AND deleted_at IS NULL
        AND (station_id = tags.station_id OR role = 'super_admin')
    )
  );

-- Tags: Admin can update tags
CREATE POLICY "tags_update_admin" ON public.tags
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND role IN ('super_admin', 'admin')
        AND deleted_at IS NULL
        AND (station_id = tags.station_id OR role = 'super_admin')
    )
  );

-- Tags: Admin can delete (soft) tags
CREATE POLICY "tags_delete_admin" ON public.tags
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND role IN ('super_admin', 'admin')
        AND deleted_at IS NULL
        AND (station_id = tags.station_id OR role = 'super_admin')
    )
  );

-- Donor_tags: Staff can read donor tags for donors in their station
CREATE POLICY "donor_tags_select_station" ON public.donor_tags
  FOR SELECT
  USING (
    donor_id IN (
      SELECT d.id FROM donors d
      JOIN profiles p ON p.station_id = d.station_id
      WHERE p.id = auth.uid() AND p.deleted_at IS NULL AND d.deleted_at IS NULL
    )
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin' AND deleted_at IS NULL
    )
  );

-- Donor_tags: Ops/admin can add tags to donors
CREATE POLICY "donor_tags_insert_staff" ON public.donor_tags
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN donors d ON d.station_id = p.station_id OR p.role = 'super_admin'
      WHERE p.id = auth.uid()
        AND p.role IN ('super_admin', 'admin', 'ops')
        AND p.deleted_at IS NULL
        AND d.id = donor_tags.donor_id
        AND d.deleted_at IS NULL
    )
  );

-- Donor_tags: Ops/admin can remove tags from donors
CREATE POLICY "donor_tags_delete_staff" ON public.donor_tags
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN donors d ON d.station_id = p.station_id OR p.role = 'super_admin'
      WHERE p.id = auth.uid()
        AND p.role IN ('super_admin', 'admin', 'ops')
        AND p.deleted_at IS NULL
        AND d.id = donor_tags.donor_id
    )
  );

-- Donor_notes: Staff can read notes for donors in their station
CREATE POLICY "donor_notes_select_station" ON public.donor_notes
  FOR SELECT
  USING (
    station_id IN (
      SELECT station_id FROM profiles WHERE id = auth.uid() AND deleted_at IS NULL
    )
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin' AND deleted_at IS NULL
    )
  );

-- Donor_notes: All staff except donor role can add notes
CREATE POLICY "donor_notes_insert_staff" ON public.donor_notes
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND role IN ('super_admin', 'admin', 'ops', 'volunteer')
        AND deleted_at IS NULL
        AND (station_id = donor_notes.station_id OR role = 'super_admin')
    )
  );

-- Donor_notes: Only note creator or admin can update (soft delete)
CREATE POLICY "donor_notes_update_owner" ON public.donor_notes
  FOR UPDATE
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND role IN ('super_admin', 'admin')
        AND deleted_at IS NULL
        AND (station_id = donor_notes.station_id OR role = 'super_admin')
    )
  );

-- =============================================================================
-- SEED DATA: Common donor tags
-- =============================================================================

-- Insert some default tags for KPFK station
INSERT INTO public.tags (station_id, name, color, description)
SELECT
  s.id,
  t.name,
  t.color,
  t.description
FROM stations s
CROSS JOIN (VALUES
  ('VIP', '#8b5cf6', 'High-value or long-term donor requiring special attention'),
  ('Major Donor', '#3b82f6', 'Donor with significant giving history'),
  ('Sustainer', '#10b981', 'Monthly recurring donor'),
  ('Lapsed', '#f59e0b', 'Previously active donor who has stopped giving'),
  ('New Donor', '#06b6d4', 'First-time donor'),
  ('Volunteer', '#ec4899', 'Has volunteered for the station'),
  ('Board Member', '#6366f1', 'Current or former board member'),
  ('Staff', '#64748b', 'Current or former staff member'),
  ('Do Not Contact', '#ef4444', 'Has requested no contact')
) AS t(name, color, description)
WHERE s.code = 'KPFK'
ON CONFLICT DO NOTHING;

-- =============================================================================
-- COMMENT ON TABLES
-- =============================================================================

COMMENT ON TABLE public.tags IS 'Station-scoped tags for donor segmentation';
COMMENT ON TABLE public.donor_tags IS 'Junction table linking donors to tags';
COMMENT ON TABLE public.donor_notes IS 'Staff notes on donor records for CRM';

COMMENT ON COLUMN public.tags.color IS 'Hex color code for UI display (e.g., #3b82f6)';
COMMENT ON COLUMN public.donor_notes.note_type IS 'Category of note: general, call, email, issue, followup, other';
