-- Migration 050: Digital Premium Assets
--
-- Three tables for gated digital content delivery:
-- 1. digital_assets — the content items (videos, audio, ebooks, documents)
-- 2. digital_asset_entitlements — rules for who can access (gift-based now, tier-based later)
-- 3. digital_asset_access_log — append-only audit trail of content views
--
-- Replaces the JSONB digital_assets column on the gifts table with a proper
-- normalized schema. The old column stays for backward compatibility — the API
-- queries the new tables instead.
--
-- Content lives on YouTube (unlisted) and OneDrive. Beacon controls access, not hosting.

-- ==========================================================================
-- Table 1: digital_assets
-- ==========================================================================
-- Stores the content items themselves. Each row is one video, audio file, etc.
-- The url column holds the actual content link (YouTube unlisted, OneDrive share)
-- and is NEVER returned in list endpoints — only via the gated /access endpoint.

CREATE TABLE public.digital_assets (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  station_id uuid NOT NULL,
  title text NOT NULL,
  -- What kind of content: video, audio, ebook, document
  asset_type text NOT NULL,
  -- The actual content URL — never exposed without entitlement check
  url text NOT NULL,
  -- Optional preview image (shown on the library card)
  thumbnail_url text NULL,
  -- Flexible metadata that varies by asset_type (speakers, duration, author, etc.)
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz NULL,

  CONSTRAINT digital_assets_pkey PRIMARY KEY (id),
  CONSTRAINT digital_assets_station_id_fkey FOREIGN KEY (station_id) REFERENCES stations(id),
  CONSTRAINT digital_assets_asset_type_check CHECK (
    asset_type = ANY(ARRAY['video', 'audio', 'ebook', 'document'])
  )
) TABLESPACE pg_default;

-- Find assets by station (most common query pattern)
CREATE INDEX digital_assets_station_id_idx
  ON public.digital_assets USING btree (station_id)
  WHERE deleted_at IS NULL;

-- Filter by type within a station (for admin filtering)
CREATE INDEX digital_assets_asset_type_idx
  ON public.digital_assets USING btree (station_id, asset_type)
  WHERE deleted_at IS NULL AND is_active = true;

-- Auto-update updated_at on any change
CREATE TRIGGER set_digital_assets_updated_at
  BEFORE UPDATE ON digital_assets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

COMMENT ON TABLE public.digital_assets IS
  'Digital content (videos, audio, ebooks) delivered via gated links. Content hosted externally (YouTube unlisted, OneDrive).';
COMMENT ON COLUMN public.digital_assets.url IS
  'The actual content URL (YouTube unlisted, OneDrive share link). Never exposed without entitlement check.';
COMMENT ON COLUMN public.digital_assets.metadata IS
  'Structured metadata varying by asset_type — speakers, duration, author, etc. Portal UI renders whatever keys are present.';

-- ==========================================================================
-- Table 2: digital_asset_entitlements
-- ==========================================================================
-- Rules for who can access a digital asset.
-- Phase 1: gift-based (donate and select a gift → unlock the linked content)
-- Phase 2: tier-based (active membership at a certain tier → unlock content)

CREATE TABLE public.digital_asset_entitlements (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  digital_asset_id uuid NOT NULL,
  -- 'gift' = unlocked by selecting this gift with a donation
  -- 'tier' = unlocked by having an active membership at this tier or above
  entitlement_type text NOT NULL,
  -- For gift-based: which gift unlocks this asset
  gift_id uuid NULL,
  -- For tier-based (Phase 2): minimum membership tier required
  tier_minimum text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT digital_asset_entitlements_pkey PRIMARY KEY (id),
  CONSTRAINT digital_asset_entitlements_asset_fkey
    FOREIGN KEY (digital_asset_id) REFERENCES digital_assets(id) ON DELETE CASCADE,
  -- RESTRICT, not CASCADE — soft deletes are the rule. If a gift is retired,
  -- set deleted_at on the gift. Entitlements stay intact so donors keep access.
  CONSTRAINT digital_asset_entitlements_gift_fkey
    FOREIGN KEY (gift_id) REFERENCES gifts(id) ON DELETE RESTRICT,
  CONSTRAINT digital_asset_entitlements_type_check CHECK (
    entitlement_type = ANY(ARRAY['gift', 'tier'])
  ),
  -- Mutual exclusion: gift entitlements need a gift_id, tier entitlements need
  -- a tier_minimum. Can't have both or neither.
  CONSTRAINT digital_asset_entitlements_gift_or_tier CHECK (
    (entitlement_type = 'gift' AND gift_id IS NOT NULL AND tier_minimum IS NULL)
    OR
    (entitlement_type = 'tier' AND tier_minimum IS NOT NULL AND gift_id IS NULL)
  )
) TABLESPACE pg_default;

