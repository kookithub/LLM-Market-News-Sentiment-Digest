<script setup>
// Tone pill: a small colored marker (▲ ● ▼) plus the English label.
import { computed } from 'vue'
import { appConfig } from '../config/app.config.js'

const props = defineProps({
  tone: { type: String, default: null },
  size: { type: String, default: 'md' }, // 'md' | 'sm'
})

const meta = computed(() => appConfig.tones[props.tone] ?? null)
</script>

<template>
  <span v-if="meta" class="tone-badge" :class="[`tone-badge--${tone}`, `tone-badge--${size}`]">
    <span class="tone-badge__mark" aria-hidden="true">{{ meta.symbol }}</span>
    <span class="sr-only">Tone:</span>
    {{ meta.label }}
  </span>
</template>
