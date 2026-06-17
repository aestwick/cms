import Link from "next/link";
import type { ComponentProps, ReactNode } from "react";

type Variant = "primary" | "secondary" | "ghost";
type Size = "sm" | "md";

const base =
  "inline-flex items-center justify-center gap-2 font-[var(--font-text)] font-extrabold uppercase tracking-[0.04em] border transition-colors cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed";

const sizes: Record<Size, string> = {
  sm: "px-4 py-2 text-xs",
  md: "px-6 py-3 text-sm",
};

const variants: Record<Variant, string> = {
  primary:
    "bg-kpfk-red border-kpfk-red text-white hover:bg-kpfk-red-press hover:border-kpfk-red-press",
  secondary:
    "bg-transparent border-kpfk-ink text-kpfk-ink hover:bg-kpfk-ink hover:text-kpfk-paper",
  ghost:
    "bg-transparent border-transparent text-kpfk-red hover:text-kpfk-red-press",
};

function classes(variant: Variant, size: Size, className?: string) {
  return [base, sizes[size], variants[variant], className]
    .filter(Boolean)
    .join(" ");
}

type CommonProps = {
  variant?: Variant;
  size?: Size;
  className?: string;
  children: ReactNode;
};

/** Link-styled button (internal href). */
export function ButtonLink({
  href,
  variant = "primary",
  size = "md",
  className,
  children,
  ...rest
}: CommonProps & { href: string } & Omit<
    ComponentProps<typeof Link>,
    "href" | "className"
  >) {
  return (
    <Link href={href} className={classes(variant, size, className)} {...rest}>
      {children}
    </Link>
  );
}

/** Native button. */
export function Button({
  variant = "primary",
  size = "md",
  className,
  children,
  type = "button",
  ...rest
}: CommonProps & ComponentProps<"button">) {
  return (
    <button
      type={type}
      className={classes(variant, size, className)}
      {...rest}
    >
      {children}
    </button>
  );
}
