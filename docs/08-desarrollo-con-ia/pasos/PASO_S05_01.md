---
id: PASO_S05_01
equipo: A
bloque: 5
dep: [PASO_S04_01, PASO_S04_02, PASO_S03_02]
siguiente: PASO_S05_02
context_files:
  - 02-turn-flow.md
  - 03-combat.md
  - 06-system-logic.md
  - GAME_ENGINE_DETALLES.md
  - GAME_ENGINE_DETALLES_PARTE2.md
  - PATRON_CARD_HANDLER.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/game/engine/state/EndPhaseState.java
  - api/src/test/java/com/codemon/game/EndPhaseStateTest.java
---

# PASO 2.7 — EndPhaseState (paso entre turnos)
**Grupo legacy:** 2 — Motor de Juego | **Equipo:** A | **Dificultad:** 🟡 | **Tiempo:** 3–4 h

## Navegación
← **Anterior:** [PASO_S04_02](PASO_S04_02.md) — AttackPipeline con 9 handlers
→ **Siguiente:** [PASO_S05_02](PASO_S05_02.md) — Bot EASY (agente de PVE)

## Archivos a cargar junto a este
- `02-turn-flow.md` → sección "Paso entre turnos"
- `03-combat.md` → secciones POISONED, BURNED, ASLEEP, PARALYZED
- `06-system-logic.md` → eventos: BETWEEN_TURNS_DAMAGE, COIN_FLIP, STATUS_REMOVED
- `GAME_ENGINE_DETALLES.md` → C-05, C-06

## Qué construye este paso
El paso entre turnos: aplica efectos de condiciones especiales (veneno, quema, sueño, parálisis), verifica KOs causados por ellas, y pasa el turno al oponente.

## Pseudocódigo — onEnter() en orden estricto (NO cambiar el orden)

```
Para CADA jugador (player1 Y player2), si su Pokémon Activo existe:

1. POISONED:
   active.damage += 10
   Emitir BETWEEN_TURNS_DAMAGE (status: POISONED, damageCounters: 1) → ambos

2. BURNED:
   flip = SecureRandom.nextBoolean()
   Emitir COIN_FLIP (context: "BURN_CHECK", result: flip) → ambos
   Si TAILS:
     active.damage += 20
     Emitir BETWEEN_TURNS_DAMAGE (damageCounters: 2, coinResult: TAILS)
   Si HEADS:
     Emitir BETWEEN_TURNS_DAMAGE (damageCounters: 0, coinResult: HEADS)
   // EL MARCADOR BURNED NO SE ELIMINA EN NINGÚN CASO

3. ASLEEP:
   flip = SecureRandom.nextBoolean()
   Emitir COIN_FLIP (context: "SLEEP_CHECK", result: flip) → ambos
   Si HEADS:
     active.statusConditions.remove(ASLEEP)
     Emitir STATUS_REMOVED (status: ASLEEP, reason: WOKE_UP) → ambos
   Si TAILS:
     sigue dormido, no hacer nada más

4. PARALYZED:
   paralyzedTurn = ctx.paralyzedOnTurn.get(active.instanceId)
   Si paralyzedTurn != null && paralyzedTurn == ctx.turnNumber:
     active.statusConditions.remove(PARALYZED)
     ctx.paralyzedOnTurn.remove(active.instanceId)
     Emitir STATUS_REMOVED (status: PARALYZED, reason: PARALYSIS_EXPIRED) → ambos

5. Verificar KOs por daño de condiciones:
   Para CADA Pokémon Activo de AMBOS jugadores:
   Si pokemon.damage >= pokemon.card.hp:
     ejecutar proceso de KO completo (igual que CheckKnockoutHandler)
     Si hay victoria → return (no continuar)

6. Cambiar jugador activo:
   ctx.isFirstTurn = false
   ctx.currentTurnPlayerId = ctx.getOpponentId(ctx.currentTurnPlayerId)
   Transicionar a DrawPhaseState
```

## Las 2 trampas más frecuentes

```java
// TRAMPA 1: BURNED cara elimina el marcador — MAL
if (burnResult == HEADS) {
    active.getStatusConditions().remove(BURNED);  // ← INCORRECTO
}
// BIEN: el marcador BURNED NUNCA se elimina por la moneda

// TRAMPA 2: Parálisis curada en turno del oponente
// MAL: curar siempre en EndPhase
active.getStatusConditions().remove(PARALYZED);  // ← INCORRECTO

// BIEN: solo curar si el Pokémon fue paralizado en el turno ACTUAL del dueño
Integer paralyzedTurn = ctx.getParalyzedOnTurn().get(active.getInstanceId());
if (paralyzedTurn != null && paralyzedTurn.equals(ctx.getTurnNumber())) {
    active.getStatusConditions().remove(PARALYZED);
}
```

