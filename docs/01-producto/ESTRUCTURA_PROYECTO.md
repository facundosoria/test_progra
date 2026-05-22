# Estructura del Proyecto Codemon

## Visión general de carpetas

```
codemon/
├── api/                          # Backend Spring Boot (a implementar por los equipos)
├── front/                        # Frontend Angular (a implementar por los equipos)
├── infra/                        # Configuración runtime (Prometheus, Grafana)
├── scripts/                      # Tooling: verify_paso, trazabilidad, sync GitHub
├── docs/                         # Toda la documentación del proyecto (9 capítulos temáticos)
├── docker-compose.yml            # Stack completo (10 servicios)
├── .env.example                  # Plantilla de variables de entorno
├── README.md                     # Entrada principal
└── CONTRIBUTING.md               # Guia operativa para desarrolladores
```

---

## Backend (api/)

```
api/
├── pom.xml                       # Maven - dependencias
│
├── src/
│   ├── main/
│   │   ├── java/com/codemon/
│   │   │   ├── CodemonApplication.java    # Main class
│   │   │   │
│   │   │   ├── shared/                     # Código compartido
│   │   │   │   ├── config/
│   │   │   │   │   ├── SecurityConfig.java
│   │   │   │   │   ├── WebSocketConfig.java
│   │   │   │   │   ├── AsyncConfig.java
│   │   │   │   │   └── CacheConfig.java
│   │   │   │   ├── dto/
│   │   │   │   │   ├── ErrorResponse.java
│   │   │   │   │   ├── SuccessResponse.java
│   │   │   │   │   └── [DTOs específicos por dominio]
│   │   │   │   ├── exception/
│   │   │   │   │   ├── GlobalExceptionHandler.java
│   │   │   │   │   ├── CustomException.java
│   │   │   │   │   ├── GameNotFoundException.java
│   │   │   │   │   ├── UnauthorizedException.java
│   │   │   │   │   └── [Excepciones específicas]
│   │   │   │   ├── utils/
│   │   │   │   │   ├── JwtTokenProvider.java
│   │   │   │   │   ├── EmailValidator.java
│   │   │   │   │   ├── PasswordValidator.java
│   │   │   │   │   └── UUIDGenerator.java
│   │   │   │   └── security/
│   │   │   │       └── JwtAuthenticationFilter.java
│   │   │   │
│   │   │   ├── auth/                       # Dominio: Autenticación
│   │   │   │   ├── controller/
│   │   │   │   │   └── AuthController.java
│   │   │   │   ├── service/
│   │   │   │   │   ├── AuthService.java
│   │   │   │   │   ├── EmailVerificationService.java
│   │   │   │   │   └── EmailService.java
│   │   │   │   ├── repository/
│   │   │   │   │   ├── UserRepository.java
│   │   │   │   │   ├── EmailVerificationRepository.java
│   │   │   │   │   └── RefreshTokenRepository.java
│   │   │   │   ├── entity/
│   │   │   │   │   ├── User.java
│   │   │   │   │   ├── EmailVerification.java
│   │   │   │   │   └── RefreshToken.java
│   │   │   │   └── dto/
│   │   │   │       ├── RegisterRequest.java
│   │   │   │       ├── LoginRequest.java
│   │   │   │       ├── VerifyEmailRequest.java
│   │   │   │       ├── RefreshTokenRequest.java
│   │   │   │       └── AuthResponse.java
│   │   │   │
│   │   │   ├── cards/                      # Dominio: Cartas
│   │   │   │   ├── controller/
│   │   │   │   │   └── CardController.java
│   │   │   │   ├── service/
│   │   │   │   │   └── CardService.java
│   │   │   │   ├── repository/
│   │   │   │   │   ├── CardRepository.java
│   │   │   │   │   └── CardImageRepository.java
│   │   │   │   ├── entity/
│   │   │   │   │   ├── Card.java
│   │   │   │   │   └── CardImage.java
│   │   │   │   └── dto/
│   │   │   │       ├── CardResponse.java
│   │   │   │       ├── CardSearchRequest.java
│   │   │   │       └── CardPageResponse.java
│   │   │   │
│   │   │   ├── decks/                      # Dominio: Mazos
│   │   │   │   ├── controller/
│   │   │   │   │   └── DeckController.java
│   │   │   │   ├── service/
│   │   │   │   │   ├── DeckService.java
│   │   │   │   │   └── DeckValidationService.java
│   │   │   │   ├── repository/
│   │   │   │   │   ├── DeckRepository.java
│   │   │   │   │   └── DeckCardRepository.java
│   │   │   │   ├── entity/
│   │   │   │   │   ├── Deck.java
│   │   │   │   │   └── DeckCard.java
│   │   │   │   └── dto/
│   │   │   │       ├── DeckCreateRequest.java
│   │   │   │       ├── DeckUpdateRequest.java
│   │   │   │       ├── DeckResponse.java
│   │   │   │       └── ValidationErrorResponse.java
│   │   │   │
│   │   │   ├── payment/                    # Dominio: Pagos
│   │   │   │   ├── controller/
│   │   │   │   │   ├── PaymentController.java
│   │   │   │   │   └── WebhookController.java
│   │   │   │   ├── service/
│   │   │   │   │   ├── PaymentService.java
│   │   │   │   │   └── WalletService.java
│   │   │   │   ├── repository/
│   │   │   │   │   ├── PaymentRecordRepository.java
│   │   │   │   │   └── WebhookLogRepository.java
│   │   │   │   ├── entity/
│   │   │   │   │   ├── PaymentRecord.java
│   │   │   │   │   └── WebhookLog.java
│   │   │   │   ├── client/
│   │   │   │   │   └── MercadoPagoClient.java
│   │   │   │   └── dto/
│   │   │   │       ├── PreferenceRequest.java
│   │   │   │       ├── PreferenceResponse.java
│   │   │   │       ├── WebhookPayload.java
│   │   │   │       └── WalletResponse.java
│   │   │   │
│   │   │   ├── booster/                    # Dominio: Sobres
│   │   │   │   ├── controller/
│   │   │   │   │   └── BoosterPackController.java
│   │   │   │   ├── service/
│   │   │   │   │   ├── BoosterPackService.java
│   │   │   │   │   └── CardGenerationService.java
│   │   │   │   ├── repository/
│   │   │   │   │   ├── BoosterPackRepository.java
│   │   │   │   │   ├── BoosterPackCardRepository.java
│   │   │   │   │   ├── UserBoosterPackRepository.java
│   │   │   │   │   └── UserCollectionRepository.java
│   │   │   │   ├── entity/
│   │   │   │   │   ├── BoosterPack.java
│   │   │   │   │   ├── BoosterPackCard.java
│   │   │   │   │   ├── UserBoosterPack.java
│   │   │   │   │   └── UserCollection.java
│   │   │   │   └── dto/
│   │   │   │       ├── BoosterPackResponse.java
│   │   │   │       ├── OpenBoosterResponse.java
│   │   │   │       └── CooldownStatusResponse.java
│   │   │   │
│   │   │   ├── collection/                 # Dominio: Colección
│   │   │   │   ├── controller/
│   │   │   │   │   └── CollectionController.java
│   │   │   │   ├── service/
│   │   │   │   │   └── CollectionService.java
│   │   │   │   └── dto/
│   │   │   │       ├── CollectionCardResponse.java
│   │   │   │       └── CollectionStatsResponse.java
│   │   │   │
│   │   │   ├── lobby/                      # Dominio: Matchmaking + Salas
│   │   │   │   ├── controller/
│   │   │   │   │   ├── MatchmakingController.java
│   │   │   │   │   └── RoomController.java
│   │   │   │   ├── service/
│   │   │   │   │   ├── MatchmakingService.java
│   │   │   │   │   └── RoomService.java
│   │   │   │   ├── repository/
│   │   │   │   │   ├── QueueEntryRepository.java
│   │   │   │   │   ├── GameRoomRepository.java
│   │   │   │   │   ├── GameRoomPlayerRepository.java
│   │   │   │   │   └── SkillRatingRepository.java
│   │   │   │   ├── entity/
│   │   │   │   │   ├── QueueEntry.java
│   │   │   │   │   ├── GameRoom.java
│   │   │   │   │   ├── GameRoomPlayer.java
│   │   │   │   │   └── SkillRating.java
│   │   │   │   └── dto/
│   │   │   │       ├── JoinQueueRequest.java
│   │   │   │       ├── CreateRoomRequest.java
│   │   │   │       ├── JoinRoomRequest.java
│   │   │   │       └── RoomResponse.java
│   │   │   │
│   │   │   ├── game/                       # Dominio: Juego (CRÍTICO)
│   │   │   │   ├── controller/
│   │   │   │   │   └── GameController.java
│   │   │   │   ├── service/
│   │   │   │   │   └── GameService.java
│   │   │   │   ├── engine/
│   │   │   │   │   ├── GameEngine.java
│   │   │   │   │   └── GameEventPublisher.java
│   │   │   │   ├── rules/
│   │   │   │   │   └── RuleValidator.java
│   │   │   │   ├── damage/
│   │   │   │   │   └── DamageCalculator.java
│   │   │   │   ├── effects/
│   │   │   │   │   └── StatusEffectManager.java
│   │   │   │   ├── victory/
│   │   │   │   │   └── VictoryConditionChecker.java
│   │   │   │   ├── bot/
│   │   │   │   │   ├── BotAgent.java
│   │   │   │   │   └── BotChatService.java
│   │   │   │   ├── repository/
│   │   │   │   │   ├── GameRepository.java
│   │   │   │   │   ├── GameStateSnapshotRepository.java
│   │   │   │   │   ├── GameEventRepository.java
│   │   │   │   │   └── GameChatMessageRepository.java
│   │   │   │   ├── entity/
│   │   │   │   │   ├── Game.java
│   │   │   │   │   ├── GameStateSnapshot.java
│   │   │   │   │   ├── GameEvent.java
│   │   │   │   │   └── GameChatMessage.java
│   │   │   │   └── dto/
│   │   │   │       ├── CreateGameRequest.java
│   │   │   │       ├── GameActionRequest.java
│   │   │   │       ├── GameResponse.java
│   │   │   │       └── GameEventResponse.java
│   │   │   │
│   │   │   ├── users/                      # Dominio: Usuarios
│   │   │   │   ├── controller/
│   │   │   │   │   └── UserController.java
│   │   │   │   ├── service/
│   │   │   │   │   └── UserService.java
│   │   │   │   └── dto/
│   │   │   │       ├── UserStatsResponse.java
│   │   │   │       ├── UserProfileResponse.java
│   │   │   │       └── RecentGameResponse.java
│   │   │   │
│   │   │   └── chat/                       # Dominio: Chat
│   │   │       ├── controller/
│   │   │       │   └── ChatController.java
│   │   │       ├── service/
│   │   │       │   └── ChatService.java
│   │   │       └── dto/
│   │   │           └── ChatMessageRequest.java
│   │   │
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-dev.yml
│   │       ├── application-prod.yml
│   │       └── db/
│   │           └── migration/
│   │               ├── V1__initial_schema.sql
│   │               ├── V2__add_2fa_tables.sql
│   │               ├── V3__add_payment_tables.sql
│   │               ├── V4__add_booster_tables.sql
│   │               ├── V5__add_collection_tables.sql
│   │               ├── V6__add_queue_tables.sql
│   │               ├── V7__add_game_rooms_tables.sql
│   │               ├── V8__add_game_tables.sql
│   │               ├── V9__add_chat_tables.sql
│   │               ├── V10__create_materialized_views.sql
│   │               ├── V11__add_indexes.sql
│   │               ├── V12__seed_cards.sql
│   │               ├── V13__seed_starter_decks.sql
│   │               ├── V14__seed_booster_packs.sql
│   │               └── V15__add_final_constraints.sql
│   │
│   └── test/
│       ├── java/com/codemon/
│       │   ├── auth/
│       │   │   ├── AuthServiceTest.java
│       │   │   ├── EmailVerificationServiceTest.java
│       │   │   └── AuthControllerTest.java
│       │   ├── cards/
│       │   │   └── CardServiceTest.java
│       │   ├── decks/
│       │   │   ├── DeckServiceTest.java
│       │   │   └── DeckValidationServiceTest.java
│       │   ├── game/
│       │   │   ├── RuleValidatorTest.java
│       │   │   ├── DamageCalculatorTest.java
│       │   │   ├── StatusEffectManagerTest.java
│       │   │   └── BotAgentTest.java
│       │   ├── payment/
│       │   │   ├── PaymentServiceTest.java
│       │   │   └── WalletServiceTest.java
│       │   ├── booster/
│       │   │   └── BoosterPackServiceTest.java
│       │   ├── lobby/
│       │   │   ├── MatchmakingServiceTest.java
│       │   │   └── RoomServiceTest.java
│       │   └── integration/
│       │       ├── AuthIntegrationTest.java
│       │       ├── GameIntegrationTest.java
│       │       └── PaymentIntegrationTest.java
│       └── resources/
│           └── application-test.yml
```

