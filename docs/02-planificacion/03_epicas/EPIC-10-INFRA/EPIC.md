# EPIC-10 — Infraestructura y DevOps

> **Epica tecnica.** No contiene Historias de Usuario porque su valor no es directo para un jugador final. Habilita a las epicas funcionales (EPIC-01..09).

## 1. Resumen

- **Valor habilitador:** sin esta epica nada arranca. Provee infraestructura local y de produccion (Docker, BD, Redis, MinIO, monitoring), contratos de API/WS y migraciones.
- **Roles involucrados:** Sistema, todos los equipos.
- **Sprints donde se completa:** S0 (kickoff completo), S8 (Grafana + metricas custom), continua transversalmente.
- **Equipos:** C (DevOps lider), A (proyecto Spring Boot + Flyway), B (proyecto Angular).

## 2. Tareas Tecnicas

| ID | Tarea | Origen | Equipo | SP | Sprint |
|---|---|---|---|---|---|
| TT-10-01 | Definir CONTRATOS_API.md con todos los dominios | PASO_S00_01 | ALL | 5 | S0 |
| TT-10-02 | Definir PROTOCOLO_WEBSOCKET.md con eventos STOMP | PASO_S00_01 | ALL | 3 | S0 |
| TT-10-03 | Definir MOCKS_FRONTEND.md con JSONs por endpoint | PASO_S00_01 | B | 3 | S0 |
| TT-10-04 | Instalar herramientas (Java 21, Maven, Node 20, Angular 21, Tailwind CSS 3, Docker) | PASO_S00_02 | C | 1 | S0 |
| TT-10-05 | docker-compose.yml con 10 servicios: Postgres, Redis, MinIO, MinIO setup, Prometheus, Grafana, postgres_exporter, redis_exporter, api, front | PASO_S00_03 | C | 2 | S0 |
| TT-10-06 | Proyecto Spring Boot 3.x + application.yml con env vars | PASO_S00_04 | A | 3 | S0 |
| TT-10-07 | Migraciones Flyway V1-V16 (25 tablas, 2 vistas materializadas, funcion `purge_expired_data()`) + seed cards.json | PASO_S00_05 | A | 5 | S0 |
| TT-10-08 | Proyecto Angular 21 con Tailwind CSS 3 + feature folders + mock interceptor | PASO_S00_06 | B | 2 | S0 |
| TT-10-09 | Smoke test infra: health, swagger, frontend up | PASO_S00_07 | C | 1 | S0 |
| TT-10-10 | Nginx reverse proxy + Dockerfile.front | PASO_S00_03, PASO_S00_06 | C | 2 | S0 |
| TT-10-11 | Configurar Prometheus + datasource Grafana | PASO_S08_05 | C | 3 | S8 |
| TT-10-12 | Metricas custom `codemon_*` (counters, gauges, timers) | PASO_S08_05 | C | 5 | S8 |
| TT-10-13 | Dashboard Grafana base con 4 paneles (sistema, BD, Redis, business) | PASO_S08_05 | C | 3 | S8 |
| TT-10-14 | `.env.example` con todas las variables de entorno listadas | PASO_S00_03 | C | 1 | S0 |
| TT-10-15 | Configurar CORS, JWT secret, MP sandbox via env vars | PASO_S00_04 | A | 2 | S0 |
| TT-10-16 | Redis con persistencia: `appendonly yes`, `appendfsync everysec` y RDB (`save 900 1`, `save 300 10`) en `command:` de docker-compose.yml; verificar con `redis-cli CONFIG GET appendonly` | PASO_S00_03 | C | 1 | S0 |
| TT-10-17 | `RedisKeyBuilder` bean con prefijo de entorno (`@Value("${app.env:dev}")`); convencion de claves `<env>:<dominio>:<id>` aplicada en TODO acceso a Redis (PATRONES_REDIS.md sec 7.2) | PASO_S00_04 | A | 2 | S0 |
| TT-10-18 | `RedisLockRegistry` bean (`spring-integration-redis`) para locks distribuidos: matchmaking tick, refresh leaderboard, purge tick (PATRONES_REDIS.md sec 7.4) | PASO_S00_04 | A | 2 | S0 |
| TT-10-19 | `MaintenanceJob.@Scheduled(cron="0 0 4 * * *")` que invoca funcion SQL `purge_expired_data()` (game_events 90d, snapshots 30d, payment_webhooks_log 180d); protegido por `RedisLockRegistry` | SCHEMA_BD.sql V16 | C | 2 | S8 |
| TT-10-20 | `WalletConsistencyJob.@Scheduled(cron="0 0 5 * * *")` que valida invariante `SUM(wallet_transactions.delta) == users.virtual_currency_balance` y alerta a Prometheus si hay discrepancia | EPIC-07 DoD | C | 2 | S8 |
| TT-10-21 | HTTPS productivo con Nginx TLS: `80 -> 443`, certificados externos montados, WebSocket seguro `wss://`, variables productivas y documentacion APB de deploy | PASO_S11_08 | C | 3 | S11 |

## 3. Contratos producidos por esta epica

- [CONTRATOS_API.md](../../../../docs/05-referencia-tecnica/CONTRATOS_API.md) — fuente unica de endpoints REST.
- [PROTOCOLO_WEBSOCKET.md](../../../../docs/05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md) — eventos STOMP.
- [MOCKS_FRONTEND.md](../../../../docs/05-referencia-tecnica/MOCKS_FRONTEND.md) — mocks para desarrollo paralelo del frontend.

## 4. Servicios y puertos

| Servicio | Puerto | Propietario |
|---|---|---|
| Spring Boot API | 8080 | A |
| Angular dev | 4200 | B |
| Nginx local gateway | 8088 | C |
| Nginx produccion HTTPS | 80/443 | C |
| PostgreSQL | 5432 | C |
| Redis | 6379 | C |
| MinIO API | 9000 | C |
| MinIO Console | 9001 | C |
| Prometheus | 9090 | C |
| Grafana | 3000 | C |
| Swagger | 8080/swagger-ui.html | A |

## 5. Definition of Done especifico

- `docker compose up -d` levanta TODOS los servicios saludables.
- `curl localhost:8088/actuator/health` → `{"status":"UP"}` (check mínimo; puerto de acceso es 8088 vía gateway, no 8080 directo).
- `SELECT COUNT(*) FROM information_schema.tables WHERE schema='public'` >= 25 (incluye `wallet_transactions`).
- `docker exec codemon_redis redis-cli CONFIG GET appendonly` → `yes`.
- `docker exec codemon_redis redis-cli CONFIG GET appendfsync` → `everysec`.
- `redisKeyBuilder.build("presence", "42")` produce `<env>:presence:42` con el `app.env` correcto por perfil (dev/staging/prod).
- Test de integracion: `purge_expired_data()` retorna 3 filas con conteos por tabla (game_events, game_state_snapshots, payment_webhooks_log).
- `MaintenanceJob` y `WalletConsistencyJob` registrados (visibles en `actuator/scheduledtasks`).
- Mailtrap o equivalente capturando emails en dev.
- Grafana muestra al menos 1 panel con `rate(codemon_games_started_total[5m])`.
- `.gitignore` incluye `.env`, `target/`, `node_modules/`.
- Produccion documentada con Nginx TLS: HTTP redirige a HTTPS, WebSocket usa `wss://`, y certificados/secretos no se versionan.
- Ningun secret hardcodeado en codigo (verificado con `git grep -E "(password|secret|token).*=.*['\"]"`).
- Hereda [DOD.md](../../04_proceso/DOD.md) global.
