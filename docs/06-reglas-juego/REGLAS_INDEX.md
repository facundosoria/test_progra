# REGLAS_INDEX.md
# Índice de Reglas del Juego — Codemon TCG

Este documento es el punto de entrada para implementar el motor de juego. Los 6 archivos de reglas son la **fuente de verdad** para toda la lógica de gameplay. Cuando una IA implemente el `GameEngine`, debe tener estos archivos como contexto.

---

## Qué hace cada documento

| Archivo | Resumen | Clase Java principal |
|---------|---------|---------------------|
| `01-setup.md` | Todo lo que pasa antes del primer turno: barajado, mano inicial, mulligan (con penalización al oponente), colocar Activo/Banca, cartas de Premio, coin flip | `SetupState.java` |
| `02-turn-flow.md` | Las 3 fases de un turno (robar, acciones, atacar) + el paso entre turnos con condiciones especiales | `DrawPhaseState`, `MainPhaseState`, `AttackPhaseState`, `EndPhaseState` |
| `03-combat.md` | Pipeline de ataque de 9 pasos, cálculo de daño en 6 pasos (base→debilidad→resistencia), 5 condiciones especiales, proceso de KO | `AttackPipeline.java`, `DamageCalculator.java`, `StatusEffectManager.java` |
| `04-win-conditions.md` | Las 3 condiciones de victoria y Muerte Súbita (1 Premio por jugador) | `VictoryConditionChecker.java` |
| `05-deck-validation.md` | 7 reglas de validación de mazos, mensajes de error específicos, todas las validaciones juntas | `DeckValidationService.java` |
| `06-system-logic.md` | Todos los eventos WebSocket: cuándo emitirlos, qué datos incluyen, qué es público vs privado | `GameEventPublisher.java` |

---

## Cómo se relacionan entre sí

```
PARTIDA EMPIEZA
       ↓
  01-setup.md        ← barajado, mulligan, premios, coin flip
       ↓
  Loop de turnos:
       ↓
  02-turn-flow.md    ← robar, acciones, atacar, paso entre turnos
       |
       ├─ Al atacar → 03-combat.md   ← pipeline, daño, condiciones, KO
       |                   ↓
       └─ Tras KO  → 04-win-conditions.md  ← ¿terminó la partida?
       |
       └─ Entre turnos → 03-combat.md (condiciones especiales)
                              ↓
                         04-win-conditions.md (¿KO por veneno/quema?)

DECK BUILDER (antes de jugar):
  05-deck-validation.md   ← validar mazo antes de guardar y antes de jugar

SIEMPRE (en paralelo):
  06-system-logic.md      ← qué evento emitir en cada momento
```

---

## Reglas específicas que NO estaban en REGLAS_JUEGO.md original

Estos puntos son más precisos en los nuevos documentos:

### Del 01-setup.md
- Mulligan Caso A (ambos sin básico): reinicio completo sin penalización
- Mulligan Caso B (uno sin básico): el oponente roba 1 carta extra **por cada mulligan adicional** (no el primero)
- Las cartas extra del oponente pueden colocarse en Banca si son Básicos (opcional)
- Los Pokémon Restaurados NO cuentan como Básicos para el mulligan

### Del 02-turn-flow.md
- Al evolucionar: se curan condiciones especiales pero NO el daño
- Mega Evolución: el turno termina inmediatamente después de colocarla
- Retirar Pokémon: mueve las Energías sobrantes a la Banca con el Pokémon
- Paso entre turnos tiene orden fijo: Envenenado → Quemado → Dormido → Paralizado → verificar KOs
- Si un efecto de carta pide robar más cartas de las que hay, se roban las disponibles (no es derrota)

### Del 03-combat.md
- Daño directo ("poner X contadores") NO aplica Debilidad/Resistencia
- Confusión: los 3 contadores de daño propio son contadores directos (sin Debilidad/Resistencia)
- Debilidad/Resistencia SOLO al Pokémon Activo, nunca a Pokémon de Banca
- Quema: el marcador permanece aunque la moneda salga Cara
- Envenenado + Quemado pueden coexistir con Dormido/Confuso/Paralizado simultáneamente
- Existen 6 ataques en XY1 cuyo `text` declara que ignoran Debilidad/Resistencia (R-IGN-01 en 03-combat.md): Greninja Mist Slash (ignora W+R+efectos defensor), Rhyperior Rock Wrecker (W+R), Dugtrio Rock Tumble / Inkay Puncture / Malamar Puncture / Aegislash Buster Swing (solo R)
- Existen habilidades pasivas que protegen Pokémon propios contra condiciones especiales (R-STATUS-IMMUNE, R-ABILITY-05); el motor emite `STATUS_BLOCKED` en lugar de `STATUS_APPLIED`. UI muestra "It doesn't affect [name]!"
- El `onEndTurn` se propaga ANTES del orden de paso entre turnos (Envenenado → Quemado → Dormido → Paralizado → KOs); ver paso 0 en 02-turn-flow.md

