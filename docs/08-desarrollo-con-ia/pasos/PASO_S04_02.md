---
id: PASO_S04_02
equipo: A
bloque: 4
dep: [PASO_S03_01, PASO_S03_02, PASO_S03_05, PASO_S04_01]
siguiente: PASO_S04_03
context_files:
  - 03-combat.md
  - PATRONES_DISENO.md
  - PATRON_CARD_HANDLER.md
  - GAME_ENGINE_DETALLES.md
  - GAME_ENGINE_DETALLES_PARTE2.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/game/engine/pipeline/AttackHandler.java
  - api/src/main/java/com/codemon/game/engine/pipeline/AttackPipeline.java
  - api/src/main/java/com/codemon/game/engine/pipeline/AttackRequest.java
  - api/src/main/java/com/codemon/game/engine/pipeline/AttackResult.java
  - api/src/main/java/com/codemon/game/engine/pipeline/handlers/ValidateAttackHandler.java
  - api/src/main/java/com/codemon/game/engine/pipeline/handlers/CalculateBaseDamageHandler.java
  - api/src/main/java/com/codemon/game/engine/pipeline/handlers/ApplyAttackerEffectsHandler.java
  - api/src/main/java/com/codemon/game/engine/pipeline/handlers/ApplyWeaknessHandler.java
  - api/src/main/java/com/codemon/game/engine/pipeline/handlers/ApplyResistanceHandler.java
  - api/src/main/java/com/codemon/game/engine/pipeline/handlers/ApplyDefenderEffectsHandler.java
  - api/src/main/java/com/codemon/game/engine/pipeline/handlers/DealDamageHandler.java
  - api/src/main/java/com/codemon/game/engine/pipeline/handlers/ExecuteAttackEffectHandler.java
  - api/src/main/java/com/codemon/game/engine/pipeline/handlers/CardEffectsPostDamageHandler.java
  - api/src/main/java/com/codemon/game/engine/pipeline/handlers/CheckKnockoutHandler.java
  - api/src/main/java/com/codemon/game/engine/state/AttackPhaseState.java
  - api/src/test/java/com/codemon/game/AttackPipelineTest.java
---

# PASO 2.6 — AttackPipeline (9 handlers)
**Grupo legacy:** 2 — Motor de Juego | **Equipo:** A | **Dificultad:** 🔥 | **Tiempo:** 12–15 h

## Navegación
← **Anterior:** [PASO_S04_01](PASO_S04_01.md) — DamageCalculator + StatusEffectManager testeados
→ **Siguiente:** [PASO_S05_01](PASO_S05_01.md) — EndPhaseState (efectos entre turnos y cambio de jugador)

## Archivos a cargar junto a este
- `03-combat.md` → sección "Pipeline de ataque" completa
- `PATRONES_DISENO.md` → sección "3. CHAIN OF RESPONSIBILITY" completa
- `GAME_ENGINE_DETALLES.md` → C-01, C-02, C-03, C-04, C-05 (CRÍTICO — leer antes de implementar)

## Qué construye este paso
La cadena completa de resolución de un ataque: desde la validación hasta el KO y los premios. Es el paso más largo del proyecto. Los 9 handlers deben ejecutarse en orden estricto.

## Los 9 handlers — orden estricto

