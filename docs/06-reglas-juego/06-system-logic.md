# 06 — Lógica del Sistema (WebSocket Events)

## ¿Qué hace este documento?
Define **todos** los eventos que el motor de juego debe emitir por WebSocket y cuándo emitirlos. Es la referencia para implementar el `GameEventPublisher` (patrón Observer). Incluye la distinción entre eventos públicos (ambos jugadores) y privados (solo el dueño), y qué datos van en cada evento.

**Implementado en:** `game/engine/observer/GameEventPublisher.java` y `game/engine/observer/WebSocketEventListener.java`
**Regla de seguridad clave:** Los eventos públicos NUNCA incluyen mano del rival, orden del mazo ni cartas de Premio
**Referencia:** RF-06 (tiempo real), RNF-05 (seguridad)

# 06 — Lógica del Sistema (WebSocket Events)

**Alcance:** Eventos que el motor de juego debe emitir por WebSocket para sincronización en tiempo real.
**Referencia de reglas:** event-types.md (all rules).

---

## Principios generales de emisión de eventos

### El sistema DEBE
- Emitir un evento por cada acción de juego significativa, en el momento en que ocurre.
- Emitir eventos en el orden en que ocurren las acciones (no acumular y enviar en lote).
- Sincronizar el estado del juego con ambos clientes después de cada evento que cambie el estado.
- Emitir eventos privados (como `CARD_DRAWN`) **únicamente** al jugador correspondiente; no al oponente.
- Emitir eventos públicos (como `POKEMON_KO`, `DAMAGE_DEALT`) a ambos jugadores.
- Emitir `STATUS_BLOCKED` ANTES de retornar de `StatusEffectManager.applyStatus()` cuando `ApplyStatusContext.isBlocked() == true`. NO emitir `STATUS_APPLIED` en ese caso.

### El sistema NO DEBE
- Omitir eventos aunque el efecto sea "sin cambio visible" (ej. una moneda que no cambia el estado de Confusión).
- Exponer información privada (cartas en mano, contenido del mazo, cartas de Premio) a través de eventos públicos.
- Emitir eventos fuera del orden de resolución definido en las reglas.

---

## Tabla de eventos

### Eventos de partida

| Evento | Cuándo se emite | Datos incluidos | Visibilidad |
|---|---|---|---|
| `GAME_START` | Al iniciar la partida (tras setup completo) | `players`, `deckSizes`, `firstPlayerId` | Ambos jugadores |
| `GAME_OVER` | Cuando se cumple una condición de victoria | `winnerId`, `loserId`, `reason` (PRIZES / DECK_EMPTY / NO_POKEMON / SUDDEN_DEATH) | Ambos jugadores |

---

### Eventos de turno

| Evento | Cuándo se emite | Datos incluidos | Visibilidad |
|---|---|---|---|
| `TURN_START` | Al inicio de cada turno | `playerId`, `turnNumber` | Ambos jugadores |
| `CARD_DRAWN` | Al robar una carta (inicio de turno o efecto de carta) | `playerId`, `cardId` (solo al dueño), `deckRemaining` | Solo el dueño de la carta |

---

### Eventos de acciones del turno

| Evento | Cuándo se emite | Datos incluidos | Visibilidad |
|---|---|---|---|
| `POKEMON_PLAYED` | Al colocar un Pokémon Básico en juego desde la mano | `playerId`, `cardId`, `zone` (`ACTIVE` / `BENCH`) | Ambos jugadores |
| `POKEMON_EVOLVED` | Al evolucionar un Pokémon | `playerId`, `fromCardId`, `toCardId`, `zone` | Ambos jugadores |
| `ENERGY_ATTACHED` | Al adjuntar una carta de Energía | `playerId`, `energyCardId`, `targetPokemonId` | Ambos jugadores |
| `TRAINER_PLAYED` | Al jugar una carta Trainer (Item, Supporter, Stadium, Tool) | `playerId`, `cardId`, `trainerType`, `effect`, `replacedStadiumOwnerId` (solo si Stadium reemplaza otro, alinea con T-05 y A-3) | Ambos jugadores |
| `ABILITY_USED` | Al activar una Habilidad | `playerId`, `pokemonId`, `abilityName` | Ambos jugadores |
| `RETREAT` | Al retirar el Pokémon Activo | `playerId`, `retreatedPokemonId`, `newActiveId`, `energiesDiscarded` | Ambos jugadores |

---

### Eventos de combate

| Evento | Cuándo se emite | Datos incluidos | Visibilidad |
|---|---|---|---|
| `ATTACK_DECLARED` | Al anunciar el ataque (antes de resolverlo) | `attackerId`, `defenderId`, `attackName` | Ambos jugadores |
| `DAMAGE_DEALT` | Tras calcular y aplicar el daño final | `attackerId`, `defenderId`, `baseDamage`, `weaknessApplied` (bool), `resistanceApplied` (bool), `finalDamage` | Ambos jugadores |
| `POKEMON_KO` | Cuando un Pokémon alcanza 0 HP efectivos | `pokemonId`, `ownerId`, `prizesToTake` (1 o 2) | Ambos jugadores |
| `PRIZE_TAKEN` | Cuando un jugador toma carta(s) de Premio | `playerId`, `count`, `prizesRemaining` | Ambos jugadores |

