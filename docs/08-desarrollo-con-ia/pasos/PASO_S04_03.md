---
id: PASO_S04_03
equipo: A
bloque: 4
dep: [PASO_S03_05, PASO_S04_01, PASO_S04_02, PASO_S05_01]
siguiente: PASO_S05_01
context_files:
  - 03-combat.md
  - 02-turn-flow.md
  - PATRON_CARD_HANDLER.md
  - GAME_ENGINE_DETALLES_PARTE2.md
  - CONVENCIONES.md
outputs:
  # 2.H.A — Ataques que ignoran W/R (R-IGN)
  - api/src/main/java/com/codemon/game/engine/cards/xy1/GreninjaMistSlashHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/RhyperiorRockWreckerHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/DugtrioRockTumbleHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/InkayPunctureHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/MalamarPunctureHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/AegislashBusterSwingHandler.java
  # 2.H.B — Prevención de daño con marker (M-02 — próximo turno del oponente)
  - api/src/main/java/com/codemon/game/engine/cards/xy1/KakunaHardenHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/QuilladinScrunchHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/AegislashKingsShieldHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/BunnelbyDigHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/DiggersbyDigHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/LunatoneMoonblastHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/WigglytuffHocusPinkusHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/ZoroarkCornerHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/ScolipedePoisonRingHandler.java
  # 2.H.C — Marker doble (M-03 — próximo turno propio)
  - api/src/main/java/com/codemon/game/engine/cards/xy1/YveltalDarknessBladeHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/XerneasXBlastHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/BisharpMetalWallopHandler.java
  # 2.H.D — Bloqueo de acciones del oponente (excepción)
  - api/src/main/java/com/codemon/game/engine/cards/xy1/TrevenantForestsCurseHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/KrookodileBotherHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/ArbokGastroAcidHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/SimisageTormentHandler.java
  # 2.H.E — Inmunidad a status (flag → STATUS_BLOCKED)
  - api/src/main/java/com/codemon/game/engine/cards/xy1/SlurpuffSweetVeilHandler.java
  # 2.H.F — Reducción / reacciones
  - api/src/main/java/com/codemon/game/engine/cards/xy1/FurfrouFurCoatHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/ChesnaughtSpikyShieldHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/VoltorbDestinyBurstHandler.java
  - api/src/main/java/com/codemon/game/engine/cards/xy1/BeedrillFlashNeedleHandler.java
  # Tests
  - api/src/test/java/com/codemon/game/cards/xy1/CardHandlersXY1Test.java
---

# PASO 2.H — Card Handlers de XY1 (26 cartas con lógica especial)

**Grupo legacy:** 2 — Motor de Juego | **Equipo:** A | **Dificultad:** 🔴 | **Tiempo:** 8–12 h (todos los sub-pasos)

## Navegación
← **Anterior:** [PASO_S05_01](PASO_S05_01.md) — EndPhaseState
→ **Siguiente:** [PASO_S05_03](PASO_S05_03.md) — GameEngine completo (GATE 2)
↔ **Paralelo:** [PASO_S05_02](PASO_S05_02.md) — Bot EASY (independiente, no requiere los handlers)

## Archivos a cargar junto a este

```
1. PATRON_CARD_HANDLER.md      ← interfaz CardHandler + Registry + mecanismos de bloqueo
2. GAME_ENGINE_DETALLES_PARTE2.md ← comportamiento exacto por carta (PARTES 8-12)
3. 03-combat.md                ← R-IGN, R-DEFENDER, R-STATUS-IMMUNE
4. 02-turn-flow.md             ← R-ABILITY-04, R-ABILITY-05, R-TURN-MARKER-01
5. 06-system-logic.md          ← evento STATUS_BLOCKED y mensaje UI
```

## Qué construye este paso

Un `@Component CardHandler` por cada carta de XY1 con lógica que no es capturable por parsing genérico de texto. Sin este PASO, los gaps de R-IGN, R-DEFENDER, R-STATUS-IMMUNE, R-ABILITY-04, R-ABILITY-05 y R-TURN-MARKER-01 quedan en el papel: el motor compila pero los 26 escenarios no funcionan.

