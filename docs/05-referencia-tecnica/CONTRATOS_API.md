# Contratos de API — Codemon TCG

> **Documento vivo.** Creado en PASO_S00_01. Puede refinarse durante el desarrollo.  
> **Propósito:** Permite al Equipo B construir la UI contra mocks antes de tener el backend real.  
> **Convención de errores:** Todos los errores retornan `{ "error": "ERROR_CODE", "message": "descripción" }`

## URL base

```
Desarrollo:  http://localhost:8088/api
Producción:  http://localhost/api  (via Nginx)
```

## Autenticación

Todos los endpoints (excepto los marcados como **público**) requieren header:
```
Authorization: Bearer <accessToken>
```

---

## 1. Autenticación (`/api/auth`)

### POST /api/auth/register
**Acceso:** Público

**Request:**
```json
{
  "username": "string (3-20 chars, solo letras/números/_)",
  "email": "string (email válido)",
  "password": "string (mín 8 chars, al menos 1 mayúscula y 1 número)"
}
```

**Response 201:**
```json
{
  "message": "Registro exitoso. Revisá tu email para verificar tu cuenta.",
  "userId": 1
}
```

**Errores:** `400 USERNAME_TAKEN`, `400 EMAIL_TAKEN`, `400 VALIDATION_ERROR`

---

### POST /api/auth/login
**Acceso:** Público

**Request:**
```json
{
  "usernameOrEmail": "string",
  "password": "string"
}
```

