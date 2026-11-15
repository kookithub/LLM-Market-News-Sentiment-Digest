# Make.com scenario — step-by-step build guide

This builds the **one** scenario the project needs: *watchlist row inserted or refreshed → fetch
headlines → AI briefing → insert a linked `news_digests` row*.

> **Verified build (14 Nov 2026).** Everything below was built in Make's current UI and tested end to
> end: a Refresh in the app produced a real digest (tone, summary, 4 key points, 8 linked headlines,
> traceability line) that appeared through Realtime. Both error routes were also triggered and wrote
> `failed` rows that the app displayed.

```
[M1 Webhook] ─filter─▶ [M2 Set variables] ▶ [M3 RSS] ▶ [M4 Aggregate to JSON] ▶ [M5 Gemini] ▶ [M6 Parse JSON] ▶ [M7 Supabase: create row]
                                                                                   │ error           │ error
                                                                                   ▼                 ▼
                                                                  [M8 Supabase: failed row]  [M10 Supabase: failed row]
                                                                                   ▼                 ▼
                                                                              [M9 Skip]         [M11 Skip]
```

**Module numbers matter.** Make numbers modules in the order you add them. The mappings below
(`{{1.record.id}}`, `{{4.json}}`, …) assume this order. Typing `{{1.record.id}}` into a field turns it
into a mapped "pill"; if your numbers differ, pick the same fields from the mapping panel instead.

