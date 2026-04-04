# The Ledger — Advanced Expense Platform

A comprehensive financial platform combining personal expense tracking with Splitwise-style group expense sharing. Built on a **serverless BaaS architecture** with zero hosting costs.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Database & Auth | Supabase (PostgreSQL, GoTrue, RLS) |
| Web Dashboard | Next.js 14, React, Tailwind CSS, Recharts |
| Mobile App | Flutter (Material 3), Riverpod, go_router |
| Edge Functions | Deno (TypeScript) — Debt Simplifier |

## Quick Start

```bash
# 1. Set up Supabase: apply migrations in SQL Editor
#    supabase/migrations/00001_initial_schema.sql
#    supabase/migrations/00002_fix_rls_and_accounts.sql
#    supabase/seed.sql

# 2. Web app
cd web
cp .env.local.example .env.local   # add your Supabase URL + anon key
npm install && npm run dev

# 3. Mobile app (optional)
cd mobile
flutter pub get
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## Documentation

See the **[full documentation](docs/)** for detailed setup guides, architecture, database schema, API reference, and design system documentation.

```bash
cd docs
npm install
npm start    # opens at http://localhost:3000
```

## Project Structure

```
lyari/
├── supabase/          # Database migrations, Edge Functions, seed data
├── web/               # Next.js 14 App Router dashboard
├── mobile/            # Flutter mobile companion app
├── docs/              # Docusaurus documentation site
└── stitch/            # Design system references
```

## Key Features

- **Personal Expense Tracking** — Filterable data table, category budgets
- **Accounts Ledger** — Bank accounts, credit/debit cards, wallets (GPay, PayPal, cash)
- **Income Tracking** — Record earnings, auto-update account balances
- **Group Expense Sharing** — Equal/exact/percentage splits
- **Invite by Email** — Add registered users to groups by email
- **Debt Simplification** — Min cash flow algorithm via Edge Function
- **Analytics** — Category pie charts, burn rate trends, comparison charts
- **Mobile-First Add** — Fast expense entry with numpad UI
- **Loading States** — Skeleton loading screens for every route

## Deployment

- **Web**: Push to GitHub, import in [Vercel](https://vercel.com). In **Project Settings > General**, set **Root Directory** to `web` (required for this monorepo). Vercel reads [`web/vercel.json`](web/vercel.json); do **not** add a root `vercel.json` that runs `cd web` — that breaks when Root Directory is already `web`.
- **Mobile**: Build APK with `flutter build apk --release --dart-define=...`
- **Edge Functions**: `supabase functions deploy debt-simplifier --project-ref YOUR_REF`

See [Vercel Deploy Guide](docs/docs/getting-started/vercel-deploy.md) and [Flutter Setup](docs/docs/getting-started/flutter-setup.md) for details.
