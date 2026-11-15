# Decision records

Short records of why each tool or approach was chosen. Add a new entry (don't rewrite old ones) when
a decision changes; mark the old one *Superseded by #N*.

---

### 1. Vue 3 + Vite (Composition API, `<script setup>`)
- **Why:** required by the course; `<script setup>` keeps components small; Vite builds in under a
  second and needs no config.
- **Trade-offs:** no SSR/SEO (not needed for a private dashboard).

### 2. Supabase for database, permissions, webhook and Realtime
- **Why:** one free service gives Postgres, an auto-generated REST API (`supabase-js`), Row Level
  Security, Database Webhooks (the Make trigger) and Realtime (live digests) — no backend to write.
- **Trade-offs:** free projects **pause after ~1 week of inactivity** (restore from the dashboard);
  public anon key + no auth means anyone with the URL can edit the watchlist. All DB code sits behind
  `src/services/` so it can be replaced.

### 3. Make.com for the automation
- **Why:** required by the course; visual scenarios are easy to demo and screenshot; built-in apps for
  Webhooks, RSS, JSON, Gemini and Supabase; error handlers out of the box.
- **Trade-offs:** 1,000 credits/month on Free (~7 credits per digest ≈ 140 digests); logic lives
  outside the repo, so we keep a written build guide (`MAKE_SETUP.md`) plus an exported blueprint, and
  all tool-specific values in one *Set multiple variables* module.

### 4. Google Gemini (free-tier Flash model) for the briefing
- **Why:** free API key from AI Studio with no billing account; Flash models are fast and good at
  short structured summaries; JSON output mode available.
- **Trade-offs:** strict free-tier rate limits (429s), free-tier data may be used by Google to improve
  products, model IDs get retired. Mitigated by the AI output contract, the error handler, the refresh
  cooldown, and storing `ai_model` on every row.

### 5. Google News RSS for headlines
- **Why:** free, no API key, covers stocks and crypto, simple query URL; Make has a native RSS module.
- **Trade-offs:** unofficial/undocumented, titles only (no article bodies), publisher name must be
  parsed from the title, results vary by region. Swappable via the headline field mapping
  (`docs/SWAPPING_TOOLS.md` §2).

### 6. Refresh via the UPDATE webhook (no extra table)
- **Why:** the Refresh button only bumps `watchlist.last_requested_at`; the same webhook fires on
  UPDATE; Make's filter runs only when that column changed. One scenario, two tables, nothing extra.
  "Pending" = `last_requested_at > latest digest.created_at`.
- **Trade-offs:** no record of who refreshed or how often; any other update to `watchlist` also hits
  the webhook (costs 1 credit, then stops at the filter). A trigger forces server time on
  `last_requested_at` so the pending check never depends on the browser clock.

### 7. No extra libraries
- **Why:** only `vue`, `vue-router`, `@supabase/supabase-js` (+ Vite). Fewer dependencies = fewer
  upgrades, smaller bundle (~40 kB gzipped JS), and nothing to explain to graders or future
  maintainers. Icons are Unicode/inline SVG, styles are plain CSS variables, dates use `Intl`.
- **Trade-offs:** no charts, no component library, no form/validation library — validation is a few
  lines in `AddAssetView.vue`.

### 8. Contracts + traceability columns instead of tool-specific code
- **Why:** the app depends only on the `news_digests` shape; the automation depends only on the two
  JSON Schemas. Each row records `ai_provider`, `ai_model`, `prompt_version`, `news_source`, so a tool
  swap never makes old and new data indistinguishable.
- **Trade-offs:** four extra columns per row; the contract must be updated deliberately when it changes.

### 9. Database normalises JSON arrays (trigger)
- **Why:** automation tools often send `jsonb` columns as text. A `before insert` trigger turns JSON
  text, newline lists or `{"key": [...]}` wrappers into real arrays and fills `headline_count`, so any
  writer produces the same record.
- **Trade-offs:** a little logic in the DB that a reader must know about (documented in `schema.sql`
  and `MAKE_SETUP.md`).

### 13. Navy ground, paper + glass tiles, gold accent (supersedes the palette of #11/#12)
- **Why:** requested a darker, more modern look. The page ground is navy (kon-iro); long-form reading
  stays on solid paper tiles (dark text), while status/navigation tiles are translucent glass with light
  text (`.tile--glass`), which gives the bento grid a visible hierarchy. Navy can no longer be the
  accent on a navy ground, so the accent becomes gold leaf (kin), still a traditional Japanese colour.
  Tiles switch palettes by redefining the same CSS variables (`--ink`, `--line`, …), so components
  didn't change.
- **Update:** the ground is now a mesh gradient (indigo / teal / plum / gold ember) under a fine grid,
  and glass tiles are frosted and mostly opaque, so text never sits on a busy background.
- **Trade-offs:** `backdrop-filter` blur costs a little GPU; badges inside glass tiles keep a paper
  backing so tone colours stay AA-readable.

### 12. Bento layout (supersedes the page-section layout of #11, keeps its palette)
- **Why:** every piece of information becomes its own tile on a 4/2/1-column grid, so grouping and
  hierarchy are visible at a glance (hero 2×2, stat tiles, featured asset tile, detail page split into
  summary / tone / key points / headlines / history). Applies core UI principles: one primary action per
  view, a fixed type and spacing scale, one radius, one icon set (`AppIcon.vue`), explicit states.
  Japanese touches: washi ground, ai-iro indigo, the woodblock wave, seigaiha textures fading into tile
  corners, hanko-like tone stamps, serif-italic accents.
- **Trade-offs:** tiles in a row share a height, so short content (e.g. key points) leaves space — filled
  with a faint seigaiha texture rather than shrinking the grid.

### 11. Modern UI on a Japanese-canvas base (supersedes the light briefing look)
- **Why:** a distinctive portfolio look that still reads as a modern, light product UI. The "canvas"
  comes from Hokusai's *Great Wave*: warm paper, Prussian blue and foam, a woodblock-style hero wave
  (`GreatWave.vue`), thin seigaiha accents and serif italics. Everything else (type, spacing, rounded
  surfaces, pills) is contemporary. Plain CSS + inline SVG only: no images, libraries or web fonts.
  (Violet/space and full ukiyo-e versions were tried and dropped; Japanese characters were removed on
  request.)
- **Trade-offs:** Prussian blue is reserved for UI (buttons, links), so tone colors use other print
  pigments (moss green / warm grey / vermilion) to keep "tone colors only for tone". Fonts are system
  stacks, so the exact look varies slightly by OS.

### 10. *Aggregate to JSON* instead of array aggregator + text aggregator
- **Why:** in Make, a second aggregator after the first sees only one bundle, so it can't build a
  second list from the RSS items. *Aggregate to JSON* produces a correctly escaped JSON array that
  goes straight into both the prompt and the `headlines` column, for 1 credit.
- **Trade-offs:** the AI reads a JSON list instead of a numbered text list (no measurable difference
  for this task).
