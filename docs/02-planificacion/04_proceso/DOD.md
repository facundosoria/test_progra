# Definition of Done — Codemon TCG

> Una HU o TT esta "Done" cuando cumple TODOS los criterios globales y los especificos de su epica. No hay HU "casi terminada".

---

## Definition of Ready (DoR)

Antes de entrar a un sprint, una HU/TT debe tener:

- [ ] ID asignado (`HU-XX-YY` o `TT-XX-YY`).
- [ ] Estimacion en story points (Fibonacci).
- [ ] Criterios de Aceptacion (AC) definidos en formato Given/When/Then.
- [ ] Requerimientos No Funcionales (RNF) listados (si aplica).
- [ ] Contrato API/WS referenciado (si aplica).
- [ ] Equipo asignado (A / B / C / multiequipo).
- [ ] Dependencias documentadas y resueltas o planeadas.

---

## Definition of Done global (aplica a TODA HU y TT)

### Codigo

- [ ] Codigo en `main` via Pull Request aprobada por al menos 1 reviewer del equipo correspondiente.
- [ ] Sin warnings de compilacion (Java + TypeScript).
- [ ] Sin comentarios `TODO` no resueltos relacionados con la HU.
- [ ] Code style aprobado: Checkstyle (Java) + ESLint/Prettier (TypeScript) sin errores.
- [ ] Sin secrets hardcoded (verificable con `git grep`).
- [ ] Variables de entorno usadas para todo lo configurable.
- [ ] Codigo, identificadores, comentarios, logs, mensajes de error, tests, fixtures, mocks, datos runtime y textos visibles de UI en ingles (segun CONVENCIONES.md).
- [ ] Documentacion `.md` para humanos/agentes en español; snippets, contratos y strings runtime dentro de `.md` en ingles.

### Tests

- [ ] Tests unitarios (JUnit 5 + Mockito o Jasmine) cubren happy path + edge cases.
- [ ] Cobertura JaCoCo ≥ **80% global**, ≥ **90% en motor de juego** (`AttackPipeline`, `DamageCalculator`, `StatusEffectManager`, `VictoryConditionChecker`, `RuleValidator`, `DeckValidationService`).
- [ ] Tests de integracion con Testcontainers donde aplique (BD, Redis, MinIO).
- [ ] Comando `./mvnw test` y `npm test` pasan en local y CI.

### Documentacion

- [ ] Endpoints documentados en Swagger con ejemplos de request/response.
- [ ] Eventos STOMP documentados en [PROTOCOLO_WEBSOCKET.md](../../../docs/05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md).
- [ ] Si la HU introduce conceptos nuevos, glosario actualizado en [GLOSARIO.md](../../../docs/05-referencia-tecnica/GLOSARIO.md).
- [ ] El archivo `EPIC.md` correspondiente refleja AC y RNF finales.

### Seguridad

- [ ] No expone PII innecesaria.
- [ ] CORS y rate-limit aplicados donde corresponde.
- [ ] Inputs validados (Bean Validation backend, Reactive Forms frontend).
- [ ] Errores de servidor no exponen stack traces al usuario final.
- [ ] Verificacion de pertenencia en endpoints `me`/`mine` (no se accede a recursos de otros).

### Performance

- [ ] P95 de endpoints REST < 500 ms en condiciones nominales (excepciones documentadas).
- [ ] Sin N+1 queries (usar `@EntityGraph` o `JOIN FETCH`).
- [ ] Indices en todas las FK y columnas de busqueda frecuente.
- [ ] Frontend: lazy loading de rutas no criticas.

### Monitoreo

- [ ] Logs estructurados en services criticos (Auth, Game, Payment).
- [ ] Metricas custom relevantes expuestas (`codemon_*`).
- [ ] `GET /actuator/health` reporta UP en local y CI.

### UX/UI (cuando aplica)

- [ ] Estados de carga visibles durante llamadas HTTP (spinners / skeletons).
- [ ] Mensajes de error claros en ingles, no stack traces.
- [ ] Toast/notificaciones funcionales.
- [ ] Accesible: contraste AA, focus visible, navegacion por teclado.

---

## DoD especifico por epica

### EPIC-01 — Autenticacion y Seguridad

- [ ] Cobertura ≥ 85% en `AuthService`, `JwtTokenProvider`, `EmailService`.
- [ ] Mailtrap (dev) recibe los emails de verificacion.
- [ ] Rate limit verificado: 5 intentos verify-email → 429; 1 resend cada 60 s.
- [ ] OAuth2 testeado contra mock servers.
- [ ] No se loguean passwords ni tokens.

### EPIC-02 — Catalogo y Coleccion

- [ ] `SELECT COUNT(*) FROM cards_catalog = 146`.
- [ ] 292 imagenes accesibles en MinIO (HTTP 200).
- [ ] Filtros combinables testeados.
- [ ] Vista materializada `user_collection_stats` refrescada al abrir sobre.

