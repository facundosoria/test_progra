---
id: PASO_S03_01
equipo: A
bloque: 3
dep: [PASO_S00_05, PASO_S02_01]
siguiente: PASO_S03_02
context_files:
  - PATRONES_DISENO.md
  - BD_Y_TABLAS.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/game/engine/GameState.java
  - api/src/main/java/com/codemon/game/engine/GameContext.java
  - api/src/main/java/com/codemon/game/engine/GameEngine.java
  - api/src/main/java/com/codemon/game/engine/GameAction.java
  - api/src/main/java/com/codemon/game/engine/ActionType.java
  - api/src/main/java/com/codemon/game/engine/GameActionResult.java
  - api/src/main/java/com/codemon/game/engine/GameEvent.java
  - api/src/main/java/com/codemon/game/engine/model/InPlayPokemon.java
  - api/src/main/java/com/codemon/game/engine/model/PlayerBoard.java
  - api/src/main/java/com/codemon/game/engine/model/GameBoard.java
  - api/src/main/java/com/codemon/game/engine/model/StatusCondition.java
  - api/src/main/java/com/codemon/game/engine/model/Marker.java
  - api/src/main/java/com/codemon/game/engine/state/SetupState.java
  - api/src/main/java/com/codemon/game/engine/state/DrawPhaseState.java
  - api/src/main/java/com/codemon/game/engine/state/MainPhaseState.java
  - api/src/main/java/com/codemon/game/engine/state/AttackPhaseState.java
  - api/src/main/java/com/codemon/game/engine/state/EndPhaseState.java
  - api/src/test/java/com/codemon/game/engine/GameContextTest.java
---

# PASO 2.0 — GameContext y State Machine
**Grupo legacy:** 2 — Motor de Juego | **Equipo:** A | **Dificultad:** 🟡 | **Tiempo:** 2–3 h

## Navegación
← **Anterior:** [PASO_S02_03](PASO_S02_03.md) — Deck Builder CRUD completado
→ **Siguiente:** [PASO_S03_02](PASO_S03_02.md) — VictoryConditionChecker (condiciones de victoria)

## Archivos a cargar junto a este
- `PATRONES_DISENO.md` → sección "1. STATE" completa
- `SCHEMA_BD.sql` → bloque V9 (tabla games)

## Qué construye este paso
El esqueleto completo del motor: la State Machine, los modelos del tablero, los DTOs de acciones y eventos. Sin lógica de juego todavía — es la estructura que los pasos 2.1 a 2.9 van a rellenar. Sin este paso, nada del motor puede compilar.

## Prompt listo para el agente

