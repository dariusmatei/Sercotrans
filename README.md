# Sercotrans — Monorepo (API + Frontend + Infra)

Monorepo pentru o aplicație de management proiecte, cu backend (Node/TypeScript), frontend (Flutter Web) și infrastructură Docker + Nginx pentru rulare locală în development. Stack-ul pornește containere pentru API, Postgres și reverse proxy; UI-ul Flutter rulează local în dev.

## Structură
- `backend/` – API Node/TypeScript (hot-reload în dev).
- `frontend/` – Dockerfile multi‑stage pentru build Flutter Web (prod). **În dev,** Flutter rulează local.
- `infra/` – `docker-compose.dev.yml`, Nginx (`nginx/default.conf`) pentru orchestrare și reverse proxy.
- `lib/`, `web/`, `pubspec.yaml` – codul Flutter (scaffold UI, navigație, theming).

## Precondiții
- **Dev stack (API/DB/Proxy):** Docker + Docker Compose v2
- **Frontend (dev):** Flutter SDK (channel stable) + Chrome

Creează un fișier `.env` la rădăcina repo-ului (vezi și `.env.example`) cu valori precum:
```bash
PORT=8080
NODE_ENV=development
JWT_SECRET=change-me
DATABASE_URL=postgresql://app_user:app_pass@postgres:5432/app_db?schema=public
```

## Rulare (development)
1. Pornește infrastructura (API + DB + Nginx):
   ```bash
   docker compose -f infra/docker-compose.dev.yml up --build
   ```
2. Verifică health-ul API prin Nginx:
   ```
   http://localhost:8081/health
   ```
3. (Frontend) Rulează Flutter local din rădăcina repo-ului:
   ```bash
   flutter pub get
   flutter run -d chrome
   ```
   *Notă:* containerul din `frontend/Dockerfile` este pentru build de producție; în development UI-ul rulează local.

## Oprire
```bash
docker compose -f infra/docker-compose.dev.yml down
```

## Status
Mediu de dezvoltare funcțional (API + DB + Nginx + scaffold UI). Integrarea completă a fluxurilor business (autentificare, CRUD proiecte etc.) se face incremental peste acest setup.