### EPIC-03 — Constructor de Mazos

- [ ] Cobertura `DeckValidationService` ≥ 90%.
- [ ] 5 reglas R-DECK-01..05 testeadas con casos validos y de error.
- [ ] 3 mazos starter cargados via seed y validan correctamente.
- [ ] Drag & drop verificado en Chrome y Firefox.

### EPIC-04 — Motor de Juego

- [ ] Cobertura ≥ 90% en `DamageCalculator`, `StatusEffectManager`, `AttackPipeline`, `VictoryConditionChecker`, `RuleValidator`.
- [ ] `getState()` sanitiza: `hand` rival = null, `deck` ambos = null (solo `deckSize`), `prizes` ambos = null (solo `prizesCount`).
- [ ] Snapshot async tras cada `ATTACK`, `KO`, `PRIZE_TAKEN`, `STATUS_APPLIED`.
- [ ] Test E2E PvE completo termina en `GAME_OVER` sin error 500.
- [ ] Sin race conditions en `processAction` con 10 acciones simultaneas (test).

### EPIC-05 — Multijugador y Matchmaking

- [ ] Test integracion: 2 usuarios con rating cercano → match en < 3 s.
- [ ] Test de carga WebSocket: 50 partidas concurrentes estables (CPU < 70%, sin errores).
- [ ] Sin doble match con 2 instancias backend (test con Testcontainers).
- [ ] Salas expiradas eliminadas via `@Scheduled`.

### EPIC-06 — Tablero y UX

- [ ] Lighthouse mobile >= 80 Performance / >= 90 Accessibility.
- [ ] Drag & drop verificado en Chrome, Firefox, Safari, tablet (touch).
- [ ] `ngOnDestroy` desconecta WebSocket (sin memory leak en DevTools).
- [ ] Test manual: partida PvE completa desde lobby → tablero → game over.

### EPIC-07 — Tienda y Monetizacion

- [ ] Webhook idempotente: replay del mismo `mp_event_id` no duplica coins (test).
- [ ] Distribucion rareza verificada con test estadistico (1000 sobres → ratio ±5%).
- [ ] Cobertura `PaymentService` ≥ 85%.
- [ ] Rate-limit `create-preference` 10 req/min/usuario.
- [ ] Saldo insuficiente → 422 antes de tocar MP.

### EPIC-08 — Bot e IA

- [ ] 100 partidas PvE EASY consecutivas sin excepcion.
- [ ] Cobertura `Bot*` ≥ 75%.
- [ ] Bot HARD timeout-safe: si excede 5 s, fallback a Medium.
- [ ] Mensajes del bot con delay 1-3 s (UX humana).

### EPIC-09 — Social y Comunidad

- [ ] Vista materializada `leaderboard` con `REFRESH CONCURRENTLY` funcional.
- [ ] Test: solicitud duplicada → error; solicitud a si mismo → error.
- [ ] Test: cruce umbral 1000 → liga actualizada a PLATA.
- [ ] Cobertura `RankingService`, `FriendsService`, `NewsService` ≥ 80%.

### EPIC-10 — Infraestructura y DevOps

- [ ] `docker compose up -d` levanta TODOS los servicios saludables en < 90 s.
- [ ] `actuator/health` → `{"status":"UP"}` (Redis y DB son componentes internos; el check mínimo es status UP).
- [ ] Grafana muestra al menos 1 panel con metricas custom.
- [ ] CI corre tests en cada PR a `main`.
- [ ] Branch protection activa.

### EPIC-11 — Calidad y Testing

- [ ] Cobertura JaCoCo ≥ 80% global.
- [ ] Suite Playwright pasa en headless (Chrome + Firefox) en CI.
- [ ] Lighthouse mobile cumple thresholds.
- [ ] Test de carga ejecutado y reportado en `docs/08-desarrollo-con-ia/pasos/REPORTE_CARGA.md`.

---

## Checklist final de entrega (Sprint 11)

Esta es la "macro DoD" del proyecto, consolidada en [CHECKLIST_ENTREGA.md](../02_sprints/CHECKLIST_ENTREGA.md).

- [ ] Todas las HU de los sprints S0-S11 en estado DONE.
- [ ] Suite Playwright cubre flujos: auth, mazos, partida PvE, partida PvP, compra de sobre.
- [ ] Cobertura global ≥ 80%, motor ≥ 90%.
- [ ] Lighthouse mobile cumple thresholds.
- [ ] `docker compose up -d --build` arranca el sistema completo desde cero.
- [ ] Documentacion actualizada: README, CONTRIBUTING, INDICE, contratos.
- [ ] Demo final ejecutable end-to-end sin errores.
