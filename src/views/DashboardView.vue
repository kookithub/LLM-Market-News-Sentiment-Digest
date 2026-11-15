<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { appConfig } from '../config/app.config.js'
import { listAssetsWithLatestDigest } from '../services/watchlist.js'
import { subscribeToNewDigests } from '../services/realtime.js'
import AppIcon from '../components/AppIcon.vue'
import AssetCard from '../components/AssetCard.vue'
import GreatWave from '../components/GreatWave.vue'
import StateBlock from '../components/StateBlock.vue'
import SummaryTiles from '../components/SummaryTiles.vue'

const today = new Intl.DateTimeFormat('en', { weekday: 'long', month: 'long', day: 'numeric' }).format(new Date())

const assets = ref([])
const phase = ref('loading') // 'loading' | 'ready' | 'error'
const reloading = ref(false)
const errorMessage = ref('')
const search = ref('')
const typeFilter = ref('all')
const liveStatus = ref('off')
const announcement = ref('')

async function load() {
  if (phase.value !== 'loading') reloading.value = true
  errorMessage.value = ''
  try {
    assets.value = await listAssetsWithLatestDigest()
    phase.value = 'ready'
  } catch (error) {
    errorMessage.value = error.message
    if (!assets.value.length) phase.value = 'error'
  } finally {
    reloading.value = false
  }
}

function onNewDigest(digest) {
  const asset = assets.value.find((a) => a.id === digest.watchlist_id)
  if (!asset) return load() // added elsewhere since our last load
  if (!asset.latestDigest || digest.created_at >= asset.latestDigest.created_at) asset.latestDigest = digest
  announcement.value = `New digest for ${asset.symbol}.`
}

let unsubscribe = () => {}
onMounted(() => {
  load()
  unsubscribe = subscribeToNewDigests({ onInsert: onNewDigest, onStatus: (s) => (liveStatus.value = s) })
})
onBeforeUnmount(() => unsubscribe())

const visibleAssets = computed(() => {
  const query = search.value.trim().toLowerCase()
  return assets.value.filter(
    (a) =>
      (typeFilter.value === 'all' || a.asset_type === typeFilter.value) &&
      (!query || a.symbol.toLowerCase().includes(query) || a.name.toLowerCase().includes(query)),
  )
})

// The most recently updated asset with a good digest gets the wide "featured" tile, shown first.
const featuredId = computed(() => {
  let best = null
  for (const a of visibleAssets.value) {
    const d = a.latestDigest
    if (d?.status === 'ok' && (!best || d.created_at > best.latestDigest.created_at)) best = a
  }
  return best?.id ?? null
})
const orderedAssets = computed(() => {
  const list = [...visibleAssets.value]
  const i = list.findIndex((a) => a.id === featuredId.value)
  if (i > 0) list.unshift(...list.splice(i, 1))
  return list
})

function clearFilters() {
  search.value = ''
  typeFilter.value = 'all'
}
</script>

<template>
  <div class="container page">
    <!-- Bento: hero (2×2) + four summary tiles -->
    <div class="bento bento--top">
      <section class="tile tile--hero" aria-labelledby="hero-title">
        <div class="hero__copy">
          <p class="eyebrow hero__date"><span class="dot" aria-hidden="true"></span>Briefing · {{ today }}</p>
          <h1 id="hero-title" class="hero__title">
            <span v-for="line in appConfig.app.heroTitle" :key="line">{{ line }}</span>
          </h1>
          <p class="hero__hint">{{ appConfig.app.heroHint }}</p>
          <div class="hero__actions">
            <RouterLink to="/new" class="btn btn--primary"><AppIcon name="plus" :size="18" /> Add an asset</RouterLink>
            <a v-if="assets.length" href="#watchlist" class="btn btn--ghost">
              View watchlist <AppIcon name="arrow-right" :size="16" />
            </a>
          </div>
        </div>
        <div class="hero__art"><GreatWave /></div>
      </section>

      <template v-if="phase === 'ready' && assets.length">
        <SummaryTiles :assets="assets" :live-status="liveStatus" :reloading="reloading" @reload="load" />
      </template>
      <template v-else-if="phase === 'loading'">
        <div v-for="n in 4" :key="n" class="tile tile--glass tile--stat skeleton" aria-hidden="true"></div>
      </template>
    </div>

    <section id="watchlist" class="section" aria-labelledby="watchlist-title">
      <!-- Loading -->
      <template v-if="phase === 'loading'">
        <p class="sr-only" role="status">Loading watchlist…</p>
        <ul class="bento bento--assets" aria-hidden="true">
          <li v-for="n in appConfig.ui.skeletonCards" :key="n" class="tile skeleton-tile">
            <span class="skeleton skeleton--title"></span>
            <span class="skeleton skeleton--line"></span>
            <span class="skeleton skeleton--block"></span>
          </li>
        </ul>
      </template>

      <!-- Error (nothing loaded) -->
      <StateBlock v-else-if="phase === 'error'" kind="error" title="Couldn't load your watchlist" :message="errorMessage">
        <button type="button" class="btn btn--primary" @click="load"><AppIcon name="refresh" :size="16" /> Try again</button>
      </StateBlock>

      <!-- Empty watchlist -->
      <StateBlock
        v-else-if="!assets.length"
        kind="empty"
        title="Your watchlist is empty"
        message="Add a stock or crypto asset and a digest of its latest news will be generated automatically."
      >
        <RouterLink to="/new" class="btn btn--primary"><AppIcon name="plus" :size="16" /> Add your first asset</RouterLink>
      </StateBlock>

      <!-- Ready -->
      <template v-else>
        <div class="tile tile--glass toolbar">
          <h2 id="watchlist-title" class="tile__title">
            Watchlist <span class="count-pill">{{ visibleAssets.length }}</span>
          </h2>
          <div class="toolbar__search">
            <label for="asset-search" class="sr-only">Search by symbol or name</label>
            <AppIcon name="search" :size="18" class="toolbar__search-icon" />
            <input id="asset-search" v-model="search" class="input" type="search" placeholder="Search symbol or name" autocomplete="off" />
          </div>
          <fieldset class="segmented">
            <legend class="sr-only">Filter by asset type</legend>
            <label v-for="f in appConfig.filters" :key="f.value" class="segmented__option">
              <input v-model="typeFilter" type="radio" name="type-filter" :value="f.value" />
              <span>{{ f.label }}</span>
            </label>
          </fieldset>
        </div>

        <div v-if="errorMessage" class="alert" role="alert">
          Reload failed: {{ errorMessage }} Showing the last loaded data.
        </div>

        <p class="sr-only" role="status" aria-live="polite">{{ announcement }}</p>

        <ul v-if="orderedAssets.length" class="bento bento--assets">
          <li
            v-for="asset in orderedAssets"
            :key="asset.id"
            :class="{ 'span-2': asset.id === featuredId }"
          >
            <AssetCard :asset="asset" :featured="asset.id === featuredId" />
          </li>
        </ul>
        <StateBlock v-else kind="empty" title="No assets match" message="Try a different search or filter.">
          <button type="button" class="btn btn--ghost" @click="clearFilters">Clear filters</button>
        </StateBlock>
      </template>
    </section>
  </div>
</template>
