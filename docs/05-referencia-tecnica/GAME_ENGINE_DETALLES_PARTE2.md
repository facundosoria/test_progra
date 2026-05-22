# GAME_ENGINE_DETALLES_PARTE2.md
# Gaps del motor identificados vs ryuu-play — comportamiento exacto e implementación

Este documento **continúa** `GAME_ENGINE_DETALLES.md` con el mismo formato.
Cubre los 6 gaps encontrados al comparar el diseño de Codemon contra el código
funcionando de ryuu-play (simulador de Pokemon TCG en TypeScript, licencia MIT).

Prerequisito: leer `PATRON_CARD_HANDLER.md` antes de implementar cualquier sección.

**Referencia de cartas XY1 afectadas:** validado contra xy1.json (146 cartas).

---

## Cómo leer este documento

Mismo formato que GAME_ENGINE_DETALLES.md:
- **Comportamiento exacto** — qué debe pasar
- **Error común** — el bug típico
- **Test que lo atrapa** — el test específico
- **Nota de implementación** — detalle técnico

---

## PARTE 7 — INFRAESTRUCTURA DE CARD HANDLERS

---

### CH-01: Lifecycle del CardHandlerRegistry — quién está "en juego"

**Comportamiento exacto:**
`registry.getActiveHandlers(board)` debe retornar los handlers de exactamente las cartas
que están en zonas de juego visibles en ese momento. Eso incluye:
- Pokémon Activo de cada jugador (y todas las cartas del slot: Pokémon base + evoluciones)
- Pokémon en Banca de cada jugador
- Stadium activo (zona compartida)
- Tools adjuntas a cualquier Pokémon en juego
- Supporter en la zona de supporter (antes de descartarse al final del turno)

No incluye:
- Cartas en mano
- Cartas en mazo
- Cartas en descarte
- Cartas de Premio

**Error común — incluir cartas del descarte:**
Una carta KO va al descarte pero su handler seguiría siendo llamado si `getAllCardsInPlay()`
incluye el descarte. Esto causaría que Chesnaught (Spiky Shield) siga reaccionando a
daño después de ser KO.

```java
// MAL: incluye descarte
public List<String> getAllCardsInPlay() {
    return Stream.concat(
        getActiveSlots().stream(),
        getDiscard().stream()   // ← WRONG
    ).collect(...);
}

// BIEN: solo zonas de juego activas
public List<String> getAllCardsInPlay() {
    List<String> cards = new ArrayList<>();
    // Activo + Banca de cada jugador
    players.forEach(p -> {
        cards.addAll(p.getActive().getAllCardIds());
        p.getBench().forEach(slot -> cards.addAll(slot.getAllCardIds()));
    });
    // Stadium activo
    if (activeStadium != null) cards.add(activeStadium.getCardId());
    // Tools adjuntas
    players.forEach(p -> {
        p.getAllPokemonSlots().forEach(slot -> {
            if (slot.getTool() != null) cards.add(slot.getTool().getCardId());
        });
    });
    return cards;
}
```

**Test que lo atrapa:**
```
test_ko_pokemon_handler_not_called_after_ko():
  Chesnaught está como Activo, tiene Spiky Shield
  Chesnaught es KO por daño del oponente
  Oponente ataca al nuevo Activo del dueño
  → onAfterDamageApplied() de Chesnaught NO debe llamarse
  → el nuevo Activo no recibe contadores de Spiky Shield
```

---

### CH-02: Orden de propagación — ¿a qué cartas primero?

**Comportamiento exacto:**
Al propagar un hook (ej: `onBeforeWeaknessCalculation`), el orden debe ser consistente
y determinista. Orden recomendado:

1. Cartas del jugador atacante (su Activo, su Banca, su Stadium)
2. Cartas del jugador defensor (su Activo, su Banca, su Stadium)

Dentro de cada jugador: Activo primero, luego Banca de izquierda a derecha, luego Tools,
luego Stadium.

**Por qué importa el orden:** en casos donde dos cartas quieren modificar el mismo valor
(ej: dos cards quieren setear `ignoreWeakness = true` y `ignoreWeakness = false`), el orden
determina cuál gana. En XY1 no hay conflictos de este tipo, pero el orden debe ser
documentado para correctitud futura.

**Error común — orden no determinista:**
```java
// MAL: Set/HashMap → orden no garantizado
Set<String> cardsInPlay = new HashSet<>(board.getAllCards());

// BIEN: List con orden definido
List<String> cardsInPlay = board.getAllCardsInPlayOrdered(); // orden fijo
```

**Test que lo atrapa:**
```
test_handler_propagation_order_is_deterministic():
  Misma board, misma acción, ejecutada 100 veces
  → El orden de llamadas a onBeforeWeaknessCalculation es idéntico en las 100 ejecuciones
```

---

### CH-03: Markers en el snapshot — serialización obligatoria

**Comportamiento exacto:**
La clase `Marker` (ver PARTE 8) debe serializarse correctamente en el `state_json` de
`game_state_snapshots`. Si el servidor se reinicia o un jugador se reconecta, los markers
activos deben sobrevivir.

