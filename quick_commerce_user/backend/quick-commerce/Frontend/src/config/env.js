/**
 * Build-time environment — the single source of truth for keys and hosts.
 *
 * Read these through `ENV.*` rather than touching `import.meta.env` directly:
 * a key referenced in one place is a key you can rotate in one place.
 */

/** Strips whitespace and stray quotes that survive .env parsing. */
function sanitize(value) {
  if (!value) return "";
  return String(value).trim().replace(/^['"]|['"]$/g, "");
}

export const ENV = {
  NODE_ENV: import.meta.env.MODE,
  API_BASE_URL: "", // Backend disconnected - new backend in progress
  FIREBASE_API_KEY: import.meta.env.VITE_FIREBASE_API_KEY,

  /**
   * Google Maps JS API key. Set VITE_GOOGLE_MAPS_API_KEY in .env — the same key
   * the mobile apps read from config/keys.env.
   * Requires: Maps JavaScript API, Places API, Geocoding API, Directions API.
   */
  GOOGLE_MAPS_API_KEY: sanitize(import.meta.env.VITE_GOOGLE_MAPS_API_KEY),
};

/** True when maps can actually render; used to hide map UI rather than show a grey box. */
export const MAPS_ENABLED = Boolean(ENV.GOOGLE_MAPS_API_KEY);
