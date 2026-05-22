# Protocolo WebSocket — Codemon TCG

> **Documento de referencia para el Equipo B.**  
> Describe todos los eventos STOMP que el servidor emite durante una partida.  
> Basado en `06-system-logic.md` (fuente de verdad para las reglas de emisión).

## Conexión

```typescript
// Configuración del cliente STOMP en Angular
const client = new Client({
  brokerURL: 'ws://localhost:8088/ws',
  connectHeaders: {
    Authorization: `Bearer ${accessToken}`
  }
});

// Suscripción al canal de la partida
client.subscribe(`/topic/game/${gameId}`, (message) => {
  const event = JSON.parse(message.body) as GameEvent;
  handleEvent(event);
});

// Suscripción al canal privado del jugador
client.subscribe(`/user/queue/game/${gameId}`, (message) => {
  const event = JSON.parse(message.body) as GameEvent;
  handlePrivateEvent(event);
});
```

## Envío de acciones

El frontend envía acciones al servidor vía:
```typescript
client.publish({
  destination: `/app/game/${gameId}/action`,
  body: JSON.stringify({
    type: 'PLAY_BASIC_POKEMON',  // valor del enum ActionType (ver GLOSARIO sección 4)
    playerId: 1,
    cardId: 'xy1-11',
    extra: { zone: 'ACTIVE' }
  })
});
```

> Los valores del campo `type` en acciones del cliente deben coincidir con `ActionType` del backend (definido en PASO_S03_01).

## Estructura base de un evento

Formato canónico — **debe coincidir con `GameEvent` del backend (PASO_S03_01)** y la sección 4 de `GLOSARIO.md`.

```typescript
interface GameEvent {
  eventType: string;         // SCREAMING_SNAKE_CASE; ej: 'TURN_START', 'CARD_DRAWN'
  gameId: number;            // Long en backend → number en TS
  timestamp: string;         // ISO 8601 UTC, generado por el backend
  payload: Record<string, any>;
  private?: boolean;         // true si es evento privado
  privateTargetUserId?: number | null;  // solo si private = true
}
```

> ⚠️ **Naming**: el campo es `eventType` (no `type`) para alinearse con el DTO Java. El campo `private` está marcado opcional porque solo lo emite el backend cuando aplica.

---

## Tipos de eventos

### GAME_START
**Visibilidad:** Ambos jugadores (canal público `/topic/game/{id}`)  
**Cuándo:** Al iniciar la partida, tras completar el setup.

```json
{
  "eventType": "GAME_START",
  "gameId": 42,
  "timestamp": "2025-01-20T15:00:00Z",
  "payload": {
    "players": [
      { "id": 1, "username": "Hernan" },
      { "id": 2, "username": "Ramiro" }
    ],
    "deckSizes": { "1": 54, "2": 54 },
    "firstPlayerId": 1
  }
}
```

---

### TURN_START
**Visibilidad:** Ambos jugadores

```json
{
  "eventType": "TURN_START",
  "payload": {
    "playerId": 1,
    "turnNumber": 3
  }
}
```

---

### CARD_DRAWN
**Visibilidad:** Solo el dueño de la carta (canal privado `/user/queue/game/{id}`)  
**Cuándo:** Al robar una carta (inicio de turno o efecto de carta).

```json
{
  "eventType": "CARD_DRAWN",
  "payload": {
    "playerId": 1,
    "cardId": "xy1-11",
    "deckRemaining": 47
  }
}
```

> ⚠️ **El oponente solo ve `deckRemaining`**. El `cardId` solo llega al dueño.

---

### POKEMON_PLAYED
**Visibilidad:** Ambos jugadores

```json
{
  "eventType": "POKEMON_PLAYED",
  "payload": {
    "playerId": 1,
    "cardId": "xy1-11",
    "zone": "ACTIVE"
  }
}
```
_zone: `ACTIVE` | `BENCH`_

---

### POKEMON_EVOLVED
**Visibilidad:** Ambos jugadores

```json
{
  "eventType": "POKEMON_EVOLVED",
  "payload": {
    "playerId": 1,
    "fromCardId": "xy1-10",
    "toCardId": "xy1-11",
    "zone": "ACTIVE"
  }
}
```

---

### ENERGY_ATTACHED
**Visibilidad:** Ambos jugadores

```json
{
  "eventType": "ENERGY_ATTACHED",
  "payload": {
    "playerId": 1,
    "energyCardId": "xy1-96",
    "targetPokemonId": "xy1-11"
  }
}
```

---

### TRAINER_PLAYED
**Visibilidad:** Ambos jugadores

```json
{
  "eventType": "TRAINER_PLAYED",
  "payload": {
    "playerId": 1,
    "cardId": "xy1-80",
    "trainerType": "Item",
    "effect": "Healed 30 HP from Venusaur-EX",
    "replacedStadiumOwnerId": null
  }
}
```
_trainerType: `Item` | `Supporter` | `Stadium` | `Tool`_

