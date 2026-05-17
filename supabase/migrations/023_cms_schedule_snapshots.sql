-- Migration 023: Schedule Snapshots
-- Adobe-style history stack for the schedule grid.
-- Snapshots are captured before "big bang" operations (Confessor imports,
-- bulk reverts, manual saves) so they can be restored later.
-- Individual slot edits are tracked in cms_audit_log instead.

CREATE TABLE IF NOT EXISTS cms_schedule_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id uuid NOT NULL REFERENCES cms_stations(id),
  operation text NOT NULL CHECK (operation IN (
    'confessor_import',
    'bulk_revert',
    'manual_save',
    'pre_revert'
  )),
  description text NOT NULL,
  slot_data jsonb NOT NULL,
  slot_count integer NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES cms_profiles(id)
);

CREATE INDEX idx_cms_schedule_snapshots_station_created
  ON cms_schedule_snapshots(station_id, created_at DESC);