```
Handler 1: ValidateAttackHandler
  ¿Pokémon dormido? → error
  ¿Pokémon paralizado? → error
  ¿Es el primer turno del jugador inicial? → error (ctx.firstTurnAttackBlocked)
  ¿Tiene las Energías necesarias? → hasRequiredEnergies()
  ¿Está Confuso?
    Cruz → 30 contadores DIRECTOS al propio Pokémon, el ataque FALLA, END_TURN
    Cara → continuar al siguiente handler

Handler 2: CalculateBaseDamageHandler
  parseDamage(attack.damage) → baseDamage
  Si attack.text contiene "damage counter" → isDirect = true
  Guardar isDirect y baseDamage en AttackRequest

Handler 3: ApplyAttackerEffectsHandler
  Si isDirect → proceed() y retornar sin modificar
  Aplicar bonuses del atacante (stub para el TPI)

Handler 4: ApplyWeaknessHandler
  Si isDirect → proceed() y retornar
  Verificar tipos del atacante vs weaknesses del defensor
  Si coincide → daño *= multiplicador (generalmente 2)

Handler 5: ApplyResistanceHandler
  Si isDirect → proceed() y retornar
  Verificar tipos del atacante vs resistances del defensor
  Si coincide → daño -= valor (generalmente 20), mínimo 0

Handler 6: ApplyDefenderEffectsHandler
  Si isDirect → proceed() y retornar
  Aplicar reducciones del defensor (stub para el TPI)

Handler 7: DealDamageHandler
  defender.damage += currentDamage
  Emitir DAMAGE_DEALT (baseDamage, weaknessApplied, resistanceApplied, finalDamage) → AMBOS

Handler 8: ExecuteAttackEffectHandler
  Si attack.text vacío → proceed() y retornar
  strategy = effectStrategyResolver.resolve(attack)
  strategy.apply(ctx, attacker, defender)

Handler 9: CheckKnockoutHandler
  Si defender.damage < defender.card.hp → proceed() (no hay KO)

  // KO detectado
  ownerId = ctx.getOwnerOf(defender)
  rivalBoard = ctx.getOpponentBoard(ownerId)
  prizesToTake = isPokemonEXorMEGA(defender) ? 2 : 1

  // 1. Descartar Pokémon + adjuntos (al discardPile del DUEÑO)
  ownerBoard.discardPile.addAll(defender.attachedEnergies)
  if (defender.attachedTool != null) ownerBoard.discardPile.add(defender.attachedTool)
  ownerBoard.discardPile.add(defender.cardId)
  ownerBoard.active = null  (o remover de bench)

  // 2. El RIVAL toma premios de SUS PROPIOS premios
  for (int i = 0; i < prizesToTake; i++) {
      String prize = rivalBoard.prizes.remove(0);
      rivalBoard.hand.add(prize);
      rivalBoard.prizesCount--;
  }
  emitir POKEMON_KO (pokemonId, ownerId, prizesToTake) → ambos
  emitir PRIZE_TAKEN (playerId: rival, count: prizesToTake, prizesRemaining) → ambos

  // 3. Verificar victoria inmediata
  if (rivalBoard.prizesCount == 0) {
      victoryChecker.checkPrizesWon(ctx);
      return;  ← la partida terminó
  }

  // 4. Si el KO fue al Activo
  if (defender era el active del ownerBoard) {
      if (ownerBoard.bench.isEmpty()) {
          victoryChecker.checkNoPokemon(ctx, ownerId);
          return;
      } else {
          ctx.awaitingReplacement = true;
          ctx.awaitingReplacementPlayerId = ownerId;
          emitir evento solicitando nuevo Activo
      }
  }
```

## Algoritmo hasRequiredEnergies() — C-03 Colorless

```java
boolean hasRequiredEnergies(InPlayPokemon pokemon, List<String> cost) {
    List<String> available = new ArrayList<>();
    for (String energyCardId : pokemon.attachedEnergies) {
        Card energy = cardLookup.get(energyCardId);
        if (isDoubleColorless(energy)) {
            available.add("Colorless");
            available.add("Colorless");  // dos Colorless de UNA carta
        } else {
            available.add(energy.getTypes().get(0));  // "Grass", "Fire", etc.
        }
    }

    // PASO 1: satisfacer tipos ESPECÍFICOS primero
    for (String required : cost) {
        if (!required.equals("Colorless")) {
            if (!available.remove(required)) return false;  // no hay ese tipo
        }
    }

    // PASO 2: satisfacer Colorless con lo que sobre
    long colorlessCost = cost.stream().filter(r -> r.equals("Colorless")).count();
    return available.size() >= colorlessCost;
}
```

## AttackPhaseState — Pre-pipeline (lo que pasa antes de los 9 handlers)

```java
onEnter(ctx, attackAction):
1. Verificar dormido → error "No puede atacar, está Dormido"
2. Verificar paralizado → error "No puede atacar, está Paralizado"
3. Verificar primer turno → error "El primer jugador no puede atacar en su primer turno"
4. Verificar Confusión (ANTES de validar energías):
   Si attacker.hasStatus(CONFUSED):
     flip = SecureRandom.nextBoolean()
     emitir COIN_FLIP (context:"CONFUSION_CHECK", result:flip)
     Si TAILS:
       attacker.damage += 30  ← 30 DIRECTOS al propio Pokémon
       emitir DAMAGE_DEALT (finalDamage:30, direct:true, target:attacker)
       checkKnockout(ctx, attacker)  ← puede hacerse KO a sí mismo
       ctx.transitionTo(new EndPhaseState())
       return
5. Encontrar el ataque elegido (action.attackName)
6. Verificar energías: hasRequiredEnergies(attacker, attack.cost)
7. Ejecutar pipeline: attackPipeline.process(req)
8. ctx.transitionTo(new EndPhaseState())
```