```
Implementá el andamiaje del motor de juego (State Machine) para el proyecto Codemon TCG.
Java 21, Spring Boot 3.3.x. Sin lógica de juego aún, solo la estructura.

Patrón a seguir (del documento adjunto):
[pegá la sección "1. STATE" de PATRONES_DISENO.md]

Schema de partidas:
[pegá bloque V9 de SCHEMA_BD.sql]

Implementá en com.codemon.game.engine:

1. GameState.java (interfaz)
   - void onEnter(GameContext context)
   - void handleAction(GameContext context, GameAction action)
   - void onExit(GameContext context)
   - String getName()

2. ActionType.java (enum):
   CONFIRM_DRAW, PLACE_ACTIVE, PLACE_BENCH, CONFIRM_SETUP,
   PLAY_BASIC_POKEMON, EVOLVE_POKEMON, ATTACH_ENERGY,
   PLAY_ITEM, PLAY_SUPPORTER, PLAY_STADIUM, PLAY_TOOL,
   RETREAT, USE_ABILITY, DECLARE_ATTACK, TAKE_PRIZE,
   REPLACE_ACTIVE_AFTER_KO, END_TURN

3. GameAction.java (record):
   ActionType type, Long playerId, String cardId (nullable),
   String targetPokemonId (nullable), String attackName (nullable),
   Map<String,Object> extra (nullable)

4. StatusCondition.java (enum): POISONED, BURNED, ASLEEP, PARALYZED, CONFUSED

5. InPlayPokemon.java
   - String instanceId (UUID — NUNCA usar cardId para identificar, puede haber 2 Pikachu)
   - String cardId
   - int damage
   - List<String> attachedEnergies
   - String attachedTool (nullable)
   - Set<StatusCondition> statusConditions
   - int turnsInPlay (0 = jugado este turno, 1+ = puede evolucionar)
   - boolean evolvedThisTurn
   - Marker marker = new Marker()     ← NUEVO: para efectos de turno siguiente (Harden, King's Shield, etc.)
   - int poisonDamage = 10            ← NUEVO: variable para veneno (no hardcodear 10 en BetweenTurns)
   - int burnDamage = 20              ← NUEVO: variable para quemadura (no hardcodear 20 en BetweenTurns)

6. PlayerBoard.java
   - Long userId
   - List<String> hand
   - List<String> deck
   - List<String> discardPile
   - List<String> prizes
   - int prizesCount
   - InPlayPokemon active (nullable)
   - List<InPlayPokemon> bench (max 5)
   - Marker marker = new Marker()     ← NUEVO: para efectos del jugador (bloquear Items, Supporters)

7. GameBoard.java
   - PlayerBoard player1Board, player2Board
   - String activeStadiumCardId (nullable)
   - Long activeStadiumOwnerId (nullable)
   Métodos: getBoard(Long playerId), getOpponentBoard(Long playerId)

8. GameContext.java — CAMPOS CRÍTICOS:
   - Long gameId
   - GameState currentState
   - GameBoard board
   - Long player1Id, player2Id
   - String matchType ("QUEUE" | "ROOM" | "PVE")
   - Long currentTurnPlayerId
   - int turnNumber
   - boolean isFirstTurn
   - boolean firstTurnAttackBlocked
   - boolean energyAttachedThisTurn
   - boolean supporterPlayedThisTurn
   - boolean retreatedThisTurn
   - boolean awaitingReplacement
   - Long awaitingReplacementPlayerId
   - Map<String, Integer> paralyzedOnTurn  (instanceId → turnNumber)
   - boolean isSuddenDeath
   - List<GameEvent> pendingEvents
   - GameActionResult lastResult
   Métodos:
   - void transitionTo(GameState newState) → llama onExit del actual, onEnter del nuevo
   - void handleAction(GameAction action) → DELEGA al estado actual: currentState.handleAction(this, action)
       (este es el único punto de entrada de acciones; GameEngine.processAction llama a ctx.handleAction)
   - void publishEvent(GameEvent event) → agrega a pendingEvents
   - Long getOpponentId(Long playerId)
   - void resetTurnFlags() → setea a false: energyAttachedThisTurn, supporterPlayedThisTurn, retreatedThisTurn
   - GameActionResult getLastResult()

9. GameEvent.java — formato canónico definido en GLOSARIO.md sección 4
   - String eventType (SCREAMING_SNAKE_CASE; ej: "TURN_START", "CARD_DRAWN")
   - Long gameId
   - String timestamp (ISO 8601 UTC; generar al construir el evento con Instant.now().toString())
   - Map<String,Object> payload
   - boolean isPrivate (renombrar a "private" al serializar; ver @JsonProperty si es necesario)
   - Long privateTargetUserId (nullable; solo si isPrivate = true)
   IMPORTANTE: el JSON serializado debe matchear el schema de PROTOCOLO_WEBSOCKET.md.
   Si el frontend espera `eventType` y `timestamp`, no renombrar los campos al serializar.

10. GameActionResult.java
    - boolean success
    - String error (nullable)
    - List<GameEvent> events

11. GameEngine.java (@Service, Facade vacío por ahora)
    - GameActionResult processAction(Long gameId, Long playerId, GameAction action)
    - Object getState(Long gameId, Long requestingPlayerId)

Los estados concretos son clases VACÍAS que implementan GameState:
SetupState, DrawPhaseState, MainPhaseState, AttackPhaseState, EndPhaseState

TESTS - GameContextTest.java:
- transitionTo() llama onExit del estado anterior y onEnter del nuevo
- resetTurnFlags() resetea todos los flags a false

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea
```
api/src/main/java/com/codemon/game/engine/
  GameState.java (interfaz)
  GameContext.java
  GameEngine.java (facade vacío)
  GameAction.java
  ActionType.java
  GameActionResult.java
  GameEvent.java
