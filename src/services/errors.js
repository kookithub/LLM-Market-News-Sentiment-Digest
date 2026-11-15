/** Error with a user-facing message and a stable code the UI can branch on. */
export class ServiceError extends Error {
  /**
   * @param {string} message  Human-readable message, safe to show in the UI.
   * @param {string} [code]   'duplicate' | 'not_found' | 'network' | 'unknown' | a Postgres code.
   * @param {unknown} [cause] Original error, for debugging.
   */
  constructor(message, code = 'unknown', cause) {
    super(message)
    this.name = 'ServiceError'
    this.code = code
    this.cause = cause
  }
}

/**
 * Converts a Supabase/PostgREST error into a ServiceError with a friendly message.
 * @param {{ code?: string, message?: string }} error
 * @param {string} action  What we were doing, e.g. "load the watchlist".
 * @returns {ServiceError}
 */
export function toServiceError(error, action) {
  if (error instanceof ServiceError) return error
  const code = error?.code ?? 'unknown'
  if (code === '23505') return new ServiceError('That symbol is already on the watchlist.', 'duplicate', error)
  if (code === '42501') return new ServiceError(`Permission denied while trying to ${action}. Check the grants in supabase/schema.sql.`, code, error)
  if (code === '42P01') return new ServiceError(`Table not found while trying to ${action}. Run supabase/schema.sql first.`, code, error)
  if (/fetch|network/i.test(error?.message ?? '')) {
    return new ServiceError(`Network error while trying to ${action}. Check your connection (or whether the Supabase project is paused).`, 'network', error)
  }
  return new ServiceError(`Could not ${action}: ${error?.message ?? 'unknown error'}`, code, error)
}
