# Equipos — Codemon TCG (modelo Scrum)

> Reemplaza al antiguo `MULTI_EQUIPO.md` (orientado a bloques tecnicos secuenciales). Ahora la organizacion habla de equipos Scrum cross-functional con asignacion por sprint.

---

## Estructura de equipos

El proyecto se ejecuta con **3 equipos Scrum** que comparten Sprint Planning, Daily, Review y Retrospective. Cada equipo tiene su area de especializacion pero NO trabaja en silos: hay handoffs continuos via contratos API/WS.

### Equipo A — Backend Core / Motor de Juego
- **Foco:** motor TCG (la parte mas critica), autenticacion, mazos, cartas.
- **Composicion sugerida:** 2 devs backend senior (Java/Spring + sistemas de estado).
- **Epicas principales:** EPIC-01 (auth core), EPIC-02 (cards backend), EPIC-03 (mazos backend), EPIC-04 (motor), EPIC-08 (bots).
- **Sprints donde es protagonista:** S1, S2 (backend), S3, S4, S5, S11 (bots).

### Equipo B — Frontend
- **Foco:** UI Angular completa con Tailwind CSS: auth, deck builder, tablero, lobby, shop, perfil, social.
- **Composicion sugerida:** 1-2 devs frontend (Angular/TypeScript/Tailwind CSS).
- **Epicas principales:** EPIC-06 (tablero y UX), EPIC-11 (E2E + responsive). Aporta UI a TODAS las epicas funcionales.
- **Sprints donde es protagonista:** S2 (Deck Builder), S5/S6 (tablero), S8 (shop), S11 (responsive + E2E).

### Equipo C — Backend Auxiliar + DevOps
- **Foco:** infraestructura, DevOps, integraciones externas (MP, OAuth2, SMTP), matchmaking, ranking, social.
- **Composicion sugerida:** 1-2 devs backend mid (Java/Spring + DevOps + Redis).
- **Epicas principales:** EPIC-10 (infra), EPIC-05 (matchmaking), EPIC-07 (tienda), EPIC-09 (social), partes de EPIC-01 (2FA, OAuth2).
- **Sprints donde es protagonista:** S0, S7, S8, S9, S10.

---

## Capacity por sprint (estimado)

Asumiendo 2-2-2 devs (A-B-C) trabajando ~32 h utiles/semana cada uno (descontando ceremonias):

| Equipo | h/sprint | SP/sprint estimado |
|---|---|---|
| A | 64 | ~40-50 SP |
| B | 32-64 | ~25-45 SP |
| C | 32-64 | ~25-45 SP |
| **Total combinado** | — | **~95-125 SP** |

> Ver [SPRINTS.md](../02_sprints/SPRINTS.md) para la planificacion sprint a sprint con SP totales por sprint.

---

## Asignacion equipo → epicas → sprints

| Sprint | Equipo A | Equipo B | Equipo C |
|---|---|---|---|
| S0 | Spring Boot + Flyway | Angular + mocks | Docker, herramientas, smoke test |
| S1 | JWT, Auth core | Auth UI, Guards, Interceptor | — |
| S2 | DeckValidation, CRUD mazos, seed cartas | Deck Builder UI, Catalog UI | — |
| S3 | Motor: GameContext, Setup, Draw, Main | — (trabajo paralelo en components base) | — (trabajo paralelo en metricas) |
| S4 | Motor: Damage, Status, AttackPipeline | — (animaciones tablero off-line) | — |
| S5 | Motor: EndPhase, Bot EASY, GameEngine, WS | Tablero minimo conectado | — |
| S6 | (soporte tecnico a B) | Drag&drop, Lobby, Chat, Animaciones | — |
| S7 | (soporte WS) | Lobby integrado | Salas privadas, Matchmaking |
| S8 | (soporte) | Shop UI, Wallet UI, Booster opener | 2FA, MP, sobres, metricas Grafana |
| S9 | (soporte) | Friends UI, Leaderboard UI, News UI | Ligas, friends backend, news backend |
| S10 | (soporte) | OAuth callback, Profile UI | OAuth2 backend, Profile endpoint |
| S11 | Bot MEDIUM/HARD, chat-bot, personalidades | Responsive, Playwright E2E | Documentacion, deploy final |

---

## Gates de sincronizacion (handoffs entre equipos)

| Gate | Sprint | Quien entrega | Quien lo necesita | Que desbloquea |
|---|---|---|---|---|
| GATE 0 | S0 | TODOS | TODOS | inicio del trabajo paralelo |
| GATE 1a | S1 | A (JWT funcional) | B | reemplazar mocks de auth |
| GATE 1b | S2 | A (cards + decks API) | B | Deck Builder real |
| GATE 2 | S5 | A (motor + WS) | B + C | tablero real (B) y matchmaking (C) |
| GATE 3 | S7 | C (salas privadas) | B | Lobby con salas reales |
| GATE 4 | S7 | C (matchmaking) | B | Lobby con cola ranked real |
| GATE 5 | S8 | C (MP + sobres + wallet) | B | Shop con compra real |
| GATE 6 | S9 | C (leaderboard + ligas + amigos + noticias) | B | Social UI con datos reales |
| GATE 7 | S10 | C (OAuth2 + perfil endpoint) | B | Login social y perfil consolidado |
| GATE 8 | S11 | TODOS | TODOS | Carga + Playwright + Lighthouse + entrega |

---

## Reuniones cross-equipo

| Evento | Frecuencia | Participantes |
|---|---|---|
| Sprint Planning | Lunes 9:00 (1 h) | TODOS |
| Daily Stand-up | Diario 9:30 (15 min) | TODOS por separado, sync rapido entre PMs si hace falta |
| Refinamiento backlog | Miercoles 14:00 (1 h) | PO + lideres tecnicos por equipo |
| Sprint Review | Viernes 14:00 (45 min) | TODOS + stakeholders |
| Retrospectiva | Viernes 15:00 (45 min) | TODOS |
| Sync de gates | ad hoc cuando se aproxima un gate | equipos involucrados en el gate |

---

## Documentos de coordinacion (compartidos)

- [CONTRATOS_API.md](../../../docs/05-referencia-tecnica/CONTRATOS_API.md) — fuente unica de endpoints REST. Si A modifica un contrato, lo comunica en el daily y actualiza el archivo.
- [PROTOCOLO_WEBSOCKET.md](../../../docs/05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md) — eventos STOMP.
- [MOCKS_FRONTEND.md](../../../docs/05-referencia-tecnica/MOCKS_FRONTEND.md) — mocks que B usa mientras A no tenga el endpoint listo.
- [CONTRATOS_INDEX.md](CONTRATOS_INDEX.md) — mapeo endpoint/evento → HU.
- [DEPENDENCIAS_EPICAS.md](DEPENDENCIAS_EPICAS.md) — ordenes de implementacion entre epicas.

---

## Roles Scrum

| Rol | Responsable sugerido |
|---|---|
| Product Owner | Lider del proyecto / cliente / docente del TPI |
| Scrum Master | Rotativo entre equipos cada sprint |
| Devs A/B/C | Cross-functional dentro de su area |

> Si el proyecto se ejecuta como TPI universitario, el "PO" puede ser el docente que aprueba prioridades y el "SM" rotativo entre los lideres tecnicos de cada equipo.
