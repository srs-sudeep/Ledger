---
sidebar_position: 3
---

# Web App Setup (Next.js)

## Environment Variables

Create `web/.env.local` (never commit real keys):

```bash
cd web
cp .env.local.example .env.local
```

| Variable | Required | Description |
|----------|----------|-------------|
| `NEXT_PUBLIC_SUPABASE_URL` | Yes | Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Yes | Supabase anon public key |

Example:

```env
NEXT_PUBLIC_SUPABASE_URL=https://xxxxxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
```

:::warning
Do **not** put the `service_role` key in `NEXT_PUBLIC_*` variables. It would be exposed to the browser.
:::

## Run Locally

```bash
cd web
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Build for Production

```bash
cd web
npm run build
npm start
```

## Routes

| Route | Description |
|-------|-------------|
| `/` | Public landing page with hero, features, and CTAs |
| `/login` | Email/password + Google OAuth login |
| `/register` | New user registration |
| `/dashboard` | Unified overview with summary cards, charts, accounts |
| `/accounts` | Bank accounts, credit cards, wallets management |
| `/personal` | Personal expenses table with budget progress |
| `/groups` | Group listing |
| `/groups/[id]` | Group detail with expenses, members, settle-up |
| `/analytics` | Charts -- category breakdown, burn rate, comparison |
| `/settings` | User settings -- default currency selector |
