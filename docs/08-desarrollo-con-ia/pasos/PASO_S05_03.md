---
id: PASO_S05_03
equipo: A
bloque: 5
dep: [PASO_S03_01, PASO_S03_02, PASO_S03_03, PASO_S03_04, PASO_S03_05, PASO_S04_01, PASO_S04_02, PASO_S05_01, PASO_S05_02]
siguiente: PASO_S05_04 PASO_S05_04]
context_files:
  - PATRONES_DISENO.md
  - PATRON_CARD_HANDLER.md
  - 06-system-logic.md
  - GAME_ENGINE_DETALLES.md
  - GAME_ENGINE_DETALLES_PARTE2.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/game/engine/GameEngine.java
  - api/src/main/java/com/codemon/game/engine/observer/GameEventPublisher.java
  - api/src/main/java/com/codemon/game/engine/observer/GameLogEventListener.java
  - api/src/main/java/com/codemon/shared/config/WebSocketConfig.java
  - api/src/main/java/com/codemon/game/controller/GameController.java
  - api/src/test/java/com/codemon/game/GameEngineTest.java
---

# PASO 2.9 — GameEngine completo (Facade + WebSocket)
**Grupo legacy:** 2 — Motor de Juego | **Equipo:** A | **Dificultad:** 🟡 | **Tiempo:** 3–5 h

## Navegación
← **Anterior:** [PASO_S05_02](PASO_S05_02.md) — Bot EASY integrado
→ **Siguiente (GATE 2 desbloqueado — paralelo):** [PASO_S07_01](PASO_S07_01.md) (C) · [PASO_S05_04](PASO_S05_04.md) (B)

## Archivos a cargar junto a este
- `PATRONES_DISENO.md` → secciones "6. FACADE" y "4. OBSERVER"
- `06-system-logic.md` — completo (todos los eventos WebSocket y su visibilidad)
- `GAME_ENGINE_DETALLES.md` → SEC-01 (datos privados), SEC-02 (validación de turno), SEC-03 (persistencia)

## Qué construye este paso
El punto de entrada único del motor, el sistema de publicación de eventos WebSocket, y la sanitización de estado para no revelar información privada. Une todos los componentes anteriores.

## processAction() — flujo completo

```java
GameActionResult processAction(Long gameId, Long playerId, GameAction action) {

    // 1. Cargar contexto (de caché en memoria o reconstruir de snapshot en BD)
    GameContext ctx = loadContext(gameId);

    // 2. Validar turno
    if (ctx.isAwaitingReplacement()) {
        if (!playerId.equals(ctx.awaitingReplacementPlayerId))
            throw new NotYourTurnException();
        if (action.getType() != REPLACE_ACTIVE_AFTER_KO)
            throw new InvalidActionException("Debes elegir un nuevo Pokémon Activo primero");
    } else if (!playerId.equals(ctx.currentTurnPlayerId)) {
        throw new NotYourTurnException();
    }

    // 3. Procesar la acción
    ctx.handleAction(action);

    // 4. Publicar eventos pendientes (sincrónico — notifica clientes primero)
    publishPendingEvents(ctx);

    // 5. Persistir snapshot (asíncrono — no bloquea el response)
    persistSnapshotAsync(ctx);

    return ctx.getLastResult();
}
```

## getState() — sanitizar para el jugador que pregunta

```java
GameStateDTO getState(Long gameId, Long viewerId) {
    GameContext ctx = loadContext(gameId);
    GameStateDTO dto = ctx.toFullDTO();

    // NUNCA revelar al rival:
    if (!viewerId.equals(ctx.player1Id)) {
        dto.getPlayer1().setHand(null);
        dto.getPlayer1().setHandCount(ctx.getPlayer1Board().getHand().size());
    }
    dto.getPlayer1().setDeck(null);
    dto.getPlayer1().setDeckSize(ctx.getPlayer1Board().getDeck().size());
    dto.getPlayer1().setPrizes(null);
    dto.getPlayer1().setPrizesCount(ctx.getPlayer1Board().getPrizesCount());

    // Igual para player2
    if (!viewerId.equals(ctx.player2Id)) {
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

## GameEventPublisher — qué canal usar

```java
void publish(GameEvent event) {
    if (event.isPrivate()) {
        // Solo al dueño — ejemplo: CARD_DRAWN
        messagingTemplate.convertAndSendToUser(
            event.getPrivateTargetUserId().toString(),
            "/queue/game",
            event.toDTO()
        );
    } else {
        // A ambos jugadores (NUNCA incluir hand/deck/prizes del rival)
        messagingTemplate.convertAndSend(
            "/topic/game/" + event.getGameId(),
            event.toPublicDTO()
        );
    }
}
```

## URL WebSocket según entorno

```
Desarrollo:  ws://localhost:8088/ws
Docker:      /ws  (nginx hace el proxy a api:8080)
```

## Prompt listo para el agente

```
Implementá GameEngine.java completo (Facade) y el sistema de eventos WebSocket (Observer) para el motor de juego Codemon TCG.

