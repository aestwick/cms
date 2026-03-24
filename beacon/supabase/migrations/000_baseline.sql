--
-- PostgreSQL database dump
--

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
-- Note: public schema always exists in Supabase, so we skip CREATE SCHEMA.
--

--
-- Name: audit_trigger_function(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.audit_trigger_function() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    v_old_data jsonb;
    v_new_data jsonb;
    v_action text;
    v_station_id uuid;
    v_user_id uuid;
BEGIN
    -- Build JSONB first, then extract station_id safely
    IF TG_OP = 'INSERT' THEN
        v_action := 'insert';
        v_old_data := NULL;
        v_new_data := to_jsonb(NEW);
        v_station_id := (v_new_data->>'station_id')::uuid;
    ELSIF TG_OP = 'UPDATE' THEN
        v_action := 'update';
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
        v_station_id := COALESCE(
            (v_new_data->>'station_id')::uuid,
            (v_old_data->>'station_id')::uuid
        );
    ELSIF TG_OP = 'DELETE' THEN
        v_action := 'delete';
        v_old_data := to_jsonb(OLD);
        v_new_data := NULL;
        v_station_id := (v_old_data->>'station_id')::uuid;
    END IF;

    v_user_id := auth.uid();

    INSERT INTO audit_log (station_id, user_id, action, table_name, record_id, old_data, new_data, created_at)
    VALUES (
        v_station_id,
        v_user_id,
        v_action,
        TG_TABLE_NAME,
        COALESCE(
            (v_new_data->>'id')::uuid,
            (v_old_data->>'id')::uuid
        ),
        v_old_data,
        v_new_data,
        now()
    );

    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$;


ALTER FUNCTION public.audit_trigger_function() OWNER TO postgres;

--
-- Name: generate_receipt_number(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_receipt_number(p_station_id uuid) RETURNS text
    LANGUAGE plpgsql
    AS $$
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


ALTER FUNCTION public.generate_receipt_number(p_station_id uuid) OWNER TO postgres;

--
-- Name: get_current_program(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_current_program(p_station_code text) RETURNS TABLE(program_id uuid, program_name text, program_slug text, start_time time without time zone, end_time time without time zone, minutes_remaining integer)
    LANGUAGE plpgsql STABLE
    AS $$
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
$$;


ALTER FUNCTION public.get_current_program(p_station_code text) OWNER TO postgres;

--
-- Name: get_current_user_profile(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_current_user_profile() RETURNS TABLE(id uuid, role text, station_id uuid, is_active boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    SELECT p.id, p.role, p.station_id, p.is_active
    FROM profiles p
    WHERE p.id = auth.uid()
    AND p.deleted_at IS NULL
    LIMIT 1;
$$;


ALTER FUNCTION public.get_current_user_profile() OWNER TO postgres;

--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
    insert into public.profiles (id, email, role, is_active)
    values (
        new.id,
        new.email,
        'donor',  -- default role; staff accounts upgraded manually
        true
    );
    return new;
end;
$$;


ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

--
-- Name: search_donors_fuzzy(uuid, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.search_donors_fuzzy(p_station_id uuid, p_query text, p_limit integer DEFAULT 10) RETURNS TABLE(id uuid, email text, first_name text, last_name text, phone text, created_at timestamp with time zone, match_score double precision, match_level integer)
    LANGUAGE plpgsql STABLE
    AS $$
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


ALTER FUNCTION public.search_donors_fuzzy(p_station_id uuid, p_query text, p_limit integer) OWNER TO postgres;

--
-- Name: update_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION public.update_updated_at() OWNER TO postgres;

--
-- Name: audit_profiles_trigger_function(); Type: FUNCTION; Schema: public; Owner: postgres
-- Specialized audit trigger for profiles table (has station_id directly).
-- Separated from generic audit_trigger_function because profiles.station_id
-- is nullable and accessed differently.
--

CREATE FUNCTION public.audit_profiles_trigger_function() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    v_old_data jsonb;
    v_new_data jsonb;
    v_action text;
    v_station_id uuid;
    v_user_id uuid;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_action := 'insert';
        v_old_data := NULL;
        v_new_data := to_jsonb(NEW);
        v_station_id := NEW.station_id;
    ELSIF TG_OP = 'UPDATE' THEN
        v_action := 'update';
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
        v_station_id := COALESCE(NEW.station_id, OLD.station_id);
    ELSIF TG_OP = 'DELETE' THEN
        v_action := 'delete';
        v_old_data := to_jsonb(OLD);
        v_new_data := NULL;
        v_station_id := OLD.station_id;
    END IF;

    v_user_id := auth.uid();

    INSERT INTO audit_log (station_id, user_id, action, table_name, record_id, old_data, new_data, created_at)
    VALUES (
        v_station_id,
        v_user_id,
        v_action,
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        v_old_data,
        v_new_data,
        now()
    );

    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$;


ALTER FUNCTION public.audit_profiles_trigger_function() OWNER TO postgres;

--
-- Name: audit_fulfillment_trigger_function(); Type: FUNCTION; Schema: public; Owner: postgres
-- Specialized audit trigger for fulfillment_items table. This table doesn't
-- have station_id directly — it gets it by joining to the parent donation.
--

CREATE FUNCTION public.audit_fulfillment_trigger_function() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    v_old_data jsonb;
    v_new_data jsonb;
    v_action text;
    v_station_id uuid;
    v_user_id uuid;
    v_record_id uuid;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_action := 'insert';
        v_old_data := NULL;
        v_new_data := to_jsonb(NEW);
        v_record_id := NEW.id;
        SELECT station_id INTO v_station_id FROM donations WHERE id = NEW.donation_id;
    ELSIF TG_OP = 'UPDATE' THEN
        v_action := 'update';
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
        v_record_id := NEW.id;
        SELECT station_id INTO v_station_id FROM donations WHERE id = NEW.donation_id;
    ELSIF TG_OP = 'DELETE' THEN
        v_action := 'delete';
        v_old_data := to_jsonb(OLD);
        v_new_data := NULL;
        v_record_id := OLD.id;
        SELECT station_id INTO v_station_id FROM donations WHERE id = OLD.donation_id;
    END IF;

    v_user_id := auth.uid();

    INSERT INTO audit_log (station_id, user_id, action, table_name, record_id, old_data, new_data, created_at)
    VALUES (
        v_station_id,
        v_user_id,
        v_action,
        TG_TABLE_NAME,
        v_record_id,
        v_old_data,
        v_new_data,
        now()
    );

    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$;


ALTER FUNCTION public.audit_fulfillment_trigger_function() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: addresses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.addresses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    donor_id uuid NOT NULL,
    address_type text DEFAULT 'shipping'::text NOT NULL,
    label text,
    recipient_name text,
    recipient_email text,
    recipient_phone text,
    street_line_1 text NOT NULL,
    street_line_2 text,
    city text NOT NULL,
    state text NOT NULL,
    postal_code text NOT NULL,
    country text DEFAULT 'US'::text NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    is_verified boolean DEFAULT false NOT NULL,
    verified_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT addresses_type_check CHECK ((address_type = ANY (ARRAY['billing'::text, 'shipping'::text, 'gift_recipient'::text])))
);


ALTER TABLE public.addresses OWNER TO postgres;

--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid,
    user_id uuid,
    action text NOT NULL,
    table_name text NOT NULL,
    record_id uuid,
    old_data jsonb,
    new_data jsonb,
    ip_address inet,
    user_agent text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.audit_log OWNER TO postgres;

--
-- Name: campaign_shows; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_shows (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    campaign_id uuid NOT NULL,
    show_id uuid NOT NULL,
    goal_cents bigint,
    station_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT campaign_shows_goal_cents_check CHECK ((goal_cents >= 0))
);


ALTER TABLE public.campaign_shows OWNER TO postgres;

--
-- Name: campaigns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaigns (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    campaign_type text DEFAULT 'fund_drive'::text NOT NULL,
    description text,
    starts_at timestamp with time zone,
    ends_at timestamp with time zone,
    goal_cents bigint,
    goal_donors integer,
    goal_sustainers integer,
    is_active boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT campaigns_goal_cents_check CHECK (((goal_cents IS NULL) OR (goal_cents >= 0)))
);


ALTER TABLE public.campaigns OWNER TO postgres;

--
-- Name: checkout_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.checkout_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    stripe_checkout_session_id text,
    mode text NOT NULL,
    operator_id uuid,
    status text DEFAULT 'pending'::text NOT NULL,
    donor_snapshot jsonb DEFAULT '{}'::jsonb NOT NULL,
    donation_snapshot jsonb DEFAULT '{}'::jsonb NOT NULL,
    donor_id uuid,
    donation_id uuid,
    expires_at timestamp with time zone,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT checkout_sessions_mode_check CHECK ((mode = ANY (ARRAY['web'::text, 'phone_card'::text, 'phone_check'::text, 'phone_cash'::text]))),
    CONSTRAINT checkout_sessions_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'completed'::text, 'expired'::text, 'cancelled'::text, 'failed'::text])))
);


ALTER TABLE public.checkout_sessions OWNER TO postgres;

--
-- Name: documents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    donor_id uuid,
    station_id uuid NOT NULL,
    uploaded_by uuid NOT NULL,
    document_type text NOT NULL,
    title text NOT NULL,
    description text,
    file_url text NOT NULL,
    file_name text NOT NULL,
    file_size_bytes bigint,
    mime_type text,
    effective_date date,
    expiration_date date,
    signed_date date,
    signed_by text[],
    visibility_level text DEFAULT 'station'::text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    supersedes_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT documents_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'active'::text, 'expired'::text, 'superseded'::text]))),
    CONSTRAINT documents_type_check CHECK ((document_type = ANY (ARRAY['contract'::text, 'bequest'::text, 'mou'::text, 'sponsorship'::text, 'correspondence'::text, 'tax_document'::text, 'other'::text]))),
    CONSTRAINT documents_visibility_check CHECK ((visibility_level = ANY (ARRAY['station'::text, 'admin_only'::text, 'super_admin_only'::text])))
);


ALTER TABLE public.documents OWNER TO postgres;

--
-- Name: donation_inspirations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.donation_inspirations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    donation_id uuid NOT NULL,
    program_id uuid,
    host_id uuid,
    category_id uuid,
    raw_value text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.donation_inspirations OWNER TO postgres;

--
-- Name: donations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.donations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    donor_id uuid NOT NULL,
    station_id uuid NOT NULL,
    checkout_session_id uuid,
    campaign_id uuid,
    show_id uuid,
    gift_id uuid,
    amount_cents bigint NOT NULL,
    fee_coverage_cents bigint DEFAULT 0 NOT NULL,
    currency text DEFAULT 'usd'::text NOT NULL,
    payment_provider text NOT NULL,
    payment_method_type text,
    stripe_payment_intent_id text,
    check_number text,
    status text DEFAULT 'pending'::text NOT NULL,
    operator_id uuid,
    source_code text,
    utm_source text,
    utm_medium text,
    utm_campaign text,
    referrer_url text,
    received_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    comments text,
    source_type text DEFAULT 'web'::text,
    gift_variant_id uuid,
    recipient_donor_id uuid,
    is_first_donation boolean DEFAULT false,
    pledged_at timestamp with time zone,
    payment_due_at timestamp with time zone,
    CONSTRAINT donations_amount_cents_check CHECK ((amount_cents > 0)),
    CONSTRAINT donations_currency_check CHECK ((currency = 'usd'::text)),
    CONSTRAINT donations_fee_coverage_cents_check CHECK ((fee_coverage_cents >= 0)),
    CONSTRAINT donations_payment_provider_check CHECK ((payment_provider = ANY (ARRAY['stripe'::text, 'check'::text, 'cash'::text]))),
    CONSTRAINT donations_status_check CHECK ((status = ANY (ARRAY['pledged'::text, 'pending'::text, 'processing'::text, 'succeeded'::text, 'failed'::text, 'refunded'::text, 'partially_refunded'::text, 'disputed'::text])))
);


ALTER TABLE public.donations OWNER TO postgres;

--
-- Name: donor_extensions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.donor_extensions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    donor_id uuid NOT NULL,
    donor_type text DEFAULT 'standard'::text NOT NULL,
    relationship_owner_id uuid,
    secondary_owner_id uuid,
    estimated_capacity_cents bigint,
    capacity_source text,
    risk_level text DEFAULT 'none'::text,
    risk_notes text,
    last_contact_date date,
    last_gift_date date,
    total_lifetime_cents bigint DEFAULT 0 NOT NULL,
    largest_gift_cents bigint,
    contact_preferences jsonb DEFAULT '{}'::jsonb NOT NULL,
    recognition_preferences jsonb DEFAULT '{}'::jsonb NOT NULL,
    vip_flag boolean DEFAULT false NOT NULL,
    board_member boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT donor_extensions_risk_check CHECK ((risk_level = ANY (ARRAY['none'::text, 'low'::text, 'medium'::text, 'high'::text]))),
    CONSTRAINT donor_extensions_type_check CHECK ((donor_type = ANY (ARRAY['standard'::text, 'major'::text, 'planned_giving'::text, 'corporate'::text, 'foundation'::text])))
);


ALTER TABLE public.donor_extensions OWNER TO postgres;

--
-- Name: donor_notes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.donor_notes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    donor_id uuid NOT NULL,
    author_id uuid,
    note_type text DEFAULT 'internal'::text NOT NULL,
    subject text,
    body text NOT NULL,
    supersedes_id uuid,
    is_pinned boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT donor_notes_type_check CHECK ((note_type = ANY (ARRAY['internal'::text, 'donor_visible'::text, 'system'::text])))
);


ALTER TABLE public.donor_notes OWNER TO postgres;

--
-- Name: donor_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.donor_tags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    donor_id uuid NOT NULL,
    tag text NOT NULL,
    applied_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.donor_tags OWNER TO postgres;

--
-- Name: donors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.donors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    email text NOT NULL,
    email_normalized text NOT NULL,
    first_name text,
    last_name text,
    phone text,
    stripe_customer_id text,
    preferences jsonb DEFAULT '{}'::jsonb NOT NULL,
    source text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.donors OWNER TO postgres;

--
-- Name: email_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    donor_id uuid,
    donation_id uuid,
    template_name text NOT NULL,
    template_version text,
    recipient_email text NOT NULL,
    subject text,
    external_id text,
    status text DEFAULT 'pending'::text NOT NULL,
    status_detail text,
    sent_at timestamp with time zone,
    delivered_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT email_log_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'sent'::text, 'delivered'::text, 'bounced'::text, 'failed'::text])))
);


ALTER TABLE public.email_log OWNER TO postgres;

--
-- Name: event_registration_gifts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.event_registration_gifts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    registration_id uuid NOT NULL,
    gift_variant_id uuid NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    fulfillment_item_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.event_registration_gifts OWNER TO postgres;

--
-- Name: event_registrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.event_registrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid NOT NULL,
    ticket_type_id uuid NOT NULL,
    donor_id uuid,
    donation_id uuid,
    attendee_name text NOT NULL,
    attendee_email text NOT NULL,
    attendee_phone text,
    quantity integer DEFAULT 1 NOT NULL,
    unit_price_cents bigint NOT NULL,
    total_cents bigint NOT NULL,
    promo_code_id uuid,
    discount_cents bigint DEFAULT 0 NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    confirmed_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    checked_in boolean DEFAULT false NOT NULL,
    checked_in_at timestamp with time zone,
    checked_in_by uuid,
    special_requests text,
    internal_notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT event_registrations_discount_cents_check CHECK ((discount_cents >= 0)),
    CONSTRAINT event_registrations_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'cancelled'::text, 'refunded'::text, 'waitlisted'::text]))),
    CONSTRAINT event_registrations_total_cents_check CHECK ((total_cents >= 0)),
    CONSTRAINT event_registrations_unit_price_cents_check CHECK ((unit_price_cents >= 0))
);


ALTER TABLE public.event_registrations OWNER TO postgres;

--
-- Name: events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    campaign_id uuid,
    show_id uuid,
    name text NOT NULL,
    slug text NOT NULL,
    description text,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone,
    doors_open_at timestamp with time zone,
    timezone text DEFAULT 'America/Los_Angeles'::text NOT NULL,
    venue_name text,
    venue_address text,
    venue_city text,
    venue_state text,
    venue_postal text,
    is_virtual boolean DEFAULT false NOT NULL,
    virtual_url text,
    total_capacity integer,
    status text DEFAULT 'draft'::text NOT NULL,
    published_at timestamp with time zone,
    registration_opens_at timestamp with time zone,
    registration_closes_at timestamp with time zone,
    allow_waitlist boolean DEFAULT false NOT NULL,
    image_url text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT events_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'published'::text, 'cancelled'::text, 'completed'::text])))
);


ALTER TABLE public.events OWNER TO postgres;

--
-- Name: feedback_responses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.feedback_responses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    donor_id uuid,
    donation_id uuid,
    membership_id uuid,
    fulfillment_item_id uuid,
    form_type text NOT NULL,
    rating integer,
    selections jsonb,
    message text,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT feedback_form_type_check CHECK ((form_type = ANY (ARRAY['donation_experience'::text, 'fulfillment_satisfaction'::text, 'cancellation'::text]))),
    CONSTRAINT feedback_rating_range CHECK (((rating IS NULL) OR ((rating >= 1) AND (rating <= 5))))
);


ALTER TABLE public.feedback_responses OWNER TO postgres;

--
-- Name: fulfillment_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fulfillment_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    donation_id uuid NOT NULL,
    gift_variant_id uuid NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    address_id uuid,
    address_snapshot jsonb,
    assigned_to uuid,
    assigned_at timestamp with time zone,
    status text DEFAULT 'pending'::text NOT NULL,
    carrier text,
    tracking_number text,
    tracking_url text,
    processing_at timestamp with time zone,
    shipped_at timestamp with time zone,
    delivered_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    cancellation_reason text,
    internal_notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT fulfillment_items_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'assigned'::text, 'processing'::text, 'shipped'::text, 'delivered'::text, 'cancelled'::text])))
);


ALTER TABLE public.fulfillment_items OWNER TO postgres;