api/src/main/java/com/codemon/game/engine/model/
  InPlayPokemon.java
  PlayerBoard.java
  GameBoard.java
  StatusCondition.java
api/src/main/java/com/codemon/game/engine/state/
  SetupState.java (vacío)
  DrawPhaseState.java (vacío)
  MainPhaseState.java (vacío)
  AttackPhaseState.java (vacío)
  EndPhaseState.java (vacío)
api/src/test/java/com/codemon/game/engine/GameContextTest.java
```

## Campos críticos — no omitir

```java
// InPlayPokemon: NUNCA usar cardId como identificador en juego
// Puede haber dos Pikachu en el tablero al mismo tiempo
String instanceId = UUID.randomUUID().toString();

// GameContext: necesario para saber cuándo curar la parálisis
Map<String, Integer> paralyzedOnTurn = new HashMap<>();
// key: instanceId del Pokémon, value: turnNumber en que fue paralizado

// GameBoard: para saber a quién devolver el Stadium al descarte
Long activeStadiumOwnerId;

// PlayerBoard: listas deben ser mutables (no List.of())
List<String> hand = new ArrayList<>();
List<String> deck = new ArrayList<>();

// Marker: para efectos de turno siguiente (Harden, King's Shield, bloqueo de Items, etc.)
// La clase Marker tiene: List<{name: String, sourceCardId: String}>
// Se agrega en InPlayPokemon (efectos sobre el slot) y en PlayerBoard (efectos sobre el jugador)
// IMPORTANTE: NO anotar con @Transient ni @JsonIgnore — debe serializar en el state_json
// Inicializar siempre en constructor (nunca null) para evitar NullPointerException
// Ver PATRON_CARD_HANDLER.md sección M-01 y GAME_ENGINE_DETALLES_PARTE2.md CH-03

// InPlayPokemon: poisonDamage y burnDamage son campos, no literales hardcodeados
// BetweenTurnsProcessor usa activePokemon.getPoisonDamage() y .getBurnDamage()
// Al aplicar POISONED: poisonDamage = 10 (resetear al default)
// Al aplicar BURNED:   burnDamage = 20 (resetear al default)
// Esto permite que cartas futuras modifiquen cuánto daña el veneno
```

## Errores comunes

- **GameContext no serializable**: si se guarda en Redis necesita `implements Serializable`; mejor usar snapshots en BD
- **Listas inmutables**: `List.of()` lanza `UnsupportedOperationException` al hacer `add()`; usar `new ArrayList<>()`
- **Estados vacíos sin manejar acciones desconocidas**: cada estado debe retornar un error descriptivo para acciones no válidas

## Tests obligatorios

```java
@Test
void gameContext_transitions_call_state_methods() {
    MockState stateA = new MockState("A");
    MockState stateB = new MockState("B");
    GameContext ctx = new GameContext();
    ctx.transitionTo(stateA);
    ctx.transitionTo(stateB);

    assertTrue(stateA.onExitCalled);
    assertTrue(stateB.onEnterCalled);
}
```

## Verificación

```bash
./mvnw compile
# PASS: "BUILD SUCCESS" — todas las clases existen y compilan sin error
# FAIL: cualquier error de compilación → revisar dependencias entre clases del engine
```

## Dependencias
PASO_S00_05 (tabla games en BD), PASO_S02_01 (DeckValidationService se usa en SetupState).