Patrón Facade y Observer:
[pegá secciones "6. FACADE" y "4. OBSERVER" de PATRONES_DISENO.md]

Todos los eventos WebSocket:
[pegá 06-system-logic.md completo]

Implementá:

1. GameEventPublisher.java (@Component):
   [Pegá el pseudocódigo de publish() de este archivo]
   Además: persistir evento en game_events (log inmutable)

2. WebSocketConfig.java (@Configuration):
   - Endpoint STOMP en /ws con SockJS fallback
   - Broker en /topic, /user, /queue
   - allowedOrigins de properties codemon.cors.allowed-origins

3. GameController.java:
   - POST /games → crear partida (matchType: PVE|QUEUE|ROOM, deckId, botDifficulty?)
   - POST /games/{id}/action → procesar acción (playerId del JWT)
   - GET  /games/{id}/state → estado sanitizado para el jugador del JWT

4. GameEngine.java (completar el Facade):
   processAction():
   [Pegá el pseudocódigo de processAction() de este archivo]

   getState():
   [Pegá el pseudocódigo de getState() de este archivo]

TESTS - GameEngineTest.java:
- getState(): player1 ve su hand, player2.hand es null para player1
- getState(): ninguno ve el orden del deck (deck == null, solo deckSize)
- getState(): ninguno ve sus prizes (prizes == null, solo prizesCount)
- Acción fuera de turno → 403 NotYourTurnException
- REPLACE_ACTIVE_AFTER_KO puede hacerlo el dueño fuera de su turno
- CARD_DRAWN llega solo al dueño (evento privado)
- DAMAGE_DEALT llega a ambos (evento público)
- Partida PVE completa (setup → turno → ataque → KO → victoria) sin errores

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea/modifica
```
api/src/main/java/com/codemon/game/engine/GameEngine.java (completar)
api/src/main/java/com/codemon/game/engine/observer/GameEventPublisher.java
api/src/main/java/com/codemon/game/engine/observer/GameLogEventListener.java
api/src/main/java/com/codemon/shared/config/WebSocketConfig.java
api/src/main/java/com/codemon/game/controller/GameController.java
api/src/test/java/com/codemon/game/GameEngineTest.java
```

## Errores comunes

- **Snapshot sincrónico bloqueando el response**: usar `@Async` para el snapshot
- **Concurrencia**: dos requests pueden modificar el mismo GameContext; usar `synchronized(gameId)` o lock Redis
- **URL WebSocket distinta en Docker**: el frontend debe usar `/ws` en producción, no `ws://localhost:8088/ws`
- **CARD_DRAWN publicado a ambos**: verificar `event.isPrivate()` siempre antes de publicar

## Checklist final del motor completo

Antes de declarar el motor como implementado, verificar:

