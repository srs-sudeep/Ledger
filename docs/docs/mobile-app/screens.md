---
sidebar_position: 2
---

# Screens

## AuthScreen

- Email/password login and registration
- Toggle between sign-in and sign-up modes
- Uses `supabase_flutter` for authentication

## DashboardScreen (Tab 1)

- Large "You Owe" and "You Are Owed" numbers
- Toggle between Personal and Group summaries
- Recent 5 transactions list

## GroupsScreen (Tab 2)

- ListView of all user's groups
- Tap to navigate to group detail
- Group detail shows expense feed and "Settle" button

## GroupDetailScreen

- Group expenses with payer, amount, category
- Members list
- Settle Up button (calls debt-simplifier Edge Function)

## AddExpenseScreen (FAB)

- Full-screen modal triggered by central FAB
- Top toggle: Personal vs Group
- Category dropdown
- Large number input area
- Save button

## ProfileScreen (Tab 3)

- User avatar and name
- Default currency preference
- Sign out button
