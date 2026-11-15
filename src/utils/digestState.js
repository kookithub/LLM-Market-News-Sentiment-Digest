// Pure helpers that decide what an asset's digest status is and whether Refresh is allowed.
// No database access: they only look at the rows the services return.
import { appConfig } from '../config/app.config.js'

const MINUTE = 60_000

/**
 * @typedef {'pending'|'stalled'|'failed'|'ok'} DigestStateKind
 * pending  – no digest yet, or a refresh was requested after the latest digest
 * stalled  – pending for longer than refresh.pendingStaleMinutes
 * failed   – latest digest has status 'failed'
 * ok       – latest digest is a normal briefing
 */

/**
 * @param {{ last_requested_at: string }} asset
 * @param {{ created_at: string, status: string } | null} latestDigest
 * @param {number} now  Epoch ms.
 * @returns {{ kind: DigestStateKind, requestedAt: number }}
 */
export function getDigestState(asset, latestDigest, now) {
  const requestedAt = Date.parse(asset.last_requested_at)
  const digestAt = latestDigest ? Date.parse(latestDigest.created_at) : -Infinity
  if (requestedAt > digestAt) {
    const stalled = now - requestedAt > appConfig.refresh.pendingStaleMinutes * MINUTE
    return { kind: stalled ? 'stalled' : 'pending', requestedAt }
  }
  return { kind: latestDigest.status === 'failed' ? 'failed' : 'ok', requestedAt }
}

/**
 * Decides whether the Refresh button is enabled and, if not, for how long.
 * @param {{ last_requested_at: string }} asset
 * @param {{ created_at: string, status: string } | null} latestDigest
 * @param {number} now  Epoch ms.
 * @returns {{ allowed: boolean, reason: 'ready'|'pending'|'cooldown', remainingMs: number, totalMs: number }}
 *   totalMs = length of the cooldown that applies (for progress gauges).
 */
export function getRefreshAvailability(asset, latestDigest, now) {
  const { kind } = getDigestState(asset, latestDigest, now)
  if (kind === 'pending') return { allowed: false, reason: 'pending', remainingMs: 0, totalMs: 0 }
  if (kind === 'stalled') return { allowed: true, reason: 'ready', remainingMs: 0, totalMs: 0 }

  const minutes = kind === 'failed' ? appConfig.refresh.failedRetryCooldownMinutes : appConfig.refresh.cooldownMinutes
  const totalMs = minutes * MINUTE
  const readyAt = Date.parse(latestDigest.created_at) + totalMs
  const remainingMs = Math.max(0, readyAt - now)
  return remainingMs > 0
    ? { allowed: false, reason: 'cooldown', remainingMs, totalMs }
    : { allowed: true, reason: 'ready', remainingMs: 0, totalMs }
}
