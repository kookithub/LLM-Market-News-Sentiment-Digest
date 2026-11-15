<script setup>
import { RouterView } from 'vue-router'
import AppHeader from './components/AppHeader.vue'
import { appConfig } from './config/app.config.js'
</script>

<template>
  <a class="skip-link" href="#main">Skip to content</a>
  <AppHeader />
  <main id="main" tabindex="-1">
    <RouterView />
  </main>
  <footer class="site-footer">
    <div class="container">
      {{ appConfig.app.name }} · AI-generated summaries of third-party headlines. They can be wrong and are not
      investment advice.
    </div>
  </footer>
</template>
