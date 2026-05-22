# EPIC-04 — Motor de Juego

## 1. Resumen

- **Valor de negocio:** los jugadores pueden jugar partidas TCG con reglas correctas (setup, turnos, combate, condiciones, victoria). Es la columna vertebral del producto: sin motor no hay juego.
- **Roles involucrados:** Jugador autenticado, Bot, Sistema.
- **Sprints donde se completa:** S3 (setup + turnos sin combate), S4 (combate completo), S5 (end phase + bot easy + websocket).
- **Equipos:** A (todo el motor; los 2 devs deben trabajar juntos en TT-04-06 AttackPipeline).

## 2. Historias de Usuario

### HU-04-01 — Iniciar una partida con setup correcto
**Como** jugador, **quiero** que la partida arranque con barajado, mano de 7 cartas, mulligan resuelto, premios y coin flip, **para** jugar bajo reglas justas.

**Story Points:** 8

**Criterios de Aceptacion:**
- AC1: Barajado con `SecureRandom` (no `new Random()` con seed fija).
- AC2: Hand inicial de 7 cartas para cada jugador.
- AC3: Mulligan Caso A (ambos sin Basico): ambos rebarajan, mulliganCount no incrementa, sin cartas extra al rival.
- AC4: Mulligan Caso B (uno sin Basico): el rival roba `mulliganCount - 1` cartas extra.
- AC5: 6 premios DESPUES de robar la mano inicial.
- AC6: Invariante: `deck.size() + hand.size() + prizes.size() == 60` para ambos.
- AC7: Coin flip determina el primer jugador.
- AC8: `getState()` devuelve `player2.hand=null` para player1 (privacidad).

**RNF:**
- RNF-Calidad: cobertura `SetupState` ≥ 90%.
- RNF-Determinismo: barajado seedeable solo en tests via inyeccion.

**Dependencias:** HU-03-03 (mazos validos).
**Sprint:** S3.

---

### HU-04-02 — Robar carta al inicio de mi turno
**Como** jugador, **quiero** robar una carta al inicio de cada turno mio, **para** mantener opciones.

**Story Points:** 2

**Criterios de Aceptacion:**
- AC1: `DrawPhaseState.onEnter()` verifica mazo vacio ANTES del robo (R-WIN-02).
- AC2: Si el mazo tiene >= 1 carta, mueve la primera a `hand`.
- AC3: `turnsInPlay++` para todos mis Pokemon en juego.
- AC4: `evolvedThisTurn=false`.
- AC5: Evento `CARD_DRAWN` enviado solo al dueno (privado).

**Sprint:** S3.

---

### HU-04-03 — Jugar Pokemon Basico al banco
**Como** jugador, **quiero** poner Pokemon Basicos en mi banco, **para** tener reemplazos cuando hagan KO mi activo.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: `PLAY_BASIC_POKEMON` rechaza Stage 1 directo.
- AC2: Banco lleno (5 Pokemon) → 422 `BENCH_FULL`.
- AC3: Carta movida de `hand` a `bench`, asignada con `instanceId` UUID.
- AC4: Evento `POKEMON_PLAYED` publico.

**Sprint:** S3.

---

### HU-04-04 — Adjuntar energia a un Pokemon
**Como** jugador, **quiero** pegarle energias a mis Pokemon, **para** poder atacar.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: Maximo 1 energia por turno (flag `energyAttachedThisTurn`).
- AC2: Double Colorless Energy = 2 energias Colorless de 1 sola carta.
- AC3: Segunda energia mismo turno → 422 `ENERGY_ALREADY_ATTACHED`.
- AC4: Evento `ENERGY_ATTACHED` publico.

**Sprint:** S3.

---

### HU-04-05 — Evolucionar un Pokemon
**Como** jugador, **quiero** evolucionar mis Pokemon, **para** aumentar su HP y dano.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: Solo evolucionables si `turnsInPlay >= 1` y `!evolvedThisTurn`.
- AC2: Evolucion cura condiciones especiales pero el dano permanece.
- AC3: Mega Evolucion termina el turno inmediatamente (`transitionTo(EndPhaseState)`).
- AC4: Tools y energias adjuntas se conservan.

**Sprint:** S3.

---

### HU-04-06 — Atacar al Pokemon activo enemigo
**Como** jugador, **quiero** declarar un ataque y resolverlo correctamente, **para** hacer KO al rival y tomar premios.

**Story Points:** 21

**Criterios de Aceptacion:**
- AC1: AttackPipeline ejecuta los 9 handlers en orden estricto: Validate → CalcBase → AttackerFX → Weakness → Resistance → DefenderFX → DealDamage → ExecuteEffect → CheckKO.
- AC2: Daño = `(base + bonus_atacante) * weakness - resistance - reduccion_defensor`, minimo 0.
- AC3: Daño directo (`put X damage counters`) omite weakness/resistance.
- AC4: Daño a banca nunca aplica weakness/resistance.
- AC5: Energias requeridas: tipos especificos antes de Colorless.
- AC6: Confusion: 30 dano directo a si mismo (sin weakness propia).
- AC7: Primer turno del jugador 1: ataque bloqueado (`firstTurnAttackBlocked`).

**RNF:**
- RNF-Calidad: cobertura `AttackPipeline` ≥ 90%, `DamageCalculator` ≥ 90%, `StatusEffectManager` ≥ 90%.
- RNF-Performance: resolucion < 50 ms.

**Sprint:** S4.

---