## Prompt listo para el agente

```
Implementá el AttackPipeline para el motor de juego Codemon TCG.
Patrón Chain of Responsibility.

Reglas del pipeline (fuente de verdad):
[pegá sección "Pipeline de ataque" de 03-combat.md]

Patrón a implementar:
[pegá sección "3. CHAIN OF RESPONSIBILITY" de PATRONES_DISENO.md]

Implementá en com.codemon.game.engine.pipeline:

1. AttackRequest.java → gameContext, attacker, defender, attack
2. AttackResult.java → baseDamage, currentDamage, isDirect, weaknessApplied, resistanceApplied
3. AttackHandler.java (abstracto) → setNext(handler), proceed(request), handle(request)
4. AttackPipeline.java (@Component) → @PostConstruct buildChain(), process(AttackRequest)

Los 9 handlers en pipeline/handlers/:
[Pegá los pseudocódigos de los 9 handlers de este archivo]

5. AttackPhaseState.java (completo):
[Pegá el pseudocódigo del pre-pipeline de este archivo]

Algoritmo hasRequiredEnergies():
[Pegá el algoritmo Colorless de este archivo]

TESTS - AttackPipelineTest.java:
- Ataque mientras dormido → error
- Ataque mientras paralizado → error
- Primer turno del jugador inicial → error
- Energías insuficientes → error
- Colorless acepta cualquier tipo de energía
- Tipo específico no satisfecho por Colorless → error
- 60 de daño aplicados correctamente
- Weakness x2 aplicada
- Resistance -20 aplicada
- Pipeline completo (bonus+weakness+resistance)
- Daño directo NO aplica weakness
- Daño de Confusión: 30 directos al propio Pokémon, sin weakness
- KO descarta energías y tool
- KO: el RIVAL toma premios de SUS PROPIOS premios
- KO Pokémon normal → 1 premio
- KO Pokémon EX → 2 premios
- Último premio tomado → GAME_OVER
- KO activo sin Banca → GAME_OVER
- KO activo con Banca → awaitingReplacement = true

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea
```
api/src/main/java/com/codemon/game/engine/pipeline/
  AttackHandler.java (abstracto)
  AttackPipeline.java
  AttackRequest.java
  AttackResult.java
  handlers/ValidateAttackHandler.java
  handlers/CalculateBaseDamageHandler.java
  handlers/ApplyAttackerEffectsHandler.java
  handlers/ApplyWeaknessHandler.java
  handlers/ApplyResistanceHandler.java
  handlers/ApplyDefenderEffectsHandler.java
  handlers/DealDamageHandler.java
  handlers/ExecuteAttackEffectHandler.java
  handlers/CheckKnockoutHandler.java
