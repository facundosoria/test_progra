# Checklist de Entrega — Codemon TCG

> Reemplaza al antiguo `CODEMON_CHECKLIST.md`. Ahora alineado al [DOD.md](../04_proceso/DOD.md) y agrupado por epica + sprint en lugar de por bloque tecnico.

> **Como usarlo:** al cierre de cada sprint, marcar los items correspondientes. La entrega final del proyecto requiere TODOS los items marcados.

---

## Etiquetas

| Badge | Equipo |
|---|---|
| `[A]` | Equipo A — Backend Core / Motor |
| `[B]` | Equipo B — Frontend Angular |
| `[C]` | Equipo C — Backend Auxiliar + DevOps |
| `[A+B]` | Verifican A y B juntos |
| `[ALL]` | Verifican los 3 equipos |

---

## Sprint 0 — Infraestructura y Contratos (EPIC-10)

- `[ALL]` □ CONTRATOS_API.md cubre todos los dominios: auth, cards, decks, games, rooms, matchmaking, collection, boosters, payments, leaderboard, news, friends.
- `[ALL]` □ PROTOCOLO_WEBSOCKET.md cubre todos los eventos STOMP con payloads.
- `[B]` □ MOCKS_FRONTEND.md tiene JSONs de ejemplo por endpoint.
- `[C]` □ Java 21, Maven 3, Node 20, Angular CLI 21, Docker instalados.
- `[C]` □ PostgreSQL, Redis, MinIO healthy en Docker.
- `[A]` □ Spring Boot 3.x compila (`./mvnw clean compile`).
- `[A]` □ application.yml con env vars para BD, Redis, MinIO, JWT, CORS, MP.
- `[A]` □ 15 migraciones Flyway aplicadas; `SELECT COUNT(*) FROM tables WHERE schema='public' >= 22`.
- `[B]` □ Angular 21 con feature folders y mock interceptor; environment.ts usa rutas relativas `/api` y `/ws`.
- `[C]` □ Gateway Nginx en `localhost:8088`: rutas `/api`, `/ws`, `/actuator`, `/swagger-ui`, `/minio` funcionan.
- `[ALL]` □ `curl localhost:8088/actuator/health` → `{"status":"UP"}` (check mínimo verificable; no requiere ver componentes db/redis en el body).
- `[ALL]` □ `curl localhost:8088/` → Angular SPA carga sin errores.
- `[A]` □ Swagger en `localhost:8088/swagger-ui.html`.
- `[C]` □ Imágenes MinIO accesibles vía `localhost:8088/minio/*` (no expuesto directamente en :9000).
- `[ALL]` □ CI configurado en GitHub Actions (tests + build).
- `[ALL]` □ Branch protection en `main`.

## Sprint 1 — Auth basica (EPIC-01 parcial)

### HU-01-01 Registro
- `[A]` □ `POST /auth/register` crea usuario, email_verified=true (temporal en S1).
- `[A]` □ Password hash BCrypt rounds≥10.
- `[A]` □ Email duplicado → 409.
- `[A]` □ Tests: registro feliz + duplicado + password debil.

### HU-01-03 Login
- `[A]` □ `POST /auth/login` retorna accessToken (15 min) + refreshToken (7 dias).
- `[A]` □ Credenciales incorrectas → 401 sin distinguir email vs password.
- `[A]` □ JWT firmado HS256, secret >=32 chars desde env.

### HU-01-04 Logout
- `[A]` □ `POST /auth/logout` revoca refresh token (`revoked=true`).
- `[A]` □ Refresh revocado → 401 al usarlo.

### HU-01-05 Refresh
- `[A]` □ `POST /auth/refresh` emite nuevo access token.
- `[A]` □ Refresh revocado/expirado → 401.

### Frontend (todas las HU de S1)
- `[B]` □ Pantallas /auth/register, /auth/login, /home funcionando.
- `[B]` □ HttpJwtInterceptor agrega JWT a requests.
- `[B]` □ Refresh automatico transparente al usuario.
- `[B]` □ AuthGuard redirige a /auth/login si no autenticado.
- `[A+B]` □ **GATE 1a** verde: registro → login → /home funciona end-to-end.