> **Campo `replacedStadiumOwnerId`** (alinea regla T-05 de `02-turn-flow.md` con A-3 del análisis):
> - Solo se completa cuando `trainerType: "Stadium"` y reemplaza otro Stadium activo en juego.
> - Indica el `userId` del jugador que originalmente había jugado el Stadium reemplazado, para que el motor pueda mover esa carta al descarte de su dueño original.
> - Si no aplica, el campo es `null`.

---

### ABILITY_USED
**Visibilidad:** Ambos jugadores

```json
{
  "eventType": "ABILITY_USED",
  "payload": {
    "playerId": 1,
    "pokemonId": "xy1-11",
    "abilityName": "Mega Kick"
  }
}
```

---

### RETREAT
**Visibilidad:** Ambos jugadores

```json
{
  "eventType": "RETREAT",
  "payload": {
    "playerId": 1,
    "retreatedPokemonId": "xy1-11",
    "newActiveId": "xy1-12",
    "energiesDiscarded": ["xy1-96", "xy1-96"]
  }
}
```

---

### ATTACK_DECLARED
**Visibilidad:** Ambos jugadores  
**Cuándo:** Al anunciar el ataque, antes de resolverlo.

```json
{
  "eventType": "ATTACK_DECLARED",
  "payload": {
    "attackerId": "xy1-11",
    "attackerPlayerId": 1,
    "defenderId": "xy1-25",
    "defenderPlayerId": 2,
    "attackName": "Frog Hop"
  }
}
```

---

### DAMAGE_DEALT
**Visibilidad:** Ambos jugadores  
**Cuándo:** Tras calcular y aplicar el daño final.

```json
{
  "eventType": "DAMAGE_DEALT",
  "payload": {
    "attackerId": "xy1-11",
    "defenderId": "xy1-25",
    "baseDamage": 40,
    "weaknessApplied": true,
    "resistanceApplied": false,
    "finalDamage": 80,
    "defenderCurrentHp": 100,
    "defenderMaxHp": 180
  }
}
```

---

### POKEMON_KO
**Visibilidad:** Ambos jugadores  
**Cuándo:** Cuando un Pokémon alcanza 0 HP.

```json
{
  "eventType": "POKEMON_KO",
  "payload": {
    "pokemonId": "xy1-25",
    "ownerId": 2,
    "prizesToTake": 2
  }
}
```
_prizesToTake: 1 normalmente, 2 si el KO'd es un Pokémon-EX_

---

### PRIZE_TAKEN
**Visibilidad:** Ambos jugadores

```json
{
  "eventType": "PRIZE_TAKEN",
  "payload": {
    "playerId": 1,
    "count": 1,
    "prizesRemaining": 5
  }
}
```

---

### STATUS_APPLIED
**Visibilidad:** Ambos jugadores

```json
{
  "eventType": "STATUS_APPLIED",
  "payload": {
    "targetPokemonId": "xy1-25",
    "status": "POISONED"
  }
}
```
_status: `POISONED` | `BURNED` | `ASLEEP` | `PARALYZED` | `CONFUSED`_

---

### STATUS_REMOVED
**Visibilidad:** Ambos jugadores

```json
{
  "eventType": "STATUS_REMOVED",
  "payload": {
    "targetPokemonId": "xy1-25",
    "status": "POISONED",
    "reason": "RETREATED"
  }
}
```
_reason: `RETREATED` | `EVOLVED` | `WOKE_UP` | `PARALYSIS_EXPIRED`_

---

### BETWEEN_TURNS_DAMAGE
**Visibilidad:** Ambos jugadores  
**Cuándo:** Cuando veneno o quemadura causan daño entre turnos.

```json
{
  "eventType": "BETWEEN_TURNS_DAMAGE",
  "payload": {
    "pokemonId": "xy1-25",
    "status": "POISONED",
    "damageCounters": 10,
    "coinResult": null
  }
}
```

Para BURNED, el coinResult indica si se tiró cara o cruz:
```json
{
  "payload": {
    "status": "BURNED",
    "damageCounters": 20,
    "coinResult": "TAILS"
  }
}
```

---

### COIN_FLIP
**Visibilidad:** Ambos jugadores  
**Cuándo:** Cualquier tirada de moneda (confusión, quemado, dormido, ataques).

```json
{
  "eventType": "COIN_FLIP",
  "payload": {
    "context": "SLEEP_CHECK",
    "result": "HEADS"
  }
}
```
_context: `SLEEP_CHECK` | `BURN_CHECK` | `PARALYSIS_CHECK` | `CONFUSION_CHECK` | `ATTACK_EFFECT`_  
_result: `HEADS` | `TAILS`_

