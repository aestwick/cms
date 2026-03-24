# KPFK CMS — Claude Code Build Instructions

**Date:** 2026-03-24
**Author:** Ace Estwick
**Status:** Ready to build

---

## What You're Building

A Next.js CMS that serves as the public face of kpfk.org. It orchestrates content from three systems:

1. **Its own database** (Supabase) — show pages, blog posts, pages, events, media, sponsorship, newsletter
2. **Beacon** (external API) — donations, ticketed events, campaigns, membership status
3. **Confessor** (external API) — broadcast schedule, now playing, episode audio/archives

The CMS never handles money (that's Beacon) and never stores audio files (that's Confessor). It's the presentation and content management layer.

---

## Repo Structure

```
kpfk-cms/
├── CLAUDE_CODE_INSTRUCTIONS.md    ← You are here
├── docs/
│   ├── kpfk_cms_spec_v1.md        ← Full platform spec (architecture, integrations, data ownership)
│   ├── kpfk_cms_schema_spec_v1.md  ← Database schema design (18 tables, all cms_ prefixed)
│   ├── kpfk_cms_uiux_handoff.md   ← UI/UX decisions, host experience, design direction
│   ├── design_direction.md         ← Design comps, palette, typography, pushback notes
│   ├── beacon_api_contract.md      ← Beacon endpoints the CMS consumes (read-only)
│   └── aiir_show_template_v2.2.html ← Reference: current show page HTML template being replaced
├── supabase/
│   └── migrations/                 ← Sequential SQL migrations (001_, 002_, etc.)
├── src/
│   ├── app/                        ← Next.js App Router pages
│   ├── components/                 ← React components
│   ├── lib/                        ← Shared utilities, API clients, auth helpers
│   └── styles/                     ← Tailwind config, global styles
├── public/                         ← Static assets
├── docker-compose.yml              ← Container config (same VPS as Beacon, separate container)
├── Dockerfile
├── next.config.js
├── tailwind.config.js
├── package.json
└── .env.example
```

---

## Key Docs — Read Order

Read these in order before writing any code:

1. **`docs/kpfk_cms_spec_v1.md`** — The full platform spec. Covers system landscape, what each system owns, API contracts between systems, auth model, all features, migration strategy, and build sequence. This is the source of truth for architectural decisions.

2. **`docs/kpfk_cms_schema_spec_v1.md`** — Database schema for all 18 CMS tables. All tables prefixed with `cms_` because they share a Supabase project with an existing QIR (transcript/show-page generation) database. Follow the migration patterns and conventions described in this doc.

3. **`docs/kpfk_cms_uiux_handoff.md`** — UI/UX decisions: design system, host experience flows (Claim Your Show, host dashboard), global components (bug/flag button, now playing widget, donation CTA, stream player), fund drive mode behavior, and explicit rejections of certain design ideas.

4. **`docs/design_direction.md`** — Visual design direction: palette (KPFK Red, Charcoal, Off-White, Action Yellow), typography (serif headlines, sans-serif body, monospace for metadata), layout language (1-2px borders, modular grid, newspaper-boxed feel), and three reference comps (The Intercept, NTS Radio, Teenage Engineering). Includes calibration notes on what NOT to do.

5. **`docs/beacon_api_contract.md`** — The specific Beacon public API endpoints the CMS will call. Read-only. The CMS never writes to Beacon.

6. **`docs/aiir_show_template_v2.2.html`** — The current hand-built HTML template for show pages in Aiir. Shows exactly what data fields a show page needs and how they're currently structured. The CMS replaces this with a React template fed by structured data from the `cms_shows` table.

---

## Infrastructure Decisions (Already Made)

| Decision | Value | Notes |
|----------|-------|-------|
| Framework | Next.js (App Router) | Same as Beacon. SPA with persistent root layout for future persistent audio player. |
| Database | Supabase (shared project with QIR) | Project: `czjhwhfqohpmwprhasve`. All CMS tables prefixed `cms_`. |
| Styling | Tailwind CSS | Map design tokens to Tailwind config. |
| Email | Resend | Shared infrastructure with Beacon. For newsletter and contact form forwarding. |
| Analytics | Self-hosted Plausible or Umami | Deploy on same VPS. No Google Analytics. No cookies. |
| Anti-bot | Cloudflare Turnstile | On all public forms (contact, newsletter signup). |
| Hosting | Docker container on existing VPS | Traefik routes `cms.kpfk.org` (staging) and eventually `kpfk.org` (production). |
| Auth | Supabase Auth (magic link) | Separate auth from Beacon entirely. Three roles: admin, editor, host. |
| Media storage | Supabase Storage | Auto-resize uploads to WebP at multiple breakpoints. |
| Image processing | Sharp (Node.js) | Generate thumbnail (200px), medium (600px), large (1200px), original on upload. |

---

## Supabase Project Details

- **Project ref:** `czjhwhfqohpmwprhasve`
- **This is a shared database.** QIR tables already exist (transcripts, show_keys, show_tags, episode_log, etc.). Do NOT modify QIR tables.
- **All CMS tables must be prefixed with `cms_`.** Example: `cms_shows`, `cms_posts`, `cms_profiles`.
- **Exception:** `cms_stations` is the station config table. One row for KPFK.
- **RLS:** Disable for now on CMS tables (same as QIR). Admin API routes use service role client. Add RLS policies later when host self-service is built.

