<script setup>
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { appConfig } from '../config/app.config.js'
import { deleteAsset, getAsset, requestDigest } from '../services/watchlist.js'
import { listDigestsForAsset } from '../services/digests.js'
import { subscribeToNewDigests } from '../services/realtime.js'
import { getDigestState, getRefreshAvailability } from '../utils/digestState.js'
import { formatDateTime, formatProvenance } from '../utils/format.js'
import { useNow } from '../utils/useNow.js'
import AppIcon from '../components/AppIcon.vue'
import ConfirmPanel from '../components/ConfirmPanel.vue'
import CooldownRing from '../components/CooldownRing.vue'
import DigestStatus from '../components/DigestStatus.vue'
import DigestTimeline from '../components/DigestTimeline.vue'
import DigestView from '../components/DigestView.vue'
import HeadlineList from '../components/HeadlineList.vue'
import KeyPointList from '../components/KeyPointList.vue'
import LiveIndicator from '../components/LiveIndicator.vue'
import StateBlock from '../components/StateBlock.vue'
import TimeAgo from '../components/TimeAgo.vue'
import TypeBadge from '../components/TypeBadge.vue'

const props = defineProps({ id: { type: String, required: true } })
const router = useRouter()
const now = useNow()

const asset = ref(null)
const digests = ref([])
const phase = ref('loading') // 'loading' | 'ready' | 'not_found' | 'error'
const errorMessage = ref('')
const liveStatus = ref('off')

const refreshing = ref(false)
const refreshError = ref('')
const confirmingDelete = ref(false)
const deleting = ref(false)
const deleteError = ref('')
const deleteButton = ref(null)

const latest = computed(() => digests.value[0] ?? null)
const okLatest = computed(() => (latest.value?.status === 'ok' ? latest.value : null))
const toneMeta = computed(() => (okLatest.value ? appConfig.tones[okLatest.value.tone] : null))
const previous = computed(() => digests.value.slice(1))
const state = computed(() => (asset.value ? getDigestState(asset.value, latest.value, now.value) : null))
const refresh = computed(() => (asset.value ? getRefreshAvailability(asset.value, latest.value, now.value) : null))
const refreshLabel = computed(() => {
  if (refreshing.value) return 'Requesting…'
  if (refresh.value?.reason === 'pending') return 'Generating…'
  // The CooldownRing beside the button shows the remaining wait.
  if (refresh.value?.reason === 'cooldown') return 'Refresh'
  return 'Refresh digest'
})

async function load() {
  phase.value = 'loading'
  errorMessage.value = ''
  try {
    const [row, list] = await Promise.all([
      getAsset(props.id),
      listDigestsForAsset(props.id, { limit: appConfig.digests.historyLimit }),
    ])
    if (!row) {
      phase.value = 'not_found'
      return
    }
    asset.value = row
    digests.value = list
    phase.value = 'ready'
  } catch (error) {
    errorMessage.value = error.message
    phase.value = 'error'
  }
}

function onNewDigest(digest) {
  if (digests.value.some((d) => d.id === digest.id)) return
  digests.value = [digest, ...digests.value].sort((a, b) => (a.created_at < b.created_at ? 1 : -1))
}

let unsubscribe = () => {}
watch(
  () => props.id,
  (id) => {
    unsubscribe()
    confirmingDelete.value = false
    load()
    unsubscribe = subscribeToNewDigests({ watchlistId: id, onInsert: onNewDigest, onStatus: (s) => (liveStatus.value = s) })
  },
  { immediate: true },
)
onBeforeUnmount(() => unsubscribe())

async function onRefresh() {
  if (!refresh.value?.allowed || refreshing.value) return
  refreshing.value = true
  refreshError.value = ''
  try {
    asset.value = await requestDigest(asset.value.id)
  } catch (error) {
    refreshError.value = error.message
  } finally {
    refreshing.value = false
  }
}

async function onConfirmDelete() {
  deleting.value = true
  deleteError.value = ''
  try {
    await deleteAsset(asset.value.id)
    router.push({ name: 'dashboard' })
  } catch (error) {
    deleteError.value = error.message
    deleting.value = false
  }
}

async function onCancelDelete() {
  confirmingDelete.value = false
  await nextTick()
  deleteButton.value?.focus()
}
</script>

