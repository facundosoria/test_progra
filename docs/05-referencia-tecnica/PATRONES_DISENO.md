# PATRONES_DISENO.md
# Patrones de diseño requeridos por RNF-04

Este documento cubre los 7 patrones de diseño del motor de Codemon.
Los primeros 6 son obligatorios por RNF-04. El séptimo es prerequisito de las cartas con lógica especial.

> **Nuevo:** Patrón 7 — CARD HANDLER documentado en `PATRON_CARD_HANDLER.md` (misma carpeta).
> Sin ese patrón, 26 cartas de XY1 no pueden implementarse correctamente (ver `GAME_ENGINE_DETALLES_PARTE2.md`).

---

## 1. STATE — Estados de turno y partida

### Dónde aplica
El juego tiene dos jerarquías de estado: la partida y el turno dentro de la partida.

### Estados de partida
```
WAITING → SETUP → ACTIVE → FINISHED
                          → ABANDONED
```

### Estados del turno (dentro de ACTIVE)
```
DRAW_PHASE → MAIN_PHASE → ATTACK_PHASE → END_PHASE
```

### Cómo implementarlo en Java

Crear `game/engine/state/GameState.java` como interfaz:

```java
public interface GameState {
    void onEnter(GameContext context);
    void handleAction(GameContext context, GameAction action);
    void onExit(GameContext context);
    String getName();
}
```

Implementaciones concretas:

```java
// game/engine/state/DrawPhaseState.java
public class DrawPhaseState implements GameState {
    @Override
    public void onEnter(GameContext ctx) {
        // Robar 1 carta al inicio del turno
        ctx.getCurrentPlayer().drawCard();
        // Publicar evento CARD_DRAWN
    }

    @Override
    public void handleAction(GameContext ctx, GameAction action) {
        // En draw phase solo se puede continuar
        if (action.getType() == ActionType.CONFIRM_DRAW) {
            ctx.transitionTo(new MainPhaseState());
        }
    }
}

// game/engine/state/MainPhaseState.java
public class MainPhaseState implements GameState {
    @Override
    public void handleAction(GameContext ctx, GameAction action) {
        switch (action.getType()) {
            case PLAY_BASIC_POKEMON   -> handlePlayBasic(ctx, action);
            case EVOLVE_POKEMON       -> handleEvolve(ctx, action);
            case ATTACH_ENERGY        -> handleEnergy(ctx, action);
            case PLAY_TRAINER         -> handleTrainer(ctx, action);
            case RETREAT              -> handleRetreat(ctx, action);
            case USE_ABILITY          -> handleAbility(ctx, action);
            case DECLARE_ATTACK       -> ctx.transitionTo(new AttackPhaseState(action));
            case END_TURN             -> ctx.transitionTo(new EndPhaseState());
        }
    }
}

// game/engine/state/AttackPhaseState.java
public class AttackPhaseState implements GameState {
    // ...resolución del ataque (delega a AttackPipeline)
}

// game/engine/state/EndPhaseState.java
public class EndPhaseState implements GameState {
    @Override
    public void onEnter(GameContext ctx) {
        // Aplicar efectos de fin de turno (Burn, Poison, etc.)
        // Curar Paralyze
        // Cambiar jugador activo
        ctx.transitionTo(new DrawPhaseState());
    }
}
```

### GameContext (el objeto que viaja entre estados)
```java
@Component
public class GameContext {
    private GameState currentState;
    private GameBoard board;
    private Long gameId;

    public void transitionTo(GameState newState) {
        if (currentState != null) currentState.onExit(this);
        this.currentState = newState;
        newState.onEnter(this);
    }

    public void handleAction(GameAction action) {
        currentState.handleAction(this, action);
    }
}
```

### Estructura de paquetes
```
game/engine/state/
├── GameState.java             (interfaz)
├── GameContext.java           (contexto)
├── DrawPhaseState.java
├── MainPhaseState.java
├── AttackPhaseState.java
└── EndPhaseState.java
```

