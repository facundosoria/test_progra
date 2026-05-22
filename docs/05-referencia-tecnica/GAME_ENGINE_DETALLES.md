# GAME_ENGINE_DETALLES.md
# Todo lo que puede fallar en el motor de juego — y cómo evitarlo

Este documento no reemplaza a los archivos de reglas (01-setup.md, 02-turn-flow.md, etc.).
Los complementa con **comportamiento exacto, casos borde, errores comunes y tests específicos**.

---

## Cómo leer este documento

Cada sección tiene:
- **Comportamiento exacto** — qué debe pasar, sin ambigüedad
- **Error común** — el bug típico que introduce una IA o desarrollador
- **Test que lo atrapa** — el test específico que falla si el error existe
- **Nota de implementación** — detalle técnico que no está en las reglas pero importa

---

## PARTE 1 — SETUP

---

### S-01: Barajado del mazo

**Comportamiento exacto:**
El mazo de 60 cartas se baraja con `Collections.shuffle(deck, new SecureRandom())`.
El orden resultante es completamente opaco: ni el servidor ni el cliente deben conocerlo más allá de la posición 0 (la carta que se roba).

**Error común — usar la misma semilla:**
```java
// MAL: misma semilla → mismo orden siempre
Collections.shuffle(deck, new Random(12345));

// BIEN
Collections.shuffle(deck, new SecureRandom());
```

**Error común — barajar la lista de referencia:**
```java
// MAL: baraja la lista original, afecta otras referencias
Collections.shuffle(player.getOriginalDeck());

// BIEN: trabajar con una copia mutable
List<String> deck = new ArrayList<>(player.getOriginalDeck());
Collections.shuffle(deck, new SecureRandom());
playerBoard.setDeck(deck);
```

**Test que lo atrapa:**
```
test_shuffle_produces_different_orders():
  Barajar el mismo mazo 10 veces
  Al menos 9 de los 10 resultados deben ser distintos entre sí
  (probabilidad de colisión con 60 cartas es astronomicamente baja)
```

---

### S-02: Detección de Pokémon Básico para mulligan

**Comportamiento exacto:**
Un Pokémon es Básico si y solo si:
- `supertype == "Pokémon"`
- `subtypes` contiene `"Basic"`
- `subtypes` NO contiene `"Restored"`

**Diagrama de decisión:**
```
supertype == "Pokémon"?  NO → No es Básico
       ↓ SÍ
subtypes.contains("Basic")?  NO → No es Básico (Stage 1, Stage 2, MEGA)
       ↓ SÍ
subtypes.contains("Restored")?  SÍ → No es Básico (caso especial)
       ↓ NO
Es Pokémon Básico válido ✓
```

**Error común — solo chequear supertype:**
```java
// MAL: acepta Stage 1, Stage 2, MEGA como "básicos"
boolean isBasic = card.getSupertype().equals("Pokémon");

// BIEN
boolean isBasic = card.getSupertype().equals("Pokémon")
    && card.getSubtypes().contains("Basic")
    && !card.getSubtypes().contains("Restored");
```

**Error común — no verificar Restaurados:**
Los Pokémon Restaurados tienen `subtypes: ["Restored"]`. Un mazo con solo Restaurados
entraría en bucle infinito de mulligans. Agregar un límite de seguridad:
```java
int mulligan_limit = 0;
while (!hasBasicPokemon(hand)) {
    if (++mulligan_limit > 30) throw new IllegalStateException("Mazo sin básicos: loop detectado");
    // ...
}
```

**Tests:**
```
test_stage1_no_es_basico():  subtypes=["Stage 1"] → no cuenta como básico
test_mega_no_es_basico():    subtypes=["MEGA","EX"] → no cuenta
test_restored_no_es_basico(): subtypes=["Restored"] → no cuenta
test_ex_es_basico():          subtypes=["Basic","EX"] → SÍ cuenta (Venusaur-EX es Basic)
```

---

### S-03: Mulligan Caso B — Cartas extra al oponente

Este es el caso más frecuentemente implementado mal.

**Comportamiento exacto:**
- Si mulliganCount == 1: oponente NO roba cartas extra (el primero no cuenta)
- Si mulliganCount == 2: oponente roba 1 carta extra
- Si mulliganCount == 3: oponente roba 2 cartas extra
- En general: `cartas_extra = mulliganCount - 1`

**Timeline exacto del Caso B:**

```
Estado inicial: player1 tiene básico, player2 NO tiene básico

[PASO 1] player1 coloca Activo, Banca y Premios (completa el setup)
[PASO 2] player2 revela su mano (sin básico) → mulliganCount = 1
[PASO 3] player2 baraja mano de vuelta al mazo y roba 7 nuevas cartas
[PASO 4] ¿player2 tiene básico ahora?

  SI → cartas_extra = mulliganCount - 1 = 0
       player1 no roba nada extra
       continuar con paso 4 (colocar Activo de player2)

  NO → mulliganCount = 2
       player2 baraja y roba 7 nuevas cartas
       cartas_extra = mulliganCount - 1 = 1
       player1 roba 1 carta extra de su mazo
       Si esa carta es Básico → player1 PUEDE colocarla en Banca (opcional)
       Repetir PASO 4 hasta que player2 tenga básico
```

**Error común — contar el primero:**
```java
// MAL: roba 1 extra incluso en el primer mulligan
extraCards = mulliganCount;  // ← WRONG

// BIEN
extraCards = mulliganCount - 1;  // 0 para el primer mulligan
```

**Error común — olvidar que las cartas extra son opcionales:**
El oponente PUEDE colocar en Banca si son Básicos, pero no está obligado.
```java
if (extraCard.isBasic()) {
    // Emitir evento preguntando al oponente si quiere colocarla en Banca
    // El oponente responde PLACE_BENCH o SKIP
    // No asumir que siempre la coloca
}
```

**Error común — el oponente con mulligan revela su mano antes de que el otro haga el setup:**
El flujo debe ser estrictamente secuencial:
1. Primero el jugador sin mulligan completa setup (Activo + Banca + Premios)
2. Luego el jugador con mulligan hace el mulligan

**Tests:**
```
test_mulligan_count_1_no_extra_cards():
  player2 hace 1 mulligan → player1 no roba cartas extra
  player2 hace 2 mulligans → player1 roba 1 carta extra
  player2 hace 3 mulligans → player1 roba 2 cartas extra

test_extra_card_is_basic_optional_bench():
  player2 hace 2 mulligans
  player1 roba 1 carta extra que resulta ser un Básico
  player1 puede elegir ponerla en Banca o no (ambas son respuestas válidas)

test_extra_card_is_not_basic_no_bench_option():
  La carta extra es un Trainer → player1 la agrega a la mano, sin opción de Banca
```

---

### S-04: Estado del tablero después del setup

