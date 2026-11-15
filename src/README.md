# src/

The Vue 3 front end (Vite, Composition API, `<script setup>`). Plain CSS, no UI libraries.

| Path | What belongs here | Rule |
|---|---|---|
| `main.js` | App bootstrap; injects tone colors from config as CSS variables. | |
| `App.vue` | Layout shell: skip link, header, `<RouterView>`, footer. | |
| `style.css` | The whole design system: tokens (colors, type scale, spacing scale, radius) at the top, then base, bento grid + tiles, and one section per screen. | No hard-coded tone colors: they come from config. Layout = `.bento` grid + `.tile` + `.span-2/3/4`. |
| `config/app.config.js` | **Every tunable value**: refresh cooldown, Realtime on/off, labels, tone colors, form limits. | Components never hard-code these. |
| `lib/supabase.js` | Creates the Supabase client. | **The only file** that imports `@supabase/supabase-js`. |
| `services/` | `watchlist.js`, `digests.js`, `realtime.js`, `errors.js`. | **The only place** that talks to the database. Every function has JSDoc. |
| `utils/` | Pure helpers with no DB access: digest state + refresh cooldown (`digestState.js`), formatting (`format.js`), shared clock (`useNow.js`). | No imports from `lib/` or `services/`. |
| `components/` | Reusable UI pieces. Tiles: `AssetCard` (asset tile, optional wide `featured`), `SummaryTiles` (the four dashboard stat tiles), `KeyPointList`, `HeadlineList`, `DigestView` (compact digest for history/failures), `DigestTimeline`. Small parts: `ToneBadge`, `TypeBadge`, `TimeAgo`, `DigestStatus`, `LiveIndicator`, `CooldownRing`, `ConfirmPanel`, `StateBlock`, `AppHeader`, `AppIcon` (the one icon set), `BrandMark` (logo), `GreatWave` (decorative hero art; colors from `.gw-*` in `style.css`). | Receive data via props; never import Supabase or services. |
| `views/` | One file per route: `DashboardView`, `AddAssetView`, `AssetDetailView`. | Call services; never import Supabase. |
| `router/` | Route table. | |

Dependency direction: `views → components / services / utils → config`, `services → lib`.
Replacing Supabase means rewriting `lib/` and `services/` only (see `docs/SWAPPING_TOOLS.md`).