---

## Frontend (front/)

```
front/
├── angular.json
├── tsconfig.json
├── package.json
│
├── src/
│   ├── main.ts
│   ├── styles.css                 # Estilos globales
│   │
│   ├── app/
│   │   ├── app.component.ts
│   │   ├── app.config.ts
│   │   ├── app.routes.ts          # Rutas
│   │   │
│   │   ├── shared/                # Código compartido
│   │   │   ├── interceptors/
│   │   │   │   ├── http-jwt.interceptor.ts
│   │   │   │   └── error.interceptor.ts
│   │   │   ├── guards/
│   │   │   │   ├── auth.guard.ts
│   │   │   │   └── email-verified.guard.ts
│   │   │   ├── services/
│   │   │   │   ├── http.service.ts
│   │   │   │   ├── storage.service.ts
│   │   │   │   └── notification.service.ts
│   │   │   ├── models/
│   │   │   │   ├── auth.model.ts
│   │   │   │   ├── card.model.ts
│   │   │   │   ├── deck.model.ts
│   │   │   │   ├── game.model.ts
│   │   │   │   └── user.model.ts
│   │   │   └── components/
│   │   │       ├── header/
│   │   │       ├── footer/
│   │   │       ├── navbar/
│   │   │       └── loading-spinner/
│   │   │
│   │   ├── auth/                  # Módulo: Autenticación
│   │   │   ├── auth.routes.ts
│   │   │   ├── services/
│   │   │   │   └── auth.service.ts
│   │   │   ├── pages/
│   │   │   │   ├── register/
│   │   │   │   │   └── register.component.ts
│   │   │   │   ├── verify-email/
│   │   │   │   │   └── verify-email.component.ts
│   │   │   │   └── login/
│   │   │   │       └── login.component.ts
│   │   │   └── components/
│   │   │       └── verification-code-input/
│   │   │           └── verification-code-input.component.ts
│   │   │
│   │   ├── home/                  # Página: Home
│   │   │   ├── home.routes.ts
│   │   │   └── pages/
│   │   │       └── home.component.ts
│   │   │
│   │   ├── cards/                 # Módulo: Cartas
│   │   │   ├── cards.routes.ts
│   │   │   ├── services/
│   │   │   │   └── card.service.ts
│   │   │   ├── pages/
│   │   │   │   └── card-list/
│   │   │   │       └── card-list.component.ts
│   │   │   └── components/
│   │   │       ├── card-grid/
│   │   │       ├── card-filter/
│   │   │       └── card-detail-modal/
│   │   │
│   │   ├── decks/                 # Módulo: Mazos
│   │   │   ├── decks.routes.ts
│   │   │   ├── services/
│   │   │   │   └── deck.service.ts
│   │   │   ├── pages/
│   │   │   │   ├── deck-list/
│   │   │   │   ├── deck-create/
│   │   │   │   ├── deck-edit/
│   │   │   │   └── starter-decks/
│   │   │   └── components/
│   │   │       ├── deck-builder/
│   │   │       ├── card-selector/
│   │   │       ├── deck-validator/
│   │   │       └── validation-errors/
│   │   │
│   │   ├── shop/                  # Módulo: Tienda
│   │   │   ├── shop.routes.ts
│   │   │   ├── services/
│   │   │   │   └── shop.service.ts
│   │   │   ├── pages/
│   │   │   │   ├── shop-list/
│   │   │   │   ├── booster-detail/
│   │   │   │   └── payment-success/
│   │   │   └── components/
│   │   │       └── booster-opener/
│   │   │
│   │   ├── collection/            # Módulo: Colección
│   │   │   ├── collection.routes.ts
│   │   │   ├── services/
│   │   │   │   └── collection.service.ts
│   │   │   ├── pages/
│   │   │   │   └── collection-gallery/
│   │   │   └── components/
│   │   │       ├── collection-grid/
│   │   │       ├── collection-filter/
│   │   │       └── collection-stats/
│   │   │
│   │   ├── wallet/                # Módulo: Cartera
│   │   │   ├── wallet.routes.ts
│   │   │   ├── services/
│   │   │   │   └── wallet.service.ts
│   │   │   ├── pages/
│   │   │   │   └── wallet-page/
│   │   │   └── components/
│   │   │       ├── wallet-display/
│   │   │       └── payment-history/
│   │   │
│   │   ├── lobby/                 # Módulo: Lobby/Matchmaking
│   │   │   ├── lobby.routes.ts
│   │   │   ├── services/
│   │   │   │   ├── matchmaking.service.ts
│   │   │   │   └── room.service.ts
│   │   │   ├── pages/
│   │   │   │   ├── lobby-main/
│   │   │   │   ├── queue-waiting/
│   │   │   │   ├── room-create/
│   │   │   │   └── room-join/
│   │   │   └── components/
│   │   │       ├── queue-indicator/
│   │   │       ├── room-code-input/
│   │   │       └── room-lobby/
│   │   │
│   │   ├── game/                  # Módulo: Juego
│   │   │   ├── game.routes.ts
│   │   │   ├── services/
│   │   │   │   ├── game.service.ts
│   │   │   │   └── websocket.service.ts
│   │   │   ├── pages/
│   │   │   │   ├── game-board/
│   │   │   │   └── game-result/
│   │   │   └── components/
│   │   │       ├── game-board/
│   │   │       ├── pokemon-zone/
│   │   │       ├── bench-zone/
│   │   │       ├── hand-zone/
│   │   │       ├── chat-window/
│   │   │       ├── action-buttons/
│   │   │       └── notification-center/
│   │   │
│   │   ├── leaderboard/           # Módulo: Ranking
│   │   │   ├── leaderboard.routes.ts
│   │   │   ├── services/
│   │   │   │   └── leaderboard.service.ts
│   │   │   ├── pages/
│   │   │   │   └── leaderboard-page/
│   │   │   └── components/
│   │   │       └── leaderboard-table/
│   │   │
│   │   └── profile/               # Módulo: Perfil
│   │       ├── profile.routes.ts
│   │       ├── services/
│   │       │   └── profile.service.ts
│   │       ├── pages/
│   │       │   └── profile-page/
│   │       └── components/
│   │           ├── profile-header/
│   │           ├── stats-panel/
│   │           └── recent-games/
│   │
│   └── assets/
│       ├── images/
│       ├── icons/
│       └── styles/
```

