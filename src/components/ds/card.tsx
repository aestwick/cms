import type { ReactNode } from "react";

/**
 * Square card: 1px Mist border, no shadow. Themes against the
 * .kpfk-page semantic vars so it flips with dark mode.
 */
export function Card({
  children,
  className = "",
  as: Tag = "div",
}: {
  children: ReactNode;
  className?: string;
  as?: "div" | "article" | "section" | "li";
}) {
  return (
    <Tag
      className={`border ${className}`}
      style={{
        background: "var(--card)",
        borderColor: "var(--line)",
        color: "var(--txt)",
      }}
    >
      {children}
    </Tag>
  );
}