The guide steps (1–11) follow the project spec; **[M#]** is the Make module number.

---

## Before you start

| You need | Where |
|---|---|
| Supabase project with `supabase/schema.sql` run | Supabase › SQL Editor |
| Supabase **Project ID** (the `xxxx` in `https://xxxx.supabase.co`) and **service_role / secret key** | Supabase › Project Settings › API Keys. The secret key is for Make only — never put it in `.env` or the repo. |
| Gemini API key (free, no billing) | [aistudio.google.com](https://aistudio.google.com) › Get API key. Do **not** link a billing account. |
| Make.com account (Free plan) | [make.com](https://www.make.com) |

> **Browser autofill warning.** When Make's "Create a connection" dialogs open, Chrome may autofill a
> saved password (e.g. your Gemini key) into the wrong field. Clear the field and paste the right key.

---

## Step 1 — Webhooks › Custom webhook **[M1]**

1. Make › **Scenarios › Create a new scenario**. Name it `Market News Sentiment Digest` (the name field
   stops at 30 characters, so the full app name doesn't fit). The original build was named
   `LLM Market News Digest`; the name is cosmetic and nothing depends on it.
2. Click the big **+** › **Webhooks** › **Custom webhook** › **Create a webhook** › name
   `supabase-watchlist` › **Save**. Copy the URL (`https://hook.<region>.make.com/…`). Treat it like a
   password: anyone with it can trigger runs.
3. Leave the module "Listening for data".

Supabase will POST this payload (Database Webhooks format):

```json
{
  "type": "UPDATE",
  "table": "watchlist",
  "schema": "public",
  "record":     { "id": "…", "symbol": "NVDA", "name": "NVIDIA", "asset_type": "stock", "search_query": "NVIDIA NVDA", "added_by": "Art", "created_at": "…", "last_requested_at": "2026-11-14T08:30:00+00:00" },
  "old_record": { "id": "…", "symbol": "NVDA", "name": "NVIDIA", "asset_type": "stock", "search_query": "NVIDIA NVDA", "added_by": "Art", "created_at": "…", "last_requested_at": "2026-11-13T07:22:00+00:00" }
}
```

For a new asset, `type` is `"INSERT"` and `old_record` is `null`.

## Step 2 — Supabase › Database Webhook (not a Make module)

1. Supabase › **Integrations › Database Webhooks › Create webhook** (it installs `pg_net` the first time).
2. Name `watchlist_to_make`. **Table: `public.watchlist`** — the table list is long and scrolls; make
   sure it really says `public watchlist`, not an `auth.*` table.
3. Events: **Insert** and **Update** (not Delete).
4. Type **HTTP Request**, method **POST**, URL = the Make webhook URL. The `Content-type:
   application/json` header is already there. **Create webhook**.
5. Send a sample so Make learns the payload: add an asset, or press **Refresh** on an asset in the app.
   Make shows **"5 values detected"** (`type`, `table`, `record`, `schema`, `old_record`). **Save** M1.

## Step 3 — Filter after the webhook

Click the wrench between **[M1]** and **[M2]** › **Set up a filter**:

* Label: `INSERT, or Refresh (last_requested_at changed)`
* Group 1: `{{1.type}}` — *Text operators: Equal to* — `INSERT`
* **Add OR rule** → Group 2: `{{1.type}}` — *Equal to* — `UPDATE`
  **AND** `{{1.record.last_requested_at}}` — *Text operators: Not equal to* — `{{1.old_record.last_requested_at}}`

> Don't press **Escape** inside Make dialogs — it closes them without saving. To dismiss the mapping
> panel, click the dialog's title instead.

## Step 4 — Tools › Set variables **[M2]**

**Every tool-specific value lives here.** Swapping a tool = edit this module + the one module you replace.

| Variable name | Value (now) | Changes when you… |
|---|---|---|
| `ai_provider` | `gemini` | swap the AI provider |
| `ai_model` | `gemini-3.6-flash` | change the model (must be an exact ID — see step 8) |
| `prompt_version` | `v1` | add `automation/prompts/digest.v2.md` |
| `news_source` | `google_news_rss` | swap the news source |
| `max_headlines` | `8` | want more/fewer headlines |

## Step 5 — RSS › Retrieve RSS feed items **[M3]**

* **URL** — type the prefix, then `encodeURL(` (Make turns it into a function block), then
  `{{1.record.search_query}}`, then `)`, then the rest:
  ```
  https://news.google.com/rss/search?q={{encodeURL(1.record.search_query)}}&hl=en-US&gl=US&ceid=US:en
  ```
  (Typing the whole `{{encodeURL(…)}}` string in one go leaves stray `{{ }}` text — build it in pieces.)
* **Maximum number of returned items:** `{{2.max_headlines}}`.

## Step 6 — Aggregate the headlines **[M4]**: JSON › Aggregate to JSON

This is the project's *array aggregator*: it collects the RSS bundles into one array **and** escapes
it as valid JSON text that both the AI and the database can read.

1. **JSON › (Show more) › Aggregate to JSON**. **Source module:** `RSS - Retrieve RSS feed items [3]`.
2. **Data structure › Add** › name `Headline v1` › **Generate** from:
   `{"title": "x", "link": "https://x", "source": "x", "published_at": "x"}` › Save.
3. Map (field names verified from a real RSS run):

   | Field | Mapping |
   |---|---|
   | `title` | `{{3.title}}` |
   | `link` | `{{3.url}}` |
   | `source` | `{{3.source.title}}` — the publisher, e.g. "CNBC" (Make's RSS output has it directly) |
   | `published_at` | `{{3.dateCreated}}` |

Output: `{{4.json}}` = `[{"title": …, "link": …, "source": …, "published_at": …}, …]`.

> **Why not array aggregator + text aggregator?** In Make, once one aggregator collapses the RSS
> bundles, a second aggregator after it receives a single bundle. *Aggregate to JSON* gives both
> outputs we need for 1 credit.

## Step 7 — The AI's input text (no extra module)

The prompt receives `{{4.json}}` directly — a JSON list of headlines is as readable to the model as a
numbered list, and it saves 2 credits per run.

## Step 8 — Google Gemini AI › Generate a response **[M5]**

1. **Google Gemini AI › Generate a response**. **Connection › Create a connection** › paste your
   AI Studio key › Save.
2. **AI Model:** pick a model from the list once, then turn on **Map** to see its exact ID (e.g.
   `gemini-3.6-flash`). Replace the text with `{{2.ai_model}}` and put that ID in step 4.
   *Model choice:* `gemini-3.8-flash` returned `503 high demand` / timeouts repeatedly during testing;
   `gemini-3.6-flash` worked. If a model keeps failing, change only `ai_model` in M2.
3. **Messages › Add item:** Role `User` › **Parts › Add item** › Message Type `Text` › **Text:** paste
   the prompt from [`automation/prompts/digest.v1.md`](../prompts/digest.v1.md) with
   `{{symbol}}` → `{{1.record.symbol}}`, `{{name}}` → `{{1.record.name}}`,
   `{{asset_type}}` → `{{1.record.asset_type}}`, `{{headlines_json}}` → `{{4.json}}`.
4. **Show advanced settings** (toggle at the bottom of the dialog):
   * **Response Format:** `JSON Output`
   * **Response Schema (Deprecated):** paste the AI output contract as Gemini schema:
     ```json
     {"type": "object", "properties": {"tone": {"type": "string", "enum": ["positive", "neutral", "negative"]}, "summary": {"type": "string"}, "key_points": {"type": "array", "items": {"type": "string"}}}, "required": ["tone", "summary", "key_points"]}
     ```
   * **Thinking Level:** `Low` (faster, fewer tokens). Temperature is deprecated for Gemini 3.6+; leave it.

## Step 9 — JSON › Parse JSON **[M6]**

1. **Data structure › Add** › name `AI output v1` › **Generate** from
   `{"tone": "positive", "summary": "Example summary.", "key_points": ["one", "two", "three"]}`.
2. **JSON string:** `{{5.candidates[1].content.parts[1].text}}` (Make arrays start at 1).

> **Important.** With *JSON Output* on, Make's Gemini module already parses the reply, so
> `5.Result` is an **object**, not text — mapping it here fails with "Source is not valid JSON".
> Use the raw text in `candidates[1].content.parts[1].text`. JSON mode + schema also means no
> ```` ```json ```` fences. With a provider that has no JSON mode, strip fences first:
> `trim(replace(replace(TEXT; "```json"; emptystring); "```"; emptystring))`.

## Step 10 — Supabase › Create a Row **[M7]**

1. **Supabase › Create a Row** › **Create a connection**: Project ID + **service_role / secret** key.
2. Table `news_digests`. Make lists every column with the `COMMENT ON` text from `schema.sql`. Map:

   | Column | Mapping |
   |---|---|
   | `watchlist_id` | `{{1.record.id}}` |
   | `status` | `ok` |
   | `tone` | `lower(` `trim(` `{{6.tone}}` `))` |
   | `summary` | `{{6.summary}}` |
   | `key_points` | `join(` `{{6.key_points}}` `; {{newline}})` — the field is a text box, so send one point per line |
   | `headlines` | `{{4.json}}` |
   | `headline_count`, `id`, `created_at`, `error_message` | leave empty (DB fills or not needed) |
   | `ai_provider` / `ai_model` / `prompt_version` / `news_source` | `{{2.ai_provider}}` / `{{2.ai_model}}` / `{{2.prompt_version}}` / `{{2.news_source}}` |

> `key_points` and `headlines` are `jsonb`, but Make sends them as text. The DB trigger
> `normalize_digest_json` turns JSON text or newline-separated text into a real JSON array and fills
> `headline_count`, so the stored row always matches the digest contract.

## Step 11 — Error handlers **[M8–M11]**

Failures must show in the app ("Failed – retry"), not vanish in Make's history.

1. Right-click **Gemini [M5]** › **Add error handler** › **Supabase › Create a Row [M8]**, table
   `news_digests`, same connection:

   | Column | Mapping |
   |---|---|
   | `watchlist_id` | `{{1.record.id}}` |
   | `status` | `failed` |
   | `error_message` | `AI step failed: ` + **Gemini › Error › Message** from the mapping panel (`{{5.error.message}}`) |
   | `headlines` | `{{4.json}}` |
   | traceability ×4 | `{{2.…}}` as in step 10 |

2. Click the **+** after **[M8]** › **Error handlers › Skip [M9]** (Make's current name for the old
   *Ignore* directive). The run then ends as handled instead of failing.
3. Right-click **Parse JSON [M6]** › **Add error handler** › **Supabase › Create a Row [M10]** with
   `error_message` = `AI returned invalid JSON: {{6.error.message}}`, the rest as in M8 › then **Skip [M11]**.
4. **Save** (Ctrl+S), optionally **Auto-align** (toolbar), and switch the scenario **Active**
   (top right). Scheduling: **Immediately as data arrives**.

---

## Credit estimate (Make Free plan: 1,000 credits / month)

Measured from real runs:

| Run type | Credits |
|---|---|
| Successful digest (M1–M7) | **7** |
| AI or JSON failure (handled, failed row written) | **6–7** |
| RSS connection failure (run stops at M3) | **3** |
| Webhook filtered out (non-refresh update) | **1** |

**≈ 140 digests per month.** Building and testing this scenario used about 50 credits. The app's
10-minute Refresh cooldown and the step 3 filter keep usage low. Gemini uses your own key, so Make
charges only the normal 1 credit for that module.

---

## Export the blueprint into the repo

1. Scenario editor › **⋮** (top right, next to Help) › **Export blueprint** (downloads a `.json`), or
   **Copy blueprint to clipboard** and paste it into a file.
2. Save it as `automation/make/scenario-blueprint.json`.
3. **Secret check** — search it for `hook.`, `service_role`, `sb_secret_`, `eyJ`, `AIza`, `apiKey`,
   `token`, your email. Connections export as numeric IDs (safe), but typed text exports verbatim.
   The current file was checked: no URLs, keys or emails; connection labels were made neutral.

**Importing it elsewhere:** Create a new scenario › ⋮ › **Import blueprint** › choose the file, then
re-create the three account-specific pieces: the webhook (step 1, and point the Supabase webhook at
the new URL), the Gemini connection and the Supabase connection (M7, M8, M10).

---

## Testing

1. **Refresh / add:** press **Refresh** on an asset whose digest is older than 10 min (or add an asset).
   The card shows *Generating digest…*.
2. **Make History:** a run with 7 green modules (≈ 5–30 s).
3. **App:** within seconds the new digest appears by itself (Realtime) with tone, summary, key points,
   linked headlines and *Generated by gemini · gemini-3.6-flash · prompt v1 · news google_news_rss*.
4. **Supabase:** `news_digests` has a row with `status = ok`, `key_points`/`headlines` as JSON arrays,
   `headline_count` filled, traceability columns set.
5. **Filter:** edit a watchlist row's `name` in Table Editor → History shows a 1-credit run stopped at
   the filter, no digest.
6. **Failure path:** set `ai_model` in M2 to `not-a-model` → Refresh → a `failed` row; the app shows
   *Failed – retry* with the error. Put it back.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| **Webhook not firing** (no run in History) | Wrong table/URL, scenario inactive | Supabase › Database Webhooks: table `public.watchlist`, Insert+Update, URL. Make: *Active*. `select * from net._http_response order by created desc limit 10;` shows HTTP results. |
| **Run stops at the filter** | Filter fields wrong / structure not determined | Re-check step 3; webhook › *Redetermine data structure* and send a sample again. |
| **RSS: `Couldn't connect — 503 Service Unavailable`** (3-credit run, card goes *Still waiting*) | Google News temporarily refusing Make's shared servers (seen repeatedly during testing) | Wait a few minutes and Refresh again; Make sometimes auto-retries. If it persists, swap the news source (see `docs/SWAPPING_TOOLS.md` §2) or add an error handler on M3. |
| **"AI returned invalid JSON: Source is not valid JSON"** | Parse JSON is fed `5.Result` (an object) | Use `{{5.candidates[1].content.parts[1].text}}` (step 9). |
| **"AI step failed: [503] … high demand" / "timed out"** | That Gemini model is overloaded | Switch `ai_model` in M2 to another Flash model (e.g. `gemini-3.6-flash`). |
| **Gemini 429 / RESOURCE_EXHAUSTED** | Free-tier per-minute/day limit | Wait; raise `refresh.cooldownMinutes`; don't refresh many assets at once. |
| **Gemini 400 model not found** | `ai_model` isn't an exact ID | Select the model in M5 with *Map* off, turn *Map* on to read the ID, copy it into M2. |
| **Empty RSS** | Query too narrow | Edit the asset's `search_query` (e.g. `Apple stock`), Refresh. |
| **Check constraint violation on `tone`** | Unexpected tone text | Keep `lower(trim(6.tone))`; the response schema restricts the values. |
| **Supabase 401/403 in M7** | Connection uses the anon key | Use the **service_role / secret** key. |
| **Card never updates without reload** | Realtime off for `news_digests` | Re-run section 6 of `schema.sql`; check `appConfig.realtime.enabled`. |
