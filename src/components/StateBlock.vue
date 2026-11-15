<script setup>
import BrandMark from './BrandMark.vue'

defineProps({
  kind: { type: String, default: 'empty' }, // 'loading' | 'empty' | 'error'
  title: { type: String, required: true },
  message: { type: String, default: '' },
})
</script>

<template>
  <div class="tile tile--glass tile--pattern state" :class="`state--${kind}`" :role="kind === 'error' ? 'alert' : 'status'">
    <!-- Loading: a turning wave curl -->
    <span v-if="kind === 'loading'" class="curl-spinner" aria-hidden="true"></span>
    <span v-else-if="kind === 'error'" class="state__icon" aria-hidden="true">!</span>
    <BrandMark v-else class="state__mark" />
    <p class="state__title">{{ title }}</p>
    <p v-if="message" class="state__message">{{ message }}</p>
    <div v-if="$slots.default" class="state__actions"><slot /></div>
  </div>
</template>
