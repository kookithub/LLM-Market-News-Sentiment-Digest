# supabase/

Database definition for Supabase (Postgres). Run these in **Supabase › SQL Editor**.

| File | What belongs here | When to run |
|---|---|---|
| `schema.sql` | Tables, index, `COMMENT ON` docs, triggers, column grants, RLS policies, Realtime publication. Re-runnable. | First, and after any schema change. |
| `seed.sql` | Fictional demo data: NVDA, TSLA, BTC, ETH with 2 digests each. Re-runnable (deletes those 4 symbols first). | After `schema.sql`, **before** creating the Database Webhook (otherwise each seeded asset triggers a Make run). |

**If the SQL Editor asks to "Run and enable RLS"**, choose **Run without RLS**. Both scripts
already enable RLS themselves; the editor's check can misread text and then fail with
`relation "…" does not exist` on a table that was never meant to exist.

The Database Webhook (watchlist → Make) is created in the Dashboard, not in SQL, so the Make URL
never lands in the repo. See `automation/make/MAKE_SETUP.md` step 2.

Tables in one line each:
- `watchlist` — primary; one row per asset; written by the Vue app (anon key).
- `news_digests` — supporting; one row per automation run, `watchlist_id` → `watchlist.id` (cascade delete); written by Make (service_role key). Shape = `automation/contracts/digest-record.schema.json`.

Security model (no auth): `anon` may select/insert/delete `watchlist` and update **only**
`last_requested_at`; `anon` may only select `news_digests`.
