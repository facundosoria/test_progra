---
id: PASO_S00_03
equipo: C
bloque: 0
dep: [PASO_S00_02]
siguiente: PASO_S00_04
context_files:
  - docker-compose.yml
  - .env.example
outputs: []
---

# PASO 0.2 — Levantar servicios Docker
**Grupo legacy:** 0 — Infraestructura | **Equipo:** C | **Dificultad:** 🟢 | **Tiempo:** 15 min

## Navegación
← **Anterior:** [PASO_S00_02](PASO_S00_02.md) — Herramientas instaladas (Java, Maven, Node, Docker)
→ **Siguiente:** [PASO_S00_04](PASO_S00_04.md) — Crear proyecto Spring Boot (Equipo A arranca aquí)

## Archivos a cargar junto a este
- `docker-compose.yml`
- `.env.example`

## Qué construye este paso
Configura y levanta todos los servicios en Docker: PostgreSQL, Redis, MinIO, API Spring Boot, Frontend Nginx (gateway), y exporters de monitoreo. Modo oficial: **Full Docker** con gateway unificado en `localhost:8088`.

## Comandos

```bash
# Crear directorio del proyecto
mkdir -p ~/codemon && cd ~/codemon

# Copiar los archivos de configuración
cp /ruta/docs/07-infraestructura/docker-compose.yml ~/codemon/
cp /ruta/docs/07-infraestructura/.env.example ~/codemon/.env
cp /ruta/docs/07-infraestructura/nginx.conf ~/codemon/nginx.conf

# Crear estructura de monitoreo
mkdir -p infra/monitoring/grafana/provisioning/{datasources,dashboards}
cp /ruta/docs/07-infraestructura/prometheus.yml infra/monitoring/
cp /ruta/docs/07-infraestructura/grafana-datasource.yml infra/monitoring/grafana/provisioning/datasources/datasource.yml

# Levantar toda la infraestructura (comando único)
docker --context colima compose up -d --build
```

## Puertos y acceso

| Servicio | Acceso externo | Acceso interno Docker |
|---|---|---|
| Frontend + Gateway | `http://localhost:8088` | — |
| API REST | `localhost:8088/api/*` | `http://api:8080/api/*` |
| WebSocket | `localhost:8088/ws/*` | `http://api:8080/ws/*` |
| Swagger UI | `localhost:8088/swagger-ui.html` | — |
| Actuator | `localhost:8088/actuator/health` | — |
| Imágenes MinIO | `localhost:8088/minio/*` | `http://minio:9000/*` |
| PostgreSQL (tooling) | `localhost:5433` | `postgres:5432` |
| Grafana | `localhost:3000` | — |
| MinIO consola admin | `localhost:9001` | — |

## Errores comunes

| Error | Causa | Solución |
|---|---|---|
| Puerto 8088 ocupado | Otro proceso en ese puerto | `lsof -i :8088` → matar proceso |
| `minio_setup` en `exited (1)` | Bucket no creado | `docker --context colima compose restart minio_setup` |
| `Cannot connect to Docker daemon` | Colima no iniciado | `colima start` |
| `502 Bad Gateway` en `/api/` | API aún inicializando | Esperar 60s y reintentar |

## Generar secretos del .env

Antes de levantar los servicios, completar los secretos vacíos en `~/codemon/.env`:

```bash
# JWT_SECRET — mínimo 32 caracteres
echo "JWT_SECRET=$(openssl rand -hex 32)" >> ~/codemon/.env

# MP_ACCESS_TOKEN — obtener en https://www.mercadopago.com.ar/developers/panel/credentials
# Usar el token TEST-... para sandbox durante desarrollo
echo "MP_ACCESS_TOKEN=TEST-xxxx" >> ~/codemon/.env

# EMAIL_PASSWORD — contraseña de aplicación de Gmail (no la contraseña principal)
# Activar "Contraseñas de aplicación" en la cuenta Google y pegar el token de 16 chars
echo "EMAIL_FROM=tu@gmail.com" >> ~/codemon/.env
echo "EMAIL_PASSWORD=abcd efgh ijkl mnop" >> ~/codemon/.env
```

Los servicios Docker (PostgreSQL, Redis, MinIO) no necesitan estos secretos para arrancar; solo los necesita la API Spring Boot (PASO_S00_04 en adelante).

## Verificación

```bash
# Gateway responde
curl -fs http://localhost:8088/ -o /dev/null && echo "Gateway OK"
# PASS: "Gateway OK"
# FAIL: Connection refused → docker --context colima compose logs front

# API sana vía gateway
curl -s http://localhost:8088/actuator/health | grep -q '"status":"UP"' && echo "API OK"
# PASS: "API OK"
# FAIL: 502 o DOWN → docker --context colima compose logs api (esperar 60s si arrancó recién)

# PostgreSQL listo
docker exec codemon_postgres pg_isready -U codemon_user
# PASS: "localhost:5432 - accepting connections"
# FAIL: "could not connect" → docker --context colima compose up postgres -d

# Redis listo y con persistencia
docker exec codemon_redis redis-cli ping
# PASS: "PONG"
docker exec codemon_redis redis-cli CONFIG GET appendonly
# PASS: 1) "appendonly" 2) "yes"

# MinIO accesible vía gateway
curl -fs http://localhost:8088/minio/minio/health/live -o /dev/null && echo "MinIO via gateway OK"
# PASS: "MinIO via gateway OK"
# FAIL: 502 → docker --context colima compose restart minio
```

## Dependencias
PASO_S00_02 completado (Docker Desktop instalado).
