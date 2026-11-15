<script setup>
// In-page confirmation (instead of window.confirm). Focuses Cancel on open; Escape cancels.
import { onMounted, ref, useId } from 'vue'

defineProps({
  title: { type: String, required: true },
  message: { type: String, default: '' },
  confirmLabel: { type: String, default: 'Confirm' },
  busyLabel: { type: String, default: 'Working…' },
  busy: { type: Boolean, default: false },
})
const emit = defineEmits(['confirm', 'cancel'])

const id = useId()
const cancelButton = ref(null)
onMounted(() => cancelButton.value?.focus())
</script>

<template>
  <div
    class="confirm"
    role="alertdialog"
    :aria-labelledby="`${id}-title`"
    :aria-describedby="`${id}-msg`"
    @keydown.esc="!busy && emit('cancel')"
  >
    <p :id="`${id}-title`" class="confirm__title">{{ title }}</p>
    <p :id="`${id}-msg`" class="confirm__message">{{ message }}</p>
    <div class="confirm__actions">
      <button ref="cancelButton" type="button" class="btn btn--sm" :disabled="busy" @click="emit('cancel')">Cancel</button>
      <button type="button" class="btn btn--danger btn--sm" :disabled="busy" @click="emit('confirm')">
        <span v-if="busy" class="spinner btn__spinner" aria-hidden="true"></span>
        {{ busy ? busyLabel : confirmLabel }}
      </button>
    </div>
  </div>
</template>
