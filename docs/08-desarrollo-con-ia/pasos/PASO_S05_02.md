---
id: PASO_S05_02
equipo: A
bloque: 5
dep: [PASO_S03_01, PASO_S03_02, PASO_S03_03, PASO_S03_04, PASO_S03_05, PASO_S04_01, PASO_S04_02, PASO_S05_01]
siguiente: PASO_S05_03
context_files:
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/game/engine/bot/BotAgent.java
  - api/src/main/java/com/codemon/game/engine/bot/BotTurnService.java
  - api/src/test/java/com/codemon/game/BotAgentTest.java
---

# PASO 2.8 — Bot EASY
**Grupo legacy:** 2 — Motor de Juego | **Equipo:** A | **Dificultad:** 🟡 | **Tiempo:** 3–4 h

## Navegación
← **Anterior:** [PASO_S03_02](PASO_S03_02.md) — VictoryConditionChecker (3 condiciones + Muerte Súbita + ELO)
→ **Siguiente:** [PASO_S05_03](PASO_S05_03.md) — GameEngine completo (Facade + WebSocket STOMP — GATE 2)

## Archivos a cargar junto a este
Ninguno adicional — el prompt es autocontenido. Opcionalmente: `ESPECIFICACION_PRODUCTO.md` → seccion "Bot con chat y personalidad argentina".

## Qué construye este paso
Un Bot que toma decisiones aleatorias válidas. No necesita ser inteligente — solo no debe crashear ni bloquear el juego. Se integra en GameEngine para que cuando el turno pase al Bot, juegue automáticamente.

## Algoritmo del Bot — prioridad de acciones

```java
void executeBotTurn(GameContext ctx) {
    // 1. Colocar Básicos en Banca si hay espacio
    List<Card> basicosEnMano = filterBasicsFromHand(ctx.getBotBoard());
    for (Card basico : basicosEnMano) {
        if (ctx.getBotBoard().bench.size() < 5) {
            processAction(ctx, new GameAction(PLAY_BASIC_POKEMON, botId, basico.id));
            Thread.sleep(random(500, 1000));  // delay para que el frontend renderice
        }
    }

    // 2. Adjuntar Energía (si no lo hizo este turno)
    if (!ctx.energyAttachedThisTurn) {
        List<Card> energias = filterEnergiesFromHand(ctx.getBotBoard());
        if (!energias.isEmpty() && ctx.getBotBoard().active != null) {
            Card energia = randomOf(energias);
            processAction(ctx, new GameAction(ATTACH_ENERGY, botId, energia.id, active.instanceId));
            Thread.sleep(random(500, 1000));
        }
    }

    // 3. Atacar si puede
    if (ctx.getBotBoard().active != null) {
        List<Attack> disponibles = ctx.getBotBoard().active.card.attacks.stream()
            .filter(a -> hasRequiredEnergies(ctx.getBotBoard().active, a.cost))
            .collect(toList());
        if (!disponibles.isEmpty()) {
            Attack ataque = randomOf(disponibles);
            processAction(ctx, new GameAction(DECLARE_ATTACK, botId, attackName: ataque.name));
            return;  // DECLARE_ATTACK termina el turno automáticamente
        }
    }

    // 4. Fallback SIEMPRE disponible — evita bucles infinitos
    processAction(ctx, new GameAction(END_TURN, botId));
}
```

## Prompt listo para el agente

```
Implementá el BotAgent EASY para Codemon TCG.
El Bot toma decisiones aleatorias válidas. No necesita ser inteligente — solo no debe crashear.

Implementá en com.codemon.game.engine.bot:

1. BotAgent.java (@Component):
   Método: List<GameAction> getAvailableActions(GameContext ctx)
   Retorna SOLO acciones que son válidas en el estado actual.
   SIEMPRE incluir END_TURN en la lista (nunca retornar lista vacía).

2. BotTurnService.java (@Service):
   executeBotTurn(GameContext ctx):
   [Pegá el algoritmo de este archivo]

   Entre cada acción: Thread.sleep(random entre 500ms y 1000ms)
   Marcar acciones como ejecutadas para no repetir en el mismo turno.
   REGLA CRÍTICA: el Bot NUNCA intenta una acción que no está disponible.
   Si la lista filtrada está vacía → END_TURN.

3. Integrar en GameEngine:
   Cuando el turno pasa al Bot (playerId es el bot), llamar automáticamente a executeBotTurn().
   El delay es responsabilidad del BotTurnService, no del caller.

TESTS - BotAgentTest.java:
- Bot puede completar un turno completo sin excepciones
- Bot siempre termina el turno (nunca queda bloqueado en loop infinito)
- getAvailableActions() nunca retorna lista vacía (siempre incluye END_TURN)
- Delay entre acciones del Bot es >= 500ms

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea
```
api/src/main/java/com/codemon/game/engine/bot/BotAgent.java
api/src/main/java/com/codemon/game/engine/bot/BotTurnService.java
api/src/main/java/com/codemon/game/engine/GameEngine.java (modificar)
api/src/test/java/com/codemon/game/BotAgentTest.java
```

## Errores comunes

- **Sin fallback END_TURN**: si el Bot no puede hacer nada, el turno quedaría bloqueado indefinidamente
- **Sin delay**: el frontend recibe todas las acciones del Bot al mismo tiempo y no puede renderizarlas
- **Bot elige acciones inválidas**: siempre filtrar antes de elegir random; nunca elegir sin validar
- **Bot llama `processAction()` directamente sin pasar por el GameEngine**: puede saltear validaciones de seguridad

## Verificación

```bash
TOKEN="eyJ..."

# Crear partida PVE
curl -X POST http://localhost:8088/games \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"deckId":1,"matchType":"PVE","botDifficulty":"EASY"}'
# PASS: {"gameId":1,"status":"ACTIVE"}
# FAIL: 500 → GameEngine no tiene integración con BotTurnService

# Dejar correr la partida
docker compose logs -f api | grep -i bot
# PASS:
#   [Bot] Turno 3: colocando básico xy1-55 en banca
#   [Bot] Turno 3: adjuntando energía xy1-126
#   [Bot] Turno 3: no puede atacar, terminando turno
# PASS: la partida llega a GAME_OVER sin errores 500 en logs
# FAIL: loop infinito → Bot no tiene fallback END_TURN en getAvailableActions()
# FAIL: delay no visible → Thread.sleep() no implementado en BotTurnService
```

## Dependencias
PASO_S03_01 a PASO_S03_02 completados (todos los estados del motor deben existir antes de integrar el Bot).