## Sprint 2 — Catalogo y Mazos (EPIC-02 parcial + EPIC-03 completa)

### HU-02-01..03 Catalogo
- `[A]` □ 146 cartas seedeadas (`SELECT COUNT FROM cards_catalog = 146`).
- `[A]` □ 292 imagenes en MinIO accesibles (HTTP 200).
- `[A]` □ Endpoints `GET /cards`, `GET /cards/{id}` con paginacion y filtros.
- `[B]` □ UI grid con paginacion, filtros y detalle.

### HU-03-01..06 Mazos
- `[A]` □ DeckValidationService con 5 reglas R-DECK-01..05.
- `[A]` □ Cobertura `DeckValidationService` ≥ 90%.
- `[A]` □ CRUD endpoints con verificacion de pertenencia (`/decks/**`).
- `[A]` □ 3 mazos starter seedeados.
- `[A]` □ Test: ver mazo ajeno → 403; eliminar starter → 422.
- `[B]` □ Deck Builder con drag & drop (cdk).
- `[B]` □ Validacion en tiempo real con errores especificos.
- `[A+B]` □ **GATE 1b** verde: crear mazo valido de 60 desde UI.

## Sprint 3 — Motor: setup + turnos sin combate (EPIC-04 parcial)

### Andamiaje
- `[A]` □ GameContext con `paralyzedOnTurn`, `awaitingReplacement`, `firstTurnAttackBlocked`, `energyAttachedThisTurn`, `supporterPlayedThisTurn`, `retreatedThisTurn`.
- `[A]` □ InPlayPokemon usa `instanceId` UUID.
- `[A]` □ Listas `PlayerBoard` mutables (`new ArrayList<>()`).

### Setup
- `[A]` □ Barajado con `SecureRandom`.
- `[A]` □ `hasBasicPokemon()` excluye Restored.
- `[A]` □ Mulligan Caso A: ambos rebarajan, mulliganCount no incrementa.
- `[A]` □ Mulligan Caso B: rival roba `mulliganCount-1` cartas extra.
- `[A]` □ Premios DESPUES de robar mano inicial.
- `[A]` □ Invariante: `deck+hand+prizes == 60` para ambos.
- `[A]` □ `getState()` sanitiza: `player2.hand=null` para player1.

### Draw + Main
- `[A]` □ DrawPhase verifica mazo vacio ANTES del robo.
- `[A]` □ MainPhase: PLAY_BASIC / EVOLVE / ATTACH_ENERGY / PLAY_SUPPORTER / PLAY_STADIUM / RETREAT.
- `[A]` □ Stadium duplicado mismo nombre → error.
- `[A]` □ Tests: cobertura `SetupState` ≥ 90%.

## Sprint 4 — Motor: combate (EPIC-04 parcial)

### DamageCalculator + StatusEffectManager
- `[A]` □ Orden: `(base + bonus_atacante) * weakness - resistance - reduccion`, min 0.
- `[A]` □ Daño directo omite weakness/resistance.
- `[A]` □ Daño a banca omite weakness/resistance.
- `[A]` □ ASLEEP/PARALYZED/CONFUSED se reemplazan; POISONED y BURNED coexisten.
- `[A]` □ Cobertura ≥ 90% en ambos.

### AttackPipeline (9 handlers)
- `[A]` □ Orden estricto: Validate → CalcBase → AttackerFX → Weakness → Resistance → DefenderFX → DealDamage → ExecuteEffect → CheckKO.
- `[A]` □ KO normal → 1 premio; EX/MEGA → 2 premios.
- `[A]` □ `hasRequiredEnergies()` satisface tipos especificos antes de Colorless.
- `[A]` □ Confusion: 30 dano directo a si mismo, sin weakness propia.
- `[A]` □ Cobertura ≥ 90%.

### Retreat + Premios
- `[A]` □ Retreat bloqueado si ASLEEP o PARALYZED; cura condiciones, dano permanece, Tool permanece.
- `[A]` □ Premios se mueven al hand del jugador que hizo KO.
- `[A]` □ KO sin reemplazo → R-WIN-03.

## Sprint 5 — Primera partida PvE jugable end-to-end (EPIC-04 cierra + EPIC-06/08 inicio)

