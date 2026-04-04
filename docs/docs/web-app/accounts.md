---
sidebar_position: 4
---

# Accounts

Route: `/accounts`

The Accounts page lets users manage their financial accounts and track income.

## Account Types

| Type | Icon | Description |
|------|------|-------------|
| `bank` | Landmark | Bank accounts (checking, savings) |
| `credit_card` | CreditCard | Credit cards |
| `debit_card` | CreditCard | Debit cards |
| `wallet` | Wallet | Digital wallets (PayPal, GPay, Apple Pay) |
| `cash` | Banknote | Physical cash |
| `other` | CircleDollarSign | Anything else |

## Features

### Account Management

- Add accounts with name, type, starting balance, and color
- Set a default account
- Delete accounts
- View total balance across all accounts

### Income Tracking

- Record income with source, amount, and date
- Optionally deposit into a specific account (auto-updates balance)
- View recent income history

### Expense Integration

When adding a personal or group expense, users can optionally select a "Pay from" account. The account balance is automatically decremented by the expense amount.

## Balance Updates

Account balances are updated in real-time on the client:

- **Income deposit**: `balance += amount`
- **Expense payment**: `balance -= amount`

These are manual updates (not automatic bank syncing).
