-- =============================================================================
-- LLM Market News Sentiment Digest — demo data (FICTIONAL, for screenshots and local demos)
-- Run AFTER schema.sql, in Supabase SQL Editor.
--
-- Tip: run this BEFORE creating the Database Webhook. Otherwise each inserted
-- asset triggers a real Make run (~7 credits each).
--
-- Re-runnable: it deletes the 4 demo symbols first (digests cascade).
-- Headlines, sources and links are invented placeholders, not real news.
-- Demo text must not contain the SQL keyword I-N-T-O followed by a word: the Supabase SQL
-- Editor's RLS check mistakes it for a SELECT that creates a new table and tries to enable
-- RLS on a table that does not exist. If the editor still asks, choose "Run without RLS":
-- schema.sql already enabled RLS on both tables.
-- =============================================================================

delete from public.watchlist where symbol in ('NVDA', 'TSLA', 'BTC', 'ETH');

-- last_requested_at is set just before the latest digest, so the app shows
-- these assets as "up to date" rather than "generating".
insert into public.watchlist (symbol, name, asset_type, search_query, added_by, created_at, last_requested_at) values
  ('NVDA', 'NVIDIA',   'stock',  'NVIDIA NVDA',   'Demo seed', now() - interval '5 days', now() - interval '2 hours 1 minute'),
  ('TSLA', 'Tesla',    'stock',  'Tesla TSLA',    'Demo seed', now() - interval '5 days', now() - interval '5 hours 1 minute'),
  ('BTC',  'Bitcoin',  'crypto', 'Bitcoin BTC',   'Demo seed', now() - interval '4 days', now() - interval '40 minutes'),
  ('ETH',  'Ethereum', 'crypto', 'Ethereum ETH',  'Demo seed', now() - interval '4 days', now() - interval '1 day 3 hours 1 minute');

insert into public.news_digests
  (watchlist_id, created_at, status, tone, summary, key_points, headline_count, headlines,
   ai_provider, ai_model, prompt_version, news_source)
select w.id, d.created_at, 'ok', d.tone, d.summary, d.key_points, jsonb_array_length(d.headlines), d.headlines,
       'gemini', 'gemini-2.5-flash', 'v1', 'google_news_rss'
