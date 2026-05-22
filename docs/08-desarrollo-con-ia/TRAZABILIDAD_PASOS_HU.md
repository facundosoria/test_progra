# Trazabilidad PASOS - HU - Epicas - GitHub Project

Este archivo es la vista humana de `TRAZABILIDAD_PASOS_HU.yml`. El YAML es la fuente de verdad para agentes y scripts.

Generado/actualizado: 2026-05-20 15:48

## Regla de cierre

Una HU o TT puede pasar a `Done` en GitHub Projects solo cuando todos sus pasos con `required_for_hu_done: true` estan `DONE` y verificados.

Los pasos smoke o gates pueden figurar como `sin HU directa`; validan integracion, pero no cierran una HU por si solos.

## EPIC-01 - Autenticacion y Seguridad

| Epica | HU/TT | Issue HU | Paso | Requerido | Estado paso | Project status | Contribucion |
|---|---|---:|---|---|---|---|---|
| EPIC-01 | HU-01-01 - Registro con email y password | pendiente | PASO_S01_01 | Si | TODO | Pendiente | backend |
| EPIC-01 | HU-01-01 - Registro con email y password | pendiente | PASO_S01_02 | Si | TODO | Pendiente | frontend |
| EPIC-01 | HU-01-02 - Verificar cuenta via codigo email | pendiente | PASO_S01_02 | Si | TODO | Pendiente | frontend |
| EPIC-01 | HU-01-02 - Verificar cuenta via codigo email | pendiente | PASO_S08_03 | Si | TODO | Pendiente | email-verification-backend |
| EPIC-01 | HU-01-03 - Iniciar sesion | pendiente | PASO_S01_01 | Si | TODO | Pendiente | backend |
| EPIC-01 | HU-01-03 - Iniciar sesion | pendiente | PASO_S01_02 | Si | TODO | Pendiente | frontend |
| EPIC-01 | HU-01-04 - Cerrar sesion | pendiente | PASO_S01_01 | Si | TODO | Pendiente | backend |
| EPIC-01 | HU-01-04 - Cerrar sesion | pendiente | PASO_S01_03 | Si | TODO | Pendiente | app-shell |
| EPIC-01 | HU-01-05 - Renovar sesion sin reingresar credenciales | pendiente | PASO_S01_01 | Si | TODO | Pendiente | backend |
| EPIC-01 | HU-01-05 - Renovar sesion sin reingresar credenciales | pendiente | PASO_S01_02 | Si | TODO | Pendiente | frontend |
| EPIC-01 | HU-01-06 - Segundo factor por email | pendiente | PASO_S08_03 | Si | TODO | Pendiente | two-factor-backend |
| EPIC-01 | HU-01-07 - Login con Google y GitHub OAuth2 | pendiente | PASO_S10_01 | Si | TODO | Pendiente | oauth-backend |
| EPIC-01 | HU-01-07 - Login con Google y GitHub OAuth2 | pendiente | PASO_S10_02 | Si | TODO | Pendiente | oauth-frontend |

## EPIC-02 - Catalogo y Coleccion de Cartas

| Epica | HU/TT | Issue HU | Paso | Requerido | Estado paso | Project status | Contribucion |
|---|---|---:|---|---|---|---|---|
| EPIC-02 | HU-02-01 - Ver catalogo paginado de cartas XY1 | pendiente | PASO_S02_02 | Si | TODO | Pendiente | backend |
| EPIC-02 | HU-02-01 - Ver catalogo paginado de cartas XY1 | pendiente | PASO_S02_05 | Si | TODO | Pendiente | frontend |
| EPIC-02 | HU-02-02 - Filtrar y buscar cartas | pendiente | PASO_S02_02 | Si | TODO | Pendiente | backend |
| EPIC-02 | HU-02-02 - Filtrar y buscar cartas | pendiente | PASO_S02_05 | Si | TODO | Pendiente | frontend |
| EPIC-02 | HU-02-03 - Ver detalle de una carta | pendiente | PASO_S02_02 | Si | TODO | Pendiente | backend |
| EPIC-02 | HU-02-03 - Ver detalle de una carta | pendiente | PASO_S02_05 | Si | TODO | Pendiente | frontend |
| EPIC-02 | HU-02-04 - Ver mi coleccion personal | pendiente | PASO_S08_01 | Si | TODO | Pendiente | collection-backend |
| EPIC-02 | HU-02-05 - Ver estadisticas de mi coleccion | pendiente | PASO_S08_02 | Si | TODO | Pendiente | collection-stats |

