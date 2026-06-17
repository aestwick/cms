"use client";

import { Button } from "@/components/ds";

/** Triggers the browser print dialog (schedule is print-styled). */
export function PrintButton({ label = "Print / PDF" }: { label?: string }) {
  return (
    <Button variant="secondary" size="sm" onClick={() => window.print()}>
      {label}
    </Button>
  );
}