### Del 04-win-conditions.md
- Muerte Súbita: nueva partida completa con solo 1 Premio por jugador
- Si el mazo se vacía por efecto de carta durante el turno → NO es derrota (solo al inicio del turno)
- Si un jugador cumple más condiciones simultáneamente que el rival → gana directamente (sin Muerte Súbita)

### Del 05-deck-validation.md
- Devolver TODOS los errores juntos, no solo el primero
- Delta Species (δ) NO es parte del nombre para el conteo de copias
- "Charizard-EX" y "Charizard" son nombres distintos (el sufijo EX es parte del nombre)
- Pokémon Tools: máx 4 del mismo nombre en el mazo (la restricción de 1 por Pokémon es de gameplay, no de mazo)

### Del 06-system-logic.md
- `CARD_DRAWN` se emite SOLO al dueño de la carta (privado)
- `PRIZE_TAKEN` incluye cuántas quedan (`prizesRemaining`)
- `STATUS_REMOVED` incluye la razón (`RETREATED`, `EVOLVED`, `WOKE_UP`, `PARALYSIS_EXPIRED`)
- `GAME_OVER` incluye el motivo (`PRIZES`, `DECK_EMPTY`, `NO_POKEMON`, `SUDDEN_DEATH`)
- `BETWEEN_TURNS_DAMAGE` incluye el resultado de la moneda solo para BURNED

---

## Cómo usar estos archivos con una IA

Cuando le pidás a una IA que implemente el motor de juego, incluí los archivos en este orden como contexto:

```
CONTEXTO PARA LA IA:
1. PATRONES_DISENO.md          ← estructura de clases y patrones (incluye Patrón 7)
2. PATRON_CARD_HANDLER.md      ← prerequisito para cartas con lógica especial
3. 01-setup.md                 ← lógica de setup
4. 02-turn-flow.md             ← lógica de turno
5. 03-combat.md                ← lógica de combate
6. 04-win-conditions.md        ← condiciones de victoria
7. 05-deck-validation.md       ← validación de mazos
8. 06-system-logic.md          ← eventos WebSocket

PARA IMPLEMENTAR CARTAS INDIVIDUALES (después de lo anterior):
9. GAME_ENGINE_DETALLES.md     ← comportamiento exacto y edge cases
10. GAME_ENGINE_DETALLES_PARTE2.md ← gaps identificados: markers, ignoreW/R, bloqueos, etc.

PROMPT:
"Implementá [SetupState.java / DeckValidationService.java / AttackPipeline.java / etc.]
siguiendo estrictamente las reglas del sistema DEBE / NO DEBE de los documentos de contexto."
```

---

## Orden de implementación recomendado del motor

```
1. DeckValidationService      ← 05-deck-validation.md (más simple, testeable solo)
2. SetupState                 ← 01-setup.md
3. TurnManager + fases        ← 02-turn-flow.md
4. DamageCalculator           ← 03-combat.md (pasos 1-6)
5. StatusEffectManager        ← 03-combat.md (condiciones especiales)
6. AttackPipeline + handlers  ← 03-combat.md + PATRONES_DISENO.md
7. CardHandlerRegistry        ← PATRON_CARD_HANDLER.md (prerequisito para cartas)
8. VictoryConditionChecker    ← 04-win-conditions.md
9. GameEventPublisher         ← 06-system-logic.md
10. GameEngine (Facade)       ← une todo con PATRONES_DISENO.md
11. Cartas XY1 individuales   ← PASO_S04_03 (26 handlers) — depende de PASO_S03_05, PASO_S04_01, PASO_S04_02, PASO_S05_01. Paralelo a PASO_S05_02 (Bot EASY). Detalle por carta en GAME_ENGINE_DETALLES_PARTE2.md
```

---

## Componentes del motor y sus tests requeridos (RNF-03)

| Componente | Tests de integración obligatorios |
|------------|----------------------------------|
| `SetupState` | mulligan ambos, mulligan uno, cartas extra oponente |
| `DeckValidationService` | todos los mensajes de error, todos los errores juntos |
| `DamageCalculator` | debilidad ×2, resistencia -20, daño directo sin modificadores, ignoreWeakness, ignoreResistance |
| `StatusEffectManager` | acumulación, reemplazo, paso entre turnos orden fijo, Slurpuff bloqueando |
| `AttackPipeline` | flujo completo de ataque, confusión, dormido/paralizado bloqueando, Greninja ignorando W/R |
| `CardHandlerRegistry` | handlers detectados, lifecycle correcto, serialización de markers en snapshot |
| `CardHandlersXY1` | 26 handlers individuales: cada uno con tests del hook que implementa (Greninja ignora W/R, Slurpuff bloquea status y emite STATUS_BLOCKED, Furfrou reduce -20 post-W/R, Trevenant lanza excepción al jugar Item, Kakuna marker un turno, Arbok bloquea USE_ABILITY del target, etc.) |
| `VictoryConditionChecker` | 3 condiciones, simultáneo → Muerte Súbita |
| `GameEventPublisher` | eventos privados vs públicos, datos correctos por evento |
