# Indice de Contratos API y WebSocket → Historias de Usuario

> Mapeo bidireccional entre cada endpoint REST y evento STOMP, y la(s) HU que lo demandan. Util para Equipo B (frontend) al construir services y para code review.

> **Fuentes canonicas:**
> - REST: [CONTRATOS_API.md](../../../docs/05-referencia-tecnica/CONTRATOS_API.md)
> - STOMP: [PROTOCOLO_WEBSOCKET.md](../../../docs/05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md)

---

## REST — Endpoints por dominio

### Autenticacion (`/auth`, `/oauth2`)
| Endpoint | HU | Sprint | Equipo |
|---|---|---|---|
| `POST /auth/register` | HU-01-01 | S1 | A |
| `POST /auth/verify-email` | HU-01-02 | S8 | C |
| `POST /auth/resend-code` | HU-01-02 | S8 | C |
| `POST /auth/login` | HU-01-03 | S1 | A |
| `POST /auth/logout` | HU-01-04 | S1 | A |
| `POST /auth/refresh` | HU-01-05 | S1 | A |
| `POST /auth/2fa/verify` | HU-01-06 | S8 | C |
| `GET /auth/me` | HU-01-03 | S1 | A |
| `GET /oauth2/authorization/google` | HU-01-07 | S10 | C |
| `GET /oauth2/authorization/github` | HU-01-07 | S10 | C |

### Cartas (`/cards`)
| Endpoint | HU | Sprint | Equipo |
|---|---|---|---|
| `GET /cards` | HU-02-01, HU-02-02 | S2 | A |
| `GET /cards/{cardId}` | HU-02-03 | S2 | A |

### Mazos (`/decks`)
| Endpoint | HU | Sprint | Equipo |
|---|---|---|---|
| `POST /decks` | HU-03-01 | S2 | A |
| `GET /decks` | HU-03-01 | S2 | A |
| `GET /decks/{id}` | HU-03-02 | S2 | A |
| `PUT /decks/{id}` | HU-03-02 | S2 | A |
| `DELETE /decks/{id}` | HU-03-04 | S2 | A |
| `POST /decks/{id}/validate` | HU-03-03 | S2 | A |
| `PUT /decks/{id}/favorite` | HU-03-05 | S2 | A |
| `GET /decks/starters` | HU-03-06 | S2 | A |
| `POST /decks/starters/{id}/copy` | HU-03-06 | S2 | A |

### Coleccion (`/users/me/collection`)
| Endpoint | HU | Sprint | Equipo |
|---|---|---|---|
| `GET /users/me/collection` | HU-02-04 | S8 | C |
| `GET /users/me/collection/stats` | HU-02-05 | S8 | C |

### Partidas (`/games`)
| Endpoint | HU | Sprint | Equipo |
|---|---|---|---|
| `POST /games` | HU-04-01, HU-08-01, HU-05-01 | S3-S5 | A |
| `GET /games/{id}/state` | HU-04-* (todas), HU-05-05 | S3-S5 | A |
| `POST /games/{id}/action` | HU-04-* (todas) | S3-S5 | A |
| `GET /games/{id}/events` | HU-05-05 | S5 | A |
| `POST /games/{id}/chat` | HU-08-05, HU-06-05 | S6-S11 | A |
| `GET /games/{id}/chat` | HU-08-05, HU-06-05 | S6-S11 | A |

### Salas privadas (`/games/rooms`)
| Endpoint | HU | Sprint | Equipo |
|---|---|---|---|
| `POST /games/rooms/create` | HU-05-01 | S7 | C |
| `POST /games/rooms/join` | HU-05-02 | S7 | C |
| `GET /games/rooms/{code}` | HU-05-01 | S7 | C |
| `DELETE /games/rooms/{id}` | HU-05-01 | S7 | C |

### Matchmaking (`/matchmaking`)
| Endpoint | HU | Sprint | Equipo |
|---|---|---|---|
| `POST /matchmaking/queue/join` | HU-05-03 | S7 | C |
| `DELETE /matchmaking/queue/leave` | HU-05-04 | S7 | C |
| `GET /matchmaking/queue/status` | HU-05-03 | S7 | C |

### Tienda y pagos (`/payments`, `/booster-packs`, `/wallet`)
| Endpoint | HU | Sprint | Equipo |
|---|---|---|---|
| `GET /booster-packs` | HU-07-03 | S8 | C |
| `POST /users/me/booster-packs/buy/{id}` | HU-07-03 | S8 | C |
| `POST /users/me/booster-packs/{id}/open` | HU-07-04 | S8 | C |
| `GET /users/me/booster-packs/cooldown` | HU-07-05 | S8 | C |
| `POST /payments/create-preference` | HU-07-02 | S8 | C |
| `POST /webhooks/mercado-pago` (publico) | HU-07-02 | S8 | C |
| `GET /users/me/wallet` | HU-07-01 | S8 | C |
| `GET /users/me/payments` | HU-07-06 | S10 | C |

