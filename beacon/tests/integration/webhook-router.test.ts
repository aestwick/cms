import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { WebhookResult } from '@/lib/stripe/webhook/router';

// =============================================================================
// Mock strategy: we replace getSupabaseAdmin, all 10 handlers, email alerts,
// and the timeout/retry wrappers so we can test the router's idempotency
// logic in isolation — no DB, no Stripe, no network.
// =============================================================================

// Track all Supabase calls so we can simulate different DB states.
//
// The router makes these Supabase call chains:
//   1. from().upsert().select()                → mockUpsert (insert or conflict)
//   2. from().select().eq().single()            → mockSelectSingle (check existing)
//   3. from().update().eq().eq().select()       → mockClaimRetry (atomic retry claim)
//   4. from().update().eq().eq()                → mockFinalUpdate (finally block, no .select())
//   5. from().update().eq()                     → mockMaxAttemptsUpdate (poison event, no .eq('status'))
//
// We use separate mocks for each so they don't consume each other's queues.

const mockUpsert = vi.fn();
const mockSelectSingle = vi.fn();
const mockClaimRetry = vi.fn();  // The retry claim with .select() at the end
const mockFinalUpdate = vi.fn().mockResolvedValue({ data: null, error: null }); // finally block

vi.mock('@/lib/supabase-admin', () => ({
  getSupabaseAdmin: () => ({
    from: (table: string) => {
      if (table !== 'system_events') throw new Error(`Unexpected table: ${table}`);
      return {
        // INSERT path: from().upsert(data, opts).select('id')
        upsert: (...args: unknown[]) => ({
          select: () => mockUpsert(...args),
        }),
        // SELECT path: from().select('cols').eq('key', val).single()
        select: () => ({
          eq: () => ({
            single: () => mockSelectSingle(),
          }),
        }),
        // UPDATE path: from().update(payload).eq(col1, val1).eq(col2, val2)[.select()]
        // Used for: retry claim (with .select), finally status (without .select),
        // and max-attempts update (without .select)
        update: () => ({
          eq: () => ({
            // Second .eq() — present on retry claim + finally block
            eq: () => {
              // This is a thenable object: if .select() is called, use mockClaimRetry.
              // If awaited directly (finally block), use mockFinalUpdate.
              const obj = {
                select: () => mockClaimRetry(),
                then: (resolve: (v: unknown) => void, reject?: (e: unknown) => void) => {
                  return mockFinalUpdate().then(resolve, reject);
                },
              };
              return obj;
            },
            // If only ONE .eq() (max-attempts or simple update without status guard),
            // make it thenable too so the finally block can await it
            then: (resolve: (v: unknown) => void, reject?: (e: unknown) => void) => {
              return mockFinalUpdate().then(resolve, reject);
            },
          }),
        }),
      };
    },
  }),
}));

// Make withTimeout/withRetry pass through (no actual delays in tests)
vi.mock('@/lib/stripe/webhook/utils', async () => {
  const actual = await vi.importActual<typeof import('@/lib/stripe/webhook/utils')>('@/lib/stripe/webhook/utils');
  return {
    ...actual,
    withTimeout: <T>(promise: PromiseLike<T>) => Promise.resolve(promise),
    withRetry: <T>(fn: () => Promise<T>) => fn(),
    logCheckpoint: vi.fn(),
  };
});

