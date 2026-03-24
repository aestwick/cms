# KPFK CMS — UI/UX Design Brief

**For:** UI/UX design finalization
**From:** Ace Estwick
**Date:** 2026-03-24
**Status:** Decisions made — ready for component-level design
**Context:** This builds on the Platform Spec v1 and the initial "Modern Analog" design exploration. It captures all decisions, resolved questions, and design constraints.

---

## 1. Design Direction — Confirmed

### The Three-Comp Framework (Adopted)

| Reference | What We Take From It | What We Don't |
|-----------|---------------------|---------------|
| **The Intercept / The Marshall Project** | Journalistic typography weight, high-contrast serif headlines, "printed record" feel for archive and blog content | Their specific layouts — KPFK is a broadcast companion, not a news org |
| **NTS Radio** | Schedule-as-navigation, grid-based show discovery, information-dense layouts that respect the listener's time | Their monochrome minimalism — KPFK needs more warmth |
| **Teenage Engineering** | Mechanical precision, intentional density, the *feel* of purpose-built tools | Literal hardware skeuomorphism — no fake knobs, no rack-mount cosplay |

### Palette — Confirmed

| Token | Value | Usage |
|-------|-------|-------|
| KPFK Red | `#B22222` | Live indicators, Donate CTAs, Fund Drive elements only — used sparingly |
| Charcoal | `#1A1A1A` | Primary text, borders, structural elements |
| Off-White | `#F9F7F2` | Page background — "printed paper" warmth |
| Action Yellow | `#FFD700` | Now Playing state, highlights, alerts |

### Typography — Confirmed Direction

- **Headlines:** High-contrast serif with journalistic weight (Publico, FB Mercury, or similar)
- **UI / Metadata / Timestamps:** Slightly condensed workhorse sans-serif (Franklin Gothic, or similar). Monospace acceptable for Confessor-sourced data labels (timestamps, durations)
- **Body text:** Clean, readable sans-serif at comfortable size

### Layout Language — Confirmed

- 1px–2px solid borders for containers (newspaper "boxed" layout), not soft shadows
- Modular grid, not single-hero layouts
- Information density prioritized over whitespace — but density ≠ clutter

---

## 2. Decisions Made Since Initial Exploration

### Confirmed

- **Aiir scrape is complete.** ~100 show pages, blog posts, evergreen pages, media assets, and full URL inventory extracted. This is the seed data for host onboarding.
- **Confessor read API is available.** We can pull schedule grid, now playing/up next, and episode lists. Write access is not yet available but is not a blocker — the CMS stores all rich metadata (show notes, episode descriptions, transcripts) in its own database and joins to Confessor audio data via `program_slug + air_date`.
- **Analytics: self-hosted Plausible or Umami.** No Google Analytics. No cookie consent banners. Decision is final.
- **Rolling host onboarding, not batch.** Hosts are invited ~10 at a time via personal outreach + magic link. No mass email blast.
- **Email is required for all hosts.** No exceptions. If a host wants a presence on the platform, they provide an email address. This is a station policy, not a technical limitation.

### Resolved Open Questions

| Question | Resolution |
|----------|-----------|
| Confessor read API scope | Read access confirmed — schedule, now playing, episode lists. Write is future. |
| Persistent audio player | Start with popup stream player. SPA root layout supports persistent player retrofit later. |
| Community events calendar | Defer to post-v1. Moderation burden unresolved. |
| Aiir scraper timing | Done. Content extracted. |

---

## 3. The Host Experience — "Claim Your Show"

This is the most important UX flow in the CMS. If hosts don't adopt it, we're back to the Google Form bottleneck.

### 3.1 Claim Flow

**Trigger:** Ace (or designated admin) sends a personal magic link invite to a host.

**Step 1 — "Is This Still You?"**
Host lands on a pre-populated page showing their scraped Aiir data: show title, bio, artwork, description, social links. The CMS asks: "We migrated your show page. Review what we have and make it yours."

**Step 2 — Edit & Confirm**
Structured form fields — NOT a blank canvas. The template controls layout and styling. Hosts edit:
- Show title & tagline
- Show description (rich text, constrained — no freeform HTML)
- Host bio(s) — supports multiple hosts per show
- Show artwork / banner image (upload with auto-resize)
- Social media links
- Contact preference (public email or contact form)

**Step 3 — Published**
Show page goes live on the public site. Host sees a confirmation with a link to their live page.

**Escape hatch:** If the scraped data is wrong (wrong host, cancelled show, merged show), the host clicks "This isn't right" which creates a flag/ticket for station staff. They do NOT edit garbage into something slightly less wrong.

### 3.2 The Host Dashboard — "Single Pane"

After claiming, the host's authenticated view is a single-screen dashboard with three zones:

