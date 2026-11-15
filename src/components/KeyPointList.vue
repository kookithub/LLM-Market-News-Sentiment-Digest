<script setup>
defineProps({
  points: { type: Array, required: true },
})
</script>

<template>
  <ol class="key-points">
    <li v-for="(point, i) in points" :key="i">
      <span class="key-points__num" aria-hidden="true">{{ String(i + 1).padStart(2, '0') }}</span>
      <span>{{ point }}</span>
    </li>
  </ol>
</template>
