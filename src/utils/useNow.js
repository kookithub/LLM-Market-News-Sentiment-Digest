import { onBeforeUnmount, ref } from 'vue'
import { appConfig } from '../config/app.config.js'

// One shared timer for every "X min ago" label and countdown, started on first use
// and stopped when the last component using it unmounts.
const now = ref(Date.now())
let users = 0
let timer = null

/**
 * Reactive current time (epoch ms) that ticks every appConfig.ui.clockTickMs.
 * Must be called from a component's setup.
 * @returns {import('vue').Ref<number>}
 */
export function useNow() {
  users += 1
  if (!timer) {
    now.value = Date.now()
    timer = setInterval(() => (now.value = Date.now()), appConfig.ui.clockTickMs)
  }
  onBeforeUnmount(() => {
    users -= 1
    if (users === 0) {
      clearInterval(timer)
      timer = null
    }
  })
  return now
}