**Lo que DEBE ser verdad después de setup completo:**
```
Para cada jugador:
  hand.size() >= 1           (puede variar por mulligans y cartas extra)
  deck.size() == 60 - hand.size() - 6   (premios salen del mazo después de la mano)
  prizes.size() == 6
  active != null             (colocó un Pokémon Activo)
  active.turnsInPlay == 0    (no ha jugado ningún turno aún)
  active.damage == 0
  active.statusConditions.isEmpty()
```

**Error común — premios sacados antes de la mano:**
```java
// MAL: saca premios ANTES de robar la mano
takeInitialPrizes();  // 6 cartas del top
drawInitialHand();    // 7 cartas del nuevo top
// → La mano y los premios se superponen

// BIEN
drawInitialHand();    // 7 cartas del top (índices 0-6)
// mulligan si necesario...
placeActive();
placeBench();
takeInitialPrizes();  // 6 cartas del nuevo top DESPUÉS de robar
```

**Test:**
```
test_setup_deck_consistency():
  Después del setup: deck.size() + hand.size() + prizes.size() == 60
  (siempre, independiente de mulligans)
```

---

## PARTE 2 — FLUJO DEL TURNO

---

### T-01: Chequeo de mazo vacío — cuándo dispararlo

**Comportamiento exacto:**
La derrota por mazo vacío (R-WIN-02) se verifica ANTES del robo obligatorio.
Si el mazo está vacío en ese momento → derrota del jugador activo.
Si el mazo se vacía por efecto de carta DURANTE el turno → NO es derrota, el juego continúa.

**Timeline exacto de DrawPhaseState.onEnter():**
```
1. turnNumber++
2. resetTurnFlags()
3. incrementar turnsInPlay de todos los Pokémon del jugador activo
4. emitir TURN_START

→ AQUÍ: chequear mazo vacío (ANTES del robo)
   Si deck.size() == 0: victoryChecker.checkDeckEmpty(ctx) → GAME_OVER

5. robar 1 carta
6. emitir CARD_DRAWN (privado)
7. transicionar a MainPhaseState
```

**Error común — chequear después del robo:**
```java
// MAL: roba primero, chequea después
String card = deck.remove(0);  // si deck vacío → IndexOutOfBoundsException
if (deck.isEmpty()) checkDeckEmpty();  // WRONG: ya robó

// BIEN
if (deck.isEmpty()) {
    victoryChecker.checkDeckEmpty(ctx);
    return;  // no continuar con el robo
}
String card = deck.remove(0);
```

**Error común — disparar derrota por efectos mid-turno:**
```java
// MAL: en PlaySycamoreHandler (descartar mano, robar 7)
// Si el mazo tiene 3 cartas y el supporter pide robar 7:
// NO es derrota, robar solo las 3 disponibles

// BIEN
int toDraw = Math.min(7, deck.size());  // robar lo que haya
for (int i = 0; i < toDraw; i++) {
    hand.add(deck.remove(0));
}
// Sin checkDeckEmpty() acá
```

**Tests:**
```
test_deck_empty_at_turn_start_loses():
  deck.size() == 0 al inicio del turno → GAME_OVER reason DECK_EMPTY

test_deck_empties_during_turn_no_loss():
  Professor Sycamore, deck tiene 3 cartas
  → Roba 3 cartas (las que hay), turno continúa normalmente

test_deck_empties_during_turn_then_next_turn_loses():
  Deck se vacía por efecto mid-turno
  Al INICIO del siguiente turno → GAME_OVER (ahí sí aplica R-WIN-02)
```

---

### T-02: turnsInPlay y la restricción de evolución

**Comportamiento exacto:**
- `turnsInPlay` se incrementa al inicio del turno del DUEÑO del Pokémon (en DrawPhaseState)
- Un Pokémon recién jugado tiene `turnsInPlay == 0`
- Solo puede evolucionar si `turnsInPlay >= 1`

**Timeline de un Básico recién jugado:**
```
Turno N:
  Jugador juega Básico → turnsInPlay = 0
  Intenta evolucionar en el mismo turno → BLOQUEADO (turnsInPlay < 1)

Turno N+1 del dueño (DrawPhaseState.onEnter()):
  Se incrementa turnsInPlay de todos los Pokémon del dueño
  Básico.turnsInPlay = 1

  Ahora puede evolucionar → PERMITIDO
```

**Error común — incrementar turnsInPlay del oponente:**
```java
// MAL: incrementa los Pokémon de TODOS los jugadores
for (InPlayPokemon p : ctx.getBoard().getAllPokemon()) {
    p.incrementTurnsInPlay();
}

// BIEN: solo los del jugador activo
PlayerBoard currentBoard = ctx.getCurrentPlayerBoard();
if (currentBoard.getActive() != null) {
    currentBoard.getActive().incrementTurnsInPlay();
}
currentBoard.getBench().forEach(p -> p.incrementTurnsInPlay());
```

**Error común — no resetear evolvedThisTurn:**
```java
// Al inicio del turno, resetear evolvedThisTurn de todos los Pokémon del jugador
// Si no se resetea, un Pokémon que evolucionó ayer no puede evolucionar hoy
currentBoard.getAllPokemon().forEach(p -> p.setEvolvedThisTurn(false));
```

**Tests:**
```
test_basic_played_this_turn_cannot_evolve():
  Turno N: jugador coloca Básico, intenta evolucionar
  → error "El Pokémon fue colocado este turno, no puede evolucionar"

test_basic_played_last_turn_can_evolve():
  Turno N: juega Básico
  Turno N+1: puede evolucionar (turnsInPlay == 1)

test_pokemon_cannot_evolve_twice_same_turn():
  Stage 1 evoluciona a Stage 2 en el mismo turno
  → error "Ya evolucionó este turno"

test_different_pokemon_can_evolve_same_turn():
  Jugador tiene 2 Básicos con Stage 1 disponibles
  Ambos pueden evolucionar en el mismo turno (turnsInPlay >= 1 para ambos)
```

---

### T-03: Mega Evolución termina el turno inmediatamente

**Comportamiento exacto:**
Al colocar una carta MEGA sobre un Pokémon-EX, el turno termina DE INMEDIATO.
No puede atacar, no puede adjuntar más energías, no puede jugar más Trainers, nada.

**Cómo identificar una carta MEGA:**
```java
boolean isMega = card.getSubtypes().contains("MEGA");
```

**Error común — permitir más acciones después de Mega Evo:**
```java
// MAL: no termina el turno
handleEvolve(ctx, action);
// jugador puede seguir haciendo cosas

// BIEN
handleEvolve(ctx, action);
if (evolutionCard.getSubtypes().contains("MEGA")) {
    ctx.transitionTo(new EndPhaseState());
    return;  // salir inmediatamente de handleAction
}
```

