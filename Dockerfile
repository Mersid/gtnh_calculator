# Step 1: Build container — compile TypeScript and stage static assets
FROM node:24-alpine AS builder
WORKDIR /app

# Install dependencies first so this layer caches independently of source changes
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

# Bring in the rest of the source and build (tsc + copyfiles -> dist/)
COPY . .
RUN npm run build

# Step 2: Lightweight static-serving runtime
FROM nginx:1.29-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -qO /dev/null http://127.0.0.1/ || exit 1
