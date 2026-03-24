-- ============================================================================
-- PHASE 006: M3 Events & Tickets Tables
-- ============================================================================
-- Creates ticketing system tables.
-- Tables: events, ticket_types, event_registrations, event_registration_gifts,
--         promo_codes
--
-- Run AFTER 005_m1_fks_indexes_rls.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- events: Event records
-- ----------------------------------------------------------------------------
create table events (
    id              uuid primary key default gen_random_uuid(),
    station_id      uuid not null references stations(id),
    campaign_id     uuid references campaigns(id),              -- optional campaign link
    show_id         uuid references shows(id),                  -- optional show link
    
    -- Event details
    name            text not null,
    slug            text not null,
    description     text,
    
    -- Timing
    starts_at       timestamptz not null,
    ends_at         timestamptz,
    doors_open_at   timestamptz,
    timezone        text not null default 'America/Los_Angeles',
    
    -- Location
    venue_name      text,
    venue_address   text,
    venue_city      text,
    venue_state     text,
    venue_postal    text,
    is_virtual      boolean not null default false,
    virtual_url     text,                                       -- Zoom/YouTube link
    
    -- Capacity
    total_capacity  integer,                                    -- null = unlimited
    
    -- Status
    status          text not null default 'draft',              -- draft, published, cancelled, completed
    published_at    timestamptz,
    
    -- Settings
    registration_opens_at   timestamptz,
    registration_closes_at  timestamptz,
    allow_waitlist          boolean not null default false,
    
    -- Images/media
    image_url       text,
    
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz
);

-- Status constraint
alter table events
    add constraint events_status_check
    check (status in ('draft', 'published', 'cancelled', 'completed'));

-- ----------------------------------------------------------------------------
-- ticket_types: Ticket tiers per event
-- ----------------------------------------------------------------------------
create table ticket_types (
    id              uuid primary key default gen_random_uuid(),
    event_id        uuid not null references events(id),
    
    -- Ticket details
    name            text not null,                              -- "General Admission", "VIP", "Student"
    description     text,
    
    -- Pricing
    price_cents     bigint not null default 0,                  -- 0 = free
    fmv_cents       bigint not null default 0,                  -- fair market value for tax purposes
    
    -- Sliding scale support
    is_sliding_scale    boolean not null default false,
    min_price_cents     bigint,                                 -- minimum for sliding scale
    max_price_cents     bigint,                                 -- maximum for sliding scale
    suggested_price_cents bigint,                               -- default/suggested amount
    
    -- Capacity
    capacity        integer,                                    -- null = unlimited (up to event capacity)
    
    -- Availability
    available_from  timestamptz,
    available_until timestamptz,
    is_active       boolean not null default true,
    
    -- Display
    sort_order      integer not null default 0,
    
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz
);

-- ----------------------------------------------------------------------------
-- promo_codes: Discount codes for events
-- ----------------------------------------------------------------------------
create table promo_codes (
    id              uuid primary key default gen_random_uuid(),
    station_id      uuid not null references stations(id),
    event_id        uuid references events(id),                 -- null = station-wide code
    
    -- Code
    code            text not null,                              -- uppercase, normalized
    
    -- Discount
    discount_type   text not null,                              -- percent, fixed_amount, free
    discount_percent integer,                                   -- e.g., 20 for 20%
    discount_cents  bigint,                                     -- fixed amount off
    
    -- Limits
    max_uses        integer,                                    -- null = unlimited
    times_used      integer not null default 0,
    max_uses_per_donor integer,                                 -- null = unlimited
    
    -- Validity
    valid_from      timestamptz,
    valid_until     timestamptz,
    is_active       boolean not null default true,
    
    -- Restrictions
    min_purchase_cents bigint,                                  -- minimum order to apply
    applicable_ticket_type_ids uuid[],                          -- null = all types
    
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz
);

-- Discount type constraint
alter table promo_codes
    add constraint promo_codes_discount_type_check
    check (discount_type in ('percent', 'fixed_amount', 'free'));

-- Unique code per station (or event)
create unique index promo_codes_station_code_idx 
    on promo_codes(station_id, upper(code)) 
    where deleted_at is null and event_id is null;

create unique index promo_codes_event_code_idx 
    on promo_codes(event_id, upper(code)) 
    where deleted_at is null and event_id is not null;