### EndPhase + Bot EASY + GameEngine + WS
- `[A]` □ EndPhase orden: Veneno → Quema → Sueño → Paralisis → KOs → cambiar jugador.
- `[A]` □ BURNED cara: 0 dano, marcador permanece; cruz: +20.
- `[A]` □ Bot EASY siempre incluye END_TURN; nunca loop infinito.
- `[A]` □ Delay 500-1000 ms entre acciones del bot.
- `[A]` □ Cobertura `VictoryConditionChecker` ≥ 90%.
- `[A]` □ R-WIN-01..04 testeadas.
- `[A]` □ Sudden Death con 1 premio.
- `[A]` □ ELO solo en `matchType=QUEUE`.
- `[A]` □ WebSocket STOMP `/ws` + `/topic` + `/user`.
- `[A]` □ Endpoints `/games`, `/games/{id}/action`, `/games/{id}/state`.

### Frontend tablero minimo
- `[B]` □ GameBoardComponent muestra zonas y estado.
- `[B]` □ WebSocketService con reconexion + resync via `getState()`.
- `[B]` □ `ngOnDestroy` desconecta sin memory leak.
- `[ALL]` □ **GATE 2** verde: partida PvE completa de inicio a `GAME_OVER` desde la UI.

## Sprint 6 — Tablero pulido + Lobby (EPIC-06)

- `[B]` □ Drag & drop completo con `@angular/cdk/drag-drop`.
- `[B]` □ Animaciones dano (shake + numero), KO (fade out), status (icono pulsante).
- `[B]` □ Lobby tabs: PvE / Ranked / Sala privada.
- `[B]` □ ChatWindow con sanitizacion + rate limit visual.
- `[B]` □ Toast notifications: KO, premio, condicion, nuevo turno.
- `[B]` □ Panel de acciones oculta "Atacar" en primer turno bloqueado.

## Sprint 7 — PvP en tiempo real (EPIC-05)

### Salas privadas
- `[C]` □ Endpoint create con codigo 6 chars alfanumericos unico.
- `[C]` □ Sala expira 10 min.
- `[C]` □ `@Scheduled(fixedRate=60000)` limpia expiradas.
- `[C]` □ `@Transactional` evita 2 Games simultaneos.
- `[C]` □ Solo creador puede cancelar.
- `[ALL]` □ **GATE 3** verde: 2 humanos juegan via codigo.

### Matchmaking
- `[C]` □ Sorted set Redis `matchmaking:queue` con score=skillRating.
- `[C]` □ Ventana ±100 inicial, expande +50 cada 5s, max ±300.
- `[C]` □ Timeout 30s → `QUEUE_TIMEOUT`.
- `[C]` □ Lock Redis (`SET NX EX 5`) entre instancias.
- `[C]` □ ELO: `K=32` rating<2000, `K=16` rating>=2000.
- `[C]` □ Skill rating inicial 1000.
- `[ALL]` □ **GATE 4** verde: 2 usuarios con rating cercano → match en <3s.

## Sprint 8 — Tienda + 2FA + metricas (EPIC-01 cierra core + EPIC-07 + EPIC-10 metrics)

### 2FA
- `[C]` □ `register` setea `email_verified=false`.
- `[C]` □ Codigo 6 digitos `SecureRandom`, hashed BCrypt en BD.
- `[C]` □ `verify-email` valida codigo.
- `[C]` □ `resend-code` rate limit 1/min.
- `[C]` □ Codigo expira 30 min.
- `[C]` □ 5 intentos fallidos → bloqueo 15 min (persistido).
- `[C]` □ EmailService con `@Async`.
- `[C]` □ Mailtrap configurado para dev.

### Mercado Pago
- `[C]` □ `POST /payments/create-preference` retorna URL sandbox.
- `[C]` □ Webhook `/webhooks/mercado-pago` PUBLICO (sin JWT).
- `[C]` □ Idempotencia: verificar `mp_event_id` antes de procesar.
- `[C]` □ Webhook duplicado → no acredita coins dos veces.
- `[C]` □ `WalletService.deductCoins()` `@Transactional`.

