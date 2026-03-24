-- 033_seed_fake_donor_data.sql
-- Seed realistic fake data for testing the admin portal.
--
-- Creates:
--   4 campaigns (Spring Drive active, Transmitter Fund evergreen, Winter Drive past, Summer Concert upcoming)
--   25 donors with varied profiles
--   ~50 donations across all statuses and sources
--   Gift variants for t-shirts and tote bags
--   ~12 fulfillment items in various states
--   6 memberships (active, cancelled, past_due)
--   10 shipping addresses
--   Tax documents for all succeeded donations
--   Tag assignments for donor segmentation
--
-- All data uses @example.com emails and fake Stripe IDs (pi_seed_*, cus_seed_*).
-- Safe to run on dev/staging — never run on production.

-- Fix memberships_status_check before seeding — original constraint (migration 001)
-- didn't include 'past_due', which we need for Michael Thompson's lapsed membership.
ALTER TABLE memberships DROP CONSTRAINT IF EXISTS memberships_status_check;
ALTER TABLE memberships ADD CONSTRAINT memberships_status_check
    CHECK (status IN ('active', 'past_due', 'paused', 'cancelled', 'canceled', 'lapsed'));

DO $$
DECLARE
  v_station_id uuid;

  -- Campaign IDs
  v_camp_spring uuid;
  v_camp_transmitter uuid;
  v_camp_winter uuid;
  v_camp_concert uuid;

  -- Gift IDs (looked up from existing seed data)
  v_gift_shirt uuid;
  v_gift_tote uuid;
  v_gift_book_ag uuid;   -- Amy Goodman book
  v_gift_album uuid;     -- Buena Vista Social Club

  -- Gift Variant IDs (created here)
  v_var_shirt_s uuid := gen_random_uuid();
  v_var_shirt_m uuid := gen_random_uuid();
  v_var_shirt_l uuid := gen_random_uuid();
  v_var_shirt_xl uuid := gen_random_uuid();
  v_var_tote uuid := gen_random_uuid();
  v_var_book_ag uuid := gen_random_uuid();
  v_var_album uuid := gen_random_uuid();

  -- Tag IDs (looked up from migration 019 seed)
  v_tag_vip uuid;
  v_tag_major uuid;
  v_tag_sustainer uuid;
  v_tag_new uuid;
  v_tag_lapsed uuid;
  v_tag_volunteer uuid;

  -- Program IDs (for show attribution on donations)
  v_prog_dn uuid;       -- Democracy Now!
  v_prog_bg uuid;       -- Background Briefing

