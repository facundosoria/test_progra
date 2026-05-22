---
id: PASO_S04_01
equipo: A
bloque: 4
dep: [PASO_S03_01, PASO_S03_05]
siguiente: PASO_S04_02
context_files:
  - 03-combat.md
  - GAME_ENGINE_DETALLES.md
  - GAME_ENGINE_DETALLES_PARTE2.md
  - PATRON_CARD_HANDLER.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/game/damage/DamageCalculator.java
  - api/src/main/java/com/codemon/game/effects/StatusEffectManager.java
  - api/src/main/java/com/codemon/game/engine/strategy/AttackEffectStrategy.java
  - api/src/main/java/com/codemon/game/engine/strategy/EffectStrategyResolver.java
  - api/src/main/java/com/codemon/game/engine/strategy/effects/PoisonEffectStrategy.java
  - api/src/main/java/com/codemon/game/engine/strategy/effects/BurnEffectStrategy.java
  - api/src/main/java/com/codemon/game/engine/strategy/effects/SleepEffectStrategy.java
  - api/src/main/java/com/codemon/game/engine/strategy/effects/ParalyzeEffectStrategy.java
  - api/src/main/java/com/codemon/game/engine/strategy/effects/ConfuseEffectStrategy.java
  - api/src/main/java/com/codemon/game/engine/strategy/effects/NoEffectStrategy.java
  - api/src/test/java/com/codemon/game/DamageCalculatorTest.java
  - api/src/test/java/com/codemon/game/StatusEffectManagerTest.java
---

# PASO 2.5 — DamageCalculator + StatusEffectManager
**Grupo legacy:** 2 — Motor de Juego | **Equipo:** A | **Dificultad:** 🔴 | **Tiempo:** 4–6 h

## Navegación
← **Anterior:** [PASO_S03_05](PASO_S03_05.md) — MainPhaseState (6 acciones del turno)
→ **Siguiente:** [PASO_S04_02](PASO_S04_02.md) — AttackPipeline (9 handlers de resolución de ataque)

## Archivos a cargar junto a este
- `03-combat.md` → secciones "Cálculo de daño" y "Condiciones Especiales"
- `GAME_ENGINE_DETALLES.md` → C-01 (daño directo), C-02 (orden del cálculo), C-05 (acumulación de condiciones)

## Qué construye este paso
Dos componentes testeables completamente aislados del resto del motor. `DamageCalculator` aplica la fórmula de daño con sus 6 pasos. `StatusEffectManager` aplica condiciones especiales y procesa los efectos entre turnos. Cobertura mínima requerida: ≥90%.

## DamageCalculator — Los 6 pasos en orden estricto

```
Paso 1: daño_base = parseDamage(attack.damage)
  "60"  → 60
  "60+" → 60  (el "+" indica modificador condicional, ignorar para el base)
  ""    → 0   (ataque sin daño, solo efecto)

Paso 1b: detectar si es daño DIRECTO
  Si attack.text contiene "put" Y "damage counter" → isDirect = true
  Si isDirect: colocar contadores directamente, SALTAR pasos 2-5

Paso 2: daño += bonus_del_atacante
  (efectos de Trainer cards o Energías especiales activos)
  Aplicar ANTES de weakness — este orden importa

Paso 3: Si defensor.weaknesses contiene el tipo del atacante:
  daño *= multiplicador (generalmente 2)
  Solo al Pokémon ACTIVO, NUNCA a Pokémon de Banca
  Si isDirect: SALTAR este paso

Paso 4: Si defensor.resistances contiene el tipo del atacante:
  daño -= valor (generalmente 20)
  Solo al Pokémon ACTIVO, NUNCA a Banca
  daño = Math.max(0, daño)  ← nunca negativo
  Si isDirect: SALTAR este paso

Paso 5: daño -= reduccion_del_defensor
  (efectos de Habilidades o Tools del defensor)
  Aplicar DESPUÉS de weakness/resistance
  daño = Math.max(0, daño)

Paso 6: resultado final
  daño = Math.max(0, daño)
  Si daño == 0: no agregar contadores (evitar eventos vacíos)
```

## StatusEffectManager — Tabla de acumulación

```
POISONED  → coexiste con TODO (BURNED, ASLEEP, PARALYZED, CONFUSED)
BURNED    → coexiste con TODO
ASLEEP    → REEMPLAZA CONFUSED y PARALYZED; coexiste con POISONED y BURNED
PARALYZED → REEMPLAZA CONFUSED y ASLEEP; coexiste con POISONED y BURNED
CONFUSED  → REEMPLAZA ASLEEP y PARALYZED; coexiste con POISONED y BURNED

Al aplicar ASLEEP, PARALYZED o CONFUSED:
  Remover SOLO las otras condiciones de rotación
  NO tocar POISONED ni BURNED
```

