---
id: PASO_S03_04
equipo: A
bloque: 3
dep: [PASO_S03_01, PASO_S03_02, PASO_S03_03]
siguiente: PASO_S03_05
context_files:
  - 02-turn-flow.md
  - 04-win-conditions.md
  - 06-system-logic.md
  - GAME_ENGINE_DETALLES.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/game/engine/state/DrawPhaseState.java
  - api/src/test/java/com/codemon/game/DrawPhaseStateTest.java
---

# PASO 2.3 — DrawPhaseState
**Grupo legacy:** 2 — Motor de Juego | **Equipo:** A | **Dificultad:** 🟢 | **Tiempo:** 1–2 h

## Navegación
← **Anterior:** [PASO_S03_03](PASO_S03_03.md) — SetupState (mulligan, activo, banca, premios)
→ **Siguiente:** [PASO_S03_05](PASO_S03_05.md) — MainPhaseState (6 acciones del turno)

## Archivos a cargar junto a este
- `02-turn-flow.md` → sección "Fase 1 — Robar carta"
- `04-win-conditions.md` → sección "R-WIN-02 — Mazo vacío"
- `06-system-logic.md` → eventos TURN_START, CARD_DRAWN
- `GAME_ENGINE_DETALLES.md` → solo T-01 ("Chequeo de mazo vacío")

## Qué construye este paso
El inicio de cada turno: resetear flags, incrementar contadores de Pokémon en juego, verificar mazo vacío (antes del robo), robar 1 carta, transicionar a MainPhaseState.

## Pseudocódigo — orden exacto de onEnter()

```
1. turnNumber++
2. ctx.resetTurnFlags()    ← energyAttachedThisTurn=false, supporterPlayedThisTurn=false, etc.
3. Para todos los Pokémon del jugador activo:
     pokemon.turnsInPlay++
     pokemon.evolvedThisTurn = false
4. Emitir TURN_START (playerId: currentTurnPlayerId, turnNumber) → AMBOS jugadores

5. ─── VERIFICAR MAZO VACÍO ANTES DEL ROBO ───
   if (deck.isEmpty()) {
     victoryChecker.checkDeckEmpty(ctx);
     return;  ← no continuar
   }

6. card = currentPlayerBoard.deck.remove(0)
   currentPlayerBoard.hand.add(card)

7. Si ctx.isFirstTurn:
     ctx.firstTurnAttackBlocked = true

8. Emitir CARD_DRAWN (playerId, cardId) → SOLO al dueño (canal privado, isPrivate=true)

9. Transicionar a MainPhaseState
```

## La trampa del mazo vacío — R-WIN-02

```java
// MAL: roba primero, chequea después → IndexOutOfBoundsException
String card = deck.remove(0);
if (deck.isEmpty()) checkDeckEmpty();

// BIEN: chequear ANTES del robo
if (deck.isEmpty()) {
    victoryChecker.checkDeckEmpty(ctx);
    return;
}
String card = deck.remove(0);
```

```
R-WIN-02 dice: "si el jugador no puede robar al INICIO de su turno → pierde"

✅ Mazo vacío al INICIO del turno → derrota inmediata
❌ Mazo vaciado por efecto de carta DURANTE el turno → NO es derrota

Ejemplo: Professor Sycamore "descartar mano, robar 7"
  Si mazo tiene 3 cartas → robar 3 (las que hay), el turno continúa
  Al INICIO del SIGUIENTE turno → ahí sí sería derrota si sigue vacío
```

## Prompt listo para el agente