### Sobres
- `[C]` □ `POST /booster-packs/{id}/open` retorna 10 cartas.
- `[C]` □ Distribucion: 5 comunes, 3 poco comunes, 1 rara, 1 holo.
- `[C]` □ Cooldown Redis 24h con TTL 86400.
- `[C]` □ `user_collection` incrementa `quantity` (indice unico).

### Metricas
- `[C]` □ `/actuator/prometheus` expone metricas `codemon_*`.
- `[C]` □ Counters: registered, games_started, boosters_opened, revenue.
- `[C]` □ Gauges: users_online, games_active, queue_size.
- `[C]` □ Grafana dashboard con `rate(codemon_games_started_total[5m])`.
- `[ALL]` □ **GATE 5** verde: comprar coins → abrir sobre → coleccion crece.

### Frontend
- `[B]` □ UI Shop con sobres + boton comprar.
- `[B]` □ BoosterPackOpener animado.
- `[B]` □ WalletDisplay en shell.
- `[B]` □ Verify-email con 6 inputs + countdown 30 min.
- `[B]` □ EmailVerifiedGuard.

## Sprint 9 — Social v1 (EPIC-09 parcial)

### Ligas
- `[C]` □ Victoria QUEUE/ROOM → +25 puntos.
- `[C]` □ Umbrales: BRONCE 0, PLATA 1000, ORO 2500.
- `[C]` □ Cruce de umbral actualiza `users.league`.
- `[C]` □ PvE no afecta ligas.

### Amigos
- `[C]` □ Solicitud PENDING → ACCEPTED/REJECTED.
- `[C]` □ Solo receptor puede aceptar.
- `[C]` □ Solicitud a si mismo → error; duplicada → error.
- `[C]` □ Presencia Redis `user:presence:{userId}` TTL 5 min.
- `[C]` □ `setPlaying(userId, gameId)` durante partida.
- `[B]` □ Lista con iconos 🟢 / 🎮 / ⚫.
- `[B]` □ Boton "Retar" solo si ONLINE.

### Leaderboard + Noticias
- `[C]` □ Vista materializada `leaderboard` con indice unico.
- `[C]` □ `REFRESH MATERIALIZED VIEW CONCURRENTLY` post-partida.
- `[C]` □ `GET /news` PUBLICO; `POST /news` solo ADMIN.
- `[C]` □ Verificacion ADMIN contra BD (no solo JWT).
- `[B]` □ UI Leaderboard con tabs Ranked vs Todos.
- `[B]` □ UI News con badges por categoria.
- `[ALL]` □ **GATE 6** verde: ganar partida → liga sube → aparece en leaderboard.

## Sprint 10 — OAuth + Perfil (EPIC-01 cierra OAuth + EPIC-09 cierra)

### OAuth2
- `[C]` □ `/oauth2/authorization/google` y `/github` redirigen a proveedor.
- `[C]` □ Backend genera JWT propio (no usa el del proveedor).
- `[C]` □ Usuario nuevo via OAuth: `email_verified=true`, `password_hash=null`.
- `[C]` □ Usuario existente con mismo email: vinculado sin duplicar.
- `[C]` □ `password_hash null` no rompe login normal.
- `[C]` □ Redirige a `{frontendUrl}/auth/callback?token=&refreshToken=`.
- `[C]` □ Test: usuario OAuth no puede login con password.
- `[B]` □ Botones "Continuar con Google/GitHub" en /auth/login.
- `[B]` □ Componente `/auth/callback`.
- `[ALL]` □ **GATE 7** verde: login con Google funciona.

### Perfil + Wallet
- `[C]` □ `GET /users/me/profile` consolidado (stats + collection + recent + wallet).
- `[C]` □ `GET /users/{id}/profile` solo info publica.
- `[C]` □ `GET /users/me/payments` con historial.
- `[B]` □ ProfileComponent muestra stats, recent games, wallet history.

## Sprint 11 — Pulido + bots avanzados + E2E (EPIC-08 cierra + EPIC-11 cierra)

### Bots avanzados
- `[A]` □ BotMedium con scoring greedy, prefiere KO inmediato.
- `[A]` □ BotHard minimax depth 3 + alfa-beta, timeout 5s con fallback.
- `[A]` □ Tabla `game_chat_messages` indexada.
- `[A]` □ BotChatService con triggers GAME_START/ATTACK/KO.
- `[A]` □ Personalidades Hernan/Santoro/Ramiro en config.
- `[A]` □ 100 partidas EASY consecutivas sin excepcion.
- `[B]` □ Mensajes bot con label "Bot" y delay 1-3s.

