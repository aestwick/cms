# Legacy Systems Documentation

## Overview

KPFK's broadcast infrastructure runs on two interconnected PHP systems — **Confessor** and **Archive** — that manage show scheduling, playlists, now-playing data, and on-demand audio. These are Pacifica-wide systems used across multiple stations (KPFK, KPFT, WPFW, etc.), not KPFK-specific. They were built long before Beacon and continue to run in production.

**Beacon (this project)** replaces the **donation/membership** system ("Otis"), not the broadcast systems. Confessor and Archive remain the source of truth for show schedules and audio archives. Beacon needs to read from them — never write to them.

### Why This Matters for Beacon

- **Show/program data**: During fund drives, donations are linked to the show that was airing when the pledge came in. Confessor knows what's on the air right now.
- **"Now Playing" widget**: The donate page can show what's currently on air to encourage giving during a listener's favorite show.
- **Program slugs**: Beacon's `programs` table stores `slug` values that correspond to Confessor's `sh_altid` (the short identifier for each show). This is the bridge between the two systems.
- **Archive links**: Donors may want to hear past episodes of shows they support. Archive provides the MP3 URLs.

---

## System Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Pacifica Network                        │
│                                                            │
│  ┌─────────────────┐         ┌──────────────────┐         │
│  │   Confessor      │         │    Archive        │         │
│  │ (Show Schedules) │◄───────►│ (Audio Files/MP3) │         │
│  │                  │         │                   │         │
│  │ confessor.kpfk.org│        │ archive.kpfk.org  │         │
│  └────────┬─────────┘         └────────┬──────────┘         │
│           │                            │                    │
│           │  HTTP API (GET requests)   │                    │
│           │  _nu_do_api.php            │                    │
│           │                            │                    │
│  ┌────────▼────────────────────────────▼──────────┐        │
│  │              Shared MySQL Database              │        │
│  │  Tables: shows, headers, playlists, filnam,     │        │
│  │  shoname, pubfile, categories, global, weeks,   │        │
│  │  confessors, users                              │        │
│  └─────────────────────────────────────────────────┘        │
│                                                             │
│  ┌─────────────────────────────────────────────────┐        │
│  │         Beacon (This Project)                    │        │
│  │                                                  │        │
│  │  donate.kpfk.org / admin.kpfk.org               │        │
│  │  Reads from Confessor API for:                   │        │
│  │  - What show is on air now                       │        │
│  │  - Show list for dropdowns                       │        │
│  │  - Auto-linking donations to current show        │        │
│  └──────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

---

## Confessor (confessor.kpfk.org)

### What It Does

Confessor is the **show schedule manager**. It knows every show on the station — what day/time it airs, who hosts it, what category it falls under (talk, music, etc.), and when each episode was broadcast. It also manages playlists (the track-by-track log of what played during a show).

Think of it as the station's master calendar.

### Base URL

```
https://confessor.kpfk.org
```

### API Endpoint

All requests go to a single PHP file:

```
https://confessor.kpfk.org/_nu_do_api.php?req=<action>&<params>
```

(The older version `_do_api.php` exists too — `_nu_do_api.php` is the current one with CORS headers and JSON support.)

### Response Format

Responses come in two formats depending on the `json` parameter:

- **Default (no `json` param)**: PHP serialized array, base64-encoded. You'd need to `base64_decode()` then `unserialize()` the response. This is the legacy format.
- **With `&json=1`**: Standard JSON. **This is what Beacon should use.**

### API Endpoints Reference

Every endpoint accepts an optional `&json=1` parameter for JSON output.

#### Schedule & Show Lookup

