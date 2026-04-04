---
sidebar_position: 3
---

# Edge Functions

## Debt Simplifier

**Function name:** `debt-simplifier`
**Location:** `supabase/functions/debt-simplifier/index.ts`

### Purpose

When a user views a group, the client calls this Edge Function to calculate the minimum number of transactions required to settle all debts within the group.

### Algorithm

1. Fetch all `expense_splits` for the group's expenses.
2. Calculate each user's **net balance** (what they paid minus what they owe).
3. Run a **greedy min cash flow algorithm**:
   - Separate users into creditors (positive balance) and debtors (negative balance).
   - Match the largest creditor with the largest debtor.
   - Settle the minimum of the two amounts.
   - Repeat until all balances are zero.

### Request

```http
POST /functions/v1/debt-simplifier
Authorization: Bearer <user_jwt>
Content-Type: application/json

{
  "group_id": "uuid-of-the-group"
}
```

### Response

```json
{
  "transactions": [
    { "from": "user-id-a", "to": "user-id-b", "amount": 1500 }
  ],
  "balances": {
    "user-id-a": -1500,
    "user-id-b": 1500
  }
}
```

Amounts are in **cents**.

### Deployment

```bash
supabase functions deploy debt-simplifier --project-ref YOUR_PROJECT_REF
```

The function auto-receives `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` from the runtime.
