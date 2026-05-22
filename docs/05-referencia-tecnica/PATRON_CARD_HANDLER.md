# PATRON_CARD_HANDLER.md
# Patrón 7 — CARD HANDLER: Lógica por carta individual

Este documento agrega un séptimo patrón a los 6 ya definidos en `PATRONES_DISENO.md`.
Es el **prerequisito** del que dependen los 6 gaps identificados en `GAPS_MOTOR.md`.
Sin este patrón, ninguna carta con lógica especial puede conectarse al pipeline de ataque.

---

## El problema que resuelve

Los 6 patrones actuales (State, Strategy, Chain of Responsibility, Observer, Repository, Facade)
cubren perfectamente la estructura del motor. Sin embargo, dejan un vacío: **no hay mecanismo
para que la lógica de una carta específica (Greninja, Kakuna, Trevenant...) se ejecute
en el momento correcto del pipeline.**

El `EffectStrategyResolver` (Strategy) resuelve efectos *genéricos* detectados por texto
del ataque ("poisoned", "burned", etc.). Pero no puede resolver efectos que dependen de
*cuál carta específica* está en juego.

Ejemplos concretos del problema:
- Cuando Greninja ataca con Mist Slash, necesita setear `ignoreWeakness = true` **antes**
  de que `ApplyWeaknessHandler` corra.
- Cuando Kakuna tiene el marker de Harden activo, necesita interceptar `DealDamageHandler`
  **antes** de que el daño se aplique.
- Cuando Trevenant está como Activo, necesita bloquear `PLAY_ITEM` **antes** de que
  `MainPhaseState` ejecute el efecto del Item.

Ninguno de estos puede resolverse con el `EffectStrategyResolver` genérico porque la
condición no es el texto del ataque, sino el estado de una carta específica en juego.

---

## 7. CARD HANDLER — Lógica por carta individual

### Dónde aplica

Cualquier carta del set XY1 que tenga efectos que no son capturables por el texto del
ataque con parsing genérico. En XY1 eso incluye 26 cartas.

Este patrón **no reemplaza** el Strategy de efectos (veneno, parálisis, etc.) — lo complementa.
El Strategy sigue manejando los efectos genéricos. El Card Handler maneja la lógica que
es específica de una carta individual.

---

### La interfaz CardHandler

```java
// game/engine/cards/CardHandler.java
public interface CardHandler {

    // Identifica qué carta maneja este handler
    String getCardId();  // ej: "xy1-9" para Greninja

    // === HOOKS DEL PIPELINE DE ATAQUE ===

    // Corre ANTES de ApplyWeaknessHandler y ApplyResistanceHandler.
    // Uso: setear ignoreWeakness, ignoreResistance, o daño base adicional.
    default void onBeforeWeaknessCalculation(AttackRequest req, GameContext ctx) {}

    // Corre DESPUÉS de ApplyResistanceHandler, ANTES de DealDamageHandler.
    // Uso: reducir o aumentar el daño final antes de aplicarlo (Furfrou).
    default void onBeforeDamageApplied(AttackRequest req, GameContext ctx) {}

    // Corre DESPUÉS de DealDamageHandler (el daño ya está en el Pokémon).
    // Uso: efectos que reaccionan al daño recibido (Chesnaught Spiky Shield,
    //      Voltorb Destiny Burst).
    default void onAfterDamageApplied(AttackRequest req, GameContext ctx) {}

    // === HOOKS DE ACCIONES DEL TURNO ===

    // Se llama cuando el jugador activo intenta jugar un Item.
    // Lanzar GameActionException para bloquearlo (Trevenant, Krookodile).
    default void onBeforePlayItem(PlayItemContext itemCtx, GameContext ctx) {}

    // Se llama cuando el jugador activo intenta jugar un Supporter.
    // Lanzar GameActionException para bloquearlo (Krookodile Bother).
    default void onBeforePlaySupporter(PlaySupporterContext supporterCtx, GameContext ctx) {}

    // Se llama antes de aplicar una condición especial a un Pokémon.
    // Lanzar GameActionException para bloquearlo (Slurpuff Sweet Veil).
    default void onBeforeApplyStatus(ApplyStatusContext statusCtx, GameContext ctx) {}

    // Se llama antes de que un Pokémon ataque. Permite bloquearlo
    // o restringir qué ataque puede usar (Rhyperior, Xerneas-EX, Simisage).
    default void onBeforeAttackDeclared(AttackValidationContext attackCtx, GameContext ctx) {}

    // Se llama cuando el jugador activo intenta usar una Habilidad activada.
    // Lanzar GameActionException para bloquearla (Arbok Gastro Acid sobre el target afectado).
    default void onBeforeUseAbility(AbilityContext abilityCtx, GameContext ctx) {}

    // === HOOKS DE FIN DE TURNO ===

    // Se llama al terminar el turno del jugador activo (EndPhaseState.onEnter).
    // Uso principal: limpiar markers que duraban "hasta el próximo turno del oponente".
    default void onEndTurn(EndTurnContext endCtx, GameContext ctx) {}

    // === HOOKS DE EVENTOS DE JUEGO ===

    // Se llama cuando ESTE Pokémon (el que maneja este handler) entra en juego
    // como Activo o en Banca.
    default void onPokemonEntersPlay(InPlayPokemon slot, GameContext ctx) {}

    // Se llama cuando ESTE Pokémon es KO.
    // Uso: Voltorb Destiny Burst (flip coin → 5 counters al atacante).
    default void onKnockedOut(KnockOutContext koCtx, GameContext ctx) {}
}
```

