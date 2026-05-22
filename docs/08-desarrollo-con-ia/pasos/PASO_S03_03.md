---
id: PASO_S03_03
equipo: A
bloque: 3
dep: [PASO_S03_01, PASO_S02_01]
siguiente: PASO_S03_04
context_files:
  - 01-setup.md
  - 06-system-logic.md
  - GAME_ENGINE_DETALLES.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/game/engine/state/SetupState.java
  - api/src/test/java/com/codemon/game/SetupStateTest.java
---

# PASO 2.2 — SetupState
**Grupo legacy:** 2 — Motor de Juego | **Equipo:** A | **Dificultad:** 🔴 | **Tiempo:** 5–7 h

## Navegación
← **Anterior:** [PASO_S03_02](PASO_S03_02.md) — VictoryConditionChecker (condiciones de victoria y muerte súbita)
→ **Siguiente:** [PASO_S03_04](PASO_S03_04.md) — DrawPhaseState (inicio de turno y robo de carta)

## Archivos a cargar junto a este
- `01-setup.md` — fuente de verdad de las reglas del setup (LEER COMPLETO antes de codear)
- `06-system-logic.md` → eventos: MULLIGAN, PRIZES_SET, COIN_FLIP, GAME_START
- `GAME_ENGINE_DETALLES.md` → secciones S-01, S-02, S-03, S-04

## Qué construye este paso
Todo lo que ocurre antes del primer turno: barajar, robar mano inicial, mulligan (dos variantes), colocar Activo y Banca, tomar premios, revelar, coin flip. La partida pasa de `WAITING` a `ACTIVE`.

## Pseudocódigo — los 9 pasos en orden estricto

```
Paso 1 — Barajar:
  Collections.shuffle(deck, new SecureRandom())
  NO usar new Random() con semilla fija
  Trabajar sobre una COPIA de la lista, nunca la original

Paso 2 — Robar 7 cartas:
  Mover deck[0..6] → hand de cada jugador
  Emitir CARD_DRAWN (PRIVADO) a cada jugador por separado

Paso 3 — Mulligan:
  hasBasicPokemon(hand) es true solo si:
    supertype == "Pokémon"
    AND subtypes.contains("Basic")
    AND NOT subtypes.contains("Restored")   ← TRAMPA FRECUENTE
  (Pokemon con subtypes=["Basic","EX"] → SÍ es básico — Venusaur-EX lo es)
  (Pokemon con subtypes=["Restored"]   → NO es básico)
  (Pokemon con subtypes=["Stage 1"]    → NO es básico)

  CASO A (ninguno tiene básico):
    Ambos devuelven mano al mazo y barajan de nuevo
    Repiten desde paso 1 — NO incrementar mulliganCount

  CASO B (solo UNO no tiene básico):
    El que SÍ tiene: ya completó pasos 4, 5, 6
    El que NO tiene:
      mulliganCount = 0
      loop:
        mulliganCount++
        devolver mano al mazo y barajar
        robar 7 nuevas cartas
        si tiene básico → salir
      extraCards = mulliganCount - 1    ← NO es mulliganCount
      (mulliganCount=1 → extraCards=0, sin cartas extra al oponente)
      (mulliganCount=2 → extraCards=1)
      El oponente roba extraCards cartas del mazo
      Emitir MULLIGAN (playerId, mulliganCount) en cada iteración

Paso 4 — Colocar Activo:
  Esperar acción PLACE_ACTIVE de cada jugador (carta básica de la mano)

Paso 5 — Colocar Banca (opcional):
  Esperar 0-5 acciones PLACE_BENCH, luego CONFIRM_SETUP

Paso 6 — Premios:
  Premios DESPUÉS de robar la mano (NO antes):
    prizes = deck.subList(0, 6)
    deck   = deck.subList(6, deck.size())
  Invariante: deck.size() + hand.size() + prizes.size() == 60 SIEMPRE

Paso 7 — Revelar:
  Todos los InPlayPokemon pasan a visibles
  Emitir PRIZES_SET (count: 6) para cada jugador

Paso 8 — Coin flip:
  SecureRandom.nextBoolean()
  Emitir COIN_FLIP (context: "FIRST_TURN", result: "HEADS"/"TAILS")
  El ganador va primero (simplificación TPI: siempre el ganador elige ir primero)

Paso 9 — Registrar primer turno:
  ctx.isFirstTurn = true
  ctx.firstTurnAttackBlocked = true
  Transicionar a DrawPhaseState
  Emitir GAME_START
```

## Prompt listo para el agente

