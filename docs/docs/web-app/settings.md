---
sidebar_position: 9
---

# Settings

Route: `/settings`

The Settings page lets users configure app-wide preferences. It is accessible from the sidebar navigation.

## Default Currency

The primary setting is the **Default currency** selector. Users pick their preferred currency (e.g. USD, INR, EUR, GBP) from a dropdown. The selection is persisted to the `profiles.default_currency` column in Supabase.

### How It Works

1. On page load, the current `default_currency` value is read from the user's profile.
2. The user selects a new currency from the dropdown.
3. On save, the app updates `profiles.default_currency` via the Supabase client.
4. The `CurrencyProvider` context is refreshed so all dashboard components immediately reflect the new currency.

## CurrencyProvider Pattern

The dashboard layout wraps all child routes in a `CurrencyProvider` (React context):

```mermaid
graph TB
  DashLayout["(dashboard) Layout"]
  CurrencyProvider["CurrencyProvider"]
  Dashboard["/dashboard"]
  Accounts["/accounts"]
  Personal["/personal"]
  Groups["/groups"]
  Analytics["/analytics"]
  Settings["/settings"]

  DashLayout --> CurrencyProvider
  CurrencyProvider --> Dashboard
  CurrencyProvider --> Accounts
  CurrencyProvider --> Personal
  CurrencyProvider --> Groups
  CurrencyProvider --> Analytics
  CurrencyProvider --> Settings
```

### Key Files

| File | Description |
|------|-------------|
| `lib/currencies.ts` | Currency definitions -- code, symbol, locale data |
| `components/currency/currency-provider.tsx` | React context provider that reads `default_currency` from the user profile and exposes it to descendants |
| `components/currency/formatted-cents.tsx` | Utility component that renders an integer-cents value as a formatted currency string using `Intl.NumberFormat` |

### Usage

Any component inside the dashboard layout can access the currency:

```typescript
const { currency } = useCurrency();
// currency = "INR" | "USD" | "EUR" | ...
```

Formatted display uses the `FormattedCents` component or calls `Intl.NumberFormat` directly:

```typescript
new Intl.NumberFormat("en-IN", {
  style: "currency",
  currency: "INR",
}).format(cents / 100);
// → "₹1,200.00"
```
