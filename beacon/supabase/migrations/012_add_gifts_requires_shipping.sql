-- ============================================================================
-- MIGRATION 012: Add requires_shipping to gifts table
-- ============================================================================
-- Adds a column to track whether a gift requires physical fulfillment.
-- This enables automatic creation of fulfillment_items when donations succeed.
-- ============================================================================

-- Add requires_shipping column (default true for physical goods)
alter table gifts
    add column if not exists requires_shipping boolean not null default true;

-- Add static_id column to map to static gift catalog IDs (e.g., 'bumper-90')
-- This allows us to link database gifts to the static KPFK_GIFTS array
alter table gifts
    add column if not exists static_id text unique;

-- Add index for static_id lookups
create index if not exists idx_gifts_static_id on gifts(static_id) where static_id is not null;

-- Comment explaining the columns
comment on column gifts.requires_shipping is 'Whether this gift requires physical shipping/fulfillment. False for digital goods or events.';
comment on column gifts.static_id is 'Maps to static gift catalog ID (e.g., bumper-90). Used to link form submissions to database records.';

-- ============================================================================
-- End of Migration 012
-- ============================================================================