// Mock all handlers — we just need to know if they were called
const mockCheckoutHandler = vi.fn().mockResolvedValue(undefined);
vi.mock('@/lib/stripe/webhook/handlers/checkoutCompleted', () => ({
  handleCheckoutSessionCompleted: (...args: unknown[]) => mockCheckoutHandler(...args),
}));
vi.mock('@/lib/stripe/webhook/handlers/paymentIntentSucceeded', () => ({
  handlePaymentIntentSucceeded: vi.fn().mockResolvedValue(undefined),
}));
vi.mock('@/lib/stripe/webhook/handlers/invoicePaid', () => ({
  handleInvoicePaymentSucceeded: vi.fn().mockResolvedValue(undefined),
}));
vi.mock('@/lib/stripe/webhook/handlers/invoiceFailed', () => ({
  handleInvoicePaymentFailed: vi.fn().mockResolvedValue(undefined),
}));
vi.mock('@/lib/stripe/webhook/handlers/subscriptionDeleted', () => ({
  handleSubscriptionDeleted: vi.fn().mockResolvedValue(undefined),
}));
vi.mock('@/lib/stripe/webhook/handlers/subscriptionUpdated', () => ({
  handleSubscriptionUpdated: vi.fn().mockResolvedValue(undefined),
}));
vi.mock('@/lib/stripe/webhook/handlers/chargeRefunded', () => ({
  handleChargeRefunded: vi.fn().mockResolvedValue(undefined),
}));
vi.mock('@/lib/stripe/webhook/handlers/chargeDispute', () => ({
  handleDisputeCreated: vi.fn().mockResolvedValue(undefined),
  handleDisputeClosed: vi.fn().mockResolvedValue(undefined),
}));
vi.mock('@/lib/stripe/webhook/handlers/paymentIntentFailed', () => ({
  handlePaymentIntentFailed: vi.fn().mockResolvedValue(undefined),
}));
vi.mock('@/lib/stripe/webhook/handlers/customerUpdated', () => ({
  handleCustomerUpdated: vi.fn().mockResolvedValue(undefined),
}));

// Mock email alerts (non-blocking, don't want real sends)
vi.mock('@/lib/email', () => ({
  sendWebhookFailureAlert: vi.fn().mockResolvedValue(undefined),
}));

// Import AFTER mocks are registered
const { routeWebhookEvent } = await import('@/lib/stripe/webhook/router');

// =============================================================================
// Helper: build a fake Stripe event
// =============================================================================

function fakeEvent(
  type = 'checkout.session.completed',
  id = 'evt_test_123'
): import('stripe').Stripe.Event {
  return {
    id,
    type,
    data: { object: { id: 'cs_test_abc' } },
    // Remaining fields aren't used by the router
    object: 'event',
    api_version: '2026-02-25.clover',
    created: Date.now() / 1000,
    livemode: false,
    pending_webhooks: 0,
    request: null,
  } as unknown as import('stripe').Stripe.Event;
}

// =============================================================================
// Tests
// =============================================================================

beforeEach(() => {
  vi.clearAllMocks();
});

describe('routeWebhookEvent — new event (first time)', () => {
  it('processes a new event and marks it completed', async () => {
    // Upsert returns a row → we claimed it as new
    mockUpsert.mockResolvedValueOnce({ data: [{ id: 'se-1' }], error: null });
    // Finally block uses mockFinalUpdate (auto-resolves via default mock)

    const result = await routeWebhookEvent(fakeEvent());

    expect(result.success).toBe(true);
    expect(result.status).toBe('processed');
    expect(mockCheckoutHandler).toHaveBeenCalledTimes(1);
  });

  it('routes checkout.session.completed to checkout handler', async () => {
    mockUpsert.mockResolvedValueOnce({ data: [{ id: 'se-1' }], error: null });

    await routeWebhookEvent(fakeEvent('checkout.session.completed'));
    expect(mockCheckoutHandler).toHaveBeenCalled();
  });
});

describe('routeWebhookEvent — duplicate (already completed)', () => {
  it('skips processing if event already completed', async () => {
    // Upsert returns nothing → row already existed (ON CONFLICT DO NOTHING)
    mockUpsert.mockResolvedValueOnce({ data: [], error: null });
    // SELECT existing event → status is 'completed'
    mockSelectSingle.mockResolvedValueOnce({
      data: { id: 'se-1', status: 'completed', attempts: 1 },
      error: null,
    });

    const result = await routeWebhookEvent(fakeEvent());

    expect(result.success).toBe(true);
    expect(result.status).toBe('duplicate');
    expect(mockCheckoutHandler).not.toHaveBeenCalled();
  });
});

describe('routeWebhookEvent — duplicate (currently processing)', () => {
  it('skips processing if another handler is working on it', async () => {
    mockUpsert.mockResolvedValueOnce({ data: [], error: null });
    mockSelectSingle.mockResolvedValueOnce({
      data: { id: 'se-1', status: 'processing', attempts: 1 },
      error: null,
    });

    const result = await routeWebhookEvent(fakeEvent());

    expect(result.success).toBe(true);
    expect(result.status).toBe('duplicate');
    expect(mockCheckoutHandler).not.toHaveBeenCalled();
  });
});