Un marker tiene: `name` (String) y `sourceCardId` (String). Son suficientes para
reconstruir el estado completo.

**Error común — markers perdidos en reconexión:**
```java
// MAL: Marker no anotado para serialización
public class InPlayPokemon {
    @Transient  // ← WRONG: Jackson/JPA no incluye el campo
    private Marker marker;
}

// BIEN: incluir en serialización
public class InPlayPokemon {
    // Sin @Transient — Jackson lo serializa automáticamente
    @JsonInclude(JsonInclude.Include.NON_EMPTY)  // solo si hay markers activos
    private Marker marker = new Marker();
}
```

**Error común — deserializar marker como null:**
```java
// Si el snapshot fue guardado sin markers, al deserializar marker = null
// → NullPointerException en marker.hasMarker()

// BIEN: inicializar siempre
@JsonCreator
public InPlayPokemon() {
    this.marker = new Marker();  // nunca null
}
```

**Test que lo atrapa:**
```
test_marker_survives_snapshot_cycle():
  Kakuna usa Harden → pokemonSlot.marker.hasMarker("KAKUNA_HARDEN") == true
  Serializar el estado completo a JSON
  Deserializar el JSON a un nuevo GameContext
  → pokemonSlot.marker.hasMarker("KAKUNA_HARDEN") == true (sobrevivió)
```

---

### CH-04: Excepción vs flag — qué mecanismo usa cada hook

Ver tabla canónica en `PATRON_CARD_HANDLER.md` § "Mecanismos de bloqueo: excepción vs flag".

**Resumen:**
- `onBeforePlayItem`, `onBeforePlaySupporter`, `onBeforeUseAbility`, `onBeforeAttackDeclared` → bloquean lanzando `GameActionException` (acción ilegal del jugador activo, debe llegar al cliente como error 400 con mensaje descriptivo).
- `onBeforeApplyStatus` → bloquea seteando `ApplyStatusContext.blocked = true` (efecto pasivo del oponente que no aplica). El `StatusEffectManager` detecta `isBlocked()` y emite `STATUS_BLOCKED` en lugar de `STATUS_APPLIED`.
- `onBeforeWeaknessCalculation`, `onBeforeDamageApplied`, `onAfterDamageApplied` → modifican el `AttackRequest` directamente (no bloquean, ajustan: setean flags `ignoreWeakness/ignoreResistance/ignoreDefenderEffects` o ajustan `currentDamage`).

**Error común — usar excepción donde corresponde flag:**
```java
// MAL: lanzar excepción desde onBeforeApplyStatus
public void onBeforeApplyStatus(ApplyStatusContext ctx, GameContext game) {
    if (hasFairyEnergy) {
        throw new GameActionException("Sweet Veil bloquea");  // ← WRONG
        // El ataque del oponente no es ilegal; solo el efecto secundario no aplica.
        // The UI would show an error instead of "It doesn't affect [name]!".
    }
}

// BIEN: setear flag, dejar que el motor publique STATUS_BLOCKED
public void onBeforeApplyStatus(ApplyStatusContext ctx, GameContext game) {
    if (hasFairyEnergy) {
        ctx.setBlocked(true);  // ← CORRECTO
    }
}
```

**Error común — usar flag donde corresponde excepción:**
Si Trevenant usara un flag en `onBeforePlayItem`, el motor seguiría procesando la acción y el Item se "consumiría" sin efecto, en vez de devolver el error al cliente. La acción es ilegal, no un efecto secundario que falla.

**Test que lo atrapa:**
```
test_status_block_does_not_throw_exception():
  Slurpuff con Energía Hada en banca propia
  Oponente ataca aplicando POISONED
  → NO se lanza GameActionException
  → se publica STATUS_BLOCKED, no STATUS_APPLIED
  → el daño del ataque sí se aplica normalmente

test_action_block_throws_exception():
  Trevenant Activo del jugador A
  Jugador B intenta PLAY_ITEM
  → GameActionException con mensaje "Forest's Curse..."
  → el Item NO se descarta de la mano de B
```

---

## PARTE 8 — SISTEMA DE MARKERS

---

### M-01: La clase Marker — estructura y operaciones

**Comportamiento exacto:**
Un marker es un par `(name: String, sourceCardId: String)`. El `sourceCardId` identifica
la carta que puso el marker, permitiendo que múltiples cartas distintas pongan markers
con el mismo nombre sin colisionar.

```
Marker {
  markers: List<{ name: String, sourceCardId: String }>
  
  addMarker(name, sourceCardId):
    Si ya existe el par exacto → no duplicar
    Si no existe → agregar
  
  hasMarker(name):
    → true si algún marker tiene ese nombre (cualquier fuente)
  
  hasMarker(name, sourceCardId):
    → true si existe el par exacto
  
  removeMarker(name, sourceCardId):
    → elimina el par exacto si existe
  
  clearMarkersWithName(name):
    → elimina todos los markers con ese nombre (de cualquier fuente)
}
```

