<script setup>
import { computed } from 'vue'
import { useNow } from '../utils/useNow.js'
import { formatDateTime, formatTimeAgo } from '../utils/format.js'

const props = defineProps({
  date: { type: [String, Date], required: true },
})

const now = useNow()
const iso = computed(() => {
  const d = new Date(props.date)
  return Number.isNaN(d.getTime()) ? undefined : d.toISOString()
})
const label = computed(() => formatTimeAgo(props.date, now.value))
</script>

<template>
  <time v-if="label" :datetime="iso" :title="formatDateTime(date)">{{ label }}</time>
</template>
