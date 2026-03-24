-- ============================================================================
-- Migration 023: Add Audit Log Triggers
-- ============================================================================
-- Creates triggers to automatically log changes to key tables.
-- Logs INSERT, UPDATE, DELETE operations with before/after data.
--
-- Tables covered:
--   - donors (PII changes)
--   - donations (financial records)
--   - memberships (subscription changes)
--   - gifts (catalog changes)
--   - campaigns (campaign changes)
--   - profiles (user/role changes)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- AUDIT TRIGGER FUNCTION
-- ----------------------------------------------------------------------------
-- Generic function that logs changes to the audit_log table.
-- Called by per-table triggers.

CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_data jsonb;
    v_new_data jsonb;
    v_action text;
    v_station_id uuid;
    v_user_id uuid;
BEGIN
    -- Determine action type
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

    -- Get current user ID (may be null for service_role operations)
    v_user_id := auth.uid();

    -- Insert audit record
    INSERT INTO audit_log (
        station_id,
        user_id,
        action,
        table_name,
        record_id,
        old_data,
        new_data,
        created_at
    ) VALUES (
        v_station_id,
        v_user_id,
        v_action,
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        v_old_data,
        v_new_data,
        now()
    );

    -- Return appropriate record
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

-- ----------------------------------------------------------------------------
-- CREATE AUDIT TRIGGERS FOR KEY TABLES
-- ----------------------------------------------------------------------------

-- Donors: Track all changes to donor records
DROP TRIGGER IF EXISTS audit_donors ON donors;
CREATE TRIGGER audit_donors
    AFTER INSERT OR UPDATE OR DELETE ON donors
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Donations: Track all donation changes (critical for financial audit)
DROP TRIGGER IF EXISTS audit_donations ON donations;
CREATE TRIGGER audit_donations
    AFTER INSERT OR UPDATE OR DELETE ON donations
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Memberships: Track subscription changes
DROP TRIGGER IF EXISTS audit_memberships ON memberships;
CREATE TRIGGER audit_memberships
    AFTER INSERT OR UPDATE OR DELETE ON memberships
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Gifts: Track catalog changes
DROP TRIGGER IF EXISTS audit_gifts ON gifts;
CREATE TRIGGER audit_gifts
    AFTER INSERT OR UPDATE OR DELETE ON gifts
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Gift Variants: Track variant changes
DROP TRIGGER IF EXISTS audit_gift_variants ON gift_variants;
CREATE TRIGGER audit_gift_variants
    AFTER INSERT OR UPDATE OR DELETE ON gift_variants
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Campaigns: Track campaign changes
DROP TRIGGER IF EXISTS audit_campaigns ON campaigns;
CREATE TRIGGER audit_campaigns
    AFTER INSERT OR UPDATE OR DELETE ON campaigns
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Profiles: Track user/role changes (no station_id, use null)
-- Need a separate function for profiles since it doesn't have station_id
CREATE OR REPLACE FUNCTION audit_profiles_trigger_function()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
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
        v_station_id := NEW.station_id; -- profiles has station_id
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

    INSERT INTO audit_log (
        station_id,
        user_id,
        action,
        table_name,
        record_id,
        old_data,
        new_data,
        created_at
    ) VALUES (
        v_station_id,
        v_user_id,
        v_action,
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        v_old_data,
        v_new_data,
        now()
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS audit_profiles ON profiles;
CREATE TRIGGER audit_profiles
    AFTER INSERT OR UPDATE OR DELETE ON profiles
    FOR EACH ROW EXECUTE FUNCTION audit_profiles_trigger_function();

-- Fulfillment Items: Track shipping/fulfillment changes
-- Need separate function since fulfillment_items doesn't have station_id directly
CREATE OR REPLACE FUNCTION audit_fulfillment_trigger_function()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
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
        -- Get station_id from the related donation
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

    INSERT INTO audit_log (
        station_id,
        user_id,
        action,
        table_name,
        record_id,
        old_data,
        new_data,
        created_at
    ) VALUES (
        v_station_id,
        v_user_id,
        v_action,
        TG_TABLE_NAME,
        v_record_id,
        v_old_data,
        v_new_data,
        now()
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS audit_fulfillment_items ON fulfillment_items;
CREATE TRIGGER audit_fulfillment_items
    AFTER INSERT OR UPDATE OR DELETE ON fulfillment_items
    FOR EACH ROW EXECUTE FUNCTION audit_fulfillment_trigger_function();

-- ============================================================================
-- End of Migration 023
-- ============================================================================