---

## Build Priorities

Build in this order. Each phase should be deployable and testable before starting the next.

### Phase 0: Scaffolding
- [ ] Next.js App Router project with persistent root layout (`layout.tsx`)
- [ ] Tailwind config with design tokens (palette, typography, spacing)
- [ ] Docker + docker-compose config (container alongside Beacon on same VPS)
- [ ] Traefik routing to `cms.kpfk.org` with basic auth gate (staging)
- [ ] Supabase client setup (pointing to shared QIR project)
- [ ] Migration runner setup (sequential SQL files in `supabase/migrations/`)
- [ ] `.env.example` with all required environment variables
- [ ] Run initial migrations: `cms_stations`, `cms_profiles`, core utility functions (`update_updated_at()`)

### Phase 1: Admin Shell + Show Pages
This is the critical path. Hosts can't claim shows until the admin can manage them.

- [ ] Auth: magic link login, role-based middleware (`admin`, `editor`, `host`)
- [ ] Admin layout: sidebar nav, top bar with user info
- [ ] Migrations: `cms_shows`, `cms_show_hosts`, `cms_media`, `cms_flags`, `cms_audit_log`
- [ ] Show CRUD: list, create, edit, view for admin
- [ ] Show page editor: structured form (title, tagline, description, history, show_type, logo upload, banner upload, social links, contact preference)
- [ ] Host management: add/edit hosts on a show, photo upload, bio editor
- [ ] Media library: upload with auto-resize, tag, search, browse
- [ ] Bug/flag button: fixed-position component on every authenticated page, auto-captures URL + timestamp + user, optional message, submits to `cms_flags`
- [ ] Seed data: import scraped Aiir show data into `cms_shows` and `cms_show_hosts` (with `is_claimed = false`)

### Phase 2: Public Show Pages + Schedule
The public-facing output. Hosts see their pages for the first time.

- [ ] Public layout: header (nav, listen live button), footer, responsive breakpoints
- [ ] Show page template: renders `cms_shows` data with all sections (masthead, about, history, hosts, episodes placeholder, donate CTA, contact form)
- [ ] Show directory page: `/on-air` — list of all active shows
- [ ] Migrations: `cms_schedule_slots`, `cms_contact_submissions`
- [ ] Schedule grid: 24/7 weekly grid, admin CRUD for slots
- [ ] Public schedule page: `/schedule` — read-only grid view, "On Now" highlighting
- [ ] Contact forms: system-generated per show, Turnstile protected, submissions logged + emailed to host
- [ ] Now Playing widget: pulls from Confessor API, displays current show + up next

### Phase 3: Claim Your Show (Host Onboarding)
The host self-service flow. This is where hosts start managing their own pages.

- [ ] Magic link invite system: admin sends invite to host email
- [ ] Claim flow: host lands on pre-populated page with scraped data, reviews, edits structured fields, submits
- [ ] "This isn't right" escape hatch: creates a flag for station staff
- [ ] Host dashboard: single-pane view with three zones (Recent Episodes, Edit Show Bio, Show Blog)
- [ ] Host auth scoping: hosts can only edit shows where they have a `cms_show_hosts` record

### Phase 4: Blog + Pages
Content creation tools for editors and hosts.

- [ ] Migrations: `cms_posts`, `cms_pages`
- [ ] Blog post CRUD: title, body (rich text editor), featured image, draft/published, optional show scope
- [ ] Show-scoped blog posts appear on the show's public page
- [ ] Blog index page: `/news` or `/blog` — all published posts, most recent first
- [ ] Pages CRUD: evergreen content pages with nested hierarchy
- [ ] RSS feed for blog

### Phase 5: Events Calendar
Unified calendar merging Beacon events with CMS-native events.

- [ ] Migration: `cms_events`
- [ ] CMS event CRUD: community events, sponsored events, protests, meetings
- [ ] Beacon events API client: fetch upcoming KPFK-produced events
- [ ] Public events page: `/events` — merged feed, both sources, sorted by date
- [ ] Event detail pages: CMS-native events render locally, Beacon events link out to `events.kpfk.org`
- [ ] Event categories: community, sponsored, fundraising, meeting, protest, other

### Phase 6: Homepage
The orchestration surface. Requires most other pieces to be in place.