```
SETUP:
[ ] Barajado con SecureRandom (no Random con semilla)
[ ] Básico: supertype=="Pokémon" AND subtypes.contains("Basic") AND NOT "Restored"
[ ] Mulligan Caso B: extraCards = mulliganCount - 1 (no mulliganCount)
[ ] Premios tomados DESPUÉS de robar la mano
[ ] deck + hand + prizes == 60 siempre

TURNO:
[ ] R-WIN-02 verificado ANTES del robo
[ ] turnsInPlay++ al inicio del turno del dueño
[ ] evolvedThisTurn = false al inicio de cada turno
[ ] Mega Evolución termina el turno inmediatamente
[ ] Retirada: cura condiciones, NO el daño, Tool permanece

COMBATE:
[ ] Daño directo: sin weakness ni resistance
[ ] Daño a Banca: sin weakness ni resistance
[ ] Daño de Confusión: 30 directos al propio Pokémon
[ ] Orden: (base+bonus) × weakness - resistance - defReduccion
[ ] Resultado mínimo: 0
[ ] Colorless: tipos específicos primero, Colorless con el resto
[ ] Double Colorless Energy = 2 Colorless (una sola carta cuenta como dos energías Colorless)

KO:
[ ] El RIVAL toma premios de SUS PROPIOS premios
[ ] EX y MEGA → 2 premios
[ ] Energías + Tool → discardPile del dueño
[ ] Victoria inmediata tras último premio
[ ] R-WIN-03 verificado DESPUÉS de los premios

CONDICIONES:
[ ] POISONED + BURNED coexisten con todo
[ ] ASLEEP/PARALYZED/CONFUSED se reemplazan mutuamente
[ ] POISONED/BURNED no se eliminan al aplicar condición de rotación
[ ] BURNED: marcador permanece aunque salga Cara
[ ] Parálisis: cura en EndPhase del turno del DUEÑO (no del oponente)
[ ] Orden entre turnos: Veneno → Quema → Sueño → Parálisis → KOs

VICTORIA:
[ ] Ambos simultáneo → Muerte Súbita (no empate)
[ ] Muerte Súbita: 1 premio c/u

CARD HANDLER REGISTRY (ver PATRON_CARD_HANDLER.md y GAME_ENGINE_DETALLES_PARTE2.md):
[ ] CardHandlerRegistry detecta @Component CardHandler automáticamente
[ ] getAllCardsInPlay() excluye mano, mazo, descarte y premios
[ ] Marker serializado en state_json (no @Transient, inicializado en constructor)
[ ] ApplyAttackerEffectsHandler propaga onBeforeWeaknessCalculation (antes de ApplyWeakness)
[ ] ApplyWeaknessHandler: si request.isIgnoreWeakness() → skip completo
[ ] ApplyResistanceHandler: si request.isIgnoreResistance() → skip completo
[ ] ApplyDefenderEffectsHandler: si !ignoreDefenderEffects → propaga onBeforeDamageApplied
[ ] CardEffectsPostDamageHandler propaga onAfterDamageApplied (después de ExecuteEffect)
[ ] MainPhaseState propaga onBeforePlayItem antes de ejecutar Items
[ ] MainPhaseState propaga onBeforePlaySupporter antes de ejecutar Supporters
[ ] MainPhaseState propaga onBeforeAttackDeclared antes de transicionar a AttackPhase
[ ] MainPhaseState propaga onBeforeUseAbility antes de ejecutar USE_ABILITY (caso Arbok / Gastro Acid)
[ ] StatusEffectManager propaga onBeforeApplyStatus; respeta ctx.isBlocked()
[ ] StatusEffectManager emite STATUS_BLOCKED (no STATUS_APPLIED) cuando ctx.isBlocked()
[ ] Evento STATUS_BLOCKED documentado en 06-system-logic.md con datos: targetPokemonId, targetPokemonName, attemptedStatus, blockingAbilityName, blockingCardId
[ ] UI cliente renderiza STATUS_BLOCKED como "It doesn't affect [targetPokemonName]!"
[ ] EndPhaseState propaga onEndTurn ANTES de cambiar jugador activo (paso 0 del orden de paso entre turnos)
[ ] poisonDamage=10 y burnDamage=20 en InPlayPokemon (no literales hardcodeados)
[ ] BetweenTurns usa pokemon.getPoisonDamage() y pokemon.getBurnDamage()
[ ] PASO_S04_03 implementado: 26 handlers de XY1 (ver lista de outputs en ese PASO)

SEGURIDAD:
[ ] hand del rival → null en getState()
[ ] deck de ambos → null (solo deckSize)
[ ] prizes de ambos → null (solo prizesCount)
[ ] CARD_DRAWN → evento privado solo al dueño
[ ] Acción fuera de turno → 403
[ ] REPLACE_ACTIVE_AFTER_KO: permitido fuera del turno normal (el dueño del KO debe elegir)

COBERTURA (RNF-03):
[ ] DamageCalculator ≥ 90%
[ ] StatusEffectManager ≥ 90%
[ ] AttackPipeline ≥ 90%
[ ] VictoryConditionChecker ≥ 90%
[ ] Global ≥ 80%
```