### HU-04-07 — Retirar mi Pokemon activo
**Como** jugador, **quiero** mover el activo al banco pagando energias, **para** salvar a un Pokemon herido.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: Bloqueado si activo esta ASLEEP o PARALYZED.
- AC2: Maximo 1 retirada por turno (flag `retreatedThisTurn`).
- AC3: Retirar cura condiciones; el dano NO cambia; Tool permanece.
- AC4: Energias gastadas van al descarte segun retreatCost.

**Sprint:** S4.

---

### HU-04-08 — Tomar premios al hacer KO
**Como** jugador, **quiero** tomar premios al noquear al rival, **para** acercarme a la victoria.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: KO normal → 1 premio; KO de EX o MEGA → 2 premios.
- AC2: El premio se mueve a la mano del que hizo KO (no al mazo del KO'd).
- AC3: Si no puede reemplazar el activo (banca vacia), se dispara R-WIN-03.
- AC4: Carta KO + adjuntos (energia, tools) van al descarte del dueno KO'd.

**Sprint:** S4.

---

### HU-04-09 — Ganar la partida
**Como** jugador, **quiero** que el sistema declare ganador segun las reglas TCG, **para** que el resultado sea oficial.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: R-WIN-01 (premios): ultimo premio tomado → `GAME_OVER reason=PRIZES`.
- AC2: R-WIN-02 (mazo vacio): mazo vacio al inicio del turno → `GAME_OVER reason=DECK_EMPTY`.
- AC3: R-WIN-03 (sin Pokemon): KO sin reemplazo → `GAME_OVER reason=NO_POKEMON`.
- AC4: Ambos cumplen condicion → `SUDDEN_DEATH_START` (no empate); muerte subita = 1 premio.
- AC5: ELO/ranking solo se actualiza en `matchType=QUEUE` (PVE y ROOM no impactan ranking).
- AC6: `wins/losses` actualizados; `REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard` ejecutado.
- AC7: Reward de coins: en `matchType=QUEUE` o `ROOM`, ganador recibe `+50` coins y perdedor `+10` coins via `walletService.creditCoins(reason=MATCH_REWARD, ref_table='games', ref_id=gameId)`. PvE no genera reward (delta=0, sin fila en wallet_transactions). Las dos credit-operations forman parte de la misma transaccion que cierra la partida; si fallan, la transicion a FINISHED rollbackea.

**RNF:**
- RNF-Calidad: cobertura `VictoryConditionChecker` ≥ 90%.
- RNF-Auditoria: cada partida QUEUE/ROOM finalizada debe producir exactamente 2 filas en `wallet_transactions` (una por jugador) con `ref_id=gameId`.

**Sprint:** S5.

## 3. Tareas Tecnicas

| ID | Tarea | Origen | Equipo | SP | Sprint |
|---|---|---|---|---|---|
| TT-04-00 | `GameContext` + `GameState` + State Machine andamiaje | PASO_S03_01 | A | 3 | S3 |
| TT-04-01 | `VictoryConditionChecker` (R-WIN-01..04) | PASO_S03_02 | A | 3 | S3 |
| TT-04-02 | `SetupState` (barajado, mano, mulligan, premios) | PASO_S03_03 | A | 8 | S3 |
| TT-04-03 | `DrawPhaseState` | PASO_S03_04 | A | 2 | S3 |
| TT-04-04 | `MainPhaseState` (6 acciones de turno) | PASO_S03_05 | A | 13 | S3 |
| TT-04-05 | `DamageCalculator` + `StatusEffectManager` | PASO_S04_01 | A | 8 | S4 |
| TT-04-06 | `AttackPipeline` (9 handlers) — los 2 devs A juntos, NO dividir | PASO_S04_02 | A | 21 | S4 |
| TT-04-07 | `EndPhaseState` (efectos entre turnos) | PASO_S05_01 | A | 5 | S5 |
| TT-04-08 | `GameEngine` Facade + WebSocket STOMP | PASO_S05_03 | A | 5 | S5 |
| TT-04-09 | `VictoryConditionChecker.declareWinner()` invoca `walletService.creditCoins(reason=MATCH_REWARD)` para ambos jugadores en partidas QUEUE/ROOM (skip en PVE) | PASO_S05_03 | A | 2 | S5 |

## 4. Contratos involucrados

- REST: `POST /games`, `GET /games/{id}/state`, `POST /games/{id}/action`, `GET /games/{id}/events`.
- STOMP: `/topic/game/{gameId}` (publicos), `/user/queue/game/{gameId}` (privados: `CARD_DRAWN`, hand updates), eventos: `TURN_START`, `ATTACK`, `DAMAGE`, `KO`, `PRIZE_TAKEN`, `STATUS_APPLIED`, `GAME_OVER`, `SUDDEN_DEATH_START`.
- Detalle: [PROTOCOLO_WEBSOCKET.md](../../../../docs/05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md).

## 5. Definition of Done especifico

- Cobertura ≥ 90% en `DamageCalculator`, `StatusEffectManager`, `AttackPipeline`, `VictoryConditionChecker`, `RuleValidator`.
- `getState()` sanitiza: `hand` rival = null, `deck` ambos = null (solo `deckSize`), `prizes` ambos = null (solo `prizesCount`).
- Snapshot de `game_state_snapshots` guardado asincronicamente tras cada `ATTACK`, `KO`, `PRIZE_TAKEN`, `STATUS_APPLIED`.
- Test E2E: partida PvE completa termina en `GAME_OVER` sin 500.
- Hereda [DOD.md](../../04_proceso/DOD.md) global.
