# Changelog

All notable changes to this project. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versions follow [SemVer](https://semver.org/).

Log **tool swaps and prompt versions** here too, so data in `news_digests` can always be matched to
what produced it (e.g. "AI: gemini-2.5-flash → gpt-4o-mini", "Prompt v2: shorter summaries").

## [Unreleased]

### Added
- Make.com scenario built and verified end to end (webhook → filter → variables → Google News RSS → Aggregate to JSON → Gemini → Parse JSON → Supabase insert), with error routes on Gemini and Parse JSON that write `failed` rows. `automation/make/MAKE_SETUP.md` rewritten to match the real build (field names, JSON Output + response schema, `candidates[1].content.parts[1].text` as Parse JSON input, `Skip` directive, measured credit costs, new troubleshooting rows).
- Supabase Database Webhook `watchlist_to_make` (Insert + Update on `public.watchlist`).
- The app accepts `VITE_SUPABASE_PUBLISHABLE_KEY` as well as `VITE_SUPABASE_ANON_KEY`.

### Changed
- Renamed the project **LLM Market News Digest → LLM Market News Sentiment Digest** (app name, header, browser titles, footer, package name, contract `$id`s, README and docs). Database tables, columns, contracts' fields and prompt version are unchanged, so existing data and the Make scenario keep working. The live Make scenario keeps its old name (Make caps names at 30 characters; cosmetic only).
- UI redesigned as a bento layout ("modern × Japanese canvas"): floating header, 2×2 hero tile with the woodblock wave, stat tiles (assets, market-mood bar, latest digest, live/reload), a wide featured asset tile, tone-coloured tile edges; detail page split into header / summary / tone stamp / key points / headlines / history tiles; add-asset page with a live preview tile and a "what happens next" tile. New components `AppIcon`, `SummaryTiles`, `KeyPointList`, `HeadlineList`; removed `IconArrow`, `SummaryBar`.
- Detail page: Key points and Source headlines tiles are now frosted glass; each point and headline is its own smoked-glass row card, points numbered with gold chips (sans, tabular) instead of serif italics.
- Widget finish (home-screen widget style): glass tiles are now clear, milky frosted glass (white tint, 26px blur, brightened backdrop) with a gradient light rim brightest at the top-left and bottom-right; nested controls inside them are darker smoked glass. Solid tiles are opaque white widgets with a soft white rim and deeper shadow. The sticky header is darker smoked glass so it stays readable over white tiles.
- Mesh background: a fixed, slowly drifting mesh gradient (indigo, sea-teal, plum, a gold ember) with a fine grid that fades downward (`body::before/::after`; still under reduced motion). Glass tiles are now frosted and mostly opaque (navy gradient + 22px blur + their own corner glow) instead of near-transparent.
- Theme: navy night ground (kon-iro) instead of cream paper; the old navy UI accent is now gold leaf (kin) — primary buttons, links, focus rings, brand mark, favicon, footer seigaiha. Tiles come in two kinds: solid paper (hero, asset tiles, summary, tone, key points, headlines, form) for reading, and translucent glass with light text (`.tile--glass`: header bar, stat tiles, toolbar, asset header, pending banner, history, preview and steps tiles, empty/error states).
- Cleanup: removed unused `formatDuration()` and the unused `app.tagline` config key.
- AI: `gemini/gemini-2.5-flash` → `gemini/gemini-3.6-flash` (2.5 is no longer offered; `gemini-3.8-flash` returned repeated 503 "high demand" errors). Prompt unchanged (`v1`). The Gemini module's model field is mapped from the `ai_model` variable, so the model is set in one place.
- `seed.sql` demo text no longer contains the phrase that tripped the Supabase SQL Editor's RLS check.
- New visual theme: modern product UI on a Japanese-canvas base. Clean sans display type, rounded surfaces, soft shadows and pill badges, on a warm paper ground with a Prussian-blue/foam palette. The dashboard hero is a woodblock-style SVG wave with a boat and Mt. Fuji (`GreatWave.vue`); thin seigaiha accents on cards and footer; serif italics for the hero accent, asset names and digest text; wave-curl bullets, loader and app mark (`BrandMark.vue`). Refresh cooldown is shown as an arc gauge (`CooldownRing.vue`). Tone colors retuned to print pigments (moss green, warm grey, vermilion) in `app.config.js`. No Japanese characters in the UI. Replaces the original "financial briefing" look (violet/space and full ukiyo-e versions were tried and dropped).

## [0.1.0] – 2026-11-14 — initial build

### Added
- Vue 3 app (Vite, Vue Router, `<script setup>`): Dashboard (`/`), Add asset (`/new`), Asset detail (`/asset/:id`).
- Dashboard: summary bar (assets, tone counts, most recent update), search, Stocks/Crypto filter, responsive card grid, Realtime updates, Reload, loading/empty/error states.
- Add asset form: validation (required, symbol ≤ 10 chars, duplicates), auto-filled search query, success redirect.
- Asset detail: latest digest with tone, summary, key points, linked headlines and "Generated by …" line; Refresh with cooldown; in-page delete confirmation; collapsible previous-digests timeline.
- Services layer (`src/services/`) as the only database access; Supabase client only in `src/lib/supabase.js`; all tunables in `src/config/app.config.js`.
- Supabase schema: `watchlist` (primary) and `news_digests` (supporting), index, comments, column grants, RLS, Realtime, triggers for server-time refresh requests and JSON normalisation. Demo seed data.
- Contracts: `ai-output.schema.json`, `digest-record.schema.json` with examples.
- Prompt `v1` (`automation/prompts/digest.v1.md`).
- Make.com build guide and blueprint placeholder.
- Docs: architecture, swapping tools, decisions, handoff.

### Tools in use
- AI: `gemini` / `gemini-2.5-flash` (free tier) — prompt `v1` (as planned; see Unreleased for the model actually used)
- News: `google_news_rss`
- Automation: Make.com (Free plan)
- Database: Supabase (Free plan)
