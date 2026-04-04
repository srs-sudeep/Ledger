# The Ledger — Advanced Expense Platform

A comprehensive financial platform combining personal expense tracking with Splitwise-style group expense sharing. Built on a **serverless BaaS architecture** with zero hosting costs.

## Architecture

```
lyari/
├── supabase/          # Database migrations, Edge Functions, seed data
├── web/               # Next.js 14 App Router dashboard
├── mobile/            # Flutter mobile companion app
└── stitch/            # Design system references
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Database & Auth | Supabase (PostgreSQL, GoTrue, RLS) |
| Web Dashboard | Next.js 14, React, Tailwind CSS, Recharts |
| Mobile App | Flutter (Material 3), Riverpod, go_router |
| Edge Functions | Deno (TypeScript) — Debt Simplifier |

## Getting Started

### Prerequisites

- Node.js 18+
- Flutter 3.x
- Supabase CLI (optional, for local dev)
- A Supabase project at [supabase.com](https://supabase.com)

### 1. Supabase Setup

1. Create a new project at [supabase.com/dashboard](https://supabase.com/dashboard)
2. Run the migration in the SQL Editor: `supabase/migrations/00001_initial_schema.sql`
3. Run the seed data: `supabase/seed.sql`
4. Deploy the Edge Function:
   ```bash
   supabase functions deploy debt-simplifier
   ```
5. Enable Google OAuth in Authentication > Providers

### 2. Web App

```bash
cd web
cp .env.local.example .env.local
# Edit .env.local with your Supabase URL and anon key
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

### 3. Mobile App

```bash
cd mobile
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Design System

The UI follows "The Precision Curator" design language:

- **Typography**: Manrope (headlines) + Inter (body/labels)
- **Colors**: M3-based surface hierarchy with tonal layering
- **No-Line Rule**: Boundaries defined by background color shifts, not borders
- **Shadows**: Ambient `0 12px 40px -12px rgba(19,27,46,0.08)`

Reference designs live in `stitch/`.

## Database Schema

| Table | Purpose |
|-------|---------|
| `profiles` | User profiles (extends auth.users) |
| `categories` | Expense categories (seeded) |
| `groups` | Expense sharing groups |
| `group_members` | Group membership with roles |
| `expenses` | Personal + group expenses (amount in cents) |
| `expense_splits` | How group expenses are split |
| `settlements` | Debt settlement records |

All tables are protected by Row Level Security (RLS).

## Key Features

- **Personal Expense Tracking** — Filterable data table, category budgets
- **Group Expense Sharing** — Equal/exact/percentage splits
- **Debt Simplification** — Min cash flow algorithm via Edge Function
- **Analytics** — Category pie charts, burn rate trends, comparison charts
- **Mobile-First Add** — 5-second expense entry with numpad UI
