# GLOSARIO — Nombres canónicos del proyecto Codemon TCG

> **Cargar este archivo como `context_file` obligatorio en TODOS los PASOS.**
> Define los nombres canónicos de entidades, paquetes, DTOs y eventos para que dos agentes IA que ejecuten pasos diferentes generen código compatible.

---

## 1. Estructura de paquetes (backend Spring Boot)

Raíz: `com.codemon`. Cada feature tiene su paquete propio. Subpaquetes estándar dentro de cada feature: `entity`, `repository`, `service`, `controller`, `dto`.

```
com.codemon
├── auth         (PASO_S01_01: User, RefreshToken, JwtService, AuthController)
├── cards        (PASO_S02_02: Card entidad de catálogo)
├── decks        (PASO_S02_01, PASO_S02_03: Deck, DeckCard, DeckValidationService)
├── game
│   ├── engine             (PASO_S03_01: GameContext, GameEngine, GameState interface, GameAction, GameEvent)
│   │   ├── model          (PASO_S03_01: InPlayPokemon, PlayerBoard, GameBoard, StatusCondition)
│   │   ├── state          (PASO_S03_01..2_7: SetupState, DrawPhaseState, MainPhaseState, AttackPhaseState, EndPhaseState)
│   │   ├── pipeline       (PASO_S04_02: AttackPipeline + 9 handlers)
│   │   ├── service        (PASO_S04_01: DamageCalculator, StatusEffectManager, VictoryConditionChecker)
│   │   ├── observer       (PASO_S05_03: GameEventPublisher, GameLogEventListener)
│   │   └── bot            (PASO_S05_02: BotEasyStrategy; PASO_S11_01: BotMediumStrategy, BotHardStrategy)
│   ├── controller         (PASO_S05_03: GameController)
│   └── persistence        (PASO_S05_03: GameSnapshotRepository, GameEventRepository)
├── matchmaking  (PASO_S07_01: GameRoom; PASO_S07_02: QueueService)
├── shop         (PASO_S08_01: BoosterPack, UserCollection)
├── payment      (PASO_S08_04: PaymentService, MercadoPagoConfig)
├── ranking      (PASO_S08_02 + 5_1: LeaderboardService, LeagueService)
├── social       (PASO_S09_02: FriendshipService, PresenceService)
├── news         (PASO_S09_03: NewsService)
├── chat         (PASO_S11_02: GameChatService)
└── shared
    ├── config     (WebSocketConfig, SecurityConfig, RedisConfig, OpenApiConfig)
    ├── exception  (NotYourTurnException, InvalidActionException, GlobalExceptionHandler)
    └── util       (RandomUtil con SecureRandom)
```

**Regla:** la entidad JPA vive en `<feature>.entity`, nunca en `<feature>` directo. El servicio en `<feature>.service`. El controller en `<feature>.controller`.

---

## 2. Entidades canónicas (1 nombre = 1 clase)

| Entidad | Paquete completo | Tabla SQL | Notas |
|---|---|---|---|
| `User` | `com.codemon.auth.entity.User` | `users` | Campo `id` Long, `username`, `email`, `passwordHash`, `role`, `emailVerified` |
| `RefreshToken` | `com.codemon.auth.entity.RefreshToken` | `refresh_tokens` | |
| `Card` | `com.codemon.cards.entity.Card` | `cards_catalog` | **Única clase Card del proyecto.** PASO_S02_01 (DeckValidationService) la consume desde este paquete; NO crear una `Card` propia. |
| `Deck` | `com.codemon.decks.entity.Deck` | `decks` | |
| `DeckCard` | `com.codemon.decks.entity.DeckCard` | `deck_cards` | |
| `BoosterPack` | `com.codemon.shop.entity.BoosterPack` | `booster_packs` | |
| `UserCollection` | `com.codemon.shop.entity.UserCollection` | `user_collection` | |
| `PaymentRecord` | `com.codemon.payment.entity.PaymentRecord` | `payment_records` | |
| `Game` | `com.codemon.game.persistence.entity.Game` | `games` | Persistencia de partidas |
| `GameSnapshot` | `com.codemon.game.persistence.entity.GameSnapshot` | `game_state_snapshots` | |
| `GameEventLog` | `com.codemon.game.persistence.entity.GameEventLog` | `game_events` | Distinto de `GameEvent` (DTO de runtime) |
| `GameRoom` | `com.codemon.matchmaking.entity.GameRoom` | `game_rooms` | |
| `SkillRating` | `com.codemon.matchmaking.entity.SkillRating` | `skill_ratings` | |
| `Friendship` | `com.codemon.social.entity.Friendship` | `friendships` | |
| `NewsPost` | `com.codemon.news.entity.NewsPost` | `news_posts` | |
| `OAuthAccount` | `com.codemon.auth.entity.OAuthAccount` | `user_oauth_accounts` | |