| Zone | Content | Update Frequency |
|------|---------|-----------------|
| **Recent Episodes** | Episode list pulled from Confessor. Each row has CMS-owned fields (show notes, description) the host can fill in. This is the working surface — it should feel active and current. | Weekly / per-episode |
| **Edit Show Bio** | Link to the structured show page editor. This should feel settled — update it once or twice a year. Lower visual weight than Recent Episodes. | Rarely |
| **Show Blog** | Create a new blog post that publishes to the show's public page. Simple: title, body (rich text), optional image. | As needed |

**Design constraint:** The dashboard must be a "get in, do the thing, get out" experience. Hosts are not CMS power users. They want to add show notes for today's episode and leave. Don't make them navigate.

### 3.3 Show Blog Posts

Hosts can publish blog posts scoped to their show. These posts:
- Appear on the show's public page (most recent first)
- Also appear in the main station blog feed (tagged with the show)
- Are the host's primary content creation tool beyond episode notes
- Simple editor: title, body, optional featured image, publish/draft toggle
- No categories, no tags, no scheduling — keep it dead simple for v1

### 3.4 Host Analytics (In Dashboard)

Pulled from self-hosted Plausible/Umami via API:
- Page views on their show page (trend over time)
- Most-listened episodes (if listen tracking is available)
- Donation attribution — how much their show has generated during fund drives (from Beacon API, visible only to host + admin)

This gives hosts a reason to care about their page quality and on-air pitching.

---

## 4. Global UI Components

### 4.1 Bug/Flag Button

**Every authenticated page** gets a fixed-position bug/flag button (bottom-right or similar). Clicking it opens a minimal form:

- Auto-captured: current URL, timestamp, user ID/role, browser/device info
- Optional: text description from user ("Something looks wrong with my episode list")
- Submits to a `flags` table and optionally emails webmaster
- This is not a support ticket system — it's a lightweight signal channel

### 4.2 Now Playing Widget

