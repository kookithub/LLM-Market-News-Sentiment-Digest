<script setup>
import { computed } from 'vue'
import { appConfig } from '../config/app.config.js'

const props = defineProps({
  kind: { type: String, required: true }, // 'pending' | 'stalled' | 'failed'
  label: { type: String, default: '' }, // overrides the default label from app.config.js
})

const DEFAULT_LABELS = {
  pending: appConfig.labels.generating,
  stalled: appConfig.labels.stalled,
  failed: appConfig.labels.failed,
}
const text = computed(() => props.label || DEFAULT_LABELS[props.kind] || '')
</script>

<template>
  <span class="digest-status" :class="`digest-status--${kind}`">
    <span v-if="kind === 'pending'" class="pulse" aria-hidden="true"></span>
    <span v-else class="digest-status__icon" aria-hidden="true">!</span>
    {{ text }}
  </span>
</template>