**Por qué default vacío y no abstracto:** cada carta solo implementa los hooks que necesita.
Greninja solo implementa `onBeforeWeaknessCalculation`. Trevenant solo implementa
`onBeforePlayItem`. No tiene sentido obligar a todas las cartas a implementar todos los hooks.

---

### CardHandlerRegistry

El registro mapea `cardId → handler`. El motor lo consulta en cada punto de extensión
del pipeline para saber si alguna carta en juego tiene lógica para ese hook.

```java
// game/engine/cards/CardHandlerRegistry.java
@Component
public class CardHandlerRegistry {

    // Map: cardId → implementación del handler
    private final Map<String, CardHandler> handlersByCardId;

    // Inyección por constructor: Spring detecta todos los @Component que
    // implementan CardHandler y los inyecta en la lista automáticamente.
    public CardHandlerRegistry(List<CardHandler> allHandlers) {
        this.handlersByCardId = allHandlers.stream()
            .collect(Collectors.toMap(CardHandler::getCardId, h -> h));
    }

    // Retorna el handler para una carta dada, o un NoOpHandler si no existe.
    public CardHandler getHandler(String cardId) {
        return handlersByCardId.getOrDefault(cardId, NoOpCardHandler.INSTANCE);
    }

    // Retorna todos los handlers de las cartas actualmente en juego en un board.
    // Usado por el pipeline para propagar eventos a todas las cartas activas.
    public List<CardHandler> getActiveHandlers(GameBoard board) {
        return board.getAllCardsInPlay().stream()
            .map(cardId -> getHandler(cardId))
            .filter(h -> !(h instanceof NoOpCardHandler))
            .collect(Collectors.toList());
    }
}
```

El `NoOpCardHandler` es un handler vacío que implementa todos los métodos como no-ops:

```java
// game/engine/cards/NoOpCardHandler.java
public final class NoOpCardHandler implements CardHandler {
    public static final NoOpCardHandler INSTANCE = new NoOpCardHandler();
    private NoOpCardHandler() {}

    @Override public String getCardId() { return ""; }
    // Todos los hooks son no-ops por el default de la interfaz.
}
```

---

### Cómo se registra una carta

Cada carta con lógica especial crea una clase que implementa `CardHandler` y se anota
con `@Component`. Spring la detecta automáticamente y el `CardHandlerRegistry` la registra.

```java
// game/engine/cards/xy1/GreninjaMistSlashHandler.java
@Component
public class GreninjaMistSlashHandler implements CardHandler {

    @Override
    public String getCardId() {
        return "xy1-9";  // ID de Greninja en el JSON del set XY1
    }

    @Override
    public void onBeforeWeaknessCalculation(AttackRequest req, GameContext ctx) {
        // Solo actuar si el atacante ES este Greninja
        if (!req.getAttackerCardId().equals(getCardId())) return;
        // Solo actuar si el ataque es Mist Slash
        if (!req.getAttack().getName().equals("Mist Slash")) return;

        req.setIgnoreWeakness(true);
        req.setIgnoreResistance(true);
        req.setIgnoreDefenderEffects(true); // "any other effects on your opponent's Active Pokémon"
    }
}
```

---

### Integración con el AttackPipeline

