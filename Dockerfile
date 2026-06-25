# ---------- Stage 1: build the Flutter web app ----------
# Pin a known-good Flutter release. Bump as needed.
FROM ghcr.io/cirruslabs/flutter:3.24.5 AS flutter-build

WORKDIR /build
# Copy the Flutter project and resolve dependencies
COPY app/ ./app/
WORKDIR /build/app
RUN flutter pub get
# Build optimized web output -> /build/app/build/web
RUN flutter build web --release

# ---------- Stage 2: Node server (API + static host) ----------
FROM node:20-slim AS runtime

ENV NODE_ENV=production
WORKDIR /app

# Install server deps first (better layer caching)
COPY server/package*.json ./
RUN npm install --omit=dev

# Server source
COPY server/ ./

# Built Flutter web -> served from ./public by Express
COPY --from=flutter-build /build/app/build/web ./public

# Render provides PORT; default to 3000 locally
EXPOSE 3000
CMD ["node", "index.js"]