## Verificación

```bash
TOKEN="eyJ..."

# Crear partida PVE
curl -X POST http://localhost:8088/games -H "Authorization: Bearer $TOKEN" \
  -d '{"deckId":1,"matchType":"PVE","botDifficulty":"EASY"}'
# PASS: {"gameId":1,"status":"ACTIVE"}
# FAIL: 500 → verificar que todos los PASO_S03_01–2.8 compilan correctamente

# Estado sanitizado — CRÍTICO verificar privacidad
curl http://localhost:8088/games/1/state -H "Authorization: Bearer $TOKEN"
# PASS — todos deben cumplirse:
#   player2.hand == null (rival no ve tu mano)
#   player1.deck == null (solo deckSize visible)
#   player1.prizes == null (solo prizesCount: 6)
# FAIL en cualquier campo → revisar getState() y sanitizeForPlayer()

# Acción fuera de turno
# PASS: 403 NotYourTurnException
# FAIL: 200 OK → validación de turno no implementada en processAction()

# Partida completa PVE
# PASS: la partida llega a GAME_OVER sin errores 500 en logs
# PASS: DAMAGE_DEALT llega a ambos, CARD_DRAWN solo al dueño
# FAIL: CARD_DRAWN llega a ambos → revisar isPrivate en GameEventPublisher
```

## Dependencias
PASO_S03_01 a PASO_S05_02 completados — este paso une todo el motor.

---

## Entrega al siguiente paso (GATE 2)

Tras completar este PASO, los siguientes (PASO_S07_01, PASO_S05_04, PASO_S05_SMOKE) pueden asumir:

- **Endpoints REST disponibles**:
  - `POST /api/games` (crear partida; matchType: `PVE` | `QUEUE` | `ROOM`; con `deckId`, opcional `botDifficulty`)
  - `POST /api/games/{id}/action` (procesa una acción del jugador autenticado)
  - `GET /api/games/{id}/state` (devuelve estado sanitizado para el viewer del JWT)
- **WebSocket STOMP activo** en `/ws` (con SockJS fallback). Suscripciones:
  - `/topic/game/{id}` — eventos públicos para ambos jugadores
  - `/user/queue/game` — eventos privados solo al dueño
- **Eventos emitidos** con formato canónico (sección 4 de [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md)): `eventType`, `gameId`, `timestamp`, `payload`, `private`, `privateTargetUserId`
- **Privacidad respetada**: el rival NO ve `hand`, `deck` ni `prizes` en `getState()`. `CARD_DRAWN` SOLO llega al dueño.
- **Bean Spring autowireable**: `GameEngine` (Facade) con `processAction()` y `getState()`
- **Persistencia**: snapshots en `game_state_snapshots`, eventos en `game_events` (asincrónico via `@Async`)
- Para PASO_S05_04 (frontend): el contrato WebSocket está estable, el agente puede empezar a integrar el tablero

---

## Definition of Done — incluye GATE 2 (revisar [PASO_S05_SMOKE](PASO_S05_SMOKE.md))

- [ ] Todos los archivos de `outputs:` existen
- [ ] `./verify_paso.sh PASO_S05_03` retorna exit 0
- [ ] El "Checklist final del motor completo" arriba está al 100%
- [ ] Cobertura ≥ 90% en DamageCalculator, StatusEffectManager, AttackPipeline, VictoryConditionChecker
- [ ] Cobertura global del motor ≥ 80%
- [ ] Una partida PvE end-to-end (setup → KO → victoria) corre sin errores 500 en logs
- [ ] Eventos WebSocket cumplen formato canónico (`eventType`, no `type`)
- [ ] Sin TODOs ni FIXMEs en el código entregado
- [ ] Naming respeta [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md)
- [ ] [PASO_S05_SMOKE](PASO_S05_SMOKE.md) — todos los checks pasan
