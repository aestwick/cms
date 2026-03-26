import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { headers } from "next/headers";

// POST /api/contact — public contact form submission
export async function POST(request: NextRequest) {
  const body = await request.json();

  const { show_id, sender_name, sender_email, subject, message, website_url_confirm } = body;

  // Honeypot check — if filled, silently accept (bots think it succeeded)
  if (website_url_confirm) {
    return NextResponse.json({ success: true }, { status: 201 });
  }

  // Basic validation
  if (!sender_name || !sender_email || !subject || !message) {
    return NextResponse.json(
      { error: "All fields are required." },
      { status: 400 }
    );
  }

  if (sender_name.length > 200 || subject.length > 500 || message.length > 5000) {
    return NextResponse.json(
      { error: "Input exceeds maximum length." },
      { status: 400 }
    );
  }

  // Basic email validation
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(sender_email)) {
    return NextResponse.json(
      { error: "Invalid email address." },
      { status: 400 }
    );
  }

  // TODO: Validate Turnstile token when TURNSTILE_SECRET_KEY is configured
  // const turnstileToken = body.turnstile_token;
  // if (process.env.TURNSTILE_SECRET_KEY) { ... verify ... }

  const supabase = getSupabaseAdmin();

  // Look up the station (KPFK)
  const { data: station } = await supabase
    .from("cms_stations")
    .select("id")
    .single();

  if (!station) {
    return NextResponse.json(
      { error: "Station not configured." },
      { status: 500 }
    );
  }

  // If show_id provided, verify it exists and get contact email
  let emailTo: string[] = [];
  if (show_id) {
    const { data: show } = await supabase
      .from("cms_shows")
      .select("id, contact_preference, contact_email, cms_show_hosts(email)")
      .eq("id", show_id)
      .eq("is_active", true)
      .is("deleted_at", null)
      .single();

    if (!show) {
      return NextResponse.json(
        { error: "Show not found." },
        { status: 404 }
      );
    }

    // Determine who to email
    if (show.contact_email) {
      emailTo.push(show.contact_email);
    }
    // Fall back to primary host email
    if (emailTo.length === 0 && show.cms_show_hosts) {
      const hostEmails = (show.cms_show_hosts as { email: string | null }[])
        .map((h) => h.email)
        .filter(Boolean) as string[];
      emailTo.push(...hostEmails);
    }
  }

  // Get client IP
  const headersList = await headers();
  const forwarded = headersList.get("x-forwarded-for");
  const ip = forwarded ? forwarded.split(",")[0].trim() : null;

  // Store submission
  const { error: insertError } = await supabase
    .from("cms_contact_submissions")
    .insert({
      station_id: station.id,
      show_id: show_id || null,
      sender_name,
      sender_email,
      subject,
      message,
      ip_address: ip,
      emailed_to: emailTo,
    });

  if (insertError) {
    return NextResponse.json(
      { error: "Failed to submit message." },
      { status: 500 }
    );
  }

  // TODO: Send email via Resend when RESEND_API_KEY is configured
  // if (emailTo.length > 0 && process.env.RESEND_API_KEY) { ... }

  return NextResponse.json({ success: true }, { status: 201 });
}