- [ ] Modular grid layout with widget zones
- [ ] Now Playing + Up Next widget (Confessor API)
- [ ] Upcoming events feed (merged Beacon + CMS)
- [ ] Recent blog posts feed
- [ ] Sponsorship/hero carousel (requires Phase 7, or placeholder initially)
- [ ] Donation CTA (contextual: fund drive thermometer vs. evergreen sustainer pitch)
- [ ] Schedule preview (today's lineup)
- [ ] Newsletter signup form

### Phase 7: Sponsorship Display + Newsletter
Revenue-supporting features.

- [ ] Migrations: `cms_sponsorship_placements`, `cms_sponsorship_creatives`, `cms_sponsorship_impressions`
- [ ] Sponsorship admin: upload creatives, assign to zones, schedule, set rotation weight
- [ ] Impression/click tracking: lightweight API endpoint, daily aggregation
- [ ] Sponsor-facing reports: exportable summary by creative, date range
- [ ] Migrations: `cms_newsletter_subscribers`, `cms_newsletter_subscriptions`
- [ ] Newsletter signup: general + show-specific opt-in
- [ ] Subscriber management: list, export, unsubscribe handling
- [ ] Resend integration: send newsletters, show-specific notifications

### Phase 8: Fund Drive Mode + Episode Metadata
Enhancements that make the system feel alive.

- [ ] Fund drive mode: admin toggle in station settings, activates thermometer bar + enhanced CTAs across all pages
- [ ] Beacon campaign stats API client: fetch live campaign progress for thermometer
- [ ] Show attribution on donation CTAs during fund drive
- [ ] Migration: `cms_episode_metadata`
- [ ] Episode metadata editor: host adds show notes, description, transcript references, segment markers to episodes
- [ ] Confessor episode list integration: fetch episode audio data, display alongside CMS metadata on show pages
- [ ] Archive/podcast browser: `/archive` — browse by show, date, search episode descriptions

### Phase 9: Migration + Launch Prep
- [ ] Import remaining Aiir content (blog posts as `cms_posts`, evergreen pages as `cms_pages`)
- [ ] Build URL redirect map: old Aiir URLs → new CMS URLs
- [ ] Implement redirects in `next.config.js` or middleware
- [ ] Deploy self-hosted Plausible or Umami on VPS
- [ ] DNS cutover plan: point kpfk.org to VPS
- [ ] Custom 404 page
- [ ] Performance audit: Lighthouse scores, image optimization verification
- [ ] Accessibility audit: keyboard navigation, screen reader testing

---

## Patterns to Follow (From Beacon)

Reference the Beacon codebase for these established patterns:

| Pattern | Beacon Reference | CMS Application |
|---------|-----------------|-----------------|
| Migration numbering | `supabase/migrations/001_*.sql` through `056_*.sql` | Same sequential numbering, `cms_` prefixed table names |
| `update_updated_at()` trigger | Exists as a shared function | Create in first migration if not already in shared DB, apply to all CMS tables with `updated_at` |
| Soft deletes | `deleted_at` column, filtered in queries | Same pattern on all content tables |
| Service role client | `getSupabaseAdmin()` in `src/lib/` | Same pattern for admin API routes |
| Auth middleware | `src/middleware.ts`, `src/lib/api-auth.ts` | Similar but separate auth — CMS has its own `cms_profiles` table, not Beacon's `profiles` |
| API route structure | `src/app/api/[resource]/route.ts` | Same pattern |
| Rate limiting | `src/lib/rate-limit.ts` | Apply to public CMS API endpoints and contact form submissions |
| Email via Resend | `src/lib/email/` | Same Resend infrastructure, different templates |

---

## What NOT to Build

- **No donation/payment handling.** All donation actions route to Beacon (`donate.kpfk.org`).
- **No ticketing/check-in.** Ticketed events are Beacon's domain (`events.kpfk.org`).
- **No donor CRM.** Donor data stays in Beacon.
- **No audio storage/streaming.** Audio comes from Confessor.
- **No form builder.** Contact forms are system-generated per show, always the same 4 fields.
- **No plugin/theme system.** This is a single-station CMS, not WordPress.
- **No comments or live chat.** Moderation burden too high.
- **No per-page code injection.** No Head HTML, CSS, or JavaScript fields on pages. The template controls everything.

---

## Environment Variables Needed

```env
# Supabase (shared project with QIR)
NEXT_PUBLIC_SUPABASE_URL=https://czjhwhfqohpmwprhasve.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

# Resend (shared with Beacon)
RESEND_API_KEY=

# Cloudflare Turnstile
NEXT_PUBLIC_TURNSTILE_SITE_KEY=
TURNSTILE_SECRET_KEY=

# Beacon API (read-only)
BEACON_API_BASE_URL=https://donate.kpfk.org/api

# Confessor API (read-only)
CONFESSOR_API_BASE_URL=https://confessor.kpfk.org

# Analytics
ANALYTICS_SITE_ID=

# Sentry (optional, same pattern as Beacon)
SENTRY_DSN=
SENTRY_AUTH_TOKEN=

# App
NEXT_PUBLIC_SITE_URL=https://cms.kpfk.org
NODE_ENV=production
```

---

## Questions Claude Code Should Ask Ace (Not Assume)

- What's the exact Confessor API endpoint format for schedule and episode data? (Don't guess — ask for a sample response.)
- What's the Beacon public API base URL and auth mechanism (rate-limited open, or API key)?
- Which Resend domain/sender should CMS emails come from? (Probably `cms@kpfk.org` or `noreply@kpfk.org`)
- Should the staging auth gate be basic auth (htpasswd) or IP whitelist? (Beacon uses IP whitelist for pledge.kpfk.org)
- What's the Supabase Storage bucket name to use? (Create new, or use existing QIR bucket?)
