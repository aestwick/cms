-- 028_gift_catalog_schema.sql
-- Session 10 prep: Gift catalog schema additions
-- Run manually in Supabase SQL editor (already applied), 
-- committed here for repo parity.
--
-- Applied: 2026-02-18
-- Changes:
--   1. Fix audit_trigger_function to handle tables without station_id
--   2. Add gift catalog columns (split minimums, display flags, etc.)
--   3. Create gift_programs junction table
--   4. Create gift_campaigns junction table
--   5. Drop old minimum_cents column

-- ============================================================================
-- 1. FIX AUDIT TRIGGER FUNCTION
--    Extracts station_id from JSONB instead of NEW.station_id so it works
--    on tables that don't have a station_id column (e.g., gift_variants).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.audit_trigger_function()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$;


-- ============================================================================
-- 2. GIFTS TABLE: Add columns for split minimums and display
-- ============================================================================

ALTER TABLE public.gifts ADD COLUMN IF NOT EXISTS minimum_cents_onetime bigint NOT NULL DEFAULT 0;
ALTER TABLE public.gifts ADD COLUMN IF NOT EXISTS minimum_cents_monthly bigint NOT NULL DEFAULT 0;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'gifts_minimum_cents_onetime_check') THEN
    ALTER TABLE public.gifts ADD CONSTRAINT gifts_minimum_cents_onetime_check CHECK (minimum_cents_onetime >= 0);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'gifts_minimum_cents_monthly_check') THEN
    ALTER TABLE public.gifts ADD CONSTRAINT gifts_minimum_cents_monthly_check CHECK (minimum_cents_monthly >= 0);
  END IF;
END $$;

ALTER TABLE public.gifts ADD COLUMN IF NOT EXISTS image_url text NULL;
ALTER TABLE public.gifts ADD COLUMN IF NOT EXISTS is_featured boolean NOT NULL DEFAULT false;
ALTER TABLE public.gifts ADD COLUMN IF NOT EXISTS is_exclusive boolean NOT NULL DEFAULT false;
ALTER TABLE public.gifts ADD COLUMN IF NOT EXISTS is_hidden boolean NOT NULL DEFAULT false;
ALTER TABLE public.gifts ADD COLUMN IF NOT EXISTS no_recurring boolean NOT NULL DEFAULT false;
ALTER TABLE public.gifts ADD COLUMN IF NOT EXISTS expires_at timestamptz NULL;
ALTER TABLE public.gifts ADD COLUMN IF NOT EXISTS fulfillment_method text NOT NULL DEFAULT 'ship';

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'gifts_fulfillment_method_check') THEN
    ALTER TABLE public.gifts ADD CONSTRAINT gifts_fulfillment_method_check CHECK (
      fulfillment_method = ANY (ARRAY['ship', 'will_call', 'digital', 'none'])
    );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS gifts_featured_idx 
ON public.gifts (station_id, is_featured, sort_order) 
WHERE deleted_at IS NULL AND is_active = true;

CREATE INDEX IF NOT EXISTS gifts_expires_at_idx 
ON public.gifts (station_id, expires_at) 
WHERE deleted_at IS NULL AND expires_at IS NOT NULL;


-- ============================================================================
-- 3. GIFT_PROGRAMS JUNCTION TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.gift_programs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  gift_id uuid NOT NULL,
  program_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT gift_programs_pkey PRIMARY KEY (id),
  CONSTRAINT gift_programs_unique UNIQUE (gift_id, program_id),
  CONSTRAINT gift_programs_gift_id_fkey FOREIGN KEY (gift_id) REFERENCES public.gifts(id) ON DELETE CASCADE,
  CONSTRAINT gift_programs_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS gift_programs_gift_id_idx ON public.gift_programs (gift_id);
CREATE INDEX IF NOT EXISTS gift_programs_program_id_idx ON public.gift_programs (program_id);


-- ============================================================================
-- 4. GIFT_CAMPAIGNS JUNCTION TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.gift_campaigns (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  gift_id uuid NOT NULL,
  campaign_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT gift_campaigns_pkey PRIMARY KEY (id),
  CONSTRAINT gift_campaigns_unique UNIQUE (gift_id, campaign_id),
  CONSTRAINT gift_campaigns_gift_id_fkey FOREIGN KEY (gift_id) REFERENCES public.gifts(id) ON DELETE CASCADE,
  CONSTRAINT gift_campaigns_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS gift_campaigns_gift_id_idx ON public.gift_campaigns (gift_id);
CREATE INDEX IF NOT EXISTS gift_campaigns_campaign_id_idx ON public.gift_campaigns (campaign_id);


-- ============================================================================
-- 5. DROP OLD minimum_cents COLUMN
--    (Session 10b removed all code references)
-- ============================================================================

ALTER TABLE public.gifts DROP CONSTRAINT IF EXISTS gifts_minimum_cents_check;
ALTER TABLE public.gifts DROP COLUMN IF EXISTS minimum_cents;