**Dónde existe el Marker:**
- `InPlayPokemon.marker` — markers específicos de ese slot (ej: Harden protege a Kakuna)
- `PlayerBoard.marker` — markers del jugador como entidad (ej: "este turno no podés jugar Items")

**Error común — no separar Marker del slot del Marker del jugador:**
```java
// MAL: el marker de bloqueo de Items va en el Pokémon
kakuna.getMarker().addMarker("BLOCK_ITEMS", "seismitoad-id");
// → El bloqueo desaparece si Kakuna es KO (markers del slot se limpian con clearEffects())

// BIEN: bloqueos de jugador van en PlayerBoard
opponentBoard.getMarker().addMarker("BLOCK_ITEMS", "trevenant-id");
// → El bloqueo persiste independientemente de qué Pokémon está en juego
```

---

### M-02: Markers de "próximo turno del oponente"

**Comportamiento exacto:**
Estos markers se activan cuando el jugador A usa un ataque y duran hasta el final del turno
del jugador B (el oponente). Patrón de dos markers:

1. `EFFECT_MARKER` en el Pokémon objetivo (ej: el slot de Kakuna) — activa el efecto
2. `CLEAR_MARKER` en el `PlayerBoard` del oponente — señala que al terminar su turno hay que limpiar

```
Turno N (Jugador A — Kakuna usa Harden):
  kakuna.slot.marker.add("KAKUNA_HARDEN", "kakuna-id")
  jugadorB.board.marker.add("CLEAR_KAKUNA_HARDEN", "kakuna-id")

Turno N+1 (Jugador B):
  Jugador B ataca → CardEffectsPreDamageHandler propaga → KakunaHandler intercepta
  → kakuna.slot.marker.hasMarker("KAKUNA_HARDEN") == true
  → si damage <= 60 → prevenirlo

  EndPhaseState del turno N+1 → onEndTurn se propaga → KakunaHandler corre
  → jugadorB.board.marker.hasMarker("CLEAR_KAKUNA_HARDEN") == true
  → limpiar: kakuna.slot.marker.remove("KAKUNA_HARDEN", "kakuna-id")
  → limpiar: jugadorB.board.marker.remove("CLEAR_KAKUNA_HARDEN", "kakuna-id")

Turno N+2 (Jugador A):
  kakuna.slot.marker.hasMarker("KAKUNA_HARDEN") == false → ya no hay protección
```

**Error común — limpiar en el EndPhase incorrecto:**
```java
// MAL: el handler limpia en CUALQUIER EndPhase
public void onEndTurn(EndTurnContext ctx, GameContext game) {
    // Esto limpia en el EndPhase del PROPIO turno de Kakuna (turno N)
    // → el marker dura 0 turnos
    cleanMarker(ctx.getActivePlayer());
}

// BIEN: limpiar solo cuando el oponente termina SU turno
public void onEndTurn(EndTurnContext ctx, GameContext game) {
    PlayerBoard endingPlayer = ctx.getActivePlayer();
    // El CLEAR_MARKER está en el jugador que acaba de terminar su turno
    if (endingPlayer.getMarker().hasMarker(CLEAR_MARKER, getCardId())) {
        endingPlayer.getMarker().removeMarker(CLEAR_MARKER, getCardId());
        // También limpiar el marker del Pokémon objetivo
        game.getOpponent(endingPlayer).getAllPokemonSlots()
            .forEach(slot -> slot.getMarker().removeMarker(HARDEN_MARKER, getCardId()));
    }
}
```

**Tests:**
```
test_harden_marker_protects_exactly_one_opponent_turn():
  Turno N: Kakuna usa Harden (kakuna.slot tiene marker)
  Turno N+1: oponente ataca con 40 daño → daño prevenido (40 <= 60)
  EndPhase turno N+1: markers limpiados
  Turno N+2 del siguiente turno propio: oponente ataca con 40 daño → daño aplicado (ya no hay marker)

test_harden_does_not_prevent_damage_over_60():
  Turno N: Kakuna usa Harden
  Turno N+1: oponente ataca con 80 daño (> 60) → daño aplicado igual

test_harden_protects_against_first_attack_only():
  Si el oponente tiene dos Pokémon que atacan en el mismo turno (por efectos de carta)
  → solo el primero puede ser prevenido; el marker se limpia al EndPhase, no por ataque
```

---

### M-03: Markers de "próximo turno propio" — doble marker

**Comportamiento exacto:**
Para efectos que duran hasta el próximo turno del *propio* jugador (ej: Rhyperior no puede
atacar, Xerneas-EX no puede usar X Blast), se usa un sistema de doble marker porque hay
dos EndPhases entre el turno actual y el próximo turno propio:

```
EndPhase del turno N (propio)         → borra MARKER_1
EndPhase del turno N+1 (oponente)     → borra MARKER_2 y el efecto principal
Inicio del turno N+2 (propio)         → el efecto ya no existe
```