## EPIC-03 - Constructor de Mazos

| Epica | HU/TT | Issue HU | Paso | Requerido | Estado paso | Project status | Contribucion |
|---|---|---:|---|---|---|---|---|
| EPIC-03 | HU-03-01 - Crear mazo nuevo | pendiente | PASO_S02_03 | Si | TODO | Pendiente | backend |
| EPIC-03 | HU-03-02 - Editar mazo con drag and drop | pendiente | PASO_S02_04 | Si | TODO | Pendiente | frontend |
| EPIC-03 | HU-03-03 - Validar mazo TCG XY1 | pendiente | PASO_S02_01 | Si | TODO | Pendiente | backend-validation |
| EPIC-03 | HU-03-03 - Validar mazo TCG XY1 | pendiente | PASO_S02_04 | Si | TODO | Pendiente | frontend-validation |
| EPIC-03 | HU-03-04 - Eliminar mazo | pendiente | PASO_S02_03 | Si | TODO | Pendiente | backend |
| EPIC-03 | HU-03-05 - Marcar mazo como favorito | pendiente | PASO_S02_03 | Si | TODO | Pendiente | backend |
| EPIC-03 | HU-03-06 - Copiar mazo starter | pendiente | PASO_S02_03 | Si | TODO | Pendiente | backend |

## EPIC-04 - Motor de Juego

| Epica | HU/TT | Issue HU | Paso | Requerido | Estado paso | Project status | Contribucion |
|---|---|---:|---|---|---|---|---|
| EPIC-04 | HU-04-01 - Iniciar partida con setup correcto | pendiente | PASO_S03_01 | Si | TODO | Pendiente | engine-foundation |
| EPIC-04 | HU-04-01 - Iniciar partida con setup correcto | pendiente | PASO_S03_03 | Si | TODO | Pendiente | setup |
| EPIC-04 | HU-04-02 - Robar carta al inicio de mi turno | pendiente | PASO_S03_04 | Si | TODO | Pendiente | draw-phase |
| EPIC-04 | HU-04-03 - Jugar Pokemon Basico al banco | pendiente | PASO_S03_05 | Si | TODO | Pendiente | main-phase |
| EPIC-04 | HU-04-04 - Adjuntar energia | pendiente | PASO_S03_05 | Si | TODO | Pendiente | main-phase |
| EPIC-04 | HU-04-05 - Evolucionar Pokemon | pendiente | PASO_S03_05 | Si | TODO | Pendiente | main-phase |
| EPIC-04 | HU-04-06 - Atacar al activo enemigo | pendiente | PASO_S04_01 | Si | TODO | Pendiente | damage-and-status |
| EPIC-04 | HU-04-06 - Atacar al activo enemigo | pendiente | PASO_S04_02 | Si | TODO | Pendiente | attack-pipeline |
| EPIC-04 | HU-04-06 - Atacar al activo enemigo | pendiente | PASO_S04_03 | Si | TODO | Pendiente | card-handlers |
| EPIC-04 | HU-04-07 - Retirar Pokemon activo | pendiente | PASO_S04_03 | Si | TODO | Pendiente | retreat |
| EPIC-04 | HU-04-08 - Tomar premios al hacer KO | pendiente | PASO_S04_03 | Si | TODO | Pendiente | prizes |
| EPIC-04 | HU-04-09 - Ganar la partida | pendiente | PASO_S03_02 | Si | TODO | Pendiente | win-conditions |
| EPIC-04 | HU-04-09 - Ganar la partida | pendiente | PASO_S05_01 | Si | TODO | Pendiente | end-phase |