---

## Infraestructura (docs/07-infraestructura/)

```
docs/07-infraestructura/
├── docker-compose.yml            # Stack completo: api, front, postgres, redis, minio, nginx
│                                 # Entrada unificada en http://localhost:8088
├── nginx.conf                    # Reverse proxy: /api/, /ws/, /actuator/, /swagger-ui, /minio/
├── Dockerfile.api                # Imagen Spring Boot
├── Dockerfile.front              # Imagen Angular (Nginx interno en :80)
├── prometheus.yml                # Configuración de scraping de métricas
├── grafana-datasource.yml        # Fuente de datos Grafana → Prometheus
└── GATEWAY_LOCAL.md              # Tabla de rutas, troubleshooting, modo debug
```

### Notas de infraestructura

- **MinIO** no está expuesto públicamente. Las imágenes se sirven siempre vía Nginx: `http://localhost:8088/minio/codemon-cards/xy1/...`
- **`CORS_ALLOWED_ORIGINS`** tiene default `http://localhost:8088` en docker-compose. Si el frontend corre fuera de Docker en desarrollo, agregar `http://localhost:4200` en `.env` local.
- **Healthcheck del frontend** usa `127.0.0.1:80` (no `localhost`) para evitar resolución IPv6 dentro del contenedor.
- **`CardSeedRunner`** actualiza de forma idempotente las URLs de cartas existentes de `localhost:9000` al prefijo del gateway (`http://localhost:8088/minio`) al arrancar.
- Las migraciones Flyway (V1–V15) y los seeds de cartas (`xy1.json`) viven en el backend bajo `api/src/main/resources/db/migration/` (ver sección Backend).