**Tests:**
```
test_mega_evolution_ends_turn():
  Jugador juega Mega Evolución → turno termina
  Estado pasa a EndPhaseState
  Jugador no puede hacer ninguna acción más

test_mega_evolution_still_cures_status():
  Pokémon-EX está Envenenado
  Evoluciona a MEGA → POISONED se cura (como toda evolución)
  El daño acumulado permanece
  Turno termina
```

---

### T-04: Retirada — qué se cura y qué no

**Comportamiento exacto:**
Al retirarse:
- ✅ Se curan TODAS las condiciones especiales (POISONED, BURNED, ASLEEP, PARALYZED, CONFUSED)
- ❌ El daño acumulado NO se cura
- ✅ Las Energías NO desechadas en el costo de retirada permanecen adjuntas
- ✅ La Tool permanece adjunta

**Error común — curar el daño:**
```java
// MAL
retreatedPokemon.setDamage(0);  // WRONG

// BIEN
retreatedPokemon.getStatusConditions().clear();  // solo condiciones
// retreatedPokemon.damage NO se toca
```

**Error común — remover la Tool:**
```java
// MAL
retreatedPokemon.setAttachedTool(null);  // la Tool permanece

// BIEN: no tocar attachedTool al retirarse
// Solo limpiar statusConditions
```

**Error común — no verificar condiciones antes de permitir retirada:**
```java
// La validación ANTES de ejecutar:
if (active.getStatusConditions().contains(StatusCondition.ASLEEP)) {
    return error("No puede retirarse, está Dormido");
}
if (active.getStatusConditions().contains(StatusCondition.PARALYZED)) {
    return error("No puede retirarse, está Paralizado");
}
```

**Tests:**
```
test_retreat_clears_all_status():
  Pokémon tiene POISONED + BURNED + CONFUSED
  Se retira → todas las condiciones removidas
  El daño permanece (ej. 50 daño)

test_retreat_keeps_damage():
  Pokémon tiene 70 de daño
  Se retira a Banca → damage sigue siendo 70

test_retreat_keeps_tool():
  Pokémon tiene Tool adjunta
  Se retira → Tool permanece adjunta

test_asleep_blocks_retreat():
  Pokémon ASLEEP → intenta retirarse → error

test_paralyzed_blocks_retreat():
  Pokémon PARALYZED → intenta retirarse → error

test_retreat_discards_exact_energy_cost():
  costo = 2, Pokémon tiene 3 energías adjuntas
  Se retira → se descartan exactamente 2 energías (elige cuáles), 1 permanece
```

---

### T-05: Stadiums — el mismo nombre bloquea

**Comportamiento exacto:**
- Si hay un Stadium activo y el jugador quiere colocar uno con DISTINTO nombre → el viejo va al descarte, el nuevo entra
- Si el jugador quiere colocar uno con el MISMO nombre que el Stadium activo → BLOQUEADO

**Error común — permitir reemplazar con el mismo nombre:**
```java
// MAL: siempre reemplaza
if (activeStadium != null) {
    discardPile.add(activeStadium);
}
ctx.setActiveStadium(newStadium);

// BIEN
if (activeStadium != null) {
    if (activeStadium.getName().equals(newStadium.getName())) {
        return error("Ya hay un " + newStadium.getName() + " en juego");
    }
    // Mandar al descarte del DUEÑO del stadium viejo (no del que lo reemplaza)
    ownerOf(activeStadium).getDiscardPile().add(activeStadium);
}
ctx.setActiveStadium(newStadium);
```

**Importante:** el Stadium viejo va al descarte del jugador que lo JUGÓ originalmente,
no del jugador que lo reemplaza. Hay que trackear quién jugó cada Stadium.

**Tests:**
```
test_stadium_same_name_blocked():
  Stadium "Fairy Garden" activo
  Jugador intenta colocar otro "Fairy Garden" → error

test_stadium_different_name_replaces():
  Stadium A activo
  Jugador coloca Stadium B → A va al descarte, B entra

test_stadium_old_goes_to_original_owners_discard():
  player1 juega Stadium A
  player2 juega Stadium B → Stadium A va al descarte de player1
```

---

## PARTE 3 — COMBATE Y DAÑO

---

### C-01: Daño directo vs daño normal — distinción crítica

**Esta distinción es la más común fuente de bugs en el motor.**

**Comportamiento exacto:**
Existen dos tipos de daño completamente distintos:

| Tipo | Cómo reconocerlo | Debilidad/Resistencia | Ejemplo |
|------|-----------------|----------------------|---------|
| **Normal** | Campo `damage` tiene número ("60", "40+") | SÍ aplican | Mayoría de ataques |
| **Directo** | `text` dice "put X damage counter(s)" | NO aplican | Efectos secundarios, Confusión |

**Cómo detectar daño directo en el texto del ataque:**
```java
boolean isDirect = attack.getText() != null
    && attack.getText().toLowerCase().contains("damage counter");

// Ejemplos de texto de ataque directo:
// "Put 3 damage counters on your opponent's Active Pokémon"
// "Put 2 damage counters on each of your opponent's Benched Pokémon"
// "This attack does 30 damage to 1 of your opponent's Benched Pokémon" ← CUIDADO
```

**CUIDADO con la tercera línea:** "This attack does 30 damage to 1 of your opponent's Benched Pokémon"
→ Esto es daño a la Banca. El daño a la Banca NUNCA aplica Debilidad/Resistencia (igual que directo).
→ NO es "damage counters" explícito, pero el efecto es similar.

**El daño de Confusión también es directo:**
```java
// Cuando sale Cruz en Confusión:
// "3 damage counters on your own Active Pokémon"
// → 30 de daño directo, SIN weakness/resistance del propio Pokémon
int confusionDamage = 30;  // siempre 30, siempre directo
attacker.setDamage(attacker.getDamage() + confusionDamage);
// NO pasar por el pipeline de debilidad/resistencia
```

**Tests:**
```
test_direct_damage_ignores_weakness():
  Atacante usa ataque con "put 3 damage counters"
  Defensor tiene weakness al tipo del atacante ×2
  → daño aplicado: 30 (3 contadores × 10), NO 60

test_normal_damage_applies_weakness():
  Atacante hace 40 daño normal
  Defensor tiene weakness ×2
  → daño aplicado: 80

test_confusion_damage_is_direct():
  Pokémon Confuso tira Cruz
  Su propio Pokémon tiene weakness a su propio tipo
  → 30 de daño, SIN aplicar weakness

test_bench_damage_no_weakness():
  Ataque afecta a Pokémon de Banca
  Pokémon de Banca tiene weakness al tipo del atacante
  → Debilidad NO aplica al daño en Banca
```

---

### C-02: Orden exacto del cálculo de daño

**El orden es estricto. Un error en el orden da resultados incorrectos.**

