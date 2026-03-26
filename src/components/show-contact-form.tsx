"use client";

import { useState, useCallback } from "react";
import { TurnstileWidget } from "@/components/turnstile-widget";

interface ShowContactFormProps {
  showId: string;
  showTitle: string;
}

export function ShowContactForm({ showId, showTitle }: ShowContactFormProps) {
  const [form, setForm] = useState({
    sender_name: "",
    sender_email: "",
    subject: "",
    message: "",
  });
  const [honeypot, setHoneypot] = useState("");
  const [turnstileToken, setTurnstileToken] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState("");

  const handleTurnstileVerify = useCallback((token: string) => {
    setTurnstileToken(token);
  }, []);

  const handleTurnstileExpire = useCallback(() => {
    setTurnstileToken(null);
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();

    // If honeypot is filled, silently "succeed" without submitting
    if (honeypot) {
      setSuccess(true);
      return;
    }

    setSubmitting(true);
    setError("");

    const res = await fetch("/api/contact", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        show_id: showId,
        ...form,
        website_url_confirm: honeypot,
        turnstile_token: turnstileToken,
      }),
    });

    setSubmitting(false);

    if (!res.ok) {
      const data = await res.json();
      setError(data.error || "Something went wrong. Please try again.");
      return;
    }

    setSuccess(true);
  }

  if (success) {
    return (
      <div className="border border-charcoal/10 p-8 text-center">
        <p className="font-serif text-xl font-bold text-charcoal">
          Message sent!
        </p>
        <p className="mt-2 text-base text-charcoal/60">
          Your message has been forwarded to {showTitle}. They&apos;ll respond if
          they can.
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
        <div>
          <label className="block text-base font-medium text-charcoal">
            Name <span className="text-kpfk-red">*</span>
          </label>
          <input
            type="text"
            required
            value={form.sender_name}
            onChange={(e) =>
              setForm((prev) => ({ ...prev, sender_name: e.target.value }))
            }
            className="mt-1.5 block w-full border border-charcoal/20 bg-off-white px-4 py-2.5 text-base focus:border-charcoal focus:outline-none"
          />
        </div>
        <div>
          <label className="block text-base font-medium text-charcoal">
            Email <span className="text-kpfk-red">*</span>
          </label>
          <input
            type="email"
            required
            value={form.sender_email}
            onChange={(e) =>
              setForm((prev) => ({ ...prev, sender_email: e.target.value }))
            }
            className="mt-1.5 block w-full border border-charcoal/20 bg-off-white px-4 py-2.5 text-base focus:border-charcoal focus:outline-none"
          />
        </div>
      </div>
      <div>
        <label className="block text-base font-medium text-charcoal">
          Subject <span className="text-kpfk-red">*</span>
        </label>
        <input
          type="text"
          required
          value={form.subject}
          onChange={(e) =>
            setForm((prev) => ({ ...prev, subject: e.target.value }))
          }
          className="mt-1.5 block w-full border border-charcoal/20 bg-off-white px-4 py-2.5 text-base focus:border-charcoal focus:outline-none"
        />
      </div>
      <div>
        <label className="block text-base font-medium text-charcoal">
          Message <span className="text-kpfk-red">*</span>
        </label>
        <textarea
          required
          rows={6}
          value={form.message}
          onChange={(e) =>
            setForm((prev) => ({ ...prev, message: e.target.value }))
          }
          className="mt-1.5 block w-full border border-charcoal/20 bg-off-white px-4 py-2.5 text-base focus:border-charcoal focus:outline-none"
        />
      </div>

      {/* Honeypot — hidden from real users, filled by bots */}
      <div aria-hidden="true" className="absolute left-[-9999px] top-[-9999px]">
        <label htmlFor="website_url_confirm">Leave this blank</label>
        <input
          type="text"
          id="website_url_confirm"
          name="website_url_confirm"
          tabIndex={-1}
          autoComplete="off"
          value={honeypot}
          onChange={(e) => setHoneypot(e.target.value)}
        />
      </div>

      {/* Cloudflare Turnstile — renders only when NEXT_PUBLIC_TURNSTILE_SITE_KEY is set */}
      <TurnstileWidget
        onVerify={handleTurnstileVerify}
        onExpire={handleTurnstileExpire}
      />

      {error && <p className="text-base text-kpfk-red">{error}</p>}

      <button
        type="submit"
        disabled={submitting}
        className="border-2 border-charcoal bg-charcoal px-7 py-3 text-base font-medium text-off-white hover:bg-charcoal/90 disabled:opacity-50"
      >
        {submitting ? "Sending..." : "Send Message"}
      </button>
    </form>
  );
}
