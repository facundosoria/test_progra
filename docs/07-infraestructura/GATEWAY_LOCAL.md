# Gateway Local — Codemon TCG

## Comando único de arranque

```bash
docker --context colima compose up -d --build
```

Esperar ~60 segundos a que la API pase el healthcheck (`condition: service_healthy`).

**URL única de acceso:** `http://localhost:8088`

Este gateway local **no usa TLS**. Produccion se documenta por separado y debe usar `https://<dominio>` + `wss://<dominio>/ws`: [GATEWAY_PRODUCCION_HTTPS.md](GATEWAY_PRODUCCION_HTTPS.md).

---

## Tabla de rutas del gateway

| Ruta pública | Destino interno Docker | Qué sirve |
|---|---|---|
| `http://localhost:8088/` | `/usr/share/nginx/html` | Angular SPA |
| `http://localhost:8088/api/*` | `http://api:8080/api/*` | REST API backend |
| `http://localhost:8088/ws/*` | `http://api:8080/ws/*` | WebSocket STOMP (partidas) |
| `http://localhost:8088/actuator/*` | `http://api:8080/actuator/*` | Health, métricas Spring |
| `http://localhost:8088/swagger-ui.html` | `http://api:8080/swagger-ui.html` | Swagger UI |
| `http://localhost:8088/v3/api-docs` | `http://api:8080/v3/api-docs` | OpenAPI JSON |
| `http://localhost:8088/minio/*` | `http://minio:9000/*` | Imágenes de cartas |

### Accesos de admin (no pasan por el gateway)

| URL | Qué es |
|---|---|
| `http://localhost:3000` | Grafana (admin/codemon123) |
| `http://localhost:9001` | MinIO Console admin |
| `localhost:5433` | PostgreSQL para tooling local (DBeaver, psql) |

---

## Variables de entorno clave

| Variable | Valor por defecto | Descripción |
|---|---|---|
| `MINIO_PUBLIC_URL` | `http://localhost:8088/minio` | Prefijo de URLs de imágenes en BD |
| `CORS_ALLOWED_ORIGINS` | `http://localhost:8088` | Origin permitido por Spring Security |
| `JWT_SECRET` | `dev_secret_cambiar_en_prod_min32chars` | **Cambiar en producción** |
| `MP_ACCESS_TOKEN` | _(vacío)_ | Token sandbox Mercado Pago |

Para sobreescribir sin tocar el compose, crear `~/codemon/.env`:
```bash
JWT_SECRET=<openssl rand -hex 32>
MP_ACCESS_TOKEN=TEST-xxxxxxxxxxxx
CORS_ALLOWED_ORIGINS=http://localhost:8088,http://localhost:4200
```

> ⚠️ **Precedencia de `.env`:** el archivo `.env` tiene prioridad sobre los valores
> por defecto definidos en `docker-compose.yml` (la sintaxis `${VAR:-default}`).
> Si `.env` existe pero `CORS_ALLOWED_ORIGINS` solo contiene `http://localhost:8088`,
> el origin `localhost:4200` (modo debug sin Docker) quedará bloqueado por CORS.
> Incluir siempre ambos orígenes como se muestra arriba.

---

## Verificación rápida post-arranque

```bash
# Gateway
curl -I http://localhost:8088/

# API health
curl -s http://localhost:8088/actuator/health

# Swagger
curl -I http://localhost:8088/swagger-ui.html

# MinIO vía gateway
curl -I http://localhost:8088/minio/minio/health/live

# Auth de prueba
curl -X POST http://localhost:8088/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.com","password":"Test123!","confirmPassword":"Test123!"}'
```

---

## Troubleshooting

### Puerto 8088 ocupado
```bash
lsof -i :8088
# Matar el proceso que lo usa, luego:
docker --context colima compose up -d --build
```

### Servicios unhealthy
```bash
docker --context colima compose ps          # ver estado
docker --context colima compose logs api    # logs de Spring Boot
docker --context colima compose logs front  # logs de Nginx
```

### API devuelve 502 Bad Gateway
La API puede tardar hasta 60s en inicializar (Flyway migrations + healthcheck). Esperar y reintentar.
```bash
watch -n5 'curl -s http://localhost:8088/actuator/health'
```

### Imágenes de cartas con URL vieja (localhost:9000)
Si las cartas ya están en BD con `imageSmallUrl: http://localhost:9000/...`, el `CardSeedRunner` debe actualizarlas al arrancar. Verificar:
```bash
curl -s http://localhost:8088/api/cards/xy1-1 | python3 -c \
  "import sys,json;c=json.load(sys.stdin);print(c.get('imageSmallUrl',''))"
# CORRECTO: http://localhost:8088/minio/codemon-cards/...
# INCORRECTO: http://localhost:9000/... → borrar volumen y reiniciar
```

Para resetear las imágenes sin borrar datos de usuario:
```bash
docker --context colima compose exec postgres psql -U codemon_user -d codemon_db \
  -c "UPDATE cards SET image_small_url = REPLACE(image_small_url, 'http://localhost:9000', 'http://localhost:8088/minio'),
      image_large_url  = REPLACE(image_large_url,  'http://localhost:9000', 'http://localhost:8088/minio');"
```

### Colima no iniciado
```bash
colima start
docker --context colima compose up -d --build
```

---

## Modo debug (sin Docker)

Solo cuando se necesita hot-reload en la API o el frontend:

```bash
# Terminal 1: infraestructura base
docker --context colima compose up postgres redis minio minio_setup -d

# Terminal 2: API con hot-reload (usa environment.development.ts)
cd ~/codemon/api && CORS_ALLOWED_ORIGINS=http://localhost:4200 ./mvnw spring-boot:run

# Terminal 3: Angular con hot-reload
# Usa environment.development.ts: apiUrl='http://localhost:8080/api'
cd ~/codemon/front && ng serve --configuration=development
# Acceso: http://localhost:4200
```

> En modo debug el frontend usa `localhost:4200` y apunta directo a `localhost:8080`.
> No es el flujo principal — usar solo para iterar cambios rápidos durante desarrollo.