**Response 200:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
  "refreshToken": "550e8400-e29b-41d4-a716-446655440000",
  "user": {
    "id": 1,
    "username": "Hernan",
    "email": "hernan@codemon.com",
    "emailVerified": true,
    "virtualCurrencyBalance": 500,
    "skillRating": 1000,
    "wins": 5,
    "losses": 3
  }
}
```

**Errores:** `401 INVALID_CREDENTIALS`, `403 EMAIL_NOT_VERIFIED`, `429 RATE_LIMITED`

---

### POST /api/auth/refresh
**Acceso:** Público

**Request:**
```json
{
  "refreshToken": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response 200:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
  "refreshToken": "nuevo-refresh-token-uuid"
}
```

**Errores:** `401 INVALID_REFRESH_TOKEN`, `401 REFRESH_TOKEN_EXPIRED`

---

### POST /api/auth/logout
**Acceso:** Autenticado

**Request:**
```json
{
  "refreshToken": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response 200:**
```json
{ "message": "Sesión cerrada correctamente." }
```

---

### GET /api/auth/me
**Acceso:** Autenticado

**Response 200:**
```json
{
  "id": 1,
  "username": "Hernan",
  "email": "hernan@codemon.com",
  "emailVerified": true,
  "virtualCurrencyBalance": 500,
  "skillRating": 1000,
  "wins": 5,
  "losses": 3,
  "draws": 1,
  "createdAt": "2025-01-15T10:30:00Z"
}
```

---

### POST /api/auth/verify-email
**Acceso:** Público

**Request:**
```json
{
  "code": "123456"
}
```

**Response 200:**
```json
{ "message": "Email verificado correctamente." }
```

**Errores:** `400 INVALID_CODE`, `400 CODE_EXPIRED`, `429 TOO_MANY_ATTEMPTS`

---

### POST /api/auth/resend-verification
**Acceso:** Público

**Request:**
```json
{
  "email": "hernan@codemon.com"
}
```

**Response 200:**
```json
{ "message": "Código reenviado. Revisá tu email." }
```

**Errores:** `400 ALREADY_VERIFIED`, `404 USER_NOT_FOUND`, `429 RATE_LIMITED`

---

## 2. Cartas (`/api/cards`)

### GET /api/cards
**Acceso:** Autenticado  
**Query params:** `page=0`, `size=20`, `sort=name`, `search=string`, `type=Fire`, `supertype=Pokémon`, `rarity=Rare`

**Response 200:**
```json
{
  "content": [
    {
      "id": "xy1-1",
      "name": "Venusaur-EX",
      "number": "1",
      "supertype": "Pokémon",
      "subtypes": ["EX"],
      "rarity": "Ultra Rare",
      "hp": 180,
      "types": ["Grass"],
      "evolvesFrom": "Ivysaur",
      "imageSmallUrl": "http://localhost:8088/minio/codemon-cards/xy1-1-small.jpg",
      "imageLargeUrl": "http://localhost:8088/minio/codemon-cards/xy1-1-large.jpg",
      "attacks": [
        {
          "name": "Frog Hop",
          "cost": ["Grass", "Colorless", "Colorless"],
          "convertedEnergyCost": 3,
          "damage": "40+",
          "text": "Flip a coin. If heads, this attack does 40 more damage."
        }
      ],
      "weaknesses": [{ "type": "Fire", "value": "×2" }],
      "resistances": [],
      "abilities": []
    }
  ],
  "totalElements": 146,
  "totalPages": 8,
  "size": 20,
  "number": 0
}
```

---

### GET /api/cards/{id}
**Acceso:** Autenticado

**Response 200:** Un objeto card con todos los campos (igual al objeto dentro de `content` de arriba).

**Errores:** `404 CARD_NOT_FOUND`

---

## 3. Mazos (`/api/decks`)

### GET /api/decks
**Acceso:** Autenticado

**Response 200:**
```json
[
  {
    "id": 1,
    "name": "Mi Mazo Fuego",
    "description": "Mazo agresivo con Charizard-EX",
    "isFavorite": true,
    "isStarter": false,
    "cardCount": 60,
    "createdAt": "2025-01-15T10:00:00Z",
    "updatedAt": "2025-01-20T15:00:00Z"
  }
]
```

---

### GET /api/decks/{id}
**Acceso:** Autenticado

**Response 200:**
```json
{
  "id": 1,
  "name": "Mi Mazo Fuego",
  "description": "Mazo agresivo con Charizard-EX",
  "isFavorite": true,
  "isStarter": false,
  "cards": [
    { "card": { "id": "xy1-11", "name": "Charizard-EX", ... }, "quantity": 2 },
    { "card": { "id": "xy1-96", "name": "Fire Energy", ... }, "quantity": 14 }
  ],
  "isValid": true,
  "validationErrors": [],
  "createdAt": "2025-01-15T10:00:00Z"
}
```

**Errores:** `404 DECK_NOT_FOUND`, `403 FORBIDDEN`

---

### POST /api/decks
**Acceso:** Autenticado

**Request:**
```json
{
  "name": "Mi Mazo Fuego",
  "description": "Mazo agresivo con Charizard-EX",
  "cards": [
    { "cardId": "xy1-11", "quantity": 2 },
    { "cardId": "xy1-96", "quantity": 14 }
  ]
}
```

**Response 201:** Objeto deck completo (igual a GET /api/decks/{id})

**Errores:** `400 VALIDATION_ERROR`, `400 INVALID_CARD_ID`

---

### PUT /api/decks/{id}
**Acceso:** Autenticado

**Request:** Igual a POST /api/decks

**Response 200:** Objeto deck actualizado

**Errores:** `404 DECK_NOT_FOUND`, `403 FORBIDDEN`, `400 VALIDATION_ERROR`

---

### DELETE /api/decks/{id}
**Acceso:** Autenticado

**Response 204:** Sin cuerpo

**Errores:** `404 DECK_NOT_FOUND`, `403 FORBIDDEN`

---

### POST /api/decks/{id}/validate
**Acceso:** Autenticado

**Response 200:**
```json
{
  "valid": false,
  "errors": [
    "El mazo debe contener exactamente 60 cartas (tiene 58)",
    "La carta 'Charizard-EX' supera el máximo de 4 copias (tiene 5)"
  ]
}
```

---

### GET /api/decks/starter
**Acceso:** Autenticado  
**Descripción:** Retorna los mazos starter disponibles para nuevos jugadores.

**Response 200:** Lista de objetos deck con `isStarter: true`

---

## 4. Partidas (`/api/games`)

### POST /api/games/pve
**Acceso:** Autenticado  
**Descripción:** Inicia una partida contra el bot.

**Request:**
```json
{
  "deckId": 1,
  "botDifficulty": "EASY",
  "botPersonality": "HERNAN"
}
```
_botDifficulty: EASY | MEDIUM | HARD_  
_botPersonality: HERNAN | SANTORO | RAMIRO_

**Response 201:**
```json
{
  "gameId": "550e8400-e29b-41d4-a716-446655440001",
  "status": "SETUP",
  "webSocketTopic": "/topic/game/550e8400-e29b-41d4-a716-446655440001"
}
```

**Errores:** `400 INVALID_DECK`, `404 DECK_NOT_FOUND`

---

### GET /api/games/{gameId}
**Acceso:** Autenticado  
**Descripción:** Estado actual de la partida (para reconexión).

**Response 200:** Estado completo del juego (GameStateDTO — definir en implementación)

---

### POST /api/games/{gameId}/action
**Acceso:** Autenticado
**Descripción:** Envía una acción del jugador. Preferir WebSocket; este endpoint es fallback.

**Request:**
```json
{
  "type": "PLAY_BASIC_POKEMON",
  "payload": { "cardId": "xy1-11", "zone": "ACTIVE" }
}
```

> Los valores válidos del campo `type` están listados en el enum `PlayerActionType` de `PROTOCOLO_WEBSOCKET.md` (alineados con el enum Java `ActionType` de PASO_S03_01). Incluye `REPLACE_ACTIVE_AFTER_KO` para reemplazar el Pokémon activo tras un KO.

**Response 200:** Estado actualizado post-acción

**Errores:** `400 INVALID_ACTION`, `400 NOT_YOUR_TURN`, `403 FORBIDDEN`

---

### POST /api/games/{gameId}/concede
**Acceso:** Autenticado
**Descripción:** El jugador autenticado concede la partida. Definido por R-CONCEDE-01 en `../06-reglas-juego/07-edge-cases.md`.

**Request:** body vacío (`{}`).

**Response 200:**
```json
{
  "gameId": 42,
  "endReason": "CONCEDED",
  "winnerId": 2
}
```

**Comportamiento:**
- El motor transita a `GAME_OVER` con `reason = "CONCEDED"` (R-CONCEDE-03).
- Emite los eventos `GAME_CONCEDED` y `GAME_OVER` por WebSocket a ambos jugadores.
- Persiste `games.end_reason = 'CONCEDED'`.
- En partidas ranked, el concesor recibe la derrota completa para ELO/liga (R-CONCEDE-02).

**Errores:**
- `403 NOT_A_PARTICIPANT` — el jugador autenticado no es participante de la partida.
- `409 GAME_ALREADY_OVER` — la partida ya tiene `end_reason` asignado (no se puede conceder dos veces).
- `404 GAME_NOT_FOUND` — `gameId` inexistente.

---

## 5. Salas Privadas (`/api/rooms`)

### POST /api/rooms
**Acceso:** Autenticado

**Request:**
```json
{ "deckId": 1 }
```

**Response 201:**
```json
{
  "roomCode": "ABC123",
  "creatorId": 1,
  "status": "WAITING",
  "expiresAt": "2025-01-20T15:10:00Z"
}
```

---

### GET /api/rooms/{code}
**Acceso:** Autenticado

**Response 200:**
```json
{
  "roomCode": "ABC123",
  "status": "WAITING",
  "players": [
    { "userId": 1, "username": "Hernan", "ready": true }
  ],
  "expiresAt": "2025-01-20T15:10:00Z"
}
```

**Errores:** `404 ROOM_NOT_FOUND`, `410 ROOM_EXPIRED`

---

### POST /api/rooms/{code}/join
**Acceso:** Autenticado

**Request:**
```json
{ "deckId": 2 }
```

**Response 200:** Estado de la sala (igual a GET /api/rooms/{code})

**Errores:** `404 ROOM_NOT_FOUND`, `409 ROOM_FULL`, `410 ROOM_EXPIRED`, `400 INVALID_DECK`

---

### DELETE /api/rooms/{code}
**Acceso:** Autenticado (solo el creador)

**Response 204:** Sin cuerpo

---

## 6. Matchmaking (`/api/matchmaking`)

### POST /api/matchmaking/queue
**Acceso:** Autenticado

**Request:**
```json
{ "deckId": 1 }
```

**Response 200:**
```json
{
  "status": "QUEUED",
  "queuePosition": null,
  "estimatedWaitSeconds": null
}
```

**Errores:** `400 ALREADY_IN_QUEUE`, `400 INVALID_DECK`

---

### DELETE /api/matchmaking/queue
**Acceso:** Autenticado

**Response 200:**
```json
{ "status": "CANCELLED" }
```

---

### GET /api/matchmaking/status
**Acceso:** Autenticado

**Response 200:**
```json
{
  "status": "WAITING",
  "joinedAt": "2025-01-20T15:00:00Z"
}
```
_status: WAITING | MATCHED | CANCELLED | TIMEOUT_

---

## 7. Colección (`/api/collection`)

### GET /api/collection
**Acceso:** Autenticado  
**Query params:** `page=0`, `size=20`, `sort=name`, `owned=true`

**Response 200:**
```json
{
  "content": [
    {
      "card": { "id": "xy1-1", "name": "Venusaur-EX", ... },
      "quantity": 2,
      "obtainedDate": "2025-01-15T10:00:00Z"
    }
  ],
  "totalElements": 50,
  "totalPages": 3
}
```

---

### GET /api/collection/stats
**Acceso:** Autenticado

**Response 200:**
```json
{
  "uniqueCards": 50,
  "totalCards": 120,
  "commonCount": 40,
  "uncommonCount": 30,
  "rareCount": 20,
  "ultraRareCount": 8,
  "secretRareCount": 2,
  "completionPercentage": 34.2
}
```

---

## 8. Sobres (`/api/boosters`)

### GET /api/boosters
**Acceso:** Autenticado

**Response 200:**
```json
[
  {
    "id": 1,
    "name": "Sobre XY Kalos Starter Set",
    "description": "10 cartas del set base XY1",
    "priceUsd": 3.99,
    "priceCoins": 100,
    "cardsPerPack": 10,
    "imageUrl": "http://localhost:8088/minio/codemon-cards/booster-xy1.jpg"
  }
]
```

---

### POST /api/boosters/{id}/purchase
**Acceso:** Autenticado

**Request:**
```json
{
  "paymentMethod": "COINS",
  "quantity": 1
}
```
_paymentMethod: COINS | MERCADO_PAGO_

**Response para COINS 201:**
```json
{
  "purchaseId": 5,
  "cards": [
    { "id": "xy1-11", "name": "Charizard-EX", "rarity": "Ultra Rare", ... },
    ...
  ],
  "remainingCoins": 400
}
```

**Response para MERCADO_PAGO 201:**
```json
{
  "paymentUrl": "https://www.mercadopago.com.ar/checkout/v1/...",
  "preferenceId": "12345678-abc"
}
```

**Errores:** `400 INSUFFICIENT_COINS`, `404 BOOSTER_NOT_FOUND`

---

### POST /api/boosters/open/{userBoosterPackId}
**Acceso:** Autenticado

**Response 200:**
```json
{
  "cards": [
    { "id": "xy1-11", "name": "Charizard-EX", "rarity": "Ultra Rare", "isNew": true },
    { "id": "xy1-96", "name": "Fire Energy", "rarity": "Common", "isNew": false }
  ]
}
```

**Errores:** `404 PACK_NOT_FOUND`, `400 PACK_ALREADY_OPENED`

---

## 9. Pagos (`/api/payments`)

### GET /api/payments/status/{paymentId}
**Acceso:** Autenticado

**Response 200:**
```json
{
  "paymentId": 5,
  "status": "COMPLETED",
  "amountUsd": 3.99,
  "completedAt": "2025-01-20T15:05:00Z"
}
```

---

### POST /api/payments/webhook
**Acceso:** Público (llamado por Mercado Pago)  
**Descripción:** Webhook para notificaciones de pago. Solo para uso interno del servidor de MP.

---

## 10. Leaderboard (`/api/leaderboard`)

### GET /api/leaderboard
**Acceso:** Autenticado  
**Query params:** `page=0`, `size=20`

**Response 200:**
```json
{
  "content": [
    {
      "rank": 1,
      "userId": 3,
      "username": "Santoro",
      "skillRating": 1850,
      "peakRating": 1900,
      "wins": 45,
      "losses": 10,
      "winPercentage": 81.8
    }
  ],
  "totalElements": 250,
  "totalPages": 13,
  "currentUserRank": 42
}
```

---

## 11. Noticias (`/api/news`)

### GET /api/news
**Acceso:** Autenticado  
**Query params:** `page=0`, `size=10`, `category=UPDATE`  
_category: UPDATE | EVENT | MAINTENANCE | ANNOUNCEMENT_

**Response 200:**
```json
{
  "content": [
    {
      "id": 1,
      "title": "Nuevas cartas del set XY2 disponibles",
      "content": "A partir de hoy pueden conseguir...",
      "category": "UPDATE",
      "author": { "id": 1, "username": "admin" },
      "publishedAt": "2025-01-20T12:00:00Z"
    }
  ],
  "totalElements": 15,
  "totalPages": 2
}
```

---

### GET /api/news/{id}
**Acceso:** Autenticado

**Response 200:** Objeto noticia completo.

---

### POST /api/news
**Acceso:** Admin

**Request:**
```json
{
  "title": "Nuevas cartas disponibles",
  "content": "Texto completo de la noticia...",
  "category": "UPDATE"
}
```

**Response 201:** Objeto noticia creado.

---

## 12. Amigos (`/api/friends`)

### GET /api/friends
**Acceso:** Autenticado

**Response 200:**
```json
[
  {
    "friendshipId": 1,
    "friend": {
      "id": 2,
      "username": "Ramiro",
      "skillRating": 1200,
      "online": true
    },
    "since": "2025-01-10T09:00:00Z"
  }
]
```

---

### GET /api/friends/requests
**Acceso:** Autenticado

**Response 200:**
```json
{
  "received": [
    {
      "friendshipId": 5,
      "from": { "id": 3, "username": "Santoro", "skillRating": 1850 },
      "sentAt": "2025-01-19T14:00:00Z"
    }
  ],
  "sent": []
}
```

---

### POST /api/friends/request
**Acceso:** Autenticado

**Request:**
```json
{ "username": "Santoro" }
```

**Response 201:**
```json
{ "friendshipId": 5, "status": "PENDING" }
```

**Errores:** `404 USER_NOT_FOUND`, `409 ALREADY_FRIENDS`, `409 REQUEST_ALREADY_SENT`, `400 CANNOT_ADD_YOURSELF`

---

### PUT /api/friends/{friendshipId}/accept
**Acceso:** Autenticado

**Response 200:**
```json
{ "status": "ACCEPTED" }
```

---

### PUT /api/friends/{friendshipId}/reject
**Acceso:** Autenticado

**Response 200:**
```json
{ "status": "REJECTED" }
```

---

### DELETE /api/friends/{friendshipId}
**Acceso:** Autenticado

**Response 204:** Sin cuerpo.

---

## 13. Usuarios (`/api/users`)

### GET /api/users/{id}/profile
**Acceso:** Autenticado

**Response 200:**
```json
{
  "id": 2,
  "username": "Ramiro",
  "skillRating": 1200,
  "wins": 20,
  "losses": 15,
  "draws": 2,
  "totalGames": 37,
  "winPercentage": 54.1,
  "createdAt": "2025-01-01T00:00:00Z"
}
```

---

### PUT /api/users/profile
**Acceso:** Autenticado

**Request:**
```json
{
  "username": "NuevoUsername"
}
```

**Response 200:** Perfil actualizado.

---

## 14. OAuth2

Los flujos OAuth2 son manejados por Spring Security. El frontend solo necesita redirigir al usuario:

```
GET /oauth2/authorization/google   → redirige a Google
GET /oauth2/authorization/github   → redirige a GitHub
```

Tras la autenticación exitosa, Spring redirige a:
```
GET /oauth2/callback?token=<accessToken>&refreshToken=<refreshToken>
```

El frontend captura los tokens de los query params y los guarda en localStorage.

---

## Paginación (convención global)

Todos los endpoints de listado usan el mismo formato:

```json
{
  "content": [...],
  "totalElements": 146,
  "totalPages": 8,
  "size": 20,
  "number": 0,
  "first": true,
  "last": false
}
```

Query params estándar: `page=0` (0-indexed), `size=20`, `sort=fieldName,asc|desc`

---

## Códigos de error globales

| Código HTTP | Código de error | Cuándo |
|-------------|----------------|--------|
| 400 | VALIDATION_ERROR | Campos inválidos |
| 401 | UNAUTHORIZED | Sin token o token inválido |
| 403 | FORBIDDEN | Sin permiso para el recurso |
| 404 | NOT_FOUND | Recurso no existe |
| 409 | CONFLICT | Estado conflictivo (ej: usuario ya existe) |
| 429 | RATE_LIMITED | Demasiadas requests |
| 500 | INTERNAL_ERROR | Error interno del servidor |
