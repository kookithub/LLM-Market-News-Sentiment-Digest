// Reads news_digests. The app never writes digests: the automation does.
// Row shape = automation/contracts/digest-record.schema.json.
import { getSupabase } from '../lib/supabase.js'
import { toServiceError } from './errors.js'

export const DIGESTS_TABLE = 'news_digests'

/**
 * @typedef {Object} Headline
 * @property {string} title
 * @property {string} link
 * @property {string} source
 * @property {string|null} published_at  ISO date string
 */

/**
 * @typedef {Object} Digest
 * @property {string} id
 * @property {string} created_at
 * @property {string} watchlist_id
 * @property {'ok'|'failed'} status
 * @property {string|null} error_message
 * @property {'positive'|'neutral'|'negative'|null} tone
 * @property {string|null} summary
 * @property {string[]} key_points
 * @property {number} headline_count
 * @property {Headline[]} headlines
 * @property {string|null} ai_provider
 * @property {string|null} ai_model
 * @property {string|null} prompt_version
 * @property {string|null} news_source
 */

/**
 * Makes a raw row safe to render: arrays are always arrays, counts always numbers.
 * Tolerant on purpose so one malformed row never breaks the page.
 * @param {Record<string, any>} row  A news_digests row.
 * @returns {Digest}
 */
export function normalizeDigest(row) {
  const keyPoints = toArray(row.key_points).map(String)
  const headlines = toArray(row.headlines)
    .filter((h) => h && typeof h === 'object')
    .map((h) => ({
      title: h.title ?? '',
      // Only http(s) links are rendered as anchors; anything else is dropped.
      link: /^https?:\/\//i.test(h.link ?? '') ? h.link : '',
      source: h.source ?? '',
      published_at: h.published_at ?? null,
    }))
  return {
    ...row,
    status: row.status === 'failed' ? 'failed' : 'ok',
    key_points: keyPoints,
    headlines,
    headline_count: row.headline_count ?? headlines.length,
  }
}

/**
 * Lists digests for one asset, newest first.
 * @param {string} watchlistId
 * @param {{ limit?: number }} [options]
 * @returns {Promise<Digest[]>}
 */
export async function listDigestsForAsset(watchlistId, { limit = 20 } = {}) {
  const { data, error } = await getSupabase()
    .from(DIGESTS_TABLE)
    .select('*')
    .eq('watchlist_id', watchlistId)
    .order('created_at', { ascending: false })
    .limit(limit)
  if (error) throw toServiceError(error, 'load digests')
  return data.map(normalizeDigest)
}

function toArray(value) {
  if (Array.isArray(value)) return value
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value)
      return Array.isArray(parsed) ? parsed : []
    } catch {
      return value.split('\n').map((s) => s.trim()).filter(Boolean)
    }
  }
  return []
}
