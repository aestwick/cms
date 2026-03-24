-- Migration 004: Schedule Slots
-- 24/7 weekly broadcast grid. Phase 2: manually managed.

CREATE TABLE IF NOT EXISTS cms_schedule_slots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id uuid NOT NULL REFERENCES cms_stations(id),
  show_id uuid REFERENCES cms_shows(id) ON DELETE SET NULL,
  day_of_week smallint NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time time NOT NULL,
  end_time time NOT NULL,
  label text,
  is_recurring boolean NOT NULL DEFAULT true,
  effective_date date,
  expires_date date,
  confessor_synced boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Composite index for schedule grid queries
CREATE INDEX idx_cms_schedule_slots_station_day_time
  ON cms_schedule_slots(station_id, day_of_week, start_time);

-- Index for one-off override lookups
CREATE INDEX idx_cms_schedule_slots_station_effective
  ON cms_schedule_slots(station_id, effective_date)
  WHERE effective_date IS NOT NULL;

-- Index for show-based lookups
CREATE INDEX idx_cms_schedule_slots_show_id
  ON cms_schedule_slots(show_id);

CREATE TRIGGER cms_schedule_slots_updated_at
  BEFORE UPDATE ON cms_schedule_slots
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
