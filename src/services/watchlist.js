// Reads and writes the watchlist (primary) table.
import { getSupabase } from '../lib/supabase.js'
import { DIGESTS_TABLE, normalizeDigest } from './digests.js'
import { ServiceError, toServiceError } from './errors.js'

const TABLE = 'watchlist'

/**
 * @typedef {Object} Asset
 * @property {string} id
 * @property {string} created_at
 * @property {string} symbol            Uppercase ticker.
 * @property {string} name
 * @property {'stock'|'crypto'} asset_type
 * @property {string} search_query
 * @property {string} added_by
 * @property {string} last_requested_at  Server time of the last digest request.
 */

/**
 * @typedef {Asset & { latestDigest: import('./digests.js').Digest | null }} AssetWithDigest
 */

/**
 * Lists every asset with its most recent digest (one query, embedded join).
 * @returns {Promise<AssetWithDigest[]>} Sorted by symbol.
 */
export async function listAssetsWithLatestDigest() {
  const { data, error } = await getSupabase()
    .from(TABLE)
    .select(`*, ${DIGESTS_TABLE}(*)`)
    .order('symbol', { ascending: true })
    .order('created_at', { referencedTable: DIGESTS_TABLE, ascending: false })
    .limit(1, { referencedTable: DIGESTS_TABLE })
  if (error) throw toServiceError(error, 'load the watchlist')
  return data.map(({ [DIGESTS_TABLE]: digests, ...asset }) => ({
    ...asset,
    latestDigest: digests?.length ? normalizeDigest(digests[0]) : null,
  }))
}

/**
 * Fetches one asset.
 * @param {string} id
 * @returns {Promise<Asset|null>} null when it doesn't exist (or the id is malformed).
 */
export async function getAsset(id) {
  const { data, error } = await getSupabase().from(TABLE).select('*').eq('id', id).maybeSingle()
  if (error?.code === '22P02') return null // invalid uuid in the URL
  if (error) throw toServiceError(error, 'load the asset')
  return data
}

/**
 * Checks whether a symbol is already on the watchlist.
 * @param {string} symbol  Any case; compared uppercase.
 * @returns {Promise<boolean>}
 */
export async function symbolExists(symbol) {
  const { count, error } = await getSupabase()
    .from(TABLE)
    .select('id', { count: 'exact', head: true })
    .eq('symbol', symbol.trim().toUpperCase())
  if (error) throw toServiceError(error, 'check the symbol')
  return (count ?? 0) > 0
}

/**
 * Adds an asset. The INSERT fires the Database Webhook, which starts the first digest.
 * @param {{ symbol: string, name: string, asset_type: 'stock'|'crypto', search_query: string, added_by: string }} input
 * @returns {Promise<Asset>} The created row.
 * @throws {ServiceError} code 'duplicate' when the symbol already exists.
 */
export async function createAsset(input) {
  const row = {
    symbol: input.symbol.trim().toUpperCase(),
    name: input.name.trim(),
    asset_type: input.asset_type,
    search_query: input.search_query.trim(),
    added_by: input.added_by.trim(),
  }
  const { data, error } = await getSupabase().from(TABLE).insert(row).select().single()
  if (error) throw toServiceError(error, 'add the asset')
  return data
}

/**
 * Asks for a new digest by bumping last_requested_at.
 * The UPDATE fires the same webhook; a DB trigger replaces the value with server time.
 * @param {string} id
 * @returns {Promise<Asset>} The updated row (with the server timestamp).
 */
export async function requestDigest(id) {
  const { data, error } = await getSupabase()
    .from(TABLE)
    .update({ last_requested_at: new Date().toISOString() })
    .eq('id', id)
    .select()
    .maybeSingle()
  if (error) throw toServiceError(error, 'request a new digest')
  if (!data) throw new ServiceError('This asset no longer exists.', 'not_found')
  return data
}

/**
 * Deletes an asset and (via ON DELETE CASCADE) all its digests.
 * @param {string} id
 * @returns {Promise<void>}
 */
export async function deleteAsset(id) {
  const { error } = await getSupabase().from(TABLE).delete().eq('id', id)
  if (error) throw toServiceError(error, 'delete the asset')
}
