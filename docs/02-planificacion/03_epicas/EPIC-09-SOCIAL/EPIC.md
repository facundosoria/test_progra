# EPIC-09 — Social y Comunidad

## 1. Resumen

- **Valor de negocio:** los jugadores construyen identidad (perfil), socializan (amigos, presencia), compiten (leaderboard, ligas) y se enteran de novedades (noticias). Aumenta la retencion del producto.
- **Roles involucrados:** Jugador autenticado, Admin (publicar noticias).
- **Sprints donde se completa:** S9 (ligas, amigos, noticias) y S10 (perfil consolidado, OAuth se hace en EPIC-01).
- **Equipos:** C (backend), B (frontend).

## 2. Historias de Usuario

### HU-09-01 — Ver mi perfil consolidado
**Como** jugador, **quiero** ver mis stats, coleccion y historial en una sola pagina, **para** tener una vista resumen.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: `GET /users/me/profile` devuelve: `username`, `email`, `wins`, `losses`, `winRate`, `skillRating`, `league`, `coins`, `collectionStats`, `recentGames[]` (ultimas 10).
- AC2: La UI muestra avatar (placeholder), badges de liga y % coleccion.
- AC3: P95 < 400 ms.
- AC4: La query de `recentGames[]` se beneficia de los indices parciales `idx_g_p1_history` e `idx_g_p2_history` (`(player_id, status, ended_at DESC) WHERE status IN ('FINISHED','ABANDONED')`). Se valida con `EXPLAIN ANALYZE` que use index scan, no seq scan.

**RNF:**
- RNF-Performance: la consulta de historial debe usar union de los dos indices parciales, no full scan de `games`.

**Dependencias:** HU-09-05 (stats), HU-02-05 (collection stats), EPIC-07.
**Sprint:** S10.

---

### HU-09-02 — Ver perfil publico de otro jugador
**Como** jugador, **quiero** ver el perfil publico de otros, **para** comparar stats antes de retarlos.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: `GET /users/{userId}/profile` devuelve solo info publica: `username`, `wins`, `losses`, `winRate`, `skillRating`, `league`, `presenceStatus`.
- AC2: No expone email, coins, ni historial detallado.

**Sprint:** S10.

---

### HU-09-03 — Solicitar amistad
**Como** jugador, **quiero** enviar/aceptar/rechazar solicitudes de amistad, **para** armar mi lista de contactos.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: `POST /friends/request {targetUserId}` crea solicitud en estado PENDING.
- AC2: `PUT /friends/{requestId}/accept` solo lo puede hacer el receptor.
- AC3: `PUT /friends/{requestId}/reject` o `DELETE /friends/{id}` para cancelar.
- AC4: No permite solicitud a si mismo, ni duplicada.
- AC5: Notificacion via WebSocket al receptor (`FRIEND_REQUEST_RECEIVED`).

**Sprint:** S9.

---

### HU-09-04 — Ver presencia en tiempo real de mis amigos
**Como** jugador, **quiero** ver quien esta online/jugando/offline, **para** decidir a quien retar.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: `GET /friends` devuelve amigos ACCEPTED con `presenceStatus` (ONLINE / PLAYING / OFFLINE).
- AC2: Estado en Redis: `user:presence:{userId}` con TTL 5 min, heartbeat frontend cada 2 min.
- AC3: Al iniciar partida, `setPlaying(userId, gameId)`; al terminar, vuelve a ONLINE.
- AC4: La UI muestra iconos: 🟢 ONLINE · 🎮 PLAYING · ⚫ OFFLINE.
- AC5: Boton "Retar" visible solo si amigo esta ONLINE; crea sala privada y emite `FRIEND_CHALLENGE`.

**RNF:**
- RNF-Privacidad: solo amigos ven mi presencia.

**Sprint:** S9.

---

### HU-09-05 — Ver leaderboard global
**Como** jugador, **quiero** ver el ranking de mejores jugadores, **para** medir donde estoy parado.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: `GET /leaderboard?filter=pvp&page=0&size=50` devuelve top jugadores ordenados por `skillRating DESC`.
- AC2: Filter `pvp` excluye partidas no QUEUE.
- AC3: Cada fila: `rank`, `username`, `wins`, `losses`, `winRate`, `skillRating`, `league`.
- AC4: Vista materializada `leaderboard` refrescada al final de cada partida ranked.

**RNF:**
- RNF-Performance: P95 < 200 ms gracias a vista materializada.

**Sprint:** S9.

---

