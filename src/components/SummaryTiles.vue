<script setup>
// The four small bento tiles beside the dashboard hero: totals, market mood, latest digest, live status.
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import { appConfig } from '../config/app.config.js'
import AppIcon from './AppIcon.vue'
import LiveIndicator from './LiveIndicator.vue'
import TimeAgo from './TimeAgo.vue'
import ToneBadge from './ToneBadge.vue'

const props = defineProps({
  /** @type {import('../services/watchlist.js').AssetWithDigest[]} */
  assets: { type: Array, required: true },
  liveStatus: { type: String, default: 'off' },
  reloading: { type: Boolean, default: false },
})
defineEmits(['reload'])

const typeCounts = computed(() =>
  Object.keys(appConfig.assetTypes).map((type) => ({
    type,
    label: appConfig.assetTypes[type].label,
    count: props.assets.filter((a) => a.asset_type === type).length,
  })),
)

const mood = computed(() => {
  const rows = Object.entries(appConfig.tones).map(([tone, meta]) => ({ tone, meta, count: 0 }))
  for (const { latestDigest } of props.assets) {
    const row = rows.find((r) => latestDigest?.status === 'ok' && r.tone === latestDigest.tone)
    if (row) row.count += 1
  }
  const total = rows.reduce((sum, r) => sum + r.count, 0)
  return { rows, total }
})

const latest = computed(() => {
  let best = null
  for (const asset of props.assets) {
    const d = asset.latestDigest
    if (d && (!best || d.created_at > best.digest.created_at)) best = { asset, digest: d }
  }
  return best
})
</script>

<template>
  <article class="tile tile--glass tile--stat" aria-labelledby="stat-tracked">
    <p id="stat-tracked" class="eyebrow">Assets tracked</p>
    <p class="stat__value">{{ assets.length }}</p>
    <p class="stat__note">
      <span v-for="(t, i) in typeCounts" :key="t.type">{{ i ? ' · ' : '' }}{{ t.count }} {{ t.label.toLowerCase() }}</span>
    </p>
  </article>

  <article class="tile tile--glass tile--stat" aria-labelledby="stat-mood">
    <p id="stat-mood" class="eyebrow">Market mood</p>
    <template v-if="mood.total">
      <div class="mood" role="img" :aria-label="mood.rows.map((r) => `${r.count} ${r.meta.label}`).join(', ')">
        <span
          v-for="r in mood.rows.filter((r) => r.count)"
          :key="r.tone"
          class="mood__seg"
          :class="`mood__seg--${r.tone}`"
          :style="{ flexGrow: r.count }"
        ></span>
      </div>
      <ul class="mood__legend">
        <li v-for="r in mood.rows" :key="r.tone" :class="`mood__item--${r.tone}`">
          <span class="mood__mark" aria-hidden="true">{{ r.meta.symbol }}</span>
          <strong>{{ r.count }}</strong> {{ r.meta.label }}
        </li>
      </ul>
    </template>
    <p v-else class="stat__note">No digests yet.</p>
  </article>

  <article class="tile tile--glass tile--stat" aria-labelledby="stat-latest">
    <p id="stat-latest" class="eyebrow">Latest digest</p>
    <template v-if="latest">
      <RouterLink :to="{ name: 'asset', params: { id: latest.asset.id } }" class="stat__link">
        <span class="ticker stat__ticker">{{ latest.asset.symbol }}</span>
        <AppIcon name="arrow-up-right" :size="16" />
      </RouterLink>
      <div class="stat__row">
        <ToneBadge v-if="latest.digest.status === 'ok'" :tone="latest.digest.tone" size="sm" />
        <span class="stat__note"><TimeAgo :date="latest.digest.created_at" /></span>
      </div>
    </template>
    <p v-else class="stat__note">Waiting for the first one.</p>
  </article>

  <article class="tile tile--glass tile--stat tile--pattern" aria-labelledby="stat-live">
    <p id="stat-live" class="eyebrow">Updates</p>
    <LiveIndicator :status="liveStatus" />
    <button type="button" class="btn btn--sm btn--quiet" :disabled="reloading" :aria-busy="reloading" @click="$emit('reload')">
      <span v-if="reloading" class="spinner btn__spinner" aria-hidden="true"></span>
      <AppIcon v-else name="refresh" :size="16" />
      Reload
    </button>
  </article>
</template>
