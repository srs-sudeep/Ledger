---
sidebar_position: 2
---

# Row Level Security (RLS)

All tables have RLS enabled. The database is entirely protected -- users can only read/write their own data or data for groups they belong to.

## Helper Functions

To avoid infinite recursion in policies that reference `group_members` from within `group_members` itself, we use `SECURITY DEFINER` helper functions:

```sql
-- Checks if a user is a member of a group (bypasses RLS)
public.is_group_member(p_group_id UUID, p_user_id UUID) → BOOLEAN

-- Checks if a user is an admin of a group
public.is_group_admin(p_group_id UUID, p_user_id UUID) → BOOLEAN

-- Checks if a user is a member of the group that an expense belongs to
public.is_expense_group_member(p_expense_id UUID, p_user_id UUID) → BOOLEAN

-- Checks if a group has zero members (for first-member bootstrap)
public.group_has_no_members(p_group_id UUID) → BOOLEAN
```

These are defined in `supabase/migrations/00002_fix_rls_and_accounts.sql`.

## Policy Summary

### profiles

| Operation | Rule |
|-----------|------|
| SELECT | All authenticated users can read all profiles |
| UPDATE | Only own profile |
| INSERT | Only own profile |

### accounts / income

| Operation | Rule |
|-----------|------|
| ALL | `user_id = auth.uid()` |

### groups

| Operation | Rule |
|-----------|------|
| SELECT | Must be a group member |
| INSERT | `created_by = auth.uid()` |
| UPDATE / DELETE | Must be a group admin |

### group_members

| Operation | Rule |
|-----------|------|
| SELECT | Must be a member of the same group |
| INSERT | Must be a group admin, OR bootstrapping first member |
| DELETE | Must be a group admin |

### expenses

| Operation | Rule |
|-----------|------|
| SELECT | Personal: `payer_id = auth.uid()`. Group: must be group member |
| INSERT | Same as SELECT |
| UPDATE | Must be payer + (personal OR group member) |
| DELETE | Must be payer |

### expense_splits

| Operation | Rule |
|-----------|------|
| SELECT / INSERT | Must be member of the expense's group |
| UPDATE / DELETE | Must be the expense payer |

### settlements

| Operation | Rule |
|-----------|------|
| SELECT / UPDATE | Must be `from_user_id` or `to_user_id` |
| INSERT | `from_user_id = auth.uid()` + group member |
