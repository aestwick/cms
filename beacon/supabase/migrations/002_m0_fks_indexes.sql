-- ============================================================================
-- PHASE 002: M0 Foreign Keys + Indexes
-- ============================================================================
-- Adds referential integrity and performance indexes for M0 tables.
-- Run AFTER 001_m0_base_tables.sql
--
-- Index strategy:
--   - FK columns get indexes (Postgres doesn't auto-index FKs)
--   - Partial indexes on deleted_at IS NULL for soft-delete tables
--   - Composite indexes for common query patterns
--   - Unique indexes where business logic requires
-- ============================================================================

-- ----------------------------------------------------------------------------
-- FOREIGN KEYS
-- ----------------------------------------------------------------------------

-- shows
alter table shows
    add constraint shows_station_id_fkey
    foreign key (station_id) references stations(id);

-- campaigns
alter table campaigns
    add constraint campaigns_station_id_fkey
    foreign key (station_id) references stations(id);

-- donors
alter table donors
    add constraint donors_station_id_fkey
    foreign key (station_id) references stations(id);

-- gifts
alter table gifts
    add constraint gifts_station_id_fkey
    foreign key (station_id) references stations(id);

-- memberships
alter table memberships
    add constraint memberships_donor_id_fkey
    foreign key (donor_id) references donors(id),
    add constraint memberships_station_id_fkey
    foreign key (station_id) references stations(id);

-- checkout_sessions
alter table checkout_sessions
    add constraint checkout_sessions_station_id_fkey
    foreign key (station_id) references stations(id),
    add constraint checkout_sessions_donor_id_fkey
    foreign key (donor_id) references donors(id),
    add constraint checkout_sessions_donation_id_fkey
    foreign key (donation_id) references donations(id);
-- Note: operator_id FK to profiles added in phase 005 (profiles doesn't exist yet)

-- donations
alter table donations
    add constraint donations_donor_id_fkey
    foreign key (donor_id) references donors(id),
    add constraint donations_station_id_fkey
    foreign key (station_id) references stations(id),
    add constraint donations_checkout_session_id_fkey
    foreign key (checkout_session_id) references checkout_sessions(id),
    add constraint donations_campaign_id_fkey
    foreign key (campaign_id) references campaigns(id),
    add constraint donations_show_id_fkey
    foreign key (show_id) references shows(id),
    add constraint donations_gift_id_fkey
    foreign key (gift_id) references gifts(id);
-- Note: operator_id FK to profiles added in phase 005

-- tax_documents
alter table tax_documents
    add constraint tax_documents_donation_id_fkey
    foreign key (donation_id) references donations(id),
    add constraint tax_documents_donor_id_fkey
    foreign key (donor_id) references donors(id),
    add constraint tax_documents_station_id_fkey
    foreign key (station_id) references stations(id),
    add constraint tax_documents_supersedes_id_fkey
    foreign key (supersedes_id) references tax_documents(id);

-- email_log
alter table email_log
    add constraint email_log_station_id_fkey
    foreign key (station_id) references stations(id),
    add constraint email_log_donor_id_fkey
    foreign key (donor_id) references donors(id),
    add constraint email_log_donation_id_fkey
    foreign key (donation_id) references donations(id);

-- audit_log
alter table audit_log
    add constraint audit_log_station_id_fkey
    foreign key (station_id) references stations(id);
-- Note: user_id FK to profiles added in phase 005

-- system_events: no FKs (standalone append-only log)

-- ----------------------------------------------------------------------------
-- INDEXES: stations
-- ----------------------------------------------------------------------------
create index stations_code_idx on stations(code) where deleted_at is null;
create index stations_deleted_at_idx on stations(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: shows
-- ----------------------------------------------------------------------------
create index shows_station_id_idx on shows(station_id) where deleted_at is null;
create unique index shows_station_slug_idx on shows(station_id, slug) where deleted_at is null;
create index shows_deleted_at_idx on shows(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: campaigns
-- ----------------------------------------------------------------------------
create index campaigns_station_id_idx on campaigns(station_id) where deleted_at is null;
create unique index campaigns_station_code_idx on campaigns(station_id, code) where deleted_at is null;
create index campaigns_is_active_idx on campaigns(station_id, is_active) where deleted_at is null;
create index campaigns_dates_idx on campaigns(station_id, starts_at, ends_at) where deleted_at is null;
create index campaigns_deleted_at_idx on campaigns(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: donors
-- ----------------------------------------------------------------------------
create index donors_station_id_idx on donors(station_id) where deleted_at is null;
create index donors_email_normalized_idx on donors(email_normalized) where deleted_at is null;
-- Unique constraints (partial - soft delete aware)
create unique index donors_station_email_unique_idx 
    on donors(station_id, email_normalized) 
    where deleted_at is null;
-- Stripe ID uniqueness (idempotency)
create unique index donors_stripe_customer_id_unique_idx 
    on donors(stripe_customer_id) 
    where stripe_customer_id is not null and deleted_at is null;
create index donors_deleted_at_idx on donors(deleted_at) where deleted_at is null;
-- Full-text search on name (optional, can be added later)
-- create index donors_name_search_idx on donors using gin(to_tsvector('english', coalesce(first_name, '') || ' ' || coalesce(last_name, '')));

-- ----------------------------------------------------------------------------
-- INDEXES: gifts
-- ----------------------------------------------------------------------------
create index gifts_station_id_idx on gifts(station_id) where deleted_at is null;
create index gifts_category_idx on gifts(station_id, category) where deleted_at is null and is_active = true;
create index gifts_is_active_idx on gifts(station_id, is_active, sort_order) where deleted_at is null;
create index gifts_deleted_at_idx on gifts(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: memberships
-- ----------------------------------------------------------------------------
create index memberships_donor_id_idx on memberships(donor_id) where deleted_at is null;
create index memberships_station_id_idx on memberships(station_id) where deleted_at is null;
-- Stripe ID uniqueness (idempotency)
create unique index memberships_stripe_subscription_unique_idx on memberships(stripe_subscription_id) 
    where stripe_subscription_id is not null and deleted_at is null;
create index memberships_status_idx on memberships(station_id, status) where deleted_at is null;
create index memberships_lapsed_idx on memberships(station_id, lapsed_at) 
    where deleted_at is null and lapsed_at is not null;
create index memberships_payment_failed_idx on memberships(station_id, payment_failed_at) 
    where deleted_at is null and payment_failed_at is not null;
create index memberships_deleted_at_idx on memberships(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: checkout_sessions
-- ----------------------------------------------------------------------------
create index checkout_sessions_station_id_idx on checkout_sessions(station_id);
create index checkout_sessions_stripe_id_idx on checkout_sessions(stripe_checkout_session_id) 
    where stripe_checkout_session_id is not null;
create index checkout_sessions_status_idx on checkout_sessions(station_id, status);
create index checkout_sessions_pending_idx on checkout_sessions(expires_at) 
    where status = 'pending';
create index checkout_sessions_donor_id_idx on checkout_sessions(donor_id) 
    where donor_id is not null;
create index checkout_sessions_donation_id_idx on checkout_sessions(donation_id) 
    where donation_id is not null;
-- Operational: "what's pending/recent?"
create index checkout_sessions_ops_idx on checkout_sessions(status, created_at desc);

-- ----------------------------------------------------------------------------
-- INDEXES: donations
-- ----------------------------------------------------------------------------
create index donations_donor_id_idx on donations(donor_id) where deleted_at is null;
create index donations_station_id_idx on donations(station_id) where deleted_at is null;
create index donations_campaign_id_idx on donations(campaign_id) where deleted_at is null and campaign_id is not null;
create index donations_show_id_idx on donations(show_id) where deleted_at is null and show_id is not null;
create index donations_gift_id_idx on donations(gift_id) where deleted_at is null and gift_id is not null;
create index donations_checkout_session_id_idx on donations(checkout_session_id) 
    where checkout_session_id is not null;
create index donations_status_idx on donations(station_id, status) where deleted_at is null;
create index donations_payment_provider_idx on donations(station_id, payment_provider) where deleted_at is null;
-- Stripe ID uniqueness (idempotency)
create unique index donations_stripe_pi_unique_idx on donations(stripe_payment_intent_id) 
    where stripe_payment_intent_id is not null and deleted_at is null;
create index donations_received_at_idx on donations(station_id, received_at) 
    where deleted_at is null and received_at is not null;
create index donations_created_at_idx on donations(station_id, created_at) where deleted_at is null;
create index donations_deleted_at_idx on donations(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: tax_documents
-- ----------------------------------------------------------------------------
create index tax_documents_donation_id_idx on tax_documents(donation_id);
create index tax_documents_donor_id_idx on tax_documents(donor_id);
create index tax_documents_station_id_idx on tax_documents(station_id);
create index tax_documents_supersedes_id_idx on tax_documents(supersedes_id) 
    where supersedes_id is not null;
create index tax_documents_document_type_idx on tax_documents(station_id, document_type);
create index tax_documents_generated_at_idx on tax_documents(station_id, generated_at);
-- Find current (non-superseded) documents
create index tax_documents_current_idx on tax_documents(donation_id) 
    where superseded_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: email_log
-- ----------------------------------------------------------------------------
create index email_log_station_id_idx on email_log(station_id);
create index email_log_donor_id_idx on email_log(donor_id) where donor_id is not null;
create index email_log_donation_id_idx on email_log(donation_id) where donation_id is not null;
create index email_log_template_idx on email_log(station_id, template_name);
create index email_log_status_idx on email_log(status);
create index email_log_external_id_idx on email_log(external_id) where external_id is not null;
create index email_log_created_at_idx on email_log(station_id, created_at);

-- ----------------------------------------------------------------------------
-- INDEXES: audit_log
-- ----------------------------------------------------------------------------
create index audit_log_station_id_idx on audit_log(station_id) where station_id is not null;
create index audit_log_user_id_idx on audit_log(user_id) where user_id is not null;
create index audit_log_table_record_idx on audit_log(table_name, record_id);
create index audit_log_action_idx on audit_log(action);
create index audit_log_created_at_idx on audit_log(created_at);
-- For audit queries by table + time range
create index audit_log_table_time_idx on audit_log(table_name, created_at);
-- Operational: "history of this record" with efficient pagination
create index audit_log_record_history_idx on audit_log(table_name, record_id, created_at desc);

-- ----------------------------------------------------------------------------
-- INDEXES: system_events
-- ----------------------------------------------------------------------------
-- idempotency_key already has unique constraint (acts as index)
create index system_events_event_type_idx on system_events(event_type);
create index system_events_source_idx on system_events(source);
create index system_events_status_idx on system_events(status);
create index system_events_pending_idx on system_events(created_at) 
    where status in ('pending', 'processing');
create index system_events_created_at_idx on system_events(created_at);
-- Operational: "recent events by type" for debugging
create index system_events_type_time_idx on system_events(event_type, created_at desc);

-- ============================================================================
-- End of Phase 002
-- Next: 003_m0_rls_policies.sql (Row Level Security)
-- ============================================================================
