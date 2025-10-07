# ---------- Base ----------
FROM node:20-alpine AS base
WORKDIR /app

# ---------- Deps (prod deps) ----------
FROM base AS deps
COPY package*.json ./
RUN npm ci

# ---------- Dev (hot-reload) ----------
FROM deps AS dev
# dev-only tooling
RUN npm install --save-dev ts-node nodemon
COPY tsconfig.json ./
COPY src ./src
EXPOSE 8080
# Rulează scriptul dev definit în package.json (ex: nodemon --exec node --loader ts-node/esm src/server.ts)
CMD [ "npm", "run", "dev" ]

# ---------- Build (TS -> JS) ----------
FROM deps AS build
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# ---------- Prod (runtime mic) ----------
FROM base AS prod
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package*.json ./
EXPOSE 8080
CMD [ "node", "dist/server.js" ]