El pipeline existente se extiende con **dos nuevos handlers** que propagan a los handlers
de cartas en los momentos correctos.

```
ANTES: Validate → BaseDamage → ApplyWeakness → ApplyResistance
       → DealDamage → ExecuteEffect → CheckKnockout

DESPUÉS: Validate → BaseDamage → [CardEffectsPreWeakness] → ApplyWeakness → ApplyResistance
         → [CardEffectsPreDamage] → DealDamage → ExecuteEffect → [CardEffectsPostDamage]
         → CheckKnockout
```

Los tres nuevos handlers (marcados con `[ ]`) llaman al registry y propagan el evento:

```java
// game/engine/pipeline/handlers/CardEffectsPreWeaknessHandler.java
public class CardEffectsPreWeaknessHandler extends AttackHandler {

    @Autowired CardHandlerRegistry registry;

    @Override
    public AttackResult handle(AttackRequest req) {
        // Propagar a todos los handlers de cartas actualmente en juego
        List<CardHandler> active = registry.getActiveHandlers(req.getContext().getBoard());
        for (CardHandler handler : active) {
            handler.onBeforeWeaknessCalculation(req, req.getContext());
        }
        return proceed(req);  // continuar con ApplyWeaknessHandler
    }
}

// game/engine/pipeline/handlers/CardEffectsPreDamageHandler.java
public class CardEffectsPreDamageHandler extends AttackHandler {

    @Autowired CardHandlerRegistry registry;

    @Override
    public AttackResult handle(AttackRequest req) {
        List<CardHandler> active = registry.getActiveHandlers(req.getContext().getBoard());
        for (CardHandler handler : active) {
            handler.onBeforeDamageApplied(req, req.getContext());
        }
        return proceed(req);  // continuar con DealDamageHandler
    }
}

// game/engine/pipeline/handlers/CardEffectsPostDamageHandler.java
public class CardEffectsPostDamageHandler extends AttackHandler {

    @Autowired CardHandlerRegistry registry;

    @Override
    public AttackResult handle(AttackRequest req) {
        List<CardHandler> active = registry.getActiveHandlers(req.getContext().getBoard());
        for (CardHandler handler : active) {
            handler.onAfterDamageApplied(req, req.getContext());
        }
        return proceed(req);  // continuar con CheckKnockoutHandler
    }
}
```

Actualizar `AttackPipeline.buildChain()`:

```java
@PostConstruct
public void buildChain() {
    validateHandler
        .setNext(baseDamageHandler)
        .setNext(cardEffectsPreWeaknessHandler)   // NUEVO
        .setNext(weaknessHandler)
        .setNext(resistanceHandler)
        .setNext(cardEffectsPreDamageHandler)      // NUEVO
        .setNext(dealDamageHandler)
        .setNext(effectHandler)
        .setNext(cardEffectsPostDamageHandler)     // NUEVO
        .setNext(knockoutHandler);
}
```

---

### Integración con MainPhaseState

`MainPhaseState.handleAction()` propaga a los handlers antes de ejecutar cada tipo de acción:

```java
// Fragmento de MainPhaseState.handleAction() — agregar propagación
case PLAY_TRAINER -> {
    TrainerAction trainerAction = (TrainerAction) action;

    if (trainerAction.getTrainerType() == TrainerType.ITEM) {
        // Propagar onBeforePlayItem a todas las cartas en juego
        PlayItemContext itemCtx = new PlayItemContext(ctx.getCurrentPlayer(), trainerAction);
        registry.getActiveHandlers(ctx.getBoard())
                .forEach(h -> h.onBeforePlayItem(itemCtx, ctx));
        // Si algún handler lanzó excepción → acción bloqueada, no llega acá
    }

    if (trainerAction.getTrainerType() == TrainerType.SUPPORTER) {
        PlaySupporterContext suppCtx = new PlaySupporterContext(ctx.getCurrentPlayer(), trainerAction);
        registry.getActiveHandlers(ctx.getBoard())
                .forEach(h -> h.onBeforePlaySupporter(suppCtx, ctx));
    }

    handleTrainer(ctx, trainerAction);
}

case DECLARE_ATTACK -> {
    AttackValidationContext attackCtx = new AttackValidationContext(ctx.getCurrentPlayer(), action);
    registry.getActiveHandlers(ctx.getBoard())
            .forEach(h -> h.onBeforeAttackDeclared(attackCtx, ctx));
    // Si algún handler bloqueó → excepción antes de llegar a AttackPhaseState

    ctx.transitionTo(new AttackPhaseState(action));
}
```

