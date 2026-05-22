# Especificacion de Producto - Codemon TCG

Proyecto fullstack para implementar una version jugable de Pokemon TCG con autenticacion avanzada, sistema de monetizacion, coleccion de cartas y matchmaking online.

Este documento describe el producto y sus requerimientos funcionales. La planificacion vigente no se organiza por fases: vive en Scrum, epicas, historias de usuario, tareas tecnicas, sprints y gates dentro de [docs/02-planificacion/](../02-planificacion/README.md).

## Stack tecnológico

- Backend: Java 21 + Spring Boot 3.x
- Frontend: Angular 21+ (Standalone Components, TypeScript strict) + Tailwind CSS 3 (utility-first)
- Base de datos: PostgreSQL
- ORM: Spring Data JPA + Hibernate
- Tiempo real: WebSockets (STOMP)
- Seguridad: JWT (access token + refresh token en BD) + 2FA por Email
- Monetización: Mercado Pago API
- Cache: Redis (para cola de matchmaking, cooldown de sobres)
- Calidad: JUnit 5, Mockito, JaCoCo, Swagger/OpenAPI
- Flujo de trabajo: Git / GitFlow

---

## Objetivo Principal

Construir una aplicación completa de Pokemon TCG que permita:

**Autenticación y Seguridad:**
- Registrarse con usuario, contraseña (confirmada), email
- Verificación por código 2FA enviado por email (válido 30 minutos)
- Login con JWT (access token 15 min + refresh token 7 días)
- Logout revocando refresh token

**Monetización y Colección:**
- Comprar Booster Packs via Mercado Pago (moneda virtual)
- Abrir sobres cada 24 horas (cooldown) con cartas aleatorias
- Acumular colección personal de cartas (con rarity: Common/Uncommon/Rare/Holographic)
- Ver progreso de colección

**Construcción de Mazos:**
- Buscar cartas del set `xy1` (desde BD local)
- Crear mazos propios usando: starter decks (ilimitado) + cartas coleccionadas (posesión limitada)
- Validar mazos (60 cartas, 1+ Pokémon Básico, máx 4 copias, máx 4 Energías Especiales, etc.)
- Marcar mazos como favoritos

**Gameplay Online:**
- Jugar en **cola de matchmaking ranked** (búsqueda automática de rival, ELO/skill rating)
- Crear/unirse a **salas privadas** (código 6 caracteres, casual)
- Jugar **vs Bot** (3 niveles: EASY, MEDIUM, HARD, sin ranking)
- Partidas en tiempo real con WebSockets
- Chat durante la partida (usuario a usuario, o usuario vs Bot)
- Bot con 3 personalidades argentinas (Hernán, Santoro, Ramiro) que picantean

**Estadísticas y Ranking:**
- Leaderboard global por win/loss ratio (solo partidas ranked)
- Estadísticas personales: partidas jugadas, victorias, derrotas, empates
- Perfil de usuario con historial de compras

**Persistencia:**
- Estado completo de la partida (snapshots después de cada acción)
- Historial de mensajes de chat
- Transacciones de pago y receipt de Mercado Pago

---

## Arquitectura de Alto Nivel

```
~/codemon/                         ← directorio de trabajo de los equipos
├── api/
│   └── src/main/java/com/codemon/
│       ├── auth/              # Autenticación JWT + 2FA
│       ├── cards/             # Catálogo de cartas
│       ├── decks/             # CRUD de mazos
│       ├── game/              # Motor de juego
│       │   ├── engine/        # GameEngine (orquestador)
│       │   ├── rules/         # Validaciones de juego
│       │   ├── damage/        # Cálculo de daño
│       │   ├── bot/           # Estrategia del Bot + chat
│       │   └── events/        # Eventos de juego
│       ├── lobby/             # Matchmaking + salas privadas
│       ├── payment/           # Integración Mercado Pago
│       ├── booster/           # Sistema de sobres
│       ├── collection/        # Colección de cartas del usuario
│       ├── users/             # Perfil y estadísticas
│       ├── chat/              # Mensajes en tiempo real
│       └── shared/            # DTOs, excepciones, utils
├── front/
│   └── src/app/
│       ├── auth/
│       ├── home/
│       ├── cards/
│       ├── decks/
│       ├── lobby/
│       ├── game/
│       ├── shop/
│       ├── collection/
│       ├── leaderboard/
│       └── profile/
├── docker-compose.yml             ← copiado de docs/07-infraestructura/
├── nginx.conf                     ← gateway unificado en http://localhost:8088
└── .env                           ← variables de entorno (no commitear)
```

**Documentación del proyecto** (en el repositorio):
```
docs/01-producto/             ← README completo, tecnologías, estructura
docs/02-planificacion/        ← Sprints, backlog, épicas, gitflow, workflow
docs/03-equipos/              ← Guías Equipo A, B, C + primer día
docs/04-diseno-ui/            ← Mockups HTML (tablero, lobby, login, launcher)
docs/05-referencia-tecnica/   ← Contratos API, schema BD, glosario, mocks, WebSocket
docs/06-reglas-juego/         ← Reglas XY1 completas (7 archivos)
docs/07-infraestructura/      ← Dockerfiles de referencia, nginx, monitoreo
docs/08-desarrollo-con-ia/    ← Convenciones, 92 pasos de implementación, trazabilidad
docs/09-handoff/              ← Documentos de entrega
```

---

## Requerimientos funcionales por area

### Base del proyecto

✅ Monorepo estructurado
✅ Docker Compose con PostgreSQL, API y Front
✅ Git/GitFlow configurado
✅ Scripts de inicio/parada

---

### Backend fundacional

**Objetivo:** Estructurar la aplicación Spring Boot

**Pasos:**
1. Crear Spring Boot 3.x con Java 21
2. Organizar por dominios: `auth`, `cards`, `deck`, `game`, `lobby`, `payment`, `booster`, `collection`, `users`, `chat`, `shared`
3. Configurar Spring Data JPA + Hibernate
4. Agregar validaciones globales (@Valid), logging (SLF4J), manejo de errores (@ControllerAdvice)
5. Publicar Swagger/OpenAPI en `/swagger-ui.html`
6. Crear entidades JPA para todas las tablas

