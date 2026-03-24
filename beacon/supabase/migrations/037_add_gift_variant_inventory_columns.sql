-- ============================================================================
-- PHASE 037: Add missing inventory columns to gift_variants
-- ============================================================================
-- The gifts management UI and API routes reference three columns that were
-- never added via migration: inventory_incoming, inventory_unavailable, and
-- reorder_point. These track incoming shipments, reserved/damaged stock, and
-- low-stock alert thresholds respectively.
--
-- Run AFTER 036_seed_cdn_gift_images.sql
-- ============================================================================

-- inventory_incoming: units on order / in transit (shown as "+N incoming" badge)
alter table gift_variants
    add column if not exists inventory_incoming integer default 0;

-- inventory_unavailable: reserved, damaged, or otherwise not sellable
alter table gift_variants
    add column if not exists inventory_unavailable integer default 0;

-- reorder_point: low-stock warning triggers at this count
-- replaces the older low_stock_threshold for the new inventory UI
alter table gift_variants
    add column if not exists reorder_point integer default 0;

-- Tell PostgREST to pick up the schema change
NOTIFY pgrst, 'reload schema';
