"use client";

import { useState } from "react";

export default function NewsletterSignup() {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
  const [message, setMessage] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!email) return;

    setStatus("loading");
    try {
      const res = await fetch("/api/newsletter/subscribe", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });

      if (res.ok) {
        setStatus("success");
        setMessage("You're subscribed. Welcome to the KPFK community.");
        setEmail("");
      } else {
        const data = await res.json().catch(() => ({}));
        setStatus("error");
        setMessage(data.error || "Something went wrong. Please try again.");
      }
    } catch {
      setStatus("error");
      setMessage("Network error. Please try again.");
    }
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4 sm:flex-row sm:items-end sm:gap-3">
      <div className="flex-1">
        <label htmlFor="newsletter-email" className="block font-mono text-xs uppercase tracking-wide text-charcoal/60">
          Email address
        </label>
        <input
          id="newsletter-email"
          type="email"
          required
          value={email}
          onChange={(e) => {
            setEmail(e.target.value);
            if (status !== "idle") setStatus("idle");
          }}
          placeholder="you@example.com"
          className="mt-1.5 w-full border-2 border-charcoal bg-off-white px-4 py-3 text-base text-charcoal placeholder:text-charcoal/30 focus:outline-none focus:ring-2 focus:ring-action-yellow"
        />
      </div>
      <button
        type="submit"
        disabled={status === "loading"}
        className="border-2 border-charcoal bg-action-yellow px-8 py-3 font-bold text-charcoal transition-colors hover:bg-charcoal hover:text-action-yellow disabled:opacity-50"
      >
        {status === "loading" ? "Subscribing..." : "Subscribe"}
      </button>
      {status === "success" && (
        <p className="text-sm font-medium text-green-700 sm:self-center">{message}</p>
      )}
      {status === "error" && (
        <p className="text-sm font-medium text-kpfk-red sm:self-center">{message}</p>
      )}
    </form>
  );
}