**Regla:** si dos PASOS necesitan referirse a la misma entidad, usan exactamente el FQN de esta tabla.

### Modelos de runtime (NO son entidades JPA)

| Modelo | Paquete | Propósito |
|---|---|---|
| `GameContext` | `com.codemon.game.engine.GameContext` | Estado de la partida en memoria durante el juego |
| `InPlayPokemon` | `com.codemon.game.engine.model.InPlayPokemon` | Pokémon en el tablero (≠ `Card`) |
| `PlayerBoard` | `com.codemon.game.engine.model.PlayerBoard` | Tablero de un jugador |
| `GameBoard` | `com.codemon.game.engine.model.GameBoard` | Tablero global |
| `GameAction` | `com.codemon.game.engine.GameAction` | Acción enviada por el cliente |
| `GameEvent` | `com.codemon.game.engine.GameEvent` | Evento emitido por el motor (NO la entidad de log) |

---

## 3. Convención de DTOs

Sufijo según dirección:
- `*Request` — entrada del cliente (POST body, query params)
- `*Response` — salida al cliente (response body)
- `*DTO` — solo cuando el objeto fluye en ambos sentidos (raro)

Ejemplos:
- `LoginRequest` → `LoginResponse`
- `CreateDeckRequest` → `DeckResponse`
- `GameActionRequest` (HTTP) — el modelo de runtime `GameAction` se mapea a `GameActionRequest` en el controller

**Paquete de DTOs:** `com.codemon.<feature>.dto`. Records de Java 21 (no clases con getters).

---

## 4. Eventos WebSocket — formato canónico

**Estructura única para todos los eventos** (backend emite, frontend consume):

```json
{
  "eventType": "TURN_START",
  "gameId": 42,
  "timestamp": "2026-05-06T15:00:00Z",
  "payload": { "playerId": 1, "turnNumber": 3 },
  "private": false,
  "privateTargetUserId": null
}
```

| Campo | Tipo Java | Tipo TypeScript | Notas |
|---|---|---|---|
| `eventType` | `String` | `string` | **Nombre canónico = `eventType`**. NO `type`. SCREAMING_SNAKE_CASE. |
| `gameId` | `Long` | `number` | Mismo tipo numérico en JS y Java. |
| `timestamp` | `String` (ISO 8601 UTC) | `string` | Generado por el backend al emitir. |
| `payload` | `Map<String,Object>` | `Record<string, any>` | Estructura específica por evento. |
| `private` | `boolean` | `boolean` | Si es privado (solo dueño). |
| `privateTargetUserId` | `Long` (nullable) | `number \| null` | Solo si `private = true`. |

**Convención de nombres de eventos:** `SCREAMING_SNAKE_CASE`. Lista canónica vive en `06-system-logic.md` y `PROTOCOLO_WEBSOCKET.md`.

**Canales STOMP:**
- Público: `/topic/game/{gameId}` — todos los suscriptores reciben.
- Privado: `/user/queue/game` — solo el `privateTargetUserId`.

**Acciones del cliente:** `/app/game/{gameId}/action` con body `GameActionRequest`.

---

## 5. Endpoints REST — convención

Prefijo global: `/api/`. Verbos REST estándar.

