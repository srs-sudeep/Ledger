---
sidebar_position: 2
---

# Supabase Setup

## Apply Database Schema

### Option A: SQL Editor (simplest)

1. Open **SQL Editor** in the Supabase dashboard.
2. Paste the contents of `supabase/migrations/00001_initial_schema.sql` and run.
3. Paste the contents of `supabase/migrations/00002_fix_rls_and_accounts.sql` and run.
4. Paste `supabase/seed.sql` and run (inserts default categories only).

### Option B: Supabase CLI

```bash
cd supabase
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

## Seed Data

`supabase/seed.sql` only inserts **categories** (Groceries, Dining, Transport, etc.). It does **not** create users, profiles, groups, or expenses.

- **Users** are created through the app's Register page or **Authentication > Users** in the dashboard.
- The `handle_new_user` trigger automatically creates a `profiles` row when a user signs up.

## Authentication URLs

In Supabase: **Authentication > URL Configuration**:

| Setting | Local Development | Production (Vercel) |
|---------|-------------------|---------------------|
| **Site URL** | `http://localhost:3000` | `https://your-app.vercel.app` |
| **Redirect URLs** | `http://localhost:3000/**` | `https://your-app.vercel.app/**` |

## Email / Password

Enabled by default under **Authentication > Providers > Email**.

## Google OAuth (optional)

1. Enable under **Authentication > Providers > Google**.
2. Add **Client ID** and **Client Secret** from [Google Cloud Console](https://console.cloud.google.com/apis/credentials).
3. Set the authorized redirect URI in Google Cloud to your Supabase callback URL (shown in the provider settings).

## Deploy Edge Function

```bash
supabase functions deploy debt-simplifier --project-ref YOUR_PROJECT_REF
```

The function receives `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` automatically from the Supabase runtime.
