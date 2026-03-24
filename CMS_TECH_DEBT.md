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

- [ ] **Confessor API shape undocumented** — The CMS will consume Confessor's API but exact response shapes are not yet confirmed. API client will need updating once real responses are available. Build with flexible parsing that won't break on unexpected fields.