---

## Documentación del repositorio

Toda la documentación vive bajo `docs/`, organizada por tema (no por audiencia). Cada subcarpeta lleva un prefijo numérico que sugiere un orden de lectura para quien aterriza al proyecto.

```
docs/
├── INDICE.md                    # Mapa de lectura por carpeta + flujo recomendado
│
├── 01-producto/
│   ├── ESPECIFICACION_PRODUCTO.md   # Especificacion funcional del producto
│   ├── ESTRUCTURA_PROYECTO.md       # Este archivo
│   └── TECNOLOGIAS.md               # Stack y por qué se eligió
│
├── 02-planificacion/
│   ├── README.md                # Mapa Scrum
│   ├── backlog-master.md        # Backlog consolidado
│   ├── 00_guia/                 # GITFLOW.md, GITHUB_PROJECT_WORKFLOW.md, WORKFLOW_DIARIO.md, LISTADO_COMPLETO_ARCHIVOS.md
│   ├── 01_backlog/              # BACKLOG.md, PRODUCT_BACKLOG.md, BACKLOG_REGLAS_POST_MVP.md, epicas_y_user_stories.csv
│   ├── 02_sprints/              # SPRINTS.md, CHECKLIST_ENTREGA.md
│   ├── 03_epicas/               # EPIC-01-AUTH … EPIC-11-CALIDAD (11 épicas)
│   ├── 04_proceso/              # DOD.md, EQUIPOS.md, DEPENDENCIAS_EPICAS.md, CONTRATOS_INDEX.md, TABLA_COMPARATIVA_PASOS_SPRINT.md
│   └── 99_deprecados/           # Archivos obsoletos (preservados como redirects)
│
├── 03-equipos/
│   ├── GUIA_PRIMER_DIA.md       # Prerequisitos + comandos esenciales
│   ├── GUIA_EQUIPO_A.md         # Backend core (auth, cards, decks, game)
│   ├── GUIA_EQUIPO_B.md         # Frontend Angular
│   └── GUIA_EQUIPO_C.md         # DevOps + backend auxiliar
│
├── 04-diseno-ui/
│   ├── Codemon_Battle_Arena.html
│   ├── Codemon_Game_Lobby.html
│   ├── Codemon_Launcher.html
│   └── Codemon_Login.html
│
├── 05-referencia-tecnica/
│   ├── GLOSARIO.md              # Nombres canónicos de paquetes, entidades, DTOs, eventos
│   ├── MOCKS_FRONTEND.md        # Mocks de referencia para el frontend
│   ├── BD_Y_TABLAS.md           # Schema de base de datos
│   ├── CARTAS_E_IMAGENES.md     # Gestión de cartas e imágenes en MinIO
│   ├── CODEMON_GUIAS_TECNICAS.md # Guías técnicas transversales
│   ├── CONTRATOS_API.md         # Contratos de todos los endpoints REST
│   ├── GAME_ENGINE_DETALLES.md  # Motor de juego — parte 1
│   ├── GAME_ENGINE_DETALLES_PARTE2.md  # Motor de juego — parte 2
│   ├── MONITOREO.md             # Prometheus + Grafana
│   ├── PATRONES_DISENO.md       # Patrones de diseño usados
│   ├── PATRONES_REDIS.md        # Estrategias de caché Redis
│   ├── PATRON_CARD_HANDLER.md   # Patrón CardHandler
│   ├── PROTOCOLO_WEBSOCKET.md   # Mensajes STOMP
│   ├── SCHEMA_BD.sql            # Schema SQL completo
│   └── xy1.json                 # Datos de las 146 cartas (seed)
│
├── 06-reglas-juego/
│   ├── REGLAS_INDEX.md          # Índice de reglas
│   ├── 01-setup.md              # Setup inicial de partida
│   ├── 02-turn-flow.md          # Flujo de turno
│   ├── 03-combat.md             # Cálculo de daño
│   ├── 04-win-conditions.md     # Condiciones de victoria
│   ├── 05-deck-validation.md    # Validación de mazos
│   ├── 06-system-logic.md       # Lógica del sistema
│   └── 07-edge-cases.md         # Casos borde
│
├── 07-infraestructura/
│   ├── GATEWAY_LOCAL.md         # Tabla de rutas + troubleshooting + debug
│   ├── Dockerfile.api           # Dockerfile de referencia API
│   ├── Dockerfile.front         # Dockerfile de referencia frontend
│   ├── docker-compose.yml       # Compose de referencia
│   ├── nginx.conf               # Config de Nginx (gateway)
│   ├── prometheus.yml           # Config de Prometheus
│   └── grafana-datasource.yml   # Datasource de Grafana
│
├── 08-desarrollo-con-ia/
│   ├── README.md                # Cómo usar el sistema de PASOS con IA
│   ├── CONVENCIONES.md          # Directivas globales (idioma, estilo, doctrina)
│   ├── ESTADO_PASOS.md          # Estado actual de cada paso
│   ├── HISTORIAL_PASOS.md       # Historial de pasos completados
│   ├── TRAZABILIDAD_PASOS_HU.md  # Trazabilidad pasos ↔ HU (vista humana)
│   ├── TRAZABILIDAD_PASOS_HU.yml # Trazabilidad pasos ↔ HU (fuente de verdad)
│   └── pasos/                   # 92 archivos PASO_S##_##.md (S00–S11) + PASO_TEMPLATE.md
│
└── 09-handoff/
    ├── README.md
    ├── CODEMON_HANDOFF_COMPLETO.md
    ├── CODEMON_EQUIPO_A_BACKEND_CORE.md
    ├── CODEMON_EQUIPO_B_FRONTEND.md
    ├── CODEMON_EQUIPO_C_DEVOPS_BACKEND_AUX.md
    ├── CODEMON_CHECKLIST_EJECUTIVA.md
    └── generar_pdfs.py
```

