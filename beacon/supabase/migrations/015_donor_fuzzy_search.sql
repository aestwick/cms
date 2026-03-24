-- ============================================================================
-- PHASE 015: Donor Fuzzy Search with pg_trgm
-- ============================================================================
-- Enables progressive fuzzy matching for donor search.
-- Uses PostgreSQL trigram extension for similarity-based matching.
--
-- Why: ILIKE substring search fails for variations like "Danny" vs "Daniel"
-- because there's no literal substring match. Trigram similarity compares
-- the n-grams of strings to find "similar enough" matches even with typos
-- or name variations.
--
-- Progressive search strategy:
--   Level 1: ILIKE substring (exact, fast)
--   Level 2: Trigram similarity >= 0.3 (moderate fuzzy)
--   Level 3: Trigram similarity >= 0.15 + email username search (very fuzzy)
-- ============================================================================

-- Enable trigram extension for fuzzy string matching
-- This is a built-in PostgreSQL extension, available in Supabase
create extension if not exists pg_trgm;

-- ----------------------------------------------------------------------------
-- TRIGRAM INDEXES on donor names
-- ----------------------------------------------------------------------------
-- GIN indexes are best for containment queries and similarity searches
-- They index all trigrams from the text, allowing fast similarity lookups

-- Trigram index on first_name for fuzzy matching
create index if not exists donors_first_name_trgm_idx
    on donors using gin (first_name gin_trgm_ops)
    where deleted_at is null and first_name is not null;

-- Trigram index on last_name for fuzzy matching
create index if not exists donors_last_name_trgm_idx
    on donors using gin (last_name gin_trgm_ops)
    where deleted_at is null and last_name is not null;

-- Trigram index on email for fuzzy email matching (typos like gmial.com)
create index if not exists donors_email_trgm_idx
    on donors using gin (email gin_trgm_ops)
    where deleted_at is null;

-- ----------------------------------------------------------------------------
-- HELPER FUNCTION: Fuzzy donor search
-- ----------------------------------------------------------------------------
-- This function performs progressive fuzzy search, getting fuzzier if needed.
-- Returns donors ordered by best match first.
--
-- Arguments:
--   p_station_id: Station to search within
--   p_query: Search term (name or email fragment)
--   p_limit: Max results to return (default 10)
--
-- Returns: Table of matching donors with similarity scores

create or replace function search_donors_fuzzy(
    p_station_id uuid,
    p_query text,
    p_limit int default 10
)
returns table (
    id uuid,
    email text,
    first_name text,
    last_name text,
    phone text,
    created_at timestamptz,
    match_score float,
    match_level int  -- 1=exact, 2=fuzzy, 3=very fuzzy
)
language plpgsql
stable  -- Function doesn't modify data, can be optimized
as $$
declare
    v_query_lower text := lower(trim(p_query));
    v_has_results boolean := false;
begin
    -- ========================================================================
    -- LEVEL 1: ILIKE substring match (strictest, fastest)
    -- ========================================================================
    return query
    select
        d.id,
        d.email,
        d.first_name,
        d.last_name,
        d.phone,
        d.created_at,
        1.0::float as match_score,
        1 as match_level
    from donors d
    where d.station_id = p_station_id
      and d.deleted_at is null
      and (
          d.first_name ilike '%' || p_query || '%'
          or d.last_name ilike '%' || p_query || '%'
      )
    order by d.created_at desc
    limit p_limit;

    -- Check if we found any results
    if found then
        return;
    end if;

    -- ========================================================================
    -- LEVEL 2: Trigram similarity >= 0.3 (moderate fuzzy)
    -- ========================================================================
    -- This catches common typos and name variations like Danny/Daniel
    return query
    select
        d.id,
        d.email,
        d.first_name,
        d.last_name,
        d.phone,
        d.created_at,
        greatest(
            coalesce(similarity(lower(d.first_name), v_query_lower), 0),
            coalesce(similarity(lower(d.last_name), v_query_lower), 0)
        )::float as match_score,
        2 as match_level
    from donors d
    where d.station_id = p_station_id
      and d.deleted_at is null
      and (
          similarity(lower(d.first_name), v_query_lower) >= 0.3
          or similarity(lower(d.last_name), v_query_lower) >= 0.3
      )
    order by match_score desc, d.created_at desc
    limit p_limit;

    if found then
        return;
    end if;

    -- ========================================================================
    -- LEVEL 3: Very fuzzy (similarity >= 0.15 + email username search)
    -- ========================================================================
    -- Last resort: very loose matching + search in email username
    -- This catches things like "Bob" matching "Robert" via email bobby@...
    return query
    select
        d.id,
        d.email,
        d.first_name,
        d.last_name,
        d.phone,
        d.created_at,
        greatest(
            coalesce(similarity(lower(d.first_name), v_query_lower), 0),
            coalesce(similarity(lower(d.last_name), v_query_lower), 0),
            -- Also check email username (part before @)
            coalesce(similarity(split_part(lower(d.email), '@', 1), v_query_lower), 0)
        )::float as match_score,
        3 as match_level
    from donors d
    where d.station_id = p_station_id
      and d.deleted_at is null
      and (
          similarity(lower(d.first_name), v_query_lower) >= 0.15
          or similarity(lower(d.last_name), v_query_lower) >= 0.15
          or similarity(split_part(lower(d.email), '@', 1), v_query_lower) >= 0.3
          or split_part(lower(d.email), '@', 1) ilike '%' || v_query_lower || '%'
      )
    order by match_score desc, d.created_at desc
    limit p_limit;

end;
$$;

-- Grant execute permission to authenticated users (for RLS to work)
grant execute on function search_donors_fuzzy(uuid, text, int) to authenticated;
grant execute on function search_donors_fuzzy(uuid, text, int) to service_role;

-- ============================================================================
-- End of Phase 015
-- ============================================================================
