# CLAUDE.md — KPFK CMS

This file is the primary context document for Claude Code sessions working on this project.

---

## Project Overview

KPFK CMS is the public-facing website for KPFK 90.7 FM, a Pacifica Foundation community radio station in Los Angeles. It replaces an Aiir-hosted CMS ($600/year) that was designed for commercial music radio and required manual HTML editing for show pages.

The CMS orchestrates content from three systems:
1. **Its own database** — show pages, blog posts, evergreen pages, events, media, sponsorship, newsletter
2. **Beacon** (external, read-only API) — donations, ticketed events, campaigns, membership
3. **Confessor** (external, read-only API) — broadcast schedule, now playing, episode audio/archives

**The CMS never handles money** (that's Beacon) and **never stores audio** (that's Confessor).

---

## Technology Stack

| Layer | Technology | Notes |
|-------|------------|-------|
| Frontend/Backend | Next.js (App Router) | SPA with persistent root layout for future audio player |
| Database | Supabase (PostgreSQL) | Shared project with QIR. All CMS tables prefixed `cms_` |
| Styling | Tailwind CSS | Custom design tokens in tailwind.config.js |
| Email | Resend | Shared infrastructure with Beacon |
| Analytics | Self-hosted Plausible or Umami | No Google Analytics, no cookies |
| Anti-bot | Cloudflare Turnstile | On all public forms |
| Auth | Supabase Auth (magic link) | Separate from Beacon auth |
| Media | Supabase Storage | Auto-resize on upload (Sharp) |
| Hosting | Docker + Traefik on VPS | Same VPS as Beacon, separate container |

---

## Supabase Project

- **Project ref:** `czjhwhfqohpmwprhasve`
- **Shared database** with QIR (transcript generation tool). QIR tables are unprefixed. CMS tables are all prefixed `cms_`.
- **Do NOT modify QIR tables.** They are: `compliance_flags`, `compliance_words`, `contacts`, `episode_log`, `qir_drafts`, `qir_settings`, `show_contacts`, `show_keys`, `show_page_generations`, `show_pages_current`, `show_tags`, `tags`, `transcript_corrections`, `transcripts`, `usage_log`.
- QIR's `transcripts` table (415 records) can be read by the CMS for episode transcript display.

---

## Auth & Roles

Three roles, scoped via `cms_profiles`:

| Role | Can Do | Cannot Do |
|------|--------|-----------|
| admin | Everything | N/A |
| editor | Blog posts, pages, media, events | User management, settings, sponsorship config |
| host | Edit own show(s) only — bio, hosts, blog posts, episode notes | Edit other shows, pages, settings |

Host scoping: a host can only write to shows where they have a `cms_show_hosts` record with their `profile_id`.

---

## Key Architecture Decisions

### 1. Separate from Beacon
The CMS is a separate app, repo, and auth system. It reads from Beacon's public API but shares no database tables, auth, or deployment. If the CMS has a bug, donations still process. If Beacon is down for maintenance, the CMS serves cached content.

### 2. Confessor is Read-Only
The CMS treats Confessor as a read-only data source. All rich episode metadata (show notes, descriptions, transcripts, segment markers) is stored in `cms_episode_metadata` and joined to Confessor audio data via `program_slug + air_date` at the application layer. The CMS is never blocked by Confessor API availability.

### 3. Shared Supabase Project with QIR
To save $10/month, CMS tables share QIR's Supabase project. All CMS tables use the `cms_` prefix. QIR tables are off-limits.

### 4. Shows are Structured Data, Not Pages
Every show is a row in `cms_shows` with structured fields. The template controls layout. Hosts edit fields, not HTML. This replaces Aiir's model where each show was a hand-coded HTML page.

### 5. SPA Root Layout
The Next.js app uses App Router with a persistent root layout. This is a day-one architectural requirement — if a persistent audio player is added later, it needs to survive page navigation without dropping playback.