| Recurso | Endpoint base | PASO |
|---|---|---|
| Auth | `/api/auth` | PASO_S01_01, PASO_S08_03, PASO_S10_02 |
| Users | `/api/users` | PASO_S01_01, PASO_S11_05 |
| Cards | `/api/cards` | PASO_S02_02 |
| Decks | `/api/decks` | PASO_S02_03 |
| Games | `/api/games` | PASO_S05_03 |
| Rooms | `/api/rooms` | PASO_S07_01 |
| Matchmaking | `/api/matchmaking` | PASO_S07_02 |
| Shop | `/api/shop` | PASO_S08_01 |
| Payments | `/api/payments` | PASO_S08_04 |
| Leaderboard | `/api/leaderboard` | PASO_S08_02 |
| Friends | `/api/friends` | PASO_S09_02 |
| News | `/api/news` | PASO_S09_03 |
| Wallet | `/api/wallet` | PASO_S11_04 |

**Errores:** formato `{ "error": "CODE", "message": "...", "details": {} }` (HTTP 4xx/5xx).

---

## 6. Frontend Angular — naming

| Tipo | Convención | Ejemplo |
|---|---|---|
| Componente | `*.component.ts` con clase `*Component` | `LoginComponent` en `login.component.ts` |
| Servicio | `*.service.ts` con clase `*Service` | `AuthService` en `auth.service.ts` |
| Modelo (interface) | `*.models.ts` con `interface *` | `interface User` en `auth.models.ts` |
| Pipe | `*.pipe.ts` con clase `*Pipe` | `CardFilterPipe` |
| Guard | `*.guard.ts` con clase `*Guard` | `AuthGuard` |
| Interceptor | `*.interceptor.ts` con clase `*Interceptor` | `MockInterceptor`, `AuthInterceptor` |

**Estructura de carpetas:** `src/app/<feature>/{components,services,models,pages}` o agrupado por página (`src/app/pages/<page>/`).

**Estilos:** Tailwind CSS 3 (utility-first). Las clases CSS que aparecen en los templates de PASOS (`action-primary`, `overlay-backdrop`, `progress-track`, `menu-item`, etc.) son **clases custom del proyecto** — se definen en `*.component.scss` con `@apply` Tailwind. No hay framework de componentes pre-armados; sólo `@angular/cdk` para drag/drop y overlays.

**Flag `environment.useMocks`** (boolean) está definida en [PASO_S00_01.md](../08-desarrollo-con-ia/pasos/PASO_S00_01.md) y [MOCKS_FRONTEND.md](MOCKS_FRONTEND.md). NO redefinir.

---

## 7. Variables de entorno

Mayúsculas con guión bajo. Documentadas en `.env.example`.

| Variable | Uso | PASO |
|---|---|---|
| `JWT_SECRET` | Firma JWT (≥32 chars) | PASO_S01_01 |
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` | PostgreSQL | PASO_S00_04 |
| `REDIS_HOST`, `REDIS_PORT` | Redis | PASO_S00_04 |
| `MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `MINIO_BUCKET` | MinIO | PASO_S02_02 |
| `MP_ACCESS_TOKEN` | Mercado Pago | PASO_S08_04 |
| `EMAIL_FROM`, `EMAIL_PASSWORD` | SMTP 2FA | PASO_S08_03 |
| `OAUTH_GOOGLE_CLIENT_ID`, `OAUTH_GOOGLE_SECRET` | OAuth2 Google | PASO_S10_01 |
| `OAUTH_GITHUB_CLIENT_ID`, `OAUTH_GITHUB_SECRET` | OAuth2 GitHub | PASO_S10_01 |

---

## 8. Convenciones cruzadas

- **IDs**: siempre `Long` en backend, `number` en frontend. UUIDs solo para `instanceId` de `InPlayPokemon` (string).
- **Fechas**: `Instant` o `OffsetDateTime` en Java; ISO 8601 UTC en JSON.
- **Plurales**: tablas en plural (`users`), entidades en singular (`User`).
- **Booleanos**: prefijo `is`/`has` (`isFirstTurn`, `hasBasicPokemon`).
- **Constantes**: `SCREAMING_SNAKE_CASE` (Java enum values, eventos WS, ActionType values).

---

## 9. Cuando un PASO contradice este glosario

**El glosario tiene precedencia.** Reportarlo como bug del PASO. NO crear nombres alternativos para "no contradecir" el PASO.

Si un PASO menciona `Card` sin paquete, asumir `com.codemon.cards.entity.Card`. Si necesita una representación diferente para juego (`CardInGame`, `CardSnapshot`), debe nombrarla explícitamente.