## Estrategias de efectos (Strategy pattern)

```java
PoisonEffectStrategy:   text.contains("Poisoned")    → aplicar al defensor
BurnEffectStrategy:     text.contains("Burned")       → aplicar al defensor
SleepEffectStrategy:    text.contains("Asleep")       → reemplaza CONFUSED y PARALYZED
ParalyzeEffectStrategy: text.contains("Paralyzed")    → reemplaza CONFUSED y ASLEEP
ConfuseEffectStrategy:  text.contains("Confused")     → reemplaza ASLEEP y PARALYZED
NoEffectStrategy:       fallback — canApply() siempre true, apply() no hace nada
```

## processBetweenTurns() — EndPhase lo llama

```
Para CADA jugador (player1 Y player2), si su Pokémon Activo existe:

1. POISONED: active.damage += 10
   Emitir BETWEEN_TURNS_DAMAGE (status: POISONED, damageCounters: 1)

2. BURNED: flip moneda
   Si TAILS: active.damage += 20
   Emitir BETWEEN_TURNS_DAMAGE (status: BURNED, damageCounters: 0/2, coinResult)
   EL MARCADOR BURNED PERMANECE SIEMPRE — no se elimina por la moneda

3. ASLEEP: flip moneda
   Si HEADS: remover ASLEEP
   Emitir STATUS_REMOVED (reason: WOKE_UP)

4. PARALYZED: si ctx.paralyzedOnTurn[instanceId] == ctx.turnNumber
   → remover PARALYZED
   Emitir STATUS_REMOVED (reason: PARALYSIS_EXPIRED)
```

## Prompt listo para el agente

```
Implementá DamageCalculator y StatusEffectManager para el motor de juego Codemon TCG.

Reglas oficiales (fuente de verdad):
[pegá las secciones de 03-combat.md indicadas]

Implementá en com.codemon.game:

1. damage/DamageCalculator.java (@Component)
   Método: int calculate(AttackRequest request)
   [Pegá el pseudocódigo de los 6 pasos de este archivo]

2. engine/strategy/AttackEffectStrategy.java (interfaz)
   - void apply(GameContext ctx, InPlayPokemon attacker, InPlayPokemon defender)
   - boolean canApply(Attack attack)

   Implementar en engine/strategy/effects/:
   [Pegá las 6 estrategias y sus condiciones de activación de este archivo]

3. engine/strategy/EffectStrategyResolver.java (@Component)
   Recibe List<AttackEffectStrategy> inyectada por Spring
   resolve(Attack attack): retorna la primera estrategia donde canApply() == true

4. effects/StatusEffectManager.java (@Component)
   processBetweenTurns(GameContext ctx):
   [Pegá el pseudocódigo de processBetweenTurns() de este archivo]
   Usar SecureRandom para los coin flips

TESTS - DamageCalculatorTest.java (cobertura ≥ 90%):
- base 60 → 60
- weakness x2 → 60*2 = 120
- resistance -20 → 60-20 = 40
- full pipeline (60+20)*2-20 = 140
- resultado nunca negativo → Math.max(0, 10-20) = 0
- daño directo no aplica weakness → 30 contadores = 30 aunque haya weakness
- daño a Banca nunca aplica weakness
- daño de Confusión es directo → 30 al propio Pokémon, sin weakness

TESTS - StatusEffectManagerTest.java (cobertura ≥ 90%):
- ASLEEP reemplaza CONFUSED
- PARALYZED reemplaza ASLEEP
- POISONED sobrevive cuando se aplica SLEEP
- BURNED sobrevive cuando se aplica PARALYZED
- BURNED HEADS → 0 daño adicional, marcador permanece
- BURNED TAILS → 20 daño adicional, marcador permanece
- ASLEEP HEADS → condición removida
- ASLEEP TAILS → condición permanece
- Parálisis se cura al final del turno del dueño

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea
```
api/src/main/java/com/codemon/game/damage/DamageCalculator.java
api/src/main/java/com/codemon/game/effects/StatusEffectManager.java
api/src/main/java/com/codemon/game/engine/strategy/AttackEffectStrategy.java
api/src/main/java/com/codemon/game/engine/strategy/EffectStrategyResolver.java
api/src/main/java/com/codemon/game/engine/strategy/effects/
  PoisonEffectStrategy.java
  BurnEffectStrategy.java
  SleepEffectStrategy.java
  ParalyzeEffectStrategy.java
  ConfuseEffectStrategy.java
  NoEffectStrategy.java
