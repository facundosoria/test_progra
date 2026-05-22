# EPIC-05 — Multijugador y Matchmaking

## 1. Resumen

- **Valor de negocio:** dos jugadores pueden enfrentarse online (en cola ranked o sala privada con codigo) y vivir la partida en tiempo real via WebSocket.
- **Roles involucrados:** Jugador autenticado.
- **Sprints donde se completa:** S7.
- **Equipos:** C (matchmaking + salas), B (UI lobby + cola), A (soporte WebSocket desde EPIC-04).

## 2. Historias de Usuario

### HU-05-01 — Crear una sala privada con codigo
**Como** jugador, **quiero** crear una sala con un codigo de 6 caracteres, **para** invitar a un amigo a jugar.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: `POST /games/rooms/create` retorna `code` de 6 chars alfanumericos `[A-Z0-9]`.
- AC2: La sala expira en 10 minutos sin segundo jugador.
- AC3: Solo el creador puede cancelar via `DELETE /games/rooms/{id}`.
- AC4: Si el codigo generado colisiona en BD, se reintenta hasta 5 veces.
- AC5: La UI muestra el codigo y "Esperando rival...".

**RNF:**
- RNF-Concurrencia: `@Transactional` evita race condition donde 2 unirse simultaneo crean 2 Games.
- RNF-Limpieza: `@Scheduled(fixedRate=60000)` elimina salas expiradas.

**Sprint:** S7.

---

### HU-05-02 — Unirme a una sala privada con codigo
**Como** jugador invitado, **quiero** entrar con el codigo que me pasaron, **para** jugar contra mi amigo.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: `POST /games/rooms/join` con `code` valido y no expirado crea automaticamente el Game cuando llega el segundo.
- AC2: Codigo expirado → 410.
- AC3: Codigo inexistente → 404.
- AC4: WebSocket emite a `/topic/room/{code}` cuando se llena la sala (ambos jugadores reciben `gameId`).

**Sprint:** S7.

---

### HU-05-03 — Entrar a la cola ranked
**Como** jugador competitivo, **quiero** unirme a una cola y ser emparejado por mi nivel, **para** jugar contra rivales similares.

**Story Points:** 8

**Criterios de Aceptacion:**
- AC1: `POST /matchmaking/queue/join` con `deckId` valido me agrega al sorted set Redis con score = `skillRating`.
- AC2: Si no tengo rating previo, se asigna 1000.
- AC3: Algoritmo de ventana: ±100 inicial, expande +50 cada 5 s, max ±300.
- AC4: Match encontrado: WebSocket emite `MATCH_FOUND` a `/user/{userId}/queue/matchmaking` con `gameId` y `opponentUsername`.
- AC5: Timeout 30 s sin match → `QUEUE_TIMEOUT`.
- AC6: Usuario ya en cola → 409 `ALREADY_IN_QUEUE`.

**RNF:**
- RNF-Concurrencia: Lock Redis (`SET NX EX 5`) entre instancias evita doble match.
- RNF-Performance: P95 entrada cola < 200 ms; emparejamiento < 3 s para 2 usuarios cercanos.

**Sprint:** S7.

---

### HU-05-04 — Cancelar mi entrada en la cola
**Como** jugador, **quiero** salirme de la cola si me canse de esperar, **para** liberar mi tiempo.

**Story Points:** 2

**Criterios de Aceptacion:**
- AC1: `DELETE /matchmaking/queue/leave` me quita del sorted set Redis.
- AC2: Si ya tenia match formado, devuelve 409 (no puedo cancelar despues del match).
- AC3: La UI tiene un boton "Cancelar busqueda".

**Sprint:** S7.

---

### HU-05-05 — Recibir eventos de partida en tiempo real
**Como** jugador en partida, **quiero** ver las acciones del rival al instante, **para** que la experiencia sea fluida.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: Conexion STOMP a `/ws` con SockJS.
- AC2: Suscripcion a `/topic/game/{gameId}` recibe eventos publicos.
- AC3: Suscripcion a `/user/queue/game` recibe eventos privados (cartas robadas).
- AC4: Reconexion automatica al reabrir el browser, recupera estado via `GET /games/{id}/state`.
- AC5: `ngOnDestroy` desconecta sin memory leaks.

**RNF:**
- RNF-Latencia: eventos publicos < 200 ms desde la accion del rival.
- RNF-Robustez: 50 partidas concurrentes sin caida (test de carga).

**Dependencias:** HU-04-06, HU-04-09 (motor + websocket).
**Sprint:** S7.

## 3. Tareas Tecnicas

| ID | Tarea | Origen | Equipo | SP | Sprint |
|---|---|---|---|---|---|
| TT-05-01 | Endpoints `/games/rooms/**` (create, join, get, delete) | PASO_S07_01 | C | 5 | S7 |
| TT-05-02 | `@Scheduled` cleanup salas expiradas + `@EnableScheduling` | PASO_S07_01 | C | 2 | S7 |
| TT-05-03 | Cola Redis sorted set + algoritmo de ventana | PASO_S07_02 | C | 8 | S7 |
| TT-05-04 | Lock Redis distribuido para emparejamiento | PASO_S07_02 | C | 3 | S7 |
| TT-05-05 | Calculo ELO post-partida (`new = old + K(result - expected)`) | PASO_S07_02 | C | 3 | S7 |
| TT-05-06 | UI Lobby: PvE / Ranked / Sala privada (tabs) | PASO_S06_01 | B | 5 | S7 |

## 4. Contratos involucrados

- REST: `POST /games/rooms/create`, `POST /games/rooms/join`, `GET /games/rooms/{code}`, `DELETE /games/rooms/{id}`, `POST /matchmaking/queue/join`, `DELETE /matchmaking/queue/leave`.
- STOMP: `/topic/room/{code}` (`ROOM_FULL`), `/user/queue/matchmaking` (`MATCH_FOUND`, `QUEUE_TIMEOUT`).

## 5. Definition of Done especifico

- Test integracion: 2 usuarios con rating cercano → match en < 3 s.
- Test de carga: 50 partidas WebSocket concurrentes estables.
- Webhook de matchmaking testeado con replay de duplicado.
- Sin race condition entre 2 instancias del backend (test con Testcontainers + 2 nodos).
- Hereda [DOD.md](../../04_proceso/DOD.md) global.
