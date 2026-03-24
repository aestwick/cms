# Beacon Public API — CMS Contract

**Purpose:** The CMS reads from Beacon's public API to display donation-related content. The CMS never writes to Beacon. All transactional actions (donate, buy tickets, manage membership) route to Beacon subdomains via links.

**Base URL:** `https://donate.kpfk.org/api` (confirm with Ace — may be a different subdomain)

**Auth:** Rate-limited, no API key (for now). Beacon has per-IP rate limiting on public endpoints. If the CMS needs higher limits, coordinate with Ace to whitelist the VPS IP or add a service key.

---

## Endpoints the CMS Needs

### Programs / Shows

| Endpoint | Method | Response | CMS Usage |
|----------|--------|----------|-----------|
| `/api/public/programs` | GET | Array of `{ id, slug, name, ... }` | Match CMS `cms_shows.program_slug` to Beacon's program slugs. Verify slug alignment during seed import. |

### Campaign Stats

| Endpoint | Method | Response | CMS Usage |
|----------|--------|----------|-----------|
| `/api/public/campaigns/active` | GET | Active campaigns with `{ id, name, goal_cents, raised_cents, donor_count, ... }` | Fund drive thermometer on homepage and all pages during fund drive mode. |
| `/api/public/campaigns/[id]/stats` | GET | Detailed stats for a specific campaign | Campaign-specific display if needed. |

### Events (KPFK-Produced)

| Endpoint | Method | Response | CMS Usage |
|----------|--------|----------|-----------|
| `/api/public/events/upcoming` | GET | Array of upcoming events with `{ id, title, slug, starts_at, venue, image_url, ticket_url, ... }` | Merged into the CMS events calendar. Display-only — ticket links route to `events.kpfk.org`. |

### Gift Catalog (If Needed)

| Endpoint | Method | Response | CMS Usage |
|----------|--------|----------|-----------|
| `/api/public/gifts` | GET | Available thank-you gifts | Could power a "see what you get when you donate" section. Low priority. |

### Sponsorship Creatives (Future)

| Endpoint | Method | Response | CMS Usage |
|----------|--------|----------|-----------|
| TBD | GET | Active sponsorship creatives with image URLs, click URLs, scheduling | CMS sponsorship display system pulls creatives from Beacon. Not available until Beacon's sponsorship module is built. For now, sponsorship creatives are managed directly in the CMS. |

### Membership Status Check (Future)

| Endpoint | Method | Response | CMS Usage |
|----------|--------|----------|-----------|
| TBD | GET | Whether a given email/donor has active membership | "Save to my feed" and gated content features. Not needed for v1. |

---

## Links to Beacon (Not API Calls)

These are URL patterns the CMS uses to link users to Beacon for transactional actions:

| Action | URL | Notes |
|--------|-----|-------|
| Donate | `https://donate.kpfk.org` | Can append `?show=slug` for show attribution |
| Donate (fund drive) | `https://donate.kpfk.org?campaign=CODE` | Campaign-attributed donation |
| Buy event tickets | `https://events.kpfk.org/public/[slug]` | Per-event ticket page |
| Donor portal | `https://my.kpfk.org` | Donor self-service |
| Manage membership | `https://my.kpfk.org/subscriptions` | Sustainer management |

---

## Notes

- **Beacon's public API is already rate-limited.** The CMS should cache Beacon responses (campaign stats, events) with a reasonable TTL (5 minutes for campaign stats during fund drives, 15 minutes for events) to avoid hitting rate limits.
- **The exact response shapes above are approximate.** Claude Code should ask Ace for actual API responses or test against the live API to confirm field names.
- **If an endpoint doesn't exist yet**, the CMS should gracefully degrade (hide the widget, show placeholder text) rather than error.