```java
// Al usar el ataque:
playerActive.getMarker().add("CANT_ATTACK_MAIN", cardId);  // el efecto real
playerActive.getMarker().add("CLEAR_1", cardId);           // se borra en EndPhase N
playerActive.getMarker().add("CLEAR_2", cardId);           // se borra en EndPhase N+1

// En onEndTurn:
if (activePlayer.getMarker().hasMarker("CLEAR_1", cardId)) {
    activePlayer.getMarker().removeMarker("CLEAR_1", cardId);
    // CLEAR_2 sigue → todavía queda un EndPhase más
} else if (activePlayer.getMarker().hasMarker("CLEAR_2", cardId)) {
    activePlayer.getMarker().removeMarker("CLEAR_2", cardId);
    activePlayer.getMarker().removeMarker("CANT_ATTACK_MAIN", cardId); // limpiar el efecto
}
```

**Cartas XY1 que usan este patrón:**
- Rhyperior / Rock Wrecker: "This Pokémon can't attack during your next turn"
- Yveltal / Darkness Blade: "If tails, this Pokémon can't attack during your next turn"
- Xerneas-EX / X Blast: "This Pokémon can't use X Blast during your next turn"
- Aegislash / King's Shield: "This Pokémon can't use King's Shield during your next turn"
- Bisharp / Metal Wallop: "During your next turn, this attack does 40 more damage"

**Test:**
```
test_cant_attack_marker_lasts_exactly_one_own_turn():
  Turno N (Rhyperior): usa Rock Wrecker
  EndPhase turno N: CLEAR_1 borrado
  Turno N+1 (oponente): hace sus cosas
  EndPhase turno N+1: CLEAR_2 borrado, CANT_ATTACK_MAIN borrado
  Turno N+2 (Rhyperior): puede atacar normalmente
```

---

### M-04: Markers que se activan solo si la moneda sale cara/cruz

**Comportamiento exacto:**
Kakuna Harden, Quilladin Scrunch, Bunnelby/Diggersby Dig, Beedrill Flash Needle (si 3
caras) y Yveltal Darkness Blade (si cruz) tienen efectos condicionales según moneda.
El marker solo se pone si el resultado de la moneda es el correcto.

El flujo correcto: tirar la moneda primero (emitir COIN_FLIP), luego si el resultado
corresponde, agregar el marker. NO agregar el marker y luego decidir si aplica.

```java
// En el handler de Quilladin:
public void onBeforeWeaknessCalculation(AttackRequest req, GameContext ctx) {
    if (!isThisAttack(req, "Scrunch")) return;

    // Tirar moneda
    ctx.flipCoin(GameMessage.COIN_FLIP, result -> {
        if (result == CoinResult.HEADS) {
            // Solo si fue cara → marker
            req.getAttackerSlot().getMarker().addMarker(SCRUNCH_MARKER, getCardId());
            ctx.getOpponent(req.getAttacker()).getBoard().getMarker()
               .addMarker(CLEAR_SCRUNCH, getCardId());
        }
        // Si fue cruz → nada
    });
}
```

---

## PARTE 9 — ATAQUES QUE IGNORAN DEBILIDAD/RESISTENCIA

---

### I-01: Los flags ignoreWeakness / ignoreResistance en AttackRequest

**Comportamiento exacto:**
`AttackRequest` tiene dos flags booleanos que comienzan en `false` para cada ataque.
El nuevo handler `CardEffectsPreWeaknessHandler` propaga `onBeforeWeaknessCalculation`
a todas las cartas en juego antes de que `ApplyWeaknessHandler` y `ApplyResistanceHandler`
corran. Las cartas pueden setear los flags a `true`.

```
ignoreWeakness = false  → ApplyWeaknessHandler aplica ×2 si aplica
ignoreWeakness = true   → ApplyWeaknessHandler no hace nada (skip)

ignoreResistance = false → ApplyResistanceHandler aplica -20 si aplica
ignoreResistance = true  → ApplyResistanceHandler no hace nada (skip)
```

**Cartas XY1 que los usan:**

| Carta | Ataque | ignoreWeakness | ignoreResistance |
|---|---|---|---|
| Greninja | Mist Slash | true | true |
| Rhyperior | Rock Wrecker | true | true |
| Dugtrio | Rock Tumble | false | true |
| Inkay | Puncture | false | true |
| Malamar | Puncture | false | true |
| Aegislash | Buster Swing | false | true |

**Error común — agregar los flags DESPUÉS de ApplyWeaknessHandler:**
Si el flag llega tarde, el cálculo ya se hizo.

```java
// MAL: el handler de Greninja se llama en ExecuteAttackEffectHandler (paso 6)
// → ApplyWeakness ya corrió en el paso 3

// BIEN: el handler de Greninja se llama en CardEffectsPreWeaknessHandler (entre paso 2 y 3)
// → ApplyWeakness aún no corrió
```

