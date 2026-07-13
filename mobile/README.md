# Lyari Mobile

Flutter companion app for the self-hosted Lyari API.

## Run (recommended — on your machine)

```bash
cp ../.env.dev ../.env   # or ../.env.prod
flutter pub get
flutter run --dart-define=API_BASE_URL=http://YOUR_LAN_IP:8000
```

Use a **LAN IP**, not `localhost`, on a physical device.

## Build APK with Docker

Docker can **build** the Android APK but cannot replace a device/emulator for daily development.

```bash
cp ../.env.prod ../.env   # set API_BASE_URL to your server
docker compose -f ../docker-compose.prod.yml --profile mobile-build run --rm mobile-build
```

Output: `mobile/build/app/outputs/flutter-apk/app-release.apk`

## Flutter packages

| Package | Version | Role |
|---------|---------|------|
| `flutter` | SDK | UI framework (Material 3) |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |
| `http` | ^1.2.2 | REST calls to FastAPI |
| `shared_preferences` | ^2.3.5 | Persist JWT locally |
| `flutter_riverpod` | ^3.3.1 | State management |
| `go_router` | ^17.2.0 | Navigation / auth redirects |
| `google_fonts` | ^8.0.2 | Typography (Manrope, Inter) |
| `intl` | ^0.20.2 | Date/number formatting |

Dev: `flutter_test`, `flutter_lints`.

## App structure

```
lib/
├── main.dart                 # App entry, ApiService.init()
├── router.dart               # go_router routes + auth guard
├── currency_format.dart      # JPY-aware money formatting
├── models/models.dart        # Data types (see below)
├── services/
│   └── api_service.dart      # JWT auth + all API endpoints
├── providers/
│   ├── auth_notifier.dart    # Login state for router
│   └── data_providers.dart   # Riverpod FutureProviders
├── screens/
│   ├── auth_screen.dart      # Login / register
│   ├── shell_screen.dart     # Bottom nav shell
│   ├── dashboard_screen.dart # Summary cards, recent expenses
│   ├── accounts_screen.dart  # Accounts + add account
│   ├── groups_screen.dart    # Group list + create
│   ├── group_detail_screen.dart  # Members, expenses, settle up
│   ├── add_expense_screen.dart   # Personal or group expense
│   ├── profile_screen.dart   # Settings, currency, sign out
│   └── help_screen.dart      # About
└── theme/app_theme.dart      # Colors, typography
```

## Models (`models/models.dart`)

| Model | Purpose |
|-------|---------|
| `Profile` | User name, email, avatar, default currency |
| `Category` | Expense category (icon, color) |
| `Group` | Shared expense group |
| `GroupMember` | Member + role (admin/member) |
| `Expense` | Personal or group expense |
| `SimplifiedTransaction` | Debt simplifier result |
| `Account` | Bank/card/wallet ledger account |
| `Income` | Income entry |

## API service methods

`ApiService` wraps the FastAPI backend:

- **Auth:** `signIn`, `signUp`, `signOut`, `getProfile`, `updateProfile`
- **Data:** `getCategories`, `getPersonalExpenses`, `addPersonalExpense`
- **Groups:** `createGroup`, `getGroup`, `getUserGroups`, `getGroupMembers`, `getGroupExpenses`, `inviteMemberByEmail`, `addGroupExpense`
- **Debts:** `getSimplifiedDebts`, `settleUp`
- **Dashboard:** `getTotalOwedToMe`, `getTotalIOwe`
- **Accounts:** `getAccounts`, `addAccount`, `deleteAccount`, `getRecentIncome`, `addIncome`

## Why not run Flutter in Docker?

- **Android emulator** inside Docker is slow and rarely worth it.
- **iOS** requires macOS + Xcode — not available in Linux containers.
- **Hot reload** works best on the host with `flutter run`.

Use Docker only for reproducible **release APK builds** on a server or in CI.
