---
id: PASO_S00_07
equipo: ALL
bloque: 0
dep: [PASO_S00_02, PASO_S00_03, PASO_S00_04, PASO_S00_05, PASO_S00_06]
siguiente: PASO_S00_SMOKE
context_files: []
outputs: []
---

# PASO 0.6 — Smoke test (Full Docker)
**Grupo legacy:** 0 — Infraestructura | **Sprint:** S0 | **Equipo:** ALL | **Dificultad:** 🟢 | **Tiempo:** 15 min

## Navegación
← **Anterior:** [PASO_S00_06](PASO_S00_06.md) — Proyecto Angular creado (ultimo paso de S0)
→ **Siguiente (paralelo — GATE 0 liberado):** [PASO_S02_01](PASO_S02_01.md) (A) · [PASO_S02_03](PASO_S02_03.md) (B) · [PASO_S08_01](PASO_S08_01.md) (C)

## Archivos a cargar junto a este
- [GATEWAY_LOCAL.md](../../07-infraestructura/GATEWAY_LOCAL.md) — comando único de arranque y tabla de rutas

## Qué construye este paso
Verifica que toda la infraestructura levanta correctamente en modo **Full Docker**: gateway Nginx en `localhost:8088`, API conectada a PostgreSQL y Redis, imágenes MinIO accesibles vía `/minio/`, Swagger accesible. No requiere `ng serve` ni `mvn spring-boot:run`.

## Comando de arranque (único)

```bash
cd ~/codemon
docker --context colima compose up -d --build
```

Esperar ~60 segundos a que la API pase el healthcheck antes de los tests.

## Verificación

```bash
# 1. Todos los servicios healthy
docker --context colima compose ps
# PASS: postgres, redis, minio, api, front en estado "running" / "healthy"
# FAIL: algún servicio en "exited" → docker compose logs <servicio>

# 2. Gateway responde
curl -I http://localhost:8088/
# PASS: HTTP/1.1 200 OK
# FAIL: Connection refused → verificar que codemon_front está healthy

# 3. API sana vía gateway (PostgreSQL + Redis conectados)
curl -s http://localhost:8088/actuator/health
# PASS: {"status":"UP"}
# PASS extendido (si management.endpoint.health.show-details=always): incluye "db" y "redis"
# FAIL: status "DOWN" → revisar docker compose logs api

# 4. Swagger disponible vía gateway
curl -I http://localhost:8088/swagger-ui.html
# PASS: HTTP 302 o 200
# FAIL: 404 → verificar location /swagger-ui en nginx.conf

# 5. MinIO accesible vía gateway
curl -I http://localhost:8088/minio/minio/health/live
# PASS: HTTP 200
# FAIL: 502 → verificar location /minio/ en nginx.conf
```

## Errores comunes

| Error | Causa | Solución |
|---|---|---|
| `Connection refused :8088` | `codemon_front` no levantó | `docker compose logs front` |
| `502 Bad Gateway` en `/api/` | API no healthy aún | Esperar 60s y reintentar |
| `502 Bad Gateway` en `/minio/` | MinIO no healthy | `docker compose restart minio` |
| `Cannot acquire lock` en Flyway | BD con estado previo | `docker compose down -v && docker compose up -d --build` |
| `Port 8088 in use` | Proceso previo o conflicto | `lsof -i :8088` → matar proceso |

## Lo que indica que el Sprint 0 está completo

- [ ] `docker compose ps` → todos los servicios healthy
- [ ] `curl http://localhost:8088/actuator/health` → `{"status":"UP"}`
- [ ] `curl http://localhost:8088/swagger-ui.html` → sin error
- [ ] `ng build --configuration production` → sin errores de TypeScript
- [ ] `environment.ts` usa rutas relativas `/api` y `/ws`

## Dependencias
PASO_S00_02 a PASO_S00_06 completados.
