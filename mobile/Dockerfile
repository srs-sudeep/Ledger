# Build Android APK only. Flutter apps are normally run on a device/emulator on the host.
# Output: mobile/build/app/outputs/flutter-apk/app-release.apk
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
RUN flutter config --no-analytics
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
# Re-resolve after full copy (host .dart_tool is dockerignored)
RUN flutter pub get
ARG API_BASE_URL=http://localhost:8000
RUN flutter build apk --release --dart-define=API_BASE_URL=${API_BASE_URL}