```
1. daño_base = parseDamage(attack.damage)
2. daño = daño_base + bonuses_atacante   ← ANTES de weakness
3. daño = daño × weakness_multiplier    ← después de bonuses
4. daño = daño - resistance_reduction   ← después de weakness
5. daño = daño - reduccion_defensor     ← al final
6. daño = max(0, daño)                  ← nunca negativo
```

**Error común — aplicar bonuses DESPUÉS de weakness:**
```java
// MAL: bonus + weakness en orden incorrecto
int damage = base * weaknessMultiplier + attackerBonus;  // WRONG

// BIEN
int damage = (base + attackerBonus) * weaknessMultiplier - resistanceReduction;
damage = Math.max(0, damage);
```

**Ejemplo concreto:**
```
Ataque base: 40, bonus del atacante: +20, weakness: ×2, resistance: -20

MAL:  40 × 2 + 20 - 20 = 80  (bonus aplicado post-weakness)
BIEN: (40 + 20) × 2 - 20 = 100  (bonus aplicado pre-weakness)
```

**Tests:**
```
test_damage_order_bonus_before_weakness():
  base=40, bonus=20, weakness=×2, resistance=0
  → (40+20)×2 = 120

test_damage_order_full_pipeline():
  base=40, bonus=20, weakness=×2, resistance=-20, defender_reduction=-10
  → ((40+20)×2 - 20) - 10 = 90

test_damage_never_negative():
  base=10, resistance=-20
  → max(0, 10-20) = 0
```

---

### C-03: Energías requeridas para atacar — Colorless

**Comportamiento exacto:**
El campo `cost` de un ataque es una lista de tipos: `["Grass", "Colorless", "Colorless"]`.
- Tipos específicos (Grass, Fire, Water, etc.) → solo los puede satisfacer una energía de ESE tipo
- "Colorless" → lo puede satisfacer una energía de CUALQUIER tipo

**Algoritmo correcto:**
```
1. Satisfacer primero los costos NO-Colorless con energías de su tipo
2. Satisfacer los Colorless con cualquier energía sobrante

NO al revés.
```

**Error común — usar Colorless primero y luego fallar en específicos:**
```java
// MAL: cuenta energías totales sin respetar tipos
if (attachedEnergies.size() >= totalCost) return true;  // WRONG

// BIEN
List<String> available = new ArrayList<>(attachedEnergyTypes); // ["Grass","Fire","Colorless"]
List<String> required = new ArrayList<>(attack.getCost());      // ["Grass","Colorless"]

// Paso 1: satisfacer específicos
for (String req : required) {
    if (!req.equals("Colorless")) {
        if (!available.remove(req)) return false;  // no hay energía de ese tipo
    }
}

// Paso 2: satisfacer Colorless con lo que sobre
long colorlessCost = required.stream().filter(r -> r.equals("Colorless")).count();
return available.size() >= colorlessCost;
```

**Caso especial: Double Colorless Energy:**
La `Double Colorless Energy` (xy1-130) provee 2 Colorless en una sola carta.
En la lista de `attachedEnergyTypes` debe representarse como dos entradas "Colorless":
```java
// Al adjuntar Double Colorless Energy:
if (isDoublColorless(energyCard)) {
    attachedEnergyTypes.add("Colorless");
    attachedEnergyTypes.add("Colorless");  // dos
} else {
    attachedEnergyTypes.add(energyCard.getTypes().get(0));
}
```

**Tests:**
```
test_specific_cost_needs_matching_energy():
  Ataque cuesta ["Grass", "Grass"]
  Pokémon tiene ["Grass", "Fire"] → FALLA (segunda Grass falta)
  Pokémon tiene ["Grass", "Grass"] → OK
  Pokémon tiene ["Grass", "Colorless"] → FALLA (Colorless no satisface Grass)

test_colorless_accepts_any_type():
  Ataque cuesta ["Colorless", "Colorless"]
  Pokémon tiene ["Fire", "Water"] → OK (ambas satisfacen Colorless)

test_double_colorless_energy_satisfies_two():
  Ataque cuesta ["Colorless", "Colorless"]
  Pokémon tiene [Double Colorless Energy] → OK

test_specific_before_colorless():
  Ataque cuesta ["Grass", "Colorless"]
  Pokémon tiene ["Grass"] → FALLA (falta 1 para Colorless)
  Pokémon tiene ["Grass", "Water"] → OK (Grass satisface Grass, Water satisface Colorless)
```

---

### C-04: Proceso de KO — orden de operaciones

**El orden importa porque la victoria puede declararse en medio del proceso.**

**Orden exacto:**
```
1. Detectar: pokemon.damage >= pokemon.card.hp

2. Descartar: pokemon.attachedEnergies → discardPile del dueño
              pokemon.attachedTool → discardPile del dueño
              pokemon (la carta base) → discardPile del dueño

3. Premios: calcular cuántos (1 normal, 2 si EX o MEGA)
            rival toma X cartas de SU zona de premios
            → agregar al HAND del rival
            → decrementar rivales.prizesCount

4. Emitir: POKEMON_KO, PRIZE_TAKEN

5. Verificar victoria: rival.prizesCount == 0 → GAME_OVER inmediato
   Si hay victoria: retornar, NO continuar

6. Si no hubo victoria:
   Si el KO fue al Pokémon ACTIVO:
     Si dueño.bench.isEmpty() → GAME_OVER (R-WIN-03)
     Si no → ctx.awaitingReplacement = true (esperar REPLACE_ACTIVE_AFTER_KO)
```

**Error común — premios del dueño del KO en vez del rival:**
```java
// MAL: el dueño del KO toma premios de sus propios premios
dueñoBoard.getPrizes().remove(0);  // WRONG

// BIEN: el RIVAL del KO toma premios de SUS propios premios
rivalBoard.getPrizes().remove(0);    // rival toma de su zona
rivalBoard.getHand().add(prize);
rivalBoard.setPrizesCount(rivalBoard.getPrizesCount() - 1);
```

**Error común — olvidar descartar Tools:**
```java
// MAL: solo descarta energías
discardPile.addAll(pokemon.getAttachedEnergies());

// BIEN: energías Y tool
discardPile.addAll(pokemon.getAttachedEnergies());
if (pokemon.getAttachedTool() != null) {
    discardPile.add(pokemon.getAttachedTool());
}
discardPile.add(pokemon.getCardId());  // la carta base también
```

**Error común — verificar victorias fuera de orden:**
```java
// MAL: verifica R-WIN-03 antes de que el rival tome premios
if (dueñoBoard.getBench().isEmpty()) declareLoser(ctx, dueño);
rivalBoard.takePrizes(prizesToTake);  // nunca llega acá

// BIEN: premios primero, victoria después
rivalBoard.takePrizes(prizesToTake);
if (rivalBoard.getPrizesCount() == 0) { declareWinner(ctx, rival); return; }
if (dueñoBoard.getBench().isEmpty()) { declareWinner(ctx, rival, "NO_POKEMON"); return; }
// esperar reemplazo del activo
```

