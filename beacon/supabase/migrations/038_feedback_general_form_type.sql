-- Migration 038: Fix feedback_responses permissions + add 'general' form type
--
-- Part 1: Fix "permission denied for table feedback_responses" on the admin dashboard.
-- The original migration (034) created the table and RLS policies but didn't include
-- explicit GRANTs. If default privileges weren't inherited (e.g., migration ran as a
-- role other than postgres), the authenticated and service_role roles can't access
-- the table at all — even though RLS policies exist. This adds the missing GRANTs.
--
-- Part 2: Add 'general' form type so feedback.kpfk.org can accept general feedback
-- without a token. Previously only donation_experience, fulfillment_satisfaction,
-- and cancellation were allowed — all requiring HMAC-signed email links.

-- Fix table-level permissions (Part 1)
-- service_role needs full access for API routes (getSupabaseAdmin)
-- authenticated needs SELECT for RLS-gated dashboard queries
-- anon gets no access (all writes go through service role in API routes)
grant select, insert, update, delete on feedback_responses to service_role;
grant select on feedback_responses to authenticated;

-- Add 'general' to the form_type constraint (Part 2)
alter table feedback_responses
  drop constraint if exists feedback_form_type_check;

alter table feedback_responses
  add constraint feedback_form_type_check check (
    form_type in ('donation_experience', 'fulfillment_satisfaction', 'cancellation', 'general')
  );

-- Notify PostgREST to reload schema cache
notify pgrst, 'reload schema';
