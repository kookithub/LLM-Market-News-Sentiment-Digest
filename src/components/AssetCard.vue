<script setup>
// Bento tile for one asset. `featured` makes it a wide tile that also shows the summary.
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import { getDigestState } from '../utils/digestState.js'
import { useNow } from '../utils/useNow.js'
import AppIcon from './AppIcon.vue'
import DigestStatus from './DigestStatus.vue'
import TimeAgo from './TimeAgo.vue'
import ToneBadge from './ToneBadge.vue'
import TypeBadge from './TypeBadge.vue'

const props = defineProps({
  /** @type {import('../services/watchlist.js').AssetWithDigest} */
  asset: { type: Object, required: true },
  featured: { type: Boolean, default: false },
})

const now = useNow()
const digest = computed(() => props.asset.latestDigest)
const state = computed(() => getDigestState(props.asset, digest.value, now.value))
const okDigest = computed(() => (digest.value?.status === 'ok' ? digest.value : null))
const preview = computed(() => okDigest.value?.key_points[0] ?? okDigest.value?.summary ?? '')
</script>

<template>
  <RouterLink
    :to="{ name: 'asset', params: { id: asset.id } }"
    class="tile asset-card"
    :class="{ 'asset-card--featured': featured, [`asset-card--${okDigest?.tone}`]: okDigest }"
  >
    <div class="asset-card__top">
      <div>
        <span class="ticker asset-card__symbol">{{ asset.symbol }}</span>
        <p class="asset-card__name">{{ asset.name }}</p>
      </div>
      <TypeBadge :type="asset.asset_type" />
    </div>

    <div class="asset-card__body">
      <DigestStatus v-if="state.kind !== 'ok'" :kind="state.kind" />
      <p v-if="state.kind === 'failed' && digest.error_message" class="asset-card__text asset-card__text--clamp">
        {{ digest.error_message }}
      </p>
      <template v-if="okDigest">
        <ToneBadge :tone="okDigest.tone" size="sm" />
        <p v-if="featured" class="asset-card__summary" :class="{ 'is-faded': state.kind !== 'ok' }">{{ okDigest.summary }}</p>
        <p v-else class="asset-card__text asset-card__text--clamp" :class="{ 'is-faded': state.kind !== 'ok' }">{{ preview }}</p>
      </template>
    </div>

    <div class="asset-card__footer">
      <span class="meta">
        <AppIcon name="clock" :size="14" />
        <template v-if="digest">Updated <TimeAgo :date="digest.created_at" /></template>
        <template v-else>Added <TimeAgo :date="asset.created_at" /></template>
      </span>
      <span class="round-icon" aria-hidden="true"><AppIcon name="arrow-right" :size="16" /></span>
    </div>
  </RouterLink>
</template>
