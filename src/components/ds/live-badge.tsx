/**
 * On-air / off-air status indicator. Pulsing red dot when live.
 */
export function LiveBadge({
  live = true,
  label,
  className = "",
}: {
  live?: boolean;
  label?: string;
  className?: string;
}) {
  const text = label ?? (live ? "On Air" : "Off Air");
  return (
    <span
      className={`inline-flex items-center gap-2 text-[11px] font-extrabold uppercase tracking-[0.14em] ${className}`}
      style={{ color: live ? "var(--kpfk-red)" : "var(--faint, #9a9087)" }}
    >
      <span
        aria-hidden="true"
        className="inline-block h-2 w-2 rounded-full"
        style={{
          background: live ? "var(--kpfk-red)" : "currentColor",
          animation: live ? "kpfk-pulse 1.8s infinite" : "none",
        }}
      />
      {text}
    </span>
  );
}
