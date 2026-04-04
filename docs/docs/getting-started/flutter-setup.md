---
sidebar_position: 4
---

# Flutter Setup

## Environment Variables

The app reads Supabase settings from compile-time `--dart-define` values.

| Define | Required | Description |
|--------|----------|-------------|
| `SUPABASE_URL` | Yes | Same as `NEXT_PUBLIC_SUPABASE_URL` |
| `SUPABASE_ANON_KEY` | Yes | Same as `NEXT_PUBLIC_SUPABASE_ANON_KEY` |

## Run (debug)

```bash
cd mobile
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## Run on a Specific Device

```bash
flutter devices
flutter run -d chrome   # or -d <device_id>
```

## Build APK (release)

```bash
cd mobile
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## App Bundle (Google Play)

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## iOS

```bash
flutter build ios --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Open `ios/Runner.xcworkspace` in Xcode for signing and App Store upload.

## Using `dart-define-from-file`

For shorter commands:

1. Copy `mobile/dart_define.example.json` to `mobile/dart_define.json` (gitignored).
2. Fill in real values.
3. Run:

```bash
flutter run --dart-define-from-file=dart_define.json
flutter build apk --release --dart-define-from-file=dart_define.json
```