---

## 2. STRATEGY — Efectos de ataques y condiciones especiales

### Dónde aplica
Cada ataque puede tener un efecto distinto: veneno, parálisis, daño extra, curar, etc.
El patrón Strategy permite agregar efectos nuevos sin modificar el código existente.

### Interfaz

```java
// game/engine/strategy/AttackEffectStrategy.java
public interface AttackEffectStrategy {
    void apply(GameContext context, Pokemon attacker, Pokemon defender);
    boolean canApply(Attack attack);   // para seleccionar la estrategia correcta
}
```

### Implementaciones concretas

```java
// game/engine/strategy/effects/PoisonEffectStrategy.java
public class PoisonEffectStrategy implements AttackEffectStrategy {
    @Override
    public void apply(GameContext ctx, Pokemon attacker, Pokemon defender) {
        defender.applyStatus(StatusCondition.POISONED);
        ctx.publishEvent(new StatusAppliedEvent(defender.getId(), "POISONED"));
    }

    @Override
    public boolean canApply(Attack attack) {
        return attack.getText() != null &&
               attack.getText().toLowerCase().contains("poisoned");
    }
}

// game/engine/strategy/effects/ParalyzeEffectStrategy.java
public class ParalyzeEffectStrategy implements AttackEffectStrategy {
    @Override
    public void apply(GameContext ctx, Pokemon attacker, Pokemon defender) {
        defender.applyStatus(StatusCondition.PARALYZED);
        ctx.publishEvent(new StatusAppliedEvent(defender.getId(), "PARALYZED"));
    }

    @Override
    public boolean canApply(Attack attack) {
        return attack.getText() != null &&
               attack.getText().toLowerCase().contains("paralyzed");
    }
}

// game/engine/strategy/effects/BurnEffectStrategy.java
// game/engine/strategy/effects/SleepEffectStrategy.java
// game/engine/strategy/effects/ConfuseEffectStrategy.java
// game/engine/strategy/effects/ExtraDamageEffectStrategy.java   (daño "+ X")
// game/engine/strategy/effects/HealEffectStrategy.java
// game/engine/strategy/effects/NoEffectStrategy.java  (ataque sin efecto)
```

### EffectStrategyResolver (selecciona la estrategia)
```java
@Component
public class EffectStrategyResolver {

    private final List<AttackEffectStrategy> strategies;

    public EffectStrategyResolver(List<AttackEffectStrategy> strategies) {
        this.strategies = strategies;
    }

    public AttackEffectStrategy resolve(Attack attack) {
        return strategies.stream()
            .filter(s -> s.canApply(attack))
            .findFirst()
            .orElse(new NoEffectStrategy());
    }
}
```

### Estructura de paquetes
```
game/engine/strategy/
├── AttackEffectStrategy.java      (interfaz)
├── EffectStrategyResolver.java
└── effects/
    ├── PoisonEffectStrategy.java
    ├── ParalyzeEffectStrategy.java
    ├── BurnEffectStrategy.java
    ├── SleepEffectStrategy.java
    ├── ConfuseEffectStrategy.java
    ├── ExtraDamageEffectStrategy.java
    ├── HealEffectStrategy.java
    └── NoEffectStrategy.java
```

---

## 3. CHAIN OF RESPONSIBILITY — Pipeline de ataque

### Dónde aplica
Un ataque pasa por una cadena de pasos en orden: validar → calcular daño → aplicar debilidad → aplicar resistencia → aplicar daño → ejecutar efecto → verificar KO.
Cada eslabón puede modificar el resultado o detener la cadena.

### Interfaz

```java
// game/engine/pipeline/AttackHandler.java
public abstract class AttackHandler {
    protected AttackHandler next;

    public AttackHandler setNext(AttackHandler next) {
        this.next = next;
        return next;
    }

    public abstract AttackResult handle(AttackRequest request);

    protected AttackResult proceed(AttackRequest request) {
        if (next != null) return next.handle(request);
        return request.getResult();
    }
}
```

