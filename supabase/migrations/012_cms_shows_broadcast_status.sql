-- Migration 012: Broadcast Status on Shows
-- Adds broadcast_status enum, status_note, returns_at, schedule_note columns.

-- Add broadcast_status column with enum constraint
ALTER TABLE cms_shows
  ADD COLUMN broadcast_status text NOT NULL DEFAULT 'active'
    CHECK (broadcast_status IN ('active', 'hiatus', 'online_only', 'retired'));

-- Free text displayed publicly where the schedule badge would go
ALTER TABLE cms_shows
  ADD COLUMN status_note text;

-- If set and status is 'hiatus', template shows "Returning [date]"
ALTER TABLE cms_shows
  ADD COLUMN returns_at date;

-- Manual schedule context displayed below the auto-generated schedule badge
ALTER TABLE cms_shows
  ADD COLUMN schedule_note text;

-- Index for filtering by broadcast status
CREATE INDEX idx_cms_shows_broadcast_status
  ON cms_shows(station_id, broadcast_status) WHERE deleted_at IS NULL;