---

### MULLIGAN
**Visibilidad:** Ambos jugadores
**Cuándo:** Cuando un jugador realiza un mulligan (no tiene básico en la mano inicial).

```json
{
  "eventType": "MULLIGAN",
  "payload": {
    "playerId": 2,
    "mulliganCount": 1,
    "extraCardsDrawn": 0
  }
}
```

> **Campo `extraCardsDrawn`** (alinea regla R-SETUP-04 Caso B de `01-setup.md` con A-1 del análisis):
> - Se completa SOLO en el último evento `MULLIGAN` antes de comenzar el turno (cuando el rival decide cuántas cartas extra robar).
> - Fórmula: `extraCardsDrawn = max(0, mulliganCount - 1)`.
> - En los eventos `MULLIGAN` intermedios el valor es `0`.
> - Cuando el rival roba sus cartas extra, se emiten también eventos `CARD_DRAWN` privados al rival con cada `cardId`.

---

### PRIZES_SET
**Visibilidad:** Ambos jugadores

```json
{
  "eventType": "PRIZES_SET",
  "payload": {
    "playerId": 1,
    "count": 6
  }
}
```

---

### SUDDEN_DEATH_START
**Visibilidad:** Ambos jugadores

```json
{
  "eventType": "SUDDEN_DEATH_START",
  "payload": {}
}
```

---

### GAME_OVER
**Visibilidad:** Ambos jugadores

```json
{
  "eventType": "GAME_OVER",
  "payload": {
    "winnerId": 1,
    "loserId": 2,
    "reason": "PRIZES"
  }
}
```
_reason: `PRIZES` | `DECK_EMPTY` | `NO_POKEMON` | `SUDDEN_DEATH` | `CONCEDED` | `TIMEOUT` | `DISCONNECTED`_

---

## Eventos de casos borde (R-CONCEDE / R-TIMEOUT / R-RECONNECT)

> Definidos en `../06-reglas-juego/07-edge-cases.md`. Estos eventos manejan finales no naturales de partida y resiliencia ante desconexiones.

### GAME_CONCEDED
**Visibilidad:** Ambos jugadores
**Cuándo:** Cuando un jugador concede explícitamente, o cuando el motor auto-concede tras 3 timeouts (R-TIMEOUT-03) o por desconexión vencida (R-RECONNECT-03).

```json
{
  "eventType": "GAME_CONCEDED",
  "payload": {
    "concedingPlayerId": 1,
    "winnerId": 2,
    "trigger": "EXPLICIT"
  }
}
```
_trigger: `EXPLICIT` (botón) | `TIMEOUT` (3 timeouts consecutivos) | `DISCONNECTED` (ventana vencida)_

> Se emite **antes** de `GAME_OVER`. Ambos eventos son obligatorios — el cliente puede usar `GAME_CONCEDED` para mostrar mensaje específico ("Tu rival se rindió") y `GAME_OVER` para la lógica común de fin de partida.

---

### TURN_TIMEOUT
**Visibilidad:** Ambos jugadores
**Cuándo:** Al expirar el temporizador de turno sin acción válida del jugador (R-TIMEOUT-02).

```json
{
  "eventType": "TURN_TIMEOUT",
  "payload": {
    "playerId": 1,
    "consecutiveTimeouts": 1
  }
}
```

> Tras emitir este evento, el motor ejecuta `END_TURN` automáticamente en nombre del jugador, salvo cuando `awaitingReplacement = true` (en ese caso se evalúa R-TIMEOUT-03 directamente).
>
> Si `consecutiveTimeouts === 3`, el siguiente evento será `GAME_CONCEDED` con `trigger = "TIMEOUT"`.

---

### RECONNECT_SUCCESS
**Visibilidad:** Solo el jugador reconectado (canal privado `/user/queue/game/{id}`)
**Cuándo:** Tras reconexión exitosa dentro de la ventana de 90 s (R-RECONNECT-02).

```json
{
  "eventType": "RECONNECT_SUCCESS",
  "payload": {
    "playerId": 1,
    "gameStateSnapshot": {
      "...": "estado completo sanitizado, mismo formato que GET /api/games/{id}/state"
    }
  }
}
```

> El campo `gameStateSnapshot` contiene el estado completo del juego sanitizado para el viewer (sin `hand` del rival, sin `deck`, sin `prizes` de ninguno). Permite al cliente reconstruir su UI sin hacer otro request HTTP.

---

### RECONNECT_FAILED
**Visibilidad:** Ambos jugadores
**Cuándo:** Al vencer la ventana de reconexión sin que el jugador desconectado haya vuelto (R-RECONNECT-03).

```json
{
  "eventType": "RECONNECT_FAILED",
  "payload": {
    "playerId": 1,
    "reason": "WINDOW_EXPIRED"
  }
}
```