## EPIC-05 - Multijugador y Matchmaking

| Epica | HU/TT | Issue HU | Paso | Requerido | Estado paso | Project status | Contribucion |
|---|---|---:|---|---|---|---|---|
| EPIC-05 | HU-05-01 - Crear sala privada con codigo | pendiente | PASO_S07_01 | Si | TODO | Pendiente | private-room |
| EPIC-05 | HU-05-02 - Unirme a sala con codigo | pendiente | PASO_S07_01 | Si | TODO | Pendiente | private-room |
| EPIC-05 | HU-05-03 - Entrar a cola ranked | pendiente | PASO_S07_02 | Si | TODO | Pendiente | matchmaking |
| EPIC-05 | HU-05-04 - Cancelar mi entrada en la cola | pendiente | PASO_S07_02 | Si | TODO | Pendiente | matchmaking |
| EPIC-05 | HU-05-05 - Recibir eventos de partida en tiempo real | pendiente | PASO_S05_03 | Si | TODO | Pendiente | websocket-events |

## EPIC-06 - Tablero y Experiencia de Juego

| Epica | HU/TT | Issue HU | Paso | Requerido | Estado paso | Project status | Contribucion |
|---|---|---:|---|---|---|---|---|
| EPIC-06 | HU-06-01 - Ver mi mano activo banco premios y descarte | pendiente | PASO_S05_04 | Si | TODO | Pendiente | board-ui |
| EPIC-06 | HU-06-04 - Lobby con seleccion de modo | pendiente | PASO_S06_01 | Si | TODO | Pendiente | lobby-ui |
| EPIC-06 | HU-06-05 - Chat de partida | pendiente | PASO_S11_02 | Si | TODO | Pendiente | chat-backend |
| EPIC-06 | HU-06-06 - Responsive mobile tablet desktop | pendiente | PASO_S11_07 | Si | TODO | Pendiente | responsive-ui |

## EPIC-07 - Tienda y Monetizacion

| Epica | HU/TT | Issue HU | Paso | Requerido | Estado paso | Project status | Contribucion |
|---|---|---:|---|---|---|---|---|
| EPIC-07 | HU-07-01 - Ver mi balance de coins | pendiente | PASO_S08_04 | Si | TODO | Pendiente | wallet-backend |
| EPIC-07 | HU-07-01 - Ver mi balance de coins | pendiente | PASO_S08_06 | Si | TODO | Pendiente | shop-ui |
| EPIC-07 | HU-07-01 - Ver mi balance de coins | pendiente | PASO_S11_04 | Si | TODO | Pendiente | wallet-endpoint-ui |
| EPIC-07 | HU-07-02 - Comprar coins con Mercado Pago | pendiente | PASO_S08_04 | Si | TODO | Pendiente | payments |
| EPIC-07 | HU-07-03 - Comprar sobre booster pack | pendiente | PASO_S08_01 | Si | TODO | Pendiente | booster-backend |
| EPIC-07 | HU-07-03 - Comprar sobre booster pack | pendiente | PASO_S08_06 | Si | TODO | Pendiente | shop-ui |
| EPIC-07 | HU-07-04 - Abrir sobre con animacion | pendiente | PASO_S08_01 | Si | TODO | Pendiente | booster-backend |
| EPIC-07 | HU-07-04 - Abrir sobre con animacion | pendiente | PASO_S08_06 | Si | TODO | Pendiente | shop-ui |
| EPIC-07 | HU-07-05 - Cooldown 24h tras abrir sobre | pendiente | PASO_S08_01 | Si | TODO | Pendiente | booster-backend |
| EPIC-07 | HU-07-05 - Cooldown 24h tras abrir sobre | pendiente | PASO_S08_06 | Si | TODO | Pendiente | shop-ui |
| EPIC-07 | HU-07-06 - Historial de pagos | pendiente | PASO_S08_04 | Si | TODO | Pendiente | payments |
| EPIC-07 | HU-07-06 - Historial de pagos | pendiente | PASO_S11_04 | Si | TODO | Pendiente | wallet-history |

