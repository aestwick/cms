-- Fix cross-product bug in v_event_sales_summary and v_ticket_type_sales
--
-- Both views independently JOIN event_orders and event_tickets to the parent
-- table, producing a Cartesian product that inflates revenue (multiplied by
-- ticket count) and ticket counts (multiplied by order count).
--
-- Fix: aggregate orders and tickets in separate lateral subqueries so each
-- dimension is counted exactly once.

-- ============================================================================
-- v_event_sales_summary — event-level totals
-- ============================================================================
CREATE OR REPLACE VIEW v_event_sales_summary AS
SELECT
    e.id AS event_id,
    e.title,
    e.starts_at,
    e.status,
    COALESCE(o.total_orders, 0) AS total_orders,
    COALESCE(t.total_tickets, 0) AS total_tickets,
    COALESCE(t.checked_in_count, 0) AS checked_in_count,
    COALESCE(o.total_revenue_cents, 0) AS total_revenue_cents,
    COALESCE(o.total_donation_cents, 0) AS total_donation_cents,
    COALESCE(o.web_orders, 0) AS web_orders,
    COALESCE(o.walk_in_orders, 0) AS walk_in_orders,
    COALESCE(o.phone_orders, 0) AS phone_orders
FROM events e
LEFT JOIN LATERAL (
    SELECT
        COUNT(*)                                                    AS total_orders,
        COALESCE(SUM(eo.total_cents), 0)                           AS total_revenue_cents,
        COALESCE(SUM(eo.donation_cents), 0)                        AS total_donation_cents,
        COUNT(*) FILTER (WHERE eo.source_type = 'web')             AS web_orders,
        COUNT(*) FILTER (WHERE eo.source_type = 'walk_in')         AS walk_in_orders,
        COUNT(*) FILTER (WHERE eo.source_type = 'phone')           AS phone_orders
    FROM event_orders eo
    WHERE eo.event_id = e.id
      AND eo.status IN ('completed', 'partially_refunded')
) o ON true
LEFT JOIN LATERAL (
    SELECT
        COUNT(*)                                                    AS total_tickets,
        COUNT(*) FILTER (WHERE et.checked_in_at IS NOT NULL)       AS checked_in_count
    FROM event_tickets et
    WHERE et.event_id = e.id
      AND et.status = 'active'
) t ON true
WHERE e.deleted_at IS NULL;

-- ============================================================================
-- v_ticket_type_sales — per-ticket-type breakdown
-- ============================================================================
CREATE OR REPLACE VIEW v_ticket_type_sales AS
SELECT
    tt.id AS ticket_type_id,
    tt.event_id,
    tt.name,
    tt.price_cents,
    tt.capacity,
    tt.sold_count,
    CASE
        WHEN tt.capacity IS NOT NULL AND tt.capacity > 0
        THEN ROUND((tt.sold_count::numeric / tt.capacity) * 100, 1)
        ELSE NULL
    END AS percent_sold,
    COALESCE(r.revenue_cents, 0) AS revenue_cents,
    COALESCE(c.checked_in_count, 0) AS checked_in_count
FROM ticket_types tt
LEFT JOIN LATERAL (
    SELECT COALESCE(SUM(eoi.unit_price_cents * eoi.quantity), 0) AS revenue_cents
    FROM event_order_items eoi
    JOIN event_orders eo ON eo.id = eoi.order_id
      AND eo.status IN ('completed', 'partially_refunded')
    WHERE eoi.ticket_type_id = tt.id
) r ON true
LEFT JOIN LATERAL (
    SELECT COUNT(*) FILTER (WHERE et.checked_in_at IS NOT NULL) AS checked_in_count
    FROM event_tickets et
    WHERE et.ticket_type_id = tt.id
      AND et.status = 'active'
) c ON true
WHERE tt.deleted_at IS NULL;
