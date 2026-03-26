# Open Questions — KPFK CMS

Unresolved decisions and questions. Resolved items stay here (struck through) for context.

---

## Resolved

### Confessor API Endpoints
~~What are the exact Confessor API endpoint formats for schedule and episode data?~~

**Resolved 2026-03-26.** Discovered from Aiir snippet reference implementations (`snippets/886_episode-player.html`, `snippets/889_combined-playlsit-viewer.html`). The Confessor API uses a single PHP gateway at `/_nu_do_api.php` with these `req` types:

| `req` value | Parameters | Returns |
|-------------|-----------|---------|
| `fil` | `id={altid}&num=N&json=1` | Episode list with MP3 URLs, dates, durations, guest/topic |
| `key` | `key={altid}&json=1` | Show metadata (name, schedule, photo, host, email) |
| `mostrecent` | `altid={altid}&json=1` | Most recent playlist for a show |
| `shotimes` | `key={altid}&json=1` | Archive dates (phid, date, time, name) |
| `playlist` | `phid={id}&json=1` | Specific playlist by phid |

The `altid` in Confessor maps to `program_slug` in `cms_shows`. Audio URLs follow the pattern `https://archive.kpfk.org/mp3/kpfk_YYMMDD_HHMMSSaltid.mp3`. Some legacy URLs have a `confessor.kpfk.org/home/kpfkarch/public_html/mp3/` prefix that needs to be rewritten.

---

## Open

### Transcript Storage
Where should episode transcripts live? Options:
- In `cms_episode_metadata.transcript` (text column)
- As a URL reference to QIR's `transcripts` table (join on mp3_url or episode identifier)
- Both (CMS column for overrides, QIR as default)

### Segment Markers Schema
What's the exact shape for `cms_episode_metadata.segment_markers`? Current proposal: `[{ start: number, title: string, guest?: string }]`. Needs validation against real use cases.

### Resend Sender Domain
Which Resend domain/sender should CMS emails come from? Probably `cms@kpfk.org` or `noreply@kpfk.org`.

### Staging Auth Gate
Should the staging auth gate be basic auth (htpasswd) or IP whitelist? Beacon uses IP whitelist for pledge.kpfk.org.

### Supabase Storage Bucket
Create a new bucket for CMS media, or use the existing QIR bucket?
