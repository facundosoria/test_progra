---
id: PASO_S00_SMOKE
equipo: TODOS
bloque: 0
dep: [PASO_S00_01, PASO_S00_02, PASO_S00_03, PASO_S00_04, PASO_S00_05, PASO_S00_06, PASO_S00_07]
siguiente: PASO_S01_01
context_files:
  - GLOSARIO.md
  - CONVENCIONES.md
outputs: []
---

# PASO S0.SMOKE — Validación integral del Sprint 0 (GATE 0)
**Grupo legacy:** 0 | **Sprint:** S0 | **Equipo:** TODOS | **Dificultad:** 🟢 | **Tiempo:** 15 min

## Navegación
← **Anterior:** [PASO_S00_07](PASO_S00_07.md) — Smoke test de infraestructura
→ **Siguiente:** [PASO_S02_01](PASO_S02_01.md) — DeckValidationService

---

## Qué valida este paso

Que **toda la infraestructura del Sprint 0 funciona en conjunto** antes de arrancar el desarrollo paralelo de S1 y siguientes. Es un checkpoint obligatorio antes del GATE 0.

---

## Verificación automatizada

```bash
# 1. Servicios Docker corriendo
docker --context colima compose ps --format json | grep -q '"State":"running".*postgres'   # PASS si: postgres corriendo
docker --context colima compose ps --format json | grep -q '"State":"running".*redis'      # PASS si: redis corriendo
docker --context colima compose ps --format json | grep -q '"State":"running".*minio'      # PASS si: minio corriendo
docker --context colima compose ps --format json | grep -q '"State":"running".*front'      # PASS si: front corriendo

# 2. PostgreSQL alcanzable
docker exec codemon_postgres pg_isready -U codemon_user                  # PASS si: accepting connections

# 3. Redis alcanzable
docker exec codemon_redis redis-cli ping | grep -q PONG                   # PASS si: PONG

# 4. Gateway Nginx responde en localhost:8088
curl -fs http://localhost:8088/ -o /dev/null                               # PASS si: HTTP 200

# 5. API Spring Boot sana vía gateway
curl -fs http://localhost:8088/actuator/health | grep -q '"status":"UP"'   # PASS si: UP

# 6. MinIO accesible vía gateway
curl -fs http://localhost:8088/minio/minio/health/live -o /dev/null        # PASS si: HTTP 200

# 7. Migraciones Flyway aplicadas (V1..V15) — al menos 22 tablas en BD
docker exec codemon_postgres psql -U codemon_user -d codemon_db -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE'" | awk '$1>=22 {exit 0} {exit 1}'  # PASS si: ≥22 tablas

# 8. Tabla flyway_schema_history existe y refleja las migraciones aplicadas
docker exec codemon_postgres psql -U codemon_user -d codemon_db -tAc "SELECT count(*) FROM flyway_schema_history WHERE success = true" | awk '$1>=15 {exit 0} {exit 1}'  # PASS si: ≥15 migraciones

# 9. Frontend Angular compila (PASO_S00_06)
cd ~/codemon/front && ng build --configuration production 2>&1 | grep -q "Application bundle generation complete"  # PASS si: compilación exitosa

# 10. Swagger accesible vía gateway
curl -fs http://localhost:8088/swagger-ui.html -o /dev/null                # PASS si: HTTP 200 o 302

# 11. Documentos canónicos del PASO_S00_01 existen
test -f docs/05-referencia-tecnica/CONTRATOS_API.md                  # PASS si: existe
test -f docs/05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md            # PASS si: existe
test -f docs/05-referencia-tecnica/MOCKS_FRONTEND.md                    # PASS si: existe
test -f docs/05-referencia-tecnica/GLOSARIO.md                          # PASS si: existe
```

---

## Definition of Done — GATE 0

- [ ] Los 11 checks de "Verificación automatizada" pasan
- [ ] `http://localhost:8088` es la única URL de acceso a la app (no se usa :8080, :4200 ni :9000 directamente)
- [ ] Los 3 equipos pueden hacer un cambio trivial (commit + push) sin conflictos
- [ ] El smoke test de PASO_S00_07 está documentado como pasado en el CHECKLIST
- [ ] Los DTOs y endpoints de `CONTRATOS_API.md` están consensuados entre los 3 equipos
- [ ] El protocolo WebSocket (`PROTOCOLO_WEBSOCKET.md`) está consensuado y alineado con [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md) sección 4

---

## Si falla un check

| Check | Acción |
|---|---|
| Servicios Docker | `docker compose up -d` y revisar logs `docker compose logs <servicio>` |
| Migraciones < 15 | revisar `docker compose logs api` para errores Flyway |
| Frontend tsc | `cd ~/codemon/front && npm install && npx tsc --noEmit` |
| Documentos canónicos faltantes | volver a PASO_S00_01 y completarlos |