| Endpoint | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `?req=getshows` | Get all shows with their scheduled times | `&before=N&after=N` (weeks, default 1) | Array keyed by day number (0-6), shows in time order |
| `?req=getday` | Get all shows for a specific day | `&day=N` (0=Sunday through 6=Saturday) | Array of shows in start-time order |
| `?req=getshow` | Get show airing at a specific time | `&dte=<unix_timestamp>` (optional, defaults to now) | Single show object |
| `?req=getnext` | Get the next show after a time | `&dte=<unix_timestamp>` (optional) | Single show object |
| `?req=getcurrent` | Get current + next show | `&dte=<unix_timestamp>` (optional) | `{ current: {...}, next: {...} }` |
| `?req=getalfa` | Get all shows alphabetically | none | Array of shows sorted A-Z |
| `?req=getary` | Get shows organized by time slot | none | Array of shows grouped by time |
| `?req=key` | Get a specific show by its altid | `&key=<altid>` | Single show object |
| `?req=getgone` | Get discontinued/retired shows | none | Array of shows with `sh_gone` flag |
| `?req=list` | Get a flat list of shows | none | Flat array of shows |
| `?req=altids` | Get all show altid (slug) values | none | Array of altid strings |
| `?req=memsys` | Get membership system IDs | none | Array mapping shows to membership system IDs |
| `?req=shotimes` | Get all scheduled times for a show | `&key=<altid>` | Array of date/time entries |
| `?req=show` | Get a show by numeric ID | `&id=<integer>` | Single show object |

#### Now Playing

| Endpoint | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `?req=getnow` | Get currently playing song/track | `&time=<unix_timestamp>` (optional) | `{ pl_artist, pl_song, pl_album, pl_label }` |
| `?req=nowshow` | Get currently airing show (full detail) | none | Show object with remaining time |
| `?req=nowshort` | Get currently airing show (short) | none | Abbreviated show object |
| `?req=nowary` | Get now-playing as structured array | none | Structured now-playing data |

#### Playlists

| Endpoint | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `?req=playlist` | Get a playlist | `&phid=<header_id>` OR `&date=<datestring>` OR `&dt=<datestring>&key=<altid>` | Playlist with track entries |
| `?req=all` | Get all playlists for a show | `&key=<altid>` | Array of playlists |
| `?req=mostrecent` | Get most recent playlist for a show | `&altid=<altid>` | Single playlist |

#### Schedule/Special Programming

| Endpoint | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `?req=sched` | Get schedule for a date range | `&stdte=<unix_ts>&endte=<unix_ts>` OR `&wks=<weeks_back>` + optional `&plistid=<id>` | Schedule entries |
| `?req=special` | Get special programming schedule | Same as sched | Special programming entries |
| `?req=jsched` | Get schedule as pre-built JSON | none | Pre-generated JSON schedule with day folding |

#### Fund Drive

| Endpoint | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `?req=pledge` | Get current pledge/drive info | none | Pledge configuration for on-air |

### Show Object Structure

When you get a show back from any endpoint, here are the key fields:

```json
{
  "sh_id": 24,                          // Internal numeric ID
  "sh_altid": "dnpm",                   // Short slug identifier — THIS MAPS TO BEACON'S programs.slug
  "sh_name": "Democracy Now! PM",       // Display name
  "sh_desc": "",                         // Description (often empty)
  "sh_djname": "Amy Goodman",           // Host name
  "sh_email": "",                        // Host/show email
  "sh_url": "",                          // Show website
  "sh_photo": "democracy_now_24.jpg",   // Photo filename (relative to confessor pix URL)
  "sh_med_photo": "",                    // Medium-sized photo
  "sh_facebook": "",                     // Social media links
  "sh_twitter": "",
  "sh_tumblr": "",
  "sh_memsysid": "xxy",                 // External membership system ID
  "sh_info": 16446,                      // Bit flags (see sh_info Flags section below)
  "sh_shour": 61200,                     // Start time in seconds since midnight
  "sh_stime": "17:00:00",               // Start time formatted
  "sh_ampm": "5:00 PM",                 // Start time AM/PM
  "sh_days": "Mon Tue Wed Thu Fri",     // Days it airs (short)
  "sh_big_days": "Monday Tuesday...",   // Days it airs (long)
  "sh_ends": "18:00:00",                // End time formatted
  "sh_ampm_ends": "6:00 PM",            // End time AM/PM
  "sh_len": 3600,                        // Duration in seconds
  "sh_start_time": 1365199200,          // Unix timestamp of first airing
  "sh_plistid": "kpfk",                 // Which confessor/station this show belongs to
  "ca_name": "Public Affairs",          // Category name
  "ca_color": "#ffffff",                // Category text color (for schedule display)
  "ca_bgcolor": "#336699"               // Category background color
}
```