api/src/test/java/com/codemon/game/DamageCalculatorTest.java
api/src/test/java/com/codemon/game/StatusEffectManagerTest.java
```

## Errores comunes

- **Daño directo aplicando Weakness**: "put X damage counters" → saltar pasos 2-5 completamente
- **Orden incorrecto**: `(base + bonus) × weakness` ≠ `base × weakness + bonus`
- **Daño de Confusión aplicando Weakness propia**: los 30 contadores de Confusión son directos al propio Pokémon
- **POISONED eliminado al aplicar ASLEEP**: solo se eliminan ASLEEP/PARALYZED/CONFUSED entre sí
- **Quema cara elimina el marcador**: BURNED permanece SIEMPRE, independiente de la moneda

## Tests obligatorios (cobertura ≥ 90% requerida)

```java
// DamageCalculator
test_base_damage_60()              → 60
test_weakness_doubles()            → 60 × 2 = 120
test_resistance_subtracts()        → 60 - 20 = 40
test_full_pipeline()               → (60 + 20) × 2 - 20 = 140
test_result_never_negative()       → max(0, 10 - 20) = 0
test_direct_damage_no_weakness()   → 30 contadores = 30 (no × 2 aunque haya weakness)
test_bench_damage_no_weakness()    → daño a Banca nunca aplica Debilidad
test_confusion_damage_is_direct()  → 30 al propio Pokémon, sin Debilidad propia

// StatusEffectManager
test_poison_applied()
test_burn_applied()
test_sleep_replaces_confused()       → ASLEEP, no CONFUSED
test_paralyzed_replaces_asleep()     → PARALYZED, no ASLEEP
test_poison_survives_sleep()         → POISONED + ASLEEP coexisten
test_burn_survives_paralyzed()       → BURNED + PARALYZED coexisten
test_burn_marker_stays_on_heads()    → BURNED permanece aunque moneda salga cara
test_between_turns_poison_damage()   → +10 HP de daño
test_between_turns_burn_tails()      → +20 HP de daño
test_between_turns_burn_heads()      → 0 daño, marcador permanece
test_sleep_heads_wakes_up()
test_sleep_tails_stays_asleep()
test_paralysis_cures_after_owner_turn()
```

## Verificación

```bash
# Solo tests unitarios — no requiere servidor
./mvnw test -pl api -Dtest=DamageCalculatorTest,StatusEffectManagerTest
# PASS: todos los tests en verde, BUILD SUCCESS
# FAIL: cualquier test fallido → verificar orden de pasos (bonus ANTES de weakness)

# Reporte de cobertura
./mvnw test jacoco:report
# PASS: DamageCalculator ≥ 90%, StatusEffectManager ≥ 90% en target/site/jacoco/index.html
# FAIL: cobertura < 90% → agregar casos de test para condiciones de borde
```

## Dependencias
PASO_S03_01 (modelos InPlayPokemon, StatusCondition, GameContext), PASO_S03_05 (CardHandlerRegistry y Marker, que este paso usa).

## Nota importante — integraciones con Card Handler

**StatusEffectManager.applyStatus()** debe propagar al `CardHandlerRegistry` antes de aplicar:
```java
public void applyStatus(InPlayPokemon target, SpecialCondition condition, GameContext ctx) {
    ApplyStatusContext statusCtx = new ApplyStatusContext(target, condition);
    registry.getActiveHandlers(ctx.getBoard())
            .forEach(h -> h.onBeforeApplyStatus(statusCtx, ctx));
    if (statusCtx.isBlocked()) return;  // Slurpuff bloqueó
    target.addSpecialCondition(condition);
    // ...emitir STATUS_APPLIED...
}
```

**DamageCalculator** en este PASO no necesita saber de ignoreWeakness/ignoreResistance —
esos flags los lee `ApplyWeaknessHandler` y `ApplyResistanceHandler` del `AttackRequest`.
La calculadora en sí sigue recibiendo `(damage, attacker, defender)` y retorna el valor modificado.

**BetweenTurnsProcessor** (dentro de StatusEffectManager o EndPhaseState) DEBE usar los campos:
```java
// NO usar literales:
// active.addDamage(10);   ← WRONG
// active.addDamage(20);   ← WRONG

// USAR los campos del InPlayPokemon:
active.addDamage(active.getPoisonDamage());   // default 10, pero modificable
active.addDamage(active.getBurnDamage());     // default 20, pero modificable
```
Ver `GAME_ENGINE_DETALLES_PARTE2.md` sección DS-02 y SC-01 (Slurpuff).
