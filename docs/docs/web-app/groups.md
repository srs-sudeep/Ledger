---
sidebar_position: 7
---

# Groups

Routes: `/groups` and `/groups/[id]`

## Group Listing

The `/groups` page shows all groups the user belongs to, with:
- Group name and type badge (trip / home / custom)
- Member count
- Create Group button

## Group Detail

The `/groups/[id]` page has two columns:

### Left Column

- **Group Expenses**: feed of all expenses in the group with payer, amount, category, splits
- **Add Group Expense**: form with split type selection (equal, exact, percentage)

### Right Column

- **Members**: list with role badges (admin/member), invite button, remove button (admin only)
- **Settle Up**: calls the `debt-simplifier` Edge Function and displays simplified transactions with the group's currency

## Currency

Each group has a `currency` field (defaults to `'USD'`). Group expenses and settlements inherit the group's currency. The currency is displayed in the settle-up results and throughout the group detail page using `Intl.NumberFormat`.

## Inviting Members

Admins can invite registered users by email:

1. Click "Invite" on the members card
2. Enter the email of a registered user
3. The system looks up the email in `profiles`
4. If found, inserts a `group_members` row with role `member`
5. Error states: user not found, already a member, permission denied

The invited user must have already registered. There is no email invitation system -- the lookup checks existing profiles only.

## Split Types

| Type | Behavior |
|------|----------|
| **Equal** | Total divided evenly among all members (remainder goes to first member) |
| **Exact** | Each member's share entered manually in the group's currency |
| **Percentage** | Each member's percentage entered; applied to total |