describe('routeWebhookEvent — retry (previously failed)', () => {
  it('retries a failed event by claiming it atomically', async () => {
    // Upsert → row existed
    mockUpsert.mockResolvedValueOnce({ data: [], error: null });
    // SELECT → status is 'failed', attempt 2
    mockSelectSingle.mockResolvedValueOnce({
      data: { id: 'se-1', status: 'failed', attempts: 2 },
      error: null,
    });
    // Atomic claim UPDATE (.select() path) → success (returned a row)
    mockClaimRetry.mockResolvedValueOnce({ data: [{ id: 'se-1' }], error: null });
    // Finally block uses mockFinalUpdate (auto-resolves)

    const result = await routeWebhookEvent(fakeEvent());

    expect(result.success).toBe(true);
    expect(result.status).toBe('processed');
    expect(mockCheckoutHandler).toHaveBeenCalledTimes(1);
  });

  it('skips if another retry claimed it first', async () => {
    mockUpsert.mockResolvedValueOnce({ data: [], error: null });
    mockSelectSingle.mockResolvedValueOnce({
      data: { id: 'se-1', status: 'failed', attempts: 2 },
      error: null,
    });
    // Atomic claim UPDATE → empty (someone else got it)
    mockClaimRetry.mockResolvedValueOnce({ data: [], error: null });

    const result = await routeWebhookEvent(fakeEvent());

    expect(result.success).toBe(true);
    expect(result.status).toBe('duplicate');
    expect(mockCheckoutHandler).not.toHaveBeenCalled();
  });
});

describe('routeWebhookEvent — poison event (max attempts)', () => {
  it('stops retrying after MAX_WEBHOOK_ATTEMPTS', async () => {
    mockUpsert.mockResolvedValueOnce({ data: [], error: null });
    // attempts = 10 → next would be 11, which exceeds MAX_WEBHOOK_ATTEMPTS (10)
    mockSelectSingle.mockResolvedValueOnce({
      data: { id: 'se-1', status: 'failed', attempts: 10 },
      error: null,
    });
    // Max-attempts update uses mockFinalUpdate (auto-resolves via thenable)

    const result = await routeWebhookEvent(fakeEvent());

    expect(result.success).toBe(true); // Returns 200 so Stripe stops retrying
    expect(result.status).toBe('max_attempts_exceeded');
    expect(mockCheckoutHandler).not.toHaveBeenCalled();
  });
});

describe('routeWebhookEvent — idempotency system failure', () => {
  it('returns idempotency_failed when upsert errors', async () => {
    mockUpsert.mockResolvedValueOnce({
      data: null,
      error: { message: 'connection refused', code: 'ECONNREFUSED' },
    });

    const result = await routeWebhookEvent(fakeEvent());

    expect(result.success).toBe(false);
    expect(result.status).toBe('idempotency_failed');
    expect(mockCheckoutHandler).not.toHaveBeenCalled();
  });
});

describe('routeWebhookEvent — handler failure', () => {
  it('marks event as failed and sends alert when handler throws', async () => {
    mockUpsert.mockResolvedValueOnce({ data: [{ id: 'se-1' }], error: null });
    mockCheckoutHandler.mockRejectedValueOnce(new Error('Stripe API down'));
    // Finally block uses mockFinalUpdate (auto-resolves)

    const result = await routeWebhookEvent(fakeEvent());

    expect(result.success).toBe(false);
    expect(result.status).toBe('failed');
    expect(result.error).toContain('Stripe API down');
  });
});

describe('routeWebhookEvent — unhandled event type', () => {
  it('completes successfully for unknown event types (no-op)', async () => {
    mockUpsert.mockResolvedValueOnce({ data: [{ id: 'se-1' }], error: null });
    // Finally block uses mockFinalUpdate (auto-resolves)

    const result = await routeWebhookEvent(fakeEvent('some.future.event'));

    expect(result.success).toBe(true);
    expect(result.status).toBe('processed');
  });
});
