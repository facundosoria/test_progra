---
id: PASO_S03_05
equipo: A
bloque: 3
dep: [PASO_S03_01, PASO_S03_04]
siguiente: PASO_S04_01
context_files:
  - 02-turn-flow.md
  - 06-system-logic.md
  - GAME_ENGINE_DETALLES.md
  - GAME_ENGINE_DETALLES_PARTE2.md
  - PATRON_CARD_HANDLER.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/game/engine/state/MainPhaseState.java
  - api/src/main/java/com/codemon/game/engine/cards/CardHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/NoOpCardHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/CardHandlerRegistry.java
  - api/src/main/java/com/codemon/game/engine/cards/context/PlayItemContext.java
  - api/src/main/java/com/codemon/game/engine/cards/context/PlaySupporterContext.java
  - api/src/main/java/com/codemon/game/engine/cards/context/AttackValidationContext.java
  - api/src/main/java/com/codemon/game/engine/cards/context/ApplyStatusContext.java
  - api/src/main/java/com/codemon/game/engine/cards/context/EndTurnContext.java
  - api/src/main/java/com/codemon/game/engine/cards/context/KnockOutContext.java
  - api/src/main/java/com/codemon/game/engine/cards/context/AbilityContext.java
  - api/src/test/java/com/codemon/game/MainPhaseStateTest.java
  # Nota: Marker.java se crea en PASO_S03_01 (model/Marker.java) para respetar el orden de compilación
---

# PASO 2.4 — MainPhaseState (las 6 acciones)
**Grupo legacy:** 2 — Motor de Juego | **Equipo:** A | **Dificultad:** 🔴 | **Tiempo:** 8–10 h

## Navegación
← **Anterior:** [PASO_S03_04](PASO_S03_04.md) — DrawPhaseState (robo de carta e inicio de turno)
→ **Siguiente:** [PASO_S04_01](PASO_S04_01.md) — DamageCalculator + StatusEffectManager

## Archivos a cargar junto a este
- `02-turn-flow.md` → sección "Fase 2 — Acciones del turno" completa
- `06-system-logic.md` → eventos: POKEMON_PLAYED, POKEMON_EVOLVED, ENERGY_ATTACHED, TRAINER_PLAYED, ABILITY_USED, RETREAT, STATUS_REMOVED
- `GAME_ENGINE_DETALLES.md` → T-02, T-03, T-04, T-05

## Qué construye este paso
Todas las acciones que el jugador puede hacer durante su turno: colocar básico, evolucionar, adjuntar energía, jugar Trainer (Item/Supporter/Stadium/Tool), retirarse, usar habilidad, declarar ataque, terminar turno.

## Router de acciones — handleAction()

```java
switch (action.getType()) {
    case PLAY_BASIC_POKEMON  → handlePlayBasic(ctx, action)
    case EVOLVE_POKEMON      → handleEvolve(ctx, action)
    case ATTACH_ENERGY       → handleAttachEnergy(ctx, action)
    case PLAY_ITEM           → handlePlayItem(ctx, action)
    case PLAY_SUPPORTER      → handlePlaySupporter(ctx, action)
    case PLAY_STADIUM        → handlePlayStadium(ctx, action)
    case PLAY_TOOL           → handlePlayTool(ctx, action)
    case RETREAT             → handleRetreat(ctx, action)
    case USE_ABILITY         → handleUseAbility(ctx, action)
    case DECLARE_ATTACK      → ctx.transitionTo(new AttackPhaseState(action))
    case END_TURN            → ctx.transitionTo(new EndPhaseState())
    default                  → return error("Acción inválida en esta fase")
}
```

## Pseudocódigo de cada acción — trampas incluidas

### PLAY_BASIC_POKEMON
```
Validar:
  carta.supertype == "Pokémon"
  carta.subtypes.contains("Basic")
  NOT carta.subtypes.contains("Restored")
  board.bench.size() < 5
Ejecutar:
  crear InPlayPokemon(instanceId=UUID, damage=0, turnsInPlay=0, statusConditions={})
  agregar a bench, remover de hand
  emitir POKEMON_PLAYED (cardId, zone:"BENCH")
```

