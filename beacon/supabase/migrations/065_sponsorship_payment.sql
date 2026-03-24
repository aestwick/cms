-- Migration 065: Payment columns on sponsorship_inquiries
--
-- Phase B addition — adds the columns needed for the collect-payment link flow
-- and form checkout on event sponsor pages. These columns track:
--   - Final deal amount (set by staff when confirming a deal)
--   - Stripe PaymentIntent for tracking payment
--   - Payment link token for the time-limited collect-payment URL
--   - Payment status and completion timestamp
--
-- Separated from migration 062 because payment flow is built after the
-- inquiry pipeline is working. Adding columns to an existing table is safe
-- and doesn't require a full table rebuild.
--
-- All statements are idempotent.


-- ============================================================================
-- 1. Add payment columns to sponsorship_inquiries
-- ============================================================================

-- deal_amount_cents: final confirmed amount, set by staff when deal is agreed
-- null until a deal is confirmed (most inquiries won't have this)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'sponsorship_inquiries' AND column_name = 'deal_amount_cents'
    ) THEN
        ALTER TABLE public.sponsorship_inquiries
            ADD COLUMN deal_amount_cents bigint CHECK (deal_amount_cents IS NULL OR deal_amount_cents >= 0);
        COMMENT ON COLUMN public.sponsorship_inquiries.deal_amount_cents IS
            'Final confirmed deal amount in cents. Set by staff. null until deal confirmed.';
    END IF;
END $$;

-- stripe_payment_intent_id: tracks the Stripe PaymentIntent for this payment
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'sponsorship_inquiries' AND column_name = 'stripe_payment_intent_id'
    ) THEN
        ALTER TABLE public.sponsorship_inquiries
            ADD COLUMN stripe_payment_intent_id text;
        COMMENT ON COLUMN public.sponsorship_inquiries.stripe_payment_intent_id IS
            'Stripe PaymentIntent ID for tracking payment.';
    END IF;
END $$;

-- Unique index on stripe_payment_intent_id (only non-null values)
CREATE UNIQUE INDEX IF NOT EXISTS sponsorship_inquiries_stripe_pi_idx
    ON public.sponsorship_inquiries(stripe_payment_intent_id)
    WHERE stripe_payment_intent_id IS NOT NULL;

-- payment_status: where the payment is in the Stripe flow
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'sponsorship_inquiries' AND column_name = 'payment_status'
    ) THEN
        ALTER TABLE public.sponsorship_inquiries
            ADD COLUMN payment_status text CHECK (payment_status IS NULL OR payment_status IN ('pending', 'succeeded', 'failed'));
        COMMENT ON COLUMN public.sponsorship_inquiries.payment_status IS
            'Payment status: pending (initiated), succeeded (paid), failed. null = no payment attempted.';
    END IF;
END $$;

-- payment_link_token: unique token for the collect-payment URL
-- e.g., sponsor.kpfk.org/pay/{payment_link_token}
-- Time-limited — expiration tracked by payment_link_expires_at
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'sponsorship_inquiries' AND column_name = 'payment_link_token'
    ) THEN
        ALTER TABLE public.sponsorship_inquiries
            ADD COLUMN payment_link_token text;
        COMMENT ON COLUMN public.sponsorship_inquiries.payment_link_token IS
            'Token for the collect-payment URL. Time-limited via payment_link_expires_at.';
    END IF;
END $$;

-- Unique index on payment_link_token (only non-null values)
CREATE UNIQUE INDEX IF NOT EXISTS sponsorship_inquiries_payment_link_token_idx
    ON public.sponsorship_inquiries(payment_link_token)
    WHERE payment_link_token IS NOT NULL;

-- payment_link_expires_at: when the collect-payment link expires (e.g., 7 days)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'sponsorship_inquiries' AND column_name = 'payment_link_expires_at'
    ) THEN
        ALTER TABLE public.sponsorship_inquiries
            ADD COLUMN payment_link_expires_at timestamptz;
        COMMENT ON COLUMN public.sponsorship_inquiries.payment_link_expires_at IS
            'When the collect-payment link expires. Checked server-side before allowing payment.';
    END IF;
END $$;

-- paid_at: when the payment actually succeeded
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'sponsorship_inquiries' AND column_name = 'paid_at'
    ) THEN
        ALTER TABLE public.sponsorship_inquiries
            ADD COLUMN paid_at timestamptz;
        COMMENT ON COLUMN public.sponsorship_inquiries.paid_at IS
            'Timestamp when payment succeeded. Set by webhook handler.';
    END IF;
END $$;


-- ============================================================================
-- 2. Notify PostgREST to reload schema cache
-- ============================================================================
NOTIFY pgrst, 'reload schema';
