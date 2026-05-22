# 07 — Casos borde del flujo de partida

## ¿Qué hace este documento?

Define las reglas para situaciones que ocurren **fuera del flujo normal de juego** pero son indispensables para que una partida online termine de forma determinista:

1. **Concesión** — el jugador abandona explícitamente.
2. **Timeout de turno** — el jugador no actúa dentro del tiempo permitido.
3. **Reconexión** — el cliente pierde la conexión y vuelve.

Estas reglas son críticas para PvP ranked (R-WIN-04 ya cubre Muerte Súbita; este documento cubre los demás finales no naturales) y para que el motor nunca quede en estado inconsistente.

**Implementado en:** `game/engine/state` y `game/engine/GameEngine.java` (timeouts y reconexión vía `@Scheduled` y `WebSocketConfig`).
**Eventos asociados:** `GAME_CONCEDED`, `TURN_TIMEOUT`, `RECONNECT_SUCCESS`, `RECONNECT_FAILED` (ver `06-system-logic.md` y `PROTOCOLO_WEBSOCKET.md`).
**Razones de fin de partida:** `CONCEDED`, `TIMEOUT`, `DISCONNECTED` (ver tabla en `06-system-logic.md`).

---

## R-CONCEDE — Concesión de partida

### R-CONCEDE-01 — Cuándo puede conceder un jugador

Un jugador puede conceder en cualquier momento de la partida, **salvo cuando ya hay un `GAME_OVER` emitido**. Tres formas válidas de concesión:

1. **Botón explícito** en la UI: el cliente envía la acción `CONCEDE`.
2. **Cierre del navegador / desconexión prolongada**: ver `R-RECONNECT-03` (auto-concede al exceder ventana).
3. **Timeouts consecutivos**: ver `R-TIMEOUT-03` (3 timeouts seguidos del mismo jugador → auto-concede).

### R-CONCEDE-02 — Efectos sobre ranking

- En partidas **ranked**: el concesor cuenta como derrota completa para ELO/liga (sin descuento por "rendición temprana"). El rival recibe la victoria.
- En partidas **PvE** (vs bot): la concesión NO afecta ranking, pero termina la partida.
- En partidas de **sala privada (ROOM)**: la concesión NO afecta ranking.

### R-CONCEDE-03 — Comportamiento del motor

Al recibir `CONCEDE`:

1. Validar que el jugador es uno de los participantes y que la partida está activa.
2. Transitar a `GAME_OVER` con `reason = "CONCEDED"`.
3. Emitir el evento `GAME_CONCEDED` con `concedingPlayerId` y `winnerId`.
4. Emitir `GAME_OVER` con la información estándar.
5. Persistir el snapshot final (`game_state_snapshots`) y registrar el evento (`game_events`).
6. Actualizar `games.end_reason = 'CONCEDED'` en BD.

**Caso borde:** si ambos jugadores conceden simultáneamente (race condition rara pero posible vía dos requests al mismo tiempo), gana el primero en llegar al motor; el segundo recibe error `ALREADY_OVER`. La partida queda con `winnerId` del jugador NO concesor (el primero).

---

## R-TIMEOUT — Timeout de turno

### R-TIMEOUT-01 — Duración máxima de turno

| matchType | Duración por defecto | Configurable |
|---|---|---|
| `PVE` | 120 s | Sí (más relajado para entrenamiento) |
| `ROOM` | 90 s | Sí (anfitrión puede ajustar al crear la sala) |
| `QUEUE` (ranked) | 60 s | No (estandar competitivo) |

El temporizador arranca al emitirse `TURN_START` y se detiene al recibirse cualquier acción válida del jugador. Acciones que NO detienen el timer: ping del cliente, mensajes de chat, requests de `getState`.

### R-TIMEOUT-02 — Comportamiento al expirar

Al vencer el timer de turno:

1. El motor emite `TURN_TIMEOUT` con `playerId` y `consecutiveTimeouts` (contador del jugador en esta partida).
2. **Auto-pase de turno**: el motor ejecuta automáticamente la acción `END_TURN` en nombre del jugador.
3. Se procede al `EndPhaseState` y luego al turno del rival, como si el jugador hubiese pasado voluntariamente.
4. Excepción: si el motor estaba esperando `REPLACE_ACTIVE_AFTER_KO` (`awaitingReplacement = true`), el timeout NO ejecuta auto-pase porque no es un turno normal — se aplica directamente `R-TIMEOUT-03` (cuenta como timeout consecutivo).

### R-TIMEOUT-03 — Auto-concede tras timeouts consecutivos

- Si un jugador acumula **3 timeouts consecutivos** (sin acción válida intercalada), el motor lo trata como concesión:
  1. Emite `GAME_CONCEDED` con `concedingPlayerId = jugadorAFK`.
  2. Aplica `R-CONCEDE-03` con `reason = "TIMEOUT"` en `GAME_OVER`.
  3. `games.end_reason = 'TIMEOUT'`.