Cada handler implementa **solo los hooks que necesita** (los demás quedan con la implementación default vacía de la interfaz). Spring detecta los `@Component` y `CardHandlerRegistry` los inyecta automáticamente vía constructor.

## Orden de implementación (sub-pasos)

Estos sub-pasos son **independientes entre sí** y cada uno es testeable por separado. Recomendación: implementarlos en este orden porque la dificultad crece progresivamente.

---

### 2.H.A — Ignore flags (6 handlers, ~1 h)

**Cartas:** Greninja / Mist Slash, Rhyperior / Rock Wrecker, Dugtrio / Rock Tumble, Inkay / Puncture, Malamar / Puncture, Aegislash / Buster Swing.

**Hook implementado:** `onBeforeWeaknessCalculation(AttackRequest, GameContext)`.

**Patrón:**
```java
@Override
public void onBeforeWeaknessCalculation(AttackRequest req, GameContext ctx) {
    if (!req.getAttackerCardId().equals(getCardId())) return;
    if (!req.getAttack().getName().equals("<NombreDelAtaque>")) return;
    req.setIgnoreWeakness(true);   // según corresponda por carta (ver R-IGN-01 en 03-combat.md)
    req.setIgnoreResistance(true);
    req.setIgnoreDefenderEffects(true);  // solo Greninja
}
```

Tabla de flags por carta (ver `GAME_ENGINE_DETALLES_PARTE2.md` PARTE 9 / I-01):

| Carta | cardId | Ataque | ignoreWeakness | ignoreResistance | ignoreDefenderEffects |
|---|---|---|---|---|---|
| Greninja | xy1-9 (verificar en xy1.json) | Mist Slash | true | true | true |
| Rhyperior | xy1-Rhyperior | Rock Wrecker | true | true | false |
| Dugtrio | xy1-Dugtrio | Rock Tumble | false | true | false |
| Inkay | xy1-Inkay | Puncture | false | true | false |
| Malamar | xy1-Malamar | Puncture | false | true | false |
| Aegislash | xy1-Aegislash | Buster Swing | false | true | false |

> Los `cardId` exactos están en `docs/05-referencia-tecnica/xy1.json` — el implementador debe consultarlos al crear cada handler.

**Nota Rhyperior:** además del flag, debe poner el marker de R-TURN-MARKER-01 ("can't attack during your next turn") usando el patrón doble (M-03). Eso lo hace en `onAfterDamageApplied` (después de aplicar el daño) o se factoriza en un sub-handler — ver 2.H.C.

**Tests obligatorios (6, uno por carta):**
- `test_<carta>_<ataque>_sets_correct_flags`: `request.isIgnoreWeakness/Resistance/DefenderEffects` queda en los valores esperados.
- `test_<carta>_does_not_set_flags_for_other_attacks`: si la misma carta tiene otro ataque, los flags quedan en `false`.

---

### 2.H.B — Prevent damage marker simple (9 handlers, ~3 h)

**Cartas:** Kakuna Harden, Quilladin Scrunch, Aegislash King's Shield, Bunnelby Dig, Diggersby Dig, Wigglytuff Hocus Pinkus, Zoroark Corner, Scolipede Poison Ring, Lunatone Moonblast.

**Patrón M-02 (`GAME_ENGINE_DETALLES_PARTE2.md`):** dos markers — uno en el slot del Pokémon (efecto), otro en el `PlayerBoard` del oponente (señal de limpieza).

**Hooks implementados:**
- `onAfterDamageApplied(AttackRequest, GameContext)` — del propio ataque: setea EFFECT_MARKER en su slot + CLEAR_MARKER en el board del oponente. Si el ataque tiene flip de moneda (Kakuna Harden, Quilladin Scrunch), el marker solo se setea si la moneda salió cara/cruz según corresponda (ver M-04).
- `onBeforeDamageApplied(AttackRequest, GameContext)` — cuando el oponente ataca: chequea si el target tiene el EFFECT_MARKER y reduce/anula el daño según las reglas de la carta.
- `onEndTurn(EndTurnContext, GameContext)` — limpia ambos markers cuando el oponente termina su turno (M-02).