### 6. No Form Builder
Contact forms are system-generated per show. Always the same 4 fields (name, email, subject, message). No per-show form customization. Turnstile on every form.

### 7. Events: Two Sources, One Calendar
The public events page merges KPFK-produced events (from Beacon API) with community/sponsored events (stored in `cms_events`). The rule: if KPFK sells tickets, it's a Beacon event. Everything else is a CMS event.

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-03-24 | Share Supabase project with QIR, prefix all CMS tables with `cms_` | Save $10/month. QIR transcripts can be joined directly. |
| 2026-03-24 | Self-hosted Plausible or Umami for analytics | Privacy-first, no cookies, no Google dependency. |
| 2026-03-24 | Rolling host onboarding (10 at a time), not batch | Higher conversion rate. Onboarding IS the email collection process. |
| 2026-03-24 | Email required for all hosts, no exceptions | Station policy. No email = no show page. |
| 2026-03-24 | No show categories/tags for v1 | Premature taxonomy. Show-scoped blog posts provide enough organization. |
| 2026-03-24 | No fund drive background color shift | Makes site look broken to visitors unfamiliar with fund drives. Fund drive mode is additive only. |
| 2026-03-24 | No skeuomorphic player controls | Accessibility issues, novelty wears off. Player should feel precise, not look like hardware. |
| 2026-03-24 | Phase 1 schedule is manual grid editor | Confessor sync comes in Phase 2. Write-back to Confessor in Phase 3 (depends on Otis). |
| 2026-03-24 | CMS-native events are lightweight calendar listings | No tickets, no pricing structures, no check-in. Just: what, when, where, link out. |

---

## Domains

| Domain | Purpose | Status |
|--------|---------|--------|
| cms.kpfk.org | Staging (auth-gated) | To be configured |
| kpfk.org | Production (post-launch) | Currently on Aiir |

---

## Related Systems

| System | Relationship | API |
|--------|-------------|-----|
| **Beacon** | Read-only. Donation stats, events, campaigns, programs. | `docs/beacon_api_contract.md` |
| **Confessor** | Read-only. Schedule, now playing, episode audio. | `confessor.kpfk.org` — endpoints TBD, ask Ace |
| **QIR** | Shared database. Transcripts readable by CMS. | Direct DB access (same Supabase project) |
| **Resend** | Shared email infra. Contact form forwarding, newsletters. | Resend API |
| **Plausible/Umami** | Analytics. Per-show metrics fed to host dashboard. | Self-hosted API |

---

## File Structure

```
kpfk-cms/
├── CLAUDE.md                       ← You are here
├── CLAUDE-CODE-SESSIONS.md         ← Session log
├── ARCHITECTURE.md                 ← System design
├── TEST_STRATEGY.md                ← Testing approach
├── TECH_DEBT.md                    ← Known workarounds
├── NON_GOALS.md                    ← What we don't build
├── OPEN_QUESTIONS.md               ← Unresolved decisions
├── docs/
│   ├── CLAUDE_CODE_INSTRUCTIONS.md ← Build priorities and phase plan
│   ├── kpfk_cms_spec_v1.md        ← Full platform spec
│   ├── kpfk_cms_schema_spec_v1.md ← Database schema (18 tables)
│   ├── kpfk_cms_uiux_handoff.md   ← UI/UX decisions
│   ├── design_direction.md        ← Palette, typography, comps
│   ├── beacon_api_contract.md     ← Beacon endpoints consumed
│   └── reference/
│       ├── aiir_show_template_v2.2.html
│       └── snippets/
│           ├── 890_show_page_css.html
│           ├── 886_episode_player.html
│           ├── 891_show_tags.html
│           └── [playlist_snippet].html
├── supabase/
│   └── migrations/
├── src/
│   ├── app/
│   ├── components/
│   ├── lib/
│   └── styles/
├── data/
│   └── seed/                       ← Scraped Aiir data for import
├── public/
├── docker-compose.yml
├── Dockerfile
├── next.config.js
├── tailwind.config.js
└── package.json
```