---

### Integración con StatusEffectManager

```java
// game/engine/damage/StatusEffectManager.java
@Component
public class StatusEffectManager {

    @Autowired CardHandlerRegistry registry;

    public void applyStatus(InPlayPokemon target, SpecialCondition condition, GameContext ctx) {
        // Propagar a todos los handlers — alguno puede bloquear (Slurpuff)
        ApplyStatusContext statusCtx = new ApplyStatusContext(target, condition);
        registry.getActiveHandlers(ctx.getBoard())
                .forEach(h -> h.onBeforeApplyStatus(statusCtx, ctx));

        if (statusCtx.isBlocked()) {
            // Publicar evento STATUS_BLOCKED si querés mostrarlo en el cliente
            return;
        }

        // Aplicar la condición normalmente
        target.addSpecialCondition(condition);
        ctx.getEventPublisher().publish(new StatusAppliedEvent(target, condition));
    }
}
```

---

### Integración con EndPhaseState

```java
// game/engine/state/EndPhaseState.java
@Override
public void onEnter(GameContext ctx) {
    PlayerBoard currentPlayer = ctx.getCurrentPlayer();

    // 1. Curar Paralizado (regla base — ya estaba)
    currentPlayer.getActive().removeSpecialCondition(SpecialCondition.PARALYZED);

    // 2. Propagar onEndTurn a todos los handlers (para limpieza de markers)
    EndTurnContext endCtx = new EndTurnContext(currentPlayer);
    registry.getActiveHandlers(ctx.getBoard())
            .forEach(h -> h.onEndTurn(endCtx, ctx));

    // 3. Condiciones especiales entre turnos (Poison, Burn, Sleep — ya estaba)
    processBetweenTurnsConditions(ctx);

    // 4. Cambiar jugador activo
    ctx.switchActivePlayer();
    ctx.transitionTo(new DrawPhaseState());
}
```

---

### Lifecycle: cuándo registrar y desregistrar

El `CardHandlerRegistry` es un singleton de Spring — siempre tiene todos los handlers
disponibles. Lo que varía es `getActiveHandlers(board)` que filtra solo los que están
en juego en ese momento.

`board.getAllCardsInPlay()` debe devolver los `cardId` de:
- Pokémon Activo (ambos jugadores)
- Pokémon en Banca (ambos jugadores)
- Stadium activo
- Supporters en zona de supporter (antes de descartarse)
- Tools adjuntas a Pokémon en juego

Cuando un Pokémon es KO, sus cartas se van al descarte y `getAllCardsInPlay()` ya no
las incluye → el handler deja de propagarse automáticamente. No hace falta "desregistrar".

---

### Contextos de propagación

Cada hook recibe un objeto de contexto que encapsula lo que puede modificar:

```java
// AttackRequest — ya existía, se extiende:
//   + boolean ignoreWeakness = false
//   + boolean ignoreResistance = false
//   + boolean ignoreDefenderEffects = false
//   + String attackerCardId   (nuevo campo para que los handlers sepan quién ataca)

// PlayItemContext — nuevo:
public class PlayItemContext {
    private PlayerBoard player;      // el que juega el Item
    private TrainerAction action;    // cuál Item
    // Las exceptions son el mecanismo de bloqueo (no un flag booleano)
    // Si el handler no lanza excepción, el Item se juega normalmente.
}

// PlaySupporterContext — nuevo (misma idea)
// AttackValidationContext — nuevo

// AbilityContext — nuevo:
public class AbilityContext {
    private PlayerBoard player;     // jugador que usa la habilidad
    private TrainerAction action;   // acción USE_ABILITY (incluye targetPokemonId, abilityName)
    // Bloqueo vía exception (igual que onBeforePlayItem)
    // Si el handler no lanza excepción, la habilidad se usa normalmente.
}

// ApplyStatusContext — nuevo:
public class ApplyStatusContext {
    private InPlayPokemon target;
    private SpecialCondition condition;
    private boolean blocked = false;    // aquí sí es flag porque no queremos exception
    public void setBlocked(boolean b) { this.blocked = b; }
    public boolean isBlocked() { return blocked; }
}

// EndTurnContext — nuevo:
public class EndTurnContext {
    private PlayerBoard activePlayer;   // el jugador que termina su turno
}

// KnockOutContext — nuevo:
public class KnockOutContext {
    private InPlayPokemon knockedOut;
    private InPlayPokemon attacker;     // el que hizo el KO (puede ser null si fue veneno)
    private GameContext ctx;
}
```