--
-- Name: gift_campaigns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gift_campaigns (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    gift_id uuid NOT NULL,
    campaign_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.gift_campaigns OWNER TO postgres;

--
-- Name: gift_intents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gift_intents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    donor_id uuid NOT NULL,
    station_id uuid NOT NULL,
    recorded_by uuid NOT NULL,
    intent_type text NOT NULL,
    stated_amount_cents bigint,
    stated_amount_range text,
    expected_date date,
    expected_timeframe text,
    evidence_type text NOT NULL,
    evidence_date date NOT NULL,
    evidence_notes text,
    confidence_level text DEFAULT 'low'::text NOT NULL,
    has_restrictions boolean DEFAULT false NOT NULL,
    restriction_details text,
    document_id uuid,
    supersedes_id uuid,
    superseded_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT gift_intents_confidence_check CHECK ((confidence_level = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text, 'confirmed'::text]))),
    CONSTRAINT gift_intents_evidence_type_check CHECK ((evidence_type = ANY (ARRAY['verbal'::text, 'written'::text, 'email'::text, 'signed_agreement'::text]))),
    CONSTRAINT gift_intents_type_check CHECK ((intent_type = ANY (ARRAY['major_gift'::text, 'bequest'::text, 'planned_gift'::text, 'restricted_gift'::text, 'pledge'::text, 'sponsorship'::text])))
);


ALTER TABLE public.gift_intents OWNER TO postgres;

--
-- Name: gift_programs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gift_programs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    gift_id uuid NOT NULL,
    program_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.gift_programs OWNER TO postgres;

--
-- Name: TABLE gift_programs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.gift_programs IS 'Links gifts to specific programs (show-specific premiums)';


--
-- Name: gift_variants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gift_variants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    gift_id uuid NOT NULL,
    name text NOT NULL,
    sku text,
    inventory_count integer,
    low_stock_threshold integer,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.gift_variants OWNER TO postgres;

--
-- Name: gifts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gifts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    category text,
    fmv_cents bigint DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    requires_shipping boolean DEFAULT true NOT NULL,
    static_id text,
    cogs_cents bigint DEFAULT 0 NOT NULL,
    minimum_cents_onetime bigint DEFAULT 0 NOT NULL,
    minimum_cents_monthly bigint DEFAULT 0 NOT NULL,
    image_url text,
    is_featured boolean DEFAULT false NOT NULL,
    is_exclusive boolean DEFAULT false NOT NULL,
    is_hidden boolean DEFAULT false NOT NULL,
    no_recurring boolean DEFAULT false NOT NULL,
    expires_at timestamp with time zone,
    fulfillment_method text DEFAULT 'ship'::text NOT NULL,
    CONSTRAINT gifts_cogs_cents_check CHECK ((cogs_cents >= 0)),
    CONSTRAINT gifts_fmv_cents_check CHECK ((fmv_cents >= 0)),
    CONSTRAINT gifts_fulfillment_method_check CHECK ((fulfillment_method = ANY (ARRAY['ship'::text, 'will_call'::text, 'digital'::text, 'none'::text]))),
    CONSTRAINT gifts_minimum_cents_monthly_check CHECK ((minimum_cents_monthly >= 0)),
    CONSTRAINT gifts_minimum_cents_onetime_check CHECK ((minimum_cents_onetime >= 0))
);


ALTER TABLE public.gifts OWNER TO postgres;

--
-- Name: COLUMN gifts.requires_shipping; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.gifts.requires_shipping IS 'Whether this gift requires physical shipping/fulfillment. False for digital goods or events.';


--
-- Name: COLUMN gifts.static_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.gifts.static_id IS 'Maps to static gift catalog ID (e.g., bumper-90). Used to link form submissions to database records.';


--
-- Name: COLUMN gifts.minimum_cents_onetime; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.gifts.minimum_cents_onetime IS 'Minimum one-time donation (cents) to qualify for this gift';


--
-- Name: COLUMN gifts.minimum_cents_monthly; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.gifts.minimum_cents_monthly IS 'Minimum monthly donation (cents) to qualify for this gift';


--
-- Name: interactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.interactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    donor_id uuid NOT NULL,
    station_id uuid NOT NULL,
    staff_user_id uuid NOT NULL,
    interaction_type text NOT NULL,
    direction text DEFAULT 'outbound'::text NOT NULL,
    occurred_at timestamp with time zone NOT NULL,
    duration_minutes integer,
    subject text,
    summary text NOT NULL,
    witness_id uuid,
    requires_followup boolean DEFAULT false NOT NULL,
    followup_by timestamp with time zone,
    followup_completed boolean DEFAULT false NOT NULL,
    followup_completed_at timestamp with time zone,
    campaign_id uuid,
    gift_intent_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT interactions_direction_check CHECK ((direction = ANY (ARRAY['inbound'::text, 'outbound'::text]))),
    CONSTRAINT interactions_type_check CHECK ((interaction_type = ANY (ARRAY['phone'::text, 'in_person'::text, 'email'::text, 'voicemail'::text, 'letter'::text, 'meeting'::text, 'event'::text])))
);


ALTER TABLE public.interactions OWNER TO postgres;

--
-- Name: invites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invites (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    email text NOT NULL,
    token text NOT NULL,
    role text DEFAULT 'volunteer'::text NOT NULL,
    invited_by uuid NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT invites_role_check CHECK ((role = ANY (ARRAY['super_admin'::text, 'admin'::text, 'ops'::text, 'volunteer'::text])))
);


ALTER TABLE public.invites OWNER TO postgres;

--
-- Name: match_allocations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.match_allocations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    donation_id uuid NOT NULL,
    match_pool_id uuid NOT NULL,
    amount_cents bigint NOT NULL,
    allocated_at timestamp with time zone DEFAULT now() NOT NULL,
    allocated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT match_allocations_amount_cents_check CHECK ((amount_cents > 0))
);


ALTER TABLE public.match_allocations OWNER TO postgres;

--
-- Name: match_pools; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.match_pools (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    campaign_id uuid,
    name text NOT NULL,
    description text,
    matcher_name text,
    matcher_type text DEFAULT 'anonymous'::text NOT NULL,
    is_public boolean DEFAULT false NOT NULL,
    match_ratio numeric(5,2) DEFAULT 1.00 NOT NULL,
    total_cents bigint NOT NULL,
    remaining_cents bigint NOT NULL,
    eligibility_rules jsonb DEFAULT '{}'::jsonb NOT NULL,
    valid_from timestamp with time zone,
    valid_until timestamp with time zone,
    is_active boolean DEFAULT true NOT NULL,
    exhausted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT match_pools_matcher_type_check CHECK ((matcher_type = ANY (ARRAY['individual'::text, 'foundation'::text, 'corporate'::text, 'anonymous'::text]))),
    CONSTRAINT match_pools_remaining_cents_check CHECK ((remaining_cents >= 0)),
    CONSTRAINT match_pools_total_cents_check CHECK ((total_cents > 0))
);


ALTER TABLE public.match_pools OWNER TO postgres;

--
-- Name: memberships; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.memberships (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    donor_id uuid NOT NULL,
    station_id uuid NOT NULL,
    stripe_subscription_id text,
    tier text DEFAULT 'member'::text NOT NULL,
    amount_cents bigint NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    cancelled_at timestamp with time zone,
    lapsed_at timestamp with time zone,
    payment_failed_at timestamp with time zone,
    payment_failures_count integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    donation_id uuid,
    ends_at timestamp with time zone,
    CONSTRAINT memberships_amount_cents_check CHECK ((amount_cents > 0)),
    CONSTRAINT memberships_status_check CHECK ((status = ANY (ARRAY['active'::text, 'past_due'::text, 'paused'::text, 'cancelled'::text, 'canceled'::text, 'lapsed'::text]))),
    CONSTRAINT memberships_tier_check CHECK ((tier = ANY (ARRAY['member'::text, 'sustainer'::text, 'defender'::text])))
);


ALTER TABLE public.memberships OWNER TO postgres;

--
-- Name: operator_activity_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.operator_activity_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    operator_profile_id uuid,
    operator_email text NOT NULL,
    action text NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    ip_address text,
    user_agent text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.operator_activity_log OWNER TO postgres;

--
-- Name: TABLE operator_activity_log; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.operator_activity_log IS 'Audit log for phone pledge form actions. Captures operator email even when unauthenticated.';


--
-- Name: payment_intents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment_intents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    donor_id uuid,
    checkout_session_id uuid,
    donation_id uuid,
    stripe_payment_intent_id text NOT NULL,
    stripe_payment_method_id text,
    amount_cents integer NOT NULL,
    fee_coverage_cents integer DEFAULT 0 NOT NULL,
    currency text DEFAULT 'usd'::text NOT NULL,
    status text DEFAULT 'requires_payment_method'::text NOT NULL,
    source_type text DEFAULT 'phone'::text NOT NULL,
    operator_id uuid,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    succeeded_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT payment_intents_amount_cents_check CHECK ((amount_cents > 0)),
    CONSTRAINT payment_intents_currency_check CHECK ((currency = 'usd'::text)),
    CONSTRAINT payment_intents_fee_coverage_cents_check CHECK ((fee_coverage_cents >= 0))
);


ALTER TABLE public.payment_intents OWNER TO postgres;

--
-- Name: press_passes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.press_passes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    pass_number text NOT NULL,
    verification_token text NOT NULL,
    holder_name text NOT NULL,
    title text,
    photo_url text,
    pass_type text DEFAULT 'staff'::text,
    status text DEFAULT 'active'::text NOT NULL,
    issued_at date NOT NULL,
    expires_at date NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT press_passes_pass_type_check CHECK ((pass_type = ANY (ARRAY['staff'::text, 'talent'::text, 'producer'::text, 'leadership'::text, 'volunteer'::text]))),
    CONSTRAINT press_passes_status_check CHECK ((status = ANY (ARRAY['active'::text, 'revoked'::text, 'lost'::text, 'expired'::text])))
);


ALTER TABLE public.press_passes OWNER TO postgres;

--
-- Name: TABLE press_passes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.press_passes IS 'KPFK press credentials for verification by security/LEO';


--
-- Name: COLUMN press_passes.verification_token; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.press_passes.verification_token IS 'Random token used in QR code URLs, separate from pass_number for security';


--
-- Name: COLUMN press_passes.pass_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.press_passes.pass_type IS 'Category of credential holder: staff, talent, producer, leadership, volunteer';


--
-- Name: COLUMN press_passes.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.press_passes.status IS 'Current status: active, revoked, lost (reported stolen), expired';


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    role text DEFAULT 'volunteer'::text NOT NULL,
    station_id uuid,
    donor_id uuid,
    display_name text,
    email text NOT NULL,
    phone text,
    avatar_url text,
    requires_2fa boolean DEFAULT false NOT NULL,
    last_login_at timestamp with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT profiles_role_check CHECK ((role = ANY (ARRAY['super_admin'::text, 'admin'::text, 'ops'::text, 'volunteer'::text, 'donor'::text])))
);


ALTER TABLE public.profiles OWNER TO postgres;

--
-- Name: program_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.program_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.program_categories OWNER TO postgres;

--
-- Name: program_host_assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.program_host_assignments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    program_id uuid NOT NULL,
    host_id uuid NOT NULL,
    is_primary boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.program_host_assignments OWNER TO postgres;

--
-- Name: program_hosts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.program_hosts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    bio text,
    photo_url text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.program_hosts OWNER TO postgres;

--
-- Name: program_schedule; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.program_schedule (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    program_id uuid NOT NULL,
    day_of_week smallint NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    duration_minutes integer NOT NULL,
    is_regular boolean DEFAULT true NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT program_schedule_day_of_week_check CHECK (((day_of_week >= 0) AND (day_of_week <= 6))),
    CONSTRAINT program_schedule_duration_minutes_check CHECK ((duration_minutes > 0))
);


ALTER TABLE public.program_schedule OWNER TO postgres;

--
-- Name: programs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.programs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    category_id uuid,
    name text NOT NULL,
    slug text NOT NULL,
    description text,
    notes text,
    website_url text,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    external_id text,
    external_source text
);


ALTER TABLE public.programs OWNER TO postgres;

--
-- Name: COLUMN programs.external_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.programs.external_id IS 'External API identifier (e.g., Spinitron show ID)';


--
-- Name: COLUMN programs.external_source; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.programs.external_source IS 'Source of external_id: spinitron, manual, etc.';


--
-- Name: promo_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.promo_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    event_id uuid,
    code text NOT NULL,
    discount_type text NOT NULL,
    discount_percent integer,
    discount_cents bigint,
    max_uses integer,
    times_used integer DEFAULT 0 NOT NULL,
    max_uses_per_donor integer,
    valid_from timestamp with time zone,
    valid_until timestamp with time zone,
    is_active boolean DEFAULT true NOT NULL,
    min_purchase_cents bigint,
    applicable_ticket_type_ids uuid[],
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT promo_codes_discount_cents_check CHECK (((discount_cents IS NULL) OR (discount_cents >= 0))),
    CONSTRAINT promo_codes_discount_type_check CHECK ((discount_type = ANY (ARRAY['percent'::text, 'fixed_amount'::text, 'free'::text]))),
    CONSTRAINT promo_codes_min_purchase_cents_check CHECK (((min_purchase_cents IS NULL) OR (min_purchase_cents >= 0)))
);


ALTER TABLE public.promo_codes OWNER TO postgres;

--
-- Name: shows; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shows (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    slug text NOT NULL,
    name text NOT NULL,
    description text,
    host_name text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.shows OWNER TO postgres;

--
-- Name: station_sequences; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.station_sequences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    sequence_year integer NOT NULL,
    current_value integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.station_sequences OWNER TO postgres;

--
-- Name: stations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    call_sign text NOT NULL,
    name text NOT NULL,
    timezone text DEFAULT 'America/Los_Angeles'::text NOT NULL,
    website_url text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.stations OWNER TO postgres;

--
-- Name: system_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.system_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_type text NOT NULL,
    source text NOT NULL,
    idempotency_key text NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb,
    payload_summary text,
    status text DEFAULT 'pending'::text NOT NULL,
    error_message text,
    attempts integer DEFAULT 0 NOT NULL,
    processed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT system_events_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'processing'::text, 'completed'::text, 'failed'::text, 'skipped'::text])))
);


ALTER TABLE public.system_events OWNER TO postgres;

--
-- Name: tax_documents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tax_documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    donation_id uuid NOT NULL,
    donor_id uuid NOT NULL,
    station_id uuid NOT NULL,
    document_type text DEFAULT 'receipt'::text NOT NULL,
    snapshot_json jsonb NOT NULL,
    gross_amount_cents bigint NOT NULL,
    fmv_cents bigint DEFAULT 0 NOT NULL,
    deductible_cents bigint NOT NULL,
    supersedes_id uuid,
    superseded_at timestamp with time zone,
    generated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    receipt_number text,
    CONSTRAINT tax_documents_deductible_cents_check CHECK ((deductible_cents >= 0)),
    CONSTRAINT tax_documents_fmv_cents_check CHECK ((fmv_cents >= 0)),
    CONSTRAINT tax_documents_gross_amount_cents_check CHECK (((gross_amount_cents > 0) OR (document_type = 'correction'::text)))
);


ALTER TABLE public.tax_documents OWNER TO postgres;

--
-- Name: ticket_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ticket_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    price_cents bigint DEFAULT 0 NOT NULL,
    fmv_cents bigint DEFAULT 0 NOT NULL,
    is_sliding_scale boolean DEFAULT false NOT NULL,
    min_price_cents bigint,
    max_price_cents bigint,
    suggested_price_cents bigint,
    capacity integer,
    available_from timestamp with time zone,
    available_until timestamp with time zone,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT ticket_types_fmv_cents_check CHECK ((fmv_cents >= 0)),
    CONSTRAINT ticket_types_max_price_cents_check CHECK (((max_price_cents IS NULL) OR (max_price_cents >= 0))),
    CONSTRAINT ticket_types_min_price_cents_check CHECK (((min_price_cents IS NULL) OR (min_price_cents >= 0))),
    CONSTRAINT ticket_types_price_cents_check CHECK ((price_cents >= 0)),
    CONSTRAINT ticket_types_suggested_price_cents_check CHECK (((suggested_price_cents IS NULL) OR (suggested_price_cents >= 0)))
);


ALTER TABLE public.ticket_types OWNER TO postgres;

--
-- Name: underwriters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.underwriters (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    name text NOT NULL,
    legal_name text,
    organization_type text DEFAULT 'business'::text NOT NULL,
    tax_id text,
    contact_name text,
    contact_email text,
    contact_phone text,
    contact_title text,
    street_line_1 text,
    street_line_2 text,
    city text,
    state text,
    postal_code text,
    country text DEFAULT 'US'::text,
    billing_same_as_primary boolean DEFAULT true NOT NULL,
    billing_street_1 text,
    billing_street_2 text,
    billing_city text,
    billing_state text,
    billing_postal text,
    billing_country text,
    relationship_owner_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT underwriters_org_type_check CHECK ((organization_type = ANY (ARRAY['business'::text, 'nonprofit'::text, 'government'::text, 'individual'::text])))
);


ALTER TABLE public.underwriters OWNER TO postgres;

--
-- Name: underwriting_agreements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.underwriting_agreements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    underwriter_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    document_id uuid,
    total_value_cents bigint NOT NULL,
    starts_at date NOT NULL,
    ends_at date NOT NULL,
    payment_schedule text DEFAULT 'monthly'::text NOT NULL,
    payment_terms_days integer DEFAULT 30 NOT NULL,
    deliverables jsonb DEFAULT '{}'::jsonb NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    signed_at date,
    auto_renew boolean DEFAULT false NOT NULL,
    renewal_notice_days integer,
    internal_notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT underwriting_agreements_payment_check CHECK ((payment_schedule = ANY (ARRAY['upfront'::text, 'monthly'::text, 'quarterly'::text, 'annual'::text, 'custom'::text]))),
    CONSTRAINT underwriting_agreements_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'pending_signature'::text, 'active'::text, 'completed'::text, 'cancelled'::text])))
);


ALTER TABLE public.underwriting_agreements OWNER TO postgres;

--
-- Name: underwriting_broadcasts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.underwriting_broadcasts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    agreement_id uuid NOT NULL,
    show_id uuid,
    scheduled_at timestamp with time zone NOT NULL,
    scheduled_duration_seconds integer DEFAULT 15 NOT NULL,
    aired_at timestamp with time zone,
    actual_duration_seconds integer,
    copy_text text,
    copy_approved boolean DEFAULT false NOT NULL,
    copy_approved_at timestamp with time zone,
    copy_approved_by uuid,
    status text DEFAULT 'scheduled'::text NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT underwriting_broadcasts_status_check CHECK ((status = ANY (ARRAY['scheduled'::text, 'aired'::text, 'missed'::text, 'cancelled'::text])))
);


ALTER TABLE public.underwriting_broadcasts OWNER TO postgres;