---

## Styling System — Editorial CSS

The public-facing site uses an **editorial/newspaper aesthetic** defined in `src/app/globals.css`. The design language is adapted from the KPFK show page snippet v2.2 (see `snippets/890_show-page-css`).

### Design Principles

- **No border-radius anywhere** — sharp rectangles reinforce the print identity
- **3px solid borders** instead of shadows or soft edges
- **Monospace for metadata** (Courier/JetBrains Mono) — schedule times, labels, tags
- **Serif for body text** (Georgia) — newspaper column feel
- **Sans-serif for headings** (Franklin Gothic) — bold, condensed, uppercase
- **Red (#B22222) used sparingly** — section accents, CTAs, stamps. Never backgrounds.
- **No gradients, no rounded corners, no soft shadows**

### How to Style New Components

**Use global CSS classes from `globals.css` first.** Only fall back to Tailwind utilities for layout (flexbox, grid, spacing, responsive breakpoints). Never recreate a pattern that already has a class.

### Available Classes

| Class | Use For |
|-------|---------|
| `.section-header` / `.section-header--large` | Section headings with red underline |
| `.masthead` | Page headers with double-rule (4px red + 1px gray) |
| `.sidebar-label` / `.sidebar-label--dark` | Uppercase monospace section labels |
| `.show-card` / `.show-card__*` | Show grid cards (thick border, square image) |
| `.host-card` / `.host-card__*` | Host cards with grayscale photos |
| `.tag-stamp` / `.tag-stamp--topic/format/audience` | Archive stamp-style tags |
| `.tag-filter` / `.tag-filter--active-*` | Filter pills on listing pages |
| `.badge` / `.badge--default/accent/muted/highlight` | Monospace metadata badges |
| `.btn-editorial` / `--primary/--secondary/--light/--small` | Flat editorial buttons |
| `.form-input` / `.form-label` | Form controls with thick borders |
| `.card-light` / `.card-editorial` | Light (2px gray) or heavy (3px black) card borders |
| `.donate-cta` | Donation call-to-action section (3px red border) |
| `.schedule-badge` | Monospace dateline-style schedule labels |
| `.social-link` | Icon + label link rows |
| `.adjacent-link` | Bordered show link cards |
| `.mono-link` | Small uppercase action links (red, underline on hover) |
| `.drop-cap` | Red first-letter on prose descriptions |
| `.divider` / `.divider--heavy` | Horizontal rules (1px gray or 4px black) |
| `.status-badge` | Overlay badge (dark background, monospace) |
| `.show-logo` | Square logo with 3px border |
| `.show-card__type` | Monospace type label (e.g., "MUSIC", "TALK") |

### When to Use Tailwind vs Global Classes

- **Global class**: Any visual pattern that appears in 2+ places (buttons, badges, cards, labels, inputs)
- **Tailwind utility**: Layout primitives (`flex`, `grid`, `mx-auto`, `max-w-7xl`, `px-6`, `py-12`, responsive breakpoints)
- **Never**: Inline `style={}` for colors or typography. Use design tokens from `@theme`.

### Adding New Patterns

If you need a new component style:
1. Check if an existing class covers it (or can be extended with a modifier)
2. If not, add it to `globals.css` in the editorial component system section
3. Follow the naming convention: `.component-name` for blocks, `.component-name__element` for children, `.component-name--modifier` for variants
4. Use CSS custom properties from `@theme` for colors and fonts — never hardcode hex values that aren't in the design system

---

## Patterns from Beacon to Follow

Reference the Beacon repo for established patterns. Don't reinvent:

- Sequential migration numbering (`001_`, `002_`, ...)
- `update_updated_at()` trigger function
- Soft deletes with `deleted_at` column
- Service role client for admin API routes
- Auth middleware pattern
- Rate limiting on public endpoints
- Resend email integration
- Amounts in cents, UUIDs everywhere, station_id scoping
