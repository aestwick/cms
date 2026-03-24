# Non-Goals — KPFK CMS

What the CMS explicitly does NOT do. Prevents scope creep.

---

## Intentionally Not Implemented

### Content & Publishing

- **WordPress-style plugin system**: No plugins, no theme marketplace. Single-station CMS with fixed templates.
- **Freeform page builder**: No drag-and-drop layout editor. Pages use structured templates. Hosts edit fields, not HTML.
- **Per-page code injection**: No Head HTML, CSS, or JavaScript fields on pages. The template controls everything. (This replaces Aiir's approach of raw HTML editing.)
- **Comments or live chat**: Audience moderation burden too high. No UGC on show pages or blog posts.
- **Wiki or knowledge base**: Not a documentation platform.
- **Podcast hosting**: Audio files live in Confessor. The CMS links to them, never stores or serves audio.

### Payments & Commerce

- **Donation processing**: That's Beacon. The CMS links to Beacon for all transactional actions.
- **Ticket sales**: That's Beacon. CMS displays Beacon events but all ticket purchases happen on `events.kpfk.org`.
- **E-commerce / merch store**: Out of scope.
- **Sponsorship invoicing or payment collection**: Sponsorship financials are Beacon's domain. The CMS handles display and impression tracking only.

### User Features

- **Password authentication**: Magic links only. No username/password.
- **Social login**: No Google, Facebook, Apple sign-in.
- **Donor/listener accounts**: The CMS has host and staff accounts. Listeners don't log in. Donor accounts are in Beacon's portal (`my.kpfk.org`).
- **User-generated content**: No public submissions of blog posts, show reviews, or community contributions (except contact forms).
- **Community events public submission (v1)**: Deferred. Community events are entered by staff. Public submission with moderation queue is a future consideration.

### Technical

- **Mobile app**: Web-only. The responsive site serves mobile users.
- **PWA / offline support**: Not in v1. The SPA root layout supports this later.
- **Real-time updates**: No WebSockets. Data refreshes on page load or via polling (now playing widget polls Confessor).
- **Multi-language / i18n**: English only. Some shows are in Spanish but the CMS UI and templates are English.
- **Full-text search across Confessor**: The CMS can search its own `cms_episode_metadata`, but searching Confessor's full audio archive transcript text is a future feature dependent on QIR data.

### Scheduling & Broadcasting

- **Replacing Confessor**: The CMS does not manage recordings, streaming, or broadcast automation. It reads from Confessor.
- **Schedule write-back to Confessor (v1)**: Phase 1 is a standalone grid editor. Confessor sync is Phase 2. Write-back is Phase 3, dependent on Otis building API endpoints.

### Analytics & Reporting

- **Custom report builder**: Not a BI tool. Show hosts see basic page metrics. Admins see Plausible/Umami dashboards.
- **Donor analytics**: Donor data analytics happen in Beacon. The CMS shows hosts their show's donation attribution, but detailed donor reports are Beacon's domain.

---

## Why These Are Non-Goals

1. **Blast radius**: The CMS should be lightweight. Every feature is maintenance burden on a one-person team.
2. **System boundaries**: Beacon handles money, Confessor handles audio. The CMS handles content and presentation. Clear lines prevent duplication.
3. **Host simplicity**: If a feature makes the host experience more complex without clear value, it doesn't belong in v1.
4. **Aiir lessons**: Aiir had 28 modules. KPFK used 9. Don't build features nobody will use.

---

## Reconsidering Non-Goals

If something listed here becomes necessary:
1. Check `OPEN_QUESTIONS.md` first
2. Document the use case
3. Consider: does this belong in the CMS, or in Beacon/Confessor?
4. Decide deliberately, not reactively