--
-- Name: underwriting_invoices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.underwriting_invoices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    agreement_id uuid NOT NULL,
    underwriter_id uuid NOT NULL,
    invoice_number text NOT NULL,
    description text,
    subtotal_cents bigint NOT NULL,
    tax_cents bigint DEFAULT 0 NOT NULL,
    total_cents bigint NOT NULL,
    line_items jsonb DEFAULT '[]'::jsonb NOT NULL,
    invoice_date date NOT NULL,
    due_date date NOT NULL,
    period_start date,
    period_end date,
    status text DEFAULT 'draft'::text NOT NULL,
    sent_at timestamp with time zone,
    paid_at timestamp with time zone,
    paid_amount_cents bigint,
    payment_method text,
    payment_reference text,
    reminder_sent_at timestamp with time zone,
    reminders_count integer DEFAULT 0 NOT NULL,
    notes text,
    internal_notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT underwriting_invoices_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'sent'::text, 'viewed'::text, 'paid'::text, 'overdue'::text, 'void'::text, 'written_off'::text])))
);


ALTER TABLE public.underwriting_invoices OWNER TO postgres;

--
-- Name: verification_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.verification_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    press_pass_id uuid,
    lookup_type text NOT NULL,
    lookup_value text NOT NULL,
    lookup_result text NOT NULL,
    ip_address inet,
    user_agent text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT verification_logs_lookup_result_check CHECK ((lookup_result = ANY (ARRAY['valid'::text, 'not_found'::text, 'revoked'::text, 'lost'::text, 'expired'::text]))),
    CONSTRAINT verification_logs_lookup_type_check CHECK ((lookup_type = ANY (ARRAY['token'::text, 'manual'::text])))
);


ALTER TABLE public.verification_logs OWNER TO postgres;

--
-- Name: TABLE verification_logs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.verification_logs IS 'Audit trail of all press pass verification attempts';


--
-- Name: COLUMN verification_logs.lookup_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.verification_logs.lookup_type IS 'How the lookup was performed: token (QR scan) or manual (ID entry)';


--
-- Name: COLUMN verification_logs.lookup_result; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.verification_logs.lookup_result IS 'Result: valid, not_found, revoked, lost, expired';


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: campaign_shows campaign_shows_campaign_id_show_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_shows
    ADD CONSTRAINT campaign_shows_campaign_id_show_id_key UNIQUE (campaign_id, show_id);


--
-- Name: campaign_shows campaign_shows_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_shows
    ADD CONSTRAINT campaign_shows_pkey PRIMARY KEY (id);


--
-- Name: campaigns campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id);


--
-- Name: checkout_sessions checkout_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checkout_sessions
    ADD CONSTRAINT checkout_sessions_pkey PRIMARY KEY (id);


--
-- Name: checkout_sessions checkout_sessions_stripe_checkout_session_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checkout_sessions
    ADD CONSTRAINT checkout_sessions_stripe_checkout_session_id_key UNIQUE (stripe_checkout_session_id);


--
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- Name: donation_inspirations donation_inspirations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donation_inspirations
    ADD CONSTRAINT donation_inspirations_pkey PRIMARY KEY (id);


--
-- Name: donations donations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_pkey PRIMARY KEY (id);


--
-- Name: donor_extensions donor_extensions_donor_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donor_extensions
    ADD CONSTRAINT donor_extensions_donor_id_key UNIQUE (donor_id);


--
-- Name: donor_extensions donor_extensions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donor_extensions
    ADD CONSTRAINT donor_extensions_pkey PRIMARY KEY (id);


--
-- Name: donor_notes donor_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donor_notes
    ADD CONSTRAINT donor_notes_pkey PRIMARY KEY (id);


--
-- Name: donor_tags donor_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donor_tags
    ADD CONSTRAINT donor_tags_pkey PRIMARY KEY (id);


--
-- Name: donors donors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donors
    ADD CONSTRAINT donors_pkey PRIMARY KEY (id);


--
-- Name: email_log email_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_log
    ADD CONSTRAINT email_log_pkey PRIMARY KEY (id);


--
-- Name: event_registration_gifts event_registration_gifts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_registration_gifts
    ADD CONSTRAINT event_registration_gifts_pkey PRIMARY KEY (id);


--
-- Name: event_registrations event_registrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_registrations
    ADD CONSTRAINT event_registrations_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: feedback_responses feedback_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.feedback_responses
    ADD CONSTRAINT feedback_responses_pkey PRIMARY KEY (id);


--
-- Name: fulfillment_items fulfillment_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fulfillment_items
    ADD CONSTRAINT fulfillment_items_pkey PRIMARY KEY (id);


--
-- Name: gift_campaigns gift_campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_campaigns
    ADD CONSTRAINT gift_campaigns_pkey PRIMARY KEY (id);


--
-- Name: gift_campaigns gift_campaigns_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_campaigns
    ADD CONSTRAINT gift_campaigns_unique UNIQUE (gift_id, campaign_id);


--
-- Name: gift_intents gift_intents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_intents
    ADD CONSTRAINT gift_intents_pkey PRIMARY KEY (id);


--
-- Name: gift_programs gift_programs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_programs
    ADD CONSTRAINT gift_programs_pkey PRIMARY KEY (id);


--
-- Name: gift_programs gift_programs_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_programs
    ADD CONSTRAINT gift_programs_unique UNIQUE (gift_id, program_id);


--
-- Name: gift_variants gift_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_variants
    ADD CONSTRAINT gift_variants_pkey PRIMARY KEY (id);


--
-- Name: gifts gifts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gifts
    ADD CONSTRAINT gifts_pkey PRIMARY KEY (id);


--
-- Name: gifts gifts_static_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gifts
    ADD CONSTRAINT gifts_static_id_key UNIQUE (static_id);


--
-- Name: interactions interactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interactions
    ADD CONSTRAINT interactions_pkey PRIMARY KEY (id);


--
-- Name: invites invites_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invites
    ADD CONSTRAINT invites_pkey PRIMARY KEY (id);


--
-- Name: invites invites_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invites
    ADD CONSTRAINT invites_token_key UNIQUE (token);


--
-- Name: match_allocations match_allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_allocations
    ADD CONSTRAINT match_allocations_pkey PRIMARY KEY (id);


--
-- Name: match_pools match_pools_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_pools
    ADD CONSTRAINT match_pools_pkey PRIMARY KEY (id);


--
-- Name: memberships memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (id);


--
-- Name: operator_activity_log operator_activity_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operator_activity_log
    ADD CONSTRAINT operator_activity_log_pkey PRIMARY KEY (id);


--
-- Name: payment_intents payment_intents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_intents
    ADD CONSTRAINT payment_intents_pkey PRIMARY KEY (id);


--
-- Name: payment_intents payment_intents_stripe_payment_intent_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_intents
    ADD CONSTRAINT payment_intents_stripe_payment_intent_id_key UNIQUE (stripe_payment_intent_id);


--
-- Name: press_passes press_passes_pass_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.press_passes
    ADD CONSTRAINT press_passes_pass_number_key UNIQUE (pass_number);


--
-- Name: press_passes press_passes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.press_passes
    ADD CONSTRAINT press_passes_pkey PRIMARY KEY (id);


--
-- Name: press_passes press_passes_verification_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.press_passes
    ADD CONSTRAINT press_passes_verification_token_key UNIQUE (verification_token);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: program_categories program_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_categories
    ADD CONSTRAINT program_categories_pkey PRIMARY KEY (id);


--
-- Name: program_categories program_categories_station_id_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_categories
    ADD CONSTRAINT program_categories_station_id_slug_key UNIQUE (station_id, slug);


--
-- Name: program_host_assignments program_host_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_host_assignments
    ADD CONSTRAINT program_host_assignments_pkey PRIMARY KEY (id);


--
-- Name: program_host_assignments program_host_assignments_program_id_host_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_host_assignments
    ADD CONSTRAINT program_host_assignments_program_id_host_id_key UNIQUE (program_id, host_id);


--
-- Name: program_hosts program_hosts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_hosts
    ADD CONSTRAINT program_hosts_pkey PRIMARY KEY (id);


--
-- Name: program_hosts program_hosts_station_id_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_hosts
    ADD CONSTRAINT program_hosts_station_id_slug_key UNIQUE (station_id, slug);


--
-- Name: program_schedule program_schedule_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_schedule
    ADD CONSTRAINT program_schedule_pkey PRIMARY KEY (id);


--
-- Name: program_schedule program_schedule_program_id_day_of_week_start_time_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_schedule
    ADD CONSTRAINT program_schedule_program_id_day_of_week_start_time_key UNIQUE (program_id, day_of_week, start_time);


--
-- Name: programs programs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_pkey PRIMARY KEY (id);


--
-- Name: programs programs_station_id_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_station_id_slug_key UNIQUE (station_id, slug);


--
-- Name: promo_codes promo_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promo_codes
    ADD CONSTRAINT promo_codes_pkey PRIMARY KEY (id);


--
-- Name: shows shows_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shows
    ADD CONSTRAINT shows_pkey PRIMARY KEY (id);


--
-- Name: station_sequences station_sequences_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.station_sequences
    ADD CONSTRAINT station_sequences_pkey PRIMARY KEY (id);


--
-- Name: station_sequences station_sequences_station_year_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.station_sequences
    ADD CONSTRAINT station_sequences_station_year_unique UNIQUE (station_id, sequence_year);


--
-- Name: stations stations_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stations
    ADD CONSTRAINT stations_code_key UNIQUE (code);


--
-- Name: stations stations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stations
    ADD CONSTRAINT stations_pkey PRIMARY KEY (id);


--
-- Name: system_events system_events_idempotency_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_events
    ADD CONSTRAINT system_events_idempotency_key_key UNIQUE (idempotency_key);


--
-- Name: system_events system_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_events
    ADD CONSTRAINT system_events_pkey PRIMARY KEY (id);


--
-- Name: tax_documents tax_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tax_documents
    ADD CONSTRAINT tax_documents_pkey PRIMARY KEY (id);


--
-- Name: tax_documents tax_documents_receipt_number_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tax_documents
    ADD CONSTRAINT tax_documents_receipt_number_unique UNIQUE (receipt_number);


--
-- Name: ticket_types ticket_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket_types
    ADD CONSTRAINT ticket_types_pkey PRIMARY KEY (id);


--
-- Name: underwriters underwriters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.underwriters
    ADD CONSTRAINT underwriters_pkey PRIMARY KEY (id);


--
-- Name: underwriting_agreements underwriting_agreements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.underwriting_agreements
    ADD CONSTRAINT underwriting_agreements_pkey PRIMARY KEY (id);


--
-- Name: underwriting_broadcasts underwriting_broadcasts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.underwriting_broadcasts
    ADD CONSTRAINT underwriting_broadcasts_pkey PRIMARY KEY (id);


--
-- Name: underwriting_invoices underwriting_invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.underwriting_invoices
    ADD CONSTRAINT underwriting_invoices_pkey PRIMARY KEY (id);


--
-- Name: verification_logs verification_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.verification_logs
    ADD CONSTRAINT verification_logs_pkey PRIMARY KEY (id);


--
-- Name: addresses_default_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX addresses_default_idx ON public.addresses USING btree (donor_id, address_type, is_default) WHERE ((deleted_at IS NULL) AND (is_default = true));


--
-- Name: addresses_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX addresses_deleted_at_idx ON public.addresses USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: addresses_donor_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX addresses_donor_id_idx ON public.addresses USING btree (donor_id) WHERE (deleted_at IS NULL);


--
-- Name: addresses_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX addresses_type_idx ON public.addresses USING btree (donor_id, address_type) WHERE (deleted_at IS NULL);


--
-- Name: audit_log_action_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX audit_log_action_idx ON public.audit_log USING btree (action);


--
-- Name: audit_log_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX audit_log_created_at_idx ON public.audit_log USING btree (created_at);


--
-- Name: audit_log_record_history_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX audit_log_record_history_idx ON public.audit_log USING btree (table_name, record_id, created_at DESC);


--
-- Name: audit_log_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX audit_log_station_id_idx ON public.audit_log USING btree (station_id) WHERE (station_id IS NOT NULL);


--
-- Name: audit_log_table_record_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX audit_log_table_record_idx ON public.audit_log USING btree (table_name, record_id);


--
-- Name: audit_log_table_time_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX audit_log_table_time_idx ON public.audit_log USING btree (table_name, created_at);


--
-- Name: audit_log_user_time_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX audit_log_user_time_idx ON public.audit_log USING btree (user_id, created_at DESC) WHERE (user_id IS NOT NULL);


--
-- Name: campaigns_dates_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX campaigns_dates_idx ON public.campaigns USING btree (station_id, starts_at, ends_at) WHERE (deleted_at IS NULL);


--
-- Name: campaigns_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX campaigns_deleted_at_idx ON public.campaigns USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: campaigns_is_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX campaigns_is_active_idx ON public.campaigns USING btree (station_id, is_active) WHERE (deleted_at IS NULL);


--
-- Name: campaigns_station_code_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX campaigns_station_code_idx ON public.campaigns USING btree (station_id, code) WHERE (deleted_at IS NULL);


--
-- Name: campaigns_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX campaigns_station_id_idx ON public.campaigns USING btree (station_id) WHERE (deleted_at IS NULL);


--
-- Name: checkout_sessions_donation_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX checkout_sessions_donation_id_idx ON public.checkout_sessions USING btree (donation_id) WHERE (donation_id IS NOT NULL);


--
-- Name: checkout_sessions_donor_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX checkout_sessions_donor_id_idx ON public.checkout_sessions USING btree (donor_id) WHERE (donor_id IS NOT NULL);


--
-- Name: checkout_sessions_ops_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX checkout_sessions_ops_idx ON public.checkout_sessions USING btree (status, created_at DESC);


--
-- Name: checkout_sessions_pending_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX checkout_sessions_pending_idx ON public.checkout_sessions USING btree (expires_at) WHERE (status = 'pending'::text);


--
-- Name: checkout_sessions_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX checkout_sessions_station_id_idx ON public.checkout_sessions USING btree (station_id);


--
-- Name: checkout_sessions_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX checkout_sessions_status_idx ON public.checkout_sessions USING btree (station_id, status);


--
-- Name: checkout_sessions_stripe_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX checkout_sessions_stripe_id_idx ON public.checkout_sessions USING btree (stripe_checkout_session_id) WHERE (stripe_checkout_session_id IS NOT NULL);


--
-- Name: documents_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX documents_deleted_at_idx ON public.documents USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: documents_donor_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX documents_donor_id_idx ON public.documents USING btree (donor_id) WHERE ((donor_id IS NOT NULL) AND (deleted_at IS NULL));


--
-- Name: documents_effective_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX documents_effective_date_idx ON public.documents USING btree (station_id, effective_date) WHERE (deleted_at IS NULL);


--
-- Name: documents_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX documents_station_id_idx ON public.documents USING btree (station_id) WHERE (deleted_at IS NULL);


--
-- Name: documents_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX documents_status_idx ON public.documents USING btree (station_id, status) WHERE (deleted_at IS NULL);


--
-- Name: documents_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX documents_type_idx ON public.documents USING btree (station_id, document_type) WHERE (deleted_at IS NULL);


--
-- Name: documents_uploaded_by_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX documents_uploaded_by_idx ON public.documents USING btree (uploaded_by);


--
-- Name: donations_campaign_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donations_campaign_id_idx ON public.donations USING btree (campaign_id) WHERE ((deleted_at IS NULL) AND (campaign_id IS NOT NULL));


--
-- Name: donations_checkout_session_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donations_checkout_session_id_idx ON public.donations USING btree (checkout_session_id) WHERE (checkout_session_id IS NOT NULL);


--
-- Name: donations_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donations_created_at_idx ON public.donations USING btree (station_id, created_at) WHERE (deleted_at IS NULL);


--
-- Name: donations_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donations_deleted_at_idx ON public.donations USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: donations_donor_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donations_donor_id_idx ON public.donations USING btree (donor_id) WHERE (deleted_at IS NULL);


--
-- Name: donations_gift_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donations_gift_id_idx ON public.donations USING btree (gift_id) WHERE ((deleted_at IS NULL) AND (gift_id IS NOT NULL));


--
-- Name: donations_payment_provider_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donations_payment_provider_idx ON public.donations USING btree (station_id, payment_provider) WHERE (deleted_at IS NULL);


--
-- Name: donations_received_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donations_received_at_idx ON public.donations USING btree (station_id, received_at) WHERE ((deleted_at IS NULL) AND (received_at IS NOT NULL));


--
-- Name: donations_show_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donations_show_id_idx ON public.donations USING btree (show_id) WHERE ((deleted_at IS NULL) AND (show_id IS NOT NULL));


--
-- Name: donations_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donations_station_id_idx ON public.donations USING btree (station_id) WHERE (deleted_at IS NULL);


--
-- Name: donations_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donations_status_idx ON public.donations USING btree (station_id, status) WHERE (deleted_at IS NULL);


--
-- Name: donations_stripe_pi_unique_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX donations_stripe_pi_unique_idx ON public.donations USING btree (stripe_payment_intent_id) WHERE ((stripe_payment_intent_id IS NOT NULL) AND (deleted_at IS NULL));


--
-- Name: donor_extensions_board_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donor_extensions_board_idx ON public.donor_extensions USING btree (board_member) WHERE (board_member = true);


--
-- Name: donor_extensions_donor_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donor_extensions_donor_id_idx ON public.donor_extensions USING btree (donor_id);


--
-- Name: donor_extensions_donor_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donor_extensions_donor_type_idx ON public.donor_extensions USING btree (donor_type);


--
-- Name: donor_extensions_relationship_owner_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donor_extensions_relationship_owner_idx ON public.donor_extensions USING btree (relationship_owner_id) WHERE (relationship_owner_id IS NOT NULL);


--
-- Name: donor_extensions_vip_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donor_extensions_vip_idx ON public.donor_extensions USING btree (vip_flag) WHERE (vip_flag = true);


--
-- Name: donor_notes_author_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donor_notes_author_id_idx ON public.donor_notes USING btree (author_id) WHERE (author_id IS NOT NULL);


--
-- Name: donor_notes_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donor_notes_deleted_at_idx ON public.donor_notes USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: donor_notes_donor_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donor_notes_donor_id_idx ON public.donor_notes USING btree (donor_id) WHERE (deleted_at IS NULL);


--
-- Name: donor_notes_pinned_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donor_notes_pinned_idx ON public.donor_notes USING btree (donor_id, is_pinned) WHERE ((deleted_at IS NULL) AND (is_pinned = true));


