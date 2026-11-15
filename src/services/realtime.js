// Live updates for new digests (Supabase Realtime, postgres_changes).
// Requires news_digests in the supabase_realtime publication (see schema.sql).
import { appConfig } from '../config/app.config.js'
import { getSupabase, isSupabaseConfigured } from '../lib/supabase.js'
import { DIGESTS_TABLE, normalizeDigest } from './digests.js'

/** @typedef {'connecting'|'live'|'error'|'off'} LiveStatus */

const STATUS_MAP = {
  SUBSCRIBED: 'live',
  CHANNEL_ERROR: 'error',
  TIMED_OUT: 'error',
  CLOSED: 'off',
}

let channelSeq = 0

/**
 * Calls onInsert whenever a new digest row is written.
 * @param {Object} options
 * @param {(digest: import('./digests.js').Digest) => void} options.onInsert
 * @param {string} [options.watchlistId]  Only digests for this asset (omit for all).
 * @param {(status: LiveStatus) => void} [options.onStatus]
 * @returns {() => void} Unsubscribe function. Safe to call more than once.
 */
export function subscribeToNewDigests({ onInsert, watchlistId, onStatus }) {
  if (!appConfig.realtime.enabled || !isSupabaseConfigured) {
    onStatus?.('off')
    return () => {}
  }

  const client = getSupabase()
  const filter = watchlistId ? { filter: `watchlist_id=eq.${watchlistId}` } : {}
  onStatus?.('connecting')

  const channel = client
    .channel(`digests-${watchlistId ?? 'all'}-${++channelSeq}`)
    .on('postgres_changes', { event: 'INSERT', schema: 'public', table: DIGESTS_TABLE, ...filter }, (payload) =>
      onInsert(normalizeDigest(payload.new)),
    )
    .subscribe((status) => onStatus?.(STATUS_MAP[status] ?? 'connecting'))

  let closed = false
  return () => {
    if (closed) return
    closed = true
    client.removeChannel(channel)
  }
}
