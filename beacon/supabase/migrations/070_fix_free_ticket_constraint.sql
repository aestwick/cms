-- Fix: Allow free tickets (price_cents = 0) for non-PWYC ticket types.
-- The original constraint in migration 052 required price_cents > 0,
-- which prevented creating complimentary/free ticket tiers.
-- Changed to price_cents >= 0.

ALTER TABLE ticket_types DROP CONSTRAINT IF EXISTS ticket_types_price_check;

ALTER TABLE ticket_types ADD CONSTRAINT ticket_types_price_check CHECK (
    (is_pwyc = true AND price_cents IS NULL AND min_price_cents IS NOT NULL)
    OR (is_pwyc = false AND price_cents IS NOT NULL AND price_cents >= 0)
);

NOTIFY pgrst, 'reload schema';
