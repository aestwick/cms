"use client";

import { Suspense } from "react";
import { LoginForm } from "@/components/login-form";

export default function LoginPage() {
  return (
    <main className="flex min-h-screen items-center justify-center">
      <div className="w-full max-w-sm border border-charcoal p-8">
        <h1 className="text-2xl font-bold text-charcoal">KPFK CMS</h1>
        <p className="mt-1 text-sm text-charcoal/60">Sign in with magic link</p>
        <Suspense fallback={<div className="mt-6 text-sm text-charcoal/40">Loading…</div>}>
          <LoginForm />
        </Suspense>
      </div>
    </main>
  );
}