BEGIN
  -- ============================================================================
  -- STEP 0: Ensure required columns exist on donations table
  -- These columns are used by the seed data but may not have been created
  -- in earlier migrations (they exist on the remote DB via dashboard edits).
  -- ============================================================================

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'donations' AND column_name = 'is_first_donation'
  ) THEN
    ALTER TABLE donations ADD COLUMN is_first_donation boolean DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'donations' AND column_name = 'pledged_at'
  ) THEN
    ALTER TABLE donations ADD COLUMN pledged_at timestamptz;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'donations' AND column_name = 'payment_due_at'
  ) THEN
    ALTER TABLE donations ADD COLUMN payment_due_at timestamptz;
  END IF;

  -- ============================================================================
  -- STEP 1: Look up station and reference data
  -- ============================================================================

  SELECT id INTO v_station_id FROM stations WHERE lower(code) = 'kpfk';
  IF v_station_id IS NULL THEN
    RAISE EXCEPTION 'KPFK station not found — run migration 018 first';
  END IF;

  -- Gifts (from migration 029)
  SELECT id INTO v_gift_shirt FROM gifts WHERE static_id = 'kpfk-shirt';
  SELECT id INTO v_gift_tote FROM gifts WHERE static_id = 'kpfk-tote';
  SELECT id INTO v_gift_book_ag FROM gifts WHERE static_id = 'amy-goodman';
  SELECT id INTO v_gift_album FROM gifts WHERE static_id = 'buenavista';

  -- Programs (from migration 009)
  SELECT id INTO v_prog_dn FROM programs WHERE slug = 'democracy-now' AND station_id = v_station_id LIMIT 1;
  SELECT id INTO v_prog_bg FROM programs WHERE slug = 'background-briefing' AND station_id = v_station_id LIMIT 1;

  -- Tags (from migration 019) — only look up if the tags table exists
  -- Migration 019 may not have run yet on all environments
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'tags'
  ) THEN
    SELECT id INTO v_tag_vip FROM tags WHERE lower(name) = 'vip' AND station_id = v_station_id LIMIT 1;
    SELECT id INTO v_tag_major FROM tags WHERE lower(name) = 'major donor' AND station_id = v_station_id LIMIT 1;
    SELECT id INTO v_tag_sustainer FROM tags WHERE lower(name) = 'sustainer' AND station_id = v_station_id LIMIT 1;
    SELECT id INTO v_tag_new FROM tags WHERE lower(name) = 'new donor' AND station_id = v_station_id LIMIT 1;
    SELECT id INTO v_tag_lapsed FROM tags WHERE lower(name) = 'lapsed' AND station_id = v_station_id LIMIT 1;
    SELECT id INTO v_tag_volunteer FROM tags WHERE lower(name) = 'volunteer' AND station_id = v_station_id LIMIT 1;
  END IF;


  -- ============================================================================
  -- STEP 2: Create campaigns
  -- Campaigns give context to donations and power the campaign dashboard.
  -- ============================================================================

  INSERT INTO campaigns (station_id, code, name, campaign_type, description, starts_at, ends_at, goal_cents, is_active, created_at)
  VALUES (v_station_id, 'spring-drive-2026', 'Spring Fund Drive 2026', 'fund_drive',
          'Annual spring fund drive — keep community radio alive!',
          '2026-02-15T00:00:00-08:00', '2026-03-15T23:59:59-07:00',
          10000000, true, '2026-02-01'::timestamptz)
  ON CONFLICT DO NOTHING
  RETURNING id INTO v_camp_spring;
  -- If it already existed, look it up
  IF v_camp_spring IS NULL THEN
    SELECT id INTO v_camp_spring FROM campaigns WHERE code = 'spring-drive-2026' AND station_id = v_station_id;
  END IF;

  INSERT INTO campaigns (station_id, code, name, campaign_type, description, goal_cents, is_active, created_at)
  VALUES (v_station_id, 'transmitter-fund', 'Transmitter Repair Fund', 'evergreen',
          'Ongoing fund to maintain and upgrade our broadcast transmitter.',
          5000000, true, '2025-06-01'::timestamptz)
  ON CONFLICT DO NOTHING
  RETURNING id INTO v_camp_transmitter;
  IF v_camp_transmitter IS NULL THEN
    SELECT id INTO v_camp_transmitter FROM campaigns WHERE code = 'transmitter-fund' AND station_id = v_station_id;
  END IF;

  INSERT INTO campaigns (station_id, code, name, campaign_type, description, starts_at, ends_at, goal_cents, is_active, created_at)
  VALUES (v_station_id, 'winter-drive-2025', 'Winter Drive 2025', 'fund_drive',
          'End-of-year fund drive — thank you for a great 2025!',
          '2025-11-15T00:00:00-08:00', '2025-12-31T23:59:59-08:00',
          7500000, false, '2025-11-01'::timestamptz)
  ON CONFLICT DO NOTHING
  RETURNING id INTO v_camp_winter;
  IF v_camp_winter IS NULL THEN
    SELECT id INTO v_camp_winter FROM campaigns WHERE code = 'winter-drive-2025' AND station_id = v_station_id;
  END IF;

  INSERT INTO campaigns (station_id, code, name, campaign_type, description, starts_at, ends_at, goal_cents, is_active, created_at)
  VALUES (v_station_id, 'summer-concert-2026', 'Community Summer Concert 2026', 'event',
          'Live outdoor concert fundraiser at Griffith Park.',
          '2026-06-15T16:00:00-07:00', '2026-06-15T22:00:00-07:00',
          1500000, true, '2026-01-15'::timestamptz)
  ON CONFLICT DO NOTHING
  RETURNING id INTO v_camp_concert;
  IF v_camp_concert IS NULL THEN
    SELECT id INTO v_camp_concert FROM campaigns WHERE code = 'summer-concert-2026' AND station_id = v_station_id;
  END IF;


  -- ============================================================================
  -- STEP 3: Create gift variants
  -- T-shirts need sizes, other gifts get a "Default" variant.
  -- Variants are needed so fulfillment items can reference a specific SKU.
  -- ============================================================================

  IF v_gift_shirt IS NOT NULL THEN
    INSERT INTO gift_variants (id, gift_id, name, sku, inventory_count, sort_order, is_active)
    VALUES
      (v_var_shirt_s,  v_gift_shirt, 'Small',  'KPFK-SHIRT-S',  25, 1, true),
      (v_var_shirt_m,  v_gift_shirt, 'Medium', 'KPFK-SHIRT-M',  30, 2, true),
      (v_var_shirt_l,  v_gift_shirt, 'Large',  'KPFK-SHIRT-L',  20, 3, true),
      (v_var_shirt_xl, v_gift_shirt, 'XL',     'KPFK-SHIRT-XL', 15, 4, true)
    ON CONFLICT DO NOTHING;
  END IF;

  IF v_gift_tote IS NOT NULL THEN
    INSERT INTO gift_variants (id, gift_id, name, sku, inventory_count, sort_order, is_active)
    VALUES (v_var_tote, v_gift_tote, 'One Size', 'KPFK-TOTE-OS', 50, 1, true)
    ON CONFLICT DO NOTHING;
  END IF;

  IF v_gift_book_ag IS NOT NULL THEN
    INSERT INTO gift_variants (id, gift_id, name, sku, inventory_count, sort_order, is_active)
    VALUES (v_var_book_ag, v_gift_book_ag, 'Default', 'AG-BOOK-01', 40, 1, true)
    ON CONFLICT DO NOTHING;
  END IF;

  IF v_gift_album IS NOT NULL THEN
    INSERT INTO gift_variants (id, gift_id, name, sku, inventory_count, sort_order, is_active)
    VALUES (v_var_album, v_gift_album, 'Default', 'BV-ALBUM-01', 35, 1, true)
    ON CONFLICT DO NOTHING;
  END IF;


  -- ============================================================================
  -- STEP 4: Create 25 donors
  -- Mix of web donors, phone pledges, walk-ins, and mail donations.
  -- Each donor has a "story" — see comments for what makes them interesting.
  -- ============================================================================

  INSERT INTO donors (station_id, email, email_normalized, first_name, last_name, phone, stripe_customer_id, source, created_at) VALUES
    -- 1. Maria Rodriguez — Major donor, VIP, active sustainer, 5 donations
    (v_station_id, 'maria.rodriguez@example.com', 'maria.rodriguez@example.com', 'Maria', 'Rodriguez', '(213) 555-0101', 'cus_seed_001', 'web', '2025-06-15'::timestamptz),
    -- 2. James Chen — Regular web donor, 3 donations
    (v_station_id, 'james.chen@example.com', 'james.chen@example.com', 'James', 'Chen', '(310) 555-0202', 'cus_seed_002', 'web', '2025-09-01'::timestamptz),
    -- 3. Sarah Williams — Bill-me pledge, waiting for payment
    (v_station_id, 'sarah.williams@example.com', 'sarah.williams@example.com', 'Sarah', 'Williams', '(818) 555-0303', NULL, 'phone', '2026-02-16'::timestamptz),
    -- 4. Robert Johnson — Long-time sustainer, VIP, 4 donations
    (v_station_id, 'robert.johnson@example.com', 'robert.johnson@example.com', 'Robert', 'Johnson', '(626) 555-0404', 'cus_seed_004', 'web', '2024-03-10'::timestamptz),
    -- 5. Lisa Park — Brand new donor, first donation this week
    (v_station_id, 'lisa.park@example.com', 'lisa.park@example.com', 'Lisa', 'Park', NULL, 'cus_seed_005', 'web', '2026-02-18'::timestamptz),
    -- 6. Michael Thompson — Lapsed donor, last donation 14 months ago
    (v_station_id, 'michael.thompson@example.com', 'michael.thompson@example.com', 'Michael', 'Thompson', '(562) 555-0606', 'cus_seed_006', 'web', '2024-10-01'::timestamptz),
    -- 7. Emily Davis — Selected gifts, fulfillment pending
    (v_station_id, 'emily.davis@example.com', 'emily.davis@example.com', 'Emily', 'Davis', '(323) 555-0707', 'cus_seed_007', 'phone', '2026-02-15'::timestamptz),
    -- 8. David Kim — One succeeded, one refunded
    (v_station_id, 'david.kim@example.com', 'david.kim@example.com', 'David', 'Kim', '(213) 555-0808', 'cus_seed_008', 'web', '2025-11-20'::timestamptz),
    -- 9. Angela Martinez — Democracy Now! fan, consistent giver
    (v_station_id, 'angela.martinez@example.com', 'angela.martinez@example.com', 'Angela', 'Martinez', '(818) 555-0909', 'cus_seed_009', 'web', '2025-03-01'::timestamptz),
    -- 10. Thomas Brown — Phone pledge, cash payment
    (v_station_id, 'thomas.brown@example.com', 'thomas.brown@example.com', 'Thomas', 'Brown', '(310) 555-1010', NULL, 'phone', '2026-02-17'::timestamptz),
    -- 11. Jennifer Lee — Single large donation ($2,500), major donor
    (v_station_id, 'jennifer.lee@example.com', 'jennifer.lee@example.com', 'Jennifer', 'Lee', '(626) 555-1111', 'cus_seed_011', 'web', '2026-02-16'::timestamptz),
    -- 12. Christopher Wilson — New monthly sustainer, 2 months in
    (v_station_id, 'chris.wilson@example.com', 'chris.wilson@example.com', 'Christopher', 'Wilson', NULL, 'cus_seed_012', 'web', '2025-12-20'::timestamptz),
    -- 13. Patricia Garcia — Small event donation
    (v_station_id, 'patricia.garcia@example.com', 'patricia.garcia@example.com', 'Patricia', 'Garcia', '(323) 555-1313', 'cus_seed_013', 'web', '2026-01-10'::timestamptz),
    -- 14. Daniel Moore — $10 web donor, minimal info
    (v_station_id, 'daniel.moore@example.com', 'daniel.moore@example.com', 'Daniel', 'Moore', NULL, 'cus_seed_014', 'web', '2026-02-19'::timestamptz),
    -- 15. Amanda Taylor — Gift membership for someone else
    (v_station_id, 'amanda.taylor@example.com', 'amanda.taylor@example.com', 'Amanda', 'Taylor', '(818) 555-1515', 'cus_seed_015', 'web', '2025-12-01'::timestamptz),
    -- 16. Kevin Anderson — Donated to 3 different campaigns
    (v_station_id, 'kevin.anderson@example.com', 'kevin.anderson@example.com', 'Kevin', 'Anderson', '(213) 555-1616', 'cus_seed_016', 'web', '2025-08-01'::timestamptz),
    -- 17. Rachel White — Check payment, still processing
    (v_station_id, 'rachel.white@example.com', 'rachel.white@example.com', 'Rachel', 'White', '(310) 555-1717', NULL, 'mail', '2026-02-10'::timestamptz),
    -- 18. Marcus Jackson — Walk-in donation
    (v_station_id, 'marcus.jackson@example.com', 'marcus.jackson@example.com', 'Marcus', 'Jackson', '(562) 555-1818', NULL, 'walk_in', '2026-02-18'::timestamptz),
    -- 19. Sophia Nguyen — Cancelled sustainer
    (v_station_id, 'sophia.nguyen@example.com', 'sophia.nguyen@example.com', 'Sophia', 'Nguyen', '(626) 555-1919', 'cus_seed_019', 'web', '2025-04-01'::timestamptz),
    -- 20. William Harris — Pledged, payment due next week
    (v_station_id, 'william.harris@example.com', 'william.harris@example.com', 'William', 'Harris', '(323) 555-2020', NULL, 'phone', '2026-02-19'::timestamptz),
    -- 21. Catherine Clark — Fulfilled donation (shipped & delivered)
    (v_station_id, 'catherine.clark@example.com', 'catherine.clark@example.com', 'Catherine', 'Clark', '(213) 555-2121', 'cus_seed_021', 'web', '2025-12-15'::timestamptz),
    -- 22. Brian Martinez — Three small donations
    (v_station_id, 'brian.martinez@example.com', 'brian.martinez@example.com', 'Brian', 'Martinez', NULL, 'cus_seed_022', 'web', '2025-11-01'::timestamptz),
    -- 23. Diana Lopez — New monthly sustainer, just started
    (v_station_id, 'diana.lopez@example.com', 'diana.lopez@example.com', 'Diana', 'Lopez', '(818) 555-2323', 'cus_seed_023', 'web', '2026-02-01'::timestamptz),
    -- 24. Steven Wright — Phone pledge with fee coverage
    (v_station_id, 'steven.wright@example.com', 'steven.wright@example.com', 'Steven', 'Wright', '(310) 555-2424', 'cus_seed_024', 'phone', '2026-02-17'::timestamptz),
    -- 25. Natalie Robinson — Failed payment
    (v_station_id, 'natalie.robinson@example.com', 'natalie.robinson@example.com', 'Natalie', 'Robinson', '(562) 555-2525', 'cus_seed_025', 'web', '2026-02-19'::timestamptz)
  ON CONFLICT DO NOTHING;


  -- ============================================================================
  -- STEP 5: Create donations
  -- ~50 donations across all statuses, sources, campaigns, and date ranges.
  -- Grouped by donor for readability.
  -- ============================================================================

  -- --- Maria Rodriguez: 5 donations, $525 total ---
  -- Spring Drive web donation (recent)
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, fee_coverage_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'maria.rodriguez@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 25000, 0, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_001', false,
    '2026-02-16 10:30:00-08'::timestamptz, '2026-02-16 10:30:00-08'::timestamptz
  );
  -- Spring Drive monthly sustainer payment
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'maria.rodriguez@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 5000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_002', false,
    '2026-02-01 00:00:00-08'::timestamptz, '2026-02-01 00:00:00-08'::timestamptz
  );
  -- Winter Drive donations
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'maria.rodriguez@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_winter, 10000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_003', false,
    '2025-12-01 14:00:00-08'::timestamptz, '2025-12-01 14:00:00-08'::timestamptz
  );
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'maria.rodriguez@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_winter, 5000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_004', false,
    '2025-11-20 09:00:00-08'::timestamptz, '2025-11-20 09:00:00-08'::timestamptz
  );
  -- First ever donation (from when she joined)
  INSERT INTO donations (donor_id, station_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'maria.rodriguez@example.com' AND station_id = v_station_id),
    v_station_id, 7500, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_005', true,
    '2025-06-15 11:00:00-07'::timestamptz, '2025-06-15 11:00:00-07'::timestamptz
  );

  -- --- James Chen: 3 donations, $200 total ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'james.chen@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 7500, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_006', false,
    '2026-02-17 15:20:00-08'::timestamptz, '2026-02-17 15:20:00-08'::timestamptz
  );
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'james.chen@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_winter, 5000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_007', false,
    '2025-12-10 10:00:00-08'::timestamptz, '2025-12-10 10:00:00-08'::timestamptz
  );
  INSERT INTO donations (donor_id, station_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'james.chen@example.com' AND station_id = v_station_id),
    v_station_id, 7500, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_008', true,
    '2025-09-01 08:30:00-07'::timestamptz, '2025-09-01 08:30:00-07'::timestamptz
  );

  -- --- Sarah Williams: 1 bill-me pledge, $120, awaiting payment ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, is_first_donation, pledged_at, payment_due_at, comments, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'sarah.williams@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 12000, 'pledged', 'phone', 'stripe', true,
    '2026-02-16 19:45:00-08'::timestamptz,
    '2026-02-23 23:59:59-08'::timestamptz,
    'Bill me — will pay by card next week',
    '2026-02-16 19:45:00-08'::timestamptz
  );

  -- --- Robert Johnson: 4 donations, $500 total, long-time sustainer ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'robert.johnson@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 5000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_009', false,
    '2026-02-15 12:00:00-08'::timestamptz, '2026-02-15 12:00:00-08'::timestamptz
  );
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'robert.johnson@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_transmitter, 20000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_010', false,
    '2025-09-15 14:00:00-07'::timestamptz, '2025-09-15 14:00:00-07'::timestamptz
  );
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'robert.johnson@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_winter, 15000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_011', false,
    '2025-11-25 16:30:00-08'::timestamptz, '2025-11-25 16:30:00-08'::timestamptz
  );
  INSERT INTO donations (donor_id, station_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'robert.johnson@example.com' AND station_id = v_station_id),
    v_station_id, 10000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_012', true,
    '2024-03-10 10:00:00-07'::timestamptz, '2024-03-10 10:00:00-07'::timestamptz
  );

  -- --- Lisa Park: 1 donation, $25, brand new donor ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'lisa.park@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 2500, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_013', true,
    '2026-02-18 20:15:00-08'::timestamptz, '2026-02-18 20:15:00-08'::timestamptz
  );

  -- --- Michael Thompson: 1 donation, $50, lapsed (14 months ago) ---
  INSERT INTO donations (donor_id, station_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'michael.thompson@example.com' AND station_id = v_station_id),
    v_station_id, 5000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_014', true,
    '2024-12-05 11:00:00-08'::timestamptz, '2024-12-05 11:00:00-08'::timestamptz
  );

  -- --- Emily Davis: 2 donations, $250 total, has gifts to fulfill ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, gift_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'emily.davis@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 15000, 'succeeded', 'phone', 'stripe', 'card', 'pi_seed_015', v_gift_shirt, true,
    '2026-02-15 18:30:00-08'::timestamptz, '2026-02-15 18:30:00-08'::timestamptz
  );
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, gift_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'emily.davis@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 10000, 'succeeded', 'phone', 'stripe', 'card', 'pi_seed_016', v_gift_tote, false,
    '2026-02-16 19:00:00-08'::timestamptz, '2026-02-16 19:00:00-08'::timestamptz
  );

  -- --- David Kim: 2 donations — 1 succeeded, 1 refunded ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'david.kim@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_winter, 7500, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_017', true,
    '2025-11-20 13:00:00-08'::timestamptz, '2025-11-20 13:00:00-08'::timestamptz
  );
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at, comments)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'david.kim@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 10000, 'refunded', 'web', 'stripe', 'card', 'pi_seed_018', false,
    '2026-02-16 09:00:00-08'::timestamptz, '2026-02-16 09:00:00-08'::timestamptz,
    'Refunded at donor request — accidental duplicate'
  );

  -- --- Angela Martinez: 3 donations to Democracy Now!, $160 total ---
  INSERT INTO donations (donor_id, station_id, campaign_id, show_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'angela.martinez@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, v_prog_dn, 6000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_019', false,
    '2026-02-18 07:30:00-08'::timestamptz, '2026-02-18 07:30:00-08'::timestamptz
  );
  INSERT INTO donations (donor_id, station_id, campaign_id, show_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'angela.martinez@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_winter, v_prog_dn, 6000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_020', false,
    '2025-12-15 08:00:00-08'::timestamptz, '2025-12-15 08:00:00-08'::timestamptz
  );
  INSERT INTO donations (donor_id, station_id, show_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'angela.martinez@example.com' AND station_id = v_station_id),
    v_station_id, v_prog_dn, 4000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_021', true,
    '2025-03-01 09:00:00-08'::timestamptz, '2025-03-01 09:00:00-08'::timestamptz
  );

  -- --- Thomas Brown: 1 phone pledge, $200, cash ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, is_first_donation, received_at, created_at, comments)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'thomas.brown@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 20000, 'succeeded', 'phone', 'cash', 'cash', true,
    '2026-02-17 20:00:00-08'::timestamptz, '2026-02-17 20:00:00-08'::timestamptz,
    'Cash payment — brought to station in person'
  );

  -- --- Jennifer Lee: 1 large donation, $2,500 ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'jennifer.lee@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 250000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_022', true,
    '2026-02-16 22:00:00-08'::timestamptz, '2026-02-16 22:00:00-08'::timestamptz
  );

  -- --- Christopher Wilson: 2 sustainer payments, $35 each ---
  INSERT INTO donations (donor_id, station_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'chris.wilson@example.com' AND station_id = v_station_id),
    v_station_id, 3500, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_023', true,
    '2025-12-20 00:00:00-08'::timestamptz, '2025-12-20 00:00:00-08'::timestamptz
  );
  INSERT INTO donations (donor_id, station_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'chris.wilson@example.com' AND station_id = v_station_id),
    v_station_id, 3500, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_024', false,
    '2026-01-20 00:00:00-08'::timestamptz, '2026-01-20 00:00:00-08'::timestamptz
  );

  -- --- Patricia Garcia: 1 small donation, $25 ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'patricia.garcia@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_concert, 2500, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_025', true,
    '2026-01-15 16:00:00-08'::timestamptz, '2026-01-15 16:00:00-08'::timestamptz
  );

  -- --- Daniel Moore: 1 tiny web donation, $10 ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'daniel.moore@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 1000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_026', true,
    '2026-02-19 21:00:00-08'::timestamptz, '2026-02-19 21:00:00-08'::timestamptz
  );

  -- --- Amanda Taylor: 1 gift membership donation, $100 ---
  INSERT INTO donations (donor_id, station_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, gift_id, is_first_donation, received_at, created_at, comments)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'amanda.taylor@example.com' AND station_id = v_station_id),
    v_station_id, 10000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_027', v_gift_book_ag, true,
    '2025-12-01 10:00:00-08'::timestamptz, '2025-12-01 10:00:00-08'::timestamptz,
    'Gift membership — recipient: John Taylor (brother)'
  );

  -- --- Kevin Anderson: 3 donations across campaigns, $225 total ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'kevin.anderson@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 10000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_028', false,
    '2026-02-15 14:00:00-08'::timestamptz, '2026-02-15 14:00:00-08'::timestamptz
  );
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'kevin.anderson@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_transmitter, 7500, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_029', false,
    '2025-10-01 12:00:00-07'::timestamptz, '2025-10-01 12:00:00-07'::timestamptz
  );
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'kevin.anderson@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_winter, 5000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_030', true,
    '2025-08-01 09:00:00-07'::timestamptz, '2025-08-01 09:00:00-07'::timestamptz
  );

  -- --- Rachel White: 1 check donation, $250, processing ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, check_number, is_first_donation, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'rachel.white@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 25000, 'processing', 'mail', 'check', 'check', '4821', true,
    '2026-02-12 00:00:00-08'::timestamptz
  );

  -- --- Marcus Jackson: 1 walk-in donation, $50 ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, is_first_donation, received_at, created_at, comments)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'marcus.jackson@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 5000, 'succeeded', 'walk_in', 'cash', 'cash', true,
    '2026-02-18 14:00:00-08'::timestamptz, '2026-02-18 14:00:00-08'::timestamptz,
    'Walked into station with cash donation'
  );

  -- --- Sophia Nguyen: 2 sustainer payments, $50 each (cancelled) ---
  INSERT INTO donations (donor_id, station_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'sophia.nguyen@example.com' AND station_id = v_station_id),
    v_station_id, 5000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_031', true,
    '2025-04-01 00:00:00-07'::timestamptz, '2025-04-01 00:00:00-07'::timestamptz
  );
  INSERT INTO donations (donor_id, station_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'sophia.nguyen@example.com' AND station_id = v_station_id),
    v_station_id, 5000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_032', false,
    '2025-05-01 00:00:00-07'::timestamptz, '2025-05-01 00:00:00-07'::timestamptz
  );

  -- --- William Harris: 1 pledge, $150, payment due next week ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, is_first_donation, pledged_at, payment_due_at, created_at, comments)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'william.harris@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 15000, 'pledged', 'phone', 'stripe', true,
    '2026-02-19 20:00:00-08'::timestamptz,
    '2026-02-26 23:59:59-08'::timestamptz,
    '2026-02-19 20:00:00-08'::timestamptz,
    'Will pay online after the show'
  );

  -- --- Catherine Clark: 1 donation, $100, fully fulfilled ---
  INSERT INTO donations (donor_id, station_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, gift_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'catherine.clark@example.com' AND station_id = v_station_id),
    v_station_id, 10000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_033', v_gift_album, true,
    '2025-12-15 18:00:00-08'::timestamptz, '2025-12-15 18:00:00-08'::timestamptz
  );

  -- --- Brian Martinez: 3 small donations, $45 total ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'brian.martinez@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 1500, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_034', false,
    '2026-02-18 12:00:00-08'::timestamptz, '2026-02-18 12:00:00-08'::timestamptz
  );
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'brian.martinez@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_winter, 2000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_035', false,
    '2025-12-28 15:00:00-08'::timestamptz, '2025-12-28 15:00:00-08'::timestamptz
  );
  INSERT INTO donations (donor_id, station_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'brian.martinez@example.com' AND station_id = v_station_id),
    v_station_id, 1000, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_036', true,
    '2025-11-01 10:00:00-07'::timestamptz, '2025-11-01 10:00:00-07'::timestamptz
  );

  -- --- Diana Lopez: 1 donation, $45, new sustainer ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'diana.lopez@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 4500, 'succeeded', 'web', 'stripe', 'card', 'pi_seed_037', true,
    '2026-02-01 17:00:00-08'::timestamptz, '2026-02-01 17:00:00-08'::timestamptz
  );

  -- --- Steven Wright: 1 phone pledge, $180, with $5.40 fee coverage ---
  INSERT INTO donations (donor_id, station_id, campaign_id, show_id, amount_cents, fee_coverage_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, received_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'steven.wright@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, v_prog_bg, 18000, 540, 'succeeded', 'phone', 'stripe', 'card', 'pi_seed_038', true,
    '2026-02-17 21:00:00-08'::timestamptz, '2026-02-17 21:00:00-08'::timestamptz
  );

  -- --- Natalie Robinson: 1 failed payment, $75 ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, created_at, comments)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'natalie.robinson@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 7500, 'failed', 'web', 'stripe', 'card', 'pi_seed_039', true,
    '2026-02-19 22:00:00-08'::timestamptz,
    'Card declined — insufficient funds'
  );

  -- --- Two more "pending" donations for pipeline variety ---
  INSERT INTO donations (donor_id, station_id, campaign_id, amount_cents, status, source_type, payment_provider, payment_method_type, stripe_payment_intent_id, is_first_donation, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'kevin.anderson@example.com' AND station_id = v_station_id),
    v_station_id, v_camp_spring, 5000, 'pending', 'web', 'stripe', 'card', 'pi_seed_040', false,
    '2026-02-20 08:00:00-08'::timestamptz
  );


  -- ============================================================================
  -- STEP 6: Create shipping addresses for donors who selected gifts
  -- ============================================================================

  INSERT INTO addresses (donor_id, address_type, label, recipient_name, street_line_1, street_line_2, city, state, postal_code, country, is_default) VALUES
    ((SELECT id FROM donors WHERE email_normalized = 'emily.davis@example.com' AND station_id = v_station_id),
     'shipping', 'Home', 'Emily Davis', '742 Evergreen Terrace', 'Apt 3B', 'Los Angeles', 'CA', '90027', 'US', true),
    ((SELECT id FROM donors WHERE email_normalized = 'catherine.clark@example.com' AND station_id = v_station_id),
     'shipping', 'Home', 'Catherine Clark', '1600 Vine Street', NULL, 'Hollywood', 'CA', '90028', 'US', true),
    ((SELECT id FROM donors WHERE email_normalized = 'amanda.taylor@example.com' AND station_id = v_station_id),
     'shipping', 'Gift Recipient', 'John Taylor', '456 Oak Avenue', NULL, 'Pasadena', 'CA', '91101', 'US', true),
    ((SELECT id FROM donors WHERE email_normalized = 'maria.rodriguez@example.com' AND station_id = v_station_id),
     'shipping', 'Home', 'Maria Rodriguez', '2200 Colorado Blvd', 'Suite 100', 'Los Angeles', 'CA', '90041', 'US', true),
    ((SELECT id FROM donors WHERE email_normalized = 'robert.johnson@example.com' AND station_id = v_station_id),
     'shipping', 'Home', 'Robert Johnson', '1234 Sunset Blvd', NULL, 'Silver Lake', 'CA', '90026', 'US', true),
    ((SELECT id FROM donors WHERE email_normalized = 'jennifer.lee@example.com' AND station_id = v_station_id),
     'shipping', 'Office', 'Jennifer Lee', '500 S Grand Ave', 'Floor 42', 'Los Angeles', 'CA', '90071', 'US', true),
    ((SELECT id FROM donors WHERE email_normalized = 'kevin.anderson@example.com' AND station_id = v_station_id),
     'shipping', 'Home', 'Kevin Anderson', '789 Wilshire Blvd', NULL, 'Santa Monica', 'CA', '90401', 'US', true),
    ((SELECT id FROM donors WHERE email_normalized = 'rachel.white@example.com' AND station_id = v_station_id),
     'shipping', 'Home', 'Rachel White', '321 Melrose Ave', 'Unit 7', 'West Hollywood', 'CA', '90046', 'US', true),
    ((SELECT id FROM donors WHERE email_normalized = 'steven.wright@example.com' AND station_id = v_station_id),
     'shipping', 'Home', 'Steven Wright', '555 Figueroa St', NULL, 'Los Angeles', 'CA', '90017', 'US', true),
    ((SELECT id FROM donors WHERE email_normalized = 'diana.lopez@example.com' AND station_id = v_station_id),
     'shipping', 'Home', 'Diana Lopez', '100 Universal City Plaza', NULL, 'Universal City', 'CA', '91608', 'US', true)
  ON CONFLICT DO NOTHING;


  -- ============================================================================
  -- STEP 7: Create fulfillment items
  -- These show up in the fulfillment queue in various states.
  -- ============================================================================

  -- Emily Davis's shirt (pending — needs to be packed)
  INSERT INTO fulfillment_items (donation_id, gift_variant_id, quantity, status, address_snapshot, created_at)
  SELECT d.id, v_var_shirt_m, 1, 'pending',
    '{"recipient_name": "Emily Davis", "street_line_1": "742 Evergreen Terrace", "street_line_2": "Apt 3B", "city": "Los Angeles", "state": "CA", "postal_code": "90027", "country": "US"}'::jsonb,
    d.created_at
  FROM donations d
  JOIN donors dn ON dn.id = d.donor_id
  WHERE dn.email_normalized = 'emily.davis@example.com' AND d.amount_cents = 15000 AND d.station_id = v_station_id
  LIMIT 1;

  -- Emily Davis's tote bag (pending)
  INSERT INTO fulfillment_items (donation_id, gift_variant_id, quantity, status, address_snapshot, created_at)
  SELECT d.id, v_var_tote, 1, 'pending',
    '{"recipient_name": "Emily Davis", "street_line_1": "742 Evergreen Terrace", "street_line_2": "Apt 3B", "city": "Los Angeles", "state": "CA", "postal_code": "90027", "country": "US"}'::jsonb,
    d.created_at
  FROM donations d
  JOIN donors dn ON dn.id = d.donor_id
  WHERE dn.email_normalized = 'emily.davis@example.com' AND d.amount_cents = 10000 AND d.station_id = v_station_id
  LIMIT 1;

  -- Catherine Clark's album (delivered — completed fulfillment)
  INSERT INTO fulfillment_items (donation_id, gift_variant_id, quantity, status, address_snapshot, carrier, tracking_number, shipped_at, delivered_at, created_at)
  SELECT d.id, v_var_album, 1, 'delivered',
    '{"recipient_name": "Catherine Clark", "street_line_1": "1600 Vine Street", "city": "Hollywood", "state": "CA", "postal_code": "90028", "country": "US"}'::jsonb,
    'USPS', '9400111899223456789012', '2025-12-18'::timestamptz, '2025-12-22'::timestamptz,
    d.created_at
  FROM donations d
  JOIN donors dn ON dn.id = d.donor_id
  WHERE dn.email_normalized = 'catherine.clark@example.com' AND d.station_id = v_station_id
  LIMIT 1;

  -- Amanda Taylor's book (shipped — in transit)
  INSERT INTO fulfillment_items (donation_id, gift_variant_id, quantity, status, address_snapshot, carrier, tracking_number, shipped_at, created_at)
  SELECT d.id, v_var_book_ag, 1, 'shipped',
    '{"recipient_name": "John Taylor", "street_line_1": "456 Oak Avenue", "city": "Pasadena", "state": "CA", "postal_code": "91101", "country": "US"}'::jsonb,
    'USPS', '9400111899223456789099', '2025-12-05'::timestamptz,
    d.created_at
  FROM donations d
  JOIN donors dn ON dn.id = d.donor_id
  WHERE dn.email_normalized = 'amanda.taylor@example.com' AND d.station_id = v_station_id
  LIMIT 1;


  -- ============================================================================
  -- STEP 8: Create memberships (recurring subscriptions)
  -- Active sustainers, cancelled, and past_due for testing all states.
  -- ============================================================================

  -- Maria Rodriguez — active sustainer, $50/month
  INSERT INTO memberships (donor_id, station_id, stripe_subscription_id, tier, amount_cents, status, started_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'maria.rodriguez@example.com' AND station_id = v_station_id),
    v_station_id, 'sub_seed_001', 'sustainer', 5000, 'active',
    '2025-06-15'::timestamptz, '2025-06-15'::timestamptz
  );

  -- Robert Johnson — active sustainer, $50/month (long-time)
  INSERT INTO memberships (donor_id, station_id, stripe_subscription_id, tier, amount_cents, status, started_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'robert.johnson@example.com' AND station_id = v_station_id),
    v_station_id, 'sub_seed_002', 'sustainer', 5000, 'active',
    '2024-03-10'::timestamptz, '2024-03-10'::timestamptz
  );

  -- Christopher Wilson — active sustainer, $35/month (new)
  INSERT INTO memberships (donor_id, station_id, stripe_subscription_id, tier, amount_cents, status, started_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'chris.wilson@example.com' AND station_id = v_station_id),
    v_station_id, 'sub_seed_003', 'sustainer', 3500, 'active',
    '2025-12-20'::timestamptz, '2025-12-20'::timestamptz
  );

  -- Diana Lopez — active sustainer, $45/month (just started)
  INSERT INTO memberships (donor_id, station_id, stripe_subscription_id, tier, amount_cents, status, started_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'diana.lopez@example.com' AND station_id = v_station_id),
    v_station_id, 'sub_seed_004', 'sustainer', 4500, 'active',
    '2026-02-01'::timestamptz, '2026-02-01'::timestamptz
  );

  -- Sophia Nguyen — cancelled sustainer (cancelled after 2 months)
  INSERT INTO memberships (donor_id, station_id, stripe_subscription_id, tier, amount_cents, status, started_at, cancelled_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'sophia.nguyen@example.com' AND station_id = v_station_id),
    v_station_id, 'sub_seed_005', 'sustainer', 5000, 'cancelled',
    '2025-04-01'::timestamptz, '2025-06-01'::timestamptz, '2025-04-01'::timestamptz
  );

  -- Michael Thompson — past_due membership (explains why he's lapsed)
  INSERT INTO memberships (donor_id, station_id, stripe_subscription_id, tier, amount_cents, status, started_at, created_at)
  VALUES (
    (SELECT id FROM donors WHERE email_normalized = 'michael.thompson@example.com' AND station_id = v_station_id),
    v_station_id, 'sub_seed_006', 'sustainer', 2500, 'past_due',
    '2024-10-01'::timestamptz, '2024-10-01'::timestamptz
  );


  -- ============================================================================
  -- STEP 9: Apply tags to donors
  -- Tags show up in the donor list and detail views for segmentation.
  -- Only runs if the tags table (from migration 019) was populated.
  -- ============================================================================

  -- Check if the donor_tags table has a tag_id column (migration 019 schema)
  -- vs the old tag text column (migration 004 schema).
  -- We insert using tag_id if it exists.
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'donor_tags' AND column_name = 'tag_id'
  ) AND v_tag_vip IS NOT NULL THEN

    INSERT INTO donor_tags (donor_id, tag_id, applied_at) VALUES
      -- Maria Rodriguez: VIP + Sustainer
      ((SELECT id FROM donors WHERE email_normalized = 'maria.rodriguez@example.com' AND station_id = v_station_id), v_tag_vip, '2025-08-01'::timestamptz),
      ((SELECT id FROM donors WHERE email_normalized = 'maria.rodriguez@example.com' AND station_id = v_station_id), v_tag_sustainer, '2025-06-15'::timestamptz),
      -- Robert Johnson: VIP + Sustainer
      ((SELECT id FROM donors WHERE email_normalized = 'robert.johnson@example.com' AND station_id = v_station_id), v_tag_vip, '2024-06-01'::timestamptz),
      ((SELECT id FROM donors WHERE email_normalized = 'robert.johnson@example.com' AND station_id = v_station_id), v_tag_sustainer, '2024-03-10'::timestamptz),
      -- Jennifer Lee: Major Donor
      ((SELECT id FROM donors WHERE email_normalized = 'jennifer.lee@example.com' AND station_id = v_station_id), v_tag_major, '2026-02-17'::timestamptz),
      -- Lisa Park: New Donor
      ((SELECT id FROM donors WHERE email_normalized = 'lisa.park@example.com' AND station_id = v_station_id), v_tag_new, '2026-02-18'::timestamptz),
      -- Daniel Moore: New Donor
      ((SELECT id FROM donors WHERE email_normalized = 'daniel.moore@example.com' AND station_id = v_station_id), v_tag_new, '2026-02-19'::timestamptz),
      -- Michael Thompson: Lapsed
      ((SELECT id FROM donors WHERE email_normalized = 'michael.thompson@example.com' AND station_id = v_station_id), v_tag_lapsed, '2025-03-01'::timestamptz),
      -- Angela Martinez: Volunteer
      ((SELECT id FROM donors WHERE email_normalized = 'angela.martinez@example.com' AND station_id = v_station_id), v_tag_volunteer, '2025-06-01'::timestamptz),
      -- Christopher Wilson: Sustainer
      ((SELECT id FROM donors WHERE email_normalized = 'chris.wilson@example.com' AND station_id = v_station_id), v_tag_sustainer, '2025-12-20'::timestamptz),
      -- Diana Lopez: Sustainer + New Donor
      ((SELECT id FROM donors WHERE email_normalized = 'diana.lopez@example.com' AND station_id = v_station_id), v_tag_sustainer, '2026-02-01'::timestamptz),
      ((SELECT id FROM donors WHERE email_normalized = 'diana.lopez@example.com' AND station_id = v_station_id), v_tag_new, '2026-02-01'::timestamptz)
    ON CONFLICT DO NOTHING;

  END IF;


  -- ============================================================================
  -- STEP 10: Create tax documents for all succeeded donations
  -- Receipt numbers follow the KPFK-YY-NNNNN format.
  -- ============================================================================

  INSERT INTO tax_documents (
    donation_id, donor_id, station_id, document_type,
    receipt_number, gross_amount_cents, fmv_cents, deductible_cents,
    snapshot_json, generated_at, created_at
  )
  SELECT
    d.id,
    d.donor_id,
    d.station_id,
    'receipt',
    -- Generate receipt numbers: KPFK-YY-NNNNN
    'KPFK-' || to_char(d.received_at, 'YY') || '-' || lpad(row_number() OVER (ORDER BY d.received_at)::text, 5, '0'),
    d.amount_cents,
    0,  -- No FMV for donations without gifts (simplified for seed data)
    d.amount_cents,  -- Full amount is deductible when FMV is 0
    jsonb_build_object(
      'donor_name', dn.first_name || ' ' || dn.last_name,
      'donor_email', dn.email,
      'amount_cents', d.amount_cents,
      'date', d.received_at,
      'payment_method', d.payment_method_type
    ),
    d.received_at,
    d.received_at
  FROM donations d
  JOIN donors dn ON dn.id = d.donor_id
  WHERE d.status = 'succeeded'
    AND d.station_id = v_station_id
    AND d.received_at IS NOT NULL;


  -- ============================================================================
  -- Done! Summary of seeded data:
  --   25 donors, 4 campaigns, ~45 donations, 4 fulfillment items,
  --   6 memberships, 10 addresses, 12 tag assignments, tax docs for all succeeded.
  -- ============================================================================

  RAISE NOTICE 'Seed data created successfully for station %', v_station_id;

END $$;

-- PostgREST needs to know about any schema changes
NOTIFY pgrst, 'reload schema';
