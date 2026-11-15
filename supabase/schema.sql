-- =============================================================================
-- LLM Market News Sentiment Digest — database schema
-- Run once in Supabase: Dashboard > SQL Editor > New query > paste > Run.
-- Safe to re-run: tables use IF NOT EXISTS, policies/triggers are dropped first.
-- Demo data lives in seed.sql (kept separate on purpose).
--
-- Contract: the shape of news_digests is documented in
-- automation/contracts/digest-record.schema.json. Change both together.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. Tables
-- -----------------------------------------------------------------------------

create table if not exists public.watchlist (
  id                uuid primary key default gen_random_uuid(),
  created_at        timestamptz not null default now(),
  symbol            text not null unique
                      check (symbol = upper(symbol) and char_length(symbol) between 1 and 10),
  name              text not null check (char_length(btrim(name)) > 0),
  asset_type        text not null check (asset_type in ('stock', 'crypto')),
  search_query      text not null check (char_length(btrim(search_query)) > 0),
  added_by          text not null check (char_length(btrim(added_by)) > 0),
  last_requested_at timestamptz not null default now()
);

create table if not exists public.news_digests (
  id             uuid primary key default gen_random_uuid(),
  created_at     timestamptz not null default now(),
  watchlist_id   uuid not null references public.watchlist (id) on delete cascade,
  status         text not null default 'ok' check (status in ('ok', 'failed')),
  error_message  text,
  tone           text check (tone in ('positive', 'neutral', 'negative')),
  summary        text,
  key_points     jsonb,
  headline_count int,
  headlines      jsonb,
  ai_provider    text,
  ai_model       text,
  prompt_version text,
  news_source    text
);

create index if not exists news_digests_watchlist_created_idx
  on public.news_digests (watchlist_id, created_at desc);


-- -----------------------------------------------------------------------------
-- 2. Self-documentation (visible in Supabase Table Editor and to any SQL client)
-- -----------------------------------------------------------------------------

comment on table public.watchlist is
  'PRIMARY table. One row per tracked stock or crypto asset, created from the Vue app. INSERT and UPDATE fire the Database Webhook that runs the Make.com digest scenario.';
comment on column public.watchlist.id is 'Primary key.';
comment on column public.watchlist.created_at is 'When the asset was added.';
comment on column public.watchlist.symbol is 'Ticker, stored UPPERCASE, unique, max 10 chars (e.g. NVDA, BTC).';
comment on column public.watchlist.name is 'Human-readable asset name (e.g. NVIDIA, Bitcoin).';
comment on column public.watchlist.asset_type is 'Either stock or crypto.';
comment on column public.watchlist.search_query is 'Query sent to the news source. The form pre-fills "<name> <symbol>".';
comment on column public.watchlist.added_by is 'Free-text name of whoever added the asset (no auth in this app).';
comment on column public.watchlist.last_requested_at is 'Bumped by the Refresh button. Changing it fires the UPDATE webhook, which asks Make for a new digest. Always set to the server clock by a trigger.';

comment on table public.news_digests is
  'SUPPORTING table. One AI-written briefing per automation run, linked to a watchlist row. Written only by the automation (service_role). Shape = automation/contracts/digest-record.schema.json.';
comment on column public.news_digests.id is 'Primary key.';
comment on column public.news_digests.created_at is 'When the automation wrote this digest.';
comment on column public.news_digests.watchlist_id is 'The asset this digest is about. Deleting the asset deletes its digests.';
comment on column public.news_digests.status is 'ok = digest generated; failed = the AI or JSON step failed (see error_message).';
comment on column public.news_digests.error_message is 'Why the run failed. Null when status = ok.';
comment on column public.news_digests.tone is 'AI-assigned tone of the news: positive, neutral or negative. Null when failed.';
comment on column public.news_digests.summary is 'AI-written briefing, 2-3 sentences.';
comment on column public.news_digests.key_points is 'JSON array of 3-5 short strings.';
comment on column public.news_digests.headline_count is 'How many headlines the AI was given. Filled automatically from headlines if omitted.';
comment on column public.news_digests.headlines is 'JSON array of {title, link, source, published_at}: the exact headlines the AI read.';
comment on column public.news_digests.ai_provider is 'Traceability: which AI provider wrote this (e.g. gemini).';
comment on column public.news_digests.ai_model is 'Traceability: exact model ID (e.g. gemini-2.5-flash).';
comment on column public.news_digests.prompt_version is 'Traceability: prompt file version, matches automation/prompts/digest.<version>.md (e.g. v1).';
comment on column public.news_digests.news_source is 'Traceability: where the headlines came from (e.g. google_news_rss).';


-- -----------------------------------------------------------------------------
-- 3. Triggers
-- -----------------------------------------------------------------------------

