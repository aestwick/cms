-- 047_drop_redundant_audit_triggers.sql
-- Drop audit triggers on tables where API routes already handle audit logging
-- with correct user attribution (user_id). The triggers use auth.uid() which
-- returns NULL when called from the service role client (used by all admin API
-- routes), causing duplicate "System" entries in the activity log alongside
-- the correctly-attributed API entries.
--
-- Tables affected:
--   gifts          — all mutations go through /api/gifts/* routes
--   gift_variants  — all mutations go through /api/gifts/*/variants/* routes
--   campaigns      — all mutations go through /api/campaigns/* routes
--
-- Tables NOT affected (triggers kept):
--   donations      — Stripe webhooks create/update donations via triggers
--   donors         — Stripe webhooks create/update donors via triggers
--   memberships    — Stripe webhooks manage subscriptions via triggers
--   profiles       — handle_new_user trigger creates profiles
--   fulfillment_items — has specialized trigger with extra logic

DROP TRIGGER IF EXISTS audit_gifts ON gifts;
DROP TRIGGER IF EXISTS audit_gift_variants ON gift_variants;
DROP TRIGGER IF EXISTS audit_campaigns ON campaigns;

-- The audit_trigger_function() itself is NOT dropped — it's still used by
-- the remaining triggers on donations, donors, memberships, etc.

NOTIFY pgrst, 'reload schema';
