---
id: PASO_S03_02
equipo: A
bloque: 3
dep: [PASO_S03_01]
siguiente: PASO_S03_04
context_files:
  - 04-win-conditions.md
  - 06-system-logic.md
  - GAME_ENGINE_DETALLES.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/game/victory/VictoryConditionChecker.java
  - api/src/test/java/com/codemon/game/VictoryConditionCheckerTest.java
---

# PASO 2.1 — VictoryConditionChecker
**Grupo legacy:** 2 — Motor de Juego | **Equipo:** A | **Dificultad:** 🟡 | **Tiempo:** 2–3 h

## Navegación
← **Anterior:** [PASO_S03_01](PASO_S03_01.md) — GameContext y State Machine (esqueleto del motor)
→ **Siguiente:** [PASO_S03_03](PASO_S03_03.md) — SetupState (inicio de partida, mulligan, premios)

## Archivos a cargar junto a este
- `04-win-conditions.md` — completo
- `06-system-logic.md` → eventos: GAME_OVER, SUDDEN_DEATH_START, PRIZES_SET
- `GAME_ENGINE_DETALLES.md` → T-01, V-01, V-02, INT-01 a INT-05

## Qué construye este paso
Las 3 condiciones de victoria y la Muerte Súbita. También actualiza ELO, wins/losses y refresca el leaderboard al terminar cada partida.

## Los 4 métodos y cuándo llamarlos

```java
// R-WIN-01: llamar INMEDIATAMENTE después de cada PRIZE_TAKEN
checkPrizesWon(ctx):
  Si rivalBoard.prizesCount == 0:
    declareWinner(ctx, rival, "PRIZES")

// R-WIN-02: llamar al INICIO de DrawPhase ANTES del robo
checkDeckEmpty(ctx):
  Si currentPlayerBoard.deck.isEmpty():
    declareLoser(ctx, currentPlayerId, "DECK_EMPTY")

// R-WIN-03: llamar después de KO cuando el dueño no puede reemplazar
checkNoPokemon(ctx, playerId):
  board = ctx.getPlayerBoard(playerId)
  Si board.active == null && board.bench.isEmpty():
    declareLoser(ctx, playerId, "NO_POKEMON")

// Para simultaneidad (cuando ambos pueden perder al mismo tiempo)
checkAllConditions(ctx):
  p1Loses = checkLosingConditions(ctx, player1Id)
  p2Loses = checkLosingConditions(ctx, player2Id)
  Si p1Loses && p2Loses → initiateSuddenDeath(ctx)
  Si solo p1Loses → declareWinner(ctx, player2Id, reason)
  Si solo p2Loses → declareWinner(ctx, player1Id, reason)
```

## declareWinner() — qué hace al terminar la partida

```java
void declareWinner(GameContext ctx, Long winnerId, String reason) {
    // 1. Actualizar estado del game en BD
    game.setStatus("FINISHED");
    game.setWinnerId(winnerId);
    game.setEndedAt(LocalDateTime.now());

    // 2. Actualizar estadísticas
    winnerUser.wins++;
    loserUser.losses++;
    // Para Muerte Súbita: draws++ para ambos (en vez de win/loss)

    // 3. Actualizar ELO (SOLO si matchType == "QUEUE")
    if (matchType.equals("QUEUE")) {
        double expected = 1.0 / (1 + Math.pow(10, (loserRating - winnerRating) / 400.0));
        winnerRating += 32 * (1 - expected);
        loserRating  += 32 * (0 - (1 - expected));
    }
    // PVE y ROOM NO actualizan ELO

    // 4. Actualizar ranking de ligas (PASO 5.1)
    // rankingService.addWinPoints(winnerId, gameId);

    // 5. Refrescar vista materializada (async)
    jdbcTemplate.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard");

    // 6. Emitir GAME_OVER → ambos jugadores
    emitir GAME_OVER (winnerId, loserId, reason)
}
```

## Muerte Súbita — initiateSuddenDeath()

```java
void initiateSuddenDeath(GameContext ctx) {
    ctx.setSuddenDeath(true);

    // Re-hacer el setup completo pero con 1 premio en vez de 6
    // Los mazos se barajan de nuevo
    // prizes = 1 por jugador (NO 6)

    emitir SUDDEN_DEATH_START → ambos
    emitir PRIZES_SET (count: 1) para cada jugador

    ctx.transitionTo(new SetupState(suddenDeath: true));
    // En SetupState: int prizesCount = ctx.isSuddenDeath() ? 1 : 6;
}
```

## Prompt listo para el agente

```
Implementá VictoryConditionChecker.java para el motor de juego Codemon TCG.

Reglas de victoria (fuente de verdad):
[pegá 04-win-conditions.md completo]

Eventos a emitir:
[pegá GAME_OVER, SUDDEN_DEATH_START de 06-system-logic.md]

Implementá en com.codemon.game.victory:

@Component VictoryConditionChecker con los 4 métodos:
[Pegá los pseudocódigos de los 4 métodos de este archivo]

declareWinner():
[Pegá el pseudocódigo de declareWinner() de este archivo]

initiateSuddenDeath():
[Pegá el pseudocódigo de este archivo]

TESTS - VictoryConditionCheckerTest.java:
- Último Premio tomado → GAME_OVER reason="PRIZES"
- Mazo vacío al inicio de turno → GAME_OVER reason="DECK_EMPTY"
- KO sin Banca → GAME_OVER reason="NO_POKEMON"
- Ambos cumplen condición simultáneamente → SUDDEN_DEATH_START, NO empate
- Muerte Súbita: prizes=1 por jugador, no 6
- ELO actualizado solo en partidas QUEUE
- ELO NO actualizado en PVE ni ROOM
- declareWinner actualiza wins/losses en users

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea
```
api/src/main/java/com/codemon/game/victory/VictoryConditionChecker.java
api/src/test/java/com/codemon/game/VictoryConditionCheckerTest.java
```

## Errores comunes

- **Muerte Súbita con 6 premios**: `int prizesCount = ctx.isSuddenDeath() ? 1 : 6;`
- **R-WIN-02 verificado después del robo**: verificar ANTES con `if (deck.isEmpty()) { ... return; }`
- **ELO calculado en partidas PVE**: verificar `matchType.equals("QUEUE")` antes de calcular ELO
- **Simultaneidad no detectada**: si ambos Pokémon Activos se hacen KO por veneno simultáneo, verificar ambos juntos

## Verificación

```bash
# Tras KO del último Pokémon sin Banca:
# PASS: {"type":"GAME_OVER","winnerId":2,"reason":"NO_POKEMON"}
# FAIL: no llega GAME_OVER → revisar checkNoPokemon() en CheckKnockoutHandler

# Tras tomar el último Premio:
# PASS: {"type":"GAME_OVER","winnerId":1,"reason":"PRIZES"}
# FAIL: partida continúa → checkPrizesWon() no se llama después de PRIZE_TAKEN

# Mazo vacío al inicio del turno:
# PASS: {"type":"GAME_OVER","winnerId":2,"reason":"DECK_EMPTY"}
# FAIL: IndexOutOfBoundsException → checkDeckEmpty() no se llama ANTES del robo en DrawPhaseState
```

## Dependencias
PASO_S03_01 (GameContext), PASO_S03_04 (DrawPhaseState lo llama para R-WIN-02), PASO_S04_02 (CheckKnockoutHandler lo llama para R-WIN-01 y R-WIN-03).