---

## Raíz del Repositorio

```
codemon/
├── README.md                    # Cara visible del proyecto en GitHub
├── CONTRIBUTING.md              # Guia operativa interna del proyecto
├── docs/02-planificacion/backlog-master.md            # Backlog consolidado
├── .gitignore
├── .env.example                 # Plantilla de variables de entorno
│
├── docker-compose.yml           # Stack completo: 10 servicios Docker
│
├── api/                         # Backend Spring Boot (a implementar)
│   ├── src/
│   ├── pom.xml
│   └── Dockerfile
│
├── front/                       # Frontend Angular (a implementar)
│   ├── src/
│   ├── package.json
│   ├── nginx.conf               # Config interna del contenedor Angular
│   └── Dockerfile
│
├── infra/
│   └── monitoring/              # Prometheus + Grafana
│       ├── prometheus.yml
│       └── grafana/
│           └── provisioning/
│               └── datasources/
│                   └── prometheus.yml
│
├── docs/                        # Toda la documentación del proyecto (ver sección anterior)
│
├── scripts/
│   ├── agent-complete-paso.sh           # Marca un paso como completado
│   ├── generate-traceability-docs.sh    # Genera docs de trazabilidad
│   ├── setup-github-project.sh          # Configura GitHub Projects
│   ├── sync-traceability-github.sh      # Sincroniza trazabilidad con GitHub
│   ├── validate-traceability.sh         # Valida la trazabilidad
│   └── verify_paso.sh                   # Ejecuta los checks de un PASO
│
└── .github/
    ├── ISSUE_TEMPLATE/
    ├── project-fields.yml              # Definición de campos de GitHub Projects
    └── workflows/
        └── project-automation.yml       # Automatización de GitHub Projects

```

