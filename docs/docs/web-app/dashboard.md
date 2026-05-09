---
sidebar_position: 4
---

# Dashboard

Route: `/dashboard`

The dashboard provides a unified overview of the user's financial state.

## Header

The dashboard header displays the **Lyari** title on the left and a **"Sign out"** button on the right. The sign-out action is also available in the sidebar navigation.

## Sidebar

The sidebar provides navigation to all dashboard routes. It also includes:

- **Help** button -- opens a modal dialog showing developer contact information (Sudeep Ranjan Sahoo, email, phone numbers, and website [iamsrs.com](https://iamsrs.com))
- **Sign out** button

## Components

| Component | Description |
|-----------|-------------|
| `SummaryCards` | Net worth, total owed to me, total I owe, monthly spend |
| `SpendingChart` | 7-day spending bar chart |
| `RecentTransactions` | Last 5 transactions (personal + group) |
| `AccountsOverview` | Top 4 accounts with balances |
| `ActiveGroups` | User's active groups |
| `PendingSettlements` | Unsettled debts |
| `InsightCard` | Contextual financial tip |

All monetary values throughout the dashboard are formatted using `Intl.NumberFormat` with the user's `default_currency` from their profile (provided by `CurrencyProvider`).

## Data Flow

The page is a **Server Component** that fetches all data in a single `Promise.all`:

- Personal expenses for the current month
- Recent expenses (limit 5)
- Group memberships (limit 5)
- Expense splits owed to the user
- Expense splits the user owes
- Pending settlements
- User accounts (limit 4)

All data is fetched server-side and passed as props to client components for rendering.