### Responsive
- `[B]` □ Layout adaptable con Tailwind CSS (grid/flex + breakpoints sm/md/lg).
- `[B]` □ Drag&drop touch en tablet.
- `[B]` □ Sin scroll horizontal >= 360px.
- `[B]` □ Lighthouse mobile >= 80 Performance / >= 90 Accessibility.

### Tests finales
- `[B]` □ Suite Playwright cubre: auth, mazos, partida PvE, partida PvP, compra sobre.
- `[A]` □ Test de carga 50 partidas WebSocket concurrentes (CPU<70%, sin errores).
- `[ALL]` □ Cobertura JaCoCo global ≥ 80%.
- `[A]` □ Cobertura motor ≥ 90%: AttackPipeline, DamageCalculator, StatusEffectManager, VictoryConditionChecker, RuleValidator.
- `[A+C]` □ Documentacion Swagger completa con ejemplos.
- `[ALL]` □ **GATE 8** verde: producto entregable.

---

## Checklist final de entrega (transversal)

### Codigo
- `[ALL]` □ Sin warnings de compilacion.
- `[ALL]` □ Sin TODOs sin resolver.
- `[ALL]` □ Sin secrets en codigo (verificable con `git grep`).
- `[A]` □ Formateado segun CONVENCIONES.md.
- `[ALL]` □ Codigo, identificadores, comentarios, logs, errores, tests, fixtures, mocks y datos runtime en ingles.
- `[ALL]` □ Textos visibles de UI en ingles, incluyendo mockups HTML de referencia.
- `[ALL]` □ Documentacion `.md` en español; snippets, contratos y strings runtime dentro de `.md` en ingles.

### Seguridad
- `[A]` □ JWT con expiry (access 15 min, refresh 7 dias).
- `[C]` □ Rate limiting: verify-email (5), resend (1/min), create-preference (10/min).
- `[A]` □ CORS configurado.
- `[C]` □ Produccion sirve por HTTPS y WebSocket seguro (`https://<dominio>` + `wss://<dominio>/ws`).
- `[A]` □ SQL injection prevenido (JPA prepared statements).
- `[B]` □ XSS prevenido (Angular sanitizer).
- `[ALL]` □ Sin credentials en logs.

### Performance
- `[A]` □ Sin N+1 (JOIN FETCH/EntityGraph).
- `[A]` □ Indices en FK.
- `[C]` □ Redis para queue, cooldown, presencia.
- `[B]` □ Lazy loading rutas Angular.

### Monitoreo
- `[C]` □ Logs en services criticos (Game, Auth, Payment).
- `[C]` □ `/actuator/health` UP en produccion.
- `[C]` □ Metricas custom visibles en Grafana.

### UX/UI
- `[B]` □ Responsive mobile-first.
- `[B]` □ Mensajes de error claros en ingles.
- `[B]` □ Loading states.
- `[B]` □ Toasts.

### Despliegue
- `[C]` □ `docker --context colima compose up -d --build` arranca todo desde cero con gateway en `localhost:8088`.
- `[C]` □ `docker compose --env-file .env.production -f docker-compose.yml -f docker-compose.prod.yml config` valida el overlay HTTPS productivo.
- `[C]` □ `.env.example` documentado con todas las variables incluyendo `MINIO_PUBLIC_URL` y `CORS_ALLOWED_ORIGINS`.
- `[C]` □ `.env.production.example` documentado con `PUBLIC_BASE_URL`, `MINIO_PUBLIC_URL`, `CORS_ALLOWED_ORIGINS` y `TLS_CERTS_DIR`.
- `[ALL]` □ Demo final ejecutable end-to-end sin errores desde `http://localhost:8088`.

---

## Firma de cierre

| Campo | Valor |
|---|---|
| Fecha de cierre del Sprint 11 | _______ |
| Equipo A — responsable | _______ |
| Equipo B — responsable | _______ |
| Equipo C — responsable | _______ |
| Product Owner | _______ |
| Notas |  |