### Eslabones de la cadena

```java
// game/engine/pipeline/handlers/ValidateAttackHandler.java
public class ValidateAttackHandler extends AttackHandler {
    @Autowired RuleValidator ruleValidator;

    @Override
    public AttackResult handle(AttackRequest req) {
        // ¿Puede atacar? ¿Tiene energías? ¿Es su turno? ¿No está paralizado/dormido?
        ValidationResult validation = ruleValidator.canAttack(req.getContext(), req.getAttack());
        if (!validation.isValid()) {
            return AttackResult.invalid(validation.getError());
        }
        return proceed(req);   // siguiente eslabón
    }
}

// game/engine/pipeline/handlers/CalculateBaseDamageHandler.java
public class CalculateBaseDamageHandler extends AttackHandler {
    @Override
    public AttackResult handle(AttackRequest req) {
        int damage = req.getAttack().getParsedDamage();
        req.getResult().setBaseDamage(damage);
        return proceed(req);
    }
}

// game/engine/pipeline/handlers/ApplyWeaknessHandler.java
public class ApplyWeaknessHandler extends AttackHandler {
    @Autowired DamageCalculator damageCalc;

    @Override
    public AttackResult handle(AttackRequest req) {
        // Si el defensor tiene weakness al tipo del atacante → daño ×2
        int damage = damageCalc.applyWeakness(
            req.getResult().getCurrentDamage(),
            req.getAttacker().getTypes(),
            req.getDefender().getWeaknesses()
        );
        req.getResult().setCurrentDamage(damage);
        return proceed(req);
    }
}

// game/engine/pipeline/handlers/ApplyResistanceHandler.java
// game/engine/pipeline/handlers/ApplyDefenderEffectsHandler.java     (Furfrou Fur Coat -20, propaga onBeforeDamageApplied)
// game/engine/pipeline/handlers/DealDamageHandler.java               (aplica el daño final)
// game/engine/pipeline/handlers/ExecuteAttackEffectHandler.java      (Poison, Paralyze, etc.)
// game/engine/pipeline/handlers/CardEffectsPostDamageHandler.java    (propaga onAfterDamageApplied)
// game/engine/pipeline/handlers/CheckKnockoutHandler.java            (HP <= 0 → KO)
```

### AttackPipeline (arma la cadena)

> **Actualizado:** La cadena ahora incluye 3 handlers de Card Handler (ver `PATRON_CARD_HANDLER.md`).
> `ApplyAttackerEffectsHandler` y `ApplyDefenderEffectsHandler` propagan al `CardHandlerRegistry`.

```java
@Component
public class AttackPipeline {

    @Autowired ValidateAttackHandler validateHandler;
    @Autowired CalculateBaseDamageHandler baseDamageHandler;
    @Autowired ApplyAttackerEffectsHandler attackerEffectsHandler; // llama CardHandlerRegistry.onBeforeWeaknessCalculation
    @Autowired ApplyWeaknessHandler weaknessHandler;               // respeta request.isIgnoreWeakness()
    @Autowired ApplyResistanceHandler resistanceHandler;           // respeta request.isIgnoreResistance()
    @Autowired ApplyDefenderEffectsHandler defenderEffectsHandler; // llama CardHandlerRegistry.onBeforeDamageApplied
    @Autowired DealDamageHandler dealDamageHandler;
    @Autowired ExecuteAttackEffectHandler effectHandler;
    @Autowired CardEffectsPostDamageHandler postDamageHandler;     // llama CardHandlerRegistry.onAfterDamageApplied
    @Autowired CheckKnockoutHandler knockoutHandler;

    @PostConstruct
    public void buildChain() {
        validateHandler
            .setNext(baseDamageHandler)
            .setNext(attackerEffectsHandler)   // NUEVO: ignoreWeakness/ignoreResistance se setean acá
            .setNext(weaknessHandler)
            .setNext(resistanceHandler)
            .setNext(defenderEffectsHandler)   // NUEVO: Furfrou -20, efectos del defensor
            .setNext(dealDamageHandler)
            .setNext(effectHandler)
            .setNext(postDamageHandler)        // NUEVO: Chesnaught Spiky Shield, Voltorb Destiny Burst
            .setNext(knockoutHandler);
    }

    public AttackResult process(AttackRequest request) {
        return validateHandler.handle(request);
    }
}
```

