/** Fallback when profile has no currency (matches migration 00005). */
export const DEFAULT_CURRENCY = "JPY";

/** Common ISO 4217 codes for settings and account pickers */
export const CURRENCY_OPTIONS = [
  { code: "JPY", label: "Japanese Yen (JPY)" },
  { code: "USD", label: "US Dollar (USD)" },
  { code: "EUR", label: "Euro (EUR)" },
  { code: "GBP", label: "British Pound (GBP)" },
  { code: "INR", label: "Indian Rupee (INR)" },
  { code: "CAD", label: "Canadian Dollar (CAD)" },
  { code: "AUD", label: "Australian Dollar (AUD)" },
  { code: "CHF", label: "Swiss Franc (CHF)" },
  { code: "CNY", label: "Chinese Yuan (CNY)" },
  { code: "SGD", label: "Singapore Dollar (SGD)" },
  { code: "AED", label: "UAE Dirham (AED)" },
  { code: "NZD", label: "New Zealand Dollar (NZD)" },
  { code: "SEK", label: "Swedish Krona (SEK)" },
  { code: "NOK", label: "Norwegian Krone (NOK)" },
  { code: "MXN", label: "Mexican Peso (MXN)" },
  { code: "BRL", label: "Brazilian Real (BRL)" },
  { code: "ZAR", label: "South African Rand (ZAR)" },
] as const;

export function amountFieldLabel(currencyCode: string): string {
  return `Amount (${currencyCode})`;
}