### sh_info Bit Flags

The `sh_info` field is a bitmask with the following flags (defined in `sh_infos.php`):

| Flag | Hex | Meaning |
|------|-----|---------|
| `sh_download` | 0x01 | Show is available for download |
| `sh_pod` | 0x02 | Show is available as podcast |
| `sh_delete_file` | 0x04 | Auto-delete audio files |
| `sh_invisible` | 0x08 | Hidden from public schedule |
| `sh_shohost` | 0x10 | Display host name |
| `sh_shodesc` | 0x20 | Display show description |
| `sh_pitch` | 0x40 | Show does fund drive pitching |
| `sh_upload` | 0x80 | Upload enabled |
| `sh_tone` | 0x100 | Has tone marker |
| `sh_unsched` | 0x200 | Unscheduled/special programming |
| `sh_no_overlap` | 0x400 | No overlapping with adjacent shows |
| `sh_copysafe` | 0x800 | Copyright-safe content |
| `sh_private` | 0x1000 | Private/restricted content |
| `sh_shonow` | 0x2000 | Show immediately (no delay) |
| `sh_talk` | 0x4000 | Talk show (vs music) |
| `sh_gone` | 0x8000 | Show is discontinued |
| `sh_norecord` | 0x10000 | Do not record/archive |
| `sh_nopledge` | 0x20000 | No pledging during this show |
| `sh_duptitle` | 0x40000 | Duplicate title allowed |
| `sh_customurl` | 0x80000 | Has a custom URL |
| `sh_waitnoise` | 0x100000 | Wait for noise detection |

**Flags relevant to Beacon:**
- `sh_gone` (0x8000): Filter out discontinued shows from dropdowns
- `sh_nopledge` (0x20000): If set, this show does NOT accept pledges during its airing — Beacon should not auto-link donations to it
- `sh_talk` (0x4000): Useful for categorization (talk vs. music shows)
- `sh_pitch` (0x40): Show participates in fund drives

---

## Archive (archive.kpfk.org)

### What It Does

Archive is the **audio file manager**. It stores recorded episodes as MP3 files and metadata about each recording — when it aired, how long it is, when it expires, what topics/guests were covered.

Think of it as the station's episode library.

### Base URL

```
https://archive.kpfk.org
```

### How Audio Files Are Accessed

Archive MP3s follow this naming convention:

```
https://archive.kpfk.org/mp3/kpfk_YYMMDD_HHMMSSaltid.mp3
```

For example:
```
https://archive.kpfk.org/mp3/kpfk_220904_100000someshow.mp3
```

Where:
- `kpfk` = station call letters
- `YYMMDD` = date (year-month-day)
- `HHMMSS` = time (hour-minute-second, in seconds since midnight)
- `altid` = the show's short slug

### Archive API Endpoint

Archive files are retrieved through the Confessor API:

```
https://confessor.kpfk.org/_nu_do_api.php?req=fil&id=<altid>&num=<count>&json=1
```

| Parameter | Description |
|-----------|-------------|
| `id` | Show's altid/slug (e.g., `dnpm` for Democracy Now PM) |
| `num` | Number of recent episodes to return (default 5, 0 = all) |

### Archive Entry Object Structure

```json
{
  "pubfile": [
    {
      "pf_host": "Amy Goodman",
      "pf_gname": "Noam Chomsky",
      "pf_gtopic": "US Foreign Policy",
      "pf_gurl": "",
      "pf_issue1": "International Affairs",
      "pf_issue2": "Politics",
      "pf_issue3": "",
      "pf_notes": ""
    }
  ],
  "idkey": "dnpm",
  "title": "Democracy Now! PM",
  "days": 60,
  "category": "Public Affairs",
  "producer": "Democracy Now!",
  "link": "",
  "mp3": "https://archive.kpfk.org/mp3/kpfk_230101_170000dnpm.mp3",
  "day": "Monday",
  "date": "January 1, 2023",
  "def_time": 1672596000,
  "expires": 1677780000,
  "txt": "",
  "lsecs": 3600,
  "length": "1:00:00"
}
```

