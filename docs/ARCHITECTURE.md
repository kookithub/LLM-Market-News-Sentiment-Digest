# Architecture

## In one sentence

The Vue app writes a **watchlist** row; a Supabase **Database Webhook** hands it to a **Make.com**
scenario, which pulls **Google News RSS** headlines, asks **Gemini** for a briefing, and writes a
**news_digests** row that the app picks up through **Realtime**.

## Diagram

```
 ┌──────────────── Browser ────────────────┐
 │  Vue 3 app                              │
 │  views → components                     │
 │     │                                   │
 │     ▼                                   │
 │  services/ (watchlist, digests,         │
 │            realtime)  ── lib/supabase   │
 └─────┬──────────────────────▲────────────┘
       │ insert / update      │ select + Realtime (INSERT on news_digests)
       │ (anon key, RLS)      │
 ┌─────▼──────────────────────┴────────────┐
 │  Supabase (Postgres)                    │
 │  watchlist  ──1:n──▶  news_digests      │
 │     │ Database Webhook (INSERT, UPDATE) │
 └─────┼───────────────────────▲───────────┘
       │ POST {type, record,   │ insert row (service_role key)
       │       old_record}     │
 ┌─────▼───────────────────────┴───────────┐
 │  Make.com scenario                      │
 │  webhook → filter → variables → RSS     │
 │  → aggregate → AI → parse → insert      │
 │  (error handlers → insert 'failed' row) │
 └─────┬─────────────────▲─────────────────┘
       │                 │
  Google News RSS     Google Gemini API
```

## Data flow

**Add an asset**
1. `AddAssetView` validates the form and calls `createAsset()` (`src/services/watchlist.js`).
2. Supabase inserts into `watchlist`. RLS allows it for the `anon` role.
3. The Database Webhook POSTs `{type: "INSERT", record, old_record: null, …}` to Make.
4. Make passes the filter, fetches up to 8 headlines for `record.search_query`, aggregates them as
   JSON, sends them with prompt `v1` to Gemini, parses the JSON reply and inserts a `news_digests`
   row with `status = 'ok'` and the traceability fields (`ai_provider`, `ai_model`,
   `prompt_version`, `news_source`).
5. Realtime pushes the INSERT to every open dashboard/detail page (`src/services/realtime.js`).

**Refresh**
1. The Refresh button calls `requestDigest()`, which updates only `last_requested_at` (the only
   column `anon` may update). A trigger replaces the value with the **server** time.
2. The webhook fires with `type: "UPDATE"`. Make's filter passes because
   `record.last_requested_at ≠ old_record.last_requested_at`. Steps 4–5 above repeat.
3. No extra "requests" table: `last_requested_at > latest digest.created_at` *is* the pending state.

**Failure**
- If the AI or JSON step errors, a Make error handler inserts a row with `status = 'failed'` and
  `error_message`. The app shows "Failed – retry".
- If nothing arrives within `refresh.pendingStaleMinutes`, the app shows "Still waiting for the
  automation" and re-enables Refresh.

## What each part does

| Part | Responsibility | Depends on |
|---|---|---|
| `src/views/` | Screens; orchestrate loading, errors, user actions. | services, components, config, utils |
| `src/components/` | Presentational pieces (cards, badges, digest, timeline). | props, config, utils |
| `src/services/` | **Only** database access; normalises rows to the digest contract. | `src/lib/supabase.js` |
| `src/lib/supabase.js` | **Only** place the Supabase client is created. | env vars |
| `src/config/app.config.js` | All tunables (cooldown, Realtime, labels, tone colors). | — |
| `src/utils/` | Pure logic: digest state, refresh availability, formatting, shared clock. | config |
| `supabase/schema.sql` | Tables, grants, RLS, triggers, Realtime. | — |
| `automation/contracts/` | The two contracts that decouple the app from the tools. | — |
| `automation/prompts/` | Versioned prompt text. | AI output contract |
| `automation/make/` | Build guide + exported scenario. | both contracts |

## The two contracts (why tools are swappable)

```
   any news source ─┐
                    ├─▶ [ any automation ] ──▶ digest-record contract ──▶ news_digests ──▶ Vue
   any AI model ────┘          ▲
        │                      │
        └── ai-output contract ┘
```

- **AI output contract** (`ai-output.schema.json`): `{tone, summary, key_points}`. Any model that
  returns this works with the rest of the scenario unchanged.
- **Digest record contract** (`digest-record.schema.json`): the `news_digests` row. Any automation
  that writes this works with the app unchanged.
- The Vue app knows only the database contract (through services). Make knows only the contracts
  (not Vue). Traceability columns record which tool, model and prompt produced each row.

## Security model

No authentication. The browser uses the public anon/publishable key, limited by:
- column grants: `anon` can `select/insert/delete` `watchlist`, `update(last_requested_at)` only;
  `select` on `news_digests` only.
- RLS policies matching those grants.
- The service_role key and Gemini key live only in Make connections. The Make webhook URL lives
  only in the Supabase webhook config.

Anyone with the app URL can add/delete assets — acceptable for a demo; see HANDOFF "Known limitations".