---

### Estructura de paquetes

```
game/engine/cards/
├── CardHandler.java                  ← interfaz con todos los hooks
├── NoOpCardHandler.java              ← implementación vacía (singleton)
├── CardHandlerRegistry.java          ← detecta y registra todos los handlers
├── context/
│   ├── PlayItemContext.java
│   ├── PlaySupporterContext.java
│   ├── AttackValidationContext.java
│   ├── AbilityContext.java
│   ├── ApplyStatusContext.java
│   ├── EndTurnContext.java
│   └── KnockOutContext.java
└── xy1/                              ← un handler por carta con lógica especial
    ├── GreninjaMistSlashHandler.java
    ├── KakunaHardenHandler.java
    ├── QuillaScrunchHandler.java
    ├── RhyperiorRockWreckerHandler.java
    ├── AegislashKingsShieldHandler.java
    ├── BeedrilFlashNeedleHandler.java
    ├── WigglytuffHocusPinkusHandler.java
    ├── BunnelbyDigHandler.java
    ├── DiggersByDigHandler.java
    ├── LunatoneMoonblastHandler.java
    ├── SimisageTormentHandler.java
    ├── YveltalDarknessBladeHandler.java
    ├── XerneasXBlastHandler.java
    ├── BisharpMetalWallopHandler.java
    ├── MalamarMentalPanicHandler.java
    ├── ScolipedePoisonRingHandler.java
    ├── ZoroarkCornerHandler.java
    ├── ArbokGastroAcidHandler.java
    ├── DugtrigoRockTumbleHandler.java
    ├── InkayPunctureHandler.java
    ├── MalamarPunctureHandler.java
    ├── AegislashBusterSwingHandler.java
    ├── TreevenantForestsCurseHandler.java
    ├── KrookodileBotherHandler.java
    ├── SlurpuffSweetVeilHandler.java
    ├── ChesnaughtSpikysShieldHandler.java
    ├── VoltorbDestinyBurstHandler.java
    └── FurfouFurCoatHandler.java
```

---

### Cómo fluye un ataque con este patrón (todos juntos)

```
Controller.processAction(gameId, playerId, ATTACK "Mist Slash")
    ↓
GameEngine.processAction()                          [FACADE]
    ↓
MainPhaseState.handleAction(DECLARE_ATTACK)         [STATE]
    → registry.getActiveHandlers() → onBeforeAttackDeclared()
    → ningún handler bloquea el ataque
    → ctx.transitionTo(AttackPhaseState)
    ↓
AttackPipeline.process(request)                     [CHAIN OF RESPONSIBILITY]
    ├── ValidateAttackHandler         → ¿tiene energías? ¿no está paralizado?
    ├── CalculateBaseDamageHandler    → baseDamage = 60
    ├── CardEffectsPreWeaknessHandler → llama a GreninjaMistSlashHandler
    │       → request.setIgnoreWeakness(true)
    │       → request.setIgnoreResistance(true)
    ├── ApplyWeaknessHandler          → flag=true → SKIP
    ├── ApplyResistanceHandler        → flag=true → SKIP
    ├── CardEffectsPreDamageHandler   → ningún handler activo modifica (Furfrou no está)
    ├── DealDamageHandler             → defensor recibe 60 de daño
    ├── ExecuteAttackEffectHandler    → Mist Slash no tiene efecto adicional → Strategy NoOp
    ├── CardEffectsPostDamageHandler  → ningún handler reacciona al daño
    └── CheckKnockoutHandler          → ¿HP <= 0? → KO si aplica
    ↓
GameEventPublisher.publish(DAMAGE_DEALT, POKEMON_KO...)   [OBSERVER]
GameEngine.snapshotService.save(ctx)
```

---

### Relación con los 6 patrones existentes

Este patrón **no reemplaza** ninguno de los 6 — los complementa:

| Patrón existente | Sigue haciendo | Card Handler agrega |
|---|---|---|
| Strategy (EffectStrategyResolver) | Efectos genéricos por texto (poison, paralyze) | Lógica específica de carta |
| Chain of Responsibility (AttackPipeline) | Orden de pasos de ataque | Nuevos handlers de propagación |
| Observer (GameEventPublisher) | Notifica WebSocket, log, métricas | Cartas pueden reaccionar a eventos |
| State (DrawPhaseState etc.) | Flujo del turno | Hooks antes de cada transición |
| Facade (GameEngine) | Punto único de entrada | Sin cambios |
| Repository | Acceso a datos | Sin cambios |