### Estructura de paquetes
```
game/engine/pipeline/
├── AttackHandler.java                (abstracta)
├── AttackPipeline.java               (arma la cadena)
├── AttackRequest.java                (datos de entrada — ver campos nuevos abajo)
├── AttackResult.java                 (resultado acumulado)
└── handlers/
    ├── ValidateAttackHandler.java
    ├── CalculateBaseDamageHandler.java
    ├── ApplyAttackerEffectsHandler.java   ← propaga onBeforeWeaknessCalculation al registry
    ├── ApplyWeaknessHandler.java          ← chequea request.isIgnoreWeakness() antes de calcular
    ├── ApplyResistanceHandler.java        ← chequea request.isIgnoreResistance() antes de calcular
    ├── ApplyDefenderEffectsHandler.java   ← propaga onBeforeDamageApplied (si !ignoreDefenderEffects)
    ├── DealDamageHandler.java
    ├── ExecuteAttackEffectHandler.java
    ├── CardEffectsPostDamageHandler.java  ← propaga onAfterDamageApplied al registry
    └── CheckKnockoutHandler.java

game/engine/cards/                         ← VER PATRON_CARD_HANDLER.md
├── CardHandler.java                  (interfaz con hooks)
├── NoOpCardHandler.java
├── CardHandlerRegistry.java
├── context/                          (PlayItemContext, ApplyStatusContext, etc.)
└── xy1/                              (26 handlers de cartas XY1 con lógica especial)
```

**Campos nuevos en `AttackRequest`:**
```java
// Setean los handlers de cartas en ApplyAttackerEffectsHandler
boolean ignoreWeakness = false;         // Greninja, Rhyperior, etc.
boolean ignoreResistance = false;       // Dugtrio, Inkay, etc.
boolean ignoreDefenderEffects = false;  // Greninja Mist Slash ("any other effects")
String attackerCardId;                  // para que handlers sepan quién ataca
```

---

## 4. OBSERVER — Eventos WebSocket

### Dónde aplica
Cuando ocurre un evento en el juego (KO, daño, turno nuevo, etc.), múltiples partes necesitan enterarse: WebSocket para el cliente, el sistema de log, las métricas de Grafana.

### Interfaz

```java
// game/engine/observer/GameEventListener.java
public interface GameEventListener {
    void onEvent(GameEvent event);
    boolean supports(String eventType);
}
```

### Implementaciones

```java
// game/engine/observer/WebSocketEventListener.java
@Component
public class WebSocketEventListener implements GameEventListener {
    @Autowired SimpMessagingTemplate messagingTemplate;

    @Override
    public void onEvent(GameEvent event) {
        // Publicar al canal correcto según el tipo de evento
        String destination = resolveDestination(event);
        messagingTemplate.convertAndSend(destination, event.toDTO());
    }

    @Override
    public boolean supports(String eventType) {
        return true;   // todos los eventos van a WebSocket
    }

    private String resolveDestination(GameEvent event) {
        return "/topic/game/" + event.getGameId();
    }
}

// game/engine/observer/GameLogEventListener.java
@Component
public class GameLogEventListener implements GameEventListener {
    @Autowired GameEventRepository eventRepo;

    @Override
    public void onEvent(GameEvent event) {
        // Persistir en game_events (log inmutable)
        eventRepo.save(GameEventEntity.from(event));
    }

    @Override
    public boolean supports(String eventType) {
        return true;   // todos los eventos se loggean
    }
}

// game/engine/observer/MetricsEventListener.java
@Component
public class MetricsEventListener implements GameEventListener {
    @Autowired CodemonMetrics metrics;

    @Override
    public void onEvent(GameEvent event) {
        switch (event.getType()) {
            case "POKEMON_KO"  -> metrics.recordKO();
            case "GAME_OVER"   -> metrics.recordGameFinished(event.getResult(), event.getDuration());
        }
    }

    @Override
    public boolean supports(String eventType) {
        return List.of("POKEMON_KO", "GAME_OVER", "PRIZE_TAKEN").contains(eventType);
    }
}
```

