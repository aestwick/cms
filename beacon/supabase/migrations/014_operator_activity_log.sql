-- ============================================================================
-- PHASE 014: Operator Activity Log
-- ============================================================================
-- Tracks all operator actions on the phone pledge form.
-- Used for auditing who took pledges, even when not authenticated.
--
-- In test mode: Form is open, but we log operator email with each action.
-- In production: IP whitelist or password required, but still logged.
-- ============================================================================

create table if not exists operator_activity_log (
    id                  uuid primary key default gen_random_uuid(),
    station_id          uuid not null references stations(id),

    -- Operator identification
    -- If authenticated: profile_id links to profiles table
    -- Always captured: operator_email (even if not authenticated)
    operator_profile_id uuid references profiles(id),
    operator_email      text not null,

    -- What happened
    action              text not null,
    -- Actions: 'form_loaded', 'donor_searched', 'donor_selected', 'donor_created',
    --          'pledge_started', 'payment_attempted', 'payment_succeeded',
    --          'payment_failed', 'pledge_created_billme'

    -- Context about the action (donation_id, donor_id, amount, error, etc.)
    metadata            jsonb not null default '{}',

    -- Request info for security auditing
    ip_address          text,
    user_agent          text,

    created_at          timestamptz not null default now()
);

-- Indexes for common queries
create index if not exists idx_operator_activity_station
    on operator_activity_log(station_id, created_at desc);
create index if not exists idx_operator_activity_email
    on operator_activity_log(operator_email, created_at desc);
create index if not exists idx_operator_activity_action
    on operator_activity_log(action, created_at desc);
create index if not exists idx_operator_activity_profile
    on operator_activity_log(operator_profile_id)
    where operator_profile_id is not null;

-- Comment for documentation
comment on table operator_activity_log is
    'Audit log for phone pledge form actions. Captures operator email even when unauthenticated.';

-- ============================================================================
-- End of Phase 014
-- ============================================================================