**Single unified widget** replacing the current dual-widget disaster. Pulls from Confessor:
- Current show name + host
- "On Now" / "Up Next" with times
- Listen Live button (persistent, always visible — this is the #1 CTA on the site)
- Link to the current show's page

### 4.3 Donation CTA (Contextual)

- **During fund drive:** Thermometer + current show attribution + "Support [show name]!" framing. Prominent.
- **Off-cycle:** Evergreen sustainer pitch. Present but not dominant.
- All donation actions route to Beacon (`donate.kpfk.org`). The CMS never handles money.

### 4.4 Stream Player

**v1: Popup player.** Click "Listen Live" → opens a small popup/overlay with play/pause, volume, and now-playing metadata. Simple.

**Architecture note:** The Next.js app uses App Router with a persistent root layout (`layout.tsx`). This means the SPA shell survives page navigation. A persistent bottom-bar player can be retrofitted later without rewriting the site. Design the root layout to accommodate this — reserve the space conceptually even if the component isn't built yet.

---

## 5. Fund Drive Mode

A site-wide admin toggle that enhances (not replaces) the normal site experience.

### What Changes

- **Persistent progress bar** appears at the top of every page — campaign thermometer pulled from Beacon API
- **Donation CTAs** get elevated prominence across all pages
- **Show attribution** appears on show pages: "Support [current show]! Pledge now!" with auto-tagged donation links
- **Optional banner** — station can set a fund drive banner/skin if desired

### What Does NOT Change

- The background color stays the same. No "Alert Red" tint on the entire site. Fund drives happen multiple times a year — the site can't look broken every time one starts. The visual shift should be additive (new elements appearing) not transformative (existing elements changing color).
- Navigation, layout, and information hierarchy stay stable. Listeners who visit during a drive should still be able to find the schedule, show pages, and archive without fighting through a wall of donation prompts.

---

## 6. Pushback on Initial Design Exploration

These items from the initial "Modern Analog" exploration are being explicitly rejected or modified:

### ❌ "Knobs, not Sliders" for Player Controls

The "rack-mounted studio gear" metaphor is evocative as a mood reference but bad as a literal UI pattern. Skeuomorphic audio controls (fake knobs, VU meters, tube amp glows) are:
- An accessibility problem (screen readers, keyboard navigation)
- A novelty that stops being charming after the third visit
- Harder to maintain and adapt to mobile

**Instead:** The player should feel *precise and mechanical* in its interaction design — immediate response, clear state indicators, no ambiguity — without literally looking like hardware. Think: Teenage Engineering's *intention*, not their *aesthetic*.

### ❌ Fund Drive Background Color Shift

As noted above: shifting the entire site background to "light Alert Red" or "Action Yellow tint" makes the site look broken to anyone who doesn't know what a fund drive is. New visitors, casual listeners checking the schedule, people arriving from search — they all get a site that looks like it's in an error state.

**Instead:** Fund drive mode is additive. New elements (thermometer bar, enhanced CTAs, banner) appear. Existing elements don't change color or position. The site always looks like a functioning radio station website.

### ⚠️ "Bulletin Board" / "Underground Newspaper" Aesthetic — Calibrate

The ethos is right: dense, intentional, human, community-centered. But "underground newspaper" can tip into deliberately rough/DIY in a way that reads as amateur rather than authoritative. KPFK has been broadcasting since 1959 — the aesthetic should convey *institutional weight with community warmth*, not "we printed this on a Risograph last night."

The newspaper/broadsheet metaphor works best for: typography choices, grid structure, information density, and the "boxed" container treatment. It should NOT drive: intentionally rough textures, distressed fonts, or "zine" visual language.

---

## 7. Page Inventory — What Needs Designing

### Public Pages

| Page | Key Components | Data Source |
|------|---------------|-------------|
| **Homepage** | Now Playing widget, sponsorship carousel, upcoming events feed, recent blog posts, donation CTA, schedule preview, newsletter signup | Confessor + Beacon + CMS |
| **Show Page** (×100) | Show bio, host info, artwork, schedule slot, episode archive feed, show blog posts, per-show donation CTA, contact form, show-specific newsletter opt-in | CMS + Confessor + Beacon |
| **Schedule** | Daily/weekly grid, "On Now" highlight, click-to-show-page | Confessor |
| **Archive / Podcast Browser** | Browse by show/date, episode detail with player + show notes + transcript, search | Confessor (audio) + CMS (metadata) |
| **Blog / News** | Post list, post detail, categories, RSS | CMS |
| **Events** | Upcoming events feed, calendar view, event detail (from Beacon), ticket links | Beacon |
| **Evergreen Pages** | About, Contact, How to Listen, Volunteer, FCC Public File, etc. | CMS |

### Authenticated Pages (Staff/Host)

| Page | Users | Key Components |
|------|-------|---------------|
| **Host Dashboard** | Hosts | Recent Episodes (with editable fields), Edit Show Bio link, Show Blog, Analytics |
| **Claim Your Show** | Hosts (one-time) | Scraped data review, structured edit form, "This isn't right" escape hatch |
| **CMS Admin** | Admin, Editor | Page CRUD, blog CRUD, media library, sponsorship config, user management, settings |
| **Sponsorship Admin** | Admin | Creative upload, placement zone assignment, scheduling, rotation rules, analytics |

### Utility Components (All Authenticated Pages)

| Component | Behavior |
|-----------|----------|
| **Bug/Flag Button** | Fixed position, every authenticated page. Auto-captures URL + timestamp + user. Optional text input. Submits to flags table + webmaster email. |

---

## 8. Mobile Considerations

Not a native app. Not a PWA (yet). But the responsive experience matters because most listeners check the schedule and show pages on their phones.

**Priorities on mobile:**
1. Listen Live button — always reachable, never buried
2. Schedule — today's lineup, what's on now
3. Show pages — bio, recent episodes, contact
4. Donation CTA — during fund drives especially

**The player** (popup in v1) must work well on mobile. Test early.

---

## 9. What's NOT Being Designed

- Beacon UI (donations, events, donor portal) — that's a separate app with its own design system
- Confessor UI — that's Otis's domain
- Mobile app — out of scope for v1
- Comments / live chat — too much moderation risk
- Plugin/theme system — this is a single-station CMS, not WordPress

---

## 10. Deliverables Needed from Design

1. **Design system / component library** — tokens (colors, type scale, spacing, border treatments), button styles, form elements, card patterns, grid system
2. **Homepage layout** — modular grid with all widget zones placed
3. **Show page template** — public view + host edit view
4. **Host dashboard** — single-pane layout with the three zones
5. **Claim Your Show flow** — the three-step onboarding screens
6. **Schedule page** — daily and weekly grid views
7. **Fund drive mode** — the additive elements (thermometer bar, enhanced CTAs) overlaid on normal site
8. **Mobile breakpoints** — responsive behavior for all key pages
9. **Stream player** — popup player (v1) + conceptual persistent player slot in root layout

---

## 11. Technical Constraints for Design

- **Next.js App Router** — SPA with persistent root layout. Page transitions don't cause full reloads. Design should account for this (no flash of unstyled content, smooth transitions).
- **Tailwind CSS** — utility-first CSS framework. Design tokens should map cleanly to Tailwind's scale.
- **Supabase Auth** — magic link login for hosts. No password fields needed in host flows.
- **Confessor data is read-only** — the CMS can display schedule/episode data but can't modify it. Design should not imply the host can change their broadcast time from within the CMS.
- **Beacon data is read-only** — donation stats, events, campaigns are displayed but all actions route to Beacon subdomains.
- **~100 shows** — the show page template needs to work at scale. Every show gets the same structure; differentiation comes from content, not layout.
- **Self-hosted analytics (Plausible/Umami)** — no Google Analytics scripts, no third-party tracking pixels, no cookie consent UI needed.