**Carta canónica de referencia:** Kakuna Harden — ver bloque de código completo en `GAME_ENGINE_DETALLES_PARTE2.md` § M-02. Las otras 8 cartas son variantes (umbrales de daño distintos, condiciones de moneda distintas, target distinto).

**Tests obligatorios (9, uno por carta):**
- `test_<carta>_marker_protects_exactly_one_opponent_turn`: en el turno N+1 (oponente) el efecto aplica; en el turno N+3 (siguiente turno propio) ya no aplica.
- `test_<carta>_marker_cleared_in_endphase`: tras `EndPhaseState.onEnter()` del oponente, ambos markers desaparecen.
- (Solo para cartas con flip:) `test_<carta>_marker_only_set_on_correct_coin`: si la moneda no salió como dice la carta, no se setea ningún marker.

---

### 2.H.C — Marker doble (3 handlers, ~2 h)

**Cartas:** Yveltal / Darkness Blade, Xerneas-EX / X Blast, Bisharp / Metal Wallop. (Rhyperior también — implementado parcialmente en 2.H.A.)

**Patrón M-03:** doble CLEAR_MARKER en el propio `PlayerBoard` para que el efecto sobreviva los EndPhase del propio jugador y del oponente.

**Hooks implementados:**
- `onAfterDamageApplied` — del ataque que produce el efecto: setea `EFFECT_MARKER` + `CLEAR_1` + `CLEAR_2` en el `PlayerBoard` del propio jugador.
- `onEndTurn` — limpia primero `CLEAR_1`; luego, en el siguiente EndPhase, limpia `CLEAR_2` + `EFFECT_MARKER`.
- `onBeforeAttackDeclared` — chequea si el `EFFECT_MARKER` está activo y bloquea con `GameActionException` (Yveltal "can't attack", Xerneas "can't use X Blast").

**Tests obligatorios (3, uno por carta):**
- `test_<carta>_marker_lasts_exactly_one_own_turn`: turno N usa el ataque; turno N+2 (próximo propio) ya no aplica.

---

### 2.H.D — Bloqueo de acciones del oponente (4 handlers, ~2 h)

**Cartas:** Trevenant / Forest's Curse, Krookodile / Bother, Arbok / Gastro Acid, Simisage / Torment.

**Hooks implementados:**
| Carta | Hook | Mecanismo |
|---|---|---|
| Trevenant | `onBeforePlayItem` | excepción si Trevenant es Activo del oponente |
| Krookodile | `onBeforePlaySupporter` | excepción si el board del jugador tiene `BOTHER_MARKER` |
| Arbok | `onBeforeUseAbility` | excepción si el target tiene `GASTRO_ACID_MARKER` |
| Simisage | `onBeforeAttackDeclared` | excepción si se cumple la restricción del ataque |

Todos lanzan `GameActionException` con mensaje descriptivo (ver `PATRON_CARD_HANDLER.md` § "Mecanismos de bloqueo").

**Tests obligatorios (8 — 4 happy + 4 owner-no-block):**
- `test_<carta>_blocks_opponent_action`: jugador B intenta la acción → `GameActionException`.
- `test_<carta>_does_not_block_owner`: jugador A (dueño) intenta la misma acción → OK.

---

### 2.H.E — Inmunidad a status (1 handler, ~1.5 h)

**Carta:** Slurpuff / Sweet Veil.

**Hook implementado:** `onBeforeApplyStatus(ApplyStatusContext, GameContext)`.

**Patrón (ver `GAME_ENGINE_DETALLES_PARTE2.md` SC-01):**
```java
@Override
public void onBeforeApplyStatus(ApplyStatusContext ctx, GameContext game) {
    PlayerBoard slurpuffOwner = game.findOwnerOf(getCardId());
    if (slurpuffOwner == null) return;  // Slurpuff no está en juego
    if (!slurpuffOwner.getAllPokemonSlots().contains(ctx.getTarget())) return;  // target no es del dueño
    boolean hasFairy = ctx.getTarget().getEnergies().stream()
        .anyMatch(e -> e.getTypes().contains("Fairy"));
    if (hasFairy) {
        ctx.setBlocked(true);
        // StatusEffectManager emite STATUS_BLOCKED — no STATUS_APPLIED. Ver 06-system-logic.md.
    }
}
```

