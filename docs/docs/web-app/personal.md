---
sidebar_position: 6
---

# Personal Expenses

Route: `/personal`

Track individual spending with a filterable data table and budget progress bars.

## Components

| Component | Description |
|-----------|-------------|
| `AddExpenseButton` | Dialog to add a personal expense (with optional account selection) |
| `BudgetProgress` | Monthly spending by category, shown as progress bars |
| `PersonalExpenseTable` | Sortable, searchable table of all personal expenses |

## Add Expense Form

Fields:
- **Description** (required)
- **Amount** -- label dynamically shows the user's currency, e.g. "Amount (INR)" or "Amount (USD)" (converted to cents on submit)
- **Category** dropdown (from seeded categories)
- **Pay from** account (optional, updates account balance)
- **Date** (defaults to today)
- **Notes** (optional)

The currency stored on each personal expense comes from the user's `default_currency` profile setting. Personal expenses have `group_id = NULL` in the database.

## Expense Table

- Search by title or category name
- Sort by date (default), amount, or title
- Ascending/descending toggle
- Amounts formatted with the user's default currency via `Intl.NumberFormat`