- El contador de timeouts se reinicia a 0 cada vez que el jugador ejecuta una acción válida en su turno.

---

## R-RECONNECT — Reconexión tras desconexión

### R-RECONNECT-01 — Ventana de reconexión

- Cuando el WebSocket de un jugador se cae (detectado vía heartbeat STOMP o falta de pong), el motor inicia un contador de **90 segundos** para ese jugador.
- Durante esos 90s la partida queda **pausada** (no avanza turno ni timer): el rival ve un indicador "Oponente desconectado, esperando…".
- Si el jugador desconectado reconecta (vía login con mismo JWT y suscripción a `/topic/game/{id}` y `/user/queue/game`), se aplica `R-RECONNECT-02`.
- La ventana de 90 s alinea con el TTL de `presence:<userId>` en Redis (ver `PATRONES_REDIS.md` sección 3).

### R-RECONNECT-02 — Reconexión exitosa

Al detectar que el cliente desconectado vuelve:

1. Cancelar el contador de desconexión.
2. Cargar el snapshot más reciente de `game_state_snapshots`.
3. Emitir `RECONNECT_SUCCESS` **solo al jugador reconectado** con el estado completo sanitizado vía `GameEngine.getState(gameId, playerId)`.
4. Reanudar el temporizador de turno desde donde quedó (no resetear).
5. Notificar al rival con un evento informativo de menor importancia (puede ser un evento simple `OPPONENT_RECONNECTED` o no emitirse nada — decisión de UX).

### R-RECONNECT-03 — Vencimiento de la ventana

Si pasan los 90 segundos sin reconexión:

1. Emitir `RECONNECT_FAILED` con `playerId` y `reason = "WINDOW_EXPIRED"`.
2. Aplicar `R-CONCEDE-03` automáticamente con el jugador desconectado como concesor.
3. `GAME_OVER` con `reason = "DISCONNECTED"`.
4. `games.end_reason = 'DISCONNECTED'`.

---

## Resumen de transiciones a `GAME_OVER`

| Origen | Quién la dispara | `GAME_OVER.reason` | `games.end_reason` |
|---|---|---|---|
| Premios completos (R-WIN-01) | El motor automáticamente | `PRIZES` | `PRIZES` |
| Mazo vacío al robar (R-WIN-02) | El motor automáticamente | `DECK_EMPTY` | `DECK_EMPTY` |
| Sin Pokémon en juego (R-WIN-03) | El motor automáticamente | `NO_POKEMON` | `NO_POKEMON` |
| Muerte súbita resuelta (R-WIN-04) | El motor automáticamente | `SUDDEN_DEATH` | `SUDDEN_DEATH` |
| Botón "abandonar" (R-CONCEDE-01) | Acción `CONCEDE` del cliente | `CONCEDED` | `CONCEDED` |
| 3 timeouts consecutivos (R-TIMEOUT-03) | Job `@Scheduled` del motor | `CONCEDED` | `TIMEOUT` |
| Ventana de reconexión vencida (R-RECONNECT-03) | Job `@Scheduled` del motor | `CONCEDED` | `DISCONNECTED` |

> Las 3 últimas comparten la lógica de R-CONCEDE-03 pero difieren en `end_reason` para auditoría y métricas.

---

## Casos borde adicionales

- **Concesión durante setup**: permitida. La partida termina antes de `GAME_START` con razón `CONCEDED`.
- **Reconexión durante setup**: la ventana es la misma (90 s); si vence, auto-concede aunque `GAME_START` no se haya emitido aún.
- **Doble desconexión**: si ambos jugadores se desconectan simultáneamente, el motor pausa la partida 90 s. Si solo uno reconecta, el otro pierde por `DISCONNECTED`. Si ninguno reconecta, ambos pierden — la partida se marca `end_reason = 'DISCONNECTED'` y ningún jugador recibe la victoria (ELO neutral en ranked).
- **Concesión en sala privada antes de match real**: si la partida nunca arrancó (esperando 2do jugador), el host puede cancelar la sala vía `DELETE /api/rooms/{code}` — eso NO es concesión.

---

## Referencias cruzadas

- **Endpoints REST**: `POST /api/games/{id}/concede` en `../05-referencia-tecnica/CONTRATOS_API.md`.
- **Eventos WebSocket**: `GAME_CONCEDED`, `TURN_TIMEOUT`, `RECONNECT_SUCCESS`, `RECONNECT_FAILED` en `../05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md`.
- **Schema BD**: columna `end_reason` en tabla `games` (`../05-referencia-tecnica/SCHEMA_BD.sql` V9).
- **Casos borde técnicos**: `../05-referencia-tecnica/GAME_ENGINE_DETALLES.md` secciones nuevas CONCEDE-01, TIMEOUT-01, RECONNECT-01.
- **Patrones Redis**: TTL de presencia en `../05-referencia-tecnica/PATRONES_REDIS.md` sección 3 (`presence:<userId>` 90 s) — valor canónico que define la ventana de reconexión.
