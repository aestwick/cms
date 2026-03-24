"use client";

import { useState } from "react";

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
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError("");

    const res = await fetch("/api/contact", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        show_id: showId,
        ...form,
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
      <div className="border border-charcoal/10 p-6 text-center">
        <p className="font-serif text-lg font-bold text-charcoal">
          Message sent!
        </p>
        <p className="mt-1 text-sm text-charcoal/60">
          Your message has been forwarded to {showTitle}. They&apos;ll respond if
          they can.
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <label className="block text-sm font-medium text-charcoal">
            Name <span className="text-kpfk-red">*</span>
          </label>
          <input
            type="text"
            required
            value={form.sender_name}
            onChange={(e) =>
              setForm((prev) => ({ ...prev, sender_name: e.target.value }))
            }
            className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-charcoal">
            Email <span className="text-kpfk-red">*</span>
          </label>
          <input
            type="email"
            required
            value={form.sender_email}
            onChange={(e) =>
              setForm((prev) => ({ ...prev, sender_email: e.target.value }))
            }
            className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
          />
        </div>
      </div>
      <div>
        <label className="block text-sm font-medium text-charcoal">
          Subject <span className="text-kpfk-red">*</span>
        </label>
        <input
          type="text"
          required
          value={form.subject}
          onChange={(e) =>
            setForm((prev) => ({ ...prev, subject: e.target.value }))
          }
          className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-charcoal">
          Message <span className="text-kpfk-red">*</span>
        </label>
        <textarea
          required
          rows={5}
          value={form.message}
          onChange={(e) =>
            setForm((prev) => ({ ...prev, message: e.target.value }))
          }
          className="mt-1 block w-full border border-charcoal/20 bg-off-white px-3 py-2 text-sm focus:border-charcoal focus:outline-none"
        />
      </div>

      {/* Turnstile widget placeholder — requires NEXT_PUBLIC_TURNSTILE_SITE_KEY */}
      <div id="turnstile-widget" />

      {error && <p className="text-sm text-kpfk-red">{error}</p>}

      <button
        type="submit"
        disabled={submitting}
        className="border-2 border-charcoal bg-charcoal px-6 py-2 text-sm font-medium text-off-white hover:bg-charcoal/90 disabled:opacity-50"
      >
        {submitting ? "Sending..." : "Send Message"}
      </button>
    </form>
  );
}