### HU-09-06 — Ver mi posicion en el ranking
**Como** jugador, **quiero** saber mi rank actual y cuantos puntos me faltan para subir, **para** tener motivacion.

**Story Points:** 2

**Criterios de Aceptacion:**
- AC1: `GET /users/me/ranking` devuelve `{rank, points, league, nextLeague, pointsToNext}`.
- AC2: La UI muestra barra de progreso hacia la siguiente liga.

**Sprint:** S9.

---

### HU-09-07 — Ver progresion por ligas
**Como** jugador, **quiero** ascender de BRONCE → PLATA → ORO segun gano partidas, **para** sentir progreso.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: Victoria en QUEUE o ROOM → +25 puntos de ranking.
- AC2: Derrota → sin cambio.
- AC3: PvE → sin efecto en ligas.
- AC4: Umbral BRONCE → PLATA: 1000 puntos; PLATA → ORO: 2500 puntos.
- AC5: Campo `users.league` se actualiza al cruzar umbral.
- AC6: `VictoryConditionChecker.declareWinner()` invoca `rankingService.addWinPoints()`.

**Sprint:** S9.

---

### HU-09-08 — Leer noticias publicadas por administracion
**Como** jugador, **quiero** ver novedades del juego, **para** estar al tanto de eventos y mantenimientos.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: `GET /news?category=&page=0&size=10` es PUBLICO (sin auth).
- AC2: Ordenado: `is_pinned DESC, published_at DESC`.
- AC3: Categorias: UPDATE, EVENT, MAINTENANCE, ANNOUNCEMENT.
- AC4: `POST /news` solo para usuarios con `role=ADMIN` (verificado contra BD, no solo JWT).
- AC5: La UI muestra badge por categoria con color distintivo y noticias pinned arriba.

**Sprint:** S9.

## 3. Tareas Tecnicas

| ID | Tarea | Origen | Equipo | SP | Sprint |
|---|---|---|---|---|---|
| TT-09-01 | Sistema de ligas y puntos: tabla, umbrales, hook desde `VictoryConditionChecker` | PASO_S09_01 | C | 3 | S9 |
| TT-09-02 | Endpoints `/friends/**` con estados PENDING/ACCEPTED/REJECTED | PASO_S09_02 | C | 5 | S9 |
| TT-09-03 | Presencia Redis con heartbeat y `setPlaying` | PASO_S09_02 | C | 3 | S9 |
| TT-09-04 | Endpoints `/news/**` con verificacion de rol desde BD | PASO_S09_03 | C | 3 | S9 |
| TT-09-05 | Vista materializada `leaderboard` (V11) + indice unico | PASO_S08_02 | C | 3 | S9 |
| TT-09-06 | Endpoint `/users/me/profile` consolidado; `recentGames[]` consulta `games` usando indices `idx_g_p1_history`/`idx_g_p2_history`; verificar plan con `EXPLAIN ANALYZE` | PASO_S11_05 | C | 3 | S10 |
| TT-09-07 | UI `ProfileComponent` con stats + recent games + collection summary | PASO_S09_05, PASO_S11_05 | B | 5 | S10 |
| TT-09-08 | UI `FriendsListComponent` con presencia y boton "Retar" | PASO_S09_05 | B | 5 | S9 |
| TT-09-09 | UI `LeaderboardComponent` y `RankingComponent` (mi rank) | PASO_S09_04 | B | 3 | S9 |
| TT-09-10 | UI `NewsComponent` con badges por categoria | PASO_S09_04 | B | 3 | S9 |

## 4. Contratos involucrados

- REST: `GET /users/me/profile`, `GET /users/{id}/profile`, `POST/PUT/DELETE /friends/**`, `GET /friends`, `GET /friends/pending`, `POST /friends/{id}/challenge`, `GET /leaderboard`, `GET /users/me/ranking`, `GET /news`, `POST /news`.
- STOMP: `/user/queue/social` (`FRIEND_REQUEST_RECEIVED`, `FRIEND_CHALLENGE`, `PRESENCE_CHANGED`).

## 5. Definition of Done especifico

- Vista materializada `leaderboard` con indice unico (`REFRESH CONCURRENTLY` funciona).
- Test: solicitud duplicada → error; solicitud a si mismo → error.
- Test: cruce umbral 1000 → liga actualizada a PLATA.
- Test: noticias `is_pinned` aparecen primero.
- Test: usuario normal POST /news → 403.
- Cobertura `RankingService`, `FriendsService`, `NewsService` ≥ 80%.
- Hereda [DOD.md](../../04_proceso/DOD.md) global.
