<script setup>
// Compact, self-contained digest (used in the history timeline and for a failed latest digest).
// The detail page lays out a successful latest digest as separate bento tiles instead.
import { computed } from 'vue'
import { formatDateTime, formatProvenance } from '../utils/format.js'
import DigestStatus from './DigestStatus.vue'
import HeadlineList from './HeadlineList.vue'
import KeyPointList from './KeyPointList.vue'
import TimeAgo from './TimeAgo.vue'
import ToneBadge from './ToneBadge.vue'

const props = defineProps({
  /** @type {import('../services/digests.js').Digest} */
  digest: { type: Object, required: true },
})

const failed = computed(() => props.digest.status === 'failed')
</script>

<template>
  <article class="digest">
    <header class="digest__head">
      <DigestStatus v-if="failed" kind="failed" label="Digest failed" />
      <ToneBadge v-else :tone="digest.tone" />
      <span class="meta"><TimeAgo :date="digest.created_at" /> · {{ formatDateTime(digest.created_at) }}</span>
    </header>

    <p v-if="failed" class="digest__error">
      {{ digest.error_message || 'The automation reported a failure without details.' }}
    </p>

    <template v-else>
      <p class="digest__summary">{{ digest.summary }}</p>
      <div class="digest__columns">
        <section v-if="digest.key_points.length">
          <h3 class="eyebrow">Key points</h3>
          <KeyPointList :points="digest.key_points" />
        </section>
        <section v-if="digest.headlines.length">
          <h3 class="eyebrow">Source headlines · {{ digest.headline_count }}</h3>
          <HeadlineList :headlines="digest.headlines" />
        </section>
      </div>
    </template>

    <footer class="provenance">{{ formatProvenance(digest) }}</footer>
  </article>
</template>
