# Lyari — Mobile

Flutter companion app for **Lyari**: personal expenses, accounts, group splits, and debt simplification against the same Supabase backend as the web app.

## Stack

| Piece | Package |
|-------|---------|
| UI | Flutter 3.x, Material 3 |
| State | Riverpod |
| Routing | go_router |
| Backend | supabase_flutter |
| Fonts | google_fonts (Manrope + Inter) |

## Prerequisites

- Flutter SDK (stable), Dart 3.x
- A Supabase project with migrations applied (see repo `supabase/migrations/` and `docs/docs/getting-started/supabase-setup.md`)
- Same `SUPABASE_URL` and anon key as the web app

## Configure Supabase

The app reads credentials at **compile time** via `--dart-define` (not `.env` at runtime).

1. Copy the example file:

   ```bash
   cp dart_define.example.json dart_define.json
   ```

2. Edit `dart_define.json` with your project URL and anon key (same values as `web/.env.local`).

3. Run or build with:

   ```bash
   flutter run --dart-define-from-file=dart_define.json
   ```

   Or pass defines inline:

   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
   ```

Keep `dart_define.json` out of version control if it contains real keys (it should be gitignored).

## Run & build

```bash
cd mobile
flutter pub get
flutter run --dart-define-from-file=dart_define.json
```

Release APK:

```bash
flutter build apk --release --dart-define-from-file=dart_define.json
```

## Features

- **Auth** — Email/password and Google OAuth (configure redirect URLs in Supabase for your platform).
- **Dashboard** — Group balances (owed / owed to you), recent personal transactions.
- **Accounts** — List balances, add accounts (type, currency, starting balance), recent income; balances update when you add income or pay from an account.
- **Groups** — List and open groups; equal-split group expenses; **Settle** uses the `debt-simplifier` Edge Function.
- **Add expense** — Full-screen flow with numpad; personal vs group; category; optional **Pay from** account for personal expenses (matches web behavior).
- **Profile** — Display name, **default currency** (saved to `profiles.default_currency`), **About** opens help/contact.
- **Help** — Developer contact details (same idea as the web sidebar Help dialog).

## Project layout

```
lib/
  main.dart              # Supabase init, MaterialApp.router
  router.dart            # go_router + auth redirect
  models/models.dart     # Profile, Category, Group, Expense, Account, Income, …
  providers/             # Riverpod providers
  services/supabase_service.dart
  screens/               # Auth, shell, dashboard, accounts, groups, profile, add expense, help
  theme/app_theme.dart
```

## Documentation

Full product and schema docs live in the repo **`docs/`** Docusaurus site (see **Mobile App** and **Concepts → Money flow** sections).

## License

Private / same as the parent Lyari repository.