---

### Mecanismos de bloqueo: excepción vs flag

El patrón usa dos mecanismos distintos según la naturaleza del bloqueo. Esta tabla es **canónica** — cualquier hook nuevo debe alinearse con uno de los dos.

| Mecanismo | Cuándo usarlo | Hooks que lo usan | Ejemplo | Razón |
|---|---|---|---|---|
| **Lanzar `GameActionException`** | Acción del jugador activo que NO debe ejecutarse y debe llegar al cliente como error | `onBeforePlayItem`, `onBeforePlaySupporter`, `onBeforeUseAbility`, `onBeforeAttackDeclared` | Trevenant Forest's Curse: "no podés jugar Items mientras Trevenant es el Activo del oponente" | El jugador intentó algo ilegal en ese momento; corresponde mostrar mensaje de error en la UI |
| **Setear flag en el contexto (`ctx.setBlocked(true)`)** | Efecto del oponente que se intenta aplicar pero el target es inmune; no es error del jugador | `onBeforeApplyStatus` | Slurpuff Sweet Veil: el ataque del oponente se ejecutó normalmente, solo el efecto secundario no aplica | La UI muestra leyenda informativa ("It doesn't affect [name]!"), no un error |
| **Modificar el `AttackRequest` directamente** | Ajuste de daño o flags de cálculo, no un bloqueo per se | `onBeforeWeaknessCalculation`, `onBeforeDamageApplied`, `onAfterDamageApplied` | Greninja setea `ignoreWeakness=true`; Furfrou resta 20 al daño; Chesnaught suma contadores al atacante | No se bloquea nada; el pipeline sigue, solo cambia el valor calculado |

**Regla rápida:** si la acción la origina el JUGADOR ACTIVO sobre su propio tablero → excepción. Si la acción la origina el OPONENTE sobre el target del defensor y el bloqueo es pasivo → flag. Si solo se ajusta un valor sin abortar nada → modificar `AttackRequest`.

---

## RESUMEN: qué hay que agregar al diseño existente

```
NUEVO PATRÓN — Card Handler:
[ ] Interfaz CardHandler con todos los hooks (default vacíos)
[ ] CardHandler.onBeforeUseAbility hook agregado a la interfaz
[ ] NoOpCardHandler singleton
[ ] CardHandlerRegistry con @Component auto-detection
[ ] context/ con PlayItemContext, ApplyStatusContext, AbilityContext, etc.
[ ] AbilityContext.java en game/engine/cards/context/
[ ] AttackRequest extendido: + ignoreWeakness, ignoreResistance, ignoreDefenderEffects, attackerCardId
[ ] Documentado cuándo lanzar excepción vs setear flag (sección "Mecanismos de bloqueo")

NUEVOS HANDLERS EN EL PIPELINE:
[ ] CardEffectsPreWeaknessHandler (entre BaseDamage y ApplyWeakness)
[ ] CardEffectsPreDamageHandler (entre ApplyResistance y DealDamage)
[ ] CardEffectsPostDamageHandler (entre ExecuteEffect y CheckKnockout)
[ ] AttackPipeline.buildChain() actualizado con los 3 nuevos handlers

INTEGRACIONES EN ESTADOS Y SERVICIOS:
[ ] MainPhaseState propaga onBeforePlayItem antes de handleTrainer (Items)
[ ] MainPhaseState propaga onBeforePlaySupporter antes de handleTrainer (Supporters)
[ ] MainPhaseState propaga onBeforeAttackDeclared antes de transicionar a AttackPhaseState
[ ] MainPhaseState propaga onBeforeUseAbility antes de ejecutar USE_ABILITY (Arbok)
[ ] StatusEffectManager propaga onBeforeApplyStatus antes de addSpecialCondition; emite STATUS_BLOCKED si ctx.isBlocked()
[ ] EndPhaseState propaga onEndTurn antes de cambiar jugador activo
[ ] KO handler propaga onKnockedOut después de determinar el KO

HANDLERS DE CARTAS XY1 (26 cartas — ver GAPS_MOTOR.md para detalle de cada una):
[ ] Un @Component por carta con lógica especial
[ ] Todos en game/engine/cards/xy1/
```
