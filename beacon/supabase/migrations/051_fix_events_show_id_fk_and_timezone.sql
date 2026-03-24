-- ============================================================================
-- Migration 051: Fix events table — show_id FK + timezone default
-- ============================================================================
-- Two fixes for known issues before M3 Events & Tickets build begins:
--
-- 1. DROP events.show_id FK to legacy "shows" table.
--    Same issue fixed for donations.show_id in migration 031. The "shows"
--    table is empty/deprecated — show data lives in the "programs" table
--    (migration 009). The FK would reject valid program UUIDs. Dropping
--    the constraint; referential integrity handled in application code.
--
-- 2. REMOVE hardcoded timezone default.
--    events.timezone defaults to 'America/Los_Angeles' — violates the
--    station-info rule (never hardcode station-specific values). Changing
--    the default to read from the stations table at insert time would
--    require a trigger, so instead we keep the column but drop the default.
--    Application code must always set timezone explicitly using
--    STATION_INFO.timezone from @/lib/station-info.
-- ============================================================================

-- 1. Drop the legacy FK from events.show_id → shows(id)
--    (same pattern as migration 031 for donations.show_id)
ALTER TABLE events DROP CONSTRAINT IF EXISTS events_show_id_fkey;

-- 2. Drop the hardcoded timezone default so app code must set it explicitly
ALTER TABLE events ALTER COLUMN timezone DROP DEFAULT;

-- Tell PostgREST to pick up the schema changes
NOTIFY pgrst, 'reload schema';
