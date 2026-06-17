"use client";

import { useState, useCallback } from "react";
import { TurnstileWidget } from "@/components/turnstile-widget";
import { Button, Input, Textarea, Label } from "@/components/ds";

interface ShowContactFormProps {
  showId: string;
  showTitle: string;
}

export function ShowContactForm({ showId, showTitle }: ShowContactFormProps) {
  const [open, setOpen] = useState(false);
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
      <div className="border p-8 text-center" style={{ borderColor: "var(--line)" }}>
        <p className="text-xl font-extrabold" style={{ color: "var(--txt)" }}>
          Message sent!
        </p>
        <p className="mt-2 text-base" style={{ color: "var(--muted)" }}>
          Your message has been forwarded to {showTitle}. They&apos;ll respond if
          they can.
        </p>
      </div>
    );
  }

  if (!open) {
    return (
      <Button variant="secondary" onClick={() => setOpen(true)}>
        Contact {showTitle}
      </Button>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
        <div>
          <Label>
            Name <span className="text-kpfk-red">*</span>
          </Label>
          <Input
            type="text"
            required
            value={form.sender_name}
            onChange={(e) =>
              setForm((prev) => ({ ...prev, sender_name: e.target.value }))
            }
          />
        </div>
        <div>
          <Label>
            Email <span className="text-kpfk-red">*</span>
          </Label>
          <Input
            type="email"
            required
            value={form.sender_email}
            onChange={(e) =>
              setForm((prev) => ({ ...prev, sender_email: e.target.value }))
            }
          />
        </div>
      </div>
      <div>
        <Label>
          Subject <span className="text-kpfk-red">*</span>
        </Label>
        <Input
          type="text"
          required
          value={form.subject}
          onChange={(e) =>
            setForm((prev) => ({ ...prev, subject: e.target.value }))
          }
        />
      </div>
      <div>
        <Label>
          Message <span className="text-kpfk-red">*</span>
        </Label>
        <Textarea
          required
          rows={6}
          value={form.message}
          onChange={(e) =>
            setForm((prev) => ({ ...prev, message: e.target.value }))
          }
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

      <Button type="submit" variant="secondary" disabled={submitting}>
        {submitting ? "Sending..." : "Send Message"}
      </Button>
    </form>
  );
}
