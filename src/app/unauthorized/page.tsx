import Link from "next/link";

export default function UnauthorizedPage() {
  return (
    <main className="flex min-h-screen items-center justify-center">
      <div className="border border-charcoal p-8 text-center">
        <h1 className="text-2xl font-bold text-charcoal">Unauthorized</h1>
        <p className="mt-2 text-sm text-charcoal/60">
          You don&apos;t have permission to access this page.
        </p>
        <Link
          href="/admin"
          className="mt-4 inline-block text-sm text-kpfk-red underline"
        >
          Back to dashboard
        </Link>
      </div>
    </main>
  );
}
