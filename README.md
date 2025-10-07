# S1-D1 – Dockerfiles & docker-compose.dev + Nginx

Acest pachet conține fișierele pentru task-ul **S1-D1**:
- `infra/docker-compose.dev.yml`
- `infra/nginx/default.conf`
- `backend/Dockerfile`
- `frontend/Dockerfile`
- prezentul `README.md` (pașii de rulare)

## Ce face
- Pornește containere pentru **API (backend)**, **DB (Postgres)** și **Nginx** (reverse proxy local).
- **Hot-reload** pentru backend în development (prin `nodemon` + bind mount).

## Precondiții
- Structura repo ca în planul monorepo: există directorul `backend/` cu proiect Node/TypeScript (package.json, tsconfig.json, src/server.ts).
- Un fișier `.env` la rădăcina repo-ului (poți copia din `.env.example`):
  ```ini
  PORT=8080
  NODE_ENV=development
  JWT_SECRET=change-me
  DATABASE_URL=postgresql://app_user:app_pass@postgres:5432/app_db?schema=public
  ```

## Rulare (development)
1. Din rădăcina repo-ului, rulează:
   ```bash
   docker compose -f infra/docker-compose.dev.yml up --build
   ```
2. Accesează API-ul prin Nginx: `http://localhost:8081/health` (rutele tale backend).
3. **Hot-reload**: orice modificare în `backend/src` repornește serverul (via `nodemon`).

> Notă: `frontend/Dockerfile` este multi-stage pentru build Flutter web (prod), dar nu este folosit în `docker-compose.dev.yml` (în dev rulezi Flutter local).

## Oprire
```bash
docker compose -f infra/docker-compose.dev.yml down
```

## DoD
- `docker compose up` pornește Postgres, backend-ul (cu hot-reload) și Nginx.
- Nginx face reverse proxy către backend (port 8080) pe `http://localhost:8081`.