### EVOLVE_POKEMON — T-02
```
Validar:
  evolutionCard.supertype == "Pokémon"
  NOT evolutionCard.subtypes.contains("Basic")
  targetPokemon.cardId == evolutionCard.evolvesFrom (campo de la carta)
  targetPokemon.turnsInPlay >= 1          ← NO si fue jugado este turno
  NOT targetPokemon.evolvedThisTurn       ← NO dos veces en el mismo turno
Ejecutar:
  targetPokemon.cardId = evolutionCard.id
  targetPokemon.evolvedThisTurn = true
  targetPokemon.statusConditions.clear()  ← CURA TODAS las condiciones
  // targetPokemon.damage → NO cambia (el daño acumulado permanece)
  Si evolutionCard.subtypes.contains("MEGA"):  ← T-03
    ctx.transitionTo(new EndPhaseState())  ← turno termina INMEDIATAMENTE
    return
  emitir POKEMON_EVOLVED
  emitir STATUS_REMOVED por cada condición curada
```

### ATTACH_ENERGY
```
Validar:
  NOT ctx.energyAttachedThisTurn
  carta.supertype == "Energy"
  targetPokemon en active o bench del jugador
Ejecutar:
  Si Double Colorless Energy (xy1-130):
    targetPokemon.attachedEnergies.add(carta.id)
    targetPokemon.attachedEnergies.add(carta.id)  // dos Colorless de una carta
  Sino:
    targetPokemon.attachedEnergies.add(carta.id)
  ctx.energyAttachedThisTurn = true
  emitir ENERGY_ATTACHED
```

### PLAY_ITEM
```
Sin límite por turno
carta va al discardPile del jugador
Efectos mínimos para XY1:
  Potion:       active.damage = Math.max(0, active.damage - 30)
  Switch:       cambiar activo por banca, cura condiciones del que se mueve
  (resto → loguear "Efecto no implementado" y descartar)
emitir TRAINER_PLAYED (trainerType:"ITEM")
```

### PLAY_SUPPORTER
```
Validar:
  NOT ctx.supporterPlayedThisTurn
Ejecutar:
  ctx.supporterPlayedThisTurn = true
  carta va al discardPile
  Efectos:
    Professor Sycamore: descartar mano entera, robar 7
      (si mazo < 7, robar lo que haya, NO es derrota)
    Shauna: barajar mano en mazo, robar 5
    (resto → "Efecto no implementado" y descartar)
  emitir TRAINER_PLAYED (trainerType:"SUPPORTER")
```

### PLAY_STADIUM — T-05
```
Validar:
  Si hay Stadium activo con el MISMO nombre → error "Ya está en juego"
Ejecutar:
  Si hay Stadium diferente activo:
    irá al discardPile del DUEÑO ORIGINAL (ctx.board.activeStadiumOwnerId)
    NO del jugador que lo reemplaza
  ctx.board.activeStadium = stadiumCard.id
  ctx.board.activeStadiumOwnerId = currentPlayerId
  emitir TRAINER_PLAYED (trainerType:"STADIUM")
```

### RETREAT — T-04
```
Validar:
  NOT ctx.retreatedThisTurn
  NOT active.statusConditions.contains(ASLEEP)
  NOT active.statusConditions.contains(PARALYZED)
  board.bench.size() > 0
  active.attachedEnergies.size() >= active.card.convertedRetreatCost
Ejecutar:
  Descartar exactamente retreatCost energías (elegidas por el jugador)
  active.statusConditions.clear()  ← cura TODAS las condiciones
  // active.damage → NO cambia
  // active.attachedTool → NO se toca (permanece)
  mover active a bench
  mover el pokemon elegido de bench a active
  ctx.retreatedThisTurn = true
  emitir RETREAT
  emitir STATUS_REMOVED por cada condición curada
```

