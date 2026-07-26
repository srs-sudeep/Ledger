# Lyari — All-in-one ledger

Self-hosted expense tracker + group splitting. **PostgreSQL**, **FastAPI**, **React (Bun)**, **Flutter**.

## Quick start

```bash
# Pick environment (copies template → .env)
./scripts/env-use.sh dev    # local development
./scripts/env-use.sh prod   # home server (edit secrets in .env first)

# Dev — hot reload API + Vite, Postgres on localhost:5432
docker compose -f docker-compose.dev.yml up --build

# Prod — nginx + optimized images
./scripts/deploy.sh
# or: docker compose -f docker-compose.prod.yml up -d --build
```

| Mode | Web | API | API docs |
|------|-----|-----|----------|
| Dev | http://localhost:5173 | http://localhost:8000 | http://localhost:8000/docs |
| Prod | http://SERVER (port 80) | http://SERVER/api | http://SERVER/api/health |

In production the API is **not** published on host `:8000` — nginx proxies `/api` only.

## Home server (LAN + Tailscale)

Current host: **hp**

| Access | URL |
|--------|-----|
| LAN | http://192.168.1.6 |
| Tailscale | http://100.118.104.48 |
| APK download | http://100.118.104.48/downloads/lyari.apk |
| Portainer | http://192.168.1.6:9000 (LAN/Tailscale only) |

**Phone / remote:** install [Tailscale](https://tailscale.com/download), join the same tailnet, then open the Tailscale URL or install the APK. The release APK is built with `API_BASE_URL=http://100.118.104.48` (nginx on port 80).

```bash
# On the server (~/Projects/lyari)
./scripts/deploy.sh          # api + web
./scripts/build-apk.sh       # Flutter APK → artifacts/apk/lyari.apk
```

Back up the Docker volume `pgdata` (or dump with your preferred Postgres backup). Do not expose Portainer or the stack on the public internet without auth/TLS.

## CI/CD

GitHub Actions runs on a **self-hosted runner** on `hp` (`runs-on: [self-hosted, linux, lyari]`).

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `Deploy` | push to `main`, manual | `git reset --hard origin/main` + `./scripts/deploy.sh` |
| `APK` | push to `main`, tags `v*`, manual | `./scripts/build-apk.sh`, upload artifact; on tags → GitHub Release |

Secrets stay in the server `.env` (never committed).

## Environment files

| File | Purpose |
|------|---------|
| `.env.dev` | Development defaults (committed) |
| `.env.prod` | Production template — **change passwords & JWT secret** |
| `.env` | Active config (gitignored) — copy from dev or prod |

```bash
cp .env.dev .env          # or: ./scripts/env-use.sh dev
cp .env.prod .env         # or: ./scripts/env-use.sh prod
```

All services (Postgres, API, web, mobile build) read from the single root `.env`.

## Docker Compose files

| File | Use case |
|------|----------|
| `docker-compose.dev.yml` | Hot reload, source mounts, Postgres exposed |
| `docker-compose.prod.yml` | Production images, nginx, persistent volume, APK downloads mount |

## Local development (without full Docker)

### API

```bash
docker compose -f docker-compose.dev.yml up db -d
cd backend && python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
export $(grep -v '^#' ../.env | xargs)
uvicorn app.main:app --reload --port 8000
```

### Web (Bun)

```bash
cd frontend
bun install
bun run dev    # http://localhost:5173
```

### Mobile

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://100.118.104.48
```

## Can Docker run Flutter?

**Build yes, run day-to-day no.**

| Task | Docker? | Notes |
|------|---------|-------|
| Build Android APK | Yes | `./scripts/build-apk.sh` |
| Run on phone/emulator | No (use host) | Install Flutter locally; point at API with `API_BASE_URL` |
| iOS build/simulator | No | Requires macOS + Xcode |

Flutter in Docker is for **CI/APK builds** only. For development, run `flutter run` on your machine.

## Project structure

```
lyari/
├── backend/                 # FastAPI
├── frontend/                # Vite + React (Bun) + nginx
├── mobile/                  # Flutter (APK via Docker)
├── artifacts/apk/           # Published APK for /downloads/
├── scripts/
│   ├── env-use.sh
│   ├── deploy.sh
│   └── build-apk.sh
├── .github/workflows/       # Deploy + APK (self-hosted)
├── docker-compose.dev.yml
└── docker-compose.prod.yml
```

## Environment variables

| Variable | Used by | Description |
|----------|---------|-------------|
| `POSTGRES_*` | db | Database credentials |
| `DATABASE_URL` | api | SQLAlchemy connection string |
| `JWT_SECRET` | api | Auth token signing (change in prod) |
| `CORS_ORIGINS` | api | Comma-separated allowed web origins |
| `VITE_API_URL` | web build | Empty when nginx/docker proxy handles `/api` |
| `API_BASE_URL` | mobile | Base URL baked into APK (`--dart-define`), e.g. Tailscale IP |
| `GOOGLE_CLIENT_ID` | api, web, mobile | Optional Google OAuth client ID |
| `PORTAINER_PORT` | portainer | Container UI (default 9000) |
| `WEB_PORT` | compose | Host port for nginx (default 80) |

See `.env.dev` and `.env.prod` for full list.

## Portainer (container logs)

Open **http://192.168.1.6:9000** → create admin on first visit → **Containers** → pick a Lyari container → **Logs**.

## Auth

- **Show password** — eye icon on all password fields
- **Confirm password** — required when registering
- **Email verification** — not sent on self-hosted; account is active immediately (email format only)
- **Google sign-in** — set `GOOGLE_CLIENT_ID` in `.env` ([Google Cloud Console](https://console.cloud.google.com/apis/credentials))

## Production notes

- Edit `.env` after `env-use prod`: strong `POSTGRES_PASSWORD`, `JWT_SECRET`, `CORS_ORIGINS`, `API_BASE_URL`.
- Back up the `pgdata` Docker volume.
- Web on port **80** proxies `/api` to FastAPI internally; APKs at `/downloads/`.
