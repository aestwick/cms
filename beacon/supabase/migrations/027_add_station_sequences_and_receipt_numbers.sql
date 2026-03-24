-- ============================================================================
-- Migration 027: Add Station Sequences and Receipt Numbers
-- ============================================================================
-- Creates station_sequences table for atomic receipt number generation
-- and adds receipt_number column to tax_documents table.
--
-- Receipt number format: CALLSIGN-YY-NNNNN (e.g., KPFK-26-00001)
-- Sequential within each station per calendar year, resets annually.
-- Uses a Postgres RPC function with advisory locks for atomicity —
-- guarantees no two tax documents can get the same receipt number,
-- even under concurrent webhook processing.
--
-- Why advisory locks instead of SELECT FOR UPDATE:
--   Advisory locks are lighter-weight and don't require row-level locks
--   on the sequence table. They prevent deadlocks when multiple webhook
--   handlers fire simultaneously for the same station.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STATION_SEQUENCES: Tracks the next receipt number per station per year
-- ----------------------------------------------------------------------------
-- Each row represents a counter for one station in one calendar year.
-- The current_value column holds the LAST assigned number (starts at 0).
create table station_sequences (
    id              uuid primary key default gen_random_uuid(),
    station_id      uuid not null references stations(id),
    sequence_year   integer not null,         -- e.g., 2026
    current_value   integer not null default 0,  -- last assigned number
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),

    -- One row per station per year — enforced by unique constraint
    constraint station_sequences_station_year_unique
        unique (station_id, sequence_year)
);

-- Index for fast lookups by station + year
create index idx_station_sequences_station_year
    on station_sequences(station_id, sequence_year);

-- Auto-update updated_at on changes
create trigger station_sequences_updated_at
    before update on station_sequences
    for each row
    execute function update_updated_at();

-- ----------------------------------------------------------------------------
-- ADD RECEIPT_NUMBER TO TAX_DOCUMENTS
-- ----------------------------------------------------------------------------
-- Unique per tax document. Format: KPFK-26-00001
-- Nullable because existing tax documents don't have receipt numbers yet.
alter table tax_documents
    add column receipt_number text;

-- Unique constraint on receipt_number (allows nulls — Postgres unique ignores nulls)
alter table tax_documents
    add constraint tax_documents_receipt_number_unique
    unique (receipt_number);

-- Index for lookups by receipt number
create index idx_tax_documents_receipt_number
    on tax_documents(receipt_number)
    where receipt_number is not null;

-- ----------------------------------------------------------------------------
-- RPC FUNCTION: generate_receipt_number
-- ----------------------------------------------------------------------------
-- Atomically generates the next receipt number for a station.
-- Uses an advisory lock keyed on station_id to prevent concurrent duplicates.
-- Returns the formatted receipt number string (e.g., 'KPFK-26-00001').
--
-- Parameters:
--   p_station_id: UUID of the station
--
-- How it works:
--   1. Acquires an advisory lock unique to this station (prevents races)
--   2. Gets or creates the sequence row for this station + current year
--   3. Increments the counter atomically
--   4. Looks up the station's call_sign for the prefix
--   5. Returns formatted receipt number
create or replace function generate_receipt_number(p_station_id uuid)
returns text
language plpgsql
as $$
declare
    v_year integer;
    v_next_value integer;
    v_call_sign text;
    v_lock_key bigint;
begin
    -- Current year (based on UTC)
    v_year := extract(year from now() at time zone 'UTC')::integer;

    -- Create a deterministic lock key from the station UUID.
    -- We use the first 8 bytes of the UUID hash to get a bigint.
    -- This ensures each station gets its own lock, preventing contention
    -- between different stations while serializing within the same station.
    v_lock_key := ('x' || left(md5(p_station_id::text || v_year::text), 15))::bit(60)::bigint;

    -- Advisory lock: blocks other calls for same station+year until we commit
    perform pg_advisory_xact_lock(v_lock_key);

    -- Upsert: create the sequence row if it doesn't exist, then increment
    insert into station_sequences (station_id, sequence_year, current_value)
    values (p_station_id, v_year, 1)
    on conflict (station_id, sequence_year)
    do update set
        current_value = station_sequences.current_value + 1,
        updated_at = now()
    returning current_value into v_next_value;

    -- Look up station call_sign for the prefix (e.g., 'KPFK')
    select call_sign into v_call_sign
    from stations
    where id = p_station_id;

    if v_call_sign is null then
        raise exception 'Station not found: %', p_station_id;
    end if;

    -- Format: KPFK-26-00001
    return v_call_sign || '-' || to_char(v_year % 100, 'FM00') || '-' || lpad(v_next_value::text, 5, '0');
end;
$$;

-- ----------------------------------------------------------------------------
-- PERMISSIONS
-- ----------------------------------------------------------------------------

-- Service role gets full access (webhook handlers use service role)
grant all on table station_sequences to service_role;
grant execute on function generate_receipt_number(uuid) to service_role;

-- Authenticated users can read sequences (for admin dashboards)
grant select on table station_sequences to authenticated;

-- RLS: Only service_role needs write access. Authenticated can read.
alter table station_sequences enable row level security;

create policy "station_sequences_service_role_all"
    on station_sequences
    for all
    to service_role
    using (true)
    with check (true);

create policy "station_sequences_authenticated_read"
    on station_sequences
    for select
    to authenticated
    using (true);

-- ============================================================================
-- End of Migration 027
-- ============================================================================
