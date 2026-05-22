---
id: PASO_S05_04
equipo: B
bloque: 5
dep: [PASO_S05_03]
siguiente: PASO_S05_SMOKE
context_files:
  - 06-system-logic.md
  - PATRONES_DISENO.md
  - CONVENCIONES.md
outputs:
  - front/src/app/game/models/game.models.ts
  - front/src/app/game/services/game.service.ts
  - front/src/app/game/services/websocket.service.ts
  - front/src/app/game/pages/game-board/game-board.component.ts
  - front/src/app/game/pages/game-board/game-board.component.html
  - front/src/app/game/pages/game-board/game-board.component.scss
  - front/src/app/game/components/pokemon-zone/pokemon-zone.component.ts
  - front/src/app/game/components/bench-zone/bench-zone.component.ts
  - front/src/app/game/components/hand-zone/hand-zone.component.ts
  - front/src/app/game/components/chat-window/chat-window.component.ts
  - front/src/app/game/components/action-buttons/action-buttons.component.ts
  - front/src/app/game/components/notification-center/notification-center.component.ts
---

# PASO 3.3 — Frontend del tablero de juego
**Grupo legacy:** 3 — Matchmaking + Frontend | **Equipo:** B | **Dificultad:** 🔴 | **Tiempo:** 10–15 h

## Navegación
← **Anterior:** [PASO_S05_03](PASO_S05_03.md) — GameEngine WebSocket STOMP (GATE 2 — desbloqueó este paso)
→ **Siguiente:** [PASO_S05_SMOKE](PASO_S05_SMOKE.md) — Smoke test Sprint 5

> ⚠️ **Aclaración de dependencia:** Este paso solo necesita `PASO_S05_03` para poder implementarse — el motor y el WebSocket son suficientes para construir y conectar el tablero. Las dependencias en `PASO_S07_01` (Salas privadas) y `PASO_S07_02` (Matchmaking) fueron eliminadas porque son dependencias de **testing**, no de implementación. Para probar el tablero end-to-end sí se necesita al menos una forma de iniciar una partida (PASO_S07_01 o PASO_S07_02), pero la construcción del componente puede arrancar en paralelo con ambas.

> ⚠️ **Alcance por sprint:** Este paso se ejecuta en dos sprints.
> - **Sprint 5:** Implementar modelos (game.models.ts), servicios (GameService, WebSocketService) y GameBoardComponent básico con ActionButtons.
> - **Sprint 6:** Completar drag & drop (CDK), animaciones CSS, ChatWindowComponent y NotificationCenter.

## Archivos a cargar junto a este
- `06-system-logic.md` — todos los eventos WebSocket y su formato
- `PATRONES_DISENO.md` → estructura de PlayerBoard e InPlayPokemon (para ver los modelos)

## Qué construye este paso
El tablero de juego completo en Angular: zona del oponente, zona propia, mano con drag & drop, panel de acciones contextual, chat, notificaciones. Todo sincronizado via WebSocket.

## Prompt listo para el agente

