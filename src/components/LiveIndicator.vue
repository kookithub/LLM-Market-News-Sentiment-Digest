<script setup>
import { computed } from 'vue'

const props = defineProps({
  status: { type: String, default: 'off' }, // 'connecting' | 'live' | 'error' | 'off'
})

const LABELS = {
  connecting: 'Connecting…',
  live: 'Live updates on',
  error: 'Live updates unavailable',
  off: 'Live updates off',
}
const label = computed(() => LABELS[props.status] ?? LABELS.off)
</script>

<template>
  <span class="live" :class="`live--${status}`" role="status">
    <span class="live__dot" aria-hidden="true"></span>
    {{ label }}
  </span>
</template>