**Requerimientos cubiertos:**
- RNF-02 (Calidad y buenas prácticas)
- RNF-05 (Seguridad)

---

### Modelo de datos y persistencia

**Objetivo:** Crear schema completo y seed de datos

**Tablas necesarias:**

1. **users** (existente, extendida)
   - id, username, email, password_hash, email_verified (boolean), virtual_currency_balance, skill_rating, wins, losses, draws, created_at

2. **email_verifications** (2FA)
   - id, user_id, code_hash, code_expires_at, attempts_count, created_at

3. **cards_catalog**
   - id (PK string), name, set_id/set_code, supertype, subtypes, types, rarity, hp, attacks, weaknesses, resistances, retreat_cost, image_small_url, image_large_url, created_at
   - Las imagenes no se guardan como BYTEA: el seed descarga `images.small` e `images.large` desde `xy1.json`, las sube a MinIO y guarda las URLs publicas en esta tabla.

5. **decks**
   - id, user_id (nullable para starters), name, description, is_favorite, created_at, updated_at

6. **deck_cards**
   - id, deck_id, card_id, quantity

7. **booster_packs**
   - id, name, price_coins, rarity_distribution (JSON), description

8. **booster_pack_cards**
   - id, booster_pack_id, card_id, rarity

9. **user_booster_packs**
   - id, user_id, booster_pack_id, obtained_at, opened_at (nullable)

10. **user_collection**
    - id, user_id, card_id, quantity, obtained_date

11. **payment_records**
    - id, user_id, amount_usd, amount_coins, mercado_pago_transaction_id, status (PENDING|COMPLETED|FAILED), created_at

12. **user_payments_webhooks**
    - id, mercado_pago_event_id, payload (JSON), processed_at

13. **skill_ratings**
    - id, user_id, current_rating (ELO), wins, losses, total_games, updated_at

14. **queue_entries**
    - id, user_id, deck_id, skill_rating, join_time, status (WAITING|MATCHED|CANCELLED)

15. **game_rooms**
    - id, creator_id, room_code (unique, 6 chars), status (WAITING|ACTIVE|FINISHED), max_players, created_at, expires_at

16. **game_room_players**
    - id, room_id, user_id, deck_id, join_time

17. **games** (extendida)
    - id, match_type (QUEUE|ROOM|PVE), room_code (nullable), player1_id, player2_id (nullable si PVE), bot_difficulty (nullable), status, started_at, ended_at, winner_id, created_at

18. **game_state_snapshots**
    - id, game_id, turn_number, state_json (completo, JSONB), created_at

19. **game_events**
    - id, game_id, event_type (TURN_START|ATTACK|DAMAGE|KO|PRIZE|etc), payload (JSON), created_at

20. **game_chat_messages**
    - id, game_id, user_id (nullable si bot), username, message, message_type (USER|BOT|SYSTEM), created_at

21. **refresh_tokens** (existente)
    - id, user_id, token_hash, expires_at, revoked_at

**Vistas materializadas:**
- `leaderboard` (user_id, username, wins, losses, draws, ratio, total_games, skill_rating) - actualizada post-partida
- `user_collection_stats` (user_id, total_cards, duplicates, rarity_distribution) - actualizada al abrir sobre

**Pasos:**
1. Crear migraciones Flyway V1-V15 (esquema + índices + constraints)
2. Seed de cartas XY1 desde `xy1.json` (146 cartas), copiado como `api/src/main/resources/seed/cards.json`
3. Seed de starter decks (5-10 mazos pre-armados)
4. Descargar imagenes desde `images.pokemontcg.io`, subirlas a MinIO y guardar `image_small_url`/`image_large_url`
5. Script para recrear vistas

**Requerimientos cubiertos:**
- RF-02, RF-03, RF-04, RF-05
- RNF-01 (Rendimiento del sistema)

---

### Autenticacion avanzada (2FA + Email)

**Objetivo:** Implementar registro seguro con verificación por email

**Endpoints:**

1. `POST /auth/register`
   - Input: { username, email, password, confirmPassword }
   - Validaciones: email único, password == confirmPassword, >8 chars, 1+ mayúscula, 1+ número
   - Crea usuario con email_verified=false
   - Genera código 2FA (6 dígitos), hasheado con BCrypt + salt
   - Envía email con código
   - Response: { userId, message: "Verifica tu email" }

2. `POST /auth/verify-email`
   - Input: { userId, code }
   - Validaciones: código válido, no expirado (30 min), intentos < 5
   - Si falla intento: incrementa attempts_count
   - Si 5 intentos: bloquea 15 minutos
   - Si éxito: email_verified=true, borra entrada verificación
   - Response: { accessToken, refreshToken }

3. `POST /auth/resend-code`
   - Input: { userId }
   - Rate limit: máximo 1 reintento cada 60 segundos
   - Genera nuevo código, envía email
   - Response: { message: "Código reenviado" }

4. `POST /auth/login` (modificado)
   - Input: { usernameOrEmail, password }
   - Validaciones: usuario existe, password correcto, email_verified=true
   - Si email no verificado: responde con estado "email_not_verified", pide re-envío de código
   - Si verificado: genera access + refresh token
   - Response: { accessToken, refreshToken, expiresIn: 900 }

5. `POST /auth/refresh` (existente)
   - Valida refresh token, emite nuevo access token

6. `POST /auth/logout`
   - Revoca refresh token en BD
   - Response: { message: "Logout exitoso" }

**Servicios:**

- `EmailVerificationService`
  - `generateCode()` → 6 dígitos aleatorios
  - `hashCode(code)` → BCrypt hash
  - `validateCode(userId, code)` → boolean
  - `markAsVerified(userId)` → void
  - `blockUserTemporarily(userId)` → bloquea por 15 min en Redis

- `EmailService`
  - `sendVerificationCode(email, code)` → envía por SMTP/Mailgun/SendGrid
  - Templating HTML para email

- `AuthService` (extendida)
  - Llama a EmailVerificationService post-registro

**Tabla nueva:** `email_verifications`

**Requerimientos cubiertos:**
- RF-08 (Autenticación Avanzada)
- RNF-05 (Seguridad)