--
-- Name: donor_notes_supersedes_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donor_notes_supersedes_idx ON public.donor_notes USING btree (supersedes_id) WHERE (supersedes_id IS NOT NULL);


--
-- Name: donor_notes_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donor_notes_type_idx ON public.donor_notes USING btree (donor_id, note_type) WHERE (deleted_at IS NULL);


--
-- Name: donor_tags_applied_by_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donor_tags_applied_by_idx ON public.donor_tags USING btree (applied_by) WHERE (applied_by IS NOT NULL);


--
-- Name: donor_tags_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donor_tags_deleted_at_idx ON public.donor_tags USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: donor_tags_donor_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donor_tags_donor_id_idx ON public.donor_tags USING btree (donor_id) WHERE (deleted_at IS NULL);


--
-- Name: donor_tags_donor_tag_unique_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX donor_tags_donor_tag_unique_idx ON public.donor_tags USING btree (donor_id, tag) WHERE (deleted_at IS NULL);


--
-- Name: donor_tags_tag_donor_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donor_tags_tag_donor_idx ON public.donor_tags USING btree (tag, donor_id) WHERE (deleted_at IS NULL);


--
-- Name: donor_tags_tag_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donor_tags_tag_idx ON public.donor_tags USING btree (tag) WHERE (deleted_at IS NULL);


--
-- Name: donors_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donors_deleted_at_idx ON public.donors USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: donors_email_normalized_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donors_email_normalized_idx ON public.donors USING btree (email_normalized) WHERE (deleted_at IS NULL);


--
-- Name: donors_email_trgm_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donors_email_trgm_idx ON public.donors USING gin (email public.gin_trgm_ops) WHERE (deleted_at IS NULL);


--
-- Name: donors_first_name_trgm_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donors_first_name_trgm_idx ON public.donors USING gin (first_name public.gin_trgm_ops) WHERE ((deleted_at IS NULL) AND (first_name IS NOT NULL));


--
-- Name: donors_last_name_trgm_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donors_last_name_trgm_idx ON public.donors USING gin (last_name public.gin_trgm_ops) WHERE ((deleted_at IS NULL) AND (last_name IS NOT NULL));


--
-- Name: donors_station_email_unique_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX donors_station_email_unique_idx ON public.donors USING btree (station_id, email_normalized) WHERE (deleted_at IS NULL);


--
-- Name: donors_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX donors_station_id_idx ON public.donors USING btree (station_id) WHERE (deleted_at IS NULL);


--
-- Name: donors_stripe_customer_id_unique_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX donors_stripe_customer_id_unique_idx ON public.donors USING btree (stripe_customer_id) WHERE ((stripe_customer_id IS NOT NULL) AND (deleted_at IS NULL));


--
-- Name: email_log_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX email_log_created_at_idx ON public.email_log USING btree (station_id, created_at);


--
-- Name: email_log_donation_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX email_log_donation_id_idx ON public.email_log USING btree (donation_id) WHERE (donation_id IS NOT NULL);


--
-- Name: email_log_donor_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX email_log_donor_id_idx ON public.email_log USING btree (donor_id) WHERE (donor_id IS NOT NULL);


--
-- Name: email_log_external_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX email_log_external_id_idx ON public.email_log USING btree (external_id) WHERE (external_id IS NOT NULL);


--
-- Name: email_log_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX email_log_station_id_idx ON public.email_log USING btree (station_id);


--
-- Name: email_log_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX email_log_status_idx ON public.email_log USING btree (status);


--
-- Name: email_log_template_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX email_log_template_idx ON public.email_log USING btree (station_id, template_name);


--
-- Name: event_registration_gifts_fulfillment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX event_registration_gifts_fulfillment_idx ON public.event_registration_gifts USING btree (fulfillment_item_id) WHERE (fulfillment_item_id IS NOT NULL);


--
-- Name: event_registration_gifts_gift_variant_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX event_registration_gifts_gift_variant_id_idx ON public.event_registration_gifts USING btree (gift_variant_id);


--
-- Name: event_registration_gifts_registration_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX event_registration_gifts_registration_id_idx ON public.event_registration_gifts USING btree (registration_id);


--
-- Name: event_registration_gifts_unique_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX event_registration_gifts_unique_idx ON public.event_registration_gifts USING btree (registration_id, gift_variant_id);


--
-- Name: event_registrations_checkin_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX event_registrations_checkin_idx ON public.event_registrations USING btree (event_id, checked_in) WHERE ((deleted_at IS NULL) AND (status = 'confirmed'::text));


--
-- Name: event_registrations_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX event_registrations_deleted_at_idx ON public.event_registrations USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: event_registrations_donation_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX event_registrations_donation_id_idx ON public.event_registrations USING btree (donation_id) WHERE (donation_id IS NOT NULL);


--
-- Name: event_registrations_donor_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX event_registrations_donor_id_idx ON public.event_registrations USING btree (donor_id) WHERE (donor_id IS NOT NULL);


--
-- Name: event_registrations_email_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX event_registrations_email_idx ON public.event_registrations USING btree (attendee_email) WHERE (deleted_at IS NULL);


--
-- Name: event_registrations_event_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX event_registrations_event_id_idx ON public.event_registrations USING btree (event_id) WHERE (deleted_at IS NULL);


--
-- Name: event_registrations_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX event_registrations_status_idx ON public.event_registrations USING btree (event_id, status) WHERE (deleted_at IS NULL);


--
-- Name: event_registrations_ticket_type_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX event_registrations_ticket_type_id_idx ON public.event_registrations USING btree (ticket_type_id) WHERE (deleted_at IS NULL);


--
-- Name: events_campaign_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX events_campaign_id_idx ON public.events USING btree (campaign_id) WHERE (campaign_id IS NOT NULL);


--
-- Name: events_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX events_deleted_at_idx ON public.events USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: events_published_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX events_published_idx ON public.events USING btree (station_id, starts_at) WHERE ((deleted_at IS NULL) AND (status = 'published'::text));


--
-- Name: events_show_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX events_show_id_idx ON public.events USING btree (show_id) WHERE (show_id IS NOT NULL);


--
-- Name: events_starts_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX events_starts_at_idx ON public.events USING btree (station_id, starts_at) WHERE (deleted_at IS NULL);


--
-- Name: events_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX events_station_id_idx ON public.events USING btree (station_id) WHERE (deleted_at IS NULL);


--
-- Name: events_station_slug_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX events_station_slug_idx ON public.events USING btree (station_id, slug) WHERE (deleted_at IS NULL);


--
-- Name: events_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX events_status_idx ON public.events USING btree (station_id, status) WHERE (deleted_at IS NULL);


--
-- Name: fulfillment_items_address_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fulfillment_items_address_id_idx ON public.fulfillment_items USING btree (address_id) WHERE (address_id IS NOT NULL);


--
-- Name: fulfillment_items_assigned_to_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fulfillment_items_assigned_to_idx ON public.fulfillment_items USING btree (assigned_to) WHERE (assigned_to IS NOT NULL);


--
-- Name: fulfillment_items_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fulfillment_items_deleted_at_idx ON public.fulfillment_items USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: fulfillment_items_donation_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fulfillment_items_donation_id_idx ON public.fulfillment_items USING btree (donation_id) WHERE (deleted_at IS NULL);


--
-- Name: fulfillment_items_gift_variant_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fulfillment_items_gift_variant_id_idx ON public.fulfillment_items USING btree (gift_variant_id) WHERE (deleted_at IS NULL);


--
-- Name: fulfillment_items_in_progress_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fulfillment_items_in_progress_idx ON public.fulfillment_items USING btree (assigned_to, status) WHERE ((deleted_at IS NULL) AND (status = ANY (ARRAY['assigned'::text, 'processing'::text])));


--
-- Name: fulfillment_items_pending_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fulfillment_items_pending_idx ON public.fulfillment_items USING btree (created_at) WHERE ((deleted_at IS NULL) AND (status = 'pending'::text));


--
-- Name: fulfillment_items_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fulfillment_items_status_idx ON public.fulfillment_items USING btree (status) WHERE (deleted_at IS NULL);


--
-- Name: gift_campaigns_campaign_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gift_campaigns_campaign_id_idx ON public.gift_campaigns USING btree (campaign_id);


--
-- Name: gift_campaigns_gift_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gift_campaigns_gift_id_idx ON public.gift_campaigns USING btree (gift_id);


--
-- Name: gift_intents_confidence_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gift_intents_confidence_idx ON public.gift_intents USING btree (station_id, confidence_level);


--
-- Name: gift_intents_current_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gift_intents_current_idx ON public.gift_intents USING btree (donor_id) WHERE (superseded_at IS NULL);


--
-- Name: gift_intents_document_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gift_intents_document_id_idx ON public.gift_intents USING btree (document_id) WHERE (document_id IS NOT NULL);


--
-- Name: gift_intents_donor_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gift_intents_donor_id_idx ON public.gift_intents USING btree (donor_id);


--
-- Name: gift_intents_recorded_by_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gift_intents_recorded_by_idx ON public.gift_intents USING btree (recorded_by);


--
-- Name: gift_intents_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gift_intents_station_id_idx ON public.gift_intents USING btree (station_id);


--
-- Name: gift_intents_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gift_intents_type_idx ON public.gift_intents USING btree (station_id, intent_type);


--
-- Name: gift_programs_gift_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gift_programs_gift_id_idx ON public.gift_programs USING btree (gift_id);


--
-- Name: gift_programs_program_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gift_programs_program_id_idx ON public.gift_programs USING btree (program_id);


--
-- Name: gift_variants_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gift_variants_active_idx ON public.gift_variants USING btree (gift_id, is_active, sort_order) WHERE (deleted_at IS NULL);


--
-- Name: gift_variants_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gift_variants_deleted_at_idx ON public.gift_variants USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: gift_variants_gift_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gift_variants_gift_id_idx ON public.gift_variants USING btree (gift_id) WHERE (deleted_at IS NULL);


--
-- Name: gift_variants_low_stock_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gift_variants_low_stock_idx ON public.gift_variants USING btree (gift_id) WHERE ((deleted_at IS NULL) AND (inventory_count IS NOT NULL) AND (low_stock_threshold IS NOT NULL) AND (inventory_count <= low_stock_threshold));


--
-- Name: gift_variants_sku_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gift_variants_sku_idx ON public.gift_variants USING btree (sku) WHERE ((sku IS NOT NULL) AND (deleted_at IS NULL));


--
-- Name: gifts_category_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gifts_category_idx ON public.gifts USING btree (station_id, category) WHERE ((deleted_at IS NULL) AND (is_active = true));


--
-- Name: gifts_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gifts_deleted_at_idx ON public.gifts USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: gifts_expires_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gifts_expires_at_idx ON public.gifts USING btree (station_id, expires_at) WHERE ((deleted_at IS NULL) AND (expires_at IS NOT NULL));


--
-- Name: gifts_featured_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gifts_featured_idx ON public.gifts USING btree (station_id, is_featured, sort_order) WHERE ((deleted_at IS NULL) AND (is_active = true));


--
-- Name: gifts_is_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gifts_is_active_idx ON public.gifts USING btree (station_id, is_active, sort_order) WHERE (deleted_at IS NULL);


--
-- Name: gifts_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gifts_station_id_idx ON public.gifts USING btree (station_id) WHERE (deleted_at IS NULL);


--
-- Name: idx_campaign_shows_campaign; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_campaign_shows_campaign ON public.campaign_shows USING btree (campaign_id);


--
-- Name: idx_campaign_shows_show; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_campaign_shows_show ON public.campaign_shows USING btree (show_id);


--
-- Name: idx_campaign_shows_station; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_campaign_shows_station ON public.campaign_shows USING btree (station_id);


--
-- Name: idx_donation_inspirations_donation; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_donation_inspirations_donation ON public.donation_inspirations USING btree (donation_id);


--
-- Name: idx_donation_inspirations_host; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_donation_inspirations_host ON public.donation_inspirations USING btree (host_id) WHERE (host_id IS NOT NULL);


--
-- Name: idx_donation_inspirations_program; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_donation_inspirations_program ON public.donation_inspirations USING btree (program_id) WHERE (program_id IS NOT NULL);


--
-- Name: idx_donations_gift_variant; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_donations_gift_variant ON public.donations USING btree (gift_variant_id) WHERE (gift_variant_id IS NOT NULL);


--
-- Name: idx_donations_recipient_donor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_donations_recipient_donor ON public.donations USING btree (recipient_donor_id) WHERE (recipient_donor_id IS NOT NULL);


--
-- Name: idx_feedback_donation; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_feedback_donation ON public.feedback_responses USING btree (donation_id) WHERE ((deleted_at IS NULL) AND (donation_id IS NOT NULL));


--
-- Name: idx_feedback_donor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_feedback_donor ON public.feedback_responses USING btree (donor_id) WHERE ((deleted_at IS NULL) AND (donor_id IS NOT NULL));


--
-- Name: idx_feedback_station_type_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_feedback_station_type_created ON public.feedback_responses USING btree (station_id, form_type, created_at DESC) WHERE (deleted_at IS NULL);


--
-- Name: idx_gifts_static_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_gifts_static_id ON public.gifts USING btree (static_id) WHERE (static_id IS NOT NULL);


--
-- Name: idx_memberships_donation; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_memberships_donation ON public.memberships USING btree (donation_id) WHERE (donation_id IS NOT NULL);


--
-- Name: idx_operator_activity_action; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_operator_activity_action ON public.operator_activity_log USING btree (action, created_at DESC);


--
-- Name: idx_operator_activity_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_operator_activity_email ON public.operator_activity_log USING btree (operator_email, created_at DESC);


--
-- Name: idx_operator_activity_profile; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_operator_activity_profile ON public.operator_activity_log USING btree (operator_profile_id) WHERE (operator_profile_id IS NOT NULL);


--
-- Name: idx_operator_activity_station; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_operator_activity_station ON public.operator_activity_log USING btree (station_id, created_at DESC);


--
-- Name: idx_payment_intents_checkout_session; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payment_intents_checkout_session ON public.payment_intents USING btree (checkout_session_id) WHERE (checkout_session_id IS NOT NULL);


--
-- Name: idx_payment_intents_donation; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payment_intents_donation ON public.payment_intents USING btree (donation_id) WHERE (donation_id IS NOT NULL);


--
-- Name: idx_payment_intents_donor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payment_intents_donor ON public.payment_intents USING btree (donor_id) WHERE (donor_id IS NOT NULL);


--
-- Name: idx_payment_intents_station; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payment_intents_station ON public.payment_intents USING btree (station_id);


--
-- Name: idx_payment_intents_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payment_intents_status ON public.payment_intents USING btree (status) WHERE (status <> 'succeeded'::text);


--
-- Name: idx_payment_intents_stripe_pi; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payment_intents_stripe_pi ON public.payment_intents USING btree (stripe_payment_intent_id);


--
-- Name: idx_press_passes_pass_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_press_passes_pass_number ON public.press_passes USING btree (pass_number) WHERE (deleted_at IS NULL);


--
-- Name: idx_press_passes_station_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_press_passes_station_id ON public.press_passes USING btree (station_id);


--
-- Name: idx_press_passes_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_press_passes_status ON public.press_passes USING btree (status) WHERE (deleted_at IS NULL);


--
-- Name: idx_press_passes_verification_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_press_passes_verification_token ON public.press_passes USING btree (verification_token) WHERE (deleted_at IS NULL);


--
-- Name: idx_program_categories_station; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_program_categories_station ON public.program_categories USING btree (station_id) WHERE (deleted_at IS NULL);


--
-- Name: idx_program_host_assignments_host; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_program_host_assignments_host ON public.program_host_assignments USING btree (host_id);


--
-- Name: idx_program_host_assignments_program; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_program_host_assignments_program ON public.program_host_assignments USING btree (program_id);


--
-- Name: idx_program_hosts_station; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_program_hosts_station ON public.program_hosts USING btree (station_id) WHERE (deleted_at IS NULL);


--
-- Name: idx_program_schedule_day_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_program_schedule_day_time ON public.program_schedule USING btree (day_of_week, start_time);


--
-- Name: idx_program_schedule_program; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_program_schedule_program ON public.program_schedule USING btree (program_id);


--
-- Name: idx_programs_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_programs_category ON public.programs USING btree (category_id) WHERE (deleted_at IS NULL);


--
-- Name: idx_programs_external; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_programs_external ON public.programs USING btree (external_source, external_id) WHERE (external_id IS NOT NULL);


--
-- Name: idx_programs_station; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_programs_station ON public.programs USING btree (station_id) WHERE (deleted_at IS NULL);


--
-- Name: idx_station_sequences_station_year; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_station_sequences_station_year ON public.station_sequences USING btree (station_id, sequence_year);


--
-- Name: idx_tax_documents_receipt_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tax_documents_receipt_number ON public.tax_documents USING btree (receipt_number) WHERE (receipt_number IS NOT NULL);


--
-- Name: idx_verification_logs_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_verification_logs_created_at ON public.verification_logs USING btree (created_at);


--
-- Name: idx_verification_logs_ip_address; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_verification_logs_ip_address ON public.verification_logs USING btree (ip_address);


--
-- Name: idx_verification_logs_press_pass_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_verification_logs_press_pass_id ON public.verification_logs USING btree (press_pass_id);


--
-- Name: idx_verification_logs_result; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_verification_logs_result ON public.verification_logs USING btree (lookup_result);


--
-- Name: interactions_campaign_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX interactions_campaign_id_idx ON public.interactions USING btree (campaign_id) WHERE (campaign_id IS NOT NULL);


--
-- Name: interactions_donor_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX interactions_donor_id_idx ON public.interactions USING btree (donor_id);


--
-- Name: interactions_followup_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX interactions_followup_idx ON public.interactions USING btree (station_id, requires_followup, followup_completed) WHERE ((requires_followup = true) AND (followup_completed = false));


--
-- Name: interactions_gift_intent_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX interactions_gift_intent_id_idx ON public.interactions USING btree (gift_intent_id) WHERE (gift_intent_id IS NOT NULL);


--
-- Name: interactions_occurred_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX interactions_occurred_at_idx ON public.interactions USING btree (station_id, occurred_at);


--
-- Name: interactions_staff_user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX interactions_staff_user_id_idx ON public.interactions USING btree (staff_user_id);


--
-- Name: interactions_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX interactions_station_id_idx ON public.interactions USING btree (station_id);


--
-- Name: interactions_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX interactions_type_idx ON public.interactions USING btree (station_id, interaction_type);