## EPIC-08 - Bot e Inteligencia Artificial

| Epica | HU/TT | Issue HU | Paso | Requerido | Estado paso | Project status | Contribucion |
|---|---|---:|---|---|---|---|---|
| EPIC-08 | HU-08-01 - Bot EASY | pendiente | PASO_S05_02 | Si | TODO | Pendiente | easy-bot |
| EPIC-08 | HU-08-02 - Bot MEDIUM greedy | pendiente | PASO_S11_01 | Si | TODO | Pendiente | medium-bot |
| EPIC-08 | HU-08-03 - Bot HARD minimax | pendiente | PASO_S11_01 | Si | TODO | Pendiente | hard-bot |
| EPIC-08 | HU-08-04 - Elegir personalidad del bot | pendiente | PASO_S11_03 | Si | TODO | Pendiente | bot-personality |
| EPIC-08 | HU-08-05 - Mensajes con personalidad durante partida | pendiente | PASO_S11_02 | Si | TODO | Pendiente | bot-chat-backend |
| EPIC-08 | HU-08-05 - Mensajes con personalidad durante partida | pendiente | PASO_S11_03 | Si | TODO | Pendiente | bot-personality |

## EPIC-09 - Social y Comunidad

| Epica | HU/TT | Issue HU | Paso | Requerido | Estado paso | Project status | Contribucion |
|---|---|---:|---|---|---|---|---|
| EPIC-09 | HU-09-01 - Perfil consolidado | pendiente | PASO_S11_05 | Si | TODO | Pendiente | profile |
| EPIC-09 | HU-09-02 - Perfil publico de otro jugador | pendiente | PASO_S11_05 | Si | TODO | Pendiente | public-profile |
| EPIC-09 | HU-09-03 - Solicitar amistad | pendiente | PASO_S09_02 | Si | TODO | Pendiente | friends-backend |
| EPIC-09 | HU-09-03 - Solicitar amistad | pendiente | PASO_S09_05 | Si | TODO | Pendiente | friends-ui |
| EPIC-09 | HU-09-04 - Presencia en tiempo real | pendiente | PASO_S09_02 | Si | TODO | Pendiente | presence-backend |
| EPIC-09 | HU-09-04 - Presencia en tiempo real | pendiente | PASO_S09_05 | Si | TODO | Pendiente | presence-ui |
| EPIC-09 | HU-09-05 - Leaderboard global | pendiente | PASO_S08_02 | Si | TODO | Pendiente | leaderboard-backend |
| EPIC-09 | HU-09-05 - Leaderboard global | pendiente | PASO_S09_04 | Si | TODO | Pendiente | leaderboard-ui |
| EPIC-09 | HU-09-06 - Mi posicion en ranking | pendiente | PASO_S08_02 | Si | TODO | Pendiente | ranking-backend |
| EPIC-09 | HU-09-06 - Mi posicion en ranking | pendiente | PASO_S09_04 | Si | TODO | Pendiente | ranking-ui |
| EPIC-09 | HU-09-07 - Progresion por ligas | pendiente | PASO_S09_01 | Si | TODO | Pendiente | leagues |
| EPIC-09 | HU-09-08 - Leer noticias | pendiente | PASO_S09_03 | Si | TODO | Pendiente | news-backend |
| EPIC-09 | HU-09-08 - Leer noticias | pendiente | PASO_S09_04 | Si | TODO | Pendiente | news-ui |

## EPIC-10 - Infraestructura y DevOps