**Identificar EX y MEGA para 2 premios:**
```java
int prizesToTake = 1;
List<String> subtypes = knockedOutPokemon.getCardSubtypes();
if (subtypes.contains("EX") || subtypes.contains("MEGA")) {
    prizesToTake = 2;
}
```

**Tests:**
```
test_ko_discards_all_attached():
  Pokémon con 2 energías y 1 Tool → KO
  Las 2 energías y la Tool van al descarte del dueño

test_ko_prizes_go_to_rival_hand():
  Pokémon normal KO → rival toma 1 de SUS premios, va a SU mano
  rival.prizesCount decrementó en 1

test_ko_ex_takes_two_prizes():
  Pokémon-EX KO → rival toma 2 premios
  rival.prizesCount decrementó en 2

test_last_prize_wins_immediately():
  Rival toma el último premio
  → GAME_OVER antes de verificar R-WIN-03

test_ko_no_bench_loses():
  KO del Activo, dueño sin Banca
  → GAME_OVER (R-WIN-03), no esperar reemplazo

test_ko_with_bench_awaits_replacement():
  KO del Activo, dueño tiene Pokémon en Banca
  → ctx.awaitingReplacement = true
  Próxima acción debe ser REPLACE_ACTIVE_AFTER_KO
  Cualquier otra acción → error "Debes elegir un nuevo Pokémon Activo"
```

---

### C-05: Condiciones especiales — tabla de acumulación

**La tabla completa de qué convive con qué:**

| Estado actual \ Nueva condición | POISONED | BURNED | ASLEEP | PARALYZED | CONFUSED |
|---|---|---|---|---|---|
| Sin condición | ✅ Agrega | ✅ Agrega | ✅ Agrega | ✅ Agrega | ✅ Agrega |
| POISONED | (ya tiene) | ✅ Coexisten | ✅ Coexisten | ✅ Coexisten | ✅ Coexisten |
| BURNED | ✅ Coexisten | (ya tiene) | ✅ Coexisten | ✅ Coexisten | ✅ Coexisten |
| ASLEEP | ✅ Coexiste | ✅ Coexiste | (ya tiene) | ⚠️ Reemplaza ASLEEP | ⚠️ Reemplaza ASLEEP |
| PARALYZED | ✅ Coexiste | ✅ Coexiste | ⚠️ Reemplaza PARALYZED | (ya tiene) | ⚠️ Reemplaza PARALYZED |
| CONFUSED | ✅ Coexiste | ✅ Coexiste | ⚠️ Reemplaza CONFUSED | ⚠️ Reemplaza CONFUSED | (ya tiene) |

**Regla simple:** POISONED y BURNED coexisten con todo. ASLEEP, PARALYZED y CONFUSED se reemplazan entre sí.

**Implementación:**
```java
void applyStatus(InPlayPokemon target, StatusCondition newStatus) {
    Set<StatusCondition> ROTATION = Set.of(ASLEEP, PARALYZED, CONFUSED);

    if (ROTATION.contains(newStatus)) {
        // Remover cualquier condición de rotación previa
        target.getStatusConditions().removeAll(ROTATION);
        // Emitir STATUS_REMOVED para cada una removida
    }
    // Agregar la nueva (POISONED y BURNED simplemente se agregan)
    target.getStatusConditions().add(newStatus);
    // Emitir STATUS_APPLIED
}
```

**Error común — remover todo al aplicar rotación:**
```java
// MAL: remueve POISONED y BURNED también
target.getStatusConditions().clear();  // WRONG
target.getStatusConditions().add(newStatus);

// BIEN: solo remueve las de rotación
target.getStatusConditions().removeAll(Set.of(ASLEEP, PARALYZED, CONFUSED));
target.getStatusConditions().add(newStatus);
// POISONED y BURNED se mantienen
```

**Tests para cada combinación:**
```
test_poisoned_and_burned_coexist():
  Pokémon POISONED → aplicar BURNED → tiene ambas

test_asleep_replaces_confused():
  Pokémon CONFUSED → aplicar ASLEEP
  → tiene ASLEEP, ya no tiene CONFUSED

test_paralyzed_replaces_asleep():
  Pokémon ASLEEP → aplicar PARALYZED
  → tiene PARALYZED, ya no tiene ASLEEP

test_rotation_doesnt_remove_poisoned():
  Pokémon POISONED + CONFUSED → aplicar ASLEEP
  → tiene POISONED + ASLEEP (CONFUSED removido, POISONED permanece)

test_rotation_doesnt_remove_burned():
  Pokémon BURNED + ASLEEP → aplicar PARALYZED
  → tiene BURNED + PARALYZED (ASLEEP removido, BURNED permanece)
```

---

### C-06: Paso entre turnos — orden y casos borde

**El orden es ESTRICTO. No cambiar.**

```
Orden:
1. Veneno  (Pokémon ACTIVO de AMBOS jugadores)
2. Quema   (Pokémon ACTIVO de AMBOS jugadores)
3. Sueño   (Pokémon ACTIVO de AMBOS jugadores)
4. Parálisis (Pokémon ACTIVO de AMBOS jugadores)
5. Verificar KOs (de TODOS los Pokémon activos afectados)
```

**Error común — solo procesar el jugador activo:**
Ambos jugadores pueden tener condiciones. Ambos deben procesarse.
```java
// MAL: solo procesa el jugador que acaba de jugar
processStatusFor(ctx.getCurrentPlayerBoard());

// BIEN: procesa ambos
processStatusFor(ctx.getPlayerBoard(ctx.getPlayer1Id()));
processStatusFor(ctx.getPlayerBoard(ctx.getPlayer2Id()));
```

**Error común — quema: eliminar el marcador cuando sale Cara:**
```java
// MAL
if (burnResult == HEADS) {
    active.getStatusConditions().remove(BURNED);  // WRONG
}

// BIEN: el marcador permanece SIEMPRE
// Solo se elimina al retirarse o evolucionar
if (burnResult == TAILS) {
    active.setDamage(active.getDamage() + 20);
}
// No tocar BURNED independientemente del resultado
```

**Error común — parálisis: cuándo se cura:**
La parálisis se cura automáticamente en el paso entre turnos que sigue al turno del DUEÑO.
```
Turno N (dueño): Pokémon paralizado en turno N
Paso entre turnos: ctx.turnNumber = N, paralyzedOnTurn[pokemon] = N
  → Se cura (N == N)

Turno N+1 (oponente): el oponente no tiene parálisis
Turno N+2 (dueño): paralyzedOnTurn[pokemon] habría sido removido en turno N
```