### GameEventPublisher (el sujeto observado)
```java
@Component
public class GameEventPublisher {

    private final List<GameEventListener> listeners;

    public GameEventPublisher(List<GameEventListener> listeners) {
        this.listeners = listeners;
    }

    public void publish(GameEvent event) {
        listeners.stream()
            .filter(l -> l.supports(event.getType()))
            .forEach(l -> l.onEvent(event));
    }
}
```

### Seguridad WebSocket (RNF-05)
El `WebSocketEventListener` NUNCA incluye estos datos en los eventos broadcast:
- Mano del jugador → se envía SOLO al usuario dueño vía `/user/queue/game`
- Orden del mazo → NUNCA se envía
- Cartas de premios → NUNCA se envían (solo la cantidad)

```java
// Evento broadcast (visible para ambos jugadores)
@Data
public class GameEventDTO {
    private String eventType;
    private Long gameId;
    private Object payload;    // datos públicos: daño, KO, turno, etc.
    // SIN: hand, deckOrder, prizes
}

// Evento privado (solo para el dueño)
// Enviado a: /user/{userId}/queue/game
@Data
public class PrivateGameEventDTO {
    private String eventType;
    private List<CardDTO> drawnCards;   // solo lo que el usuario puede ver
}
```

### Estructura de paquetes
```
game/engine/observer/
├── GameEventListener.java        (interfaz)
├── GameEventPublisher.java       (sujeto)
├── WebSocketEventListener.java
├── GameLogEventListener.java
└── MetricsEventListener.java
```

---

## 5. REPOSITORY — Acceso a datos

### Dónde aplica
Todos los accesos a la base de datos van a través de interfaces Repository, nunca con SQL directo en los servicios.

### Patrón ya cubierto en ESTRUCTURA_PROYECTO.md

Todos los dominios tienen su `repository/` con interfaces que extienden `JpaRepository<Entity, Long>`.

```java
// Ejemplo: auth/repository/UserRepository.java
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    Optional<User> findByUsername(String username);
    boolean existsByEmail(String email);
}

// Ejemplo: game/repository/GameRepository.java
public interface GameRepository extends JpaRepository<Game, Long> {
    List<Game> findByPlayer1IdOrPlayer2IdAndStatus(Long p1, Long p2, String status);
    Optional<Game> findTopByGameIdOrderByCreatedAtDesc(Long gameId);
}
```

**Este patrón ya está implementado en toda la arquitectura.** Cada dominio tiene su propio repository.

---

## 6. FACADE — GameEngine

### Dónde aplica
El `GameEngine` es el punto de entrada único para cualquier acción del juego. Los controladores no acceden directamente al pipeline, los estados, los calculadores, etc.

### Implementación

