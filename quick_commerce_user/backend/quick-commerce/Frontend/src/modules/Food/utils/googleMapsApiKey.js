/**
 * Google Maps API key accessor.
 *
 * Delegates to `src/config/env.js`, which is the single source of truth.
 * Kept as a module so the existing async call sites do not have to change.
 */
import { ENV, MAPS_ENABLED } from "@/config/env";

/**
 * @returns {Promise<string>} Google Maps API key, or "" when unconfigured.
 */
export async function getGoogleMapsApiKey() {
  return ENV.GOOGLE_MAPS_API_KEY;
}

/** Synchronous accessor for render paths that cannot await. */
export function googleMapsApiKey() {
  return ENV.GOOGLE_MAPS_API_KEY;
}

export function isGoogleMapsEnabled() {
  return MAPS_ENABLED;
}

/**
 * Retained for call-site compatibility. The key is now a build-time constant,
 * so there is no cache to clear.
 */
export function clearGoogleMapsApiKeyCache() {}