-- ----------------------------------------------------------------------------
-- event_registrations: Ticket orders/RSVPs
-- ----------------------------------------------------------------------------
create table event_registrations (
    id              uuid primary key default gen_random_uuid(),
    event_id        uuid not null references events(id),
    ticket_type_id  uuid not null references ticket_types(id),
    donor_id        uuid references donors(id),                 -- null for anonymous/guest
    donation_id     uuid references donations(id),              -- linked payment
    
    -- Attendee info (snapshot, in case donor updates later)
    attendee_name   text not null,
    attendee_email  text not null,
    attendee_phone  text,
    
    -- Ticket details
    quantity        integer not null default 1,
    unit_price_cents bigint not null,                           -- price at time of purchase
    total_cents     bigint not null,                            -- quantity * unit_price
    
    -- Promo code
    promo_code_id   uuid references promo_codes(id),
    discount_cents  bigint not null default 0,
    
    -- Status
    status          text not null default 'pending',            -- pending, confirmed, cancelled, refunded, waitlisted
    confirmed_at    timestamptz,
    cancelled_at    timestamptz,
    
    -- Check-in
    checked_in      boolean not null default false,
    checked_in_at   timestamptz,
    checked_in_by   uuid references profiles(id),
    
    -- Notes
    special_requests text,
    internal_notes  text,
    
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    deleted_at      timestamptz
);

-- Status constraint
alter table event_registrations
    add constraint event_registrations_status_check
    check (status in ('pending', 'confirmed', 'cancelled', 'refunded', 'waitlisted'));

-- ----------------------------------------------------------------------------
-- event_registration_gifts: Add-on gifts for registrations
-- ----------------------------------------------------------------------------
create table event_registration_gifts (
    id                  uuid primary key default gen_random_uuid(),
    registration_id     uuid not null references event_registrations(id),
    gift_variant_id     uuid not null references gift_variants(id),
    
    -- Quantity
    quantity            integer not null default 1,
    
    -- Fulfillment link
    fulfillment_item_id uuid references fulfillment_items(id),
    
    created_at          timestamptz not null default now()
    -- No updated_at/deleted_at: immutable junction table
);

-- Prevent duplicate gift selections
create unique index event_registration_gifts_unique_idx 
    on event_registration_gifts(registration_id, gift_variant_id);

-- ----------------------------------------------------------------------------
-- INDEXES: events
-- ----------------------------------------------------------------------------
create index events_station_id_idx on events(station_id) where deleted_at is null;
create index events_campaign_id_idx on events(campaign_id) where campaign_id is not null;
create index events_show_id_idx on events(show_id) where show_id is not null;
create unique index events_station_slug_idx on events(station_id, slug) where deleted_at is null;
create index events_status_idx on events(station_id, status) where deleted_at is null;
create index events_starts_at_idx on events(station_id, starts_at) where deleted_at is null;
create index events_published_idx on events(station_id, starts_at) 
    where deleted_at is null and status = 'published';
