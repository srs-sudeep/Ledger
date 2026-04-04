---
sidebar_position: 1
---

# Supabase Tables API

All data access goes through the Supabase client SDKs. There is no custom backend server.

## Common Patterns

### Fetching with Relations

```typescript
// Expense with category and payer profile
const { data } = await supabase
  .from("expenses")
  .select("*, categories(*), profiles!expenses_payer_id_fkey(*)")
  .eq("payer_id", userId)
  .is("group_id", null)
  .order("date", { ascending: false });
```

### Inserting with Cents Conversion

```typescript
const cents = Math.round(parseFloat(amountStr) * 100);
await supabase.from("expenses").insert({
  title,
  amount: cents,
  payer_id: userId,
  group_id: null,
  category_id: categoryId || null,
  account_id: accountId || null,
});
```

### Group Members with Profiles

```typescript
const { data: members } = await supabase
  .from("group_members")
  .select("*, profiles(*)")
  .eq("group_id", groupId);
```

### Account Balance Update

```typescript
// After an expense
await supabase
  .from("accounts")
  .update({ balance: account.balance - cents })
  .eq("id", accountId);

// After income
await supabase
  .from("accounts")
  .update({ balance: account.balance + cents })
  .eq("id", accountId);
```

## Client Setup

### Next.js Server Component

```typescript
import { createClient } from "@/lib/supabase/server";
const supabase = createClient();
```

### Next.js Client Component

```typescript
import { createClient } from "@/lib/supabase/client";
const supabase = createClient();
```

### Flutter

```dart
final supabase = Supabase.instance.client;
```