## Prompt listo para el agente

```
Implementá MainPhaseState.java para el motor de juego Codemon TCG.
Esta es la fase donde el jugador puede hacer acciones antes de atacar.

Reglas detalladas de cada acción:
[pegá 02-turn-flow.md sección "Fase 2" completa]

Eventos a emitir:
[pegá los eventos correspondientes de 06-system-logic.md]

Implementá handleAction(ctx, action) con el router de acciones y los handlers descritos a continuación:

[Pegá el pseudocódigo de cada acción de este archivo]

TESTS por acción:
- PlayBasic: banca llena (5 pokémon) → error | Stage 1 directo → error | múltiples básicos mismo turno → OK
- Evolve: pokemon jugado este turno (turnsInPlay=0) → error
- Evolve: ya evolucionó este turno → error
- Evolve MEGA: el turno termina automáticamente después
- Evolve: daño acumulado permanece, statusConditions se limpian
- AttachEnergy: segunda energía mismo turno → error
- AttachEnergy: Double Colorless agrega 2 energías
- Retreat: dormido → error | paralizado → error | segunda retirada → error
- Retreat: cura condiciones, NO el daño, Tool permanece
- Supporter: segundo supporter → error
- Stadium mismo nombre → error
- Stadium diferente: stadium viejo va al descarte del DUEÑO ORIGINAL

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que modifica
```
api/src/main/java/com/codemon/game/engine/state/MainPhaseState.java
api/src/test/java/com/codemon/game/MainPhaseStateTest.java
```

## Errores comunes

| Acción | Error común |
|---|---|
| PLAY_BASIC | Aceptar Stage 1 directo | Verificar `subtypes.contains("Basic")` |
| EVOLVE | No verificar `turnsInPlay >= 1` | `turnsInPlay >= 1` obligatorio |
| EVOLVE | Curar el daño (no debe) | Solo limpiar `statusConditions`, `damage` NO se toca |
| EVOLVE MEGA | No terminar el turno inmediatamente | `transitionTo(EndPhaseState)` y `return` después de evolucionar |
| ATTACH_ENERGY | Permitir segunda energía sin flag | Verificar `ctx.energyAttachedThisTurn` antes de procesar |
| PLAY_STADIUM | Reemplaza mismo nombre | Verificar nombre antes de reemplazar — mismo nombre es error |
| PLAY_STADIUM | Stadium viejo va al descarte equivocado | Usar `ctx.board.activeStadiumOwnerId` para mandarlo al dueño original |
| RETREAT | Curar el daño (no debe) | Solo limpiar `statusConditions`, `damage` NO se toca |
| RETREAT | Remover el Tool | `attachedTool` NO se toca, permanece en el Pokémon |

## Tests obligatorios

```java
// PlayBasic
test_stage1_rejected_as_basic()
test_bench_full_5_pokemon_rejected()
test_multiple_basics_same_turn_allowed()

// Evolve
test_cannot_evolve_pokemon_played_this_turn()   // turnsInPlay == 0
test_cannot_evolve_twice_same_turn()            // evolvedThisTurn
test_evolution_clears_status_keeps_damage()     // damage permanece, statusConditions limpiadas
test_mega_evolution_ends_turn()                 // transición a EndPhase inmediata
test_wrong_evolution_chain_rejected()           // evolvesFrom mismatch

// AttachEnergy
test_second_energy_same_turn_rejected()
test_double_colorless_adds_two_energies()

// Retreat
test_asleep_blocks_retreat()
test_paralyzed_blocks_retreat()
test_retreat_clears_status_keeps_damage()
test_retreat_keeps_tool()
test_second_retreat_rejected()
test_insufficient_energy_blocks_retreat()

// Stadium
test_same_stadium_name_blocked()
test_different_stadium_replaces_and_old_goes_to_original_owner_discard()

