# ─────────────────────────────────────────────────────────────
# STAGE 1: Build (Node 20 + Angular CLI)
# ─────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar package.json primero para cachear node_modules
COPY package*.json ./
RUN npm ci --silent

# Copiar código fuente y buildear en producción
COPY . .
RUN npm run build -- --configuration production

# ─────────────────────────────────────────────────────────────
# STAGE 2: Servir con Nginx
# ─────────────────────────────────────────────────────────────
FROM nginx:1.27-alpine

# Copiar el build de Angular al directorio de Nginx
COPY --from=builder /app/dist/front/browser /usr/share/nginx/html

# Copiar configuración de Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget --spider -q http://localhost:80 || exit 1