**Notas de implementación:**
- Usar Spring Security Filter para JWT
- Rate limiting con Bucket4j o similar
- Tests: código válido, expirado, múltiples intentos, etc.

---

### Catalogo de cartas e imagenes

**Objetivo:** Servir cartas desde BD sin URLs externas

**Endpoints:**

1. `GET /cards?set=xy1&name=...&supertype=...&rarity=...&page=0&size=20`
   - Retorna lista paginada de cartas con metadata
   - Response: { content: [{id, name, type, rarity, hp, imageSmallUrl, imageLargeUrl}], totalPages, currentPage }

2. `GET /cards/{cardId}`
   - Retorna metadata completa de carta
   - Response: { id, name, set_code, hp, attacks: [{name, damage, description}], ability, ... }

3. Imagenes de cartas
   - No hay endpoint binario de imagen como contrato canonico.
   - El frontend carga `imageSmallUrl`/`imageLargeUrl` directamente desde MinIO.
   - Fallback: imagen placeholder si la URL de MinIO no responde.

**Servicio:**

- `CardService`
  - `findByCriteria(set, name, supertype, rarity, page)` → Page<CardDTO>
  - `findById(cardId)` → CardDTO

**Requerimientos cubiertos:**
- RF-02 (Tipos de cartas)
- RNF-01 (Rendimiento)

---

### Constructor de mazos

**Objetivo:** CRUD de mazos con validación de reglas XY1

**Endpoints:**

1. `POST /decks`
   - Input: { userId, name, description }
   - Crea mazo vacío
   - Response: { deckId, name, cards: [] }

2. `GET /decks?userId=X`
   - Retorna mazos del usuario (propios + starters)
   - Response: [{ id, name, cardCount, isValid, isFavorite }]

3. `GET /decks/{deckId}`
   - Retorna mazo completo con validación
   - Response: { id, name, cards: [{cardId, name, quantity}], errors: [], isValid: boolean }

4. `PUT /decks/{deckId}`
   - Input: { name, description, cards: [{cardId, quantity}] }
   - Valida reglas antes de guardar
   - Response: { deckId, cards, errors, isValid }

5. `DELETE /decks/{deckId}`
   - Borra mazo (solo si es del usuario)
   - Response: { message: "Mazo eliminado" }

6. `POST /decks/{deckId}/validate`
   - Valida mazo sin guardar
   - Response: { isValid, errors: [{ rule, message }] }

7. `PUT /decks/{deckId}/favorite`
   - Toggle de favorito
   - Response: { isFavorite }

8. `GET /decks/starters`
   - Lista mazos pre-armados del sistema
   - Response: [{ id, name, cards, isFavorite }]

9. `POST /decks/{starterId}/copy`
   - Copia starter a mazos del usuario
   - Response: { newDeckId, name, cards }

**Validaciones de Reglas XY1:**

- ✓ Exactamente 60 cartas
- ✓ Mínimo 1 Pokémon Básico
- ✓ Máximo 4 copias del mismo nombre (excepto Energía Básica ilimitada)
- ✓ Máximo 4 Energías Especiales
- ✓ Máximo 1 carta ACE SPEC
- ✓ Máximo 1 Stadio en juego (se valida en gameplay, pero advertir en builder)

**Servicio:**

- `DeckService`
  - `createDeck(userId, name)` → Deck
  - `addCardToDeck(deckId, cardId, quantity)` → void
  - `validateDeck(deck)` → List<ValidationError>

- `DeckValidationService`
  - `validateCardCount(deck)` → boolean
  - `validateBasicPokemon(deck)` → boolean
  - `validateCardCopies(deck)` → List<ValidationError>
  - etc. (una función por regla)

**Requerimientos cubiertos:**
- RF-04 (Construcción de mazos)
- RNF-02 (Calidad)

---

### Sistema de pago (Mercado Pago)

**Objetivo:** Integración con Mercado Pago para compra de sobres

**Endpoints:**

1. `POST /payments/create-preference`
   - Input: { boosterPackId, quantity }
   - Crea preferencia en Mercado Pago API
   - Response: { paymentUrl, preferenceId }

2. `POST /webhooks/mercado-pago`
   - Webhook del servidor de Mercado Pago
   - Escucha eventos: payment.created, payment.updated
   - Si status=COMPLETED: acredita moneda virtual a usuario
   - Guarda en `payment_records` y `user_payments_webhooks`
   - Response: 200 OK

3. `GET /users/{userId}/wallet`
   - Retorna saldo de moneda virtual
   - Response: { balance: 5000, lastTransaction: {...} }

4. `GET /users/{userId}/payment-history`
   - Historial de compras con paginación
   - Response: [{ id, amount_usd, amount_coins, date, status }]

**Servicio:**

- `PaymentService`
  - `createPreference(userId, boosterPackId, quantity)` → PreferenceDTO
  - `processWebhook(eventPayload)` → void
  - `creditUserCoins(userId, coins)` → void
  - Usa SDK oficial de Mercado Pago

- `WalletService`
  - `getBalance(userId)` → long
  - `deductCoins(userId, amount)` → void
  - Transaccional para evitar race conditions

**Configuración:**
- Variables de entorno: MERCADO_PAGO_ACCESS_TOKEN, WEBHOOK_SECRET
- URLs: dev usa sandbox.mercadopago.com, prod usa api.mercadopago.com

**Requerimientos cubiertos:**
- RF-09 (Sistema de Pago)
- RNF-05 (Seguridad)

**Notas de implementación:**
- NUNCA guardar tarjetas ni números de tarjeta (delegar a Mercado Pago)
- Idempotencia en webhooks (guardar event_id para evitar duplicados)
- Log de todas las transacciones
- Tests con Mercado Pago sandbox

---

### Sistema de sobres booster

**Objetivo:** Compra, cooldown y apertura de sobres

**Endpoints:**

1. `GET /booster-packs`
   - Lista tipos de sobres disponibles
   - Response: [{ id, name, price_coins, description, rarity_dist }]

2. `POST /users/{userId}/booster-packs`
   - Input: { boosterPackId, quantity }
   - Valida: usuario tiene saldo >= precio * quantity
   - Deduce moneda, crea entries en `user_booster_packs`
   - Response: { boosterPackIds: [...], balance: 3000 }