## Prompt listo para el agente

```
Implementá EndPhaseState.java para el motor de juego Codemon TCG.

Reglas del paso entre turnos (fuente de verdad):
[pegá sección "Paso entre turnos" de 02-turn-flow.md]
[pegá las 4 secciones de condiciones especiales de 03-combat.md]

Eventos a emitir:
[pegá BETWEEN_TURNS_DAMAGE, COIN_FLIP, STATUS_REMOVED de 06-system-logic.md]

Implementá onEnter(ctx) con el pseudocódigo siguiente (el orden es ESTRICTO):
[Pegá el pseudocódigo completo de este archivo]

TESTS - EndPhaseStateTest.java:
- Veneno aplica 1 contador (10 HP de daño) entre turnos
- Quema CARA: 0 daño adicional, marcador BURNED permanece
- Quema CRUZ: 2 contadores (20 HP de daño), marcador BURNED permanece
- Dormido CARA: condición ASLEEP removida
- Dormido CRUZ: condición ASLEEP permanece
- Paralizado: se cura automáticamente al final del turno en que fue aplicado
- NO se cura en el turno del oponente
- KO por veneno entre turnos: premio tomado, victoria verificada
- Procesamiento ocurre para AMBOS jugadores, no solo el activo
- El orden Veneno→Quema→Dormido→Paralizado es estricto

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que modifica
```
api/src/main/java/com/codemon/game/engine/state/EndPhaseState.java
api/src/test/java/com/codemon/game/EndPhaseStateTest.java
```

## Errores comunes

- **Solo procesar el jugador activo**: ambos jugadores pueden tener condiciones activas simultáneamente
- **Eliminar BURNED al salir cara**: BURNED permanece SIEMPRE (el Pokémon nunca se "cura" de quema por la moneda)
- **Parálisis curada en turno del oponente**: solo se cura en EndPhase del turno del DUEÑO del Pokémon
- **KO por condición sin premios**: el proceso de KO del entre turnos también da premios y puede ganar la partida
- **Orden alterado**: si Quema aplica antes de Veneno en una implementación, cambia quién podría quedar KO primero

## Verificación

```bash
# Partida con Pokémon envenenado:
# PASS: después de pasar el turno → damage aumentó en 10
# FAIL: damage no cambia → EndPhaseState no procesa POISONED

# Pokémon con BURNED, moneda HEADS:
# PASS: damage sin cambio, BURNED sigue en statusConditions
# FAIL: BURNED desaparece → no eliminar marcador cuando sale cara

# Verificar en los logs de WebSocket:
# PASS: COIN_FLIP event llega al cliente con context:"BURN_CHECK"
# PASS: STATUS_REMOVED llega con reason:"WOKE_UP" o "PARALYSIS_EXPIRED" cuando corresponde
# FAIL: eventos no llegan → revisar publishPendingEvents() en GameEngine
```

## Dependencias
PASO_S04_01 (StatusEffectManager para la lógica de condiciones), PASO_S04_02 (CheckKnockoutHandler para el proceso de KO), PASO_S03_02 (VictoryConditionChecker).

## Nota importante — propagación de onEndTurn al CardHandlerRegistry

`EndPhaseState.onEnter()` debe propagar el hook `onEndTurn` a todos los card handlers
**ANTES** de cambiar el jugador activo. Este es el mecanismo que limpia los markers de
efectos de turno siguiente:

```java
@Override
public void onEnter(GameContext ctx) {
    PlayerBoard currentPlayer = ctx.getCurrentPlayer();

    // 1. Curar Paralizado (regla base)
    currentPlayer.getActive().removeSpecialCondition(SpecialCondition.PARALYZED);

    // 2. Propagar onEndTurn a los handlers — limpieza de markers de "próximo turno"
    EndTurnContext endCtx = new EndTurnContext(currentPlayer);
    registry.getActiveHandlers(ctx.getBoard())
            .forEach(h -> h.onEndTurn(endCtx, ctx));
    // Los handlers como KakunaHandler limpian CLEAR_MARKER del board del oponente acá

    // 3. Condiciones especiales entre turnos (Poison, Burn, Sleep — EXISTENTE)
    processBetweenTurnsConditions(ctx);

    // 4. Verificar KOs por condiciones
    checkKoByConditions(ctx);

    // 5. Cambiar jugador activo
    ctx.switchActivePlayer();
    ctx.transitionTo(new DrawPhaseState());
}
```

Ver `GAME_ENGINE_DETALLES_PARTE2.md` secciones M-02 y M-03 para el comportamiento exacto
de la limpieza de markers y los tests que lo verifican.