-- Look up all entitlements for an asset (used when checking access)
CREATE INDEX digital_asset_entitlements_asset_idx
  ON public.digital_asset_entitlements USING btree (digital_asset_id);

-- Look up all assets linked to a gift (used in library query)
CREATE INDEX digital_asset_entitlements_gift_idx
  ON public.digital_asset_entitlements USING btree (gift_id)
  WHERE gift_id IS NOT NULL;

-- Prevent the same gift from being linked to the same asset twice
CREATE UNIQUE INDEX digital_asset_entitlements_unique_gift_idx
  ON public.digital_asset_entitlements USING btree (digital_asset_id, gift_id)
  WHERE entitlement_type = 'gift';

COMMENT ON TABLE public.digital_asset_entitlements IS
  'Rules for who can access a digital asset. Phase 1: gift-based. Phase 2: tier-based.';

-- ==========================================================================
-- Table 3: digital_asset_access_log
-- ==========================================================================
-- Append-only audit trail. Every time a donor clicks "Access" and we return
-- the content URL, a row is logged here. Used for:
-- 1. Analytics (how popular is each asset?)
-- 2. Leak investigation (if an unlisted URL gets shared, who accessed it?)
-- 3. Refund auditing (was content accessed before refund?)

CREATE TABLE public.digital_asset_access_log (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  digital_asset_id uuid NOT NULL,
  donor_id uuid NOT NULL,
  -- Denormalized for reporting queries without joins
  station_id uuid NOT NULL,
  -- Traces back to WHY the donor had access (which donation, which rule)
  donation_id uuid NULL,
  entitlement_id uuid NULL,
  ip_address inet NULL,
  user_agent text NULL,
  accessed_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT digital_asset_access_log_pkey PRIMARY KEY (id),
  CONSTRAINT digital_asset_access_log_asset_fkey
    FOREIGN KEY (digital_asset_id) REFERENCES digital_assets(id),
  CONSTRAINT digital_asset_access_log_donor_fkey
    FOREIGN KEY (donor_id) REFERENCES donors(id),
  CONSTRAINT digital_asset_access_log_station_fkey
    FOREIGN KEY (station_id) REFERENCES stations(id),
  CONSTRAINT digital_asset_access_log_donation_fkey
    FOREIGN KEY (donation_id) REFERENCES donations(id),
  CONSTRAINT digital_asset_access_log_entitlement_fkey
    FOREIGN KEY (entitlement_id) REFERENCES digital_asset_entitlements(id)
) TABLESPACE pg_default;

-- Find all access events for an asset (analytics, leak investigation)
CREATE INDEX digital_asset_access_log_asset_idx
  ON public.digital_asset_access_log USING btree (digital_asset_id, accessed_at DESC);

-- Find all access events for a donor (their access history)
CREATE INDEX digital_asset_access_log_donor_idx
  ON public.digital_asset_access_log USING btree (donor_id, accessed_at DESC);

-- Find all access events for a station (reporting)
CREATE INDEX digital_asset_access_log_station_idx
  ON public.digital_asset_access_log USING btree (station_id, accessed_at DESC);

COMMENT ON TABLE public.digital_asset_access_log IS
  'Append-only log of content access. Used for analytics and leak investigation. station_id denormalized for reporting. donation_id + entitlement_id trace access back to the specific grant for refund auditing.';

-- ==========================================================================
-- RLS — enabled but no policies = deny all direct access
-- ==========================================================================
-- All access goes through the service role client in API routes.
-- This is the established Beacon pattern — same as donations, donors, etc.

ALTER TABLE digital_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE digital_asset_entitlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE digital_asset_access_log ENABLE ROW LEVEL SECURITY;

-- Tell PostgREST to pick up the new tables
NOTIFY pgrst, 'reload schema';