3. `GET /users/{userId}/booster-packs`
   - Lista sobres del usuario (abiertos y sin abrir)
   - Indica si puede abrir (cooldown)
   - Response: [{ id, boosterPackId, name, openedAt, canOpen: boolean, cooldownEndsAt }]

4. `POST /users/{userId}/booster-packs/{boosterPackEntryId}/open`
   - Abre un sobre
   - Valida: no abierto, cooldown respetado
   - Genera cartas aleatorias según rarity_distribution
   - Agrega a `user_collection`
   - Guarda open_time en `user_booster_packs`
   - Setea próximo cooldown en Redis (24 horas)
   - Response: { cardsObtained: [{cardId, name, rarity}], newBalance, nextCooldown }

5. `GET /users/{userId}/booster-packs/cooldown-status`
   - Info del cooldown actual
   - Response: { canOpenNow: boolean, nextAvailableAt: timestamp }

**Servicio:**

- `BoosterPackService`
  - `purchaseBoosterPack(userId, boosterPackId, quantity)` → void
  - `openBoosterPack(userId, entryId)` → List<Card>
  - `getBoosterPacksForUser(userId)` → List<BoosterPackDTO>
  - Usa Redis para cooldown (key: `booster:cooldown:{userId}`)

- `CardGenerationService`
  - `generateCardsFromBooster(boosterPackId)` → List<Card>
  - Respeta rarity_distribution (ej: 60% common, 25% uncommon, 12% rare, 3% holographic)
  - Puede haver garantías (ej: 1 raro cada 10 sobres)

**Tabla nueva:** `user_booster_packs`, `booster_pack_cards`, `booster_packs`

**Requerimientos cubiertos:**
- RF-10 (Sistema de Sobres)
- RNF-01 (Performance con Redis)

**Notas de implementación:**
- Cooldown en Redis (más rápido que BD)
- Log cada apertura de sobre para analytics
- Tests: rarity correcta, cooldown, wallet deduction

---

### Coleccion de cartas

**Objetivo:** Mostrar cartas coleccionadas del usuario

**Endpoints:**

1. `GET /users/{userId}/collection`
   - Lista todas las cartas coleccionadas (con cantidad)
   - Con filtros: rarity, cardType, sortBy (date|name|rarity)
   - Response: [{ cardId, name, quantity, rarity, obtainedDate, image_url }]

2. `GET /users/{userId}/collection/stats`
   - Estadísticas de colección
   - Response: { totalCards, uniqueCards, completionPercentage, byRarity: {common: 50, uncommon: 30, rare: 15, holo: 5} }

3. `GET /users/{userId}/collection/{cardId}`
   - Detalle de una carta coleccionada
   - Response: { cardId, name, quantity, rarity, firstObtainedDate, allInstances: [{obtainedFrom: "booster_pack_5", date: ...}] }

**Servicio:**

- `CollectionService`
  - `getCollectionForUser(userId, filters, sort, page)` → Page<CollectionCardDTO>
  - `getCollectionStats(userId)` → CollectionStatsDTO
  - `addCardToCollection(userId, cardId, quantity)` → void

**Vista materializada:** `user_collection_stats` (actualizada post-apertura de sobre)

**Requerimientos cubiertos:**
- RF-10 (Sistema de Sobres, parte visual)

---

### Gestion de partida y lobby

**Objetivo:** Crear partidas, validar jugadores, estado inicial

**Endpoints:**

1. `POST /games`
   - Input: { userId, deckId, matchType: 'PVE', botDifficulty: 'MEDIUM' }
   - Validaciones: usuario existe, deck válido, es del usuario
   - Crea partida con estado=WAITING
   - Si PVE: asigna mazo aleatorio al Bot
   - Response: { gameId, status, players: [{userId, username, deckName}] }

2. `GET /games`
   - Lista partidas disponibles (PVP cola)
   - Response: [{ gameId, player1, skill_rating, createdAt }]

3. `POST /games/{gameId}/join`
   - Input: { userId, deckId, matchType: 'QUEUE'|'ROOM', roomCode? }
   - Si ROOM: valida roomCode existe, tiene lugar
   - Si QUEUE: entra a cola
   - Response: { gameId, status }

4. `GET /games/{gameId}`
   - Retorna estado actual de partida (sin revelar cartas del oponente)
   - Response: { id, status, players, board: {...} }

**Lógica de Setup (mulligan + premios):**

- Ambos jugadores roban 7 cartas
- Si no tienen Pokémon Básico: vuelven a robar, repite
- Se distribuyen 6 premios cara abajo a cada jugador
- Se lanza moneda: ganador inicia

**Servicio:**

- `GameService`
  - `createGame(userId, deckId, matchType, botDifficulty?)` → Game
  - `joinGame(gameId, userId, deckId, roomCode?)` → void
  - `startGame(gameId)` → transición WAITING → SETUP
  - `setupGame(gameId)` → transición SETUP → ACTIVE

**Estados de partida:** WAITING → SETUP → ACTIVE → FINISHED

**Requerimientos cubiertos:**
- RF-03 (Gestión de partida)
- RF-05 (Persistencia)

---

### Sistema de cola online (matchmaking ranked)

**Objetivo:** Búsqueda automática de rivales con ELO

**Endpoints:**

1. `POST /games/queue/join`
   - Input: { userId, deckId }
   - Crea entry en queue_entries
   - Agrega a Redis: zadd matchmaking:queue {skill_rating} {userId}
   - Inicia job cron que cada 2-3 segundos busca matches
   - Retorna estado: WAITING + estimado de espera
   - Response: { queueEntryId, status: 'WAITING', estimatedWait: '30s' }

2. `DELETE /games/queue/{queueEntryId}`
   - Cancela búsqueda
   - Elimina de queue_entries y Redis
   - Response: { message: "Cancelado" }

3. `GET /games/queue/status/{userId}`
   - Chequea estado de búsqueda
   - Response: { status: 'WAITING'|'MATCHED'|'TIMEOUT', foundOpponent?, gameId? }

**Algoritmo de Matchmaking:**

