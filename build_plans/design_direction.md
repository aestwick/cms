# KPFK CMS — Design Direction

**Status:** Decisions made, ready for implementation
**Source:** Collaborative design exploration, March 2026

---

## Design Philosophy

The site should feel like a **well-run community institution** — dense with information, intentional in its layout, warm without being casual. Not a tech startup landing page. Not a DIY zine. Not a commercial music radio template.

KPFK has been broadcasting since 1959. The design should convey institutional weight with community warmth.

---

## Three Reference Comps

### 1. The Intercept / The Marshall Project (Journalistic Weight)
- High-character serif typography for headlines — feels like a printed broadsheet
- Grid-heavy, "boxed" layouts that give content a sense of permanence
- **Use for:** Archive pages, blog posts, show descriptions, any long-form content

### 2. NTS Radio (Utility / Schedule-First)
- Schedule IS the primary navigation
- Unapologetically grid-based
- Clean but dense — respects the listener's time
- **Use for:** Schedule page, show directory, episode lists, host dashboard

### 3. Teenage Engineering (Intentional Precision)
- Mechanical precision in interaction design — immediate response, clear state indicators
- Purpose-built feel, nothing decorative without function
- **Use for:** The *feel* of interactive elements (player, fund drive thermometer, admin tools)
- **Do NOT literally copy:** No fake knobs, no rack-mount skeuomorphism, no VU meters

---

## Palette

| Token | Hex | Usage |
|-------|-----|-------|
| **KPFK Red** | `#B22222` | Live indicators, Donate CTAs, Fund Drive elements — used sparingly |
| **Charcoal** | `#1A1A1A` | Primary text, borders, structural elements |
| **Off-White** | `#F9F7F2` | Page background — "printed paper" warmth, not harsh white |
| **Action Yellow** | `#FFD700` | Now Playing state, highlights, alert indicators |

### Tailwind Config Mapping
```js
colors: {
  kpfk: {
    red: '#B22222',
    charcoal: '#1A1A1A',
    cream: '#F9F7F2',
    yellow: '#FFD700',
  }
}
```

Additional neutrals and state colors should be derived from these anchors. Use Tailwind's default gray scale for secondary text and disabled states.

---

## Typography

| Role | Style | Examples |
|------|-------|---------|
| **Headlines** | High-contrast serif, bold | Show titles, page titles, section headers. Candidates: Publico, FB Mercury, Playfair Display (free), Lora (free). |
| **Body text** | Clean sans-serif, comfortable reading size | Show descriptions, blog posts, page content. Candidates: Inter, Source Sans Pro. |
| **UI / Metadata / Timestamps** | Slightly condensed sans-serif or monospace | Schedule times, episode dates, admin labels, Confessor-sourced data. Candidates: JetBrains Mono (mono), Barlow Condensed (sans). |

### Font Loading
Use `next/font` for self-hosted fonts. No Google Fonts CDN calls — consistent with the privacy-first approach (no third-party requests).

---

## Layout Language

### Containers
- **1-2px solid borders** for content containers (newspaper "boxed" layout)
- **No soft shadows** — the current Aiir site uses soft shadows everywhere and it reads as generic SaaS
- Borders create structure and hierarchy without the "floating card" aesthetic

### Grid
- **12-column modular grid** for homepage and content pages
- Information density prioritized over whitespace — but density ≠ clutter
- Each section should feel like a newspaper column: purposeful, complete, self-contained

### Spacing
- Generous vertical rhythm between sections
- Tight spacing within components (cards, list items)
- The contrast between "breathing room between sections" and "density within sections" creates the newspaper feel

---

## Explicit Design Rejections

### ❌ Skeuomorphic Player Controls
No fake knobs, VU meters, tube amp glows, or rack-mounted equipment aesthetics. The player should feel precise and mechanical in its *interaction design* (immediate response, clear states) without literally looking like hardware. Accessibility concerns: screen readers, keyboard navigation, touch targets on mobile.

### ❌ Fund Drive Background Color Shift
Fund drive mode does NOT change the site's background color to "Alert Red" or "Action Yellow tint." This makes the site look broken to visitors who don't know what a fund drive is. Fund drive mode is **additive**: new elements appear (thermometer bar, enhanced CTAs, banner). Existing elements don't change color or position.

### ❌ Full "Underground Newspaper" / Zine Aesthetic
The ethos of density and intentionality is correct. But the visual treatment should NOT include: intentionally rough textures, distressed fonts, "screen-printed" visual language, or deliberately lo-fi elements. KPFK is an institution, not a pop-up. The newspaper metaphor applies to **structure** (typography, grid, borders, information density), not to **surface treatment** (textures, distressing, collage).

---

## Component-Specific Design Notes

### Now Playing Widget
- High visibility — this is how listeners know what's on
- Show name + host prominently displayed
- "On Now" and "Up Next" with times
- Listen Live button — always the #1 CTA on the site
- Action Yellow background or accent for "On Now" state

### Donation CTA
- **During fund drive:** KPFK Red accent, thermometer bar, show attribution ("Support Bike Talk!")
- **Off-cycle:** Subtle, present but not dominant. Evergreen sustainer pitch.
- All clicks route to Beacon — the CMS never handles money

### Stream Player (v1)
- Popup player: play/pause, volume, now-playing metadata
- Clean, minimal, works on mobile
- The root layout reserves space for a future persistent bottom-bar player

### Host Dashboard
- "Get in, do the thing, get out" — not a complex admin interface
- Three zones: Recent Episodes (active, working surface), Edit Show Bio (settled, rarely updated), Show Blog (creative tool)
- Recent Episodes should have higher visual weight than the other two zones

### Bug/Flag Button
- Fixed position (bottom-right), present on every authenticated page
- Minimal: icon that expands to a small form on click
- Auto-captures context (URL, timestamp, user), optional text message
- Should not feel intrusive but should always be findable

---

## Mobile Priorities

Not a native app. Not a PWA yet. But responsive is critical — most listeners check the schedule on their phones.

1. **Listen Live button** — always reachable, never buried under menus
2. **Schedule** — today's lineup, what's on now
3. **Show pages** — bio, recent episodes, contact
4. **Donation CTA** — especially during fund drives

The popup player must work well on mobile. Test early.

---

## What This Design Does NOT Cover

- Beacon UI (donations, events, donor portal) — separate design system
- Confessor admin UI — Otis's domain
- Email templates — will be designed separately when newsletter feature is built
- Mobile app — out of scope