---

## Dependencias principales (pom.xml)

### Spring Boot
- spring-boot-starter-web
- spring-boot-starter-data-jpa
- spring-boot-starter-security
- spring-boot-starter-websocket
- spring-boot-starter-mail
- spring-boot-starter-cache

### Base de datos
- postgresql
- flyway-core
- lombok

### Validación y seguridad
- spring-security-crypto
- jjwt (JSON Web Tokens)
- bucket4j (rate limiting)

### Integración
- mercado-pago-sdk (Mercado Pago)

### Caché
- spring-boot-starter-data-redis

### Testing
- spring-boot-starter-test
- junit-jupiter
- mockito
- testcontainers
- testcontainers-postgresql

### Logging
- slf4j
- logback

---

## Dependencias principales (package.json)

### Angular
- @angular/core
- @angular/router
- @angular/forms
- @angular/common/http

### UI
- tailwindcss 3 (devDependency, junto con postcss y autoprefixer)
- @fortawesome/fontawesome-free (iconos)

### WebSockets
- stompjs
- sockjs-client

### HTTP
- axios o httpclient nativo

### Testing
- jasmine
- karma
- playwright

---

## Notas sobre la estructura

### 1. Organización por dominios (Backend)
Cada dominio (auth, cards, decks, etc.) es independiente:
- `controller/` - HTTP endpoints
- `service/` - Lógica de negocio
- `repository/` - Acceso a BD
- `entity/` - Entidades JPA
- `dto/` - Data Transfer Objects