<template>
  <div class="container page">
    <RouterLink to="/" class="back-link"><AppIcon name="arrow-left" :size="16" /> Dashboard</RouterLink>

    <StateBlock v-if="phase === 'loading'" kind="loading" title="Loading digest…" />

    <StateBlock v-else-if="phase === 'not_found'" kind="empty" title="Asset not found" message="It may have been deleted.">
      <RouterLink to="/" class="btn btn--primary">Go to dashboard</RouterLink>
    </StateBlock>

    <StateBlock v-else-if="phase === 'error'" kind="error" title="Couldn't load this asset" :message="errorMessage">
      <button type="button" class="btn btn--primary" @click="load"><AppIcon name="refresh" :size="16" /> Try again</button>
    </StateBlock>

    <div v-else class="bento bento--detail">
      <!-- Asset header + actions -->
      <header class="tile tile--glass tile--asset span-4">
        <div class="asset-head">
          <div class="asset-head__title">
            <h1 class="ticker asset-head__symbol">{{ asset.symbol }}</h1>
            <p class="asset-head__name">{{ asset.name }}</p>
          </div>
          <dl class="asset-head__meta">
            <div><dt>Type</dt><dd><TypeBadge :type="asset.asset_type" /></dd></div>
            <div><dt>News query</dt><dd>{{ asset.search_query }}</dd></div>
            <div><dt>Added</dt><dd>{{ asset.added_by }} · <TimeAgo :date="asset.created_at" /></dd></div>
          </dl>
        </div>

        <div class="asset-head__actions">
          <div class="asset-head__buttons">
            <CooldownRing v-if="refresh.reason === 'cooldown'" :remaining-ms="refresh.remainingMs" :total-ms="refresh.totalMs" />
            <button
              type="button"
              class="btn btn--primary"
              :disabled="!refresh.allowed || refreshing"
              :aria-busy="refreshing"
              aria-describedby="refresh-note"
              @click="onRefresh"
            >
              <span v-if="refreshing || refresh.reason === 'pending'" class="spinner btn__spinner" aria-hidden="true"></span>
              <AppIcon v-else name="refresh" :size="16" />
              {{ refreshLabel }}
            </button>
            <button
              v-if="!confirmingDelete"
              ref="deleteButton"
              type="button"
              class="btn btn--danger-ghost"
              @click="confirmingDelete = true"
            >
              <AppIcon name="trash" :size="16" /> Delete
            </button>
          </div>
          <p id="refresh-note" class="meta">One refresh per {{ appConfig.refresh.cooldownMinutes }} min — protects the free AI quota.</p>
          <ConfirmPanel
            v-if="confirmingDelete"
            :title="`Delete ${asset.symbol}?`"
            :message="`This removes ${asset.symbol} and all ${digests.length} of its digests. This cannot be undone.`"
            confirm-label="Delete asset"
            busy-label="Deleting…"
            :busy="deleting"
            @confirm="onConfirmDelete"
            @cancel="onCancelDelete"
          />
          <p v-if="deleteError" class="field__error" role="alert">{{ deleteError }}</p>
        </div>
      </header>

      <!-- Status banners -->
      <div v-if="refreshError" class="alert span-4" role="alert">{{ refreshError }}</div>
      <div v-if="state.kind === 'pending'" class="tile tile--glass banner span-4" role="status">
        <DigestStatus kind="pending" />
        <span class="meta">Fetching headlines and asking the AI — usually 10–30 seconds. The new digest appears here by itself.</span>
        <button v-if="liveStatus !== 'live'" type="button" class="link-button" @click="load">Check now</button>
      </div>
      <div v-else-if="state.kind === 'stalled'" class="tile banner banner--warn span-4" role="status">
        <DigestStatus kind="stalled" />
        <span>
          Requested <TimeAgo :date="asset.last_requested_at" /> but nothing arrived yet. The news source or automation
          may be busy — try Refresh again.
        </span>
        <button type="button" class="link-button" @click="load">Check again</button>
      </div>

      <!-- Latest digest as bento tiles -->
      <template v-if="okLatest">
        <article class="tile tile--summary span-3" aria-labelledby="latest-heading">
          <div class="tile__head">
            <h2 id="latest-heading" class="eyebrow">Latest digest</h2>
            <LiveIndicator :status="liveStatus" />
          </div>
          <p class="summary-text">{{ okLatest.summary }}</p>
          <p class="meta"><TimeAgo :date="okLatest.created_at" /> · {{ formatDateTime(okLatest.created_at) }}</p>
          <footer class="provenance">{{ formatProvenance(okLatest) }}</footer>
        </article>

        <article class="tile tile--tone" :class="`tile--tone-${okLatest.tone}`" aria-labelledby="tone-heading">
          <h2 id="tone-heading" class="eyebrow">Tone</h2>
          <span class="tone-stamp" aria-hidden="true">{{ toneMeta.symbol }}</span>
          <p class="tone-label">{{ toneMeta.label }}</p>
          <p class="meta">From {{ okLatest.headline_count }} headlines</p>
        </article>

        <article v-if="okLatest.key_points.length" class="tile tile--glass span-2" aria-labelledby="points-heading">
          <h2 id="points-heading" class="tile__title">Key points</h2>
          <KeyPointList :points="okLatest.key_points" />
        </article>

        <article v-if="okLatest.headlines.length" class="tile tile--glass span-2" aria-labelledby="headlines-heading">
          <h2 id="headlines-heading" class="tile__title">
            Source headlines <span class="count-pill">{{ okLatest.headline_count }}</span>
          </h2>
          <HeadlineList :headlines="okLatest.headlines" />
        </article>
      </template>

      <section v-else-if="latest" class="tile span-4" aria-label="Latest digest">
        <DigestView :digest="latest" />
      </section>

      <StateBlock
        v-else
        class="span-4"
        kind="empty"
        :title="appConfig.labels.noDigestYet"
        message="The first digest appears here automatically once the automation finishes."
      />

      <section class="tile tile--glass span-4" aria-label="Previous digests">
        <DigestTimeline :digests="previous" />
      </section>
    </div>
  </div>
</template>