--
-- Name: invites_email_pending_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX invites_email_pending_idx ON public.invites USING btree (email) WHERE (used_at IS NULL);


--
-- Name: invites_expires_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX invites_expires_at_idx ON public.invites USING btree (expires_at) WHERE (used_at IS NULL);


--
-- Name: invites_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX invites_station_id_idx ON public.invites USING btree (station_id);


--
-- Name: invites_token_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX invites_token_idx ON public.invites USING btree (token);


--
-- Name: match_allocations_allocated_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX match_allocations_allocated_at_idx ON public.match_allocations USING btree (allocated_at);


--
-- Name: match_allocations_donation_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX match_allocations_donation_id_idx ON public.match_allocations USING btree (donation_id);


--
-- Name: match_allocations_donation_pool_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX match_allocations_donation_pool_idx ON public.match_allocations USING btree (donation_id, match_pool_id);


--
-- Name: match_allocations_match_pool_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX match_allocations_match_pool_id_idx ON public.match_allocations USING btree (match_pool_id);


--
-- Name: match_pools_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX match_pools_active_idx ON public.match_pools USING btree (station_id, is_active) WHERE ((deleted_at IS NULL) AND (remaining_cents > 0));


--
-- Name: match_pools_campaign_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX match_pools_campaign_id_idx ON public.match_pools USING btree (campaign_id) WHERE (campaign_id IS NOT NULL);


--
-- Name: match_pools_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX match_pools_deleted_at_idx ON public.match_pools USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: match_pools_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX match_pools_station_id_idx ON public.match_pools USING btree (station_id) WHERE (deleted_at IS NULL);


--
-- Name: memberships_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX memberships_deleted_at_idx ON public.memberships USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: memberships_donor_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX memberships_donor_id_idx ON public.memberships USING btree (donor_id) WHERE (deleted_at IS NULL);


--
-- Name: memberships_lapsed_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX memberships_lapsed_idx ON public.memberships USING btree (station_id, lapsed_at) WHERE ((deleted_at IS NULL) AND (lapsed_at IS NOT NULL));


--
-- Name: memberships_payment_failed_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX memberships_payment_failed_idx ON public.memberships USING btree (station_id, payment_failed_at) WHERE ((deleted_at IS NULL) AND (payment_failed_at IS NOT NULL));


--
-- Name: memberships_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX memberships_station_id_idx ON public.memberships USING btree (station_id) WHERE (deleted_at IS NULL);


--
-- Name: memberships_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX memberships_status_idx ON public.memberships USING btree (station_id, status) WHERE (deleted_at IS NULL);


--
-- Name: memberships_stripe_subscription_unique_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX memberships_stripe_subscription_unique_idx ON public.memberships USING btree (stripe_subscription_id) WHERE ((stripe_subscription_id IS NOT NULL) AND (deleted_at IS NULL));


--
-- Name: profiles_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profiles_deleted_at_idx ON public.profiles USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: profiles_donor_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profiles_donor_id_idx ON public.profiles USING btree (donor_id) WHERE (donor_id IS NOT NULL);


--
-- Name: profiles_email_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profiles_email_idx ON public.profiles USING btree (email) WHERE (deleted_at IS NULL);


--
-- Name: profiles_is_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profiles_is_active_idx ON public.profiles USING btree (is_active) WHERE (deleted_at IS NULL);


--
-- Name: profiles_role_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profiles_role_idx ON public.profiles USING btree (role) WHERE (deleted_at IS NULL);


--
-- Name: profiles_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profiles_station_id_idx ON public.profiles USING btree (station_id) WHERE (deleted_at IS NULL);


--
-- Name: promo_codes_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX promo_codes_active_idx ON public.promo_codes USING btree (station_id, is_active) WHERE (deleted_at IS NULL);


--
-- Name: promo_codes_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX promo_codes_deleted_at_idx ON public.promo_codes USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: promo_codes_event_code_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX promo_codes_event_code_idx ON public.promo_codes USING btree (event_id, upper(code)) WHERE ((deleted_at IS NULL) AND (event_id IS NOT NULL));


--
-- Name: promo_codes_event_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX promo_codes_event_id_idx ON public.promo_codes USING btree (event_id) WHERE (event_id IS NOT NULL);


--
-- Name: promo_codes_station_code_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX promo_codes_station_code_idx ON public.promo_codes USING btree (station_id, upper(code)) WHERE ((deleted_at IS NULL) AND (event_id IS NULL));


--
-- Name: promo_codes_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX promo_codes_station_id_idx ON public.promo_codes USING btree (station_id) WHERE (deleted_at IS NULL);


--
-- Name: shows_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX shows_deleted_at_idx ON public.shows USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: shows_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX shows_station_id_idx ON public.shows USING btree (station_id) WHERE (deleted_at IS NULL);


--
-- Name: shows_station_slug_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX shows_station_slug_idx ON public.shows USING btree (station_id, slug) WHERE (deleted_at IS NULL);


--
-- Name: stations_code_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX stations_code_idx ON public.stations USING btree (code) WHERE (deleted_at IS NULL);


--
-- Name: stations_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX stations_deleted_at_idx ON public.stations USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: system_events_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX system_events_created_at_idx ON public.system_events USING btree (created_at);


--
-- Name: system_events_event_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX system_events_event_type_idx ON public.system_events USING btree (event_type);


--
-- Name: system_events_pending_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX system_events_pending_idx ON public.system_events USING btree (created_at) WHERE (status = ANY (ARRAY['pending'::text, 'processing'::text]));


--
-- Name: system_events_source_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX system_events_source_idx ON public.system_events USING btree (source);


--
-- Name: system_events_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX system_events_status_idx ON public.system_events USING btree (status);


--
-- Name: system_events_type_time_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX system_events_type_time_idx ON public.system_events USING btree (event_type, created_at DESC);


--
-- Name: tax_documents_current_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tax_documents_current_idx ON public.tax_documents USING btree (donation_id) WHERE (superseded_at IS NULL);


--
-- Name: tax_documents_document_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tax_documents_document_type_idx ON public.tax_documents USING btree (station_id, document_type);


--
-- Name: tax_documents_donation_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tax_documents_donation_id_idx ON public.tax_documents USING btree (donation_id);


--
-- Name: tax_documents_donor_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tax_documents_donor_id_idx ON public.tax_documents USING btree (donor_id);


--
-- Name: tax_documents_generated_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tax_documents_generated_at_idx ON public.tax_documents USING btree (station_id, generated_at);


--
-- Name: tax_documents_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tax_documents_station_id_idx ON public.tax_documents USING btree (station_id);


--
-- Name: tax_documents_supersedes_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tax_documents_supersedes_id_idx ON public.tax_documents USING btree (supersedes_id) WHERE (supersedes_id IS NOT NULL);


--
-- Name: ticket_types_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ticket_types_active_idx ON public.ticket_types USING btree (event_id, is_active, sort_order) WHERE (deleted_at IS NULL);


--
-- Name: ticket_types_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ticket_types_deleted_at_idx ON public.ticket_types USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: ticket_types_event_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ticket_types_event_id_idx ON public.ticket_types USING btree (event_id) WHERE (deleted_at IS NULL);


--
-- Name: underwriters_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX underwriters_deleted_at_idx ON public.underwriters USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: underwriters_is_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX underwriters_is_active_idx ON public.underwriters USING btree (station_id, is_active) WHERE (deleted_at IS NULL);


--
-- Name: underwriters_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX underwriters_name_idx ON public.underwriters USING btree (station_id, name) WHERE (deleted_at IS NULL);


--
-- Name: underwriters_relationship_owner_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX underwriters_relationship_owner_idx ON public.underwriters USING btree (relationship_owner_id) WHERE (relationship_owner_id IS NOT NULL);


--
-- Name: underwriters_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX underwriters_station_id_idx ON public.underwriters USING btree (station_id) WHERE (deleted_at IS NULL);


--
-- Name: underwriting_invoices_number_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX underwriting_invoices_number_idx ON public.underwriting_invoices USING btree (station_id, invoice_number) WHERE (deleted_at IS NULL);


--
-- Name: uw_agreements_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_agreements_active_idx ON public.underwriting_agreements USING btree (station_id) WHERE ((deleted_at IS NULL) AND (status = 'active'::text));


--
-- Name: uw_agreements_dates_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_agreements_dates_idx ON public.underwriting_agreements USING btree (station_id, starts_at, ends_at) WHERE (deleted_at IS NULL);


--
-- Name: uw_agreements_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_agreements_deleted_at_idx ON public.underwriting_agreements USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: uw_agreements_document_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_agreements_document_id_idx ON public.underwriting_agreements USING btree (document_id) WHERE (document_id IS NOT NULL);


--
-- Name: uw_agreements_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_agreements_station_id_idx ON public.underwriting_agreements USING btree (station_id) WHERE (deleted_at IS NULL);


--
-- Name: uw_agreements_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_agreements_status_idx ON public.underwriting_agreements USING btree (station_id, status) WHERE (deleted_at IS NULL);


--
-- Name: uw_agreements_underwriter_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_agreements_underwriter_id_idx ON public.underwriting_agreements USING btree (underwriter_id) WHERE (deleted_at IS NULL);


--
-- Name: uw_broadcasts_agreement_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_broadcasts_agreement_id_idx ON public.underwriting_broadcasts USING btree (agreement_id);


--
-- Name: uw_broadcasts_copy_approval_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_broadcasts_copy_approval_idx ON public.underwriting_broadcasts USING btree (station_id, copy_approved) WHERE ((status = 'scheduled'::text) AND (copy_approved = false));


--
-- Name: uw_broadcasts_pending_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_broadcasts_pending_idx ON public.underwriting_broadcasts USING btree (station_id, scheduled_at) WHERE (status = 'scheduled'::text);


--
-- Name: uw_broadcasts_scheduled_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_broadcasts_scheduled_at_idx ON public.underwriting_broadcasts USING btree (station_id, scheduled_at);


--
-- Name: uw_broadcasts_show_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_broadcasts_show_id_idx ON public.underwriting_broadcasts USING btree (show_id) WHERE (show_id IS NOT NULL);


--
-- Name: uw_broadcasts_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_broadcasts_station_id_idx ON public.underwriting_broadcasts USING btree (station_id);


--
-- Name: uw_broadcasts_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_broadcasts_status_idx ON public.underwriting_broadcasts USING btree (station_id, status);


--
-- Name: uw_invoices_agreement_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_invoices_agreement_id_idx ON public.underwriting_invoices USING btree (agreement_id) WHERE (deleted_at IS NULL);


--
-- Name: uw_invoices_deleted_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_invoices_deleted_at_idx ON public.underwriting_invoices USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: uw_invoices_due_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_invoices_due_date_idx ON public.underwriting_invoices USING btree (station_id, due_date) WHERE (deleted_at IS NULL);


--
-- Name: uw_invoices_overdue_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_invoices_overdue_idx ON public.underwriting_invoices USING btree (station_id, due_date) WHERE ((deleted_at IS NULL) AND (status = ANY (ARRAY['sent'::text, 'viewed'::text, 'overdue'::text])));


--
-- Name: uw_invoices_station_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_invoices_station_id_idx ON public.underwriting_invoices USING btree (station_id) WHERE (deleted_at IS NULL);


--
-- Name: uw_invoices_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_invoices_status_idx ON public.underwriting_invoices USING btree (station_id, status) WHERE (deleted_at IS NULL);


--
-- Name: uw_invoices_underwriter_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uw_invoices_underwriter_id_idx ON public.underwriting_invoices USING btree (underwriter_id) WHERE (deleted_at IS NULL);


--
-- Name: addresses addresses_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER addresses_updated_at BEFORE UPDATE ON public.addresses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: campaigns audit_campaigns; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_campaigns AFTER INSERT OR DELETE OR UPDATE ON public.campaigns FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: donations audit_donations; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_donations AFTER INSERT OR DELETE OR UPDATE ON public.donations FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: donors audit_donors; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_donors AFTER INSERT OR DELETE OR UPDATE ON public.donors FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: fulfillment_items audit_fulfillment_items; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_fulfillment_items AFTER INSERT OR DELETE OR UPDATE ON public.fulfillment_items FOR EACH ROW EXECUTE FUNCTION public.audit_fulfillment_trigger_function();


--
-- Name: gift_variants audit_gift_variants; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_gift_variants AFTER INSERT OR DELETE OR UPDATE ON public.gift_variants FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: gifts audit_gifts; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_gifts AFTER INSERT OR DELETE OR UPDATE ON public.gifts FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: memberships audit_memberships; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_memberships AFTER INSERT OR DELETE OR UPDATE ON public.memberships FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: profiles audit_profiles; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_profiles AFTER INSERT OR DELETE OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.audit_profiles_trigger_function();


--
-- Name: campaigns campaigns_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER campaigns_updated_at BEFORE UPDATE ON public.campaigns FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: checkout_sessions checkout_sessions_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER checkout_sessions_updated_at BEFORE UPDATE ON public.checkout_sessions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: documents documents_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER documents_updated_at BEFORE UPDATE ON public.documents FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: donations donations_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER donations_updated_at BEFORE UPDATE ON public.donations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: donor_extensions donor_extensions_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER donor_extensions_updated_at BEFORE UPDATE ON public.donor_extensions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: donor_notes donor_notes_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER donor_notes_updated_at BEFORE UPDATE ON public.donor_notes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: donors donors_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER donors_updated_at BEFORE UPDATE ON public.donors FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: event_registrations event_registrations_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER event_registrations_updated_at BEFORE UPDATE ON public.event_registrations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: events events_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER events_updated_at BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: fulfillment_items fulfillment_items_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER fulfillment_items_updated_at BEFORE UPDATE ON public.fulfillment_items FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: gift_variants gift_variants_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER gift_variants_updated_at BEFORE UPDATE ON public.gift_variants FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: gifts gifts_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER gifts_updated_at BEFORE UPDATE ON public.gifts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: match_pools match_pools_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER match_pools_updated_at BEFORE UPDATE ON public.match_pools FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: memberships memberships_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER memberships_updated_at BEFORE UPDATE ON public.memberships FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: press_passes press_passes_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER press_passes_updated_at BEFORE UPDATE ON public.press_passes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: profiles profiles_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: promo_codes promo_codes_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER promo_codes_updated_at BEFORE UPDATE ON public.promo_codes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: shows shows_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER shows_updated_at BEFORE UPDATE ON public.shows FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: station_sequences station_sequences_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER station_sequences_updated_at BEFORE UPDATE ON public.station_sequences FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: stations stations_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER stations_updated_at BEFORE UPDATE ON public.stations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: ticket_types ticket_types_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ticket_types_updated_at BEFORE UPDATE ON public.ticket_types FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: underwriters underwriters_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER underwriters_updated_at BEFORE UPDATE ON public.underwriters FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: underwriting_agreements uw_agreements_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER uw_agreements_updated_at BEFORE UPDATE ON public.underwriting_agreements FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: underwriting_broadcasts uw_broadcasts_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER uw_broadcasts_updated_at BEFORE UPDATE ON public.underwriting_broadcasts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: underwriting_invoices uw_invoices_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER uw_invoices_updated_at BEFORE UPDATE ON public.underwriting_invoices FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: addresses addresses_donor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.donors(id);


--
-- Name: audit_log audit_log_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: audit_log audit_log_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id);


--
-- Name: campaign_shows campaign_shows_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_shows
    ADD CONSTRAINT campaign_shows_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- Name: campaign_shows campaign_shows_show_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_shows
    ADD CONSTRAINT campaign_shows_show_id_fkey FOREIGN KEY (show_id) REFERENCES public.shows(id);


--
-- Name: campaign_shows campaign_shows_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_shows
    ADD CONSTRAINT campaign_shows_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: campaigns campaigns_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: checkout_sessions checkout_sessions_donation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checkout_sessions
    ADD CONSTRAINT checkout_sessions_donation_id_fkey FOREIGN KEY (donation_id) REFERENCES public.donations(id);


--
-- Name: checkout_sessions checkout_sessions_donor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checkout_sessions
    ADD CONSTRAINT checkout_sessions_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.donors(id);


--
-- Name: checkout_sessions checkout_sessions_operator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checkout_sessions
    ADD CONSTRAINT checkout_sessions_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES public.profiles(id);


--
-- Name: checkout_sessions checkout_sessions_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checkout_sessions
    ADD CONSTRAINT checkout_sessions_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: documents documents_donor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.donors(id);


--
-- Name: documents documents_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: documents documents_supersedes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_supersedes_id_fkey FOREIGN KEY (supersedes_id) REFERENCES public.documents(id);


--
-- Name: documents documents_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.profiles(id);


--
-- Name: donation_inspirations donation_inspirations_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donation_inspirations
    ADD CONSTRAINT donation_inspirations_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.program_categories(id) ON DELETE SET NULL;


--
-- Name: donation_inspirations donation_inspirations_donation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donation_inspirations
    ADD CONSTRAINT donation_inspirations_donation_id_fkey FOREIGN KEY (donation_id) REFERENCES public.donations(id) ON DELETE CASCADE;


--
-- Name: donation_inspirations donation_inspirations_host_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donation_inspirations
    ADD CONSTRAINT donation_inspirations_host_id_fkey FOREIGN KEY (host_id) REFERENCES public.program_hosts(id) ON DELETE SET NULL;


--
-- Name: donation_inspirations donation_inspirations_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donation_inspirations
    ADD CONSTRAINT donation_inspirations_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(id) ON DELETE SET NULL;


--
-- Name: donations donations_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- Name: donations donations_checkout_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_checkout_session_id_fkey FOREIGN KEY (checkout_session_id) REFERENCES public.checkout_sessions(id);


--
-- Name: donations donations_donor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.donors(id);


--
-- Name: donations donations_gift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_gift_id_fkey FOREIGN KEY (gift_id) REFERENCES public.gifts(id);


--
-- Name: donations donations_gift_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_gift_variant_id_fkey FOREIGN KEY (gift_variant_id) REFERENCES public.gift_variants(id);


--
-- Name: donations donations_operator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES public.profiles(id);


--
-- Name: donations donations_recipient_donor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_recipient_donor_id_fkey FOREIGN KEY (recipient_donor_id) REFERENCES public.donors(id);


--
-- Name: donations donations_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: donor_extensions donor_extensions_donor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donor_extensions
    ADD CONSTRAINT donor_extensions_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.donors(id);


--
-- Name: donor_extensions donor_extensions_relationship_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donor_extensions
    ADD CONSTRAINT donor_extensions_relationship_owner_id_fkey FOREIGN KEY (relationship_owner_id) REFERENCES public.profiles(id);


