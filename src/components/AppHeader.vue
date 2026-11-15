<script setup>
import { RouterLink } from 'vue-router'
import AppIcon from './AppIcon.vue'
import BrandMark from './BrandMark.vue'
</script>

<template>
  <header class="masthead">
    <div class="container">
      <div class="masthead__bar">
        <RouterLink to="/" class="brand" aria-label="LLM Market News Sentiment Digest, home">
          <BrandMark />
          <span class="brand__name">LLM Market News<span> Sentiment Digest</span></span>
        </RouterLink>
        <nav class="masthead__nav" aria-label="Main">
          <RouterLink to="/" class="nav-link nav-link--hide-sm" exact-active-class="is-active">Dashboard</RouterLink>
          <RouterLink to="/new" class="btn btn--primary btn--sm" active-class="is-active">
            <AppIcon name="plus" :size="16" /> Add asset
          </RouterLink>
        </nav>
      </div>
    </div>
  </header>
</template>