```
Implementá DrawPhaseState.java para el motor de juego Codemon TCG.

Reglas:
[pegá sección "Fase 1 — Robar carta" de 02-turn-flow.md]
[pegá sección "R-WIN-02" de 04-win-conditions.md]

Eventos a emitir:
[pegá eventos TURN_START y CARD_DRAWN de 06-system-logic.md]

Implementá en com.codemon.game.engine.state:

onEnter(ctx):
1. Incrementar ctx.turnNumber
2. Llamar ctx.resetTurnFlags()
3. Incrementar turnsInPlay de todos los InPlayPokemon del jugador activo
4. Setear evolvedThisTurn = false para todos los Pokémon del jugador activo
5. Emitir TURN_START (playerId, turnNumber) → ambos jugadores
6. ANTES de robar: si deck del jugador activo está vacío
   → llamar victoryConditionChecker.checkDeckEmpty(ctx) y retornar
7. Robar 1 carta del deck, moverla a hand
8. Si ctx.isFirstTurn: setear ctx.firstTurnAttackBlocked = true
9. Emitir CARD_DRAWN (playerId, cardId) → SOLO al dueño (isPrivate=true, privateTargetUserId=playerId)
10. Transicionar a MainPhaseState

IMPORTANTE: el chequeo de mazo vacío es ANTES del robo, no después.

TESTS - DrawPhaseStateTest.java:
- Al inicio del turno, deck disminuye en 1 y hand aumenta en 1
- CARD_DRAWN es evento privado (isPrivate=true, privateTargetUserId=playerId)
- Mazo vacío al inicio del turno → victoryChecker.checkDeckEmpty invocado, NO se intenta deck.remove(0)
- Mazo vaciado por efecto de carta durante el turno → NO llama checkDeckEmpty
- turnsInPlay de cada Pokémon del jugador activo incrementa en 1 al inicio de su turno
- evolvedThisTurn resetea a false al inicio de cada turno

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que modifica
```
api/src/main/java/com/codemon/game/engine/state/DrawPhaseState.java
api/src/test/java/com/codemon/game/DrawPhaseStateTest.java
```

## Errores comunes

- **Verificar el mazo DESPUÉS del robo**: causa `IndexOutOfBoundsException` o que la derrota se declare tarde — siempre verificar antes de `deck.remove(0)`
- **No resetear `evolvedThisTurn`**: un Pokémon que evolucionó ayer podría evolucionar hoy también, violando la regla de una evolución por turno
- **No incrementar `turnsInPlay`**: un Pokémon que lleva 2 turnos en juego aparece como `turnsInPlay=0`, bloqueando que evolucione
- **Emitir `CARD_DRAWN` a ambos jugadores**: el oponente vería qué carta robó — debe ser `isPrivate=true` con `privateTargetUserId=currentPlayerId`
- **Emitir `CARD_DRAWN` antes de verificar el mazo vacío**: si el mazo está vacío y se intenta emitir igual, el sistema queda en estado inconsistente

## Tests obligatorios

```java
test_draw_reduces_deck_by_one():
  Turno 2 empieza: deck.size() = X → después del robo: deck.size() = X-1

test_card_drawn_is_private():
  Emitir CARD_DRAWN → evento.isPrivate == true
  evento.privateTargetUserId == currentPlayerId

test_deck_empty_before_draw_loses():
  deck.size() == 0 al inicio del turno
  → victoryChecker.checkDeckEmpty() invocado
  → NO intentar deck.remove(0)

test_deck_empties_mid_turn_no_loss():
  Jugador usa Sycamore, deck tiene 3 cartas
  → roba 3, turno continúa, sin error, sin GAME_OVER

test_turns_in_play_increments():
  Básico con turnsInPlay = 0 al inicio del turno
  → turnsInPlay = 1 después del DrawPhase del dueño

test_evolved_this_turn_resets():
  Pokémon con evolvedThisTurn = true del turno anterior
  → evolvedThisTurn = false al inicio del siguiente turno
```

## Verificación

```bash
TOKEN="eyJ..."
# Después de END_TURN, el siguiente turno:
# PASS: deck del jugador activo bajó en 1 (deckSize decrementó)
# PASS: CARD_DRAWN llegó solo al dueño (verificar en dos ventanas WebSocket separadas)
# FAIL: CARD_DRAWN llega a ambos → revisar isPrivate=true en el evento
```

## Dependencias
PASO_S03_01 (GameContext, resetTurnFlags), PASO_S03_03 (SetupState, para que haya un juego activo).
