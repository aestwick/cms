"use client";

import { createBrowserClient } from "@supabase/ssr";
import { useState } from "react";
import { useSearchParams } from "next/navigation";
import { Button, Input, Label } from "@/components/ds";

export function LoginForm() {
  const [email, setEmail] = useState("");
  const [sent, setSent] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const searchParams = useSearchParams();
  const redirectTo = searchParams.get("redirect") || "/admin";

  const supabase = createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);

    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: `${window.location.origin}/auth/callback?redirect=${encodeURIComponent(redirectTo)}`,
      },
    });

    setLoading(false);

    if (error) {
      setError(error.message);
    } else {
      setSent(true);
    }
  }

  if (sent) {
    return (
      <div className="mt-6">
        <p className="text-sm text-charcoal">
          Check your email for a sign-in link. You can close this tab.
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="mt-6 space-y-4">
      <div>
        <Label htmlFor="email">Email</Label>
        <Input
          id="email"
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="you@kpfk.org"
        />
      </div>

      {error && <p className="text-sm text-kpfk-red">{error}</p>}

      <Button type="submit" variant="secondary" disabled={loading} className="w-full">
        {loading ? "Sending…" : "Send magic link"}
      </Button>
    </form>
  );
}
