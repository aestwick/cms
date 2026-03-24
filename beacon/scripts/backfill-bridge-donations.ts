#!/usr/bin/env npx tsx
// Backfill bridge donations for existing paid event orders.
//
// Run once after deploying migration 071 and the bridge donation code.
// Creates a donations row (source_type='event') for each paid event order
// that doesn't already have one.
//
// Safe to run multiple times — checks for existing bridge donations first,
// and the unique index on event_order_id prevents duplicates.
//
// Usage:
//   npx tsx scripts/backfill-bridge-donations.ts
//   DRY_RUN=1 npx tsx scripts/backfill-bridge-donations.ts   # preview only

import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const DRY_RUN = process.env.DRY_RUN === '1';

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function main() {
  console.log(DRY_RUN ? '=== DRY RUN MODE ===' : '=== LIVE MODE ===');
  console.log('');

  // Find all completed/partially_refunded event orders with total > 0
  // that don't already have a bridge donation
  const { data: orders, error } = await (supabase
    .from('event_orders' as any) as any)
    .select('id, station_id, donor_id, event_id, order_number, total_cents, payment_provider, stripe_payment_intent_id, source_type, status, created_at')
    .in('status', ['completed', 'partially_refunded'])
    .gt('total_cents', 0);

  if (error) {
    console.error('Failed to fetch event orders:', error);
    process.exit(1);
  }

  if (!orders || orders.length === 0) {
    console.log('No paid event orders found.');
    return;
  }

  console.log(`Found ${orders.length} paid event orders.`);

  // Check which already have bridge donations
  const orderIds = orders.map((o: any) => o.id);
  const { data: existing } = await supabase
    .from('donations')
    .select('event_order_id')
    .in('event_order_id', orderIds)
    .eq('source_type', 'event');

  const existingSet = new Set((existing || []).map((d: any) => d.event_order_id));
  const toCreate = orders.filter((o: any) => !existingSet.has(o.id));

  console.log(`${existingSet.size} already have bridge donations.`);
  console.log(`${toCreate.length} need bridge donations.`);
  console.log('');

  if (toCreate.length === 0) {
    console.log('Nothing to do!');
    return;
  }

  // Load event titles and FMV data for context
  const eventIds = [...new Set(toCreate.map((o: any) => o.event_id))];
  const { data: events } = await (supabase
    .from('events' as any) as any)
    .select('id, title, campaign_id');

  const eventMap = new Map<string, { title: string; campaign_id: string | null }>();
  if (events) {
    for (const e of events as any[]) {
      eventMap.set(e.id, { title: e.title, campaign_id: e.campaign_id });
    }
  }

  // Load order items to calculate FMV per order
  // FMV = sum of (fmv_cents × quantity) for each order item
  const { data: orderItems } = await (supabase
    .from('event_order_items' as any) as any)
    .select('order_id, fmv_cents, quantity')
    .in('order_id', toCreate.map((o: any) => o.id));

  const fmvByOrder = new Map<string, number>();
  if (orderItems) {
    for (const item of orderItems as any[]) {
      const current = fmvByOrder.get(item.order_id) || 0;
      fmvByOrder.set(item.order_id, current + (item.fmv_cents || 0) * (item.quantity || 1));
    }
  }

  // Create bridge donations
  let created = 0;
  let skipped = 0;
  let failed = 0;

  for (const order of toCreate) {
    const event = eventMap.get(order.event_id);
    const fmvCents = fmvByOrder.get(order.id) || 0;
    const deductibleCents = Math.max(0, order.total_cents - fmvCents);

    if (DRY_RUN) {
      console.log(`  [DRY] Would create bridge for order ${order.order_number}: $${(order.total_cents / 100).toFixed(2)} (FMV: $${(fmvCents / 100).toFixed(2)}, deductible: $${(deductibleCents / 100).toFixed(2)}) — ${event?.title || 'Unknown'}`);
      created++;
      continue;
    }

    const { error: insertError } = await supabase
      .from('donations')
      .insert({
        station_id: order.station_id,
        donor_id: order.donor_id,
        amount_cents: order.total_cents,
        fmv_cents: fmvCents,
        currency: 'usd',
        status: 'succeeded',
        payment_provider: order.payment_provider,
        stripe_payment_intent_id: order.stripe_payment_intent_id || null,
        source_type: 'event',
        event_order_id: order.id,
        campaign_id: event?.campaign_id || null,
        is_anonymous: false,
        donation_type: 'one_time',
        received_at: order.created_at,
        private_note: `Event ticket revenue: ${event?.title || 'Unknown'} (order ${order.order_number}). Deductible: ${deductibleCents} cents. [backfill]`,
      } as any);

    if (insertError) {
      if (insertError.code === '23505') {
        // Duplicate — already exists (race condition or re-run)
        skipped++;
      } else {
        console.error(`  [FAIL] Order ${order.order_number}:`, insertError.message);
        failed++;
      }
    } else {
      console.log(`  [OK] Order ${order.order_number}: $${(order.total_cents / 100).toFixed(2)} — ${event?.title || 'Unknown'}`);
      created++;
    }
  }

  console.log('');
  console.log('=== Summary ===');
  console.log(`Created: ${created}`);
  console.log(`Skipped (already exist): ${skipped}`);
  console.log(`Failed: ${failed}`);
}

main().catch((err) => {
  console.error('Backfill failed:', err);
  process.exit(1);
});