```java
// game/engine/GameEngine.java
@Service
public class GameEngine {

    // Internamente orquesta todo, pero hacia afuera es una interfaz simple
    @Autowired private GameContext gameContext;
    @Autowired private AttackPipeline attackPipeline;
    @Autowired private RuleValidator ruleValidator;
    @Autowired private VictoryConditionChecker victoryChecker;
    @Autowired private GameStateSnapshotService snapshotService;
    @Autowired private GameEventPublisher eventPublisher;

    // INTERFAZ PÚBLICA SIMPLE (lo que ve el Controller)
    public GameActionResult processAction(Long gameId, Long playerId, GameAction action) {
        // 1. Cargar contexto
        GameContext ctx = loadContext(gameId);

        // 2. Validar que sea el turno de este jugador
        validateTurn(ctx, playerId);

        // 3. Delegar al estado actual
        ctx.handleAction(action);

        // 4. Verificar victoria
        checkVictoryConditions(ctx);

        // 5. Persistir snapshot
        snapshotService.save(ctx);

        return ctx.getLastResult();
    }

    public GameStateDTO getState(Long gameId, Long requestingPlayerId) {
        // Retorna el estado filtrado (sin datos privados del rival)
        GameContext ctx = loadContext(gameId);
        return sanitizeForPlayer(ctx, requestingPlayerId);
    }

    // PRIVADO — el Controller no necesita saber de esto
    private GameStateDTO sanitizeForPlayer(GameContext ctx, Long playerId) {
        GameStateDTO dto = ctx.toDTO();
        // Ocultar mano del rival, orden del mazo, cartas de premios
        if (!playerId.equals(ctx.getPlayer1Id())) {
            dto.setPlayer1Hand(null);      // null para el rival
            dto.setPlayer1HandCount(dto.getPlayer1HandSize());  // solo cantidad
        }
        if (!playerId.equals(ctx.getPlayer2Id())) {
            dto.setPlayer2Hand(null);
            dto.setPlayer2HandCount(dto.getPlayer2HandSize());
        }
        dto.setPlayer1DeckOrder(null);   // nunca se envía
        dto.setPlayer2DeckOrder(null);
        dto.setPrizesPlayer1(null);      // nunca se envían las cartas de premios
        dto.setPrizesPlayer2(null);
        dto.setPrizesPlayer1Count(ctx.getPrizesCount(ctx.getPlayer1Id()));
        dto.setPrizesPlayer2Count(ctx.getPrizesCount(ctx.getPlayer2Id()));
        return dto;
    }
}
```

### Lo que el Controller ve (simple)
```java
// game/controller/GameController.java
@RestController
@RequestMapping("/games")
public class GameController {

    @Autowired GameEngine gameEngine;   // solo esto, nada más

    @PostMapping("/{gameId}/action")
    public ResponseEntity<GameActionResult> processAction(
            @PathVariable Long gameId,
            @RequestBody GameAction action,
            @AuthenticationPrincipal UserDetails user) {

        Long playerId = extractPlayerId(user);
        GameActionResult result = gameEngine.processAction(gameId, playerId, action);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/{gameId}/state")
    public ResponseEntity<GameStateDTO> getState(
            @PathVariable Long gameId,
            @AuthenticationPrincipal UserDetails user) {

        Long playerId = extractPlayerId(user);
        GameStateDTO state = gameEngine.getState(gameId, playerId);
        return ResponseEntity.ok(state);
    }
}
```

---

## RESUMEN DE PAQUETES POR PATRÓN