### Social (`/users`, `/friends`, `/leaderboard`, `/news`)
| Endpoint | HU | Sprint | Equipo |
|---|---|---|---|
| `GET /users/me/profile` | HU-09-01 | S10 | C |
| `GET /users/{id}/profile` | HU-09-02 | S10 | C |
| `POST /friends/request` | HU-09-03 | S9 | C |
| `PUT /friends/{id}/accept` | HU-09-03 | S9 | C |
| `PUT /friends/{id}/reject` | HU-09-03 | S9 | C |
| `DELETE /friends/{id}` | HU-09-03 | S9 | C |
| `GET /friends` | HU-09-04 | S9 | C |
| `GET /friends/pending` | HU-09-03 | S9 | C |
| `POST /friends/{id}/challenge` | HU-09-04 | S9 | C |
| `GET /leaderboard` | HU-09-05 | S9 | C |
| `GET /users/me/ranking` | HU-09-06, HU-09-07 | S9 | C |
| `GET /news` (publico) | HU-09-08 | S9 | C |
| `GET /news/{id}` (publico) | HU-09-08 | S9 | C |
| `POST /news` (admin) | HU-09-08 | S9 | C |

### Salud y metricas
| Endpoint | HU/TT | Sprint | Equipo |
|---|---|---|---|
| `GET /actuator/health` | TT-10-09 | S0 | A |
| `GET /actuator/prometheus` | TT-10-12 | S8 | C |
| `GET /swagger-ui.html` | TT-10-09 | S0 | A |

---

## STOMP — Eventos por canal

### Canales publicos (a ambos jugadores)
| Canal | Evento | HU | Sprint |
|---|---|---|---|
| `/topic/game/{gameId}` | `TURN_START` | HU-04-02, HU-05-05 | S3-S7 |
| `/topic/game/{gameId}` | `ATTACK` | HU-04-06 | S4 |
| `/topic/game/{gameId}` | `DAMAGE_DEALT` | HU-04-06 | S4 |
| `/topic/game/{gameId}` | `KO` | HU-04-08 | S4 |
| `/topic/game/{gameId}` | `PRIZE_TAKEN` | HU-04-08 | S4 |
| `/topic/game/{gameId}` | `STATUS_APPLIED` | HU-04-06 | S4 |
| `/topic/game/{gameId}` | `POKEMON_PLAYED` | HU-04-03 | S3 |
| `/topic/game/{gameId}` | `ENERGY_ATTACHED` | HU-04-04 | S3 |
| `/topic/game/{gameId}` | `RETREAT` | HU-04-07 | S4 |
| `/topic/game/{gameId}` | `MULLIGAN` | HU-04-01 | S3 |
| `/topic/game/{gameId}` | `GAME_OVER` | HU-04-09 | S5 |
| `/topic/game/{gameId}` | `SUDDEN_DEATH_START` | HU-04-09 | S5 |
| `/topic/game/{gameId}/chat` | `CHAT_MESSAGE` | HU-06-05, HU-08-05 | S6-S11 |
| `/topic/room/{code}` | `ROOM_FULL` | HU-05-02 | S7 |

### Canales privados (solo al usuario)
| Canal | Evento | HU | Sprint |
|---|---|---|---|
| `/user/queue/game/{gameId}` | `CARD_DRAWN` | HU-04-02 | S3 |
| `/user/queue/game/{gameId}` | `HAND_UPDATED` | HU-04-02..05 | S3 |
| `/user/queue/game/{gameId}` | `REPLACE_ACTIVE_AFTER_KO` | HU-04-08 | S4 |
| `/user/queue/matchmaking` | `MATCH_FOUND` | HU-05-03 | S7 |
| `/user/queue/matchmaking` | `QUEUE_TIMEOUT` | HU-05-03 | S7 |
| `/user/queue/social` | `FRIEND_REQUEST_RECEIVED` | HU-09-03 | S9 |
| `/user/queue/social` | `FRIEND_CHALLENGE` | HU-09-04 | S9 |
| `/user/queue/social` | `PRESENCE_CHANGED` | HU-09-04 | S9 |
| `/user/queue/wallet` | `WALLET_UPDATED` | HU-07-02 | S8 |

---

## Sanitizacion en `getState()`

| Campo | Visible al dueno | Visible al rival | HU/RNF |
|---|---|---|---|
| `myPlayer.hand` | si | no (`null`) | HU-04-01, RNF-Privacidad |
| `myPlayer.deck` | no (solo `deckSize`) | no (solo `deckSize`) | HU-04-01 |
| `myPlayer.prizes` | no (solo `prizesCount`) | no (solo `prizesCount`) | HU-04-01 |
| `myPlayer.discard` | si | si | publico |
| `myPlayer.active`, `bench` | si | si (sin cartas adjuntas privadas) | publico |

---

## Cambios al contrato

Cada modificacion al contrato debe:
1. Documentarse en `CONTRATOS_API.md` y/o `PROTOCOLO_WEBSOCKET.md`.
2. Reflejarse en el `EPIC.md` afectado.
3. Versionar el endpoint si rompe compatibilidad (ej. `/v2/games`).
4. Actualizar este indice.
