-- Migration 066: Communications infrastructure
--
-- Adds three capabilities to the Beacon comms system:
-- 1. Inbound email tracking (reply.kpfk.org receives donor replies via Resend)
-- 2. Email preferences (donor opt-out for non-essential emails, CAN-SPAM)
-- 3. Enhanced email_log for Resend webhook delivery/bounce/complaint tracking
--
-- Context: reply.kpfk.org is configured in Resend as an inbound domain.
-- Resend POSTs to /api/webhook/resend when emails arrive or delivery events fire.

-- =============================================================================
-- 1. INBOUND EMAILS — donor replies received at reply.kpfk.org
-- =============================================================================

CREATE TABLE public.inbound_emails (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    station_id uuid NOT NULL REFERENCES public.stations(id),
    -- Link to donor if we can match the sender email
    donor_id uuid REFERENCES public.donors(id),
    -- Link to the outbound email this is replying to (if we can match via In-Reply-To header)
    in_reply_to_email_log_id uuid REFERENCES public.email_log(id),
    -- Resend's unique ID for this inbound email
    resend_id text UNIQUE,
    -- Envelope data
    from_email text NOT NULL,
    from_name text,
    to_email text NOT NULL,
    subject text,
    -- Body content — store both for display flexibility
    body_text text,
    body_html text,
    -- Headers we care about for threading
    message_id text,
    in_reply_to_header text,
    -- Staff workflow: has someone read/handled this reply?
    is_read boolean DEFAULT false NOT NULL,
    read_by uuid REFERENCES public.profiles(id),
    read_at timestamptz,
    -- Metadata from Resend
    received_at timestamptz DEFAULT now() NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL
);

-- Index for donor detail page: "show all replies from this donor"
CREATE INDEX idx_inbound_emails_donor_id ON public.inbound_emails(donor_id) WHERE donor_id IS NOT NULL;
-- Index for station scoping
CREATE INDEX idx_inbound_emails_station_id ON public.inbound_emails(station_id);
-- Index for unread inbox view
CREATE INDEX idx_inbound_emails_unread ON public.inbound_emails(station_id, is_read) WHERE is_read = false;
-- Index for matching replies to outbound emails
CREATE INDEX idx_inbound_emails_in_reply_to ON public.inbound_emails(in_reply_to_email_log_id) WHERE in_reply_to_email_log_id IS NOT NULL;

-- RLS: service role only for writes, authenticated can read (admin panel)
ALTER TABLE public.inbound_emails ENABLE ROW LEVEL SECURITY;
CREATE POLICY "inbound_emails_service_insert" ON public.inbound_emails
    FOR INSERT TO service_role WITH CHECK (true);
CREATE POLICY "inbound_emails_service_select" ON public.inbound_emails
    FOR SELECT TO service_role USING (true);
CREATE POLICY "inbound_emails_service_update" ON public.inbound_emails
    FOR UPDATE TO service_role USING (true);
CREATE POLICY "inbound_emails_authenticated_select" ON public.inbound_emails
    FOR SELECT TO authenticated USING (true);
CREATE POLICY "inbound_emails_authenticated_update" ON public.inbound_emails
    FOR UPDATE TO authenticated USING (true);
-- Anon and authenticated can't insert (webhook uses service role)
CREATE POLICY "inbound_emails_anon_deny" ON public.inbound_emails
    FOR ALL TO anon USING (false);

-- =============================================================================
-- 2. EMAIL PREFERENCES — donor opt-out for non-essential emails
-- =============================================================================
-- Non-essential = anything that isn't legally required (tax receipts) or
-- operationally critical (payment failed, refund confirmation).
-- Donors can opt out of: marketing-adjacent transactional emails like
-- reactivation outreach, annual tax summaries, fulfillment updates.

