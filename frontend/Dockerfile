# Multi-stage build pentru Flutter web (production)
# În dev, rulează Flutter local. Acest Dockerfile este util pentru build & servire statică.
# Necesită Docker cu spatiu suficient (~se descarcă toolchain Flutter).

# ---------- Builder ----------
FROM ghcr.io/cirruslabs/flutter:3.24.0 AS build
WORKDIR /app
# Copiază descriptorii înainte pentru cache
COPY pubspec.yaml ./
RUN flutter pub get
COPY . .
RUN flutter build web --release

# ---------- Nginx (serve SPA) ----------
FROM nginx:alpine AS web
COPY --from=build /app/build/web /usr/share/nginx/html
# Config SPA fallback (opțional poți suprascrie cu un default.conf dedicat)
EXPOSE 80
CMD ["nginx","-g","daemon off;"]