**Error común — parálisis curada en el turno del oponente:**
```java
// La lógica de cura de parálisis:
// "se cura en el paso entre turnos POSTERIOR al turno del dueño"

// El "paso entre turnos posterior al turno del dueño" es:
// el EndPhaseState que se ejecuta DESPUÉS del turno del dueño,
// ANTES del turno del oponente.

// NO debe curarse en el EndPhase del turno del oponente
// SOLO en el EndPhase del turno del propio dueño del Pokémon paralizado

if (active.getStatusConditions().contains(PARALYZED)) {
    Integer paralyzedTurn = ctx.getParalyzedOnTurn().get(active.getInstanceId());
    if (paralyzedTurn != null && paralyzedTurn == ctx.getTurnNumber()) {
        active.getStatusConditions().remove(PARALYZED);
        ctx.getParalyzedOnTurn().remove(active.getInstanceId());
        ctx.publishEvent(STATUS_REMOVED(PARALYZED, reason: PARALYSIS_EXPIRED));
    }
}
```

**Tests:**
```
test_between_turns_processes_both_players():
  player1.active = POISONED
  player2.active = BURNED
  Paso entre turnos → ambos reciben daño

test_burn_heads_no_damage_marker_stays():
  Pokémon BURNED, moneda Cara
  → damage no cambia, sigue teniendo BURNED en statusConditions

test_burn_tails_damage_and_marker_stays():
  Pokémon BURNED, moneda Cruz
  → damage += 20, sigue teniendo BURNED

test_paralysis_cured_after_owners_turn():
  Turno N (player1): player1.active paralizado en ese mismo turno
  EndPhase del turno N: parálisis se cura
  Turno N+1 (player2): player1.active ya no está paralizado

test_ko_by_poison_between_turns():
  Pokémon con 10 HP, POISONED
  Paso entre turnos → damage += 10 → 10 >= 10 → KO
  → Rival toma premios, verificar victoria
```

---

## PARTE 4 — CONDICIONES DE VICTORIA

---

### V-01: Múltiples condiciones simultáneas

**Comportamiento exacto:**
Si dos condiciones ocurren en el mismo momento, se evalúan SIMULTÁNEAMENTE.

**Casos posibles:**

```
CASO 1: Solo player1 cumple condición → player2 gana
CASO 2: Solo player2 cumple condición → player1 gana
CASO 3: Ambos cumplen condición → Muerte Súbita
CASO 4: Ambos cumplen Y además uno cumple más condiciones → el que tiene más gana directamente
```

**El único caso donde hay Muerte Súbita es cuando AMBOS están en condición de derrota.**

**Error común — declarar Muerte Súbita cuando solo uno pierde:**
```java
// MAL: confunde "dos condiciones en el mismo momento" con "ambos pierden"
if (victoryConcitionsMet >= 2) initiateSuddenDeath();  // WRONG

// BIEN
boolean p1Loses = checkLosingConditions(ctx, player1Id);
boolean p2Loses = checkLosingConditions(ctx, player2Id);

if (p1Loses && p2Loses) { initiateSuddenDeath(); return; }
if (p1Loses) { declareWinner(ctx, player2Id, reason); return; }
if (p2Loses) { declareWinner(ctx, player1Id, reason); return; }
```

---

### V-02: Muerte Súbita — configuración

**Comportamiento exacto:**
- Nueva partida completa con 1 Premio por jugador (no 6)
- Nuevo coin flip para determinar quién va primero
- El setup completo se repite (mulligan incluido)

**Error común — 6 premios en Muerte Súbita:**
```java
// MAL
int prizesCount = 6;

// BIEN: detectar si es Muerte Súbita
int prizesCount = ctx.isSuddenDeath() ? 1 : 6;
```

**Tests:**
```
test_sudden_death_one_prize_each():
  Muerte Súbita inicia
  → cada jugador tiene exactamente 1 Premio, no 6

test_sudden_death_new_coin_flip():
  → emite COIN_FLIP para determinar quién va primero

test_sudden_death_full_setup():
  → setup completo se repite (barajado, mano, etc.)
```

---

## PARTE 5 — ESTADO DEL JUEGO Y SEGURIDAD

---

### SEC-01: Qué nunca debe enviarse al cliente

**Esto es crítico. Una filtración de datos rompe la fairness del juego.**

| Dato | Cliente propio | Cliente rival |
|------|---------------|---------------|
| Cartas en mano | ✅ Completo | ❌ NUNCA (solo handCount) |
| Orden del mazo | ❌ NUNCA (solo deckSize) | ❌ NUNCA |
| Cartas de premios | ❌ NUNCA (solo prizesCount) | ❌ NUNCA |
| Pokémon Activo propio | ✅ Completo | ✅ Completo (visible) |
| Pokémon en Banca propia | ✅ Completo | ✅ Completo (visible) |
| Cartas en descarte | ✅ Completo | ✅ Completo (visible) |

**Implementar en GameEngine.sanitizeForPlayer():**
```java
private GameStateDTO sanitizeForPlayer(GameContext ctx, Long viewerId) {
    GameStateDTO dto = ctx.toFullDTO();

    // Player 1
    if (!viewerId.equals(ctx.getPlayer1Id())) {
        dto.getPlayer1().setHand(null);           // ocultar mano
        dto.getPlayer1().setHandCount(ctx.getPlayer1Board().getHand().size());
    }
    dto.getPlayer1().setDeck(null);               // mazo NUNCA (ni para el dueño)
    dto.getPlayer1().setDeckSize(ctx.getPlayer1Board().getDeck().size());
    dto.getPlayer1().setPrizes(null);             // premios NUNCA
    dto.getPlayer1().setPrizesCount(ctx.getPlayer1Board().getPrizesCount());

    // Player 2 (igual)
    if (!viewerId.equals(ctx.getPlayer2Id())) {
        dto.getPlayer2().setHand(null);
        dto.getPlayer2().setHandCount(ctx.getPlayer2Board().getHand().size());
    }
    dto.getPlayer2().setDeck(null);
    dto.getPlayer2().setDeckSize(ctx.getPlayer2Board().getDeck().size());
    dto.getPlayer2().setPrizes(null);
    dto.getPlayer2().setPrizesCount(ctx.getPlayer2Board().getPrizesCount());

    return dto;
}
```

**Tests:**
```
test_viewer_cannot_see_opponent_hand():
  player1 llama getState()
  response.player2.hand == null
  response.player2.handCount == 7

test_nobody_can_see_deck_order():
  Cualquier jugador llama getState()
  response.player1.deck == null  (solo deckSize)
  response.player2.deck == null

test_nobody_can_see_prizes():
  response.player1.prizes == null  (solo prizesCount)
  response.player2.prizes == null
```

---

### SEC-02: Validación del turno actual

**Todo request de acción debe verificar que es el turno del jugador.**

```java
// En GameEngine.processAction():
if (!ctx.getCurrentTurnPlayerId().equals(playerId)) {
    throw new NotYourTurnException("No es tu turno");
}
```