**Error común — Greninja ignora efectos del defensor también:**
El texto completo es: "This attack's damage isn't affected by Weakness, Resistance, **or any
other effects on your opponent's Active Pokémon**." Esto incluye efectos como Furfrou (-20).
Un tercer flag `ignoreDefenderEffects` en `AttackRequest` controla este caso.

```java
// Implementación de ApplyWeaknessHandler con los flags:
@Override
public AttackResult handle(AttackRequest req) {
    if (req.isIgnoreWeakness()) {
        return proceed(req);  // saltar todo este handler
    }
    // ... cálculo de debilidad existente ...
    return proceed(req);
}
```

**Tests:**
```
test_mist_slash_ignores_weakness_and_resistance():
  Defensor tiene weakness al tipo de Greninja (×2)
  Defensor tiene resistance (-20)
  Greninja usa Mist Slash con baseDamage=60
  → daño final = 60 (ni weakness ni resistance aplicados)

test_mist_slash_ignores_furfrou_reduction():
  Defensor es Furfrou con Fur Coat activo
  Greninja usa Mist Slash con baseDamage=60
  → daño final = 60 (Fur Coat ignorado por ignoreDefenderEffects)

test_rock_tumble_ignores_resistance_but_applies_weakness():
  Defensor tiene resistance (-20) y weakness (×2)
  Dugtrio usa Rock Tumble con baseDamage=40
  → daño final = 40×2 = 80 (weakness aplicada, resistance ignorada)

test_normal_attack_applies_both():
  Atacante usa ataque sin flags
  → weakness y resistance aplicados normalmente
```

---

## PARTE 10 — BLOQUEO DE ACCIONES DEL OPONENTE

---

### A-01: Trevenant — bloqueo continuo de Items mientras es Activo

**Comportamiento exacto:**
Habilidad PASIVA. Mientras Trevenant es el Pokémon Activo de su dueño, el **oponente**
no puede jugar ningún Item de su mano.

La condición se verifica en tiempo real: si Trevenant se retira o es KO, el bloqueo
desaparece inmediatamente. No usa markers porque la condición es el estado presente del
tablero, no un efecto temporal.

```java
// TrevenantHandler.onBeforePlayItem():
public void onBeforePlayItem(PlayItemContext itemCtx, GameContext game) {
    // ¿Quién intenta jugar el Item?
    PlayerBoard itemPlayer = itemCtx.getPlayer();

    // ¿Dónde está Trevenant?
    PlayerBoard trevenantOwner = game.findOwnerOf(getCardId());
    if (trevenantOwner == null) return;  // no está en juego

    // ¿Trevenant es el Activo de su dueño?
    if (!trevenantOwner.getActive().containsCard(getCardId())) return;

    // ¿El que juega el Item es el oponente de Trevenant?
    if (itemPlayer == trevenantOwner) return;  // el dueño puede jugar Items

    // Bloquear
    throw new GameActionException("Forest's Curse: no podés jugar Items mientras " +
                                   "Trevenant es el Pokémon Activo del oponente");
}
```

**Error común — olvidar que el DUEÑO de Trevenant sí puede jugar Items:**
La habilidad dice "your **opponent** can't play". El dueño de Trevenant juega Items
normalmente.

**Error común — verificar si Trevenant está en juego pero no si es el Activo:**
Si Trevenant está en Banca, la habilidad no aplica.

**Tests:**
```
test_trevenant_active_blocks_opponent_items():
  Trevenant es el Activo del jugador A
  Jugador B intenta jugar un Item
  → GameActionException

test_trevenant_owner_can_still_play_items():
  Trevenant es el Activo del jugador A
  Jugador A intenta jugar un Item
  → OK

test_trevenant_bench_does_not_block():
  Trevenant está en Banca del jugador A
  Jugador B intenta jugar un Item
  → OK

test_trevenant_knocked_out_clears_block():
  Trevenant es KO → va al descarte → getAllCardsInPlay() ya no lo incluye
  Jugador B intenta jugar un Item
  → OK (el handler de Trevenant ya no se propaga)
```

---

### A-02: Krookodile — bloqueo de Supporters por un turno (con marker)

**Comportamiento exacto:**
Ataque "Bother": tirar moneda. Si sale cara, el oponente no puede jugar Supporters
durante su próximo turno. Usa el patrón de marker de "próximo turno del oponente".

```java
// KrookodileHandler.onBeforeWeaknessCalculation() — para el ataque Bother:
// (o podría ir en onAfterDamageApplied si se quiere separar)
// El ataque Bother hace 0 daño, es solo efecto → ExecuteAttackEffectHandler lo llama

// KrookodileHandler.onBeforePlaySupporter():
public void onBeforePlaySupporter(PlaySupporterContext ctx, GameContext game) {
    PlayerBoard player = ctx.getPlayer();
    if (player.getMarker().hasMarker(BOTHER_MARKER, getCardId())) {
        throw new GameActionException("Bother: no podés jugar Supporters este turno");
    }
}
```