--
-- Name: donor_extensions donor_extensions_secondary_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donor_extensions
    ADD CONSTRAINT donor_extensions_secondary_owner_id_fkey FOREIGN KEY (secondary_owner_id) REFERENCES public.profiles(id);


--
-- Name: donor_notes donor_notes_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donor_notes
    ADD CONSTRAINT donor_notes_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id);


--
-- Name: donor_notes donor_notes_donor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donor_notes
    ADD CONSTRAINT donor_notes_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.donors(id);


--
-- Name: donor_notes donor_notes_supersedes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donor_notes
    ADD CONSTRAINT donor_notes_supersedes_id_fkey FOREIGN KEY (supersedes_id) REFERENCES public.donor_notes(id);


--
-- Name: donor_tags donor_tags_applied_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donor_tags
    ADD CONSTRAINT donor_tags_applied_by_fkey FOREIGN KEY (applied_by) REFERENCES public.profiles(id);


--
-- Name: donor_tags donor_tags_donor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donor_tags
    ADD CONSTRAINT donor_tags_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.donors(id);


--
-- Name: donors donors_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donors
    ADD CONSTRAINT donors_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: email_log email_log_donation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_log
    ADD CONSTRAINT email_log_donation_id_fkey FOREIGN KEY (donation_id) REFERENCES public.donations(id);


--
-- Name: email_log email_log_donor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_log
    ADD CONSTRAINT email_log_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.donors(id);


--
-- Name: email_log email_log_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_log
    ADD CONSTRAINT email_log_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: event_registration_gifts event_registration_gifts_fulfillment_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_registration_gifts
    ADD CONSTRAINT event_registration_gifts_fulfillment_item_id_fkey FOREIGN KEY (fulfillment_item_id) REFERENCES public.fulfillment_items(id);


--
-- Name: event_registration_gifts event_registration_gifts_gift_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_registration_gifts
    ADD CONSTRAINT event_registration_gifts_gift_variant_id_fkey FOREIGN KEY (gift_variant_id) REFERENCES public.gift_variants(id);


--
-- Name: event_registration_gifts event_registration_gifts_registration_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_registration_gifts
    ADD CONSTRAINT event_registration_gifts_registration_id_fkey FOREIGN KEY (registration_id) REFERENCES public.event_registrations(id);


--
-- Name: event_registrations event_registrations_checked_in_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_registrations
    ADD CONSTRAINT event_registrations_checked_in_by_fkey FOREIGN KEY (checked_in_by) REFERENCES public.profiles(id);


--
-- Name: event_registrations event_registrations_donation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_registrations
    ADD CONSTRAINT event_registrations_donation_id_fkey FOREIGN KEY (donation_id) REFERENCES public.donations(id);


--
-- Name: event_registrations event_registrations_donor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_registrations
    ADD CONSTRAINT event_registrations_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.donors(id);


--
-- Name: event_registrations event_registrations_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_registrations
    ADD CONSTRAINT event_registrations_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id);


--
-- Name: event_registrations event_registrations_promo_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_registrations
    ADD CONSTRAINT event_registrations_promo_code_id_fkey FOREIGN KEY (promo_code_id) REFERENCES public.promo_codes(id);


--
-- Name: event_registrations event_registrations_ticket_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_registrations
    ADD CONSTRAINT event_registrations_ticket_type_id_fkey FOREIGN KEY (ticket_type_id) REFERENCES public.ticket_types(id);


--
-- Name: events events_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- Name: events events_show_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_show_id_fkey FOREIGN KEY (show_id) REFERENCES public.shows(id);


--
-- Name: events events_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: feedback_responses feedback_responses_donation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.feedback_responses
    ADD CONSTRAINT feedback_responses_donation_id_fkey FOREIGN KEY (donation_id) REFERENCES public.donations(id);


--
-- Name: feedback_responses feedback_responses_donor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.feedback_responses
    ADD CONSTRAINT feedback_responses_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.donors(id);


--
-- Name: feedback_responses feedback_responses_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.feedback_responses
    ADD CONSTRAINT feedback_responses_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: fulfillment_items fulfillment_items_address_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fulfillment_items
    ADD CONSTRAINT fulfillment_items_address_id_fkey FOREIGN KEY (address_id) REFERENCES public.addresses(id);


--
-- Name: fulfillment_items fulfillment_items_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fulfillment_items
    ADD CONSTRAINT fulfillment_items_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.profiles(id);


--
-- Name: fulfillment_items fulfillment_items_donation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fulfillment_items
    ADD CONSTRAINT fulfillment_items_donation_id_fkey FOREIGN KEY (donation_id) REFERENCES public.donations(id);


--
-- Name: fulfillment_items fulfillment_items_gift_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fulfillment_items
    ADD CONSTRAINT fulfillment_items_gift_variant_id_fkey FOREIGN KEY (gift_variant_id) REFERENCES public.gift_variants(id);


--
-- Name: gift_campaigns gift_campaigns_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_campaigns
    ADD CONSTRAINT gift_campaigns_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE CASCADE;


--
-- Name: gift_campaigns gift_campaigns_gift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_campaigns
    ADD CONSTRAINT gift_campaigns_gift_id_fkey FOREIGN KEY (gift_id) REFERENCES public.gifts(id) ON DELETE CASCADE;


--
-- Name: gift_intents gift_intents_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_intents
    ADD CONSTRAINT gift_intents_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.documents(id);


--
-- Name: gift_intents gift_intents_donor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_intents
    ADD CONSTRAINT gift_intents_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.donors(id);


--
-- Name: gift_intents gift_intents_recorded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_intents
    ADD CONSTRAINT gift_intents_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES public.profiles(id);


--
-- Name: gift_intents gift_intents_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_intents
    ADD CONSTRAINT gift_intents_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: gift_intents gift_intents_supersedes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_intents
    ADD CONSTRAINT gift_intents_supersedes_id_fkey FOREIGN KEY (supersedes_id) REFERENCES public.gift_intents(id);


--
-- Name: gift_programs gift_programs_gift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_programs
    ADD CONSTRAINT gift_programs_gift_id_fkey FOREIGN KEY (gift_id) REFERENCES public.gifts(id) ON DELETE CASCADE;


--
-- Name: gift_programs gift_programs_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_programs
    ADD CONSTRAINT gift_programs_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(id) ON DELETE CASCADE;


--
-- Name: gift_variants gift_variants_gift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_variants
    ADD CONSTRAINT gift_variants_gift_id_fkey FOREIGN KEY (gift_id) REFERENCES public.gifts(id);


--
-- Name: gifts gifts_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gifts
    ADD CONSTRAINT gifts_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: interactions interactions_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interactions
    ADD CONSTRAINT interactions_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- Name: interactions interactions_donor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interactions
    ADD CONSTRAINT interactions_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.donors(id);


--
-- Name: interactions interactions_gift_intent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interactions
    ADD CONSTRAINT interactions_gift_intent_id_fkey FOREIGN KEY (gift_intent_id) REFERENCES public.gift_intents(id);


--
-- Name: interactions interactions_staff_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interactions
    ADD CONSTRAINT interactions_staff_user_id_fkey FOREIGN KEY (staff_user_id) REFERENCES public.profiles(id);


--
-- Name: interactions interactions_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interactions
    ADD CONSTRAINT interactions_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: interactions interactions_witness_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interactions
    ADD CONSTRAINT interactions_witness_id_fkey FOREIGN KEY (witness_id) REFERENCES public.profiles(id);


--
-- Name: invites invites_invited_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invites
    ADD CONSTRAINT invites_invited_by_fkey FOREIGN KEY (invited_by) REFERENCES public.profiles(id);


--
-- Name: invites invites_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invites
    ADD CONSTRAINT invites_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: match_allocations match_allocations_allocated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_allocations
    ADD CONSTRAINT match_allocations_allocated_by_fkey FOREIGN KEY (allocated_by) REFERENCES public.profiles(id);


--
-- Name: match_allocations match_allocations_donation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_allocations
    ADD CONSTRAINT match_allocations_donation_id_fkey FOREIGN KEY (donation_id) REFERENCES public.donations(id);


--
-- Name: match_allocations match_allocations_match_pool_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_allocations
    ADD CONSTRAINT match_allocations_match_pool_id_fkey FOREIGN KEY (match_pool_id) REFERENCES public.match_pools(id);


--
-- Name: match_pools match_pools_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_pools
    ADD CONSTRAINT match_pools_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- Name: match_pools match_pools_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_pools
    ADD CONSTRAINT match_pools_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: memberships memberships_donation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT memberships_donation_id_fkey FOREIGN KEY (donation_id) REFERENCES public.donations(id);


--
-- Name: memberships memberships_donor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT memberships_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.donors(id);


--
-- Name: memberships memberships_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT memberships_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: operator_activity_log operator_activity_log_operator_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operator_activity_log
    ADD CONSTRAINT operator_activity_log_operator_profile_id_fkey FOREIGN KEY (operator_profile_id) REFERENCES public.profiles(id);


--
-- Name: operator_activity_log operator_activity_log_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operator_activity_log
    ADD CONSTRAINT operator_activity_log_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: payment_intents payment_intents_checkout_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_intents
    ADD CONSTRAINT payment_intents_checkout_session_id_fkey FOREIGN KEY (checkout_session_id) REFERENCES public.checkout_sessions(id);


--
-- Name: payment_intents payment_intents_donation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_intents
    ADD CONSTRAINT payment_intents_donation_id_fkey FOREIGN KEY (donation_id) REFERENCES public.donations(id);


--
-- Name: payment_intents payment_intents_donor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_intents
    ADD CONSTRAINT payment_intents_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.donors(id);


--
-- Name: payment_intents payment_intents_operator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_intents
    ADD CONSTRAINT payment_intents_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES public.profiles(id);


--
-- Name: payment_intents payment_intents_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_intents
    ADD CONSTRAINT payment_intents_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: press_passes press_passes_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.press_passes
    ADD CONSTRAINT press_passes_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: profiles profiles_donor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.donors(id);


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: profiles profiles_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: program_categories program_categories_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_categories
    ADD CONSTRAINT program_categories_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: program_host_assignments program_host_assignments_host_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_host_assignments
    ADD CONSTRAINT program_host_assignments_host_id_fkey FOREIGN KEY (host_id) REFERENCES public.program_hosts(id) ON DELETE CASCADE;


--
-- Name: program_host_assignments program_host_assignments_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_host_assignments
    ADD CONSTRAINT program_host_assignments_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(id) ON DELETE CASCADE;


--
-- Name: program_hosts program_hosts_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_hosts
    ADD CONSTRAINT program_hosts_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: program_schedule program_schedule_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_schedule
    ADD CONSTRAINT program_schedule_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(id) ON DELETE CASCADE;


--
-- Name: programs programs_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.program_categories(id);


--
-- Name: programs programs_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: promo_codes promo_codes_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promo_codes
    ADD CONSTRAINT promo_codes_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id);


--
-- Name: promo_codes promo_codes_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promo_codes
    ADD CONSTRAINT promo_codes_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: shows shows_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shows
    ADD CONSTRAINT shows_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_sequences station_sequences_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.station_sequences
    ADD CONSTRAINT station_sequences_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: tax_documents tax_documents_donation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tax_documents
    ADD CONSTRAINT tax_documents_donation_id_fkey FOREIGN KEY (donation_id) REFERENCES public.donations(id);


--
-- Name: tax_documents tax_documents_donor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tax_documents
    ADD CONSTRAINT tax_documents_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.donors(id);


--
-- Name: tax_documents tax_documents_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tax_documents
    ADD CONSTRAINT tax_documents_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: tax_documents tax_documents_supersedes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tax_documents
    ADD CONSTRAINT tax_documents_supersedes_id_fkey FOREIGN KEY (supersedes_id) REFERENCES public.tax_documents(id);


--
-- Name: ticket_types ticket_types_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket_types
    ADD CONSTRAINT ticket_types_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id);


--
-- Name: underwriters underwriters_relationship_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.underwriters
    ADD CONSTRAINT underwriters_relationship_owner_id_fkey FOREIGN KEY (relationship_owner_id) REFERENCES public.profiles(id);


--
-- Name: underwriters underwriters_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.underwriters
    ADD CONSTRAINT underwriters_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: underwriting_agreements underwriting_agreements_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.underwriting_agreements
    ADD CONSTRAINT underwriting_agreements_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.documents(id);


--
-- Name: underwriting_agreements underwriting_agreements_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.underwriting_agreements
    ADD CONSTRAINT underwriting_agreements_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: underwriting_agreements underwriting_agreements_underwriter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.underwriting_agreements
    ADD CONSTRAINT underwriting_agreements_underwriter_id_fkey FOREIGN KEY (underwriter_id) REFERENCES public.underwriters(id);


--
-- Name: underwriting_broadcasts underwriting_broadcasts_agreement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.underwriting_broadcasts
    ADD CONSTRAINT underwriting_broadcasts_agreement_id_fkey FOREIGN KEY (agreement_id) REFERENCES public.underwriting_agreements(id);


--
-- Name: underwriting_broadcasts underwriting_broadcasts_copy_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.underwriting_broadcasts
    ADD CONSTRAINT underwriting_broadcasts_copy_approved_by_fkey FOREIGN KEY (copy_approved_by) REFERENCES public.profiles(id);


--
-- Name: underwriting_broadcasts underwriting_broadcasts_show_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.underwriting_broadcasts
    ADD CONSTRAINT underwriting_broadcasts_show_id_fkey FOREIGN KEY (show_id) REFERENCES public.shows(id);


--
-- Name: underwriting_broadcasts underwriting_broadcasts_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.underwriting_broadcasts
    ADD CONSTRAINT underwriting_broadcasts_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: underwriting_invoices underwriting_invoices_agreement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.underwriting_invoices
    ADD CONSTRAINT underwriting_invoices_agreement_id_fkey FOREIGN KEY (agreement_id) REFERENCES public.underwriting_agreements(id);


--
-- Name: underwriting_invoices underwriting_invoices_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.underwriting_invoices
    ADD CONSTRAINT underwriting_invoices_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: underwriting_invoices underwriting_invoices_underwriter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.underwriting_invoices
    ADD CONSTRAINT underwriting_invoices_underwriter_id_fkey FOREIGN KEY (underwriter_id) REFERENCES public.underwriters(id);


--
-- Name: verification_logs verification_logs_press_pass_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.verification_logs
    ADD CONSTRAINT verification_logs_press_pass_id_fkey FOREIGN KEY (press_pass_id) REFERENCES public.press_passes(id);


--
-- Name: addresses; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;

--
-- Name: addresses addresses_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY addresses_anon_deny_all ON public.addresses TO anon USING (false);


--
-- Name: addresses addresses_authenticated_deny_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY addresses_authenticated_deny_delete ON public.addresses FOR DELETE TO authenticated USING (false);


--
-- Name: addresses addresses_authenticated_deny_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY addresses_authenticated_deny_insert ON public.addresses FOR INSERT TO authenticated WITH CHECK (false);


--
-- Name: addresses addresses_authenticated_deny_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY addresses_authenticated_deny_update ON public.addresses FOR UPDATE TO authenticated USING (false);


--
-- Name: addresses addresses_authenticated_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY addresses_authenticated_select ON public.addresses FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM (public.profiles p
     JOIN public.donors d ON ((d.station_id = p.station_id)))
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND (d.id = addresses.donor_id) AND (p.role = ANY (ARRAY['super_admin'::text, 'admin'::text, 'ops'::text, 'volunteer'::text])))))));


--
-- Name: addresses addresses_donor_self_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY addresses_donor_self_select ON public.addresses FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.donor_id = addresses.donor_id) AND (p.role = 'donor'::text))))));


--
-- Name: addresses addresses_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY addresses_service_role_all ON public.addresses TO service_role USING (true) WITH CHECK (true);


--
-- Name: invites admin_station_invites; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY admin_station_invites ON public.invites TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'admin'::text) AND (profiles.station_id = invites.station_id) AND (profiles.is_active = true) AND (profiles.deleted_at IS NULL)))));


--
-- Name: audit_log; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

--
-- Name: audit_log audit_log_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY audit_log_anon_deny_all ON public.audit_log TO anon USING (false);


--
-- Name: audit_log audit_log_authenticated_deny_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY audit_log_authenticated_deny_delete ON public.audit_log FOR DELETE TO authenticated USING (false);


--
-- Name: audit_log audit_log_authenticated_deny_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY audit_log_authenticated_deny_insert ON public.audit_log FOR INSERT TO authenticated WITH CHECK (false);


--
-- Name: audit_log audit_log_authenticated_deny_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY audit_log_authenticated_deny_update ON public.audit_log FOR UPDATE TO authenticated USING (false);


--
-- Name: audit_log audit_log_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY audit_log_service_role_all ON public.audit_log TO service_role USING (true) WITH CHECK (true);


--
-- Name: audit_log audit_log_super_admin_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY audit_log_super_admin_select ON public.audit_log FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND (p.role = 'super_admin'::text)))));


--
-- Name: campaign_shows; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.campaign_shows ENABLE ROW LEVEL SECURITY;

--
-- Name: campaign_shows campaign_shows_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY campaign_shows_select ON public.campaign_shows FOR SELECT TO authenticated USING (true);


--
-- Name: campaign_shows campaign_shows_service_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY campaign_shows_service_all ON public.campaign_shows TO service_role USING (true) WITH CHECK (true);


--
-- Name: campaigns; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;

--
-- Name: campaigns campaigns_anon_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY campaigns_anon_select ON public.campaigns FOR SELECT TO anon USING ((deleted_at IS NULL));


--
-- Name: campaigns campaigns_authenticated_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY campaigns_authenticated_select ON public.campaigns FOR SELECT TO authenticated USING ((deleted_at IS NULL));


--
-- Name: campaigns campaigns_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY campaigns_service_role_all ON public.campaigns TO service_role USING (true) WITH CHECK (true);


--
-- Name: checkout_sessions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.checkout_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: checkout_sessions checkout_sessions_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY checkout_sessions_anon_deny_all ON public.checkout_sessions TO anon USING (false);


--
-- Name: checkout_sessions checkout_sessions_authenticated_deny_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY checkout_sessions_authenticated_deny_delete ON public.checkout_sessions FOR DELETE TO authenticated USING (false);


--
-- Name: checkout_sessions checkout_sessions_authenticated_deny_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY checkout_sessions_authenticated_deny_insert ON public.checkout_sessions FOR INSERT TO authenticated WITH CHECK (false);


