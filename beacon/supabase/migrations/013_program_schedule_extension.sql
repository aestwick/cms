-- ============================================================================
-- PHASE 013: Program Schedule Extension
-- ============================================================================
-- Adds schedule time slots and external API identifiers to programs.
-- Enables auto-detection of currently airing show during pledge calls.
--
-- Why a separate schedule table?
-- Programs can air multiple times per week (e.g., Mon 6am, Wed 6am).
-- Each time slot is a row in program_schedule.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Add external_id to programs for API lookups (Spinitron, etc.)
-- ----------------------------------------------------------------------------
alter table programs add column if not exists external_id text;
alter table programs add column if not exists external_source text; -- 'spinitron', 'manual', etc.

comment on column programs.external_id is 'External API identifier (e.g., Spinitron show ID)';
comment on column programs.external_source is 'Source of external_id: spinitron, manual, etc.';

-- ----------------------------------------------------------------------------
-- program_schedule: Time slots for when programs air
-- ----------------------------------------------------------------------------
create table if not exists program_schedule (
    id              uuid primary key default gen_random_uuid(),
    program_id      uuid not null references programs(id) on delete cascade,

    -- Day of week: 0=Sunday, 1=Monday, ..., 6=Saturday (matches JS Date.getDay())
    day_of_week     smallint not null check (day_of_week >= 0 and day_of_week <= 6),

    -- Time in station's local timezone (stored as time without timezone)
    -- Actual timezone comes from stations.timezone
    start_time      time not null,
    end_time        time not null,

    -- Duration in minutes (denormalized for easy queries)
    -- Can span midnight if end_time < start_time
    duration_minutes integer not null check (duration_minutes > 0),

    -- Is this the regular slot or a special/temporary one?
    is_regular      boolean not null default true,

    -- Optional notes: "Summer schedule", "Alternates with X", etc.
    notes           text,

    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),

    -- Prevent duplicate slots for same program/day/time
    unique (program_id, day_of_week, start_time)
);

-- ----------------------------------------------------------------------------
-- Indexes
-- ----------------------------------------------------------------------------
create index if not exists idx_program_schedule_program on program_schedule(program_id);
create index if not exists idx_program_schedule_day_time on program_schedule(day_of_week, start_time);
create index if not exists idx_programs_external on programs(external_source, external_id)
    where external_id is not null;

-- ----------------------------------------------------------------------------
-- Helper function: Get currently airing program for a station
-- Usage: select * from get_current_program('kpfk');
-- ----------------------------------------------------------------------------
create or replace function get_current_program(p_station_code text)
returns table (
    program_id uuid,
    program_name text,
    program_slug text,
    start_time time,
    end_time time,
    minutes_remaining integer
) as $$
declare
    v_station_tz text;
    v_local_time time;
    v_day_of_week smallint;
begin
    -- Get station timezone
    select timezone into v_station_tz
    from stations
    where code = p_station_code;

    if v_station_tz is null then
        v_station_tz := 'America/Los_Angeles'; -- Default for KPFK
    end if;

    -- Get current local time and day in station's timezone
    v_local_time := (now() at time zone v_station_tz)::time;
    v_day_of_week := extract(dow from now() at time zone v_station_tz)::smallint;

    return query
    select
        p.id as program_id,
        p.name as program_name,
        p.slug as program_slug,
        ps.start_time,
        ps.end_time,
        -- Calculate minutes remaining (handles midnight crossing)
        case
            when ps.end_time > v_local_time then
                extract(epoch from (ps.end_time - v_local_time))::integer / 60
            else
                extract(epoch from (ps.end_time + interval '24 hours' - v_local_time))::integer / 60
        end as minutes_remaining
    from programs p
    join program_schedule ps on ps.program_id = p.id
    join stations s on s.id = p.station_id
    where s.code = p_station_code
      and p.deleted_at is null
      and p.is_active = true
      and ps.day_of_week = v_day_of_week
      and ps.is_regular = true
      -- Time is within the slot (handles midnight crossing)
      and (
          (ps.start_time <= ps.end_time and v_local_time >= ps.start_time and v_local_time < ps.end_time)
          or
          (ps.start_time > ps.end_time and (v_local_time >= ps.start_time or v_local_time < ps.end_time))
      )
    limit 1;
end;
$$ language plpgsql stable;

-- ============================================================================
-- End of Phase 013
-- ============================================================================
