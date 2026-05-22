---
id: PASO_S09_02
equipo: C+B
bloque: 9
dep: [PASO_S01_01, PASO_S07_01, PASO_S00_03]
siguiente: PASO_S09_03
context_files:
  - BD_Y_TABLAS.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/friends/entity/Friendship.java
  - api/src/main/java/com/codemon/friends/repository/FriendshipRepository.java
  - api/src/main/java/com/codemon/friends/service/FriendService.java
  - api/src/main/java/com/codemon/friends/service/PresenceService.java
  - api/src/main/java/com/codemon/friends/controller/FriendController.java
  - api/src/main/java/com/codemon/friends/dto/FriendResponse.java
  - front/src/app/friends/pages/friends-page/friends-page.component.ts
  - front/src/app/friends/components/friends-list/friends-list.component.ts
  - front/src/app/friends/services/friend.service.ts
  - front/src/app/friends/services/presence.service.ts
---

# PASO 5.2 — Sistema de amigos
**Grupo legacy:** 5 — Features Finales | **Equipo:** C (backend) + B (frontend) | **Dificultad:** 🟡 | **Tiempo:** 4–5 h

## Navegación
← **Anterior:** [PASO_S09_01](PASO_S09_01.md) — Sistema de ligas completado
→ **Siguiente:** [PASO_S09_03](PASO_S09_03.md) — Sección de noticias

## Archivos a cargar junto a este
- `SCHEMA_BD.sql` → bloque V13 (tabla friendships, columna last_seen_at en users)

## Qué construye este paso
Sistema de amigos con estados de presencia en tiempo real (ONLINE/PLAYING/OFFLINE) via Redis y WebSocket. Permite retar a un amigo a una partida directamente.

## Prompt listo para el agente

```
Implementá el sistema de amigos y presencia para Codemon TCG.
Spring Boot 3.x, Redis para presencia en tiempo real.

Schema:
[pegá bloque V13 de SCHEMA_BD.sql]

Implementá:

1. Friendship.java entity + FriendshipRepository
   Status enum: PENDING, ACCEPTED, BLOCKED

2. PresenceService.java (@Service):
   Usa Redis keys construidas via `redisKeyBuilder.build("presence", userId)` que produce
   `<env>:presence:<userId>` (NUNCA hardcodear `user:presence:{userId}` — ver PATRONES_REDIS.md sec 7.2).
   Valor: "ONLINE" | "PLAYING" | "OFFLINE".
   TTL de 5 minutos (el frontend hace heartbeat cada 2 minutos)
   - setPresence(userId, status): SET <env>:presence:<userId> {status} EX 300
   - getPresence(userId): si key no existe → OFFLINE
   - setPlaying(userId, gameId): valor "PLAYING" con TTL de 3600s

3. FriendService.java (@Service):
   - sendRequest(requesterId, targetUsername):
     Validar: no existe ya una amistad, no es el mismo usuario, target existe
   - acceptRequest(receiverId, friendshipId)
   - rejectRequest(receiverId, friendshipId)
   - blockUser(userId, targetId)
   - getFriends(userId): lista de amigos ACCEPTED con presencia actual de Redis
   - getPendingRequests(userId): solicitudes PENDING recibidas
   - challengeToGame(userId, friendId, deckId):
     Crear sala privada (RoomService.createRoom)
     Emitir FRIEND_CHALLENGE a /user/{friendId}/queue/social con {from, roomCode}

4. FriendController.java:
   POST   /friends/request         → sendRequest
   PUT    /friends/{id}/accept     → acceptRequest
   PUT    /friends/{id}/reject     → rejectRequest
   DELETE /friends/{id}            → eliminar o cancelar
   GET    /friends                 → getFriends (con presencia)
   GET    /friends/pending         → getPendingRequests
   POST   /friends/{id}/challenge  → challengeToGame

5. Integrar presencia con el sistema existente:
   - WebSocket connect/authenticate → presenceService.setPresence(userId, "ONLINE")
   - WebSocket disconnect → presenceService.setPresence(userId, "OFFLINE")
   - GameEngine.startGame() → presenceService.setPlaying(userId, gameId) para ambos jugadores
   - VictoryConditionChecker.declareWinner() → presenceService.setPresence(winnerId, "ONLINE") y (loserId, "ONLINE")

6. Frontend - FriendsListComponent:
   - GET /friends cada 30 segundos para actualizar presencia
   - Íconos de estado: 🟢 ONLINE | 🎮 PLAYING | ⚫ OFFLINE
   - Botón "Retar" solo si el amigo está ONLINE
   - Notificación toast cuando llega FRIEND_CHALLENGE

TESTS:
- sendRequest → status PENDING
- acceptRequest → status ACCEPTED
- sendRequest a sí mismo → error
- sendRequest duplicado → error "Ya existe una solicitud"
- getFriends retorna presencia de Redis (mock Redis en test)
- challengeToGame crea sala y emite evento al amigo

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea
```
api/src/main/java/com/codemon/friends/
  entity/Friendship.java
  repository/FriendshipRepository.java
  service/FriendService.java
  service/PresenceService.java
  controller/FriendController.java
  dto/FriendResponse.java
front/src/app/friends/
  pages/friends-page/friends-page.component.ts + .html + .scss
  components/friends-list/friends-list.component.ts + .html + .scss
  services/friend.service.ts
  services/presence.service.ts
```

## Errores comunes

- **Presencia desactualizada**: el TTL de Redis es 5 minutos; si el frontend no hace heartbeat, el usuario pasa a OFFLINE
- **Solicitud duplicada**: verificar que no existe `friendship WHERE (requester_id=A AND receiver_id=B) OR (requester_id=B AND receiver_id=A)`
- **PLAYING sin reverter a ONLINE**: cuando la partida termina, VictoryConditionChecker debe setear ONLINE de vuelta

## Verificación

```bash
TOKEN1="eyJ..."
TOKEN2="eyJ..."

# Enviar solicitud
curl -X POST http://localhost:8088/friends/request \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"targetUsername":"misty"}'
# PASS: {"id":1,"status":"PENDING"}
# FAIL: 404 → target usuario no existe; 409 → solicitud duplicada

# Aceptar
curl -X PUT http://localhost:8088/friends/1/accept \
  -H "Authorization: Bearer $TOKEN2"
# PASS: {"id":1,"status":"ACCEPTED"}
# FAIL: 403 → solo el receptor puede aceptar, verificar lógica de receiverId

# Ver amigos con estado
curl http://localhost:8088/friends \
  -H "Authorization: Bearer $TOKEN1"
# PASS: [{"username":"misty","presenceStatus":"ONLINE","currentGameId":null}]
# FAIL: presenceStatus siempre OFFLINE → TTL de Redis expiró o heartbeat no enviado
```

## Dependencias
PASO_S01_01 (autenticación), PASO_S07_01 (RoomService para challengeToGame), PASO_S00_03 (Redis para presencia).