```
Implementá SetupState.java para el motor de juego Codemon TCG.

Reglas del setup (fuente de verdad):
[pegá 01-setup.md completo]

Eventos WebSocket a emitir:
[pegá la sección "Eventos de setup" de 06-system-logic.md]

Implementá los 9 pasos descritos a continuación.
Ya tengo GameContext.java implementado con todos los campos del PASO 2.0.

Implementá la clase SetupState en com.codemon.game.engine.state que implementa GameState.

PASO 1 — Verificar y barajar:
- Verificar 60 cartas en cada mazo (lanzar IllegalStateException si no)
- Barajar con Collections.shuffle(deck, new SecureRandom())

PASO 2 — Robar 7 cartas:
- Mover primeras 7 cartas del deck a hand de cada jugador
- Emitir CARD_DRAWN (privado a cada jugador por separado)

PASO 3 — Mulligan:
Implementar hasBasicPokemon(List<String> hand, Map<String, Card> cardLookup):
  supertype == "Pokémon" AND subtypes.contains("Basic") AND NOT subtypes.contains("Restored")

CASO A (ninguno tiene básico):
  Ambos devuelven mano al mazo y barajan de nuevo, NO incrementar mulliganCount

CASO B (solo uno sin básico):
  El que SÍ tiene ya completó pasos 4-6
  El que NO tiene: loop de mulligan, contando mulliganCount
  extraCards = mulliganCount - 1 (si mulliganCount == 1: sin cartas extra)
  Emitir MULLIGAN (playerId, mulliganCount) en cada iteración

PASOS 4 y 5 — Colocar Activo y Banca:
  Esperar acciones PLACE_ACTIVE y PLACE_BENCH del jugador, luego CONFIRM_SETUP

PASO 6 — Premios (DESPUÉS de robar la mano):
  prizes = primeras 6 cartas del deck
  Verificar: deck.size() + hand.size() + prizes.size() == 60

PASOS 7-9 — Revelar, coin flip, registrar primer turno:
  Emitir PRIZES_SET, COIN_FLIP, GAME_START
  ctx.isFirstTurn = true, ctx.firstTurnAttackBlocked = true
  Transicionar a DrawPhaseState

TESTS obligatorios - SetupStateTest.java:
- Setup completo con ambos con básico → estado ACTIVE, prizesCount=6 para cada uno
- deckSize == 60 - handSize - 6 para cada jugador
- Mulligan Caso A: ambos sin básico → loop hasta que ambos tengan básico
- Mulligan Caso B con 1 mulligan → oponente no roba cartas extra
- Mulligan Caso B con 2 mulligans → oponente roba 1 carta extra
- player2.hand es null en getState() para player1

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que modifica
```
api/src/main/java/com/codemon/game/engine/state/SetupState.java
api/src/test/java/com/codemon/game/SetupStateTest.java
```

## Errores comunes

| Error | Causa | Solución |
|---|---|---|
| Restaurados aceptados como básicos | No verificar `!subtypes.contains("Restored")` | Agregar la verificación en `hasBasicPokemon()` |
| Bucle infinito en mulligan | Mazo sin ningún Básico | Agregar `if (++limit > 30) throw new IllegalStateException()` |
| Cartas extra = mulliganCount | Contar el primer mulligan | `extraCards = mulliganCount - 1` |
| Premios antes que la mano | Orden incorrecto de operaciones | Secuencia: draw 7 → mulligan → place active/bench → take prizes |
| deck+hand+prizes ≠ 60 | Error en la secuencia | Agregar assertion al final del setup |
| Mano del rival visible en GAME_START | DTO no sanitizado | `sanitizeForPlayer()` antes de emitir — player2.hand debe ser null para player1 |

## Tests obligatorios

```java
test_setup_happy_path():
  Ambos tienen básico → estado ACTIVE
  player1.handCount entre 1 y 7
  player1.prizesCount == 6
  player1.deckSize == 60 - hand.size() - 6
  player1.active != null
  player2.hand == null (en el DTO del player1)

test_mulligan_caso_a_ambos_sin_basico():
  Fabricar mazos sin Básicos → ambos hacen mulligan
  Al terminar: ambos tienen Básico

test_mulligan_caso_b_un_mulligan():
  player2 hace 1 mulligan → extraCards = 0
  player1 no roba cartas extra

test_mulligan_caso_b_dos_mulligans():
  player2 hace 2 mulligans → extraCards = 1
  player1 roba 1 carta extra

test_setup_deck_consistency():
  Después del setup: deck.size() + hand.size() + prizes.size() == 60
  Para AMBOS jugadores
```

## Verificación

```bash
TOKEN="eyJ..."

curl -X POST http://localhost:8088/games \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"deckId":1,"matchType":"PVE","botDifficulty":"EASY"}'
# PASS: {"gameId":1,"status":"ACTIVE"}
# FAIL: 500 → revisar SetupState.onEnter() y validación del mazo

curl http://localhost:8088/games/1/state -H "Authorization: Bearer $TOKEN"
# PASS — todos deben cumplirse:
# player1.handCount: entre 1 y 7 (puede ser menor si hubo mulligan)
# player1.prizesCount: 6
# player1.deckSize: 60 - handCount - 6
# player1.active: {cardId, hp, damage:0}
# player1.hand: [...cartas visibles para el dueño]
# player2.hand: null (no visible para player1) ← CRÍTICO
# player2.deck: null (nunca visible)
# player1.prizes: null (nunca visible, solo prizesCount)
# FAIL en cualquier campo → revisar sanitizeForPlayer() en GameEngine.getState()
```

## Dependencias
PASO_S03_01 (GameContext, InPlayPokemon, PlayerBoard), PASO_S02_01 (DeckValidationService).
