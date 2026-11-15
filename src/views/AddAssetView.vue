<script setup>
import { nextTick, onBeforeUnmount, reactive, ref, watch } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { appConfig } from '../config/app.config.js'
import { createAsset, symbolExists } from '../services/watchlist.js'
import AppIcon from '../components/AppIcon.vue'

const router = useRouter()
const rules = appConfig.form

const form = reactive({
  symbol: '',
  name: '',
  asset_type: rules.defaultAssetType,
  search_query: '',
  added_by: '',
})
const errors = reactive({ symbol: '', name: '', search_query: '', added_by: '' })
const queryEdited = ref(false)
const phase = ref('idle') // 'idle' | 'submitting' | 'success' | 'error'
const submitError = ref('')
const created = ref(null)
const formEl = ref(null)
let redirectTimer = null

// --- Search query auto-fill: "<name> <symbol>" until the user edits it ---
const defaultQuery = () => `${form.name.trim()} ${form.symbol.trim()}`.trim()
watch(
  () => [form.name, form.symbol],
  () => {
    if (!queryEdited.value) form.search_query = defaultQuery()
  },
)
function onQueryInput() {
  queryEdited.value = form.search_query !== defaultQuery()
}
function resetQuery() {
  queryEdited.value = false
  form.search_query = defaultQuery()
  errors.search_query = ''
}

watch(
  () => form.symbol,
  (value) => {
    const cleaned = value.toUpperCase().replace(/\s+/g, '')
    if (cleaned !== value) form.symbol = cleaned
  },
)

// --- Validation ---
function validateField(field) {
  const value = form[field].trim()
  const limits = {
    symbol: rules.symbolMaxLength,
    name: rules.nameMaxLength,
    search_query: rules.searchQueryMaxLength,
    added_by: rules.addedByMaxLength,
  }
  let message = ''
  if (!value) message = 'This field is required.'
  else if (value.length > limits[field]) message = `Use at most ${limits[field]} characters.`
  else if (field === 'symbol' && !rules.symbolPattern.test(value)) message = 'Use letters, digits, "." or "-" only.'
  errors[field] = message
  return !message
}

function validateAll() {
  return ['symbol', 'name', 'search_query', 'added_by'].map(validateField).every(Boolean)
}

async function checkDuplicate() {
  if (!validateField('symbol')) return
  try {
    if (await symbolExists(form.symbol)) errors.symbol = `${form.symbol} is already on your watchlist.`
  } catch {
    // Not fatal here: the check runs again on submit and the DB enforces uniqueness.
  }
}

async function focusFirstError() {
  await nextTick()
  formEl.value?.querySelector('[aria-invalid="true"]')?.focus()
}

// --- Submit ---
async function submit() {
  if (phase.value === 'submitting' || phase.value === 'success') return
  submitError.value = ''
  if (!validateAll()) return focusFirstError()

  phase.value = 'submitting'
  try {
    if (await symbolExists(form.symbol)) {
      errors.symbol = `${form.symbol} is already on your watchlist.`
      phase.value = 'idle'
      return focusFirstError()
    }
    created.value = await createAsset({ ...form })
    phase.value = 'success'
    redirectTimer = setTimeout(() => router.push({ name: 'dashboard' }), appConfig.ui.redirectDelayMs)
  } catch (error) {
    if (error.code === 'duplicate') {
      errors.symbol = error.message
      phase.value = 'idle'
      return focusFirstError()
    }
    submitError.value = error.message
    phase.value = 'error'
  }
}

onBeforeUnmount(() => clearTimeout(redirectTimer))
</script>

