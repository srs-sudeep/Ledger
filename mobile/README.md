# Ledger Mobile

Flutter companion app for the self-hosted Ledger API.

## Run (recommended — on your machine)

```bash
cp ../.env.dev ../.env   # or ../.env.prod
flutter pub get
flutter run --dart-define=API_BASE_URL=http://YOUR_LAN_IP
```

Use a **LAN IP** or Tailscale IP, not `localhost`, on a physical device.

## Android APK

```bash
./scripts/build-apk.sh   # from repo root on the home server / CI
```

Download (after publish):

- Tailscale: http://100.118.104.48/downloads/ledger.apk
- LAN: http://192.168.1.6/downloads/ledger.apk

## iOS

There is **no published iPhone install link**. iOS builds require macOS + Xcode (`flutter build ipa`) and distribution via TestFlight or sideloading — not set up in this home-server CI. The iOS project under `mobile/ios/` is for local development only.
