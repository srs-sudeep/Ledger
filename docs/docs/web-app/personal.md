---
sidebar_position: 5
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
- **Amount** in dollars (converted to cents on submit)
- **Category** dropdown (from seeded categories)
- **Pay from** account (optional, updates account balance)
- **Date** (defaults to today)
- **Notes** (optional)

Personal expenses have `group_id = NULL` in the database.

## Expense Table

- Search by title or category name
- Sort by date (default), amount, or title
- Ascending/descending toggle
- Amounts shown as negative values (money spent)