**Tests:**
```
test_bother_heads_blocks_opponent_supporter_next_turn():
  Krookodile usa Bother → moneda HEADS
  Turno del oponente: intenta jugar Supporter
  → GameActionException

test_bother_tails_does_not_block():
  Krookodile usa Bother → moneda TAILS
  → ningún marker puesto → oponente puede jugar Supporters

test_bother_marker_expires_after_one_turn():
  Krookodile usa Bother (HEADS)
  Turno del oponente: puede atacar, juega otras cartas
  EndPhase del oponente: marker limpiado
  Turno siguiente del oponente: puede jugar Supporters
```

---

### A-03: Arbok — sin Habilidades hasta el fin del próximo turno propio

**Comportamiento exacto:**
Ataque "Gastro Acid": el Pokémon Defensor no tiene Habilidades hasta el final del próximo
turno de Arbok. Esto implica:
- El Pokémon afectado no puede usar habilidades activadas (rechazar `USE_ABILITY`)
- Las habilidades pasivas del Pokémon afectado tampoco deben dispararse

Usa el patrón de marker de "próximo turno propio" (doble marker).

El handler de Arbok debe interceptar `onBeforeAttackDeclared` (para `USE_ABILITY` si se
unifica) o un nuevo hook `onBeforeUseAbility`. Si el slot del Pokémon Defensor tiene el
marker activo, bloquear.

```java
// En MainPhaseState, agregar hook USE_ABILITY similar a PLAY_ITEM:
case USE_ABILITY -> {
    AbilityContext abilityCtx = new AbilityContext(ctx.getCurrentPlayer(), action);
    registry.getActiveHandlers(ctx.getBoard())
            .forEach(h -> h.onBeforeUseAbility(abilityCtx, ctx));
    handleAbility(ctx, action);
}
```

---

## PARTE 11 — PREVENCIÓN DE CONDICIONES ESPECIALES

---

### SC-01: Slurpuff — Sweet Veil previene condiciones especiales

**Comportamiento exacto:**
Habilidad PASIVA. Mientras Slurpuff está en juego (Activo o Banca), cada Pokémon propio
que tenga Fairy Energy adjunta **no puede ser afectado por condiciones especiales**.

"No puede ser afectado" significa que la condición simplemente no se aplica. No hay error,
el ataque del oponente "funciona" pero el efecto de condición no tiene efecto sobre los
Pokémon protegidos.

La verificación ocurre en `StatusEffectManager.applyStatus()` antes de llamar a
`addSpecialCondition()`.

```java
// SlurpuffHandler.onBeforeApplyStatus():
public void onBeforeApplyStatus(ApplyStatusContext ctx, GameContext game) {
    // ¿Slurpuff está en juego?
    PlayerBoard slurpuffOwner = game.findOwnerOf(getCardId());
    if (slurpuffOwner == null) return;

    // ¿El target es un Pokémon del dueño de Slurpuff?
    InPlayPokemon target = ctx.getTarget();
    if (!slurpuffOwner.getAllPokemonSlots().contains(target)) return;

    // ¿El target tiene Fairy Energy adjunta?
    boolean hasFairyEnergy = target.getEnergies().stream()
        .anyMatch(e -> e.getTypes().contains("Fairy"));

    if (hasFairyEnergy) {
        ctx.setBlocked(true);
        // El StatusEffectManager (después de propagar este hook) detecta isBlocked() y emite
        // STATUS_BLOCKED en lugar de STATUS_APPLIED, con datos:
        //   targetPokemonId       = target.getId()
        //   targetPokemonName     = target.getCard().getName()
        //   attemptedStatus       = ctx.getCondition()
        //   blockingAbilityName   = "Sweet Veil"
        //   blockingCardId        = getCardId()
        // Ver 06-system-logic.md para el contrato del evento y el mensaje UI
        // ("It doesn't affect [targetPokemonName]!").
    }
}
```

**Error común — bloquear solo el Pokémon Activo:**
Sweet Veil protege a TODOS los Pokémon propios con Fairy Energy, incluyendo los de Banca.

**Error común — requerir que Slurpuff sea el Activo:**
La habilidad dice "as long as this Pokémon **is in play**", no "as long as it's your
Active Pokémon". Slurpuff en Banca también protege.

**Error común — proteger Pokémon sin Fairy Energy:**
Solo los que tienen Fairy Energy adjunta están protegidos.

**Tests:**
```
test_slurpuff_bench_prevents_status_on_fairy_pokemon():
  Slurpuff en Banca del jugador A
  Venusaur (con Fairy Energy) es el Activo del jugador A
  Oponente usa ataque que aplica POISONED
  → Venusaur no queda POISONED

test_slurpuff_does_not_protect_without_fairy_energy():
  Slurpuff en Banca del jugador A
  Blastoise (sin Fairy Energy) es el Activo del jugador A
  Oponente usa ataque que aplica POISONED
  → Blastoise queda POISONED normalmente

test_slurpuff_knocked_out_removes_protection():
  Slurpuff es KO
  Venusaur (con Fairy Energy) es el Activo
  Oponente aplica condición
  → Venusaur queda afectado (Slurpuff ya no está en juego)
```

