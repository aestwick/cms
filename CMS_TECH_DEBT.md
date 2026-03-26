# Technical Debt — KPFK CMS

## How to use this file
- Add items when implementing workarounds or shortcuts
- Include: what, why, where (file path), and suggested fix
- Check off items when resolved
- Review during each phase

---

## Phase 0 - Scaffolding

*No tech debt yet — this is a new project. Add items here as they arise during development.*

---

## Known Inherited Constraints

These aren't bugs — they're deliberate trade-offs made before code was written:

- [ ] **Shared Supabase project with QIR** — All CMS tables prefixed `cms_` to avoid collisions. If QIR adds a table that conflicts with a CMS table name, rename the CMS table. The `cms_` prefix should prevent this but it's worth noting.

- [ ] **No RLS on CMS tables initially** — RLS disabled to match QIR's approach and simplify initial development. Admin API routes use service role client. Host scoping enforced at API layer, not DB layer. **Must add RLS before opening host self-service to untrusted users.**

- [x] **Confessor API shape undocumented** — ~~The CMS will consume Confessor's API but exact response shapes are not yet confirmed.~~ **Resolved 2026-03-26:** API endpoints discovered from Aiir snippet reference implementations. See `OPEN_QUESTIONS.md`.

---

## Phase 2 — Public Show Pages

- [ ] **Confessor legacy PHP API proxy** — `src/app/api/confessor/episodes/route.ts` proxies Confessor's `_nu_do_api.php` endpoint. This is a legacy PHP script, not a designed API. Quirks: response must be `JSON.parse()`'d from raw text, audio URLs sometimes contain local filesystem paths that need rewriting, episode metadata uses abbreviated field names (`pf_gname`, `pf_gtopic`), no pagination support. Replace with proper Confessor API when Otis builds it (Phase 3 dependency).

- [ ] **Episode enrichment not wired** — The Aiir snippet (`886_episode-player.html`) enriches episodes by querying QIR's `episode_log` table via Supabase REST, matching on `mp3_url`. The new `EpisodeArchive` component does NOT do this yet. When `cms_episode_metadata` is built (Phase 8), enrich episodes from that table instead, joining on `program_slug + air_date`.
