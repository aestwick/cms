-- Migration 049: Add station contact info columns
--
-- Moves all hardcoded station identity data (EIN, phone, addresses, emails,
-- etc.) into the stations table so they can be read from the database and
-- eventually edited in the admin UI. This is the first step toward
-- multi-station support and eliminating hardcoded values from code.
--
-- Three address types:
--   office_address  — business/admin office (111 N Jackson St, Glendale)
--   mailing_address — where donors mail checks (PO Box 8639, Universal City)
--   studio_address  — broadcast studio (if different from office, nullable)

-- ============================================================================
-- 1. Add columns to stations table
-- ============================================================================
ALTER TABLE stations
  ADD COLUMN IF NOT EXISTS legal_name text,
  ADD COLUMN IF NOT EXISTS ein text,
  ADD COLUMN IF NOT EXISTS frequency text,
  ADD COLUMN IF NOT EXISTS phone text,
  ADD COLUMN IF NOT EXISTS phone_tel text,
  ADD COLUMN IF NOT EXISTS email text,
  ADD COLUMN IF NOT EXISTS major_gift_email text,
  ADD COLUMN IF NOT EXISTS office_address jsonb DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS mailing_address jsonb DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS studio_address jsonb,
  ADD COLUMN IF NOT EXISTS operating_hours text,
  ADD COLUMN IF NOT EXISTS founded_year integer,
  ADD COLUMN IF NOT EXISTS locale text DEFAULT 'en-US',
  ADD COLUMN IF NOT EXISTS currency text DEFAULT 'USD';

-- ============================================================================
-- 2. Seed KPFK contact data
-- ============================================================================
UPDATE stations SET
  legal_name = 'Pacifica Foundation',
  ein = '94-1347046',
  frequency = '90.7',
  phone = '(818) 985-5735',
  phone_tel = '+18189855735',
  email = 'giving@kpfk.org',
  major_gift_email = 'gm@kpfk.org',
  office_address = jsonb_build_object(
    'line1', '111 N Jackson St',
    'line2', 'Suite 201',
    'city', 'Glendale',
    'state', 'CA',
    'zip', '91206'
  ),
  mailing_address = jsonb_build_object(
    'line1', 'PO Box 8639',
    'city', 'Universal City',
    'state', 'CA',
    'zip', '91618'
  ),
  studio_address = NULL,
  operating_hours = 'Monday–Friday, 10am–6pm',
  founded_year = 1959,
  locale = 'en-US',
  currency = 'USD'
WHERE code = 'kpfk';

-- ============================================================================
-- 3. Add staff notification email config to station_settings
--    Admins can set to/cc recipients for staff notifications in the admin UI.
--    Supports multiple email addresses per field.
-- ============================================================================
-- Ensure a station_settings row exists for KPFK (upsert pattern)
INSERT INTO station_settings (station_id, settings)
SELECT id, jsonb_build_object(
  'phone_pledge', jsonb_build_object(
    'bill_me_due_days', 30,
    'reminder_days', '[7, 21, 30]'::jsonb,
    'enabled_methods', '["card", "bill_me", "check"]'::jsonb
  ),
  'notifications', jsonb_build_object(
    'staff_donation_to', '["subscriptions@kpfk.org"]'::jsonb,
    'staff_donation_cc', '["giving@kpfk.org"]'::jsonb,
    'alert_to', '["giving@kpfk.org"]'::jsonb
  )
)
FROM stations WHERE code = 'kpfk'
ON CONFLICT (station_id)
DO UPDATE SET
  settings = station_settings.settings || jsonb_build_object(
    'notifications', jsonb_build_object(
      'staff_donation_to', '["subscriptions@kpfk.org"]'::jsonb,
      'staff_donation_cc', '["giving@kpfk.org"]'::jsonb,
      'alert_to', '["giving@kpfk.org"]'::jsonb
    )
  ),
  updated_at = now();

-- ============================================================================
-- 4. Notify PostgREST to pick up schema changes
-- ============================================================================
NOTIFY pgrst, 'reload schema';