### 2. Shared
Código compartido entre dominios:
- Excepciones globales
- DTOs comunes
- Configuración
- Utilidades

### 3. Tests
Estructura paralela a src/:
- Mismo path
- Nombre: `*Test.java`
- Una clase de test por clase principal

### 4. Frontend
Organización por feature (Auth, Cards, Decks, etc):
- `routes.ts` - Rutas de la feature
- `services/` - Llamadas a API
- `pages/` - Componentes principales
- `components/` - Componentes reutilizables
- `models/` - Interfaces TypeScript

### 5. Base de datos
Migraciones Flyway separadas por feature:
- V1: Schema inicial
- V2-V5: Nuevas features
- V10: Índices
- V12-V14: Seeds
- V15: Constraints finales

---

## Definición de "Completada" una carpeta

Una carpeta está lista cuando:

✅ **Backend - Dominio X**
- Todas las clases existen (aunque estén vacías)
- Todos los métodos en interfaces/abstract están presentes
- pom.xml incluye todas las dependencias
- No hay errores de compilación
- Swagger está configurado

✅ **Frontend - Módulo X**
- Componentes creados
- Rutas definidas
- Servicios con métodos (sin lógica)
- Models/Interfaces tipados
- No hay errores de compilación

✅ **BD - Migraciones**
- Scripts .sql creados
- No hay errores sintácticos SQL
- Nombres consistentes

---

**Fecha:** 19/05/2026  
**Versión:** 2.0
