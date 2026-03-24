-- ============================================================================
-- PHASE 017: Add Missing Money Invariant Constraints
-- ============================================================================
-- These constraints were present in the original schema design but missing
-- from the applied migrations. They ensure data integrity for monetary values.
--
-- Uses DO blocks to safely add constraints only if they don't already exist.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- From 001_m0_base_tables.sql
-- ----------------------------------------------------------------------------

-- Campaigns money invariant
do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'campaigns_goal_cents_check') then
        alter table campaigns add constraint campaigns_goal_cents_check
            check (goal_cents is null or goal_cents >= 0);
    end if;
end $$;

-- Gifts money invariants
do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'gifts_minimum_cents_check') then
        alter table gifts add constraint gifts_minimum_cents_check check (minimum_cents >= 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'gifts_fmv_cents_check') then
        alter table gifts add constraint gifts_fmv_cents_check check (fmv_cents >= 0);
    end if;
end $$;

-- Membership money invariant
do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'memberships_amount_cents_check') then
        alter table memberships add constraint memberships_amount_cents_check check (amount_cents > 0);
    end if;
end $$;

-- Donation money invariants
do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'donations_amount_cents_check') then
        alter table donations add constraint donations_amount_cents_check check (amount_cents > 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'donations_fee_coverage_cents_check') then
        alter table donations add constraint donations_fee_coverage_cents_check check (fee_coverage_cents >= 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'donations_currency_check') then
        alter table donations add constraint donations_currency_check check (currency = 'usd');
    end if;
end $$;

-- Tax documents money invariants
do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'tax_documents_gross_amount_cents_check') then
        alter table tax_documents add constraint tax_documents_gross_amount_cents_check check (gross_amount_cents > 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'tax_documents_fmv_cents_check') then
        alter table tax_documents add constraint tax_documents_fmv_cents_check check (fmv_cents >= 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'tax_documents_deductible_cents_check') then
        alter table tax_documents add constraint tax_documents_deductible_cents_check check (deductible_cents >= 0);
    end if;
end $$;

-- ----------------------------------------------------------------------------
-- From 002_m0_fks_indexes.sql
-- ----------------------------------------------------------------------------

-- Better audit_log index for user activity queries with pagination
-- Drop old index if exists and create improved version
drop index if exists audit_log_user_id_idx;
create index if not exists audit_log_user_time_idx
    on audit_log(user_id, created_at desc)
    where user_id is not null;

-- ----------------------------------------------------------------------------
-- From 006_m3_events_tables.sql
-- ----------------------------------------------------------------------------

-- Ticket types money invariants
do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'ticket_types_price_cents_check') then
        alter table ticket_types add constraint ticket_types_price_cents_check check (price_cents >= 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ticket_types_fmv_cents_check') then
        alter table ticket_types add constraint ticket_types_fmv_cents_check check (fmv_cents >= 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ticket_types_min_price_cents_check') then
        alter table ticket_types add constraint ticket_types_min_price_cents_check check (min_price_cents is null or min_price_cents >= 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ticket_types_max_price_cents_check') then
        alter table ticket_types add constraint ticket_types_max_price_cents_check check (max_price_cents is null or max_price_cents >= 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ticket_types_suggested_price_cents_check') then
        alter table ticket_types add constraint ticket_types_suggested_price_cents_check check (suggested_price_cents is null or suggested_price_cents >= 0);
    end if;
end $$;

-- Promo codes money invariants
do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'promo_codes_discount_cents_check') then
        alter table promo_codes add constraint promo_codes_discount_cents_check check (discount_cents is null or discount_cents >= 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'promo_codes_min_purchase_cents_check') then
        alter table promo_codes add constraint promo_codes_min_purchase_cents_check check (min_purchase_cents is null or min_purchase_cents >= 0);
    end if;
end $$;

-- Event registrations money invariants
do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'event_registrations_unit_price_cents_check') then
        alter table event_registrations add constraint event_registrations_unit_price_cents_check check (unit_price_cents >= 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'event_registrations_total_cents_check') then
        alter table event_registrations add constraint event_registrations_total_cents_check check (total_cents >= 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'event_registrations_discount_cents_check') then
        alter table event_registrations add constraint event_registrations_discount_cents_check check (discount_cents >= 0);
    end if;
end $$;

-- ----------------------------------------------------------------------------
-- From 007_m4_stewardship_tables.sql
-- ----------------------------------------------------------------------------

-- Match pools money invariants
do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'match_pools_total_cents_check') then
        alter table match_pools add constraint match_pools_total_cents_check check (total_cents > 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'match_pools_remaining_cents_check') then
        alter table match_pools add constraint match_pools_remaining_cents_check check (remaining_cents >= 0);
    end if;
end $$;

-- Match allocations money invariant
do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'match_allocations_amount_cents_check') then
        alter table match_allocations add constraint match_allocations_amount_cents_check check (amount_cents > 0);
    end if;
end $$;

-- ============================================================================
-- End of Phase 017
-- ============================================================================
