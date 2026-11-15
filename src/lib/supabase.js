// The ONLY file that creates the Supabase client.
// Swapping the database means replacing this file and src/services/ — nothing else.
import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
// Supabase calls the public key "anon" (legacy) or "publishable" (newer); accept either name.
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

/** True when the URL and a public key are present. */
export const isSupabaseConfigured = Boolean(url && anonKey)

// No auth in this app, so don't persist or refresh sessions.
const client = isSupabaseConfigured
  ? createClient(url, anonKey, { auth: { persistSession: false, autoRefreshToken: false } })
  : null

/**
 * Returns the shared Supabase client.
 * @returns {import('@supabase/supabase-js').SupabaseClient}
 * @throws {Error} when VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY are missing.
 */
export function getSupabase() {
  if (!client) {
    throw new Error(
      'Supabase is not configured. Copy .env.example to .env, fill in VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY (or VITE_SUPABASE_PUBLISHABLE_KEY), then restart `npm run dev`.',
    )
  }
  return client
}
