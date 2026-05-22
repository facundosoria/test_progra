---
id: PASO_S11_01
equipo: A
bloque: 11
dep: [PASO_S05_02]
siguiente: PASO_S11_02
context_files:
  - PATRONES_DISENO.md
  - 02-turn-flow.md
  - 03-combat.md
  - GAME_ENGINE_DETALLES.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/game/bot/BotStrategy.java
  - api/src/main/java/com/codemon/game/bot/EasyBotStrategy.java
  - api/src/main/java/com/codemon/game/bot/MediumBotStrategy.java
  - api/src/main/java/com/codemon/game/bot/HardBotStrategy.java
  - api/src/main/java/com/codemon/game/bot/BotTurnService.java
  - api/src/test/java/com/codemon/game/bot/MediumBotStrategyTest.java
  - api/src/test/java/com/codemon/game/bot/HardBotStrategyTest.java
---

# PASO 6.1 — Bot MEDIUM y HARD

> 🧩 **EXTRA — Feature adicional al juego base**
> Este paso no es necesario para completar el proyecto funcional. El juego ya incluye Bot EASY (PASO_S05_02). Este paso agrega dos dificultades superiores que enriquecen la experiencia de juego para usuarios avanzados. Implementar solo si el equipo dispone de tiempo después de completar todos los pasos del 0 al 5.

**Grupo legacy:** 6 — Features Extra | **Equipo:** A | **Dificultad:** 🔴 | **Tiempo:** 6–9 h

## Navegación
← **Anterior:** [PASO_S05_02](PASO_S05_02.md) — Bot EASY (base sobre la que se construye)
→ **Siguiente:** [PASO_S11_02](PASO_S11_02.md) — Chat en partida backend

## Archivos a cargar junto a este
- `PATRONES_DISENO.md` → patrón STRATEGY (el que se aplica aquí)
- `02-turn-flow.md` → flujo del turno completo
- `03-combat.md` → cálculo de daño para greedy (MEDIUM)
- `PATRON_CARD_HANDLER.md` → para que el bot entienda markers y flags activos al evaluar acciones

## Qué construye este paso

Reemplaza el `BotTurnService` monolítico de `PASO_S05_02` con un sistema basado en el patrón **Strategy**. Cada dificultad implementa `BotStrategy` de forma independiente. `BotTurnService` delega en la estrategia correspondiente según `botDifficulty` del `GameContext`.

## Comportamiento por dificultad

### EASY (ya existe — no modificar)
- Selecciona acción válida aleatoria
- Siempre hace END_TURN como fallback

### MEDIUM — Greedy inmediato
La IA evalúa cada acción válida y elige la que maximiza el beneficio inmediato:

1. **Prioridad de acciones** (en orden):
   - Si puede atacar y el ataque deja KO al rival → atacar
   - Si puede atacar y el ataque hace más de 50% del HP rival → atacar
   - Si puede colocar un Pokémon Básico en la banca (protege del KO) → colocar
   - Si puede adjuntar energía al activo → adjuntar
   - Si puede evolucionar el activo → evolucionar
   - Si puede jugar un Supporter (solo si no jugó ninguno este turno) → jugar
   - Si puede jugar un Item de curación (si activo tiene daño) → jugar
   - END_TURN como fallback

2. **Selección de ataque greedy:**
```java
Attack bestAttack = attacks.stream()
    .filter(a -> hasRequiredEnergies(board, a))
    .max(Comparator.comparingInt(a -> parseDamage(a.getDamage())))
    .orElse(null);
```

3. **No hace lookahead** — solo evalúa el estado actual, no proyecta turnos futuros.

### HARD — Lookahead corto (1 turno)
Simula el resultado de cada acción posible y elige la que produce el mejor estado proyectado.

1. **Clonar GameContext** para simulación:
```java
GameContext simCtx = GameContext.deepCopy(ctx);
```

2. **Para cada acción válida:**
   - Aplicar acción en `simCtx`
   - Calcular `scoreState(simCtx)` (ver fórmula abajo)
   - Guardar (acción, score) 
   - Restaurar `simCtx` al estado original

3. **Fórmula de scoring:**
```java
int scoreState(GameContext ctx) {
    PlayerBoard mine = ctx.getBoard(ctx.botPlayerId);
    PlayerBoard rival = ctx.getBoard(ctx.humanPlayerId);
    return (6 - mine.getPrizesCount()) * 100     // premios tomados
         - (6 - rival.getPrizesCount()) * 100     // premios cedidos
         + rival.getActive().getDamageTaken() * 2 // daño acumulado en rival
         - mine.getActive().getDamageTaken()       // daño propio (negativo)
         + mine.getBench().size() * 10;            // tener banca llena es bueno
}
```

4. **Elegir acción con mayor score.** En empate, preferir la que haga más daño.

5. **Límite de tiempo:** El lookahead no debe tardar más de 200ms. Si hay más de 15 acciones posibles, evaluar solo las 10 con mayor prioridad heurística.

## Refactor de BotTurnService

```java
public interface BotStrategy {
    GameAction selectAction(GameContext ctx);
}

@Service
public class BotTurnService {
    private final Map<BotDifficulty, BotStrategy> strategies = Map.of(
        BotDifficulty.EASY,   new EasyBotStrategy(),
        BotDifficulty.MEDIUM, new MediumBotStrategy(),
        BotDifficulty.HARD,   new HardBotStrategy()
    );

    public void executeBotTurn(GameContext ctx) {
        BotStrategy strategy = strategies.get(ctx.getBotDifficulty());
        GameAction action;
        do {
            action = strategy.selectAction(ctx);
            Thread.sleep(500 + random.nextInt(500)); // delay para UI
            gameEngine.processAction(ctx.getGameId(), ctx.getBotPlayerId(), action);
        } while (action.getType() != ActionType.END_TURN);
    }
}
```

## Migración necesaria

Ninguna. `BotDifficulty` ya existe como parte del `GameContext` desde `PASO_S03_01`. Solo requiere que `GameContext.deepCopy()` esté implementado (método nuevo a agregar si no existe).

## Implementar `GameContext.deepCopy()`

```java
public static GameContext deepCopy(GameContext original) {
    // Clonar usando serialización o constructor copia
    // Importante: PlayerBoard, InPlayPokemon, List<Card> deben ser copias profundas
    // NO compartir referencias con el original
    ObjectMapper mapper = new ObjectMapper();
    return mapper.readValue(mapper.writeValueAsString(original), GameContext.class);
}
```

## Errores comunes

- **HARD se cuelga:** El lookahead puede ser costoso. Limitar a 10 acciones candidatas.
- **deepCopy incompleto:** Si las listas son referencias al original, la simulación modifica el estado real.
- **Score negativo siempre:** Verificar que prizesCount disminuye cuando se toman premios (no aumenta).

## Verificación

```bash
# Test MEDIUM gana consistentemente vs EASY (>60% en 100 partidas)
./mvnw test -Dtest=MediumBotStrategyTest

# Test HARD gana consistentemente vs MEDIUM (>55% en 100 partidas)  
./mvnw test -Dtest=HardBotStrategyTest

# Verificar que delay >= 500ms entre acciones
./mvnw test -Dtest=BotTurnServiceTest#testActionDelay
```