create index events_deleted_at_idx on events(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: ticket_types
-- ----------------------------------------------------------------------------
create index ticket_types_event_id_idx on ticket_types(event_id) where deleted_at is null;
create index ticket_types_active_idx on ticket_types(event_id, is_active, sort_order) 
    where deleted_at is null;
create index ticket_types_deleted_at_idx on ticket_types(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: promo_codes
-- ----------------------------------------------------------------------------
create index promo_codes_station_id_idx on promo_codes(station_id) where deleted_at is null;
create index promo_codes_event_id_idx on promo_codes(event_id) where event_id is not null;
create index promo_codes_active_idx on promo_codes(station_id, is_active) where deleted_at is null;
create index promo_codes_deleted_at_idx on promo_codes(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: event_registrations
-- ----------------------------------------------------------------------------
create index event_registrations_event_id_idx on event_registrations(event_id) where deleted_at is null;
create index event_registrations_ticket_type_id_idx on event_registrations(ticket_type_id) where deleted_at is null;
create index event_registrations_donor_id_idx on event_registrations(donor_id) where donor_id is not null;
create index event_registrations_donation_id_idx on event_registrations(donation_id) where donation_id is not null;
create index event_registrations_status_idx on event_registrations(event_id, status) where deleted_at is null;
create index event_registrations_email_idx on event_registrations(attendee_email) where deleted_at is null;
create index event_registrations_checkin_idx on event_registrations(event_id, checked_in)
    where deleted_at is null and status = 'confirmed';
create index event_registrations_deleted_at_idx on event_registrations(deleted_at) where deleted_at is null;

-- ----------------------------------------------------------------------------
-- INDEXES: event_registration_gifts
-- ----------------------------------------------------------------------------
create index event_registration_gifts_registration_id_idx on event_registration_gifts(registration_id);
create index event_registration_gifts_gift_variant_id_idx on event_registration_gifts(gift_variant_id);
create index event_registration_gifts_fulfillment_idx on event_registration_gifts(fulfillment_item_id) 
    where fulfillment_item_id is not null;

-- ----------------------------------------------------------------------------
-- RLS: events (public read for published, staff write)
-- ----------------------------------------------------------------------------
alter table events enable row level security;

-- Public can see published events
create policy "events_anon_select"
    on events for select to anon
    using (deleted_at is null and status = 'published');

create policy "events_authenticated_select"
    on events for select to authenticated
    using (deleted_at is null);

create policy "events_service_role_all"
    on events for all to service_role
    using (true) with check (true);

-- ----------------------------------------------------------------------------
-- RLS: ticket_types (public read for active)
-- ----------------------------------------------------------------------------
alter table ticket_types enable row level security;

create policy "ticket_types_anon_select"
    on ticket_types for select to anon
    using (
        deleted_at is null 
        and is_active = true
        and exists (
            select 1 from events e 
            where e.id = ticket_types.event_id 
            and e.status = 'published'
            and e.deleted_at is null
        )
    );

create policy "ticket_types_authenticated_select"
    on ticket_types for select to authenticated
    using (deleted_at is null);

create policy "ticket_types_service_role_all"
    on ticket_types for all to service_role
    using (true) with check (true);

-- ----------------------------------------------------------------------------
-- RLS: promo_codes (staff only)
-- ----------------------------------------------------------------------------
alter table promo_codes enable row level security;

create policy "promo_codes_anon_deny_all"
    on promo_codes for all to anon
    using (false);

-- Staff can read codes for their station
create policy "promo_codes_staff_select"
    on promo_codes for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and (p.role = 'super_admin' or p.station_id = promo_codes.station_id)
        )
    );

create policy "promo_codes_service_role_all"
    on promo_codes for all to service_role
    using (true) with check (true);

-- ----------------------------------------------------------------------------
-- RLS: event_registrations (PII)
-- ----------------------------------------------------------------------------
alter table event_registrations enable row level security;

create policy "event_registrations_anon_deny_all"
    on event_registrations for all to anon
    using (false);

-- Staff can read registrations for events in their station
create policy "event_registrations_staff_select"
    on event_registrations for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            join events e on e.station_id = p.station_id
            where p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and e.id = event_registrations.event_id
            and p.role in ('super_admin', 'admin', 'ops', 'volunteer')
        )
    );

-- Donors can see their own registrations
create policy "event_registrations_donor_self_select"
    on event_registrations for select to authenticated
    using (
        deleted_at is null
        and exists (
            select 1 from profiles p
            where p.id = auth.uid()
            and p.donor_id = event_registrations.donor_id
        )
    );

create policy "event_registrations_service_role_all"
    on event_registrations for all to service_role
    using (true) with check (true);

-- ----------------------------------------------------------------------------
-- RLS: event_registration_gifts
-- ----------------------------------------------------------------------------
alter table event_registration_gifts enable row level security;

create policy "event_registration_gifts_anon_deny_all"
    on event_registration_gifts for all to anon
    using (false);

-- Follows registration access
create policy "event_registration_gifts_staff_select"
    on event_registration_gifts for select to authenticated
    using (
        exists (
            select 1 from event_registrations er
            join events e on e.id = er.event_id
            join profiles p on p.station_id = e.station_id
            where er.id = event_registration_gifts.registration_id
            and p.id = auth.uid()
            and p.deleted_at is null
            and p.is_active = true
            and p.role in ('super_admin', 'admin', 'ops', 'volunteer')
        )
    );

create policy "event_registration_gifts_service_role_all"
    on event_registration_gifts for all to service_role
    using (true) with check (true);

-- ----------------------------------------------------------------------------
-- TRIGGERS: updated_at
-- ----------------------------------------------------------------------------
create trigger events_updated_at before update on events
    for each row execute function update_updated_at();
create trigger ticket_types_updated_at before update on ticket_types
    for each row execute function update_updated_at();
create trigger promo_codes_updated_at before update on promo_codes
    for each row execute function update_updated_at();
create trigger event_registrations_updated_at before update on event_registrations
    for each row execute function update_updated_at();

-- ============================================================================
-- End of Phase 006
-- Next: 007_m4_stewardship_tables.sql (Matching + Stewardship)
-- ============================================================================