from public.watchlist w
join (values
  -- NVDA ---------------------------------------------------------------------
  ('NVDA', now() - interval '2 hours', 'positive',
   'Coverage of NVIDIA is upbeat, led by reports of strong data-center demand and new cloud partnerships. Analysts flag supply constraints as the main near-term risk, but the overall tone favours continued growth.',
   '["Data-center demand remains the dominant theme in coverage", "Several outlets report new cloud and sovereign-AI partnerships", "Analysts cite chip supply limits as the key near-term risk", "Options activity suggests elevated expectations ahead of earnings"]'::jsonb,
   '[{"title": "NVIDIA data-center orders stay strong, analysts say", "link": "https://example.com/demo/nvda-1", "source": "Demo Markets Wire", "published_at": "2026-11-13T14:05:00Z"},
     {"title": "Cloud providers expand AI capacity deals with NVIDIA", "link": "https://example.com/demo/nvda-2", "source": "Sample Tech Daily", "published_at": "2026-11-13T11:30:00Z"},
     {"title": "Supply limits could cap next-quarter chip shipments", "link": "https://example.com/demo/nvda-3", "source": "Example Finance", "published_at": "2026-11-13T09:12:00Z"},
     {"title": "Traders position for volatility ahead of NVIDIA results", "link": "https://example.com/demo/nvda-4", "source": "Demo Markets Wire", "published_at": "2026-11-12T20:45:00Z"}]'::jsonb),
  ('NVDA', now() - interval '2 days 6 hours', 'neutral',
   'NVIDIA headlines were mixed: product announcements drew interest while export-rule uncertainty weighed on sentiment. No single story dominated the news cycle.',
   '["New product roadmap details drew broad coverage", "Export-rule uncertainty remains an open question", "Shares tracked the wider semiconductor sector"]'::jsonb,
   '[{"title": "NVIDIA outlines next-generation GPU roadmap", "link": "https://example.com/demo/nvda-5", "source": "Sample Tech Daily", "published_at": "2026-11-11T16:00:00Z"},
     {"title": "Chip stocks drift as export rules remain unclear", "link": "https://example.com/demo/nvda-6", "source": "Example Finance", "published_at": "2026-11-11T13:20:00Z"},
     {"title": "Semiconductor index flat in quiet session", "link": "https://example.com/demo/nvda-7", "source": "Demo Markets Wire", "published_at": "2026-11-11T21:10:00Z"}]'::jsonb),

  -- TSLA ---------------------------------------------------------------------
  ('TSLA', now() - interval '5 hours', 'negative',
   'Tesla coverage turned cautious after reports of softer quarterly deliveries in key markets and rising price competition. Commentary on autonomy plans provided some offset but did not change the overall tone.',
   '["Reports point to softer deliveries in several regions", "Price competition from rival EV makers is intensifying", "Autonomy and robotaxi plans remain a long-term talking point"]'::jsonb,
   '[{"title": "Tesla deliveries come in below some estimates", "link": "https://example.com/demo/tsla-1", "source": "Example Finance", "published_at": "2026-11-13T12:00:00Z"},
     {"title": "EV price war pressures margins across the sector", "link": "https://example.com/demo/tsla-2", "source": "Demo Markets Wire", "published_at": "2026-11-13T08:40:00Z"},
     {"title": "Tesla reiterates robotaxi timeline at investor event", "link": "https://example.com/demo/tsla-3", "source": "Sample Auto News", "published_at": "2026-11-12T18:15:00Z"}]'::jsonb),
  ('TSLA', now() - interval '3 days 2 hours', 'positive',
   'Tesla headlines were favourable as energy-storage growth and a new factory milestone drew attention. Coverage framed the energy business as an increasingly important second engine.',
   '["Energy-storage deployments reached a reported record", "A new factory production milestone was announced", "Analysts highlight energy as a growing share of revenue", "Shares outperformed the wider auto sector"]'::jsonb,
   '[{"title": "Tesla energy storage hits record quarter", "link": "https://example.com/demo/tsla-4", "source": "Sample Auto News", "published_at": "2026-11-10T15:30:00Z"},
     {"title": "New Tesla plant reaches production milestone", "link": "https://example.com/demo/tsla-5", "source": "Demo Markets Wire", "published_at": "2026-11-10T10:05:00Z"},
     {"title": "Why analysts are watching the Tesla energy unit", "link": "https://example.com/demo/tsla-6", "source": "Example Finance", "published_at": "2026-11-10T07:50:00Z"},
     {"title": "Auto stocks mixed as Tesla leads gains", "link": "https://example.com/demo/tsla-7", "source": "Demo Markets Wire", "published_at": "2026-11-09T21:00:00Z"}]'::jsonb),

  -- BTC ----------------------------------------------------------------------
  ('BTC', now() - interval '35 minutes', 'positive',
   'Bitcoin news flow is positive, driven by steady ETF inflows and renewed institutional interest. Some outlets warn that leverage in derivatives markets is rising, which could amplify swings.',
   '["Spot ETF inflows continued for a consecutive week", "Institutional buyers are cited as the main source of demand", "Derivatives leverage is rising, a possible volatility risk"]'::jsonb,
   '[{"title": "Bitcoin ETFs log another week of inflows", "link": "https://example.com/demo/btc-1", "source": "Demo Crypto Desk", "published_at": "2026-11-14T06:20:00Z"},
     {"title": "Institutions return to bitcoin as volatility cools", "link": "https://example.com/demo/btc-2", "source": "Example Finance", "published_at": "2026-11-14T03:45:00Z"},
     {"title": "Futures open interest climbs, raising leverage concerns", "link": "https://example.com/demo/btc-3", "source": "Sample Markets Daily", "published_at": "2026-11-13T22:10:00Z"},
     {"title": "Bitcoin holds key level after weekend rally", "link": "https://example.com/demo/btc-4", "source": "Demo Crypto Desk", "published_at": "2026-11-13T19:00:00Z"},
     {"title": "Miners report steady output after network upgrade", "link": "https://example.com/demo/btc-5", "source": "Sample Markets Daily", "published_at": "2026-11-13T15:30:00Z"}]'::jsonb),
  ('BTC', now() - interval '1 day 8 hours', 'negative',
   'Bitcoin coverage was cautious after a sharp intraday drop triggered liquidations. Regulatory headlines added to the uncertainty, although several analysts described the move as a routine pullback.',
   '["A sharp intraday drop triggered leveraged liquidations", "New regulatory proposals added uncertainty", "Some analysts called the move a routine pullback"]'::jsonb,
   '[{"title": "Bitcoin slides as liquidations hit leveraged traders", "link": "https://example.com/demo/btc-6", "source": "Demo Crypto Desk", "published_at": "2026-11-13T01:15:00Z"},
     {"title": "Regulators float new rules for crypto exchanges", "link": "https://example.com/demo/btc-7", "source": "Example Finance", "published_at": "2026-11-12T17:40:00Z"},
     {"title": "Analysts: bitcoin dip is a pause, not a reversal", "link": "https://example.com/demo/btc-8", "source": "Sample Markets Daily", "published_at": "2026-11-12T14:00:00Z"}]'::jsonb),

  -- ETH ----------------------------------------------------------------------
  ('ETH', now() - interval '1 day 3 hours', 'neutral',
   'Ethereum news was balanced: developer progress on the next network upgrade was well received, while weaker on-chain fee revenue drew questions. Price action mostly followed bitcoin.',
   '["Developers confirmed progress on the next network upgrade", "On-chain fee revenue has declined recently", "Price action largely tracked bitcoin"]'::jsonb,
   '[{"title": "Ethereum developers set testnet date for next upgrade", "link": "https://example.com/demo/eth-1", "source": "Demo Crypto Desk", "published_at": "2026-11-13T05:00:00Z"},
     {"title": "Ethereum fee revenue falls to multi-month low", "link": "https://example.com/demo/eth-2", "source": "Sample Markets Daily", "published_at": "2026-11-12T20:30:00Z"},
     {"title": "Ether moves in step with bitcoin in quiet trade", "link": "https://example.com/demo/eth-3", "source": "Example Finance", "published_at": "2026-11-12T16:45:00Z"}]'::jsonb),
  ('ETH', now() - interval '3 days 5 hours', 'positive',
   'Ethereum coverage was upbeat as staking participation rose and a large asset manager announced a tokenised fund on the network. Commentators framed this as growing institutional use of Ethereum.',
   '["Staking participation reached a reported high", "A large asset manager launched a tokenised fund on Ethereum", "Layer-2 activity continued to grow", "Commentators point to rising institutional use"]'::jsonb,
   '[{"title": "Ethereum staking participation climbs to new high", "link": "https://example.com/demo/eth-4", "source": "Demo Crypto Desk", "published_at": "2026-11-11T09:30:00Z"},
     {"title": "Asset manager launches tokenised fund on Ethereum", "link": "https://example.com/demo/eth-5", "source": "Example Finance", "published_at": "2026-11-11T07:10:00Z"},
     {"title": "Layer-2 networks post record weekly activity", "link": "https://example.com/demo/eth-6", "source": "Sample Markets Daily", "published_at": "2026-11-10T23:55:00Z"}]'::jsonb)
) as d(symbol, created_at, tone, summary, key_points, headlines)
  on d.symbol = w.symbol;