---

### Eventos de condiciones especiales

| Evento | Cuándo se emite | Datos incluidos | Visibilidad |
|---|---|---|---|
| `STATUS_APPLIED` | Al aplicar una condición especial | `targetPokemonId`, `status` (`POISONED` / `BURNED` / `ASLEEP` / `PARALYZED` / `CONFUSED`) | Ambos jugadores |
| `STATUS_REMOVED` | Al eliminar una condición especial | `targetPokemonId`, `status`, `reason` (`RETREATED` / `EVOLVED` / `WOKE_UP` / `PARALYSIS_EXPIRED`) | Ambos jugadores |
| `STATUS_BLOCKED` | Cuando una habilidad pasiva bloquea la aplicación de una condición especial sobre un Pokémon inmune (ej. Slurpuff Sweet Veil sobre Pokémon con Energía Hada) | `targetPokemonId`, `targetPokemonName`, `attemptedStatus` (`POISONED` / `BURNED` / `ASLEEP` / `PARALYZED` / `CONFUSED`), `blockingAbilityName` (ej. `"Sweet Veil"`), `blockingCardId` (ej. `"xy1-Slurpuff"`) | Ambos jugadores |

#### Mensaje de UI para `STATUS_BLOCKED`

El cliente DEBE renderizar este evento como leyenda en pantalla:

> **It doesn't affect [`targetPokemonName`]!**

Opcionalmente, en tooltip o log secundario: "Ability: [`blockingAbilityName`] from [`blockingCardId`]". El mensaje principal visible al jugador es solo "It doesn't affect …!". Cuando el motor emite `STATUS_BLOCKED`, NO debe haber emitido `STATUS_APPLIED` en el mismo turno para el mismo target/status (son mutuamente excluyentes).

---

### Eventos del paso entre turnos

| Evento | Cuándo se emite | Datos incluidos | Visibilidad |
|---|---|---|---|
| `BETWEEN_TURNS_DAMAGE` | Cuando una condición especial causa daño entre turnos | `pokemonId`, `status` (`POISONED` / `BURNED`), `damageCounters`, `coinResult` (solo para BURNED) | Ambos jugadores |
| `COIN_FLIP` | Al lanzar moneda (Confusión, Quemado, Dormido, o ataque con coin flip) | `context` (razón del flip), `result` (`HEADS` / `TAILS`) | Ambos jugadores |

---

### Eventos de setup

| Evento | Cuándo se emite | Datos incluidos | Visibilidad |
|---|---|---|---|
| `MULLIGAN` | Cuando un jugador realiza un mulligan | `playerId`, `mulliganCount`, `extraCardsDrawn` (solo en último evento; Caso B de R-SETUP-04) | Ambos jugadores |
| `PRIZES_SET` | Al colocar las cartas de Premio | `playerId`, `count` (siempre 6, o 1 en Muerte Súbita) | Ambos jugadores |
| `SUDDEN_DEATH_START` | Al iniciar una Muerte Súbita | — | Ambos jugadores |

---

## Referencia rápida — Razones de fin de partida (`GAME_OVER.reason`)

| Valor | Condición que lo causó |
|---|---|
| `PRIZES` | Un jugador tomó todas sus cartas de Premio (R-WIN-01) |
| `DECK_EMPTY` | Un jugador no pudo robar al inicio de su turno (R-WIN-02) |
| `NO_POKEMON` | Un jugador no tiene Pokémon en juego (R-WIN-03) |
| `SUDDEN_DEATH` | Resolución de Muerte Súbita |
| `CONCEDED` | Un jugador concedió la partida (ver R-CONCEDE-01 en `07-edge-cases.md`) |
| `TIMEOUT` | Auto-concede tras 3 timeouts consecutivos (ver R-TIMEOUT-03 en `07-edge-cases.md`) |
| `DISCONNECTED` | Auto-concede tras superar la ventana de reconexión (ver R-RECONNECT-03 en `07-edge-cases.md`) |

---

## Eventos de casos borde y resiliencia

Eventos definidos en `07-edge-cases.md` y documentados en `PROTOCOLO_WEBSOCKET.md`:

| Evento | Cuándo se emite | Datos incluidos | Visibilidad |
|---|---|---|---|
| `GAME_CONCEDED` | Cuando un jugador concede explícitamente (R-CONCEDE-03) | `concedingPlayerId`, `winnerId` | Ambos jugadores |
| `TURN_TIMEOUT` | Cuando expiran los segundos de turno sin acción (R-TIMEOUT-02) | `playerId`, `consecutiveTimeouts` | Ambos jugadores |
| `RECONNECT_SUCCESS` | Cuando un jugador se reconecta exitosamente (R-RECONNECT-02) | `playerId`, `gameStateSnapshot` | Solo el jugador reconectado |
| `RECONNECT_FAILED` | Cuando vence la ventana de reconexión (R-RECONNECT-03) | `playerId`, `reason` | Ambos jugadores |

---

## Detalles de payload

Los detalles exactos de cada evento (formato JSON, tipos de campos, ejemplos) viven en [`../05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md`](../05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md). Este archivo lista qué eventos existen y sus reglas de emisión; el protocolo lista cómo se serializan en JSON.