- Calcula skill_gap = |player1_rating - player2_rating|
- Window inicial: ±100 rating puntos
- Cada 5 segundos sin match: expande window en ±50 puntos
- A los 30 segundos: cancel automático si no hay match
- Threshold máximo: ±300 puntos (después de 20 segundos)

**Servicio:**

- `MatchmakingService`
  - `addToQueue(userId, deckId, skillRating)` → QueueEntry
  - `removeFromQueue(userId)` → void
  - `findMatches()` → cron job que busca pares
  - `calculateSkillGap(rating1, rating2)` → int
  - `isCompatibleMatch(user1, user2, secondsWaiting)` → boolean
  - `createGameFromMatch(user1, user2)` → Game + notifica por WebSocket

**Cron Job:**
- Cada 3 segundos (configurable): busca usuarios en Redis
- Para cada usuario esperando: busca mejor match
- Si encuentra: crea game, notifica ambos, elimina de queue
- WebSocket publica en `/topic/queue/{userId}`: "Match found!"

**Tabla nueva:** `queue_entries`, `skill_ratings`
**Cache (Redis):** `matchmaking:queue` (sorted set por rating)

**Requerimientos cubiertos:**
- RF-03 (Cola ranked)
- RNF-01 (Performance)

---

### Sistema de salas privadas

**Objetivo:** Creación y entrada a salas con código

**Endpoints:**

1. `POST /games/rooms/create`
   - Input: { userId, deckId }
   - Genera código único (6 caracteres alfanuméricos)
   - Crea room con status=WAITING, expires_at = ahora + 10 minutos
   - Response: { roomId, roomCode: 'AB7K2X', expiresAt }

2. `POST /games/rooms/join`
   - Input: { userId, deckId, roomCode }
   - Valida: room existe, status=WAITING, no expirada, tiene lugar
   - Agrega usuario a room_room_players
   - Si 2 jugadores: transición a ACTIVE, crea game, publica WebSocket
   - Response: { roomId, status, players: [{...}, {...}], gameId? }

3. `GET /games/rooms/{roomCode}`
   - Info de sala (sin revelar)
   - Response: { roomCode, creator, playerCount, status, expiresAt }

4. `DELETE /games/rooms/{roomId}`
   - Cancela sala (solo creador)
   - Response: { message: "Sala cancelada" }

**Servicio:**

- `RoomService`
  - `createRoom(userId, deckId)` → Room (con código generado)
  - `joinRoom(userId, deckId, roomCode)` → Room
  - `getRoomByCode(roomCode)` → Room
  - `deleteRoom(roomId, userId)` → void (solo si es creador)
  - `getExpiredRooms()` → List<Room> (cron para limpiar)

**Generador de código:**
- 6 caracteres: A-Z, 0-9 (62^6 posibilidades)
- Verificar unicidad en BD

**Tabla nueva:** `game_rooms`, `game_room_players`

**Requerimientos cubiertos:**
- RF-03 (Salas privadas)

---

### Motor de juego

**Objetivo:** Orquestador central y lógica de reglas

**Componentes principales:**

1. **GameEngine** (orquestador / Facade)
   - `processAction(gameId, action: GameAction)` → resultado
   - Coordina validación, daño, estado, eventos
   - Publica eventos por WebSocket
   - Snapshots después de cada acción relevante

2. **TurnManager** (fases del turno — State pattern)
   - Draw Phase: verifica mazo vacío → roba carta
   - Main Phase: juega cartas, adjunta energía, evoluciona, etc.
   - Attack Phase: ataca (si puede)
   - End Phase: aplica condiciones especiales entre turnos, cambia jugador
   - Turno inicial: sin ataque (solo jugador que va primero)

3. **RuleValidator** (validación de acciones)
   - `canPlayBasic(card, board)` → boolean
   - `canEvolvePokemon(pokemon, evolution)` → boolean
   - `canAttachEnergy(energy, pokemon)` → boolean
   - `canAttack(attacker, defender, attack)` → boolean
   - `canRetreat(pokemon, cost)` → boolean

4. **DamageCalculator** (daño realista)
   - Base: attack_damage del JSON
   - Efectos del atacante: bonus antes de debilidad
   - Weakness: ×2 si el defensor tiene debilidad al tipo del atacante
   - Resistance: -20 si el defensor tiene resistencia
   - Efectos del defensor: reducción después de W/R (ej: Furfrou Fur Coat)
   - Daño mínimo: 0
   - Daño directo ("put X damage counters"): NO aplica W/R
   - Ataques con ignoreWeakness/ignoreResistance: saltean esos pasos

5. **StatusEffectManager** (efectos especiales)
   - Aplicar: POISONED, BURNED, ASLEEP, PARALYZED, CONFUSED
   - Paso entre turnos (orden fijo): POISONED → BURNED → ASLEEP → PARALYZED
   - POISONED: -10 HP por paso entre turnos (1 contador de daño)
   - BURNED: tirar moneda — Cruz: -20 HP; Cara: sin daño. Marcador permanece en ambos casos.
   - ASLEEP: tirar moneda — Cara: se despierta; Cruz: sigue dormido
   - PARALYZED: se cura al final del propio turno del dueño
   - CONFUSED: al atacar, tirar moneda — Cruz: 30 daño directo propio, no ataca
   - Verificar KOs causados por condiciones al final del paso entre turnos

6. **CardHandlerRegistry** (lógica específica por carta — Card Handler pattern)
   - Detecta automáticamente todos los `@Component CardHandler` por Spring
   - Propaga hooks al pipeline en los momentos correctos:
     - `onBeforeWeaknessCalculation`: cartas setean ignoreWeakness/ignoreResistance
     - `onBeforeDamageApplied`: cartas modifican daño antes de aplicar (Furfrou)
     - `onAfterDamageApplied`: cartas reaccionan al daño (Chesnaught Spiky Shield)
     - `onBeforePlayItem/Supporter`: cartas bloquean acciones (Trevenant, Krookodile)
     - `onBeforeApplyStatus`: cartas previenen condiciones (Slurpuff)
     - `onEndTurn`: limpieza de markers de turno siguiente
   - Sistema de markers para efectos de "próximo turno" (Kakuna Harden, Aegislash, etc.)
   - Ver `PATRON_CARD_HANDLER.md` y `GAME_ENGINE_DETALLES_PARTE2.md`

