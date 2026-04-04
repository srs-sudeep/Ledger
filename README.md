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

---

## Demo

There is **no hosted public demo instance** in this repo. Run the stack locally (or on your own Supabase + Vercel) and use the flows below.

### Demo account

| Item | Details |
|------|---------|
| **Login** | There is no fixed demo user. After setup, open **`/register`**, sign up with any real email (or use Supabase **Authentication → Users → Add user** for testing). |
| **Password** | Choose your own; minimum length follows Supabase project settings (default 6). |
| **Email confirmation** | If **Confirm email** is enabled in Supabase, complete the link in the message (or disable confirmations under **Authentication → Providers → Email** for local dev). |

### Placeholder environment values (documentation only)

Use your real **Project URL** and **anon** key from **Supabase → Project Settings → API**. These are **fake examples** for shape only:

| Variable | Example (not real) |
|----------|---------------------|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://abcdefghijklmnop.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (long JWT-style string) |
| Flutter `SUPABASE_URL` | Same as `NEXT_PUBLIC_SUPABASE_URL` |
| Flutter `SUPABASE_ANON_KEY` | Same as `NEXT_PUBLIC_SUPABASE_ANON_KEY` |
| **Project ref** (CLI / dashboard URL) | 20-character id shown in the Supabase dashboard URL and **Project Settings → General** |

Never commit real keys; keep them in `web/.env.local` and local Flutter `dart_define.json` (gitignored).

### Demo data (seed)

[`supabase/seed.sql`](supabase/seed.sql) only inserts **categories** (lookup rows in `public.categories`). It does **not** add users, profiles, groups, or expenses.

- **Users** live in `auth.users` and are created through **Register** in the app, **Authentication → Users** in the Supabase dashboard, or the Auth API — not in this seed file.
- After a user signs up, the migration’s `handle_new_user` trigger creates their **`profiles`** row automatically.

### Suggested demo flow (local)