CREATE TABLE public.email_preferences (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    donor_id uuid NOT NULL REFERENCES public.donors(id),
    station_id uuid NOT NULL REFERENCES public.stations(id),
    -- Category-level opt-outs. true = subscribed (default), false = opted out.
    -- Granular enough to be useful, not so granular that it's overwhelming.
    receive_fulfillment_updates boolean DEFAULT true NOT NULL,
    receive_membership_reminders boolean DEFAULT true NOT NULL,
    receive_reactivation_emails boolean DEFAULT true NOT NULL,
    receive_annual_summary boolean DEFAULT true NOT NULL,
    receive_portal_notifications boolean DEFAULT true NOT NULL,
    -- Global kill switch — if false, only legally-required emails send
    -- (tax receipts, refund confirmations, payment failure notices)
    receive_all_optional boolean DEFAULT true NOT NULL,
    -- When/how they changed preferences
    updated_at timestamptz DEFAULT now() NOT NULL,
    updated_via text DEFAULT 'portal' NOT NULL,  -- 'portal', 'unsubscribe_link', 'admin', 'api'
    created_at timestamptz DEFAULT now() NOT NULL,
    -- One preference row per donor per station
    CONSTRAINT email_preferences_donor_station_unique UNIQUE (donor_id, station_id)
);

CREATE INDEX idx_email_preferences_donor_id ON public.email_preferences(donor_id);
CREATE INDEX idx_email_preferences_station_id ON public.email_preferences(station_id);

-- RLS: service role full access, authenticated read-only (admin panel)
ALTER TABLE public.email_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "email_preferences_service_all" ON public.email_preferences
    FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "email_preferences_authenticated_select" ON public.email_preferences
    FOR SELECT TO authenticated USING (true);
-- Anon can't access
CREATE POLICY "email_preferences_anon_deny" ON public.email_preferences
    FOR ALL TO anon USING (false);

-- =============================================================================
-- 3. ENHANCED EMAIL_LOG — Resend webhook delivery tracking
-- =============================================================================

-- Add columns for Resend webhook event data.
-- email_log already has: status (sent/failed/delivered/bounced), delivered_at, external_id
-- We need: bounce details, complaint tracking, and opened/clicked tracking.

-- Bounce reason from Resend (e.g., "mailbox_full", "invalid_email")
ALTER TABLE public.email_log ADD COLUMN IF NOT EXISTS bounce_type text;
-- Complaint type (e.g., "abuse", "fraud")
ALTER TABLE public.email_log ADD COLUMN IF NOT EXISTS complaint_type text;
-- Track opens and clicks for delivery analytics
ALTER TABLE public.email_log ADD COLUMN IF NOT EXISTS opened_at timestamptz;
ALTER TABLE public.email_log ADD COLUMN IF NOT EXISTS clicked_at timestamptz;
-- Resend webhook event ID for dedup
ALTER TABLE public.email_log ADD COLUMN IF NOT EXISTS last_webhook_event_id text;
-- When status was last updated by webhook
ALTER TABLE public.email_log ADD COLUMN IF NOT EXISTS status_updated_at timestamptz;

-- Add 'complained' and 'opened' to the status check constraint.
-- Need to drop and recreate since we're expanding the allowed values.
ALTER TABLE public.email_log DROP CONSTRAINT IF EXISTS email_log_status_check;
ALTER TABLE public.email_log ADD CONSTRAINT email_log_status_check
    CHECK (status = ANY (ARRAY['pending', 'sent', 'delivered', 'bounced', 'failed', 'complained']));

-- Index for Resend webhook lookups (match by external_id = Resend message ID)
CREATE INDEX IF NOT EXISTS idx_email_log_external_id ON public.email_log(external_id) WHERE external_id IS NOT NULL;

-- Index for comms history on donor detail page
CREATE INDEX IF NOT EXISTS idx_email_log_donor_id ON public.email_log(donor_id) WHERE donor_id IS NOT NULL;

-- =============================================================================
-- Done — notify PostgREST to reload schema cache
-- =============================================================================
NOTIFY pgrst, 'reload schema';