7. **VictoryConditionChecker** (condiciones de victoria)
   - R-WIN-01: rival tomó todos sus premios → gana inmediatamente
   - R-WIN-02: mazo vacío al inicio del turno → pierde
   - R-WIN-03: sin Pokémon en juego → pierde
   - R-WIN-04: simultáneos → Muerte Súbita (1 Premio, nuevo setup completo)

8. **BotAgent** (estrategia según dificultad)
   - EASY: acciones válidas aleatorias
   - MEDIUM: greedy (maximiza daño inmediato, minimiza pérdida)
   - HARD: minimax simple (2-3 movimientos adelante)

**Acciones de juego:**

```
DRAW_CARD
PLAY_BASIC_POKEMON (side: BENCH|ACTIVE)
EVOLVE_POKEMON (targetId, evolutionCardId)
ATTACH_ENERGY (energyId, targetPokemonId)
PLAY_ITEM (itemId, targets?)
PLAY_SUPPORTER (supporterId, targets?)
PLAY_STADIUM (stadiumId)
RETREAT_POKEMON (targetId, retreatCosts)
USE_ABILITY (abilityId, targets?)
ATTACK (attackId, targetPokemonId)
TAKE_PRIZE (prizeIndex)
REPLACE_ACTIVE (benchPokemonId)
END_TURN
```

**Persistencia de snapshots:**

Después de acciones: ATTACK, KO, PRIZE_TAKEN, STATUS_APPLIED
Snapshot contiene: board state JSON completo (posiciones, HP, energías, etc)

**Requerimientos cubiertos:**
- RF-01 (Reglas del juego)
- RF-02 (Tipos de cartas)
- RF-03 (Gestión de partida)
- RF-05 (Persistencia)

**Cobertura de tests:**
- RuleValidator: >= 90%
- DamageCalculator: >= 90%
- StatusEffectManager: >= 90%

**Notas de implementación:**
- Estados transaccionales en BD
- Validaciones antes de cada acción
- Logs detallados de cada movimiento
- Tests para cada regla

---

### WebSockets (tiempo real)

**Objetivo:** Sincronizar juego en tiempo real

**Canales STOMP:**

1. **Broadcast (público):**
   - `/topic/game/{gameId}` → estado de partida
   - Eventos: TURN_START, ATTACK, DAMAGE, KO, PRIZE_TAKEN, STATUS_APPLIED, GAME_OVER

2. **Privado (por jugador):**
   - `/user/queue/game/{gameId}` → eventos privados
   - Mano de cartas (nunca enviar al oponente)
   - Premios revelados solo al dueño

3. **Matchmaking (cola):**
   - `/topic/queue/{userId}` → notificaciones de búsqueda
   - Eventos: MATCH_FOUND, QUEUE_TIMEOUT, QUEUE_CANCELLED

4. **Chat:**
   - `/topic/game/{gameId}/chat` → mensajes en tiempo real
   - Eventos: USER_MESSAGE, BOT_MESSAGE, SYSTEM_MESSAGE

**Eventos tipados:**

```json
{
  "eventId": "uuid",
  "gameId": 123,
  "eventType": "ATTACK",
  "timestamp": "2025-04-30T10:30:00Z",
  "payload": {
    "attacker": { "pokemonId": 456, "name": "Pikachu" },
    "defender": { "pokemonId": 789, "name": "Blastoise" },
    "attackId": "bolt-strike",
    "damage": 120,
    "accuracy": 100
  }
}
```

**Reconexión:**

Si cliente se desconecta y reconnecta:
- Servidor reenvía último snapshot válido
- Cliente restaura estado visual
- No repite acciones

**Servicio:**

- `GameEventPublisher`
  - `publishGameEvent(gameId, event)` → WebSocket
  - `publishChatMessage(gameId, user, message, type)` → WebSocket
  - `publishQueueNotification(userId, event)` → WebSocket

**Requerimientos cubiertos:**
- RF-06 (Tiempo real)

---

### Bot con chat y personalidad argentina

**Objetivo:** Bot juega automáticamente y comenta la partida

**Personalidades:**

1. **HERNÁN:** Competitivo, descontrolado, grita
2. **SANTORO:** Profesor condescendiente, táctico
3. **RAMIRO:** Bromista, relajado, amistoso

**Triggers de mensajes:**

- GAME_START: saludo
- TURN_START: anuncia turno + 50% chance comentario
- ATTACK_STRONG: daño > 50 → "¡AJAA!"
- ATTACK_WEAK: daño <= 20 → "bah, eso no le hace nada"
- POKEMON_KO_BY_BOT: "¿ESE ERA TU MEJOR POKE?"
- POKEMON_KO_BY_USER: "boludo, me sacaste un poke"
- PRIZE_TAKEN_BY_BOT: "uno menos para vos"
- GAME_OVER_WIN: "ya te dije que te iba a ganar"
- GAME_OVER_LOSS: "che, ganaste pero casi"
- DRAW: "un empate, boludo"

**Servicio:**

- `BotChatService`
  - `selectPersonality()` → BotPersonality (random al inicio)
  - `getMessageForEvent(event, damage)` → String
  - `sendBotMessage(gameId, event, damage)` → WebSocket (con delay 1-3s)

**Tabla nueva:** `game_chat_messages`

**Requerimientos cubiertos:**
- RF-11 (Chat con Bot)

---

### Frontend Angular

**Objetivo:** UI completa en tiempo real

**Vistas requeridas:**

1. **Autenticación:**
   - `/auth/register` - formulario (usuario, email, password, confirm)
   - `/auth/verify-email` - input código 6 dígitos
   - `/auth/login` - email + password

2. **Home:**
   - `/home` - landing con mazos del usuario + botón favoritos

3. **Cartas:**
   - `/cards` - catálogo con filtros (nombre, tipo, rarity), paginación, imágenes

4. **Mazos:**
   - `/decks` - listado de mazos
   - `/decks/new` - crear mazo
   - `/decks/{id}/edit` - deck builder (lista cartas | mazo seleccionado | contador | errores)
   - `/decks/starters` - mazos pre-armados para elegir o copiar