> Tras este evento, el motor emite automáticamente `GAME_CONCEDED` con `trigger = "DISCONNECTED"` y luego `GAME_OVER` con `reason = "DISCONNECTED"`.

---

## Enum completo de tipos de eventos

```typescript
type GameEventType =
  | 'GAME_START'
  | 'GAME_OVER'
  | 'TURN_START'
  | 'CARD_DRAWN'
  | 'POKEMON_PLAYED'
  | 'POKEMON_EVOLVED'
  | 'ENERGY_ATTACHED'
  | 'TRAINER_PLAYED'
  | 'ABILITY_USED'
  | 'RETREAT'
  | 'ATTACK_DECLARED'
  | 'DAMAGE_DEALT'
  | 'POKEMON_KO'
  | 'PRIZE_TAKEN'
  | 'STATUS_APPLIED'
  | 'STATUS_REMOVED'
  | 'BETWEEN_TURNS_DAMAGE'
  | 'COIN_FLIP'
  | 'MULLIGAN'
  | 'PRIZES_SET'
  | 'SUDDEN_DEATH_START'
  | 'GAME_CONCEDED'
  | 'TURN_TIMEOUT'
  | 'RECONNECT_SUCCESS'
  | 'RECONNECT_FAILED';
```

## Tipos de acciones que puede enviar el frontend

> Los nombres canónicos de acciones viven en el enum `ActionType` del backend (PASO_S03_01 — `com.codemon.game.engine.ActionType`). El cliente debe usar exactamente estos valores.

```typescript
type PlayerActionType =
  | 'CONFIRM_DRAW'                // Confirmar el robo automático del inicio del turno
  | 'PLACE_ACTIVE'                // Colocar Pokémon activo durante setup
  | 'PLACE_BENCH'                 // Colocar Pokémon en banca durante setup
  | 'CONFIRM_SETUP'               // Confirmar el setup completo
  | 'PLAY_BASIC_POKEMON'          // Jugar Pokémon básico desde mano (durante main phase)
  | 'EVOLVE_POKEMON'              // Evolucionar un Pokémon en juego
  | 'ATTACH_ENERGY'               // Adjuntar energía (1 por turno)
  | 'PLAY_ITEM'                   // Jugar carta Trainer tipo Item
  | 'PLAY_SUPPORTER'              // Jugar carta Trainer tipo Supporter (1 por turno)
  | 'PLAY_STADIUM'                // Jugar carta Trainer tipo Stadium
  | 'PLAY_TOOL'                   // Adherir Pokémon Tool a un Pokémon en juego
  | 'RETREAT'                     // Retirar Pokémon activo
  | 'USE_ABILITY'                 // Usar habilidad activada de Pokémon
  | 'DECLARE_ATTACK'              // Declarar ataque (termina la fase principal)
  | 'TAKE_PRIZE'                  // Tomar carta de premio tras KO del rival
  | 'REPLACE_ACTIVE_AFTER_KO'     // Reemplazar Pokémon activo tras KO (alinea con SEC-02 de GAME_ENGINE_DETALLES y A-2 del análisis)
  | 'END_TURN'                    // Terminar turno sin atacar
  | 'CONCEDE';                    // Conceder partida (ver R-CONCEDE-01 en 07-edge-cases.md)
```

### REPLACE_ACTIVE_AFTER_KO (acción del cliente)

Tras un KO, el motor entra en estado `awaitingReplacement = true` y solo aceptará esta acción del jugador cuyo Pokémon fue noqueado, **incluso si no es su turno** (alinea con SEC-02 de `GAME_ENGINE_DETALLES.md`).

Payload mínimo:
```typescript
{
  type: 'REPLACE_ACTIVE_AFTER_KO',
  playerId: 1,
  pokemonInstanceId: 'uuid-del-pokemon-en-banca'  // debe estar en bench del jugador
}
```

Si el jugador no tiene Pokémon en banca → la partida termina inmediatamente con `GAME_OVER` razón `NO_POKEMON` (R-WIN-03).

## Canales STOMP

| Canal | Tipo | Quién recibe | Contenido |
|-------|------|-------------|-----------|
| `/topic/game/{gameId}` | Público | Ambos jugadores | Eventos públicos del juego |
| `/user/queue/game/{gameId}` | Privado | Solo el jugador autenticado | CARD_DRAWN (con cardId), reconexión de estado |
| `/app/game/{gameId}/action` | Envío | Servidor | Acciones del jugador |

---

## Regla de seguridad crítica

> Los eventos públicos **NUNCA** incluyen:
> - Cartas en la mano del oponente (`cardId` en CARD_DRAWN solo va al dueño)
> - El orden de las cartas en el mazo
> - El contenido de las cartas de Premio

El frontend nunca debe intentar inferir estas informaciones de los eventos públicos.