-- Why: the browser clock can be wrong. The app compares last_requested_at with
-- news_digests.created_at (server time) to decide whether a refresh is pending,
-- so both must come from the same clock. The client only signals "bump it".
create or replace function public.set_last_requested_at_server_time()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.last_requested_at is distinct from old.last_requested_at then
    new.last_requested_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists watchlist_last_requested_server_time on public.watchlist;
create trigger watchlist_last_requested_server_time
  before update of last_requested_at on public.watchlist
  for each row execute function public.set_last_requested_at_server_time();


-- Why: automation tools often send jsonb columns as TEXT (e.g. '["a","b"]',
-- a newline-separated list, or {"headlines":[...]}). This turns any of those
-- into a real JSON array so every writer produces the same digest record.
create or replace function public.coerce_jsonb_array(value jsonb)
returns jsonb
language plpgsql
set search_path = public
as $$
declare
  txt    text;
  parsed jsonb;
begin
  if value is null or jsonb_typeof(value) = 'array' then
    return value;
  end if;

  if jsonb_typeof(value) = 'object' then
    select v into parsed from jsonb_each(value) as e(k, v) where jsonb_typeof(v) = 'array' limit 1;
    return coalesce(parsed, jsonb_build_array(value));
  end if;

  if jsonb_typeof(value) = 'string' then
    txt := btrim(value #>> '{}');
    if txt = '' then
      return '[]'::jsonb;
    end if;
    begin
      parsed := txt::jsonb;
      if jsonb_typeof(parsed) in ('array', 'object') then
        return public.coerce_jsonb_array(parsed);
      end if;
    exception when others then
      null; -- not JSON: fall through to line splitting
    end;
    return (
      select coalesce(jsonb_agg(btrim(line)), '[]'::jsonb)
      from regexp_split_to_table(txt, E'\n') as line
      where btrim(line) <> ''
    );
  end if;

  return jsonb_build_array(value);
end;
$$;

create or replace function public.normalize_digest_json()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.key_points := public.coerce_jsonb_array(new.key_points);
  new.headlines  := public.coerce_jsonb_array(new.headlines);
  if new.headline_count is null and new.headlines is not null then
    new.headline_count := jsonb_array_length(new.headlines);
  end if;
  return new;
end;
$$;

drop trigger if exists news_digests_normalize_json on public.news_digests;
create trigger news_digests_normalize_json
  before insert or update on public.news_digests
  for each row execute function public.normalize_digest_json();


-- -----------------------------------------------------------------------------
-- 4. Grants (column-level) — no auth, so the browser runs as role "anon"
-- -----------------------------------------------------------------------------

-- Supabase grants everything to anon/authenticated by default; start from zero.
revoke all on public.watchlist    from anon, authenticated;
revoke all on public.news_digests from anon, authenticated;

grant select, insert, delete on public.watchlist to anon;
grant update (last_requested_at) on public.watchlist to anon;   -- Refresh button only
grant select on public.news_digests to anon;                     -- digests are written by Make (service_role)

grant all on public.watchlist, public.news_digests to service_role;


-- -----------------------------------------------------------------------------
-- 5. Row Level Security
-- -----------------------------------------------------------------------------

alter table public.watchlist    enable row level security;
alter table public.news_digests enable row level security;

drop policy if exists "anon can read watchlist"        on public.watchlist;
drop policy if exists "anon can add assets"            on public.watchlist;
drop policy if exists "anon can delete assets"         on public.watchlist;
drop policy if exists "anon can request a new digest"  on public.watchlist;
drop policy if exists "anon can read digests"          on public.news_digests;

create policy "anon can read watchlist"       on public.watchlist    for select to anon using (true);
create policy "anon can add assets"           on public.watchlist    for insert to anon with check (true);
create policy "anon can delete assets"        on public.watchlist    for delete to anon using (true);
-- The column grant above limits this UPDATE policy to last_requested_at.
create policy "anon can request a new digest" on public.watchlist    for update to anon using (true) with check (true);
create policy "anon can read digests"         on public.news_digests for select to anon using (true);
-- No insert/update/delete policy on news_digests for anon: service_role bypasses RLS.


-- -----------------------------------------------------------------------------
-- 6. Realtime — the app listens for new digests
-- -----------------------------------------------------------------------------

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'news_digests'
  ) then
    alter publication supabase_realtime add table public.news_digests;
  end if;
end;
$$;


-- -----------------------------------------------------------------------------
-- 7. Database Webhook (create it in the Dashboard, not here)
-- Database > Webhooks > Create: table watchlist, events INSERT + UPDATE,
-- HTTP POST to your Make webhook URL. See automation/make/MAKE_SETUP.md.
-- Kept out of SQL so the Make URL (a secret) never lands in the repo.
-- -----------------------------------------------------------------------------