5. **Shop:**
   - `/shop` - tienda de sobres (mostrar precio, descripción)
   - `/shop/booster/{id}` - detalle sobre + abrir animado
   - `/shop/success` - confirmación de compra

6. **Colección:**
   - `/collection` - galería de cartas coleccionadas con filtros

7. **Wallet:**
   - `/wallet` - saldo virtual + historial de compras

8. **Lobby:**
   - `/lobby` - selector de modo (Cola/Sala/PVE)
   - `/lobby/queue` - interfaz de cola (timer, cancelar)
   - `/lobby/rooms` - crear/unirse a sala
   - `/lobby/rooms/{code}` - sala privada esperando

9. **Juego:**
   - `/game/{id}` - tablero completo (activo, banca, mano, premios, descarte, oponente)
   - Chat integrado
   - Acciones: botones (no drag-and-drop como mínimo)
   - Notificaciones en tiempo real

10. **Leaderboard:**
    - `/leaderboard` - ranking global (PVP ranked), con tabs para filtros
    - Columnas: posición, nombre, wins, losses, ratio, skill_rating

11. **Perfil:**
    - `/profile` - perfil del usuario con estadísticas, historial de compras

**Componentes clave:**

- `VerificationCodeInput` - 6 inputs numéricos
- `DeckBuilder` - lista cartas | mazo | validación
- `GameBoard` - tablero con zonas, cartas, etc.
- `ChatWindow` - scroll automático, mensajes tipados
- `BoosterPackOpener` - animación de apertura
- `QueueIndicator` - spinner + timer de espera

**Interceptor JWT:**
- Agrega token a headers
- Maneja refresh automático
- Redirige a login si token inválido

**Guards de rutas:**
- AuthGuard: solo usuarios autenticados
- EmailVerifiedGuard: redirecciona a verify-email si no verificado

**WebSocket:**
- Suscripción a `/topic/game/{id}` en GameComponent
- Suscripción a `/topic/queue/{userId}` en QueueComponent
- Suscripción a `/topic/game/{id}/chat` en ChatComponent

**Requerimientos cubiertos:**
- RF-07 (Interfaz de usuario)
- RF-06 (Tiempo real)
- RNF-05 (Seguridad)

---

### Interfaz de juego detallada

**Objetivo:** Tablero funcional con reglas visuales

**Zonas del tablero:**

- **Active (Activo):** Pokémon en juego (1 máximo)
- **Bench (Banca):** 5 espacios para Pokémon de respaldo
- **Hand (Mano):** cartas en mano (ocultas para oponente)
- **Prizes (Premios):** 6 cartas cara abajo (mostrar cantidad)
- **Deck (Baraja):** mostrar cantidad
- **Discard (Descarte):** mostrar cantidad (se pueden ver cartas)
- **Opponent:** vista simplificada (sin detalles privados)

**Información visible de cada Pokémon:**

- HP actual vs HP máximo
- Contador de daño (rojo si > 0)
- Energías adjuntas (cantidad por tipo)
- Herramientas equipadas
- Status (Sleep, Burn, etc.)

**Acciones disponibles (via botones):**

- Jugar Pokémon Básico
- Evolucionar Pokémon
- Adjuntar Energía
- Jugar Ítem/Supporter/Estadio
- Retretar Pokémon
- Usar Habilidad
- Atacar (si puede)
- Tomar Premio
- Cambiar Activo
- Terminar Turno

**Notificaciones:**

- "Es tu turno"
- "{X} HP de daño a {Pokémon}"
- "{Pokémon} fue KO"
- "¡Condición especial aplicada!"
- "¡{Jugador} tomó un premio!"

**Requerimientos cubiertos:**
- RF-07 (Interfaz)
- RF-06 (Tiempo real)

---

### Leaderboard y estadisticas

**Objetivo:** Ranking global y perfil de usuario

**Endpoints:**

1. `GET /leaderboard?page=0&filter=pvp|all`
   - Página 1: top 100
   - Filtro PVP: solo partidas ranked
   - Filtro ALL: todo tipo (incluyendo casual)
   - Response: [{ rank, userId, username, wins, losses, draws, ratio, skillRating, totalGames }]

2. `GET /users/{userId}/stats`
   - Estadísticas personales
   - Response: { wins, losses, draws, totalGames, winRate, skillRating, favoriteCard, lastGameDate }

3. `GET /users/{userId}/recent-games`
   - Últimas 10 partidas
   - Response: [{ gameId, opponent, result, date, deckUsed }]

**Vista materializada:** `leaderboard` (actualizada post-partida)

**Actualización de stats:**

Post-partida (en `GameService.finishGame()`):
- Determina ganador
- Actualiza users.wins/losses/draws
- Actualiza skill_rating (si PVP: ajusta ELO)
- Refresca vista `leaderboard`
- Publica evento WebSocket: `/topic/leaderboard/update`

**Cálculo ELO:**

Fórmula: new_rating = current_rating + K * (result - expected)
- K = 32 (rating < 2000), K = 16 (rating >= 2000)
- result = 1 (gana), 0.5 (empate), 0 (pierde)
- expected = 1 / (1 + 10^((opponent_rating - current_rating)/400))

**Requerimientos cubiertos:**
- RF-07 (Leaderboard)
- RF-03 (Gestión de partida)

---

### Calidad y pruebas

**Objetivo:** Tests exhaustivos y cobertura >= 80%

**Unit Tests (JUnit 5 + Mockito):**

Para cada servicio:
- Tests de caso feliz
- Tests de excepciones
- Tests de validaciones

Ejemplos:
- `RuleValidatorTest`: 50+ tests (todas las reglas)
- `DamageCalculatorTest`: 40+ tests (weakness, resistance, efectos)
- `StatusEffectManagerTest`: 30+ tests (cada status, transiciones)
- `BotAgentTest`: 20+ tests (decisiones por dificultad)
- `AuthServiceTest`: 30+ tests (registro, 2FA, login)
- `PaymentServiceTest`: 25+ tests (transacciones)

**Integration Tests (Testcontainers):**

Con PostgreSQL real:
- Flujo de registro → verificación → login
- Flujo de compra de sobre → apertura → colección actualizada
- Flujo de crear partida → jugar turnos → terminar
- Flujo de matchmaking → encontrar rival → crear game

