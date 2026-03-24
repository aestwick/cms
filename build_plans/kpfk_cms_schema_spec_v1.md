# KPFK CMS — Database Schema Spec v1

**Last updated:** 2026-03-24
**Status:** Ready for implementation
**Purpose:** Schema design for the CMS Supabase project. Claude Code should use this as the source of truth when writing migrations. Reference Beacon's migration patterns (migration numbering, `updated_at` triggers, soft deletes, RLS conventions) for consistency.

---

## Design Principles

- **Separate Supabase project** from Beacon. No shared tables, no shared auth.
- **`station_id` on every content table** for future multi-station support (same pattern as Beacon).
- **Soft deletes** (`deleted_at`) on all user-facing content tables.
- **`updated_at` triggers** on all mutable tables (use Beacon's `update_updated_at()` pattern).
- **Rich text stored as HTML** in `text` columns — the frontend editor produces sanitized HTML.
- **Media references are Supabase Storage paths**, not URLs. URLs are generated at render time.
- **Confessor data is NOT stored** — it's fetched via API at request time. The CMS stores only CMS-owned metadata that joins to Confessor data via `program_slug + air_date`.

---

## Auth & Profiles

### `profiles`

CMS user accounts. Separate from Beacon profiles entirely.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | = Supabase Auth user ID |
| station_id | uuid FK → stations | |
| role | text | `admin`, `editor`, `host` |
| display_name | text | |
| email | text | |
| created_at | timestamptz | |
| updated_at | timestamptz | |
| deleted_at | timestamptz | nullable, soft delete |

### `stations`

Station configuration. One row for KPFK now, multi-station ready.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| name | text | "KPFK 90.7 FM" |
| slug | text | "kpfk" |
| tagline | text | nullable |
| timezone | text | "America/Los_Angeles" |
| stream_url | text | Live stream URL |
| beacon_api_url | text | "https://donate.kpfk.org/api" or similar |
| confessor_api_url | text | "https://confessor.kpfk.org" or similar |
| analytics_site_id | text | Plausible/Umami site identifier |
| settings | jsonb | Station-level config (fund drive mode toggle, default contact email, social links, branding colors, etc.) |
| created_at | timestamptz | |
| updated_at | timestamptz | |

---

## Shows & Hosts

### `shows`

The core content unit. Each show gets one row. Replaces the Aiir page-per-show model.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| station_id | uuid FK → stations | |
| title | text | "Bike Talk" |
| slug | text | unique per station. Used in URL: `/on-air/bike-talk` |
| tagline | text | nullable. "Bikes first — people-powered transportation for all." |
| description | text | Rich text (HTML). "About the Show" section. |
| history | text | nullable. Rich text (HTML). "History & Legacy" section. |
| show_type | text | `talk`, `music`, `mixed` — controls which template sections render |
| program_slug | text | nullable. Maps to Confessor program + Beacon programs table. Join key for schedule and episodes. |
| logo_path | text | nullable. Supabase Storage path for show logo/artwork. |
| banner_path | text | nullable. Supabase Storage path for banner image. |
| contact_preference | text | `form`, `email`, `both`, `none` |
| contact_email | text | nullable. Public contact email (if preference allows). |
| website_url | text | nullable. External show website. |
| rss_url | text | nullable. External RSS feed (for shows like Democracy Now that have their own site). |
| social_links | jsonb | `{ "facebook": "url", "twitter": "url", "instagram": "url", ... }` |
| is_active | boolean | Whether show appears in directory and search. |
| is_claimed | boolean | default false. Set true when host completes Claim Your Show flow. |
| claimed_at | timestamptz | nullable. |
| sort_order | integer | For manual ordering in directory. |
| created_at | timestamptz | |
| updated_at | timestamptz | |
| deleted_at | timestamptz | nullable |

**Indexes:** `station_id + slug` (unique, where deleted_at is null), `station_id + program_slug`, `station_id + is_active`.

### `show_hosts`

Junction table linking hosts to shows. Supports multi-host shows and hosts with multiple shows.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| show_id | uuid FK → shows | |
| profile_id | uuid FK → profiles | nullable — host may not have claimed yet |
| name | text | Display name (from scrape initially, editable by host) |
| bio | text | Rich text (HTML). |
| photo_path | text | nullable. Supabase Storage path. |
| email | text | Host's email. Required for magic link auth. |
| is_primary | boolean | default false. Primary host displayed first. |
| sort_order | integer | |
| created_at | timestamptz | |
| updated_at | timestamptz | |

**Indexes:** `show_id`, `profile_id`.

**Note:** When a host claims their show, `profile_id` gets linked to their auth account. Before claiming, the row exists with `profile_id = null` (seeded from scrape data).

---

## Episodes (CMS-Owned Metadata)

### `episode_metadata`

Rich metadata stored in the CMS, joined to Confessor audio data via `program_slug + air_date`. The CMS never stores audio files — those come from Confessor at render time.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| station_id | uuid FK → stations | |
| show_id | uuid FK → shows | |
| program_slug | text | Matches Confessor program identifier. |
| air_date | date | Broadcast date. Composite join key with program_slug. |
| title | text | nullable. Custom episode title (overrides Confessor default). |
| description | text | nullable. Rich text (HTML). Show notes / episode description. |
| transcript_url | text | nullable. URL or storage path to VTT/SRT transcript file. |
| segments | jsonb | nullable. Array of `{ "title": "...", "start_seconds": N }` for chapter markers. |
| is_published | boolean | default true. Host can hide episodes from the public page. |
| created_by | uuid FK → profiles | nullable. |
| created_at | timestamptz | |
| updated_at | timestamptz | |

**Indexes:** `station_id + program_slug + air_date` (unique), `show_id + air_date`, `station_id + air_date`.

---

## Blog Posts

### `posts`

Blog posts created by editors or hosts. Host posts are scoped to their show.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| station_id | uuid FK → stations | |
| show_id | uuid FK → shows | nullable. If set, this is a show-scoped post. |
| author_id | uuid FK → profiles | |
| title | text | |
| slug | text | unique per station |
| body | text | Rich text (HTML). |
| excerpt | text | nullable. Auto-generated from body if not provided. |
| featured_image_path | text | nullable. Supabase Storage path. |
| status | text | `draft`, `published` |
| published_at | timestamptz | nullable. Set when status changes to published. |
| is_featured | boolean | default false. Pinned to homepage. |
| created_at | timestamptz | |
| updated_at | timestamptz | |
| deleted_at | timestamptz | nullable |

**Indexes:** `station_id + slug` (unique, where deleted_at is null), `station_id + status + published_at`, `show_id` (where show_id is not null), `station_id + is_featured`.

**Decision:** No categories or tags for v1. Show-scoped posts are the primary organization mechanism. If needed later, add a `post_tags` junction table.

---

## Pages (Evergreen Content)

### `pages`

Static content pages: About, Contact, How to Listen, Volunteer, FCC Public File, etc.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| station_id | uuid FK → stations | |
| parent_id | uuid FK → pages | nullable. For nested hierarchy: `/about/history`, `/about/staff`. |
| title | text | |
| slug | text | |
| body | text | Rich text (HTML). |
| meta_title | text | nullable. Auto-generated from title if not set. |
| meta_description | text | nullable. |
| sort_order | integer | For ordering in navigation. |
| is_published | boolean | default true |
| created_at | timestamptz | |
| updated_at | timestamptz | |
| deleted_at | timestamptz | nullable |

**Indexes:** `station_id + slug` (unique, where deleted_at is null), `parent_id`, `station_id + is_published`.

**Full path computation:** Slug path is computed at query time by walking `parent_id` chain. No denormalized `path` column — the hierarchy is shallow (max 2 levels) so the join is trivial.

---

## Events (CMS-Native)

### `cms_events`

Community events, sponsored events, protests, meetings — anything where KPFK doesn't sell tickets. KPFK-produced ticketed events come from Beacon API and are NOT stored here.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| station_id | uuid FK → stations | |
| title | text | |
| slug | text | |
| description | text | Rich text (HTML). |
| category | text | `community`, `sponsored`, `fundraising`, `meeting`, `protest`, `other` |
| venue_name | text | nullable. Free text — no full venue management needed. |
| venue_address | text | nullable. |
| event_url | text | nullable. Link to external site (Ticketmaster, organizer page, etc.). |
| image_path | text | nullable. Supabase Storage path. |
| price_text | text | nullable. Free text: "$40-$172", "Free", "Sliding scale $10-$50". |
| starts_at | timestamptz | |
| ends_at | timestamptz | nullable. |
| is_all_day | boolean | default false |
| is_highlighted | boolean | default false. Featured on events homepage. |
| created_by | uuid FK → profiles | |
| created_at | timestamptz | |
| updated_at | timestamptz | |
| deleted_at | timestamptz | nullable |

**Indexes:** `station_id + slug` (unique, where deleted_at is null), `station_id + category`, `station_id + starts_at` (where deleted_at is null), `station_id + is_highlighted`.

**Note:** The public events calendar merges these with Beacon events (fetched via API) into a unified feed. The frontend handles the merge — no data duplication.

---

## Schedule

### `schedule_slots`

The 24/7 weekly grid. Phase 1: manually managed. Phase 2: populated from Confessor. Phase 3: writes back to Confessor.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| station_id | uuid FK → stations | |
| show_id | uuid FK → shows | nullable. Can be a generic slot like "Something's Happening" without a show page. |
| day_of_week | smallint | 0 = Sunday, 6 = Saturday |
| start_time | time | Local time (station timezone). |
| end_time | time | Local time. |
| label | text | nullable. Override display name for this slot (e.g., "Something's Happening A Hour 1 honoring Roy Of Hollywood"). |
| is_recurring | boolean | default true. Template slot vs. one-off override. |
| effective_date | date | nullable. For one-off overrides: the specific date this slot applies to. |
| expires_date | date | nullable. For one-off overrides: when the override ends. |
| confessor_synced | boolean | default false. True if this slot was pulled from Confessor. |
| created_at | timestamptz | |
| updated_at | timestamptz | |

**Indexes:** `station_id + day_of_week + start_time`, `station_id + effective_date` (where effective_date is not null), `show_id`.

**Schedule resolution logic (application layer):**
1. Check for a one-off override matching the specific date.
2. Fall back to the recurring template slot for that day/time.
3. If `show_id` is set, link to the show page. If only `label` is set, display as plain text.

---

## Contact Forms & Submissions

### `contact_submissions`

All contact form submissions. Forms are system-generated per show (no form builder needed).

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| station_id | uuid FK → stations | |
| show_id | uuid FK → shows | nullable. Null = general station contact form. |
| sender_name | text | |
| sender_email | text | |
| subject | text | |
| message | text | |
| ip_address | inet | nullable. For anti-abuse. |
| turnstile_token | text | nullable. Cloudflare Turnstile validation token. |
| emailed_to | text[] | Array of email addresses the submission was forwarded to. |
| created_at | timestamptz | |

**Indexes:** `station_id + created_at`, `show_id` (where show_id is not null).

**No soft delete.** Submissions are append-only. Add a retention policy later if needed.

---

## Media Library

### `media`

Metadata for files stored in Supabase Storage. The actual files live in storage buckets — this table tracks metadata, usage, and provides searchability.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| station_id | uuid FK → stations | |
| storage_path | text | Path in Supabase Storage bucket. |
| filename | text | Original upload filename. |
| alt_text | text | nullable. |
| mime_type | text | `image/jpeg`, `image/png`, `image/webp`, `application/pdf`, etc. |
| size_bytes | bigint | |
| width | integer | nullable. For images. |
| height | integer | nullable. For images. |
| tags | text[] | Searchable tags. |
| uploaded_by | uuid FK → profiles | |
| created_at | timestamptz | |

**Indexes:** `station_id + created_at`, `station_id + mime_type`, `tags` (GIN index for array search).

**Storage bucket structure:** `{station_id}/shows/`, `{station_id}/posts/`, `{station_id}/events/`, `{station_id}/pages/`, `{station_id}/sponsorship/`, `{station_id}/general/`.

**Image processing:** On upload, generate WebP variants at standard breakpoints (thumbnail: 200px, medium: 600px, large: 1200px, original). Store all variants in storage; the `media` row references the original, and variants follow a naming convention: `{path}_thumb.webp`, `{path}_medium.webp`, `{path}_large.webp`.

---

## Sponsorship Display

### `sponsorship_placements`

Defines where sponsored/promotional content can appear on the site.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| station_id | uuid FK → stations | |
| zone | text | `homepage_hero`, `homepage_sidebar`, `show_page_banner`, `show_page_sidebar`, `archive_banner`, `blog_interstitial`, `sitewide_banner` |
| name | text | Human-readable: "Homepage Hero Carousel", "Show Page Sidebar" |
| max_items | integer | Max creatives in rotation for this zone. |
| is_active | boolean | default true |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### `sponsorship_creatives`

Individual creative assets assigned to placement zones.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| station_id | uuid FK → stations | |
| placement_id | uuid FK → sponsorship_placements | |
| title | text | Internal name: "Bob Marley One Love Banner" |
| creative_type | text | `image`, `html` |
| image_path | text | nullable. Supabase Storage path (for image type). |
| html_content | text | nullable. HTML snippet (for html type). |
| click_url | text | nullable. Destination URL on click. |
| alt_text | text | nullable. |
| weight | integer | default 1. Higher weight = more frequent in rotation. |
| is_pinned | boolean | default false. Pinned items always show in a fixed position. |
| pin_position | integer | nullable. Position index if pinned. |
| starts_at | timestamptz | nullable. Scheduled start. |
| ends_at | timestamptz | nullable. Scheduled end. |
| is_active | boolean | default true |
| created_by | uuid FK → profiles | |
| created_at | timestamptz | |
| updated_at | timestamptz | |
| deleted_at | timestamptz | nullable |

**Indexes:** `placement_id + is_active`, `station_id + starts_at + ends_at`.

### `sponsorship_impressions`

Lightweight impression and click tracking. Aggregated, not per-pageview.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| creative_id | uuid FK → sponsorship_creatives | |
| date | date | Aggregation date. |
| impressions | bigint | default 0 |
| clicks | bigint | default 0 |
| constraint | | unique(creative_id, date) |

**Indexes:** `creative_id + date` (unique).

**Tracking approach:** Impressions increment via a lightweight API call when a creative renders. Clicks tracked via a redirect endpoint. Aggregated daily — no per-user tracking, consistent with privacy-first analytics approach.

---

## Newsletter & Subscribers

### `newsletter_subscribers`

Email subscribers for station and show-specific newsletters.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| station_id | uuid FK → stations | |
| email | text | |
| email_normalized | text | Lowercased, trimmed. |
| name | text | nullable. |
| status | text | `active`, `unsubscribed`, `bounced` |
| subscribed_at | timestamptz | |
| unsubscribed_at | timestamptz | nullable |
| created_at | timestamptz | |
| updated_at | timestamptz | |

**Indexes:** `station_id + email_normalized` (unique), `station_id + status`.

### `newsletter_subscriptions`

Which newsletters/shows a subscriber is opted into.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| subscriber_id | uuid FK → newsletter_subscribers | |
| show_id | uuid FK → shows | nullable. Null = general station newsletter. |
| is_active | boolean | default true |
| created_at | timestamptz | |
| updated_at | timestamptz | |

**Indexes:** `subscriber_id`, `show_id`.

---

## Flags / Bug Reports

### `flags`

Lightweight issue reporting from any authenticated page.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| station_id | uuid FK → stations | |
| reporter_id | uuid FK → profiles | |
| url | text | Page URL where the flag was submitted. |
| message | text | nullable. Optional description from user. |
| user_agent | text | nullable. |
| status | text | `open`, `resolved`, `dismissed` |
| resolved_by | uuid FK → profiles | nullable. |
| resolved_at | timestamptz | nullable. |
| created_at | timestamptz | |

**Indexes:** `station_id + status`, `station_id + created_at`.

---

## Audit Log

### `cms_audit_log`

Field-level change tracking. Same pattern as Beacon's `audit_log`.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| station_id | uuid FK → stations | |
| user_id | uuid | nullable. |
| action | text | `create`, `update`, `delete` |
| table_name | text | |
| record_id | uuid | nullable. |
| old_data | jsonb | nullable. |
| new_data | jsonb | nullable. |
| ip_address | inet | nullable. |
| created_at | timestamptz | |

**Indexes:** Same pattern as Beacon — `table_name + record_id`, `user_id + created_at`, `table_name + created_at`.

---

## Tables NOT in This Schema

These are explicitly out of scope for the CMS database:

| Data | Where It Lives | How CMS Accesses It |
|------|---------------|-------------------|
| Donations, memberships, donor data | Beacon | Public API |
| Ticketed events (KPFK-produced) | Beacon | Public API |
| Campaign stats, thermometers | Beacon | Public API |
| Sponsorship accounts & agreements | Beacon | API (post-sponsorship module) |
| Broadcast schedule (canonical) | Confessor | Read API |
| Audio files, stream URLs | Confessor | Read API |
| Episode list (audio data) | Confessor | Read API |
| Now playing / up next | Confessor | Read API |
| Listener/streaming stats | stats.pacifica.org | TBD |

---

## Migration Notes for Claude Code

1. **Follow Beacon's migration numbering pattern.** Sequential, zero-padded: `001_initial_schema.sql`, `002_add_shows.sql`, etc.
2. **Create the `update_updated_at()` function first** — same as Beacon. Apply trigger to all tables with `updated_at`.
3. **RLS policies:** Admin routes will likely use service role client (same as Beacon). Host routes need RLS: hosts can only read/write shows where they have a `show_hosts` record with their `profile_id`. Editors can read/write all content. Admins can do everything.
4. **Seed data:** Create the KPFK station row. Seed the sponsorship placement zones. Import scraped show data into `shows` and `show_hosts` tables (with `is_claimed = false`, `profile_id = null`).
5. **The `shows.program_slug` must match Beacon's `programs.slug`** for Confessor integration to work. Verify slugs match during seed import.
6. **`episode_metadata` is purely CMS-owned data.** Confessor provides the audio; this table provides the rich metadata. They join on `program_slug + air_date` at the application layer, not via foreign keys (since Confessor data isn't in this database).
7. **Storage bucket names** should be created as part of the migration or setup script. One bucket per content type, or one bucket with path-based organization — decide at implementation time.

---

## Table Count Summary

| Category | Tables | Count |
|----------|--------|-------|
| Auth & Config | stations, profiles | 2 |
| Shows | shows, show_hosts | 2 |
| Episodes | episode_metadata | 1 |
| Content | posts, pages | 2 |
| Events | cms_events | 1 |
| Schedule | schedule_slots | 1 |
| Contact | contact_submissions | 1 |
| Media | media | 1 |
| Sponsorship | sponsorship_placements, sponsorship_creatives, sponsorship_impressions | 3 |
| Newsletter | newsletter_subscribers, newsletter_subscriptions | 2 |
| Utility | flags, cms_audit_log | 2 |
| **Total** | | **18** |