```
Implementá el componente de tablero de juego para el frontend Angular del juego Codemon TCG.
Angular 21+, TypeScript strict, Standalone Components, @angular/cdk/drag-drop.

Eventos WebSocket que llegan:
[pegá 06-system-logic.md completo]

Implementá en src/app/game/:

1. models/game.models.ts:
   Interfaces TypeScript para:
   GameStateDTO, PlayerBoardDTO, InPlayPokemonDTO,
   GameEvent (con eventType, payload), GameAction, StatusCondition (enum), ActionType (enum)

2. services/game.service.ts:
   - createGame(deckId, matchType, botDifficulty?): POST /games
   - processAction(gameId, action): POST /games/{id}/action
   - getState(gameId): GET /games/{id}/state

3. services/websocket.service.ts:
   - connect(gameId, userId, token): conectar a /ws con STOMP+SockJS
   - subscribeToGame(gameId): /topic/game/{gameId} → Observable<GameEvent>
   - subscribeToPrivate(userId): /user/queue/game → Observable<GameEvent>
   - disconnect()
   - onDisconnect: llamar getState() para recuperar estado (reconnect automático)

4. pages/game-board/game-board.component.ts (Standalone):
   - Recibir gameId por route param (:id)
   - Suscribirse a WebSocket al inicializar (ngOnInit), desuscribirse al destruir (ngOnDestroy)
   - Mantener estado local GameStateDTO actualizado por los eventos WebSocket
   - NUNCA modificar estado local optimistamente: esperar confirmación del servidor

5. game-board.component.html — estructura del tablero:
   ZONA OPONENTE (arriba):
   - Activo del oponente: imagen carta, HP como barra de progreso, daño acumulado,
     energías adjuntas (íconos de tipo), condición especial (ícono con color)
   - Banca del oponente: 5 slots, mostrar dorso de carta si hay Pokémon, vacío si no
   - Contador de cartas en mano (número), contador de mazo, premios restantes

   ZONA CENTRAL:
   - Stadium activo si hay (nombre y efectos)

   ZONA PROPIA (abajo):
   - Activo propio: igual que oponente pero con info completa, zona de drag-drop para recibir energías
   - Banca propia: 5 slots con imagen de carta real, drag-drop para recibir energías y evoluciones
   - Mano: cartas visibles con drag-drop como origen (arrastrar a Activo/Banca)
   - Premios: mostrar N cartas boca abajo (solo prizesCount, no las cartas reales)
   - Mazo: cantidad de cartas, botón "Barajar" (decorativo)

6. components/action-buttons/action-buttons.component.ts:
   Botones contextuales según la fase:
   - DRAW_PHASE: ningún botón visible (esperar que el servidor procese)
   - MAIN_PHASE (turno propio): "Terminar Turno", y botones según selección de carta
   - No mostrar "Atacar" si ctx.firstTurnAttackBlocked == true
   - Cada acción envía GameAction al GameEngine via game.service.processAction()

7. components/chat-window/chat-window.component.ts:
   - Suscrito a /topic/game/{id}/chat
   - Scroll automático al mensaje más reciente
   - Input con límite de 100 caracteres
   - Input deshabilitado cuando la partida terminó (status == "FINISHED")
   - Mensajes del BOT visualmente distintos (color diferente, indicador "Bot")

8. components/notification-center/notification-center.component.ts:
   Toast notifications para:
   - KO (propio o del oponente)
   - Premio tomado
   - Condición especial aplicada
   - Nuevo turno

Drag & drop (@angular/cdk/drag-drop):
- La mano es un cdkDropList de origen
- El Activo y cada slot de Banca son cdkDropList de destino
- Al soltar una carta en un destino:
  - Si es Energía → ATTACH_ENERGY al Pokémon destino
  - Si es Pokémon Básico → PLAY_BASIC_POKEMON en Banca
  - Si es Evolución → EVOLVE_POKEMON sobre el Básico destino
  - Si es Trainer → determinar tipo y acción según supertype
- NUNCA modificar el estado local antes de recibir confirmación del servidor

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea
```
front/src/app/game/
  models/game.models.ts
  services/game.service.ts
  services/websocket.service.ts
  pages/game-board/game-board.component.ts + .html + .scss
  components/pokemon-zone/pokemon-zone.component.ts + .html + .scss
  components/bench-zone/bench-zone.component.ts + .html + .scss
  components/hand-zone/hand-zone.component.ts + .html + .scss
  components/chat-window/chat-window.component.ts + .html + .scss
  components/action-buttons/action-buttons.component.ts + .html + .scss
  components/notification-center/notification-center.component.ts + .html + .scss
```

## Errores comunes

- **URL WebSocket distinta en Docker**: usar `environment.wsUrl` para la URL (`/ws` en prod, `http://localhost:8088/ws` en dev)
- **Estado local desincronizado**: NUNCA modificar el estado antes de confirmación del servidor
- **Memory leak en WebSocket**: siempre llamar `disconnect()` en `ngOnDestroy`
- **Drag & drop sin soltar en zona válida**: manejar el evento `dropped` solo si el destino es válido para esa carta
- **CARD_DRAWN sin mano visible**: el evento CARD_DRAWN del servidor actualiza la mano; no asumir que la mano ya está actualizada

## Verificación

Verificación manual en browser:
- [ ] PASS: Drag & drop de energía al Activo envía `ATTACH_ENERGY` al servidor
- [ ] PASS: Panel de acciones muestra/oculta "Atacar" según el turno y fase
- [ ] PASS: Mano del oponente muestra dorsos con cantidad correcta
- [ ] PASS: Chat del Bot tiene delay visible entre mensajes
- [ ] PASS: Notificación de KO aparece cuando un Pokémon es derrotado
- [ ] PASS: Al cerrar y volver a abrir el browser, el estado se recupera via getState()
- [ ] FAIL en cualquier ítem → usar DevTools Network para verificar los eventos WebSocket recibidos

## Dependencias
PASO_S05_03 (GameEngine con WebSocket), PASO_S07_01 (salas) y PASO_S07_02 (matchmaking) para el lobby.