**Tests obligatorios (3):**
- `test_slurpuff_bench_protects_active_with_fairy_energy`: Slurpuff en Banca, Activo con Energía Hada → `STATUS_BLOCKED` emitido, target sin status.
- `test_slurpuff_does_not_protect_without_fairy_energy`: target sin Energía Hada → `STATUS_APPLIED` normal.
- `test_slurpuff_ko_removes_protection`: Slurpuff KO → `getAllCardsInPlay()` no lo incluye → handler no se propaga → status se aplica normalmente al target.

---

### 2.H.F — Reducción / reacciones (4 handlers, ~2 h)

**Cartas:** Furfrou / Fur Coat, Chesnaught / Spiky Shield, Voltorb / Destiny Burst, Beedrill / Flash Needle.

| Carta | Hook | Comportamiento |
|---|---|---|
| Furfrou | `onBeforeDamageApplied` | resta 20 al `currentDamage` (post W/R); respeta `request.isIgnoreDefenderEffects()` (Greninja salta este handler) |
| Chesnaught | `onAfterDamageApplied` | si recibió daño melee, suma 1 contador al atacante |
| Voltorb | `onKnockedOut` | flip coin; si cara → 5 contadores al Pokémon que hizo el KO |
| Beedrill | `onBeforeWeaknessCalculation` | si la moneda del ataque sale 3 caras, setea `ignoreDefenderEffects=true` |

**Tests obligatorios (4):**
- `test_furfrou_reduces_damage_by_20_post_wr`: 40 base × 2 weakness → 80 − 20 = 60.
- `test_furfrou_does_not_reduce_when_ignored`: Greninja Mist Slash → 50 limpio (Fur Coat ignorado).
- `test_chesnaught_spiky_shield_returns_damage_to_attacker`: atacante recibe 1 contador.
- `test_voltorb_destiny_burst_5_counters_on_heads`.

---

## Pruebas obligatorias por sub-paso (resumen)

Total: **~33 tests unitarios** distribuidos en `CardHandlersXY1Test.java`:

| Sub-paso | Tests |
|---|---|
| 2.H.A — Ignore flags | 6 (uno por carta) + 6 negativos (otros ataques de la misma carta no setean flags) |
| 2.H.B — Prevent damage marker | 9 (uno por carta) + 9 (marker se limpia en EndPhase oponente) + ~5 (tests de moneda) |
| 2.H.C — Marker doble | 3 (uno por carta) + 3 (marker dura exactamente 1 turno propio) |
| 2.H.D — Bloqueo acciones | 4 + 4 (dueño no se bloquea) |
| 2.H.E — Sweet Veil | 3 (Banca protege, sin Fairy no protege, KO levanta) |
| 2.H.F — Reducción / reacciones | 4 |

Ejecutar con:
```bash
./mvnw test -Dtest=CardHandlersXY1Test
```

Todos deben pasar antes de marcar el PASO completo.

## Verificación de integración con SMOKE

`PASO_S05_SMOKE.md` ya cubre los smokes 10–17 que validan el flujo end-to-end (ataque + WebSocket events) para Greninja, Kakuna, Trevenant, Slurpuff (incluido `STATUS_BLOCKED`), Furfrou y Arbok. Tras este PASO, los 8 smokes deben pasar sin warnings.

## Dependencias

| PASO | Qué provee |
|---|---|
| `PASO_S03_05` | `CardHandlerRegistry`, `CardHandler`, `Marker`, `AbilityContext` (con hook `onBeforeUseAbility`) |
| `PASO_S04_01` | `StatusEffectManager` que propaga `onBeforeApplyStatus` y emite `STATUS_BLOCKED` |
| `PASO_S04_02` | Pipeline con `ApplyAttackerEffectsHandler`, `ApplyDefenderEffectsHandler`, `CardEffectsPostDamageHandler` |
| `PASO_S05_01` | `EndPhaseState` que propaga `onEndTurn` antes del orden Envenenado→Quemado→Dormido→Paralizado |

Si alguno de los PASOs anteriores está incompleto, los handlers compilarán pero los hooks no se invocarán.