<template>
  <div class="container page">
    <RouterLink to="/" class="back-link"><AppIcon name="arrow-left" :size="16" /> Dashboard</RouterLink>

    <div class="bento bento--form">
    <form ref="formEl" class="tile form-tile span-3" novalidate @submit.prevent="submit">
      <header class="form-tile__head">
        <h1 class="page__title">Add an asset</h1>
        <p class="page__lede">Track a stock or a cryptocurrency. Its first AI digest is written as soon as you save.</p>
      </header>

      <div v-if="phase === 'success'" class="alert alert--success" role="status">
        <AppIcon name="check" :size="18" />
        <span><strong>{{ created?.symbol }}</strong> added. Its first digest is being generated — taking you to the dashboard…</span>
      </div>
      <div v-if="phase === 'error'" class="alert" role="alert">{{ submitError }}</div>

      <fieldset class="form-grid fieldset-reset" :disabled="phase === 'submitting' || phase === 'success'">
        <legend class="sr-only">Asset details</legend>

        <div class="form-grid form-grid--2">
          <div class="field">
            <label for="f-symbol" class="field__label">Symbol</label>
            <input
              id="f-symbol"
              v-model="form.symbol"
              class="input input--mono"
              type="text"
              placeholder="NVDA"
              autocomplete="off"
              autocapitalize="characters"
              spellcheck="false"
              :maxlength="rules.symbolMaxLength"
              required
              :aria-invalid="Boolean(errors.symbol)"
              aria-describedby="f-symbol-hint f-symbol-error"
              @blur="checkDuplicate"
              @input="errors.symbol = ''"
            />
            <span id="f-symbol-hint" class="field__hint">Up to {{ rules.symbolMaxLength }} characters.</span>
            <span id="f-symbol-error" class="field__error" aria-live="polite">{{ errors.symbol }}</span>
          </div>

          <div class="field">
            <label for="f-name" class="field__label">Name</label>
            <input
              id="f-name"
              v-model="form.name"
              class="input"
              type="text"
              placeholder="NVIDIA"
              autocomplete="off"
              :maxlength="rules.nameMaxLength"
              required
              :aria-invalid="Boolean(errors.name)"
              aria-describedby="f-name-error"
              @blur="validateField('name')"
              @input="errors.name = ''"
            />
            <span id="f-name-error" class="field__error" aria-live="polite">{{ errors.name }}</span>
          </div>
        </div>

        <fieldset class="field">
          <legend class="field__label">Type</legend>
          <div class="segmented segmented--block">
            <label v-for="(meta, value) in appConfig.assetTypes" :key="value" class="segmented__option">
              <input v-model="form.asset_type" type="radio" name="asset-type" :value="value" />
              <span>{{ meta.label }}</span>
            </label>
          </div>
        </fieldset>

        <div class="field">
          <div class="field__row">
            <label for="f-query" class="field__label">News search query</label>
            <button v-if="queryEdited" type="button" class="link-button" @click="resetQuery">Reset to default</button>
          </div>
          <input
            id="f-query"
            v-model="form.search_query"
            class="input"
            type="text"
            placeholder="NVIDIA NVDA"
            autocomplete="off"
            :maxlength="rules.searchQueryMaxLength"
            required
            :aria-invalid="Boolean(errors.search_query)"
            aria-describedby="f-query-hint f-query-error"
            @input="onQueryInput(); errors.search_query = ''"
            @blur="validateField('search_query')"
          />
          <span id="f-query-hint" class="field__hint">
            Filled in from name and symbol. Edit it to sharpen the news search (e.g. add "stock" or "crypto").
          </span>
          <span id="f-query-error" class="field__error" aria-live="polite">{{ errors.search_query }}</span>
        </div>

        <div class="field">
          <label for="f-added-by" class="field__label">Added by</label>
          <input
            id="f-added-by"
            v-model="form.added_by"
            class="input"
            type="text"
            placeholder="Your name"
            autocomplete="name"
            :maxlength="rules.addedByMaxLength"
            required
            :aria-invalid="Boolean(errors.added_by)"
            aria-describedby="f-added-by-error"
            @blur="validateField('added_by')"
            @input="errors.added_by = ''"
          />
          <span id="f-added-by-error" class="field__error" aria-live="polite">{{ errors.added_by }}</span>
        </div>
      </fieldset>

      <div class="form-actions">
        <button type="submit" class="btn btn--primary" :disabled="phase === 'submitting' || phase === 'success'">
          <span v-if="phase === 'submitting'" class="spinner btn__spinner" aria-hidden="true"></span>
          <AppIcon v-else name="plus" :size="16" />
          {{ phase === 'submitting' ? 'Adding…' : 'Add to watchlist' }}
        </button>
        <RouterLink to="/" class="btn btn--ghost">Cancel</RouterLink>
      </div>
    </form>

    <!-- Live preview + what happens next -->
    <aside class="aside-stack" aria-label="Preview and next steps">
      <div class="tile tile--glass preview-tile" aria-hidden="true">
        <p class="eyebrow">Preview</p>
        <div class="preview-card">
          <span class="ticker preview-card__symbol">{{ form.symbol || 'SYMBOL' }}</span>
          <span class="preview-card__name">{{ form.name || 'Asset name' }}</span>
          <span class="type-badge">{{ appConfig.assetTypes[form.asset_type]?.label }}</span>
        </div>
        <p class="meta">News search: “{{ form.search_query || '…' }}”</p>
      </div>
      <div class="tile tile--glass tile--pattern steps-tile">
        <p class="eyebrow">What happens next</p>
        <ol class="steps">
          <li><span class="steps__num">1</span>Your asset is saved to the watchlist.</li>
          <li><span class="steps__num">2</span>The automation collects the latest headlines.</li>
          <li><span class="steps__num">3</span>AI writes a short briefing with a tone.</li>
          <li><span class="steps__num">4</span>It appears on your dashboard — usually within 30 seconds.</li>
        </ol>
      </div>
    </aside>
    </div>
  </div>
</template>
