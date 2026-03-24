-- Migration 061: Workflow review timelog tables
-- Staff log activities in 30-minute blocks during a one-week pilot review.
-- All reads/writes go through API routes with service role key — RLS denies all direct client access.

-- Table: time_entries
-- Each row is one time slot for one staff member on one day.
-- Upsert on (staff_slug, week_of, day_index, time_slot) — one entry per slot.
CREATE TABLE time_entries (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  staff_slug text NOT NULL,
  staff_name text NOT NULL,
  week_of date NOT NULL,
  day_index smallint NOT NULL,       -- 0=Mon ... 6=Sun
  time_slot time NOT NULL,           -- '09:00:00', '09:15:00', '09:30:00', '09:45:00'
  activity text NOT NULL DEFAULT '',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE UNIQUE INDEX idx_time_entries_unique
  ON time_entries (staff_slug, week_of, day_index, time_slot);
CREATE INDEX idx_time_entries_week ON time_entries (week_of);
CREATE INDEX idx_time_entries_staff_week ON time_entries (staff_slug, week_of);

-- Table: time_entries_history
-- Append-only audit trail. Trigger logs every INSERT, UPDATE, DELETE on time_entries.
CREATE TABLE time_entries_history (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  entry_id uuid NOT NULL,
  staff_slug text NOT NULL,
  staff_name text NOT NULL,
  week_of date NOT NULL,
  day_index smallint NOT NULL,
  time_slot time NOT NULL,
  activity text,
  action text NOT NULL,              -- 'INSERT', 'UPDATE', or 'DELETE'
  changed_at timestamptz DEFAULT now()
);

CREATE INDEX idx_history_entry ON time_entries_history (entry_id);
CREATE INDEX idx_history_staff ON time_entries_history (staff_slug, week_of);

-- Table: day_submissions
-- Logged each time a staff member clicks "Submit [Day]". Multiple per day allowed.
CREATE TABLE day_submissions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  staff_slug text NOT NULL,
  staff_name text NOT NULL,
  week_of date NOT NULL,
  day_index smallint NOT NULL,
  submitted_at timestamptz DEFAULT now(),
  client_ip text,
  location_match text NOT NULL DEFAULT 'unknown'
    CHECK (location_match IN ('station', 'remote', 'unknown'))
);

CREATE INDEX idx_submissions_staff ON day_submissions (staff_slug, week_of);

-- Trigger: log every change to time_entries into the history table.
-- Fires BEFORE so it can set updated_at on the NEW row.
CREATE OR REPLACE FUNCTION log_time_entry_change()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    INSERT INTO time_entries_history
      (entry_id, staff_slug, staff_name, week_of, day_index, time_slot, activity, action)
    VALUES
      (OLD.id, OLD.staff_slug, OLD.staff_name, OLD.week_of, OLD.day_index, OLD.time_slot, OLD.activity, 'DELETE');
    RETURN OLD;
  END IF;

  NEW.updated_at = now();

  INSERT INTO time_entries_history
    (entry_id, staff_slug, staff_name, week_of, day_index, time_slot, activity, action)
  VALUES
    (NEW.id, NEW.staff_slug, NEW.staff_name, NEW.week_of, NEW.day_index, NEW.time_slot, NEW.activity, TG_OP);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_time_entry_audit
  BEFORE INSERT OR UPDATE OR DELETE ON time_entries
  FOR EACH ROW EXECUTE FUNCTION log_time_entry_change();

-- RLS: enabled but no policies — anon/authenticated get denied by default.
-- Service role bypasses RLS entirely. No deny-all policies needed (they
-- actually block service_role too, which caused the original permission error).
ALTER TABLE time_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_entries_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE day_submissions ENABLE ROW LEVEL SECURITY;

-- Grant table-level access to service_role (Supabase doesn't auto-grant on new tables)
GRANT ALL ON time_entries TO service_role;
GRANT ALL ON time_entries_history TO service_role;
GRANT ALL ON day_submissions TO service_role;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