**Casos especiales que requieren validación diferente:**
1. `REPLACE_ACTIVE_AFTER_KO`: puede ser del jugador que NO tiene el turno (el dueño del KO debe reemplazar su Activo aunque no sea su turno)
2. Acciones de setup: ambos jugadores hacen acciones simultáneas

```java
if (ctx.isAwaitingReplacement()) {
    if (!playerId.equals(ctx.getAwaitingReplacementPlayerId())) {
        throw new NotYourTurnException("No sos el jugador que debe reemplazar el Activo");
    }
    if (action.getType() != ActionType.REPLACE_ACTIVE_AFTER_KO) {
        throw new InvalidActionException("Debes elegir un nuevo Pokémon Activo primero");
    }
}
```

---

### SEC-03: Persistencia del estado

**Cada acción debe persistir el estado DESPUÉS de procesarse, de forma asíncrona.**

```java
// En GameEngine.processAction():
ctx.handleAction(action);
publishPendingEvents(ctx);    // 1. notificar clientes (sincrónico)
persistSnapshotAsync(ctx);    // 2. guardar en BD (asíncrono, no bloquea)
return ctx.getLastResult();
```

**El snapshot debe contener el estado COMPLETO (con información privada):**
```java
// El snapshot en BD tiene TODO (para poder reconstruir la partida)
// La sanitización ocurre SOLO al enviar al cliente
gameStateSnapshot.setStateJson(ctx.toFullDTO());  // completo en BD
```

**Reconexión — recuperar estado:**
```java
// GET /games/{id}/state cuando cliente reconecta
GameContext ctx = loadContext(gameId);
return sanitizeForPlayer(ctx, requestingPlayerId);
// El cliente recibe el estado actual sin datos privados del rival
```

---

## PARTE 6 — TESTS DE INTEGRACIÓN CRÍTICOS

Estos tests cubren los flujos más complejos. Si pasan, la mayoría de los bugs están cubiertos.

---

### INT-01: Partida completa PVE de principio a fin

```java
@Test
void test_complete_pve_game_no_errors() {
    // Setup
    Game game = createPVEGame(player1DeckId, BotDifficulty.EASY);
    assertThat(game.getStatus()).isEqualTo("ACTIVE");

    // Jugar hasta que termine (máximo 200 turnos para evitar loops)
    int maxTurns = 200;
    int turns = 0;
    while (!"FINISHED".equals(game.getStatus()) && turns < maxTurns) {
        // Si es turno del jugador: hacer acción random válida
        // Si es turno del Bot: el Bot decide solo
        GameStateDTO state = gameEngine.getState(game.getId(), player1Id);
        List<GameAction> validActions = getValidActionsFor(state, currentPlayer);
        assertThat(validActions).isNotEmpty();  // siempre hay al menos END_TURN
        gameEngine.processAction(game.getId(), currentPlayer, randomOf(validActions));
        turns++;
    }

    assertThat(turns).isLessThan(maxTurns);  // la partida terminó
    assertThat(game.getWinnerId()).isNotNull();
    assertThat(game.getStatus()).isEqualTo("FINISHED");
}
```

---

### INT-02: Flujo de KO con Pokémon-EX → 2 premios

```java
@Test
void test_ko_ex_takes_two_prizes() {
    // Setup: player1.active = Pokémon-EX con 10 HP
    // player2.prizes = 6

    // player2 ataca con suficiente daño para KO
    gameEngine.processAction(gameId, player2Id, attackAction);

    GameStateDTO state = gameEngine.getState(gameId, player2Id);
    assertThat(state.getPlayer2().getPrizesCount()).isEqualTo(4);  // 6 - 2
    // player1.active = null (fue KO)
    // player1 debe elegir nuevo activo
    assertThat(ctx.isAwaitingReplacement()).isTrue();
}
```

---

### INT-03: Condiciones especiales sobreviven evolución

```java
@Test
void test_evolving_cures_status_but_not_damage() {
    // Setup: player1.active = Básico con 50 daño, POISONED + BURNED
    // player1 tiene Stage 1 en mano que puede evolucionar (turnsInPlay >= 1)

    gameEngine.processAction(gameId, player1Id, evolveAction);

    GameStateDTO state = gameEngine.getState(gameId, player1Id);
    InPlayPokemonDTO active = state.getPlayer1().getActive();

    assertThat(active.getStatusConditions()).isEmpty();  // curadas
    assertThat(active.getDamage()).isEqualTo(50);        // daño permanece
}
```

---

### INT-04: Muerte Súbita — simultaneidad

```java
@Test
void test_mutual_ko_triggers_sudden_death() {
    // Setup:
    // player1.active = 10 HP, player2.active = 10 HP
    // player1 usa ataque que hace exactamente 10 de daño al activo rival
    // player2.active tiene ataque de daño que por algún efecto daña también a player1

    // El turno de player1 ataca
    gameEngine.processAction(gameId, player1Id, attackFor10);

    // Si player2.active también queda KO en el mismo momento
    // (ej: daño de veneno en el paso entre turnos)
    advanceToBetweenTurns();

    // Ambos KO → Muerte Súbita
    GameStateDTO state = gameEngine.getState(gameId, player1Id);
    assertThat(game.getStatus()).isEqualTo("SUDDEN_DEATH");
    assertThat(state.getPlayer1().getPrizesCount()).isEqualTo(1);
    assertThat(state.getPlayer2().getPrizesCount()).isEqualTo(1);
}
```

---

### INT-05: Mazo vacío por efecto de carta vs inicio de turno

```java
@Test
void test_deck_emptied_by_card_effect_no_loss() {
    // Setup: player1 tiene 5 cartas en mazo
    // Professor Sycamore: descartar mano, robar 7
    // Con solo 5 cartas disponibles → debe robar 5, no declarar derrota

    gameEngine.processAction(gameId, player1Id, playSycamoreAction);

    GameStateDTO state = gameEngine.getState(gameId, player1Id);
    assertThat(state.getPlayer1().getDeckSize()).isEqualTo(0);
    assertThat(game.getStatus()).isEqualTo("ACTIVE");  // sigue jugando
}

@Test
void test_empty_deck_at_next_turn_start_loses() {
    // Continuar desde el test anterior
    // Finalizar el turno de player1
    gameEngine.processAction(gameId, player1Id, endTurnAction);

    // Turno de player2: player2 hace sus cosas y termina
    gameEngine.processAction(gameId, player2Id, endTurnAction);

    // Inicio del turno de player1 con mazo vacío
    // → DrawPhaseState chequea ANTES de robar → GAME_OVER
    assertThat(game.getStatus()).isEqualTo("FINISHED");
    assertThat(game.getWinnerId()).isEqualTo(player2Id);
}
```

---

## CHECKLIST FINAL DEL MOTOR

Antes de considerar el motor como "terminado", verificar:

```
SETUP:
[ ] Barajado con SecureRandom
[ ] Básico detectado correctamente (excluyendo Restaurados)
[ ] Mulligan Caso A: reinicio sin penalización
[ ] Mulligan Caso B: cartas extra = mulliganCount - 1
[ ] Premios tomados DESPUÉS de robar la mano inicial
[ ] state_json generado con todos los campos
[ ] mano del rival = null en getState()

TURNO:
[ ] R-WIN-02 verificado ANTES del robo
[ ] turnsInPlay incrementado al inicio del turno del dueño
[ ] evolvedThisTurn reseteado cada turno
[ ] Mega Evolución termina el turno inmediatamente
[ ] Retirada: curar condiciones, NO el daño
[ ] Stadium mismo nombre: bloqueado
[ ] Stadium viejo va al descarte del jugador ORIGINAL

COMBATE:
[ ] Daño directo ("damage counters"): SIN weakness/resistance
[ ] Daño a Banca: SIN weakness/resistance
[ ] Daño de Confusión: SIEMPRE directo (30)
[ ] Orden: (base + bonus_atacante) × weakness - resistance - bonus_defensor
[ ] Resultado mínimo: 0
[ ] Colorless satisfecho con cualquier tipo
[ ] Double Colorless = 2 Colorless

KO:
[ ] RIVAL toma premios, no el dueño del KO
[ ] EX y MEGA dan 2 premios
[ ] Energías + Tool → descarte
[ ] Victoria inmediata si se tomó el último premio
[ ] R-WIN-03 verificado DESPUÉS de los premios

CONDICIONES:
[ ] POISONED + BURNED coexisten con todo
[ ] ASLEEP/PARALYZED/CONFUSED se reemplazan mutuamente
[ ] POISONED/BURNED NO se remueven al aplicar rotación
[ ] Quema: marcador permanece aunque salga Cara
[ ] Parálisis: se cura en EndPhase del PROPIO turno del dueño

VICTORIA:
[ ] Ambos pierden simultáneamente → Muerte Súbita
[ ] Muerte Súbita: 1 premio, nuevo coin flip, setup completo

SEGURIDAD:
[ ] hand del rival: null en getState()
[ ] deck de ambos: null en getState() (solo size)
[ ] prizes de ambos: null en getState() (solo count)
[ ] CARD_DRAWN: evento privado solo al dueño
[ ] Acción fuera de turno: error 403
[ ] REPLACE_ACTIVE_AFTER_KO permitido fuera del turno normal

CASOS BORDE (R-CONCEDE / R-TIMEOUT / R-RECONNECT, ver 07-edge-cases.md):
[ ] CONCEDE-01: POST /api/games/{id}/concede emite GAME_CONCEDED + GAME_OVER
[ ] CONCEDE-02: games.end_reason = 'CONCEDED' tras concesión explícita
[ ] CONCEDE-03: doble concesión simultánea: gana el primero en llegar; segundo recibe 409 ALREADY_OVER
[ ] TIMEOUT-01: timer arranca al emitir TURN_START y se detiene en cualquier acción válida
[ ] TIMEOUT-02: al expirar, motor ejecuta END_TURN automáticamente (excepto si awaitingReplacement)
[ ] TIMEOUT-03: 3 timeouts consecutivos → auto-CONCEDE con games.end_reason = 'TIMEOUT'
[ ] TIMEOUT-04: contador de timeouts se resetea al recibir acción válida
[ ] RECONNECT-01: detección de desconexión vía heartbeat STOMP, ventana 90 s
[ ] RECONNECT-02: durante ventana, partida pausada (timer detenido)
[ ] RECONNECT-03: al reconectar, RECONNECT_SUCCESS al jugador con snapshot completo sanitizado
[ ] RECONNECT-04: ventana vencida → RECONNECT_FAILED + GAME_CONCEDED + GAME_OVER reason=DISCONNECTED
[ ] RECONNECT-05: ventana de 90 s coincide con TTL de presence:<userId> en Redis
[ ] CONCEDE durante setup permitido (antes de GAME_START)
[ ] Doble desconexión simultánea: pausa 90 s, si nadie reconecta ambos pierden (ELO neutral)

ENERGÍAS ESPECIALES (R-ENERGY-SPECIAL, ver 03-combat.md):
[ ] DCE cuenta como 2 Colorless al verificar costo
[ ] DCE NO cubre costos de tipo específico (Fuego, Agua, etc.)
[ ] Rainbow cuenta como 1 unidad de cualquier tipo elegido por costo
[ ] Rainbow aplica 10 daño directo al adherir (sin Debilidad/Resistencia)
[ ] Energías especiales se descartan al KO igual que básicas
[ ] Validación de mazo: máx 4 energías especiales (R-DECK-07)

HABILIDADES (R-ABILITY, ver 02-turn-flow.md):
[ ] Clasificación pasiva vs activada al cargar el Pokémon en juego
[ ] Habilidades activadas: solo ejecutar al recibir USE_ABILITY
[ ] Habilidades pasivas: trigger automático en eventos (POKEMON_PLAYED, DAMAGE_DEALT, etc.)
[ ] Ambos tipos emiten ABILITY_USED al ejecutarse
[ ] Habilidades "once per turn": rastreo en GameContext, reset en TURN_START
```

> **PARTE 2 DEL CHECKLIST:** ver `GAME_ENGINE_DETALLES_PARTE2.md` para los gaps identificados
> vs ryuu-play. Incluye Card Handler Registry, markers, ignoreWeakness/ignoreResistance,
> bloqueo de Items/Supporters, prevención de condiciones especiales y stats dinámicos.
> Esos ítems deben marcarse junto con los de arriba antes de considerar el motor terminado.

---

## Implementación de timers (R-CONCEDE / R-TIMEOUT / R-RECONNECT)

Los temporizadores deben implementarse con scheduling distribuido (compatible con múltiples pods de la API):

- **Turn timer**: job `@Scheduled(fixedRate=1000)` revisa partidas activas con `next_timeout_at < now()` y dispara `TURN_TIMEOUT`. Campo `next_timeout_at` se persiste en `games` y se actualiza al recibir cada acción válida.
- **Reconnect timer**: al detectar desconexión, marcar `games.disconnect_started_at = now()` y `games.disconnected_player_id = userId`. Job `@Scheduled` revisa partidas con `disconnect_started_at + 90s < now()` y dispara `RECONNECT_FAILED`.
- **Lock distribuido (Redis SETNX) sobre `gameId`** evita que dos pods disparen el mismo timeout o doble auto-concede.
- **Detección de desconexión**: usar `SessionDisconnectEvent` de Spring + heartbeat STOMP (intervalo 10s, timeout 30s — ajustar por tipo de match si necesario).

> Estas son guías de implementación. El PASO que implemente concede/timeout/reconnect debe respetar los contratos de eventos y `end_reason` definidos en `07-edge-cases.md`. NO servir código completo aquí — solo el contrato.
