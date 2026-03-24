import { notFound } from "next/navigation";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { ShowContactForm } from "@/components/show-contact-form";
import type { Metadata } from "next";

interface ShowHost {
  id: string;
  name: string;
  bio: string | null;
  photo_path: string | null;
  is_primary: boolean;
}

interface Show {
  id: string;
  station_id: string;
  title: string;
  slug: string;
  tagline: string | null;
  description: string | null;
  history: string | null;
  show_type: string;
  logo_path: string | null;
  banner_path: string | null;
  contact_preference: string;
  contact_email: string | null;
  website_url: string | null;
  rss_url: string | null;
  social_links: Record<string, string>;
  cms_show_hosts: ShowHost[];
}

interface PageProps {
  params: Promise<{ slug: string }>;
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const supabase = getSupabaseAdmin();

  const { data: show } = await supabase
    .from("cms_shows")
    .select("title, tagline")
    .eq("slug", slug)
    .eq("is_active", true)
    .is("deleted_at", null)
    .single();

  if (!show) return { title: "Show Not Found — KPFK 90.7 FM" };

  return {
    title: `${show.title} — KPFK 90.7 FM`,
    description: show.tagline || `Listen to ${show.title} on KPFK 90.7 FM.`,
  };
}

export default async function ShowPage({ params }: PageProps) {
  const { slug } = await params;
  const supabase = getSupabaseAdmin();

  const { data: show } = await supabase
    .from("cms_shows")
    .select("*, cms_show_hosts(*)")
    .eq("slug", slug)
    .eq("is_active", true)
    .is("deleted_at", null)
    .single();

  if (!show) notFound();

  const typedShow = show as Show;
  const hosts = (typedShow.cms_show_hosts ?? []).sort(
    (a, b) => (b.is_primary ? 1 : 0) - (a.is_primary ? 1 : 0)
  );
  const showContact = ["form", "both"].includes(typedShow.contact_preference);
  const showEmail = ["email", "both"].includes(typedShow.contact_preference);
  const socialEntries = Object.entries(typedShow.social_links || {}).filter(
    ([, url]) => url
  );

  // Fetch schedule slots for this show
  const { data: scheduleSlots } = await supabase
    .from("cms_schedule_slots")
    .select("day_of_week, start_time, end_time, label")
    .eq("show_id", typedShow.id)
    .eq("is_recurring", true)
    .order("day_of_week", { ascending: true })
    .order("start_time", { ascending: true });

  const dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

  function formatTime(t: string) {
    const [h, m] = t.split(":");
    const hour = parseInt(h);
    const ampm = hour >= 12 ? "PM" : "AM";
    const h12 = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
    return `${h12}:${m} ${ampm}`;
  }

  return (
    <article className="mx-auto max-w-7xl px-4 py-10 sm:px-6">
      {/* Masthead */}
      <header className="border-b-2 border-charcoal pb-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:gap-6">
          {typedShow.logo_path ? (
            <div className="h-24 w-24 flex-shrink-0 border border-charcoal/10 bg-charcoal/5" />
          ) : (
            <div className="flex h-24 w-24 flex-shrink-0 items-center justify-center border border-charcoal/10 bg-charcoal/5">
              <span className="font-serif text-3xl font-bold text-charcoal/20">
                {typedShow.title.charAt(0)}
              </span>
            </div>
          )}
          <div>
            <span className="font-mono text-xs uppercase text-charcoal/40">
              {typedShow.show_type}
            </span>
            <h1 className="font-serif text-4xl font-bold leading-tight text-charcoal">
              {typedShow.title}
            </h1>
            {typedShow.tagline && (
              <p className="mt-1 text-lg text-charcoal/60">{typedShow.tagline}</p>
            )}
          </div>
        </div>

        {/* Schedule slots */}
        {scheduleSlots && scheduleSlots.length > 0 && (
          <div className="mt-4 flex flex-wrap gap-3">
            {scheduleSlots.map((slot, i) => (
              <span
                key={i}
                className="border border-charcoal/15 px-2.5 py-1 font-mono text-xs text-charcoal/60"
              >
                {dayNames[slot.day_of_week]}s {formatTime(slot.start_time)}–{formatTime(slot.end_time)}
              </span>
            ))}
          </div>
        )}
      </header>

      <div className="mt-8 grid grid-cols-1 gap-10 lg:grid-cols-3">
        {/* Main content */}
        <div className="lg:col-span-2 space-y-10">
          {/* About */}
          {typedShow.description && (
            <section>
              <h2 className="font-serif text-2xl font-bold text-charcoal">About the Show</h2>
              <div
                className="prose mt-4 max-w-none text-charcoal/80"
                dangerouslySetInnerHTML={{ __html: typedShow.description }}
              />
            </section>
          )}

          {/* History */}
          {typedShow.history && (
            <section>
              <h2 className="font-serif text-2xl font-bold text-charcoal">History &amp; Legacy</h2>
              <div
                className="prose mt-4 max-w-none text-charcoal/80"
                dangerouslySetInnerHTML={{ __html: typedShow.history }}
              />
            </section>
          )}

          {/* Episodes placeholder */}
          <section className="border border-charcoal/10 p-6">
            <h2 className="font-serif text-xl font-bold text-charcoal">Recent Episodes</h2>
            <p className="mt-2 text-sm text-charcoal/40">
              Episode archive coming soon — powered by Confessor.
            </p>
          </section>

          {/* Contact form */}
          {showContact && (
            <section>
              <h2 className="font-serif text-2xl font-bold text-charcoal">
                Contact {typedShow.title}
              </h2>
              <div className="mt-4">
                <ShowContactForm showId={typedShow.id} showTitle={typedShow.title} />
              </div>
            </section>
          )}
        </div>

        {/* Sidebar */}
        <aside className="space-y-8">
          {/* Hosts */}
          {hosts.length > 0 && (
            <section className="border border-charcoal/10 p-5">
              <h3 className="text-sm font-bold uppercase tracking-wider text-charcoal/40">
                {hosts.length === 1 ? "Host" : "Hosts"}
              </h3>
              <div className="mt-3 space-y-4">
                {hosts.map((host) => (
                  <div key={host.id}>
                    <div className="flex items-center gap-3">
                      {host.photo_path ? (
                        <div className="h-10 w-10 rounded-full border border-charcoal/10 bg-charcoal/5" />
                      ) : (
                        <div className="flex h-10 w-10 items-center justify-center rounded-full border border-charcoal/10 bg-charcoal/5">
                          <span className="text-sm font-bold text-charcoal/30">
                            {host.name.charAt(0)}
                          </span>
                        </div>
                      )}
                      <div>
                        <p className="text-sm font-medium text-charcoal">{host.name}</p>
                        {host.is_primary && (
                          <span className="font-mono text-[10px] uppercase text-charcoal/30">
                            Primary host
                          </span>
                        )}
                      </div>
                    </div>
                    {host.bio && (
                      <div
                        className="mt-2 text-sm leading-relaxed text-charcoal/60"
                        dangerouslySetInnerHTML={{ __html: host.bio }}
                      />
                    )}
                  </div>
                ))}
              </div>
            </section>
          )}

          {/* Contact email */}
          {showEmail && typedShow.contact_email && (
            <section className="border border-charcoal/10 p-5">
              <h3 className="text-sm font-bold uppercase tracking-wider text-charcoal/40">
                Email
              </h3>
              <a
                href={`mailto:${typedShow.contact_email}`}
                className="mt-2 block text-sm text-kpfk-red hover:text-kpfk-red/80"
              >
                {typedShow.contact_email}
              </a>
            </section>
          )}

          {/* Links */}
          {(typedShow.website_url || typedShow.rss_url || socialEntries.length > 0) && (
            <section className="border border-charcoal/10 p-5">
              <h3 className="text-sm font-bold uppercase tracking-wider text-charcoal/40">
                Links
              </h3>
              <ul className="mt-3 space-y-2 text-sm">
                {typedShow.website_url && (
                  <li>
                    <a
                      href={typedShow.website_url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-kpfk-red hover:text-kpfk-red/80"
                    >
                      Website
                    </a>
                  </li>
                )}
                {typedShow.rss_url && (
                  <li>
                    <a
                      href={typedShow.rss_url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-kpfk-red hover:text-kpfk-red/80"
                    >
                      RSS Feed
                    </a>
                  </li>
                )}
                {socialEntries.map(([platform, url]) => (
                  <li key={platform}>
                    <a
                      href={url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="capitalize text-kpfk-red hover:text-kpfk-red/80"
                    >
                      {platform}
                    </a>
                  </li>
                ))}
              </ul>
            </section>
          )}

          {/* Donate CTA */}
          <section className="border-2 border-kpfk-red p-5 text-center">
            <p className="font-serif text-lg font-bold text-charcoal">
              Support {typedShow.title}
            </p>
            <p className="mt-1 text-sm text-charcoal/60">
              Keep community radio on the air.
            </p>
            <a
              href="https://donate.kpfk.org"
              target="_blank"
              rel="noopener noreferrer"
              className="mt-4 inline-block border-2 border-kpfk-red bg-kpfk-red px-6 py-2 text-sm font-bold text-off-white transition-colors hover:bg-off-white hover:text-kpfk-red"
            >
              Donate Now
            </a>
          </section>
        </aside>
      </div>
    </article>
  );
}