1. **Web:** `cd web && npm run dev` → [http://localhost:3000](http://localhost:3000) → **Register** → **Dashboard**.
2. **Personal:** **Transactions** (sidebar) or **Personal** route → **Add Expense** → pick category, amount, save.
3. **Groups:** **Groups** → **Create Group** → open the group → **Add Group Expense** with splits → **Settle Up** (requires deployed **`debt-simplifier`** Edge Function).
4. **Analytics:** **Analytics** after you have dated personal expenses.
5. **Mobile:** Run Flutter with the same Supabase URL/anon key; sign in with the same user.

---

## Setup guide

### Prerequisites

- **Node.js** 18+
- **npm** or **pnpm**
- **Flutter** 3.x (stable) with Android Studio / Xcode as needed
- A **Supabase** project ([supabase.com/dashboard](https://supabase.com/dashboard))
- **Supabase CLI** (optional but recommended): [Supabase CLI install](https://supabase.com/docs/guides/cli)

---

### 1. Supabase

#### Create project

1. Go to [Supabase Dashboard](https://supabase.com/dashboard) → **New project**.
2. Note **Project URL** and **anon public** key: **Project Settings → API**.

#### Apply database schema and seed

**Option A — SQL Editor (simplest)**

1. Open **SQL Editor** → **New query**.
2. Paste the full contents of [`supabase/migrations/00001_initial_schema.sql`](supabase/migrations/00001_initial_schema.sql) → **Run**.
3. Paste [`supabase/seed.sql`](supabase/seed.sql) → **Run**.

**Option B — Supabase CLI**

```bash
cd supabase
supabase link --project-ref YOUR_PROJECT_REF
supabase db push   # if you use linked migrations; otherwise use SQL Editor for the single migration file
```

If you only have one SQL file, pasting it in the SQL Editor is usually fastest.

#### Authentication URLs (required for web + OAuth)

In Supabase: **Authentication → URL Configuration**

| Setting | Local development | Production (Vercel) |
|--------|-------------------|---------------------|
| **Site URL** | `http://localhost:3000` | `https://your-app.vercel.app` (your real domain when ready) |
| **Redirect URLs** | Add `http://localhost:3000/**` and `http://localhost:3000/auth/callback` | Add `https://your-app.vercel.app/**` and `https://your-app.vercel.app/auth/callback` |

#### Email / password

Enabled by default under **Authentication → Providers → Email**.

#### Google OAuth (optional)

1. **Authentication → Providers → Google** — enable and add **Client ID** and **Client Secret** from [Google Cloud Console](https://console.cloud.google.com/apis/credentials) (OAuth 2.0 Web client).
2. Authorized redirect URI in Google Cloud must include Supabase’s callback, e.g.  
   `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback`  
   (exact value is shown in the Supabase Google provider settings).

#### Deploy Edge Function (`debt-simplifier`)

From the repo root (with [CLI logged in](https://supabase.com/docs/guides/cli/getting-started)):

```bash
supabase functions deploy debt-simplifier --project-ref YOUR_PROJECT_REF
```

Hosted functions receive `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` automatically; no extra secrets are required for this function unless you customize it.

---

### 2. Web (Next.js) — environment variables

Create **`web/.env.local`** (never commit real keys). Copy from the example:

```bash
cd web
cp .env.local.example .env.local
```

| Variable | Required | Description |
|----------|----------|-------------|
| `NEXT_PUBLIC_SUPABASE_URL` | Yes | Supabase project URL (`https://xxxxx.supabase.co`) |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Yes | Supabase **anon** **public** key (safe to expose in the browser) |

Example **`web/.env.local`**:

```env
NEXT_PUBLIC_SUPABASE_URL=https://xxxxxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Do not** put the **service_role** key in `NEXT_PUBLIC_*` or in any file shipped to the client.

#### Run locally

```bash
cd web
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

#### Build locally

```bash
cd web
npm run build
npm start
```

#### Deploy to Vercel

1. Push the repo to GitHub/GitLab/Bitbucket.
2. In [Vercel](https://vercel.com) → **Add New → Project** → import the repo.
3. **Root Directory**: set to **`web`** (monorepo).
4. **Framework Preset**: Next.js (auto-detected).
5. **Environment Variables** (Production / Preview / Development as needed):

   | Name | Value |
   |------|--------|
   | `NEXT_PUBLIC_SUPABASE_URL` | Same as local |
   | `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Same anon key |

6. Deploy. Update Supabase **Site URL** and **Redirect URLs** to your Vercel URL (see table above).

Optional: assign a custom domain in Vercel and add that domain to Supabase redirect URLs.

---

### 3. Flutter — environment variables

The app reads Supabase settings from **compile-time** `--dart-define` values (see [`mobile/lib/main.dart`](mobile/lib/main.dart)). There is no `.env` file committed; pass secrets at build/run time.

| Define | Required | Description |
|--------|----------|-------------|
| `SUPABASE_URL` | Yes | Same as `NEXT_PUBLIC_SUPABASE_URL` |
| `SUPABASE_ANON_KEY` | Yes | Same as `NEXT_PUBLIC_SUPABASE_ANON_KEY` |

#### Run (debug)

```bash
cd mobile
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

#### Run on a specific device

```bash
flutter devices
flutter run -d chrome   # or -d <device_id>
```

#### Build APK (release)

```bash
cd mobile
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

#### App bundle (Google Play)

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Configure signing in `android/app/build.gradle` and `android/key.properties` per [Flutter Android deployment](https://docs.flutter.dev/deployment/android).

#### iOS (release)

```bash
flutter build ios --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Open `ios/Runner.xcworkspace` in Xcode for signing, capabilities, and App Store upload.

#### Optional: `dart-define-from-file` (shorter commands)

1. Copy [`mobile/dart_define.example.json`](mobile/dart_define.example.json) to **`mobile/dart_define.json`** (gitignored — do not commit).
2. Replace the placeholder URL and anon key.
3. Run or build:

```bash
cd mobile
flutter run --dart-define-from-file=dart_define.json
flutter build apk --release --dart-define-from-file=dart_define.json
```

Requires a recent Flutter SDK that supports `--dart-define-from-file`. If your SDK is older, use the explicit `--dart-define=...` pairs above.

#### Optional: shell script

Use a small script or `Makefile` that passes `--dart-define` from your environment. **Do not** commit real keys.

#### Mobile auth redirects (Google / deep links)

For **Google OAuth on mobile**, configure the redirect URL Supabase expects for your platform (e.g. custom URL scheme or universal links). Update **Authentication → URL Configuration** in Supabase and your OAuth provider to match. The exact scheme depends on how you implement OAuth in `supabase_flutter` (see [Supabase Flutter Auth](https://supabase.com/docs/reference/dart/introduction)).

---

## Design System

The UI follows "The Precision Curator" design language:

- **Typography**: Manrope (headlines) + Inter (body/labels)
- **Colors**: M3-based surface hierarchy with tonal layering
- **No-Line Rule**: Boundaries defined by background color shifts, not borders
- **Shadows**: Ambient `0 12px 40px -12px rgba(19,27,46,0.08)`

Reference designs live in `stitch/`.

---

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

---

## Key Features

- **Personal Expense Tracking** — Filterable data table, category budgets
- **Group Expense Sharing** — Equal/exact/percentage splits
- **Debt Simplification** — Min cash flow algorithm via Edge Function
- **Analytics** — Category pie charts, burn rate trends, comparison charts
- **Mobile-First Add** — Fast expense entry with numpad UI
