# Handoff — if you're new, start here

## 10-minute orientation

| Minute | Read | You'll learn |
|---|---|---|
| 0–2 | [`../README.md`](../README.md) | What the app does, quick start |
| 2–4 | [`ARCHITECTURE.md`](ARCHITECTURE.md) (diagram + data flow) | How a digest gets made |
| 4–6 | [`../automation/contracts/`](../automation/contracts/) (the two schemas + examples) | The only things every tool must agree on |
| 6–8 | [`../src/config/app.config.js`](../src/config/app.config.js) and [`../src/services/`](../src/services/) | What's tunable; every DB call in one place |
| 8–10 | [`../supabase/schema.sql`](../supabase/schema.sql) (comments on every column) | Tables, permissions, triggers |

Then skim [`../automation/make/MAKE_SETUP.md`](../automation/make/MAKE_SETUP.md) if you'll touch the automation.

## How to run

```bash
npm install
cp .env.example .env      # fill VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY
npm run dev               # http://localhost:5173
npm run build             # production build in dist/
```

Database: run `supabase/schema.sql`, then `supabase/seed.sql` in the Supabase SQL Editor.
Automation: follow `automation/make/MAKE_SETUP.md`. Without Make the app still works with seed data;
new assets just stay "Generating digest…".

## Where to change what

| I want to… | Change | Notes |
|---|---|---|
| Change the AI model | Make step 4 (`ai_model`) only — the Gemini module's model field is mapped from it | Use an exact model ID; CHANGELOG line |
| Change the AI provider | Make step 4 + replace step 8 module + re-map step 9 | `SWAPPING_TOOLS.md` §1 |
| Change the prompt | New `automation/prompts/digest.vN.md`, Make step 8 + step 4 (`prompt_version`) | Never edit an old version |
| Change the news source / headline count | Make step 4 (`news_source`, `max_headlines`) + step 5 (+ step 6 mapping) | `SWAPPING_TOOLS.md` §2 |
| Change the refresh cooldown | `src/config/app.config.js` → `refresh.cooldownMinutes` | Protects free credits |
| Turn Realtime off | `src/config/app.config.js` → `realtime.enabled` | Reload button still works |
| Change tone colors / labels | `src/config/app.config.js` → `tones`, `labels` | CSS reads them as variables |
| Change form limits (symbol length…) | `src/config/app.config.js` → `form` | DB has a matching `check` for symbol length |
| Change the look | `src/style.css` (tokens at the top) | No UI library |
| Add a DB column | `supabase/schema.sql` (+ `COMMENT ON`), `digest-record.schema.json` if on digests, the service that reads it, the component that shows it | Contract change → CHANGELOG |
| Replace Supabase | `src/lib/supabase.js` + `src/services/*` only | `SWAPPING_TOOLS.md` §4 |
| Replace Make | New workflow + Supabase webhook URL | `SWAPPING_TOOLS.md` §3 |
| Add a page | `src/views/NewView.vue` + `src/router/index.js` | Views call services, never Supabase |

## Code rules (keep them)

- Components and views **never** import Supabase; they call `src/services/`.
- No magic values in components; put them in `src/config/app.config.js`.
- Every service function has JSDoc (inputs/outputs).
- Tool-specific values live in Make step 4, never in the Vue app.
- Comments explain *why*, not *what*.

## Known limitations

- **No authentication.** Anyone with the app URL and anon key can add or delete assets. Fine for a
  demo; add Supabase Auth + per-user RLS before real use.
- **Free tiers:** Make 1,000 credits/month (~140 digests); Gemini free-tier rate limits (429s); Supabase
  free projects pause after ~1 week idle.
- **Google News RSS is unreliable from Make's servers.** During testing it often answered
  `503 Service Unavailable`; the run then stops at RSS with no row written, and the app shows
  "Still waiting" until you Refresh again. Options: add an error handler on the RSS module (like
  M8/M10), or swap the news source (`SWAPPING_TOOLS.md` §2).
- **Gemini model availability changes.** Newer Flash models can be overloaded (`503 high demand`);
  failures are written as `failed` digests. Change `ai_model` in Make step 4 to switch.
- **Empty news search** stops the Make run after RSS (no row written). The app shows "Still waiting
  for the automation" after `refresh.pendingStaleMinutes`; fix the asset's `search_query`.
- **The cooldown is enforced in the UI only.** Someone calling the API directly could bump
  `last_requested_at` repeatedly. A DB check (e.g. a trigger rejecting bumps within N minutes) would close this.
- **Realtime covers digests only.** Assets added/deleted in another tab appear after Reload.
- **Search query can't be edited in the app** after creation (only in Supabase Table Editor) — `anon`
  may update only `last_requested_at` by design.
- **Headlines are titles only**; the AI never reads article bodies, so summaries are headline-level.
- **Router uses HTML5 history.** Static hosts need a fallback to `index.html` (Netlify `_redirects`,
  Vercel rewrites), or switch to `createWebHashHistory` in `src/router/index.js`.

## Open TODOs

- [ ] Export the real Make blueprint to `automation/make/scenario-blueprint.json` (check for secrets).
- [ ] Take the submission screenshots (see README "Submission checklist").
- [ ] Server-side refresh cooldown (trigger) to back up the UI rule.
- [ ] Optional: "Edit search query" via a narrow RPC function.
- [ ] Future work in README: scheduled daily digests, email/Telegram delivery, price data, auth.