--
-- Name: checkout_sessions checkout_sessions_authenticated_deny_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY checkout_sessions_authenticated_deny_update ON public.checkout_sessions FOR UPDATE TO authenticated USING (false);


--
-- Name: checkout_sessions checkout_sessions_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY checkout_sessions_service_role_all ON public.checkout_sessions TO service_role USING (true) WITH CHECK (true);


--
-- Name: checkout_sessions checkout_sessions_station_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY checkout_sessions_station_staff_select ON public.checkout_sessions FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND ((p.role = 'super_admin'::text) OR ((p.role = ANY (ARRAY['admin'::text, 'ops'::text, 'volunteer'::text])) AND (p.station_id = checkout_sessions.station_id)))))));


--
-- Name: documents; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

--
-- Name: documents documents_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY documents_anon_deny_all ON public.documents TO anon USING (false);


--
-- Name: documents documents_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY documents_service_role_all ON public.documents TO service_role USING (true) WITH CHECK (true);


--
-- Name: documents documents_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY documents_staff_select ON public.documents FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND ((p.role = 'super_admin'::text) OR ((p.role = 'admin'::text) AND (p.station_id = documents.station_id) AND (documents.visibility_level = ANY (ARRAY['station'::text, 'admin_only'::text]))) OR ((p.role = 'ops'::text) AND (p.station_id = documents.station_id) AND (documents.visibility_level = 'station'::text))))))));


--
-- Name: donations; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;

--
-- Name: donations donations_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donations_anon_deny_all ON public.donations TO anon USING (false);


--
-- Name: donations donations_authenticated_deny_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donations_authenticated_deny_delete ON public.donations FOR DELETE TO authenticated USING (false);


--
-- Name: donations donations_authenticated_deny_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donations_authenticated_deny_insert ON public.donations FOR INSERT TO authenticated WITH CHECK (false);


--
-- Name: donations donations_authenticated_deny_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donations_authenticated_deny_update ON public.donations FOR UPDATE TO authenticated USING (false);


--
-- Name: donations donations_self_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donations_self_select ON public.donations FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM (public.profiles p
     JOIN public.donors d ON ((d.id = p.donor_id)))
  WHERE ((p.id = auth.uid()) AND (p.role = 'donor'::text) AND (donations.donor_id = d.id))))));


--
-- Name: donations donations_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donations_service_role_all ON public.donations TO service_role USING (true) WITH CHECK (true);


--
-- Name: donations donations_station_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donations_station_staff_select ON public.donations FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND ((p.role = 'super_admin'::text) OR ((p.role = ANY (ARRAY['admin'::text, 'ops'::text, 'volunteer'::text])) AND (p.station_id = donations.station_id))))))));


--
-- Name: donor_extensions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.donor_extensions ENABLE ROW LEVEL SECURITY;

--
-- Name: donor_extensions donor_extensions_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donor_extensions_anon_deny_all ON public.donor_extensions TO anon USING (false);


--
-- Name: donor_extensions donor_extensions_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donor_extensions_service_role_all ON public.donor_extensions TO service_role USING (true) WITH CHECK (true);


--
-- Name: donor_extensions donor_extensions_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donor_extensions_staff_select ON public.donor_extensions FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM (public.profiles p
     JOIN public.donors d ON ((d.station_id = p.station_id)))
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND (d.id = donor_extensions.donor_id) AND (p.role = ANY (ARRAY['super_admin'::text, 'admin'::text, 'ops'::text]))))));


--
-- Name: donor_notes; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.donor_notes ENABLE ROW LEVEL SECURITY;

--
-- Name: donor_notes donor_notes_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donor_notes_anon_deny_all ON public.donor_notes TO anon USING (false);


--
-- Name: donor_notes donor_notes_authenticated_deny_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donor_notes_authenticated_deny_delete ON public.donor_notes FOR DELETE TO authenticated USING (false);


--
-- Name: donor_notes donor_notes_authenticated_deny_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donor_notes_authenticated_deny_insert ON public.donor_notes FOR INSERT TO authenticated WITH CHECK (false);


--
-- Name: donor_notes donor_notes_authenticated_deny_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donor_notes_authenticated_deny_update ON public.donor_notes FOR UPDATE TO authenticated USING (false);


--
-- Name: donor_notes donor_notes_donor_self_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donor_notes_donor_self_select ON public.donor_notes FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (note_type = 'donor_visible'::text) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.donor_id = donor_notes.donor_id) AND (p.role = 'donor'::text))))));


--
-- Name: donor_notes donor_notes_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donor_notes_service_role_all ON public.donor_notes TO service_role USING (true) WITH CHECK (true);


--
-- Name: donor_notes donor_notes_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donor_notes_staff_select ON public.donor_notes FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM (public.profiles p
     JOIN public.donors d ON ((d.station_id = p.station_id)))
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND (d.id = donor_notes.donor_id) AND (p.role = ANY (ARRAY['super_admin'::text, 'admin'::text, 'ops'::text])))))));


--
-- Name: donor_tags; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.donor_tags ENABLE ROW LEVEL SECURITY;

--
-- Name: donor_tags donor_tags_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donor_tags_anon_deny_all ON public.donor_tags TO anon USING (false);


--
-- Name: donor_tags donor_tags_authenticated_deny_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donor_tags_authenticated_deny_delete ON public.donor_tags FOR DELETE TO authenticated USING (false);


--
-- Name: donor_tags donor_tags_authenticated_deny_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donor_tags_authenticated_deny_insert ON public.donor_tags FOR INSERT TO authenticated WITH CHECK (false);


--
-- Name: donor_tags donor_tags_authenticated_deny_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donor_tags_authenticated_deny_update ON public.donor_tags FOR UPDATE TO authenticated USING (false);


--
-- Name: donor_tags donor_tags_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donor_tags_service_role_all ON public.donor_tags TO service_role USING (true) WITH CHECK (true);


--
-- Name: donor_tags donor_tags_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donor_tags_staff_select ON public.donor_tags FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM (public.profiles p
     JOIN public.donors d ON ((d.station_id = p.station_id)))
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND (d.id = donor_tags.donor_id) AND (p.role = ANY (ARRAY['super_admin'::text, 'admin'::text, 'ops'::text, 'volunteer'::text])))))));


--
-- Name: donors; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.donors ENABLE ROW LEVEL SECURITY;

--
-- Name: donors donors_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donors_anon_deny_all ON public.donors TO anon USING (false);


--
-- Name: donors donors_authenticated_deny_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donors_authenticated_deny_delete ON public.donors FOR DELETE TO authenticated USING (false);


--
-- Name: donors donors_authenticated_deny_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donors_authenticated_deny_insert ON public.donors FOR INSERT TO authenticated WITH CHECK (false);


--
-- Name: donors donors_authenticated_deny_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donors_authenticated_deny_update ON public.donors FOR UPDATE TO authenticated USING (false);


--
-- Name: donors donors_self_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donors_self_select ON public.donors FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.donor_id = donors.id) AND (p.role = 'donor'::text))))));


--
-- Name: donors donors_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donors_service_role_all ON public.donors TO service_role USING (true) WITH CHECK (true);


--
-- Name: donors donors_station_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY donors_station_staff_select ON public.donors FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND ((p.role = 'super_admin'::text) OR ((p.role = ANY (ARRAY['admin'::text, 'ops'::text, 'volunteer'::text])) AND (p.station_id = donors.station_id))))))));


--
-- Name: email_log; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.email_log ENABLE ROW LEVEL SECURITY;

--
-- Name: email_log email_log_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY email_log_anon_deny_all ON public.email_log TO anon USING (false);


--
-- Name: email_log email_log_authenticated_deny_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY email_log_authenticated_deny_delete ON public.email_log FOR DELETE TO authenticated USING (false);


--
-- Name: email_log email_log_authenticated_deny_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY email_log_authenticated_deny_insert ON public.email_log FOR INSERT TO authenticated WITH CHECK (false);


--
-- Name: email_log email_log_authenticated_deny_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY email_log_authenticated_deny_update ON public.email_log FOR UPDATE TO authenticated USING (false);


--
-- Name: email_log email_log_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY email_log_service_role_all ON public.email_log TO service_role USING (true) WITH CHECK (true);


--
-- Name: email_log email_log_station_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY email_log_station_staff_select ON public.email_log FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND ((p.role = 'super_admin'::text) OR ((p.role = ANY (ARRAY['admin'::text, 'ops'::text])) AND (p.station_id = email_log.station_id)))))));


--
-- Name: event_registration_gifts; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.event_registration_gifts ENABLE ROW LEVEL SECURITY;

--
-- Name: event_registration_gifts event_registration_gifts_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY event_registration_gifts_anon_deny_all ON public.event_registration_gifts TO anon USING (false);


--
-- Name: event_registration_gifts event_registration_gifts_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY event_registration_gifts_service_role_all ON public.event_registration_gifts TO service_role USING (true) WITH CHECK (true);


--
-- Name: event_registration_gifts event_registration_gifts_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY event_registration_gifts_staff_select ON public.event_registration_gifts FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM ((public.event_registrations er
     JOIN public.events e ON ((e.id = er.event_id)))
     JOIN public.profiles p ON ((p.station_id = e.station_id)))
  WHERE ((er.id = event_registration_gifts.registration_id) AND (p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND (p.role = ANY (ARRAY['super_admin'::text, 'admin'::text, 'ops'::text, 'volunteer'::text]))))));


--
-- Name: event_registrations; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.event_registrations ENABLE ROW LEVEL SECURITY;

--
-- Name: event_registrations event_registrations_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY event_registrations_anon_deny_all ON public.event_registrations TO anon USING (false);


--
-- Name: event_registrations event_registrations_donor_self_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY event_registrations_donor_self_select ON public.event_registrations FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.donor_id = event_registrations.donor_id))))));


--
-- Name: event_registrations event_registrations_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY event_registrations_service_role_all ON public.event_registrations TO service_role USING (true) WITH CHECK (true);


--
-- Name: event_registrations event_registrations_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY event_registrations_staff_select ON public.event_registrations FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM (public.profiles p
     JOIN public.events e ON ((e.station_id = p.station_id)))
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND (e.id = event_registrations.event_id) AND (p.role = ANY (ARRAY['super_admin'::text, 'admin'::text, 'ops'::text, 'volunteer'::text])))))));


--
-- Name: events; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

--
-- Name: events events_anon_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY events_anon_select ON public.events FOR SELECT TO anon USING (((deleted_at IS NULL) AND (status = 'published'::text)));


--
-- Name: events events_authenticated_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY events_authenticated_select ON public.events FOR SELECT TO authenticated USING ((deleted_at IS NULL));


--
-- Name: events events_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY events_service_role_all ON public.events TO service_role USING (true) WITH CHECK (true);


--
-- Name: feedback_responses; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.feedback_responses ENABLE ROW LEVEL SECURITY;

--
-- Name: feedback_responses feedback_staff_read; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY feedback_staff_read ON public.feedback_responses FOR SELECT TO authenticated USING ((station_id IN ( SELECT profiles.station_id
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = ANY (ARRAY['super_admin'::text, 'admin'::text, 'ops'::text])) AND (profiles.deleted_at IS NULL)))));


--
-- Name: feedback_responses feedback_super_admin_read; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY feedback_super_admin_read ON public.feedback_responses FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'super_admin'::text) AND (profiles.deleted_at IS NULL)))));


--
-- Name: fulfillment_items; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.fulfillment_items ENABLE ROW LEVEL SECURITY;

--
-- Name: fulfillment_items fulfillment_items_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY fulfillment_items_anon_deny_all ON public.fulfillment_items TO anon USING (false);


--
-- Name: fulfillment_items fulfillment_items_authenticated_deny_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY fulfillment_items_authenticated_deny_delete ON public.fulfillment_items FOR DELETE TO authenticated USING (false);


--
-- Name: fulfillment_items fulfillment_items_authenticated_deny_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY fulfillment_items_authenticated_deny_insert ON public.fulfillment_items FOR INSERT TO authenticated WITH CHECK (false);


--
-- Name: fulfillment_items fulfillment_items_authenticated_deny_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY fulfillment_items_authenticated_deny_update ON public.fulfillment_items FOR UPDATE TO authenticated USING (false);


--
-- Name: fulfillment_items fulfillment_items_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY fulfillment_items_service_role_all ON public.fulfillment_items TO service_role USING (true) WITH CHECK (true);


--
-- Name: fulfillment_items fulfillment_items_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY fulfillment_items_staff_select ON public.fulfillment_items FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM (public.profiles p
     JOIN public.donations don ON ((don.station_id = p.station_id)))
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND (don.id = fulfillment_items.donation_id) AND (p.role = ANY (ARRAY['super_admin'::text, 'admin'::text, 'ops'::text, 'volunteer'::text])))))));


--
-- Name: gift_intents; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.gift_intents ENABLE ROW LEVEL SECURITY;

--
-- Name: gift_intents gift_intents_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY gift_intents_anon_deny_all ON public.gift_intents TO anon USING (false);


--
-- Name: gift_intents gift_intents_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY gift_intents_service_role_all ON public.gift_intents TO service_role USING (true) WITH CHECK (true);


--
-- Name: gift_intents gift_intents_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY gift_intents_staff_select ON public.gift_intents FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND ((p.role = 'super_admin'::text) OR ((p.role = ANY (ARRAY['admin'::text, 'ops'::text])) AND (p.station_id = gift_intents.station_id)))))));


--
-- Name: gift_variants; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.gift_variants ENABLE ROW LEVEL SECURITY;

--
-- Name: gift_variants gift_variants_anon_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY gift_variants_anon_select ON public.gift_variants FOR SELECT TO anon USING (((deleted_at IS NULL) AND (is_active = true)));


--
-- Name: gift_variants gift_variants_authenticated_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY gift_variants_authenticated_select ON public.gift_variants FOR SELECT TO authenticated USING ((deleted_at IS NULL));


--
-- Name: gift_variants gift_variants_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY gift_variants_service_role_all ON public.gift_variants TO service_role USING (true) WITH CHECK (true);


--
-- Name: gifts; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.gifts ENABLE ROW LEVEL SECURITY;

--
-- Name: gifts gifts_anon_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY gifts_anon_select ON public.gifts FOR SELECT TO anon USING (((deleted_at IS NULL) AND (is_active = true)));


--
-- Name: gifts gifts_authenticated_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY gifts_authenticated_select ON public.gifts FOR SELECT TO authenticated USING ((deleted_at IS NULL));


--
-- Name: gifts gifts_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY gifts_service_role_all ON public.gifts TO service_role USING (true) WITH CHECK (true);


--
-- Name: interactions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.interactions ENABLE ROW LEVEL SECURITY;

--
-- Name: interactions interactions_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY interactions_anon_deny_all ON public.interactions TO anon USING (false);


--
-- Name: interactions interactions_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY interactions_service_role_all ON public.interactions TO service_role USING (true) WITH CHECK (true);


--
-- Name: interactions interactions_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY interactions_staff_select ON public.interactions FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND ((p.role = 'super_admin'::text) OR ((p.role = ANY (ARRAY['admin'::text, 'ops'::text])) AND (p.station_id = interactions.station_id)))))));


--
-- Name: invites; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.invites ENABLE ROW LEVEL SECURITY;

--
-- Name: match_allocations; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.match_allocations ENABLE ROW LEVEL SECURITY;

--
-- Name: match_allocations match_allocations_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY match_allocations_anon_deny_all ON public.match_allocations TO anon USING (false);


--
-- Name: match_allocations match_allocations_authenticated_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY match_allocations_authenticated_select ON public.match_allocations FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM (public.profiles p
     JOIN public.donations d ON ((d.station_id = p.station_id)))
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND (d.id = match_allocations.donation_id) AND (p.role = ANY (ARRAY['super_admin'::text, 'admin'::text, 'ops'::text]))))));


--
-- Name: match_allocations match_allocations_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY match_allocations_service_role_all ON public.match_allocations TO service_role USING (true) WITH CHECK (true);


--
-- Name: match_pools; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.match_pools ENABLE ROW LEVEL SECURITY;

--
-- Name: match_pools match_pools_anon_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY match_pools_anon_select ON public.match_pools FOR SELECT TO anon USING (((deleted_at IS NULL) AND (is_active = true) AND (is_public = true)));


--
-- Name: match_pools match_pools_authenticated_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY match_pools_authenticated_select ON public.match_pools FOR SELECT TO authenticated USING ((deleted_at IS NULL));


--
-- Name: match_pools match_pools_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY match_pools_service_role_all ON public.match_pools TO service_role USING (true) WITH CHECK (true);


--
-- Name: memberships; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.memberships ENABLE ROW LEVEL SECURITY;

--
-- Name: memberships memberships_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY memberships_anon_deny_all ON public.memberships TO anon USING (false);


--
-- Name: memberships memberships_authenticated_deny_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY memberships_authenticated_deny_delete ON public.memberships FOR DELETE TO authenticated USING (false);


--
-- Name: memberships memberships_authenticated_deny_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY memberships_authenticated_deny_insert ON public.memberships FOR INSERT TO authenticated WITH CHECK (false);


--
-- Name: memberships memberships_authenticated_deny_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY memberships_authenticated_deny_update ON public.memberships FOR UPDATE TO authenticated USING (false);


--
-- Name: memberships memberships_self_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY memberships_self_select ON public.memberships FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM (public.profiles p
     JOIN public.donors d ON ((d.id = p.donor_id)))
  WHERE ((p.id = auth.uid()) AND (p.role = 'donor'::text) AND (memberships.donor_id = d.id))))));


--
-- Name: memberships memberships_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY memberships_service_role_all ON public.memberships TO service_role USING (true) WITH CHECK (true);


--
-- Name: memberships memberships_station_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY memberships_station_staff_select ON public.memberships FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND ((p.role = 'super_admin'::text) OR ((p.role = ANY (ARRAY['admin'::text, 'ops'::text, 'volunteer'::text])) AND (p.station_id = memberships.station_id))))))));


--
-- Name: payment_intents; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.payment_intents ENABLE ROW LEVEL SECURITY;

--
-- Name: payment_intents payment_intents_authenticated_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY payment_intents_authenticated_all ON public.payment_intents TO authenticated USING (true) WITH CHECK (true);


--
-- Name: payment_intents payment_intents_authenticated_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY payment_intents_authenticated_insert ON public.payment_intents FOR INSERT TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM auth.users
  WHERE (users.id = auth.uid()))));


