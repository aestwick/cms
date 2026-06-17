import type { ComponentProps, ReactNode } from "react";

const fieldBase =
  "w-full border bg-[var(--card)] px-3 py-2 text-[var(--txt)] text-base outline-none transition-colors rounded-[2px] focus:border-kpfk-red";

const fieldStyle = { borderColor: "var(--line)" } as const;

/** Uppercase tracked field label. */
export function Label({
  children,
  htmlFor,
  className = "",
}: {
  children: ReactNode;
  htmlFor?: string;
  className?: string;
}) {
  return (
    <label
      htmlFor={htmlFor}
      className={`mb-1 block text-[12px] font-extrabold uppercase tracking-[0.14em] text-[var(--muted)] ${className}`}
    >
      {children}
    </label>
  );
}

export function Input({ className = "", ...rest }: ComponentProps<"input">) {
  return (
    <input className={`${fieldBase} ${className}`} style={fieldStyle} {...rest} />
  );
}

export function Textarea({
  className = "",
  ...rest
}: ComponentProps<"textarea">) {
  return (
    <textarea
      className={`${fieldBase} ${className}`}
      style={fieldStyle}
      {...rest}
    />
  );
}