api/src/main/java/com/codemon/game/engine/state/AttackPhaseState.java
api/src/test/java/com/codemon/game/AttackPipelineTest.java
```

## Errores comunes

| Handler | Error común | Consecuencia | Solución |
|---|---|---|---|
| ValidateAttack | No verificar primer turno del jugador inicial | El jugador 1 puede atacar en su primer turno | Verificar `ctx.firstTurnAttackBlocked` |
| CalculateBase | `"60+"` parseado como `0` | Daño siempre 0 para ataques con bonus condicional | Parsear solo la parte numérica: `"60+".replaceAll("[^0-9]", "")` |
| ApplyWeakness | Aplicado a daño en Banca | Regla violada: weakness solo aplica al Activo | Verificar si el target es el Activo antes de aplicar |
| ApplyWeakness | Aplicado a daño directo (`isDirect`) | Regla violada | `if (isDirect) { proceed(); return; }` |
| ApplyResistance | Resultado puede quedar negativo | Error de lógica: el daño mínimo es 0 | `daño = Math.max(0, daño)` después de restar |
| DealDamage | Emitir DAMAGE_DEALT como evento privado | El oponente no ve el daño recibido | DAMAGE_DEALT es evento PÚBLICO → ambos jugadores |
| ExecuteEffect | Condición aplicada al atacante en vez del defensor | Bug crítico: el atacante se venena a sí mismo | La estrategia recibe `defender` como parámetro |
| CheckKO | El dueño del KO toma premios en vez del rival | Premios van al jugador equivocado | `rivalBoard = ctx.getOpponentBoard(ownerId)` — el rival saca de SUS premios |
| CheckKO | EX y MEGA no dan 2 premios | Regla violada | `prizesToTake = isPokemonEXorMEGA(defender) ? 2 : 1` |
| CheckKO | Victoria no verificada tras último premio | La partida no termina cuando debería | `if (rivalBoard.prizesCount == 0) { victoryChecker.checkPrizesWon(ctx); return; }` |
| Chain (cualquier handler) | Handler no llama `proceed()` | La cadena se corta, handlers posteriores no ejecutan | Cada handler que no detiene la cadena DEBE llamar `proceed()` al final |

## Verificación

```bash
./mvnw test -Dtest=AttackPipelineTest
# PASS: todos en verde, cobertura ≥90%
# FAIL: test de KO → revisar que el RIVAL toma premios de SUS PROPIOS premios, no del KO'd

# Manual: partida PVE
TOKEN="eyJ..."
curl -X POST http://localhost:8088/games/1/action \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"type":"DECLARE_ATTACK","attackName":"Frog Hop"}'
# PASS: {"success":true,"events":[{"type":"DAMAGE_DEALT","finalDamage":40,...},{"type":"TURN_START",...}]}
# FAIL: {"success":false,"error":"No puede atacar"} → revisar hasRequiredEnergies() y firstTurnAttackBlocked
```

## Dependencias
PASO_S03_05 (MainPhaseState, CardHandlerRegistry, Marker), PASO_S04_01 (DamageCalculator, StatusEffectManager, EffectStrategyResolver), PASO_S03_02 (VictoryConditionChecker — inyectado en CheckKnockoutHandler).

## Nota importante — handlers de Card Handler en el pipeline

Este PASO implementa los 3 handlers nuevos que conectan el `CardHandlerRegistry` al pipeline:

**`ApplyAttackerEffectsHandler`** (entre `CalculateBaseDamageHandler` y `ApplyWeaknessHandler`):
```java
// Propaga onBeforeWeaknessCalculation — las cartas setean ignoreWeakness/ignoreResistance acá
registry.getActiveHandlers(board).forEach(h -> h.onBeforeWeaknessCalculation(req, ctx));
// Después de propagar, ApplyWeaknessHandler lee req.isIgnoreWeakness()
```

**`ApplyDefenderEffectsHandler`** (entre `ApplyResistanceHandler` y `DealDamageHandler`):
```java
// Solo propagar si NO se ignoran efectos del defensor (Greninja Mist Slash los ignora)
if (!req.isIgnoreDefenderEffects()) {
    registry.getActiveHandlers(board).forEach(h -> h.onBeforeDamageApplied(req, ctx));
}
// Furfrou reduce -20 acá (después de W/R, antes de aplicar al Pokémon)
```

**`CardEffectsPostDamageHandler`** (entre `ExecuteAttackEffectHandler` y `CheckKnockoutHandler`):
```java
// Propaga onAfterDamageApplied — Chesnaught Spiky Shield pone contadores al atacante acá
registry.getActiveHandlers(board).forEach(h -> h.onAfterDamageApplied(req, ctx));
```

**`AttackRequest`** debe tener los campos nuevos:
```java
boolean ignoreWeakness = false;         // Greninja, Rhyperior, etc.
boolean ignoreResistance = false;       // Dugtrio, Inkay, Malamar, Aegislash BS
boolean ignoreDefenderEffects = false;  // solo Greninja Mist Slash
String attackerCardId;                  // para que los handlers sepan quién ataca
```

**`ApplyWeaknessHandler`** chequea el flag antes de calcular:
```java
if (req.isIgnoreWeakness()) return proceed(req);  // saltar sin modificar
// ... cálculo de debilidad normal ...
```

**`ApplyResistanceHandler`** ídem para resistance.

Ver `PATRON_CARD_HANDLER.md` y `GAME_ENGINE_DETALLES_PARTE2.md` secciones I-01, DS-01 para tests.
