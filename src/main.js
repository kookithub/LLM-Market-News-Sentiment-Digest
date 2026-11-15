import { createApp } from 'vue'
import App from './App.vue'
import { router } from './router/index.js'
import { appConfig } from './config/app.config.js'
import './style.css'

// Tone colors are defined once in app.config.js and exposed to CSS as variables.
const root = document.documentElement
for (const [tone, colors] of Object.entries(appConfig.tones)) {
  root.style.setProperty(`--tone-${tone}-fg`, colors.fg)
  root.style.setProperty(`--tone-${tone}-bg`, colors.bg)
  root.style.setProperty(`--tone-${tone}-border`, colors.border)}

createApp(App).use(router).mount('#app')