--
-- Name: payment_intents payment_intents_authenticated_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY payment_intents_authenticated_select ON public.payment_intents FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM auth.users
  WHERE (users.id = auth.uid()))));


--
-- Name: payment_intents payment_intents_authenticated_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY payment_intents_authenticated_update ON public.payment_intents FOR UPDATE TO authenticated USING ((EXISTS ( SELECT 1
   FROM auth.users
  WHERE (users.id = auth.uid()))));


--
-- Name: payment_intents payment_intents_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY payment_intents_service_role_all ON public.payment_intents TO service_role USING (true) WITH CHECK (true);


--
-- Name: press_passes; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.press_passes ENABLE ROW LEVEL SECURITY;

--
-- Name: press_passes press_passes_anon_select_for_verification; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY press_passes_anon_select_for_verification ON public.press_passes FOR SELECT TO anon USING ((deleted_at IS NULL));


--
-- Name: press_passes press_passes_authenticated_deny_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY press_passes_authenticated_deny_delete ON public.press_passes FOR DELETE TO authenticated USING (false);


--
-- Name: press_passes press_passes_authenticated_deny_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY press_passes_authenticated_deny_insert ON public.press_passes FOR INSERT TO authenticated WITH CHECK (false);


--
-- Name: press_passes press_passes_authenticated_deny_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY press_passes_authenticated_deny_update ON public.press_passes FOR UPDATE TO authenticated USING (false);


--
-- Name: press_passes press_passes_authenticated_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY press_passes_authenticated_select ON public.press_passes FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.station_id = press_passes.station_id) AND (profiles.deleted_at IS NULL))))));


--
-- Name: press_passes press_passes_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY press_passes_service_role_all ON public.press_passes TO service_role USING (true) WITH CHECK (true);


--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles profiles_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_anon_deny_all ON public.profiles TO anon USING (false);


--
-- Name: profiles profiles_self_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_self_select ON public.profiles FOR SELECT TO authenticated USING (((id = auth.uid()) AND (deleted_at IS NULL)));


--
-- Name: profiles profiles_self_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_self_update ON public.profiles FOR UPDATE TO authenticated USING (((id = auth.uid()) AND (deleted_at IS NULL))) WITH CHECK ((id = auth.uid()));


--
-- Name: profiles profiles_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_service_role_all ON public.profiles TO service_role USING (true) WITH CHECK (true);


--
-- Name: profiles profiles_station_admin_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_station_admin_select ON public.profiles FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM public.get_current_user_profile() p(id, role, station_id, is_active)
  WHERE ((p.is_active = true) AND ((p.role = 'super_admin'::text) OR ((p.role = ANY (ARRAY['admin'::text, 'ops'::text])) AND (p.station_id = profiles.station_id))))))));


--
-- Name: promo_codes; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;

--
-- Name: promo_codes promo_codes_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY promo_codes_anon_deny_all ON public.promo_codes TO anon USING (false);


--
-- Name: promo_codes promo_codes_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY promo_codes_service_role_all ON public.promo_codes TO service_role USING (true) WITH CHECK (true);


--
-- Name: promo_codes promo_codes_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY promo_codes_staff_select ON public.promo_codes FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND ((p.role = 'super_admin'::text) OR (p.station_id = promo_codes.station_id)))))));


--
-- Name: shows; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.shows ENABLE ROW LEVEL SECURITY;

--
-- Name: shows shows_anon_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY shows_anon_select ON public.shows FOR SELECT TO anon USING ((deleted_at IS NULL));


--
-- Name: shows shows_authenticated_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY shows_authenticated_select ON public.shows FOR SELECT TO authenticated USING ((deleted_at IS NULL));


--
-- Name: shows shows_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY shows_service_role_all ON public.shows TO service_role USING (true) WITH CHECK (true);


--
-- Name: station_sequences; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.station_sequences ENABLE ROW LEVEL SECURITY;

--
-- Name: station_sequences station_sequences_authenticated_read; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY station_sequences_authenticated_read ON public.station_sequences FOR SELECT TO authenticated USING (true);


--
-- Name: station_sequences station_sequences_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY station_sequences_service_role_all ON public.station_sequences TO service_role USING (true) WITH CHECK (true);


--
-- Name: stations; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.stations ENABLE ROW LEVEL SECURITY;

--
-- Name: stations stations_anon_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY stations_anon_select ON public.stations FOR SELECT TO anon USING ((deleted_at IS NULL));


--
-- Name: stations stations_authenticated_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY stations_authenticated_select ON public.stations FOR SELECT TO authenticated USING ((deleted_at IS NULL));


--
-- Name: stations stations_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY stations_service_role_all ON public.stations TO service_role USING (true) WITH CHECK (true);


--
-- Name: invites super_admin_all_invites; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY super_admin_all_invites ON public.invites TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'super_admin'::text) AND (profiles.is_active = true) AND (profiles.deleted_at IS NULL)))));


--
-- Name: system_events; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.system_events ENABLE ROW LEVEL SECURITY;

--
-- Name: system_events system_events_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY system_events_anon_deny_all ON public.system_events TO anon USING (false);


--
-- Name: system_events system_events_authenticated_deny_write; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY system_events_authenticated_deny_write ON public.system_events FOR INSERT TO authenticated WITH CHECK (false);


--
-- Name: system_events system_events_authenticated_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY system_events_authenticated_select ON public.system_events FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM auth.users
  WHERE (users.id = auth.uid()))));


--
-- Name: system_events system_events_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY system_events_service_role_all ON public.system_events TO service_role USING (true) WITH CHECK (true);


--
-- Name: tax_documents; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.tax_documents ENABLE ROW LEVEL SECURITY;

--
-- Name: tax_documents tax_documents_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY tax_documents_anon_deny_all ON public.tax_documents TO anon USING (false);


--
-- Name: tax_documents tax_documents_authenticated_deny_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY tax_documents_authenticated_deny_delete ON public.tax_documents FOR DELETE TO authenticated USING (false);


--
-- Name: tax_documents tax_documents_authenticated_deny_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY tax_documents_authenticated_deny_insert ON public.tax_documents FOR INSERT TO authenticated WITH CHECK (false);


--
-- Name: tax_documents tax_documents_authenticated_deny_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY tax_documents_authenticated_deny_update ON public.tax_documents FOR UPDATE TO authenticated USING (false);


--
-- Name: tax_documents tax_documents_self_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY tax_documents_self_select ON public.tax_documents FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM ((public.profiles p
     JOIN public.donors d ON ((d.id = p.donor_id)))
     JOIN public.donations don ON ((don.donor_id = d.id)))
  WHERE ((p.id = auth.uid()) AND (p.role = 'donor'::text) AND (tax_documents.donation_id = don.id)))));


--
-- Name: tax_documents tax_documents_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY tax_documents_service_role_all ON public.tax_documents TO service_role USING (true) WITH CHECK (true);


--
-- Name: tax_documents tax_documents_station_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY tax_documents_station_staff_select ON public.tax_documents FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM (public.profiles p
     JOIN public.donations don ON ((don.id = tax_documents.donation_id)))
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND ((p.role = 'super_admin'::text) OR ((p.role = ANY (ARRAY['admin'::text, 'ops'::text])) AND (p.station_id = don.station_id)))))));


--
-- Name: ticket_types; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.ticket_types ENABLE ROW LEVEL SECURITY;

--
-- Name: ticket_types ticket_types_anon_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY ticket_types_anon_select ON public.ticket_types FOR SELECT TO anon USING (((deleted_at IS NULL) AND (is_active = true) AND (EXISTS ( SELECT 1
   FROM public.events e
  WHERE ((e.id = ticket_types.event_id) AND (e.status = 'published'::text) AND (e.deleted_at IS NULL))))));


--
-- Name: ticket_types ticket_types_authenticated_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY ticket_types_authenticated_select ON public.ticket_types FOR SELECT TO authenticated USING ((deleted_at IS NULL));


--
-- Name: ticket_types ticket_types_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY ticket_types_service_role_all ON public.ticket_types TO service_role USING (true) WITH CHECK (true);


--
-- Name: underwriters; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.underwriters ENABLE ROW LEVEL SECURITY;

--
-- Name: underwriters underwriters_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY underwriters_anon_deny_all ON public.underwriters TO anon USING (false);


--
-- Name: underwriters underwriters_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY underwriters_service_role_all ON public.underwriters TO service_role USING (true) WITH CHECK (true);


--
-- Name: underwriters underwriters_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY underwriters_staff_select ON public.underwriters FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND ((p.role = 'super_admin'::text) OR ((p.role = ANY (ARRAY['admin'::text, 'ops'::text])) AND (p.station_id = underwriters.station_id))))))));


--
-- Name: underwriting_agreements; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.underwriting_agreements ENABLE ROW LEVEL SECURITY;

--
-- Name: underwriting_broadcasts; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.underwriting_broadcasts ENABLE ROW LEVEL SECURITY;

--
-- Name: underwriting_invoices; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.underwriting_invoices ENABLE ROW LEVEL SECURITY;

--
-- Name: underwriting_agreements uw_agreements_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY uw_agreements_anon_deny_all ON public.underwriting_agreements TO anon USING (false);


--
-- Name: underwriting_agreements uw_agreements_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY uw_agreements_service_role_all ON public.underwriting_agreements TO service_role USING (true) WITH CHECK (true);


--
-- Name: underwriting_agreements uw_agreements_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY uw_agreements_staff_select ON public.underwriting_agreements FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND ((p.role = 'super_admin'::text) OR ((p.role = ANY (ARRAY['admin'::text, 'ops'::text])) AND (p.station_id = underwriting_agreements.station_id))))))));


--
-- Name: underwriting_broadcasts uw_broadcasts_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY uw_broadcasts_anon_deny_all ON public.underwriting_broadcasts TO anon USING (false);


--
-- Name: underwriting_broadcasts uw_broadcasts_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY uw_broadcasts_service_role_all ON public.underwriting_broadcasts TO service_role USING (true) WITH CHECK (true);


--
-- Name: underwriting_broadcasts uw_broadcasts_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY uw_broadcasts_staff_select ON public.underwriting_broadcasts FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND ((p.role = 'super_admin'::text) OR ((p.role = ANY (ARRAY['admin'::text, 'ops'::text])) AND (p.station_id = underwriting_broadcasts.station_id)))))));


--
-- Name: underwriting_invoices uw_invoices_anon_deny_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY uw_invoices_anon_deny_all ON public.underwriting_invoices TO anon USING (false);


--
-- Name: underwriting_invoices uw_invoices_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY uw_invoices_service_role_all ON public.underwriting_invoices TO service_role USING (true) WITH CHECK (true);


--
-- Name: underwriting_invoices uw_invoices_staff_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY uw_invoices_staff_select ON public.underwriting_invoices FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.deleted_at IS NULL) AND (p.is_active = true) AND ((p.role = 'super_admin'::text) OR ((p.role = ANY (ARRAY['admin'::text, 'ops'::text])) AND (p.station_id = underwriting_invoices.station_id))))))));


--
-- Name: verification_logs; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.verification_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: verification_logs verification_logs_anon_deny_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY verification_logs_anon_deny_select ON public.verification_logs FOR SELECT TO anon USING (false);


--
-- Name: verification_logs verification_logs_anon_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY verification_logs_anon_insert ON public.verification_logs FOR INSERT TO anon WITH CHECK (true);


--
-- Name: verification_logs verification_logs_authenticated_deny_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY verification_logs_authenticated_deny_delete ON public.verification_logs FOR DELETE TO authenticated USING (false);


--
-- Name: verification_logs verification_logs_authenticated_deny_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY verification_logs_authenticated_deny_update ON public.verification_logs FOR UPDATE TO authenticated USING (false);


--
-- Name: verification_logs verification_logs_authenticated_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY verification_logs_authenticated_insert ON public.verification_logs FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: verification_logs verification_logs_authenticated_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY verification_logs_authenticated_select ON public.verification_logs FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM (public.press_passes pp
     JOIN public.profiles p ON ((p.station_id = pp.station_id)))
  WHERE ((pp.id = verification_logs.press_pass_id) AND (p.id = auth.uid()) AND (p.deleted_at IS NULL)))));


--
-- Name: verification_logs verification_logs_service_role_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY verification_logs_service_role_all ON public.verification_logs TO service_role USING (true) WITH CHECK (true);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: FUNCTION generate_receipt_number(p_station_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.generate_receipt_number(p_station_id uuid) TO service_role;


--
-- Name: FUNCTION get_current_user_profile(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_current_user_profile() TO authenticated;


--
-- Name: FUNCTION search_donors_fuzzy(p_station_id uuid, p_query text, p_limit integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.search_donors_fuzzy(p_station_id uuid, p_query text, p_limit integer) TO authenticated;
GRANT ALL ON FUNCTION public.search_donors_fuzzy(p_station_id uuid, p_query text, p_limit integer) TO service_role;


--
-- Name: TABLE addresses; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.addresses TO service_role;
GRANT ALL ON TABLE public.addresses TO authenticated;


--
-- Name: TABLE audit_log; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.audit_log TO service_role;
GRANT ALL ON TABLE public.audit_log TO authenticated;


--
-- Name: TABLE campaigns; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.campaigns TO service_role;
GRANT SELECT ON TABLE public.campaigns TO anon;
GRANT ALL ON TABLE public.campaigns TO authenticated;


--
-- Name: TABLE checkout_sessions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.checkout_sessions TO service_role;
GRANT ALL ON TABLE public.checkout_sessions TO authenticated;


--
-- Name: TABLE donation_inspirations; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.donation_inspirations TO service_role;
GRANT ALL ON TABLE public.donation_inspirations TO authenticated;


--
-- Name: TABLE donations; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.donations TO service_role;
GRANT ALL ON TABLE public.donations TO authenticated;


--
-- Name: TABLE donor_notes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.donor_notes TO service_role;
GRANT ALL ON TABLE public.donor_notes TO authenticated;


--
-- Name: TABLE donor_tags; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.donor_tags TO service_role;
GRANT ALL ON TABLE public.donor_tags TO authenticated;


--
-- Name: TABLE donors; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.donors TO service_role;
GRANT ALL ON TABLE public.donors TO authenticated;


--
-- Name: TABLE email_log; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.email_log TO service_role;
GRANT ALL ON TABLE public.email_log TO authenticated;


--
-- Name: TABLE event_registrations; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.event_registrations TO service_role;


--
-- Name: TABLE events; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.events TO service_role;


--
-- Name: TABLE fulfillment_items; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.fulfillment_items TO service_role;
GRANT ALL ON TABLE public.fulfillment_items TO authenticated;


--
-- Name: TABLE gift_variants; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.gift_variants TO service_role;
GRANT ALL ON TABLE public.gift_variants TO authenticated;
GRANT SELECT ON TABLE public.gift_variants TO anon;


--
-- Name: TABLE gifts; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.gifts TO service_role;
GRANT SELECT ON TABLE public.gifts TO anon;
GRANT ALL ON TABLE public.gifts TO authenticated;


--
-- Name: TABLE invites; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.invites TO service_role;
GRANT ALL ON TABLE public.invites TO authenticated;


--
-- Name: TABLE match_allocations; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.match_allocations TO service_role;


--
-- Name: TABLE match_pools; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.match_pools TO service_role;


--
-- Name: TABLE memberships; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.memberships TO service_role;
GRANT ALL ON TABLE public.memberships TO authenticated;


--
-- Name: TABLE operator_activity_log; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.operator_activity_log TO service_role;
GRANT ALL ON TABLE public.operator_activity_log TO authenticated;


--
-- Name: TABLE payment_intents; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.payment_intents TO service_role;
GRANT ALL ON TABLE public.payment_intents TO authenticated;


--
-- Name: TABLE press_passes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.press_passes TO service_role;
GRANT SELECT ON TABLE public.press_passes TO authenticated;
GRANT SELECT ON TABLE public.press_passes TO anon;


--
-- Name: TABLE profiles; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profiles TO service_role;
GRANT ALL ON TABLE public.profiles TO authenticated;


--
-- Name: TABLE program_categories; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.program_categories TO service_role;
GRANT SELECT ON TABLE public.program_categories TO authenticated;
GRANT SELECT ON TABLE public.program_categories TO anon;


--
-- Name: TABLE program_host_assignments; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.program_host_assignments TO service_role;


--
-- Name: TABLE program_hosts; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.program_hosts TO service_role;
GRANT SELECT ON TABLE public.program_hosts TO authenticated;
GRANT SELECT ON TABLE public.program_hosts TO anon;


--
-- Name: TABLE program_schedule; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.program_schedule TO service_role;
GRANT SELECT ON TABLE public.program_schedule TO authenticated;
GRANT SELECT ON TABLE public.program_schedule TO anon;


--
-- Name: TABLE programs; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.programs TO service_role;
GRANT SELECT ON TABLE public.programs TO authenticated;
GRANT SELECT ON TABLE public.programs TO anon;


--
-- Name: TABLE promo_codes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.promo_codes TO service_role;


--
-- Name: TABLE shows; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.shows TO service_role;
GRANT SELECT ON TABLE public.shows TO anon;
GRANT ALL ON TABLE public.shows TO authenticated;


--
-- Name: TABLE station_sequences; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.station_sequences TO service_role;
GRANT SELECT ON TABLE public.station_sequences TO authenticated;


--
-- Name: TABLE stations; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.stations TO service_role;
GRANT SELECT ON TABLE public.stations TO anon;
GRANT SELECT ON TABLE public.stations TO authenticated;


--
-- Name: TABLE system_events; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.system_events TO service_role;
GRANT SELECT ON TABLE public.system_events TO authenticated;


--
-- Name: TABLE tax_documents; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.tax_documents TO service_role;
GRANT ALL ON TABLE public.tax_documents TO authenticated;


--
-- Name: TABLE ticket_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.ticket_types TO service_role;


--
-- Name: TABLE underwriters; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.underwriters TO service_role;


--
-- Name: TABLE underwriting_invoices; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.underwriting_invoices TO service_role;


--
-- Name: TABLE verification_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.verification_logs TO service_role;
GRANT SELECT,INSERT ON TABLE public.verification_logs TO authenticated;
GRANT INSERT ON TABLE public.verification_logs TO anon;


--
-- PostgreSQL database dump complete
--

-- Tell PostgREST to reload its schema cache
NOTIFY pgrst, 'reload schema';