---

## PARTE 12 — STATS DINÁMICOS

---

### DS-01: Furfrou — Fur Coat reduce daño de ataques en 20

**Comportamiento exacto:**
Habilidad PASIVA. Cualquier daño hecho a Furfrou por ataques del oponente se reduce en 20,
**después de aplicar Debilidad y Resistencia**.

El hook correcto es `onBeforeDamageApplied` (entre ApplyResistance y DealDamage).
El daño ya pasó por el pipeline de weakness/resistance y este handler lo ajusta.

La reducción aplica solo si:
- El target ES este Furfrou (no otros Pokémon)
- El daño viene de un ATAQUE (no de condición especial, no de counter de Rainbow Energy)

```java
// FurfouFurCoatHandler.onBeforeDamageApplied():
public void onBeforeDamageApplied(AttackRequest req, GameContext ctx) {
    // ¿El target del daño es este Furfrou?
    if (!req.getDefenderSlot().containsCard(getCardId())) return;

    // ¿El daño viene de un ataque normal (no directo)?
    if (req.isDirect()) return;  // contadores directos no aplican (ver C-01 en GAME_ENGINE_DETALLES.md)

    // Reducir 20 (mínimo 0)
    int current = req.getCurrentDamage();
    req.setCurrentDamage(Math.max(0, current - 20));
}
```

**Error común — aplicar la reducción ANTES de la debilidad:**
Fur Coat dice "after applying Weakness and Resistance". Si se aplica antes, el resultado
es incorrecto cuando hay debilidad.

```
Ejemplo: atacante hace 80, Furfrou tiene weakness ×2
  MAL: (80 - 20) × 2 = 120
  BIEN: (80 × 2) - 20 = 140
```

**Error común — Greninja Mist Slash no respeta Fur Coat:**
Mist Slash dice "not affected by... any other effects on your opponent's Active Pokémon".
Fur Coat ES un efecto del Pokémon defensor. Con `ignoreDefenderEffects = true` en AttackRequest,
`CardEffectsPreDamageHandler` debe saltar la propagación a Furfrou.

```java
// CardEffectsPreDamageHandler.handle():
@Override
public AttackResult handle(AttackRequest req) {
    if (!req.isIgnoreDefenderEffects()) {
        // Solo propagar si no se ignoran los efectos del defensor
        List<CardHandler> active = registry.getActiveHandlers(req.getContext().getBoard());
        for (CardHandler handler : active) {
            handler.onBeforeDamageApplied(req, req.getContext());
        }
    }
    return proceed(req);
}
```

**Tests:**
```
test_fur_coat_reduces_damage_by_20():
  Furfrou es el Activo, sin weakness ni resistance
  Oponente ataca con 60 de daño
  → Furfrou recibe 40 de daño

test_fur_coat_applies_after_weakness():
  Furfrou tiene weakness ×2 al tipo del atacante
  Oponente ataca con 40 de daño base
  → (40 × 2) - 20 = 60 de daño final

test_fur_coat_does_not_go_below_zero():
  Furfrou recibe un ataque de 10 de daño
  → max(0, 10 - 20) = 0 de daño (no daño negativo)

test_fur_coat_does_not_apply_to_benched_pokemon():
  Furfrou está en Banca, otro Pokémon es el Activo
  El handler de Furfrou NO debe activarse para el daño al Activo

test_mist_slash_ignores_fur_coat():
  Furfrou es el Activo
  Greninja usa Mist Slash con 60 de daño
  → Furfrou recibe 60 (Fur Coat ignorado por ignoreDefenderEffects)
```

---

### DS-02: poisonDamage y burnDamage como campos de InPlayPokemon

**Comportamiento exacto:**
`InPlayPokemon` tiene dos campos numéricos:
```
poisonDamage: int = 10   // daño por contador de veneno entre turnos
burnDamage:   int = 20   // daño por contador de quemadura (si sale Cruz) entre turnos
```

Al aplicar una condición especial, resetear al default:
```java
// En addSpecialCondition():
if (condition == POISONED)  this.poisonDamage = 10;
if (condition == BURNED)    this.burnDamage = 20;
```

En `BetweenTurnsProcessor`, usar los valores del objeto en lugar de literales:
```java
// MAL:
if (hasCondition(POISONED)) activePokemon.addDamage(10);
if (hasCondition(BURNED) && coinResult == TAILS) activePokemon.addDamage(20);

// BIEN:
if (hasCondition(POISONED)) activePokemon.addDamage(activePokemon.getPoisonDamage());
if (hasCondition(BURNED) && coinResult == TAILS) activePokemon.addDamage(activePokemon.getBurnDamage());
```

**Por qué en XY1:** no hay cartas en XY1 que modifiquen estos valores, pero el patrón
es necesario para correctitud y extensibilidad. Si en el futuro se carga otro set con
un veneno más fuerte, ya está contemplado.

