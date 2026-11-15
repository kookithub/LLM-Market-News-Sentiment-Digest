<script setup>
import AppIcon from './AppIcon.vue'
import TimeAgo from './TimeAgo.vue'

defineProps({
  /** @type {import('../services/digests.js').Headline[]} */
  headlines: { type: Array, required: true },
})
</script>

<template>
  <ul class="headlines">
    <li v-for="(h, i) in headlines" :key="i">
      <a v-if="h.link" :href="h.link" target="_blank" rel="noopener noreferrer" class="headlines__item">
        <span class="headlines__title">{{ h.title }}</span>
        <span class="headlines__meta">
          {{ h.source }}<template v-if="h.source && h.published_at"> · </template>
          <TimeAgo v-if="h.published_at" :date="h.published_at" />
        </span>
        <AppIcon name="arrow-up-right" :size="16" class="headlines__icon" />
        <span class="sr-only"> (opens in a new tab)</span>
      </a>
      <div v-else class="headlines__item">
        <span class="headlines__title">{{ h.title }}</span>
        <span class="headlines__meta">{{ h.source }}</span>
      </div>
    </li>
  </ul>
</template>