**E2E Tests (Playwright):**

Ejemplos:
1. Registro + verificación + login
2. Crear mazo + jugar partida vs Bot
3. Comprar sobre + abrir + ver colección
4. Entrar a cola + encontrar rival + ganar

**Coverage:**

- Global: >= 80%
- RuleValidator: >= 90%
- DamageCalculator: >= 90%
- StatusEffectManager: >= 90%
- AuthService: >= 85%
- PaymentService: >= 85%

**Reporte JaCoCo:**

Generar con: `mvn clean test jacoco:report`
Publicar en: `/target/site/jacoco/index.html`

**Requerimientos cubiertos:**
- RNF-03 (Pruebas y cobertura)

---

### Documentacion y entrega

**Documentos a mantener:**

1. **`docs/05-referencia-tecnica/CONTRATOS_API.md`**
   - Todos los endpoints con ejemplos de request/response
   - Códigos de error
   - Ejemplos cURL

2. **`docs/05-referencia-tecnica/BD_Y_TABLAS.md`**
   - Schema completo (ER)
   - Relaciones e índices

3. **`docs/05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md`**
   - Canales STOMP
   - Eventos y payloads
   - Ejemplos de suscripción

4. **`docs/06-reglas-juego/`** (7 archivos)
   - Reglas XY1 completas
   - Validaciones de cartas
   - Cálculo de daño y condiciones de victoria

5. **`docs/05-referencia-tecnica/GAME_ENGINE_DETALLES.md`** y `GAME_ENGINE_DETALLES_PARTE2.md`
   - Motor de juego completo

6. **`docs/05-referencia-tecnica/CODEMON_GUIAS_TECNICAS.md`**
   - Guías técnicas transversales (pagos, email, OAuth2)

7. **`docs/09-handoff/CODEMON_HANDOFF_COMPLETO.md`**
   - Documento de entrega completo para los equipos

**Checklist de entrega:**

- [ ] Todos los endpoints testeados y documentados en Swagger
- [ ] Cobertura >= 80% en tests
- [ ] Leaderboard actualizado y funcionando
- [ ] 2FA y login funcionando
- [ ] Pagos integrados con Mercado Pago (sandbox)
- [ ] Sobres: compra, cooldown, apertura
- [ ] Colección visible y actualizada
- [ ] Matchmaking en cola funcionando
- [ ] Salas privadas creables y joinables
- [ ] PVE vs Bot funcionando (3 dificultades)
- [ ] Motor de juego (todas las reglas validadas)
- [ ] WebSockets en tiempo real
- [ ] Chat PVP y PVE con Bot
- [ ] Leaderboard filtrable
- [ ] Frontend con todas las vistas
- [ ] Documentación completa
- [ ] ADRs actualizados

**Requerimientos cubiertos:**
- Todos los RF y RNF

---

## Planificacion vigente

Este documento no define el orden de implementacion. El orden de trabajo vive en los artefactos Scrum del proyecto:

- Planificacion general, epicas, sprints y gates: [../02-planificacion/README.md](../02-planificacion/README.md)
- Product Backlog priorizado: [../02-planificacion/01_backlog/PRODUCT_BACKLOG.md](../02-planificacion/01_backlog/PRODUCT_BACKLOG.md)
- Plan de sprints: [../02-planificacion/02_sprints/SPRINTS.md](../02-planificacion/02_sprints/SPRINTS.md)
- Dependencias y gates: [../02-planificacion/04_proceso/DEPENDENCIAS_EPICAS.md](../02-planificacion/04_proceso/DEPENDENCIAS_EPICAS.md)
- Pasos de implementacion con IA: [../08-desarrollo-con-ia/README.md](../08-desarrollo-con-ia/README.md)

---

## Notas Importantes

### Para el Backend:

1. **Transacciones:** Usa @Transactional en métodos que modifican BD
2. **Seguridad:** Spring Security Filter para JWT en todos los endpoints (excepto auth/register, auth/verify)
3. **Rate Limiting:** Bucket4j para 2FA, chat, pagos
4. **Logging:** Usa SLF4J con log level configurable
5. **Errores:** @ControllerAdvice con GlobalExceptionHandler
6. **Tests:** Estructura: Given → When → Then

### Para el Frontend:

1. **TypeScript Estricto:** strict mode activado en tsconfig.json
2. **Interceptores:** HTTP + JWT + error handling
3. **Guards:** AuthGuard + EmailVerifiedGuard
4. **Observables:** Unsubscribe en ngOnDestroy
5. **Change Detection:** OnPush donde sea posible (performance)

### Para la BD:

1. **Migraciones:** Versionadas, idempotentes, reversibles
2. **Índices:** En todas las FK y campos de búsqueda frecuente
3. **Constraints:** NOT NULL, UNIQUE, FOREIGN KEY donde corresponda
4. **Vistas:** Materializadas para leaderboard (refresh post-partida)

### Para WebSockets:

1. **Reconexión:** Implementar exponential backoff en cliente
2. **Heartbeat:** Ping cada 30 segundos para detectar desconexiones
3. **Seguridad:** Validar userId en cada mensaje (no confiar en cliente)

---

## Decisiones Clave a Confirmar

1. **Sistema de rating:** ¿ELO o simple W/L ratio?
2. **Moneda única:** ¿Codemones Coins comprados con dinero real?
3. **Rarity distribution:** ¿60% common, 25% uncommon, 12% rare, 3% holo?
4. **Email provider:** ¿Sendgrid, Mailgun o SMTP local?
5. **Cooldown sobres:** ¿24 horas exactas o "1 por día" (reset medianoche)?

---

## Areas para busqueda rapida

- 2FA: Autenticacion avanzada
- Pagos: Sistema de pago
- Sobres: Sistema de sobres booster
- Matchmaking: Sistema de cola online
- Salas: Sistema de salas privadas
- Motor: Motor de juego
- WebSocket: WebSockets
- Bot chat: Bot con chat y personalidad argentina
- Frontend: Frontend Angular e interfaz de juego
- Tests: Calidad y pruebas

---

**Creado:** 30/04/2025  
**Actualizado:** 19/05/2026  
**Versión:** 1.1  
**Estado:** Listo para implementación
