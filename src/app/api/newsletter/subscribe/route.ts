import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { verifyTurnstileToken } from "@/lib/turnstile";
import { NextRequest, NextResponse } from "next/server";

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { email, show_id } = body as {
      email?: string;
      show_id?: string;
    };

    // Validate email
    if (!email || !EMAIL_REGEX.test(email)) {
      return NextResponse.json(
        { error: "A valid email address is required." },
        { status: 400 }
      );
    }

    // Verify Turnstile token if present
    const turnstileToken = req.headers.get("X-Turnstile-Token") ?? undefined;
    const ip = req.headers.get("X-Forwarded-For")?.split(",")[0]?.trim() ?? null;
    const turnstileOk = await verifyTurnstileToken(turnstileToken, ip);
    if (!turnstileOk) {
      return NextResponse.json(
        { error: "Bot verification failed. Please try again." },
        { status: 403 }
      );
    }

    const supabase = getSupabaseAdmin();

    // Get KPFK station_id
    const { data: station } = await supabase
      .from("cms_stations")
      .select("id")
      .limit(1)
      .single();

    if (!station) {
      return NextResponse.json(
        { error: "Station not found." },
        { status: 500 }
      );
    }

    const normalizedEmail = email.toLowerCase().trim();

    // Check if subscriber already exists (including unsubscribed/deleted)
    const { data: existing } = await supabase
      .from("cms_newsletter_subscribers")
      .select("id, unsubscribed_at, deleted_at")
      .eq("station_id", station.id)
      .eq("email", normalizedEmail)
      .limit(1)
      .maybeSingle();

    let subscriberId: string;

    if (existing) {
      if (!existing.unsubscribed_at && !existing.deleted_at) {
        // Already subscribed and active — return success silently
        subscriberId = existing.id;
      } else {
        // Re-subscribe: clear unsubscribed_at and deleted_at
        const { data: updated, error: updateError } = await supabase
          .from("cms_newsletter_subscribers")
          .update({
            unsubscribed_at: null,
            deleted_at: null,
            source: "website",
          })
          .eq("id", existing.id)
          .select("id")
          .single();

        if (updateError) {
          return NextResponse.json(
            { error: "Failed to subscribe. Please try again." },
            { status: 500 }
          );
        }
        subscriberId = updated.id;
      }
    } else {
      // Insert new subscriber
      const { data: inserted, error: insertError } = await supabase
        .from("cms_newsletter_subscribers")
        .insert({
          station_id: station.id,
          email: normalizedEmail,
          source: "website",
        })
        .select("id")
        .single();

      if (insertError) {
        return NextResponse.json(
          { error: "Failed to subscribe. Please try again." },
          { status: 500 }
        );
      }
      subscriberId = inserted.id;
    }

    // If show_id provided, add show-specific subscription
    if (show_id) {
      await supabase
        .from("cms_newsletter_subscriptions")
        .upsert(
          { subscriber_id: subscriberId, show_id },
          { onConflict: "subscriber_id,show_id" }
        );
    }

    return NextResponse.json({ success: true });
  } catch {
    return NextResponse.json(
      { error: "Invalid request." },
      { status: 400 }
    );
  }
}