Key fields:
- `idkey`: The show slug (matches `sh_altid` in Confessor, `slug` in Beacon's `programs` table)
- `mp3`: Direct URL to the audio file
- `def_time`: Unix timestamp of when the show aired
- `expires`: Unix timestamp after which the audio is no longer available
- `days`: Number of days the recording stays available
- `lsecs`: Duration of the recording in seconds
- `pubfile`: Array of guest/topic metadata per segment (talk shows)

---

## Database Schema (Legacy MySQL)

The legacy system uses a shared MySQL database with the following key tables. These are **not** in Beacon's Supabase — they live on the Confessor/Archive server.

### Confessor Tables (Schedule)

| Table | Prefix | Purpose |
|-------|--------|---------|
| `shows` (sh_table) | `sh_` | Show definitions (name, host, category, flags) |
| `headers` (ph_table) | `ph_` | Scheduled time slots — one row per show-airing |
| `playlists` (pl_table) | `pl_` | Track entries within a show's playlist |
| `pubfile` (pf_table) | `pf_` | Guest/topic metadata per episode segment |
| `categories` (ca_table) | `ca_` | Show categories (Talk, Music, Public Affairs, etc.) |
| `global` (gl_table) | `gl_` | Station-wide settings (pix URLs, defaults) |
| `weeks` (wk_table) | `wk_` | Week templates for schedule management |

### Archive Tables (Audio Files)

| Table | Prefix | Purpose |
|-------|--------|---------|
| `filnam` (fn_table) | — | Audio file records (path, duration, expiry, topics) |
| `shoname` (sn_table) | `sn_` | Archive-only show definitions (shows without a Confessor entry) |
| `confessors` (cf_table) | `cf_` | Registry of Confessor instances (multi-station support) |

### Users Table

| Table | Prefix | Purpose |
|-------|--------|---------|
| `users` (u_table) | `u_` | Staff logins for Confessor admin (separate from Beacon auth) |
| `showlogins` (sl_table) | `sl_` | Maps users to shows they can manage |

### Key Relationships

- `shows.sh_altid` ↔ `headers.ph_shaltid` — Which show each time slot belongs to
- `shows.sh_caid` ↔ `categories.ca_id` — Show's category
- `filnam.idkey` ↔ `shows.sh_altid` — Archive recordings linked to shows
- `filnam.def_time` ↔ `headers.ph_date` — Recording tied to specific airing
- `pubfile.pf_idkey` + `pf_schedtime` ↔ Episode guest/topic info

### The "Confessors" Concept

The `confessors` table (`cf_table`) is a registry of Confessor instances. Pacifica has multiple stations sharing one Archive server, each with its own Confessor database. The `cf_plistid` field (e.g., `"kpfk"`) identifies which station a show belongs to.

Key `cf_info` flags:
- `cf_noncf` (0x01): Archive-only show (not managed by Confessor)
- `cf_signal` (0x04): "Signal" Confessor — the primary one for this station
- `cf_scheduled` (0x10): Has scheduled programming
- `cf_upload` (0x02): Upload-enabled

---

## Legacy User Roles

The old system uses a simple bit-flag role model (defined in `pl_config_defines.php`):

| Flag | Hex | Role | Access |
|------|-----|------|--------|
| `u_updater` | 0x01 | Updater | Can modify playlists |
| `u_root` | 0x02 | Root | Full access within own station |
| `u_rootroot` | 0x04 | Root Root | Can create root users |
| `u_superroot` | 0x08 | Super Root | Cross-station access, can create any user |

These are **completely separate** from Beacon's roles (`super_admin`, `admin`, `ops`, `volunteer`, `donor`). Legacy auth uses cookie-based sessions with a hash check; Beacon uses Supabase Auth with magic links.

---

## The Bridge: `sh_altid` ↔ Beacon's `programs.slug`

The critical integration point between Confessor and Beacon is the **show slug** (also called `altid` or `idkey`):

| System | Field | Example |
|--------|-------|---------|
| Confessor | `sh_altid` | `"dnpm"` |
| Archive | `idkey` | `"dnpm"` |
| Beacon | `programs.slug` | `"dnpm"` |

When Beacon's `programs` table was populated (migration 009), the slugs were designed to match Confessor's `sh_altid` values. This means:

1. Beacon can call `?req=getcurrent&json=1` to find what show is on air
2. The response includes `sh_altid`
3. Beacon looks up that slug in its `programs` table to find the UUID
4. That UUID gets attached to the donation as `show_id`

Per the settings module spec: *"Program slugs are only used by the external archive/confessor system where they function as UUIDs. Auto-generate on creation, never show in UI."*

---

## Legacy Donation Form (Static HTML)

The `legacy/` folder also contains a static HTML donation form that predates Beacon's Next.js implementation:

### Files

| File | Purpose |
|------|---------|
| `index.html` (86 KB) | Main donation page — multi-step form with gift selection |
| `pledge.html` (35 KB) | Phone pledge form for operators |
| `success.html` (7 KB) | Post-donation confirmation |
| `cancel.html` (10 KB) | Cancelled/abandoned donation page |
| `gifts.js` (12 KB) | Gift catalog data (names, images, min amounts, sizes, categories) |
| `programs.js` (1.7 KB) | Show list for the attribution dropdown |
| `styles.css` (42 KB) | Shared stylesheet |
| `images/` (2.8 MB) | 28 images — gift photos, logos, bumper stickers |

### Gift Categories in Legacy Form

The static form organized gifts into:
- **Merch**: Bumper stickers, t-shirts, totes, coffee, grocery bags
- **Books**: Political/social titles by featured authors
- **Music**: CDs, box sets, magazine subscriptions, archive access links
- **Events**: Concert tickets, meet-and-greets, courses, therapy sessions

Each gift had `monthlyMin` and `onetimeMin` thresholds — the minimum donation amount to qualify for that gift. This concept carries forward to Beacon's `gifts.min_cents` field.

### What Beacon Replaced

The static HTML form handled:
- Amount selection with min/max validation
- Gift browsing and selection with size/variant picking
- Show attribution ("I'm donating because of this show")
- One-time vs. monthly donation toggle
- Shipping address collection for physical gifts

All of this is now in Beacon's Next.js frontend. The legacy files are kept for reference only.

---

## How Beacon Should Interact with Confessor/Archive

### Read-Only Integration

Beacon should **only read** from these systems. All mutations (schedule changes, playlist updates, file management) happen through Confessor's admin interface.

### Recommended Endpoints for Beacon

For the immediate needs of the donation platform:

| Need | Endpoint | Notes |
|------|----------|-------|
| What's on air now | `?req=getcurrent&json=1` | Returns current + next show. Use `sh_altid` to look up program in Beacon. |
| Full show list | `?req=getshows&before=1&after=1&json=1` | For dropdowns. Filter out `sh_gone` (0x8000) and `sh_invisible` (0x08) shows. |
| Show by slug | `?req=key&key=<altid>&json=1` | Look up a specific show's details. |
| Now-playing song | `?req=getnow&json=1` | For music shows — returns artist/song/album. |
| Recent episodes | `?req=fil&id=<altid>&num=5&json=1` | Get archive MP3 links for a show. |
| Weekly schedule | `?req=getday&day=<0-6>&json=1` | Build a "this week on KPFK" widget. |

### Implementation Considerations

1. **Always use `&json=1`** — the default base64+serialize format is a PHP-ism that's painful in TypeScript.

2. **Cache aggressively** — show schedules change weekly at most. Cache the full show list for at least an hour. Cache "now playing" for 30-60 seconds.

3. **Graceful degradation** — if Confessor is down, Beacon should still work. Donations can be recorded without a show link. The `programs` table in Beacon has its own show list as a fallback.

4. **No auth required** — the Confessor API endpoints used here are public (no login needed). The `_nu_do_api.php` file has CORS headers allowing all origins.

5. **The `sh_nopledge` flag** — some shows have this set (0x20000 in `sh_info`). If the currently airing show has this flag, don't auto-link donations to it. This typically applies to syndicated content where the local station can't pitch for donations.

6. **Time handling** — Confessor uses Unix timestamps everywhere and the station's local timezone (`America/Los_Angeles`). Convert to/from as needed. Beacon already stores this timezone in `STATION_INFO`.

7. **The `plistid`** — when querying schedule or special programming, the `plistid` parameter identifies which Confessor instance (station) to query. For KPFK, this is `"kpfk"`. You generally don't need to pass it unless the endpoint requires it.

### Environment Variables Needed

When integrating, add these to Beacon's `.env`:

```
CONFESSOR_API_URL=https://confessor.kpfk.org/_nu_do_api.php
ARCHIVE_BASE_URL=https://archive.kpfk.org
```

### Potential API Wrapper (Future)

A thin TypeScript wrapper in `src/lib/confessor.ts` could look like:

```typescript
// Conceptual — not yet implemented
async function getCurrentShow(): Promise<ConfessorShow | null>
async function getShowBySlug(altid: string): Promise<ConfessorShow | null>
async function getShowList(): Promise<ConfessorShow[]>
async function getNowPlaying(): Promise<NowPlaying | null>
async function getRecentEpisodes(altid: string, count?: number): Promise<ArchiveEntry[]>
async function getDaySchedule(day: number): Promise<ConfessorShow[]>
```

---

## Legacy PHP File Index

Quick reference for what each PHP file in the `legacy/` folder does:

| File | Purpose |
|------|---------|
| `confessor_api.php` | Client library (generic station) — functions that call the Confessor API via HTTP |
| `confessor_api.inc.php` | Older version of the client library (KPFT-specific) |
| `php:nu_confessor_api.php` | KPFK-specific version of the client library, points to `confessor.kpfk.org` |
| `_do_api.php` | Server-side API handler (older version) — processes `?req=` requests |
| `_nu_do_api.php` | Server-side API handler (current) — with CORS + JSON support |
| `Shows.php` | PHP class hierarchy for managing show data: `Shows` → `Scheds` → `OneShow` → `CurrentShows` → `Podcasts` |
| `pub_sched.php` | Public schedule page renderer (weekly grid layout) |
| `pub_sched.sav.php` | Backup of schedule page |
| `pub_sched_141220.php` | Historical schedule page from December 2014 |
| `pl_config.php` | Main configuration — HTTPS handling, session management, auth functions |
| `pl_config1.php` | Lightweight config for non-authenticated pages |
| `pl_config_defines.php` | All constant definitions — bit flags, role masks, time units |
| `sh_infos.php` | Show info bit flag definitions (`sh_download`, `sh_pod`, `sh_gone`, etc.) |

---

## Glossary

| Term | Meaning |
|------|---------|
| **altid** / **idkey** | Short slug for a show (e.g., `"dnpm"` for Democracy Now PM). The universal identifier across Confessor, Archive, and Beacon. |
| **plistid** | Identifies which Confessor database/station a show belongs to (e.g., `"kpfk"`). |
| **ph_date** | Unix timestamp of a scheduled show header (when it airs). |
| **sh_shour** | Start time as seconds since midnight (e.g., 61200 = 5:00 PM). |
| **sh_len** | Show duration in seconds (e.g., 3600 = 1 hour). |
| **def_time** | The canonical air date/time of an archive recording (Unix timestamp). |
| **filnam** | An audio file record in the archive database. |
| **pubfile** | Guest/topic metadata attached to a specific episode (talk shows). |
| **ph_id** | Header ID — numeric identifier for a specific scheduled slot. |
| **sh_info** | Bitmask field on shows — encodes download, podcast, visibility, pledge, and other flags. |
| **gone show** | A show that's been discontinued (`sh_gone` flag set). |
| **signal confessor** | The primary Confessor instance for a station (vs. secondary/networked ones). |
| **memsysid** | External membership system ID — maps shows to a legacy pledge tracking system. |
| **Otis** | The old donation/membership PHP system that Beacon replaces. Separate from Confessor/Archive. |
