import { resolveImageUrl } from "@/lib/format";
import type { Block } from "@/lib/blocks";

// Renders a Story/Episode block body to the design system. Styling uses the
// shared semantic theme vars (--txt, --muted, --line, --kpfk-red, voice
// tints) so it themes light/dark with the rest of the suite. Server-safe.

const LABEL =
  "text-xs font-extrabold uppercase tracking-[0.14em]";

function Subhead({ text, level }: { text: string; level: 2 | 3 }) {
  const Tag = level === 3 ? "h3" : "h2";
  return (
    <Tag
      className="kpfk-display mt-8 mb-3 uppercase"
      style={{ color: "var(--txt)", fontSize: level === 3 ? 20 : 26, lineHeight: 1 }}
    >
      {text}
    </Tag>
  );
}

export function BlockRenderer({ blocks }: { blocks: Block[] }) {
  if (!blocks.length) return null;
  return (
    <div className="space-y-4">
      {blocks.map((b) => {
        switch (b.type) {
          case "text":
            return (
              <div
                key={b.id}
                className="kpfk-prose text-lg leading-relaxed"
                style={{ color: "var(--txt)" }}
                dangerouslySetInnerHTML={{ __html: b.html }}
              />
            );

          case "subhead":
            return <Subhead key={b.id} text={b.text} level={b.level} />;

          case "key_takeaways":
            return (
              <aside key={b.id} className="my-6 border p-5" style={{ borderColor: "var(--line)", background: "var(--card)" }}>
                <div className={LABEL} style={{ color: "var(--kpfk-red)" }}>Key takeaways</div>
                <ul className="mt-3 space-y-2">
                  {b.items.map((it, i) => (
                    <li key={i} className="flex gap-2 text-base leading-snug" style={{ color: "var(--txt)" }}>
                      <span style={{ color: "var(--kpfk-red)" }}>—</span>
                      <span>{it}</span>
                    </li>
                  ))}
                </ul>
              </aside>
            );

          case "pull_quote":
            return (
              <blockquote key={b.id} className="my-8 border-l-4 pl-6" style={{ borderColor: "var(--kpfk-red)" }}>
                <p className="kpfk-display text-3xl leading-tight" style={{ color: "var(--txt)" }}>
                  {b.quote}
                </p>
                {b.attribution && (
                  <cite className="mt-3 block text-sm not-italic" style={{ color: "var(--muted)" }}>
                    — {b.attribution}
                  </cite>
                )}
              </blockquote>
            );

          case "take_action":
            return (
              <div key={b.id} className="my-6 border-2 p-6" style={{ borderColor: "var(--kpfk-red)", background: "var(--live-bg)" }}>
                <div className={LABEL} style={{ color: "var(--kpfk-red)" }}>Take action</div>
                <h3 className="mt-2 text-xl font-bold" style={{ color: "var(--txt)" }}>{b.heading}</h3>
                {b.body && <p className="mt-2 text-base" style={{ color: "var(--muted)" }}>{b.body}</p>}
                {b.cta_url && (
                  <a href={b.cta_url} className="mt-4 inline-block bg-kpfk-red px-5 py-2.5 text-sm font-extrabold uppercase tracking-[0.04em] text-white">
                    {b.cta_label || "Take action"} →
                  </a>
                )}
              </div>
            );

          case "correction":
            return (
              <div key={b.id} className="my-6 border p-4" style={{ borderColor: "var(--line)", background: "var(--card)" }}>
                <div className={LABEL} style={{ color: "var(--muted)" }}>
                  Correction{b.dated_at ? ` · ${b.dated_at}` : ""}
                </div>
                <p className="mt-2 text-sm" style={{ color: "var(--txt)" }}>{b.text}</p>
              </div>
            );

          case "lee_en_espanol":
            return (
              <a key={b.id} href={b.url || "#"} className="my-4 inline-flex items-center gap-2 border px-4 py-2 text-sm font-semibold" style={{ borderColor: "var(--line)", color: "var(--txt)" }}>
                🌐 {b.text || "Lee en español"} →
              </a>
            );

          case "links_resources":
            return (
              <div key={b.id} className="my-6 border p-5" style={{ borderColor: "var(--line)" }}>
                <div className={LABEL} style={{ color: "var(--kpfk-red)" }}>Links &amp; resources</div>
                <ul className="mt-3 space-y-2">
                  {b.items.map((l, i) => (
                    <li key={i}>
                      <a href={l.url} className="text-base underline" style={{ color: "var(--txt)" }}>{l.label || l.url}</a>
                    </li>
                  ))}
                </ul>
              </div>
            );

          case "audio_clip":
            return (
              <div key={b.id} className="my-6 border p-4" style={{ borderColor: "var(--line)", background: "var(--card)" }}>
                <div className={LABEL} style={{ color: "var(--kpfk-red)" }}>{b.label || "Audio clip"}</div>
                {b.src && <audio controls preload="none" src={resolveImageUrl(b.src)} className="mt-3 w-full" />}
              </div>
            );

          case "tracklist":
            return (
              <div key={b.id} className="my-6 border" style={{ borderColor: "var(--line)" }}>
                <div className={`${LABEL} border-b p-3`} style={{ color: "var(--kpfk-red)", borderColor: "var(--line)" }}>Tracklist</div>
                <ul>
                  {b.items.map((t, i) => (
                    <li key={i} className="flex items-baseline gap-3 border-b px-4 py-2.5 text-sm last:border-0" style={{ borderColor: "var(--hair)" }}>
                      {t.time && <span className="font-mono text-xs" style={{ color: "var(--faint)" }}>{t.time}</span>}
                      <span className="font-semibold" style={{ color: "var(--txt)" }}>{t.title}</span>
                      {t.artist && <span style={{ color: "var(--muted)" }}>· {t.artist}</span>}
                      {t.label && <span className="ml-auto text-xs" style={{ color: "var(--faint)" }}>{t.label}</span>}
                    </li>
                  ))}
                </ul>
              </div>
            );

          case "guest_card":
            return (
              <div key={b.id} className="my-6 flex gap-4 border p-5" style={{ borderColor: "var(--line)", background: "var(--card)" }}>
                {b.image_path && (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={resolveImageUrl(b.image_path)} alt={b.name} className="h-20 w-20 flex-shrink-0 object-cover" />
                )}
                <div>
                  <div className={LABEL} style={{ color: "var(--kpfk-red)" }}>Guest</div>
                  <div className="mt-1 text-lg font-bold" style={{ color: "var(--txt)" }}>{b.name}</div>
                  {b.role && <div className="text-sm" style={{ color: "var(--muted)" }}>{b.role}</div>}
                  {b.bio && <p className="mt-2 text-sm" style={{ color: "var(--txt)" }}>{b.bio}</p>}
                  {b.link_url && <a href={b.link_url} className="mt-2 inline-block text-sm underline" style={{ color: "var(--kpfk-red)" }}>More →</a>}
                </div>
              </div>
            );

          case "data_table":
            return (
              <figure key={b.id} className="my-6 overflow-x-auto">
                <table className="w-full border-collapse text-sm" style={{ color: "var(--txt)" }}>
                  {b.columns.length > 0 && (
                    <thead>
                      <tr>
                        {b.columns.map((c, i) => (
                          <th key={i} className="border p-2 text-left font-bold" style={{ borderColor: "var(--line)" }}>{c}</th>
                        ))}
                      </tr>
                    </thead>
                  )}
                  <tbody>
                    {b.rows.map((row, ri) => (
                      <tr key={ri}>
                        {row.map((cell, ci) => (
                          <td key={ci} className="border p-2" style={{ borderColor: "var(--hair)" }}>{cell}</td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
                {b.caption && <figcaption className="mt-2 text-xs" style={{ color: "var(--faint)" }}>{b.caption}</figcaption>}
              </figure>
            );

          case "image":
            return (
              <figure key={b.id} className="my-6">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={resolveImageUrl(b.image_path)} alt={b.alt || ""} className="w-full border" style={{ borderColor: "var(--line)" }} />
                {b.caption && <figcaption className="mt-2 text-xs" style={{ color: "var(--faint)" }}>{b.caption}</figcaption>}
              </figure>
            );

          case "gallery":
            return (
              <div key={b.id} className="my-6 grid grid-cols-2 gap-2 sm:grid-cols-3">
                {b.images.map((img, i) => (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img key={i} src={resolveImageUrl(img.image_path)} alt={img.alt || ""} className="aspect-square w-full border object-cover" style={{ borderColor: "var(--line)" }} />
                ))}
              </div>
            );

          case "video_embed":
            return (
              <figure key={b.id} className="my-6">
                <div className="relative w-full" style={{ aspectRatio: "16 / 9" }}>
                  <iframe src={b.url} title={b.caption || "Video"} className="absolute inset-0 h-full w-full border" style={{ borderColor: "var(--line)" }} allowFullScreen />
                </div>
                {b.caption && <figcaption className="mt-2 text-xs" style={{ color: "var(--faint)" }}>{b.caption}</figcaption>}
              </figure>
            );

          case "event_card":
            return (
              <a key={b.id} href={b.url || "#"} className="my-6 flex items-center gap-4 border p-4" style={{ borderColor: "var(--line)", background: "var(--card)" }}>
                {b.image_path && (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={resolveImageUrl(b.image_path)} alt={b.title} className="h-16 w-16 flex-shrink-0 object-cover" />
                )}
                <div>
                  <div className={LABEL} style={{ color: "var(--kpfk-red)" }}>Event</div>
                  <div className="mt-1 font-bold" style={{ color: "var(--txt)" }}>{b.title}</div>
                  <div className="text-sm" style={{ color: "var(--muted)" }}>
                    {[b.starts_at, b.venue].filter(Boolean).join(" · ")}
                  </div>
                </div>
              </a>
            );

          default:
            return null;
        }
      })}
    </div>
  );
}
