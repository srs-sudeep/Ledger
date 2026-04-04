---
sidebar_position: 2
---

# Edge Functions API

## debt-simplifier

Calculates the minimum number of transactions to settle all group debts.

### Endpoint

```
POST https://<project-ref>.supabase.co/functions/v1/debt-simplifier
```

### Headers

| Header | Value |
|--------|-------|
| `Authorization` | `Bearer <user_jwt>` |
| `Content-Type` | `application/json` |

### Request Body

```json
{
  "group_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Success Response (200)

```json
{
  "transactions": [
    {
      "from": "user-uuid-1",
      "to": "user-uuid-2",
      "amount": 2500
    }
  ],
  "balances": {
    "user-uuid-1": -2500,
    "user-uuid-2": 2500
  }
}
```

- `transactions`: minimal set of payments needed to settle all debts
- `balances`: net balance per user (positive = owed money, negative = owes money)
- All amounts in **cents**

### Error Response (400)

```json
{
  "error": "group_id is required"
}
```

### Calling from Next.js

```typescript
const { data: { session } } = await supabase.auth.getSession();

const response = await fetch(
  `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/debt-simplifier`,
  {
    method: "POST",
    headers: {
      Authorization: `Bearer ${session?.access_token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ group_id: groupId }),
  }
);

const result = await response.json();
```

### Calling from Flutter

```dart
final response = await supabase.functions.invoke(
  'debt-simplifier',
  body: {'group_id': groupId},
);
```
