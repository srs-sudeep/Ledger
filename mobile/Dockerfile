# Build Android APK only. Flutter apps are normally run on a device/emulator on the host.
# Output (via compose volume): mobile/build/app/outputs/flutter-apk/app-release.apk
FROM ghcr.io/cirruslabs/flutter:stable
WORKDIR /app
RUN flutter config --no-analytics
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
# Re-resolve after full copy (host .dart_tool is dockerignored)
RUN flutter pub get
ARG API_BASE_URL=http://localhost:8000
ENV API_BASE_URL=${API_BASE_URL}
# Build at container runtime so the compose outputs volume receives the APK
CMD ["sh", "-c", "flutter build apk --release --dart-define=API_BASE_URL=${API_BASE_URL}"]
