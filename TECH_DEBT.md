# Tech Debt — KPFK CMS

Known workarounds, shortcuts, and things to revisit.

---

## Active

### Confessor Legacy PHP API
**Added:** 2026-03-26
**Files:** `src/app/api/confessor/episodes/route.ts`

The episode archive proxies Confessor's legacy `_nu_do_api.php` endpoint. This is a PHP script that predates any formal API design. Quirks:
- Response is raw text that must be `JSON.parse()`'d (not always valid JSON)
- Audio URLs sometimes contain local filesystem paths (`confessor.kpfk.org/home/kpfkarch/public_html/mp3/`) that need rewriting to `archive.kpfk.org/mp3/`
- Episode metadata (guest name, topic) is nested in a `pubfile` array with abbreviated field names (`pf_gname`, `pf_gtopic`)
- No pagination — `num` parameter controls count, max ~50

When Otis builds proper Confessor API endpoints (Phase 3 dependency), replace this proxy with the new API.

### Episode Enrichment Not Yet Wired
**Added:** 2026-03-26
**Files:** `src/components/episode-archive.tsx`

The Aiir snippet (`886_episode-player.html`) enriches episodes by querying QIR's `episode_log` table via Supabase REST, matching on `mp3_url`. The new `EpisodeArchive` component does NOT do this yet. When `cms_episode_metadata` is built (Phase 8), episode enrichment should use that table instead, joining on `program_slug + air_date`.

### No node_modules — Build Not Verified Locally
**Added:** 2026-03-26

Dependencies are not installed in the dev environment. TypeScript compilation and Next.js build cannot be verified locally. All pre-existing type errors are from missing `next`, `react`, and `@supabase/supabase-js` type declarations.