// Supporter
test_second_supporter_rejected()
```

## Verificación

```bash
TOKEN="eyJ..."
# Adjuntar energía → éxito
curl -X POST http://localhost:8088/games/1/action \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"type":"ATTACH_ENERGY","cardId":"xy1-132","targetPokemonId":"uuid-001"}'
# PASS: {"success":true}
# FAIL: {"success":false} → revisar validación energyAttachedThisTurn en handleAttachEnergy()

# Segunda energía → error
curl -X POST http://localhost:8088/games/1/action \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"type":"ATTACH_ENERGY","cardId":"xy1-131","targetPokemonId":"uuid-001"}'
# PASS: {"success":false,"error":"Ya adjuntaste una Energía este turno"}
# FAIL: {"success":true} → flag energyAttachedThisTurn no se setea a true
```

## Dependencias
PASO_S03_01 (GameContext, flags de turno), PASO_S03_04 (DrawPhaseState para que exista MainPhase después del robo).

## Nota importante — Card Handler Registry

Este PASO también crea el `CardHandlerRegistry` y la interfaz `CardHandler` (ver `PATRON_CARD_HANDLER.md`).
Son necesarios para que `MainPhaseState` pueda propagar hooks antes de ejecutar cada acción:

```java
// Antes de ejecutar PLAY_ITEM:
PlayItemContext ctx = new PlayItemContext(player, action);
registry.getActiveHandlers(board).forEach(h -> h.onBeforePlayItem(ctx, gameCtx));
// Si algún handler lanzó GameActionException → la acción es rechazada con ese mensaje

// Antes de ejecutar PLAY_SUPPORTER:
PlaySupporterContext sCtx = new PlaySupporterContext(player, action);
registry.getActiveHandlers(board).forEach(h -> h.onBeforePlaySupporter(sCtx, gameCtx));

// Antes de transicionar a AttackPhaseState:
AttackValidationContext aCtx = new AttackValidationContext(player, action);
registry.getActiveHandlers(board).forEach(h -> h.onBeforeAttackDeclared(aCtx, gameCtx));

// Antes de ejecutar USE_ABILITY:
AbilityContext abCtx = new AbilityContext(player, action);
registry.getActiveHandlers(board).forEach(h -> h.onBeforeUseAbility(abCtx, gameCtx));
```

También en este PASO se crea la clase `Marker` (usada por `InPlayPokemon` y `PlayerBoard`):
- Ver `GAME_ENGINE_DETALLES_PARTE2.md` sección M-01 para la estructura completa.
- Asegurar serialización Jackson: sin `@Transient`, con `@JsonInclude(NON_EMPTY)`.
- Inicializar siempre en constructor (nunca null).

## Checklist de salida del PASO

```
[ ] CardHandler interface incluye onBeforePlayItem, onBeforePlaySupporter, onBeforeAttackDeclared
[ ] CardHandler interface incluye onBeforeUseAbility(AbilityContext, GameContext)
[ ] CardHandler interface incluye onBeforeApplyStatus, onEndTurn, onKnockedOut, onPokemonEntersPlay
[ ] CardHandler interface incluye onBeforeWeaknessCalculation, onBeforeDamageApplied, onAfterDamageApplied
[ ] AbilityContext.java existe en game/engine/cards/context/ con campos PlayerBoard player + TrainerAction action
[ ] NoOpCardHandler singleton con todos los hooks vacíos (default de la interfaz)
[ ] CardHandlerRegistry detecta @Component CardHandler vía constructor (List<CardHandler>)
[ ] CardHandlerRegistry.getActiveHandlers(board) retorna List ordenada (atacante → defensor) — no Set
[ ] MainPhaseState propaga onBeforePlayItem, onBeforePlaySupporter, onBeforeUseAbility, onBeforeAttackDeclared
[ ] Marker.java en game/engine/model/ — pares (name, sourceCardId), inicializado en constructor, no @Transient
```
