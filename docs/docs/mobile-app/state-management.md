---
sidebar_position: 3
---

# State Management

The mobile app uses **Riverpod** for reactive state management.

## Providers

### Auth Provider

Watches the Supabase auth state and exposes the current user. Used by the router for authentication guards.

```dart
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});
```

### Data Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `personalExpensesProvider` | FutureProvider | Fetches personal expenses |
| `groupsProvider` | FutureProvider | Fetches user's groups |
| `groupDetailProvider(id)` | FutureProvider.family | Fetches a specific group's data |
| `profileProvider` | FutureProvider | Fetches current user profile |

### Supabase Service

A singleton service class (`SupabaseService`) wraps all Supabase client calls:

- `getPersonalExpenses()`
- `addExpense()`
- `getGroups()`
- `getGroupDetail(groupId)`
- `addGroupExpense()`
- `settleDebt()`
- `updateProfile()`

All methods return typed Dart objects defined in `models/models.dart`.
