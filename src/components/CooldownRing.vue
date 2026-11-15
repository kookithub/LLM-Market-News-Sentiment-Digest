<script setup>
// Arc gauge for the refresh cooldown: the gold arc shrinks as the wait runs out.
import { computed } from 'vue'
import { formatClock } from '../utils/format.js'

const props = defineProps({
  remainingMs: { type: Number, required: true },
  totalMs: { type: Number, required: true },
})

const R = 21
const CIRC = 2 * Math.PI * R
const dash = computed(() => {
  const fraction = props.totalMs > 0 ? Math.min(1, props.remainingMs / props.totalMs) : 0
  return `${(CIRC * fraction).toFixed(2)} ${CIRC.toFixed(2)}`
})
</script>

<template>
  <span class="cooldown" role="img" :aria-label="`Refresh available in ${formatClock(remainingMs)}`">
    <svg viewBox="0 0 52 52" aria-hidden="true">
      <circle cx="26" cy="26" :r="R" class="cooldown__track" />
      <circle cx="26" cy="26" :r="R" class="cooldown__arc" :stroke-dasharray="dash" transform="rotate(-90 26 26)" />
    </svg>
    <span class="cooldown__text" aria-hidden="true">{{ formatClock(remainingMs) }}</span>
  </span>
</template>