| Epica | HU/TT | Issue HU | Paso | Requerido | Estado paso | Project status | Contribucion |
|---|---|---:|---|---|---|---|---|
| EPIC-10 | TT-10-01 - Definir CONTRATOS_API.md | pendiente | PASO_S00_01 | Si | READY | Pendiente | contracts |
| EPIC-10 | TT-10-02 - Definir PROTOCOLO_WEBSOCKET.md | pendiente | PASO_S00_01 | Si | READY | Pendiente | websocket-contracts |
| EPIC-10 | TT-10-03 - Definir MOCKS_FRONTEND.md | pendiente | PASO_S00_01 | Si | READY | Pendiente | frontend-mocks |
| EPIC-10 | TT-10-03 - Definir MOCKS_FRONTEND.md | pendiente | PASO_S00_06 | Si | TODO | Pendiente | frontend-project |
| EPIC-10 | TT-10-05 - docker-compose.yml con 10 servicios | pendiente | PASO_S00_02 | Si | TODO | Pendiente | local-tooling |
| EPIC-10 | TT-10-05 - docker-compose.yml con 10 servicios | pendiente | PASO_S00_03 | Si | TODO | Pendiente | docker-stack |
| EPIC-10 | TT-10-05 - docker-compose.yml con 10 servicios | pendiente | PASO_S00_04 | Si | TODO | Pendiente | api-project |
| EPIC-10 | TT-10-05 - docker-compose.yml con 10 servicios | pendiente | PASO_S00_07 | Si | TODO | Pendiente | infrastructure-smoke |
| EPIC-10 | TT-10-07 - Migraciones Flyway V1-V15 | pendiente | PASO_S00_05 | Si | TODO | Pendiente | database-migrations |
| EPIC-10 | TT-10-12 - Metricas custom codemon_* | pendiente | PASO_S08_05 | Si | TODO | Pendiente | monitoring |
| EPIC-10 | TT-10-21 - HTTPS productivo con Nginx TLS | pendiente | PASO_S11_08 | Si | DONE | Done | production-https |
| EPIC-10 | GATE 0 - infraestructura S0 | pendiente | PASO_S00_SMOKE | No | TODO | - | smoke-gate |

## EPIC-11 - Calidad y Testing

| Epica | HU/TT | Issue HU | Paso | Requerido | Estado paso | Project status | Contribucion |
|---|---|---:|---|---|---|---|---|
| EPIC-11 | TT-11-04 - Suite Playwright E2E | pendiente | PASO_S11_06 | Si | TODO | Pendiente | e2e-tests |
| EPIC-11 | TT-11-05 - Lighthouse audit mobile | pendiente | PASO_S11_07 | Si | TODO | Pendiente | lighthouse |
| EPIC-11 | TT-11-09 - Test de carga 50 partidas WebSocket | pendiente | PASO_S11_06 | Si | TODO | Pendiente | load-tests |

## SIN_EPICA - Gate S7

| Epica | HU/TT | Issue HU | Paso | Requerido | Estado paso | Project status | Contribucion |
|---|---|---:|---|---|---|---|---|
| - | GATE 3/4 - salas privadas y matchmaking | pendiente | PASO_S07_SMOKE | No | TODO | - | smoke-gate |

## SIN_EPICA - Gate S3-S5

| Epica | HU/TT | Issue HU | Paso | Requerido | Estado paso | Project status | Contribucion |
|---|---|---:|---|---|---|---|---|
| - | GATE 2 - motor y PvE | pendiente | PASO_S05_SMOKE | No | TODO | - | smoke-gate |

## SIN_EPICA - Gate S1-S2

| Epica | HU/TT | Issue HU | Paso | Requerido | Estado paso | Project status | Contribucion |
|---|---|---:|---|---|---|---|---|
| - | GATE 1a/1b - auth cartas y mazos | pendiente | PASO_S02_SMOKE | No | TODO | - | smoke-gate |

## SIN_EPICA - Gate S8

| Epica | HU/TT | Issue HU | Paso | Requerido | Estado paso | Project status | Contribucion |
|---|---|---:|---|---|---|---|---|
| - | GATE 5 - tienda pagos sobres 2FA metricas | pendiente | PASO_S08_SMOKE | No | TODO | - | smoke-gate |

## SIN_EPICA - Gate S9-S10

| Epica | HU/TT | Issue HU | Paso | Requerido | Estado paso | Project status | Contribucion |
|---|---|---:|---|---|---|---|---|
| - | GATE 6/7 - social OAuth perfil | pendiente | PASO_S10_SMOKE | No | TODO | - | smoke-gate |
