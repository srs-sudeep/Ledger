/**
 * Brand & SEO — single source of truth for titles, taglines, and canonical URLs.
 * Set NEXT_PUBLIC_SITE_URL in production (e.g. https://your-app.vercel.app).
 */

export const SITE_NAME = "Lyari";

/** Short line under the name (meta, OG, manifest). */
export const SITE_TAGLINE =
  "All-in-one ledger—personal & group finances, clear balances, zero spreadsheet chaos.";

/** Sidebar / compact UI line. */
export const SITE_UI_TAGLINE = "All-in-one ledger";

/** Primary meta description (~155 chars for Google). */
export const SITE_DESCRIPTION =
  "Track personal spending, split bills with groups, and settle who owes whom. Budgets, analytics, multi-currency (JPY-first), and debt simplification—built on Supabase, yours to host.";

export const SITE_KEYWORDS = [
  "expense tracker",
  "split bills",
  "group expenses",
  "personal finance",
  "budget",
  "shared ledger",
  "settle up",
  "Splitwise alternative",
  "Supabase",
  "multi-currency",
  "JPY",
] as const;

export const SITE_AUTHOR = {
  name: "Sudeep Ranjan Sahoo",
  url: "https://iamsrs.com",
} as const;

/** Optional X/Twitter @handle — leave null if none. */
export const SITE_TWITTER_HANDLE: string | null = null;

/**
 * Canonical site origin for metadataBase, OG URLs, and sitemap.
 * Falls back to localhost in dev; set NEXT_PUBLIC_SITE_URL in Vercel env.
 */
export function getSiteUrl(): string {
  if (process.env.NEXT_PUBLIC_SITE_URL) {
    return process.env.NEXT_PUBLIC_SITE_URL.replace(/\/$/, "");
  }
  if (process.env.VERCEL_URL) {
    return `https://${process.env.VERCEL_URL.replace(/\/$/, "")}`;
  }
  return "http://localhost:3000";
}