```
game/engine/
├── GameEngine.java              ← FACADE (punto de entrada único)
├── GameContext.java             ← STATE (contexto compartido)
│
├── state/                       ← STATE pattern
│   ├── GameState.java
│   ├── DrawPhaseState.java
│   ├── MainPhaseState.java      ← propaga hooks al CardHandlerRegistry
│   ├── AttackPhaseState.java
│   └── EndPhaseState.java       ← propaga onEndTurn al CardHandlerRegistry
│
├── pipeline/                    ← CHAIN OF RESPONSIBILITY
│   ├── AttackHandler.java
│   ├── AttackPipeline.java
│   ├── AttackRequest.java       ← + ignoreWeakness, ignoreResistance, ignoreDefenderEffects
│   ├── AttackResult.java
│   └── handlers/
│       ├── ValidateAttackHandler.java
│       ├── CalculateBaseDamageHandler.java
│       ├── ApplyAttackerEffectsHandler.java  ← llama CardHandlerRegistry
│       ├── ApplyWeaknessHandler.java         ← respeta ignoreWeakness flag
│       ├── ApplyResistanceHandler.java       ← respeta ignoreResistance flag
│       ├── ApplyDefenderEffectsHandler.java  ← llama CardHandlerRegistry
│       ├── DealDamageHandler.java
│       ├── ExecuteAttackEffectHandler.java
│       ├── CardEffectsPostDamageHandler.java ← llama CardHandlerRegistry
│       └── CheckKnockoutHandler.java
│
├── strategy/                    ← STRATEGY
│   ├── AttackEffectStrategy.java
│   ├── EffectStrategyResolver.java
│   └── effects/
│       ├── PoisonEffectStrategy.java
│       ├── ParalyzeEffectStrategy.java
│       ├── BurnEffectStrategy.java
│       ├── SleepEffectStrategy.java
│       ├── ConfuseEffectStrategy.java
│       ├── ExtraDamageEffectStrategy.java
│       ├── HealEffectStrategy.java
│       └── NoEffectStrategy.java
│
├── cards/                       ← CARD HANDLER (ver PATRON_CARD_HANDLER.md)
│   ├── CardHandler.java         ← interfaz con hooks (onBeforeWeakness, onBeforeDamage, etc.)
│   ├── NoOpCardHandler.java
│   ├── CardHandlerRegistry.java ← detecta todos los @Component CardHandler
│   ├── context/                 ← PlayItemContext, ApplyStatusContext, EndTurnContext, etc.
│   └── xy1/                     ← 26 handlers de cartas XY1 con lógica especial
│
└── observer/                    ← OBSERVER
    ├── GameEventListener.java
    ├── GameEventPublisher.java
    ├── WebSocketEventListener.java
    ├── GameLogEventListener.java
    └── MetricsEventListener.java
```

---

## CÓMO FLUYE UN ATAQUE (todos los patrones juntos)

```
Controller.processAction(gameId, playerId, ATTACK_ACTION)
    ↓
GameEngine.processAction()          [FACADE — punto único de entrada]
    ↓
GameContext.handleAction()          [STATE — delega al estado actual]
    ↓
MainPhaseState.handleAction()       [STATE — propaga onBeforeAttackDeclared al Registry]
    ↓
AttackPhaseState.handleAction()     [STATE — solo acepta ataques]
    ↓
AttackPipeline.process(request)     [CHAIN OF RESPONSIBILITY]
    ├── ValidateAttackHandler           → ¿puede atacar? ¿energías? ¿no dormido/paralizado?
    ├── CalculateBaseDamageHandler      → daño base = 60
    ├── ApplyAttackerEffectsHandler     → llama Registry → Greninja setea ignoreWeakness=true
    ├── ApplyWeaknessHandler            → ignoreWeakness=true → SKIP (o ×2 si aplica)
    ├── ApplyResistanceHandler          → ignoreResistance flag (o -20 si aplica)
    ├── ApplyDefenderEffectsHandler     → llama Registry → Furfrou reduce -20
    ├── DealDamageHandler               → defensor recibe daño final
    ├── ExecuteAttackEffectHandler      → aplica veneno/parálisis
    │       ↓
    │   EffectStrategyResolver          [STRATEGY — selecciona por texto del ataque]
    │       ↓
    │   PoisonEffectStrategy.apply()    [STRATEGY — aplica veneno]
    │   (StatusEffectManager primero propaga onBeforeApplyStatus → Slurpuff puede bloquear)
    ├── CardEffectsPostDamageHandler    → llama Registry → Chesnaught pone contadores
    └── CheckKnockoutHandler            → ¿HP <= 0? → KO
    ↓
GameEventPublisher.publish(KO_EVENT) [OBSERVER — notifica a todos]
    ├── WebSocketEventListener      → envía a /topic/game/123
    ├── GameLogEventListener        → persiste en game_events
    └── MetricsEventListener        → incrementa contador de KO
    ↓
GameEngine.checkVictoryConditions()
GameEngine.snapshotService.save()
```