**Test:**
```
test_poison_damage_uses_field_value():
  activePokemon.setPoisonDamage(10)  // valor default
  BetweenTurnsProcessor corre
  → activePokemon.getDamage() incrementa en 10 (no en literal hardcodeado)
```

---

## CHECKLIST FINAL — PARTE 2

Agregar a la lista de verificación de `GAME_ENGINE_DETALLES.md`:

```
CARD HANDLER REGISTRY:
[ ] CardHandler interfaz con todos los hooks definidos (default vacíos)
[ ] NoOpCardHandler singleton para cartas sin lógica especial
[ ] CardHandlerRegistry detecta @Component automáticamente
[ ] getAllCardsInPlay() retorna solo zonas activas (no descarte, no mano)
[ ] Orden de propagación documentado y determinista
[ ] Marker serializado en state_json (no @Transient, inicializado en constructor)
[ ] 26 handlers de cartas XY1 implementados (ver paquete xy1/)

PIPELINE EXTENDIDO:
[ ] CardEffectsPreWeaknessHandler entre BaseDamage y ApplyWeakness
[ ] CardEffectsPreDamageHandler entre ApplyResistance y DealDamage (respeta ignoreDefenderEffects)
[ ] CardEffectsPostDamageHandler entre ExecuteEffect y CheckKnockout
[ ] AttackRequest: ignoreWeakness=false, ignoreResistance=false, ignoreDefenderEffects=false, attackerCardId
[ ] ApplyWeaknessHandler: si ignoreWeakness=true → skip completo
[ ] ApplyResistanceHandler: si ignoreResistance=true → skip completo

INTEGRACIONES EN ESTADOS Y SERVICIOS:
[ ] MainPhaseState propaga onBeforePlayItem (Items)
[ ] MainPhaseState propaga onBeforePlaySupporter (Supporters)
[ ] MainPhaseState propaga onBeforeAttackDeclared (antes de transicionar)
[ ] MainPhaseState propaga onBeforeUseAbility (antes de USE_ABILITY)
[ ] StatusEffectManager propaga onBeforeApplyStatus → respeta ctx.isBlocked()
[ ] EndPhaseState propaga onEndTurn ANTES de cambiar jugador activo
[ ] KO handler propaga onKnockedOut después del KO

MARKERS:
[ ] Marker: add/has/remove con par (name, sourceCardId)
[ ] Marker en InPlayPokemon y PlayerBoard
[ ] clearEffects() de InPlayPokemon NO borra markers del PlayerBoard
[ ] Marker limpiado correctamente al KO (el slot de InPlayPokemon sí limpia sus markers)
[ ] Marker de "próximo turno oponente": EFFECT en slot del Pokémon, CLEAR en board del oponente
[ ] Marker de "próximo turno propio": doble CLEAR en el propio board (EndPhase N y N+1)
[ ] Marker condicional (flip de moneda): solo se agrega si el resultado es correcto

ATAQUES QUE IGNORAN W/R:
[ ] Greninja Mist Slash: ignoreWeakness=true, ignoreResistance=true, ignoreDefenderEffects=true
[ ] Rhyperior Rock Wrecker: ignoreWeakness=true, ignoreResistance=true
[ ] Dugtrio Rock Tumble: ignoreResistance=true
[ ] Inkay Puncture: ignoreResistance=true
[ ] Malamar Puncture: ignoreResistance=true
[ ] Aegislash Buster Swing: ignoreResistance=true

BLOQUEO DE ACCIONES:
[ ] Trevenant Forest's Curse: lanza excepción en onBeforePlayItem si es Activo
[ ] Trevenant NO bloquea al dueño propio
[ ] Trevenant en Banca: no bloquea
[ ] Krookodile Bother: marker de bloqueo Supporters por un turno del oponente
[ ] Arbok Gastro Acid: marker sin habilidades por turno propio siguiente

PREVENCIÓN DE CONDICIONES:
[ ] Slurpuff Sweet Veil: ctx.setBlocked(true) si target tiene Fairy Energy
[ ] StatusEffectManager emite STATUS_BLOCKED (no STATUS_APPLIED) cuando ctx.isBlocked()
[ ] STATUS_BLOCKED incluye targetPokemonName, blockingAbilityName, blockingCardId
[ ] UI cliente renderiza "It doesn't affect [targetPokemonName]!"
[ ] Slurpuff en Banca también protege (no solo si es Activo)
[ ] Solo protege Pokémon del dueño de Slurpuff con Fairy Energy adjunta

STATS DINÁMICOS:
[ ] Furfrou Fur Coat: reduce 20 en onBeforeDamageApplied (después de W/R)
[ ] Fur Coat NO aplica si ignoreDefenderEffects=true
[ ] Fur Coat solo si el daño viene de un ataque (no directo)
[ ] Daño nunca queda negativo por Fur Coat
[ ] InPlayPokemon.poisonDamage = 10, burnDamage = 20 (campos, no literales)
[ ] BetweenTurnsProcessor usa los campos, no literales hardcodeados
[ ] addSpecialCondition() resetea poisonDamage/burnDamage al default al aplicar
```
