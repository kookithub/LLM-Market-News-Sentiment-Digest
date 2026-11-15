<script setup>
import { formatDateTime } from '../utils/format.js'
import DigestStatus from './DigestStatus.vue'
import DigestView from './DigestView.vue'
import ToneBadge from './ToneBadge.vue'

defineProps({
  /** Older digests, newest first. @type {import('../services/digests.js').Digest[]} */
  digests: { type: Array, required: true },
})
</script>

<template>
  <!-- Native <details> gives keyboard and screen-reader support for free. -->
  <details class="timeline">
    <summary class="timeline__toggle">
      <span class="tile__title">Previous digests <span class="count-pill">{{ digests.length }}</span></span>
      <span class="round-icon chevron" aria-hidden="true">▾</span>
    </summary>

    <p v-if="!digests.length" class="meta timeline__empty">No earlier digests yet. Each refresh adds one here.</p>

    <ol v-else class="timeline__list">
      <li v-for="d in digests" :key="d.id" class="timeline__item">
        <details class="timeline__entry">
          <summary>
            <span class="timeline__head">
              <span class="meta">{{ formatDateTime(d.created_at) }}</span>
              <DigestStatus v-if="d.status === 'failed'" kind="failed" label="Failed" />
              <ToneBadge v-else :tone="d.tone" size="sm" />
            </span>
            <span class="chevron" aria-hidden="true">▾</span>
            <span class="timeline__excerpt">{{ d.summary || d.error_message }}</span>
          </summary>
          <DigestView :digest="d" />
        </details>
      </li>
    </ol>
  </details>
</template>
