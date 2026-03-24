-- Migration 034: Feedback responses table
-- Stores donor feedback from three form types:
--   1. donation_experience — linked from donation receipt emails
--   2. fulfillment_satisfaction — linked from shipped/delivered emails
--   3. cancellation — linked from membership cancellation emails
--
-- Forms are public (no auth required) but use HMAC-signed tokens
-- in the URL to prevent spam and link responses to specific donors/donations.

create table if not exists public.feedback_responses (
  id uuid primary key default gen_random_uuid(),
  station_id uuid not null references stations(id),

  -- Who and what this feedback is about (all nullable for flexibility)
  donor_id uuid references donors(id),
  donation_id uuid references donations(id),
  membership_id uuid,           -- for cancellation feedback (no FK — memberships may not exist yet)
  fulfillment_item_id uuid,     -- for fulfillment satisfaction (no FK — same reason)

  -- The feedback itself
  form_type text not null,      -- which form was submitted
  rating integer,               -- 1-5 stars (not all forms require this)
  selections jsonb,             -- multiple choice answers, e.g. {"items": ["cost", "programming"]}
  message text,                 -- free text response

  -- Extensible metadata (e.g. browser info, referrer, form version)
  metadata jsonb default '{}'::jsonb,

  -- Timestamps — follows Beacon conventions
  created_at timestamptz not null default now(),
  deleted_at timestamptz,       -- soft delete

  -- Constraints
  constraint feedback_form_type_check check (
    form_type in ('donation_experience', 'fulfillment_satisfaction', 'cancellation')
  ),
  constraint feedback_rating_range check (
    rating is null or (rating >= 1 and rating <= 5)
  )
);

-- Indexes for dashboard queries
-- Using IF NOT EXISTS so this migration is safe to re-run
-- Station + form type + date is the primary dashboard query pattern
create index if not exists idx_feedback_station_type_created
  on feedback_responses(station_id, form_type, created_at desc)
  where deleted_at is null;

-- Look up all feedback for a specific donation (shown on donation detail page)
create index if not exists idx_feedback_donation
  on feedback_responses(donation_id)
  where deleted_at is null and donation_id is not null;

-- Look up all feedback from a specific donor (shown on donor profile)
create index if not exists idx_feedback_donor
  on feedback_responses(donor_id)
  where deleted_at is null and donor_id is not null;

-- RLS policies — feedback_responses is written by public (form submissions)
-- and read by staff (dashboard). Using service role for writes (API route
-- handles token verification), so RLS is mostly for defense in depth.

alter table feedback_responses enable row level security;

-- Drop-then-create for idempotency (policies don't support IF NOT EXISTS)
drop policy if exists "feedback_staff_read" on feedback_responses;
drop policy if exists "feedback_super_admin_read" on feedback_responses;

-- Staff can read feedback for their station
create policy "feedback_staff_read" on feedback_responses
  for select to authenticated
  using (
    station_id in (
      select station_id from profiles
      where id = auth.uid()
        and role in ('super_admin', 'admin', 'ops')
        and deleted_at is null
    )
  );

-- Super admin can read all feedback
create policy "feedback_super_admin_read" on feedback_responses
  for select to authenticated
  using (
    exists (
      select 1 from profiles
      where id = auth.uid()
        and role = 'super_admin'
        and deleted_at is null
    )
  );

-- No public read/write via RLS — all writes go through service role in API route
-- This prevents anyone from querying feedback directly via PostgREST

-- Notify PostgREST to reload schema cache
notify pgrst, 'reload schema';
