<script setup>
import { appConfig } from '../config/app.config.js'

defineProps({ type: { type: String, required: true } })
</script>

<template>
  <span class="type-badge">{{ appConfig.assetTypes[type]?.label ?? type }}</span>
</template>
