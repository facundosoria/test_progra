# Backlog operativo — vista por Sprint

> Este archivo reemplaza al antiguo `INDEX.md` (orientado a bloques tecnicos secuenciales). Ahora el backlog se ordena por sprint Scrum: cada sprint declara su Sprint Goal, sus HU/TT, su entregable y sus contratos.

> Para detalle de cada HU (AC + RNF) ir al `EPIC.md` correspondiente. Para el plan completo de sprints ver [SPRINTS.md](../02_sprints/SPRINTS.md). Para vision priorizada por valor ver [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md).

> **GitHub Milestones:** cada Sprint es un Milestone en GitHub con due date.
> La columna `Issue #` se completa una vez que se ejecuta `scripts/setup-github-project.sh`.
> Ver mapeo completo de terminología en [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md#mapeo-a-github-projects-v2).

---

## Resumen ejecutivo

| Sprint | Sprint Goal | Entregable demoable |
|---|---|---|
| S0 | Infraestructura + contratos | Skeleton corre (Docker UP, health UP, Angular hello) |
| S1 | Auth basica | Registro + login + logout + refresh |
| S2 | Catalogo + Mazos | Grid 146 cartas + Deck Builder valido 60 |
| S3 | Motor: setup + turnos | Setup TCG + draw + main phase via API |
| S4 | Motor: combate | AttackPipeline + KO + premios |
| S5 | Primera partida PvE jugable | UI minima → bot easy → game over |
| S6 | Tablero pulido + Lobby | Drag & drop completo + 3 tabs lobby + chat |
| S7 | PvP en tiempo real | Sala privada + matchmaking ranked + WebSocket |
| S8 | Tienda + 2FA + metricas | MP sandbox + sobres + 2FA + Grafana |
| S9 | Social v1 | Ligas + amigos + leaderboard + noticias |
| S10 | OAuth + Perfil | Google/GitHub + perfil consolidado + wallet history |
| S11 | Pulido + bots avanzados + E2E | Bot HARD + responsive + Playwright + carga |

---

## Sprint 0 — Kickoff

**GitHub Milestone:** `S0 — Kickoff` (due: 2026-05-24)
**Sprint Goal:** infraestructura corre y contratos acordados.
**Entregable:** `docker compose up -d` saludable, health UP, frontend hello, contratos firmados.

| Tipo | ID | Titulo | Equipo | SP | Ref | Issue # |
|---|---|---|---|---|---|---|
| TT | TT-10-01 | Definir CONTRATOS_API.md | ALL | 5 | PASO_S00_01 | — |
| TT | TT-10-02 | Definir PROTOCOLO_WEBSOCKET.md | ALL | 3 | PASO_S00_01 | — |
| TT | TT-10-03 | Definir MOCKS_FRONTEND.md | B | 3 | PASO_S00_01 | — |
| TT | TT-10-04 | Instalar herramientas (Java 21, Maven, Node, Angular CLI, Tailwind CSS, Docker) | C | 1 | PASO_S00_02 | — |
| TT | TT-10-05 | docker-compose.yml con 10 servicios | C | 2 | PASO_S00_03 | — |
| TT | TT-10-06 | Proyecto Spring Boot + application.yml | A | 3 | PASO_S00_04 | — |
| TT | TT-10-07 | Migraciones Flyway V1-V15 + seed cards.json | A | 5 | PASO_S00_05 | — |
| TT | TT-10-08 | Proyecto Angular + Tailwind CSS + features + mocks | B | 2 | PASO_S00_06 | — |
| TT | TT-10-09 | Smoke test infra | C | 1 | PASO_S00_07 | — |
| TT | TT-10-10 | Nginx reverse proxy + Dockerfile.front | C | 2 | PASO_S00_03/0_5 | — |
| TT | TT-10-14 | `.env.example` con todas las variables | C | 1 | PASO_S00_03 | — |
| TT | TT-10-15 | Configurar CORS, JWT secret, MP sandbox | A | 2 | PASO_S00_04 | — |
| TT | TT-11-06 | Checkstyle + ESLint + Prettier | A/B | 2 | — | — |
| TT | TT-11-07 | GH Actions: tests + build/Docker | C | 5 | — | — |
| TT | TT-11-08 | Branch protection en `main` | C | 1 | — | — |
| TT | TT-01-02 | Migracion `email_verifications`, `refresh_tokens` (V2-V3) | A | 2 | PASO_S00_05 | — |

---

## Sprint 1 — Auth basica

**GitHub Milestone:** `S1 — Auth básica` (due: 2026-05-31)
**Sprint Goal:** un usuario puede registrarse, loguearse y mantener sesion.
**Entregable:** registro → login → home protegido; logout funcional; refresh automatico.

| Tipo | ID | Titulo | Equipo | SP | Ref | Issue # |
|---|---|---|---|---|---|---|
| HU | HU-01-01 | Registro con email + password | A | 5 | EPIC-01 | — |
| HU | HU-01-03 | Iniciar sesion | A | 3 | EPIC-01 | — |
| HU | HU-01-04 | Cerrar sesion | A | 2 | EPIC-01 | — |
| HU | HU-01-05 | Renovar sesion (refresh token) | A | 3 | EPIC-01 | — |
| TT | TT-01-03 | JwtTokenProvider + JwtAuthenticationFilter + SecurityConfig | A | 5 | PASO_S01_01 | — |
| TT | TT-01-04 | HttpJwtInterceptor con refresh automatico (Angular) | B | 3 | PASO_S01_02/1B_2 | — |
| TT | TT-01-05 | AuthGuard Angular | B | 2 | PASO_S01_03 | — |
| TT | TT-11-02 | Configurar Testcontainers | A | 3 | — | — |

---

## Sprint 2 — Catalogo + Mazos

**GitHub Milestone:** `S2 — Catálogo + Mazos` (due: 2026-06-07)
**Sprint Goal:** un usuario logueado ve las 146 cartas y arma un mazo valido de 60.
**Entregable:** grid catalogo + Deck Builder con drag&drop + validacion en tiempo real + persistencia.

| Tipo | ID | Titulo | Equipo | SP | Ref | Issue # |
|---|---|---|---|---|---|---|
| HU | HU-02-01 | Ver catalogo paginado | A/B | 5 | EPIC-02 | — |
| HU | HU-02-02 | Filtrar y buscar cartas | A/B | 3 | EPIC-02 | — |
| HU | HU-02-03 | Ver detalle de carta | A/B | 3 | EPIC-02 | — |
| HU | HU-03-01 | Crear mazo | A/B | 3 | EPIC-03 | — |
| HU | HU-03-02 | Editar mazo con drag&drop | B | 8 | EPIC-03 | — |
| HU | HU-03-03 | Validar mazo TCG | A | 5 | EPIC-03 | — |
| HU | HU-03-04 | Eliminar mazo | A | 2 | EPIC-03 | — |
| HU | HU-03-05 | Marcar favorito | A | 2 | EPIC-03 | — |
| HU | HU-03-06 | Copiar starter | A | 3 | EPIC-03 | — |
| TT | TT-02-01 | CardSeedRunner 146 cartas idempotente | A | 5 | PASO_S02_02 | — |
| TT | TT-02-02 | MinioService + descarga 292 imagenes | A | 5 | PASO_S02_02 | — |
| TT | TT-02-03 | Entidad `Card` con JSON y arrays | A | 3 | PASO_S02_02 | — |
| TT | TT-02-04 | UI CardCatalog | B | 5 | PASO_S02_05 | — |
| TT | TT-03-01 | DeckValidationService puro Java | A | 5 | PASO_S02_01 | — |
| TT | TT-03-02 | Endpoints CRUD `/decks/**` | A | 5 | PASO_S02_03 | — |
| TT | TT-03-03 | Seed 3 mazos starter | A | 2 | PASO_S02_03 | — |
| TT | TT-03-04 | UI Deck Builder con `@angular/cdk/drag-drop` | B | 8 | PASO_S02_04 | — |

**GATE 1b:** mazos funcionando end-to-end.

---

## Sprint 3 — Motor: setup + turnos sin combate

**GitHub Milestone:** `S3 — Motor: setup + turnos` (due: 2026-06-14)
**Sprint Goal:** una partida arranca y avanza turnos correctamente, sin atacar todavia.
**Entregable:** API permite jugar turnos validos via Postman/Swagger.

| Tipo | ID | Titulo | Equipo | SP | Ref | Issue # |
|---|---|---|---|---|---|---|
| HU | HU-04-01 | Iniciar partida con setup TCG | A | 8 | EPIC-04 | — |
| HU | HU-04-02 | Robar carta al inicio del turno | A | 2 | EPIC-04 | — |
| HU | HU-04-03 | Jugar Pokemon Basico al banco | A | 3 | EPIC-04 | — |
| HU | HU-04-04 | Adjuntar energia | A | 3 | EPIC-04 | — |
| HU | HU-04-05 | Evolucionar Pokemon | A | 3 | EPIC-04 | — |
| TT | TT-04-00 | GameContext + StateMachine | A | 3 | PASO_S03_01 | — |
| TT | TT-04-01 | VictoryConditionChecker | A | 3 | PASO_S03_02 | — |
| TT | TT-04-02 | SetupState (mulligan + premios) | A | 8 | PASO_S03_03 | — |
| TT | TT-04-03 | DrawPhaseState | A | 2 | PASO_S03_04 | — |
| TT | TT-04-04 | MainPhaseState (6 acciones) | A | 13 | PASO_S03_05 | — |
| TT | TT-11-01 | JaCoCo configurado para cobertura | A | 2 | — | — |

---

## Sprint 4 — Motor: combate completo

**GitHub Milestone:** `S4 — Motor: combate` (due: 2026-06-21)
**Sprint Goal:** los ataques resuelven con todas las reglas TCG.
**Entregable:** test integracion completo con KO + premios.

| Tipo | ID | Titulo | Equipo | SP | Ref | Issue # |
|---|---|---|---|---|---|---|
| HU | HU-04-06 | Atacar (9-handlers) | A | 21 | EPIC-04 | — |
| HU | HU-04-07 | Retirar Pokemon activo | A | 3 | EPIC-04 | — |
| HU | HU-04-08 | Tomar premios al hacer KO | A | 3 | EPIC-04 | — |
| TT | TT-04-05 | DamageCalculator + StatusEffectManager | A | 8 | PASO_S04_01 | — |
| TT | TT-04-06 | AttackPipeline (9 handlers) — los 2 devs A juntos | A | 21 | PASO_S04_02 | — |

---

## Sprint 5 — Primera partida PvE jugable end-to-end

**GitHub Milestone:** `S5 — PvE jugable` (due: 2026-06-28)
**Sprint Goal:** un usuario juega PvE completo desde la UI.
**Entregable:** lobby → PvE → tablero → bot easy → game over.

| Tipo | ID | Titulo | Equipo | SP | Ref | Issue # |
|---|---|---|---|---|---|---|
| HU | HU-04-09 | Ganar partida (R-WIN-01..04) | A | 5 | EPIC-04 | — |
| HU | HU-08-01 | Bot EASY | A | 5 | EPIC-08 | — |
| HU | HU-06-01 | Ver zonas del tablero (basico) | B | 5 | EPIC-06 | — |
| TT | TT-04-07 | EndPhaseState | A | 5 | PASO_S05_01 | — |
| TT | TT-04-08 | GameEngine Facade + WebSocket STOMP | A | 5 | PASO_S05_03 | — |
| TT | TT-08-01 | BotEasy implementado | A | 5 | PASO_S05_02 | — |
| TT | TT-06-01 | GameBoardComponent (basico) | B | 8 | PASO_S05_04 | — |
| TT | TT-06-03 | WebSocketService Angular (STOMP+SockJS) con reconexion | B | 5 | PASO_S05_04 | — |

**GATE 2 critico:** motor + WebSocket completos.

---

## Sprint 6 — Tablero pulido + Lobby

**GitHub Milestone:** `S6 — Tablero pulido + Lobby` (due: 2026-07-05)
**Sprint Goal:** experiencia de juego fluida.

| Tipo | ID | Titulo | Equipo | SP | Ref | Issue # |
|---|---|---|---|---|---|---|
| HU | HU-06-02 | Drag&drop completo | B | 8 | EPIC-06 | — |
| HU | HU-06-03 | Animaciones dano/KO/status | B | 5 | EPIC-06 | — |
| HU | HU-06-04 | Lobby con seleccion de modo | B | 5 | EPIC-06 | — |
| HU | HU-06-05 | Chat de partida | B | 3 | EPIC-06 | — |
| TT | TT-06-02 | Drag&drop CDK completo | B | 8 | PASO_S05_04 | — |
| TT | TT-06-04 | LobbyComponent con 3 tabs | B | 5 | PASO_S06_01 | — |
| TT | TT-06-05 | ChatWindowComponent | B | 3 | PASO_S05_04 | — |
| TT | TT-06-06 | Animaciones CSS + toasts | B | 5 | PASO_S05_04 | — |

---

## Sprint 7 — PvP en tiempo real

**GitHub Milestone:** `S7 — PvP en tiempo real` (due: 2026-07-12)
**Sprint Goal:** dos humanos juegan online.

| Tipo | ID | Titulo | Equipo | SP | Ref | Issue # |
|---|---|---|---|---|---|---|
| HU | HU-05-01 | Crear sala privada | C | 5 | EPIC-05 | — |
| HU | HU-05-02 | Unirse a sala con codigo | C | 3 | EPIC-05 | — |
| HU | HU-05-03 | Entrar a cola ranked | C | 8 | EPIC-05 | — |
| HU | HU-05-04 | Cancelar cola | C | 2 | EPIC-05 | — |
| HU | HU-05-05 | Recibir eventos en tiempo real | A/B | 5 | EPIC-05 | — |
| TT | TT-05-01 | Endpoints `/games/rooms/**` | C | 5 | PASO_S07_01 | — |
| TT | TT-05-02 | Cleanup salas expiradas | C | 2 | PASO_S07_01 | — |
| TT | TT-05-03 | Cola Redis sorted set + ventana | C | 8 | PASO_S07_02 | — |
| TT | TT-05-04 | Lock Redis distribuido | C | 3 | PASO_S07_02 | — |
| TT | TT-05-05 | Calculo ELO | C | 3 | PASO_S07_02 | — |
| TT | TT-05-06 | UI Lobby (integracion real) | B | 5 | PASO_S06_01 | — |

**GATE 3:** salas privadas. **GATE 4:** matchmaking ranked.

---

## Sprint 8 — Tienda + 2FA + metricas

**GitHub Milestone:** `S8 — Tienda + 2FA + métricas` (due: 2026-07-19)
**Sprint Goal:** monetizacion en sandbox + 2FA + observabilidad.

| Tipo | ID | Titulo | Equipo | SP | Ref | Issue # |
|---|---|---|---|---|---|---|
| HU | HU-01-02 | Verificacion email (2FA basica) | C | 5 | EPIC-01 | — |
| HU | HU-01-06 | 2FA por email en login | C | 5 | EPIC-01 | — |
| HU | HU-07-01 | Ver balance de coins | C/B | 2 | EPIC-07 | — |
| HU | HU-07-02 | Comprar coins con MP | C | 8 | EPIC-07 | — |
| HU | HU-07-03 | Comprar sobre | C | 5 | EPIC-07 | — |
| HU | HU-07-04 | Abrir sobre con animacion | C/B | 5 | EPIC-07 | — |
| HU | HU-07-05 | Cooldown 24h | C | 3 | EPIC-07 | — |
| HU | HU-02-04 | Ver mi coleccion | C/B | 5 | EPIC-02 | — |
| HU | HU-02-05 | Stats de coleccion | C/B | 3 | EPIC-02 | — |
| TT | TT-01-01 | SMTP + EmailService `@Async` | C | 3 | PASO_S08_03 | — |
| TT | TT-01-06 | Bucket4j rate limit verify-email/resend | C | 3 | PASO_S08_03 | — |
| TT | TT-02-05 | UI CollectionView | B | 3 | PASO_S08_01 | — |
| TT | TT-02-06 | Vista materializada `user_collection_stats` | C | 2 | PASO_S08_02 | — |
| TT | TT-07-01 | Mercado Pago SDK + createPreference | C | 5 | PASO_S08_04 | — |
| TT | TT-07-02 | Webhook MP idempotente | C | 5 | PASO_S08_04 | — |
| TT | TT-07-03 | WalletService `@Transactional` | C | 3 | PASO_S08_04 | — |
| TT | TT-07-04 | BoosterPackService.openPack() | C | 5 | PASO_S08_01 | — |
| TT | TT-07-05 | Redis cooldown 24h | C | 2 | PASO_S08_01 | — |
| TT | TT-07-06 | Seed booster XY1 | C | 1 | PASO_S08_01 | — |
| TT | TT-07-07 | UI `/shop` | B | 5 | PASO_S08_06 | — |
| TT | TT-07-08 | UI `BoosterPackOpener` animado | B | 5 | PASO_S08_06 | — |
| TT | TT-07-09 | UI WalletDisplay | B | 3 | PASO_S11_04 | — |
| TT | TT-10-11 | Configurar Prometheus + datasource Grafana | C | 3 | PASO_S08_05 | — |
| TT | TT-10-12 | Metricas custom `codemon_*` | C | 5 | PASO_S08_05 | — |
| TT | TT-10-13 | Dashboard Grafana base | C | 3 | PASO_S08_05 | — |

---

## Sprint 9 — Social v1

**GitHub Milestone:** `S9 — Social v1` (due: 2026-07-26)
**Sprint Goal:** ligas, amigos, leaderboard, noticias.

| Tipo | ID | Titulo | Equipo | SP | Ref | Issue # |
|---|---|---|---|---|---|---|
| HU | HU-09-03 | Solicitar amistad | C/B | 5 | EPIC-09 | — |
| HU | HU-09-04 | Presencia tiempo real | C/B | 5 | EPIC-09 | — |
| HU | HU-09-05 | Leaderboard global | C/B | 3 | EPIC-09 | — |
| HU | HU-09-06 | Mi posicion en ranking | C/B | 2 | EPIC-09 | — |
| HU | HU-09-07 | Progresion por ligas | C/B | 5 | EPIC-09 | — |
| HU | HU-09-08 | Leer noticias | C/B | 3 | EPIC-09 | — |
| TT | TT-09-01 | Sistema de ligas + hook desde VictoryChecker | C | 3 | PASO_S09_01 | — |
| TT | TT-09-02 | Endpoints `/friends/**` | C | 5 | PASO_S09_02 | — |
| TT | TT-09-03 | Presencia Redis con heartbeat | C | 3 | PASO_S09_02 | — |
| TT | TT-09-04 | Endpoints `/news/**` con verificacion ADMIN | C | 3 | PASO_S09_03 | — |
| TT | TT-09-05 | Vista materializada leaderboard | C | 3 | PASO_S08_02 | — |
| TT | TT-09-08 | UI FriendsList | B | 5 | PASO_S09_05 | — |
| TT | TT-09-09 | UI Leaderboard + Ranking | B | 3 | PASO_S09_04 | — |
| TT | TT-09-10 | UI News con badges | B | 3 | PASO_S09_04 | — |

---

## Sprint 10 — OAuth2 + Perfil + Wallet history

**GitHub Milestone:** `S10 — OAuth + Perfil` (due: 2026-08-02)
**Sprint Goal:** login social y perfil consolidado.

| Tipo | ID | Titulo | Equipo | SP | Ref | Issue # |
|---|---|---|---|---|---|---|
| HU | HU-01-07 | Login Google/GitHub | C/B | 8 | EPIC-01 | — |
| HU | HU-09-01 | Perfil consolidado | C/B | 5 | EPIC-09 | — |
| HU | HU-09-02 | Perfil publico | C/B | 3 | EPIC-09 | — |
| HU | HU-07-06 | Historial pagos | C/B | 3 | EPIC-07 | — |
| TT | TT-01-07 | OAuth2 Spring Security (Google + GitHub) | C | 5 | PASO_S10_01 | — |
| TT | TT-01-08 | UI `/auth/callback` + botones sociales | B | 3 | PASO_S10_02 | — |
| TT | TT-09-06 | Endpoint `/users/me/profile` consolidado | C | 3 | PASO_S11_05 | — |
| TT | TT-09-07 | UI ProfileComponent | B | 5 | PASO_S09_05, PASO_S11_05 | — |

---

## Sprint 11 — Pulido + bots avanzados + E2E

**GitHub Milestone:** `S11 — Pulido + bots + E2E` (due: 2026-08-09)
**Sprint Goal:** producto listo para entrega.

| Tipo | ID | Titulo | Equipo | SP | Ref | Issue # |
|---|---|---|---|---|---|---|
| HU | HU-08-02 | Bot MEDIUM (greedy) | A | 8 | EPIC-08 | — |
| HU | HU-08-03 | Bot HARD (minimax) | A | 13 | EPIC-08 | — |
| HU | HU-08-04 | Elegir personalidad | A | 3 | EPIC-08 | — |
| HU | HU-08-05 | Mensajes con personalidad | A | 5 | EPIC-08 | — |
| HU | HU-06-06 | Responsive mobile/tablet/desktop | B | 5 | EPIC-06 | — |
| TT | TT-08-02 | BotMedium con scoring greedy | A | 8 | PASO_S11_01 | — |
| TT | TT-08-03 | BotHard minimax + alfa-beta | A | 13 | PASO_S11_01 | — |
| TT | TT-08-04 | Tabla `game_chat_messages` + endpoint | A | 3 | PASO_S11_02 | — |
| TT | TT-08-05 | BotChatService con triggers | A | 3 | PASO_S11_02 | — |
| TT | TT-08-06 | Personalidades (Hernan/Santoro/Ramiro) | A | 3 | PASO_S11_03 | — |
| TT | TT-06-07 | Responsive con media queries | B | 3 | PASO_S11_07 | — |
| TT | TT-11-04 | Suite Playwright E2E | B | 13 | PASO_S11_06 | — |
| TT | TT-11-05 | Lighthouse audit | B | 3 | PASO_S11_07 | — |
| TT | TT-11-09 | Test de carga 50 partidas WebSocket | A | 5 | PASO_S11_06 | — |
| TT | TT-11-10 | Documentacion Swagger completa | A/C | 3 | — | — |

**Demo final + entrega.**

---

## Gates como Milestones especiales

Los "Gates" del proyecto son checkpoints de calidad que deben superarse antes de continuar.
En GitHub Projects v2 se representan como **issues de tipo Spike** con label `blocked` en bloque
mientras no se cumplan los criterios.

| Gate | Sprint | Criterio de éxito | Milestone GitHub |
|---|---|---|---|
| **GATE 1b** | S2 | Mazos CRUD + validación TCG funcionando end-to-end. DeckBuilder con drag&drop guardando cambios. | `S2 — Catálogo + Mazos` |
| **GATE 2** | S5 | Motor + WebSocket completos. Partida PvE EASY llega a GAME_OVER sin error 500. | `S5 — PvE jugable` |
| **GATE 3** | S7 | Salas privadas: dos jugadores conectados reciben gameId via WebSocket. | `S7 — PvP en tiempo real` |
| **GATE 4** | S7 | Matchmaking ranked: match encontrado en < 3s con 2 usuarios de rating similar. | `S7 — PvP en tiempo real` |
| **GATE 5** | S8 | Mercado Pago sandbox + sobres + wallet/tienda: comprar coins, abrir sobre y ver colección crecer. | `S8 — Tienda + 2FA + métricas` |
| **GATE 6** | S9 | Leaderboard + ligas + amigos + noticias integrados con datos reales. | `S9 — Social v1` |
| **GATE 7** | S10 | OAuth2 + perfil consolidado + wallet history funcionando desde UI. | `S10 — OAuth + Perfil` |
| **GATE 8** | S11 | Test de carga + Playwright + Lighthouse + checklist de entrega final OK. | `S11 — Pulido + E2E` |

> **Nota:** Los gates no son Milestones separados en GitHub. Son criterios de Done verificados
> al cierre del milestone correspondiente. Si un gate falla, las HU del siguiente sprint
> se mantienen en estado `Blocked` hasta que el gate pase.

---

## Cobertura de PASO_*.md

Todos los `PASO_*.md` de [docs/08-desarrollo-con-ia/pasos/](../../../docs/08-desarrollo-con-ia/pasos/) estan referenciados al menos una vez como Tarea Tecnica. Los pasos siguen siendo guias de implementacion detallada y se citan desde aqui.

| Pasos nuevos (sprint-based) | Sprint(s) |
|---|---|
| PASO_S00_01..PASO_S00_SMOKE | S0 |
| PASO_S01_01..PASO_S01_03 | S1 |
| PASO_S02_01..PASO_S02_SMOKE | S2 |
| PASO_S03_01..PASO_S03_05 | S3 |
| PASO_S04_01..PASO_S04_03 | S4 |
| PASO_S05_01..PASO_S05_SMOKE | S5 |
| PASO_S05_04 (sprint scope S5+S6) | S5, S6 |
| PASO_S06_01 (sprint scope S6+S7) | S6, S7 |
| PASO_S07_01..PASO_S07_SMOKE | S7 |
| PASO_S08_01..PASO_S08_SMOKE | S8 |
| PASO_S09_01..PASO_S09_05 | S9 |
| PASO_S09_05 (sprint scope S9+S10) | S9, S10 |
| PASO_S10_01..PASO_S10_SMOKE | S10 |
| PASO_S11_01..PASO_S11_07 | S11 |
