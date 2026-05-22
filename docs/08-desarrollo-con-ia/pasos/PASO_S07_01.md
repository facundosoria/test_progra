---
id: PASO_S07_01
equipo: C
bloque: 7
dep: [PASO_S05_03]
siguiente: PASO_S07_02
context_files:
  - BD_Y_TABLAS.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/lobby/entity/GameRoom.java
  - api/src/main/java/com/codemon/lobby/entity/GameRoomPlayer.java
  - api/src/main/java/com/codemon/lobby/repository/GameRoomRepository.java
  - api/src/main/java/com/codemon/lobby/repository/GameRoomPlayerRepository.java
  - api/src/main/java/com/codemon/lobby/service/RoomService.java
  - api/src/main/java/com/codemon/lobby/controller/RoomController.java
  - api/src/main/java/com/codemon/lobby/dto/RoomResponse.java
  - api/src/test/java/com/codemon/lobby/RoomServiceTest.java
---

# PASO 3.1 — Salas privadas
**Grupo legacy:** 3 — Matchmaking + Frontend | **Equipo:** C | **Dificultad:** 🟡 | **Tiempo:** 3–4 h

## Navegación
← **Anterior:** [PASO_S05_03](PASO_S05_03.md) — GameEngine con WebSocket STOMP (GATE 2 completado)
→ **Siguiente:** [PASO_S07_02](PASO_S07_02.md) — Matchmaking cola ranked

## Archivos a cargar junto a este
- `SCHEMA_BD.sql` → bloque V8 (tablas game_rooms, game_room_players)

## Qué construye este paso
El sistema de salas privadas donde dos jugadores pueden enfrentarse usando un código de 6 caracteres. Incluye expiración automática de salas inactivas.

## Prompt listo para el agente

```
Implementá el sistema de salas privadas para el juego Codemon TCG.
Spring Boot 3.3.x, Java 21.

Schema de BD:
[pegá bloque V8 de SCHEMA_BD.sql]

Requerimientos:
- Código de sala: 6 caracteres alfanuméricos (A-Z, 0-9), único en BD
- La sala expira en 10 minutos si no se une el 2do jugador
- Cuando 2 jugadores están en la sala → crear Game automáticamente
- Cron job @Scheduled(fixedRate=60000) que limpia salas con expires_at < NOW()

ENTITIES: GameRoom.java, GameRoomPlayer.java
REPOSITORIES: GameRoomRepository.java, GameRoomPlayerRepository.java

RoomService.java:
- createRoom(Long userId, Long deckId) → RoomResponse (roomCode, expiresAt)
  Generar código único: verificar en BD, regenerar si hay colisión (máx 5 intentos)
- joinRoom(Long userId, Long deckId, String roomCode) → RoomResponse
  Si 2 jugadores: llamar gameEngine.startGame(matchType: "ROOM")
- getRoomByCode(String code) → RoomResponse
- cancelRoom(Long roomId, Long userId) → void (solo el creador puede cancelar)
- cleanupExpiredRooms() → @Scheduled, marcar expiradas

RoomController.java:
- POST /games/rooms/create
- POST /games/rooms/join
- GET  /games/rooms/{code}
- DELETE /games/rooms/{id}

WebSocket: emitir a /topic/room/{code} cuando el 2do jugador se une
(el evento indica que la partida está lista y comparte el gameId)

TESTS:
- Crear sala → código de 6 chars, alfanumérico
- Unirse con código válido → OK, 2 jugadores → gameId en la respuesta
- Unirse con código expirado → error apropiado
- Unirse con código inexistente → 404
- Creador cancela sala → OK
- No creador cancela sala → 403

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea
```
api/src/main/java/com/codemon/lobby/
  entity/GameRoom.java
  entity/GameRoomPlayer.java
  repository/GameRoomRepository.java
  repository/GameRoomPlayerRepository.java
  service/RoomService.java
  controller/RoomController.java
  dto/RoomResponse.java
api/src/test/java/com/codemon/lobby/RoomServiceTest.java
```

## Errores comunes

- **Colisión de código de sala**: verificar que el código no existe antes de guardar; regenerar hasta 5 veces
- **Sala no expira**: el `@Scheduled` solo corre si está habilitado con `@EnableScheduling` en la clase de configuración
- **Dos jugadores se unen simultáneamente**: usar `@Transactional` con lock a nivel de BD para evitar que se creen dos Games

## Verificación

```bash
TOKEN1="eyJ..."
TOKEN2="eyJ..."

# Crear sala
ROOM=$(curl -s -X POST http://localhost:8088/games/rooms/create \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json" \
  -d '{"deckId":1}')
echo $ROOM
# PASS: {"roomCode":"AB7K2X","expiresAt":"..."} — código de exactamente 6 chars alfanuméricos
# FAIL: error o código con formato incorrecto
CODE=$(echo $ROOM | python3 -c "import sys,json; print(json.load(sys.stdin)['roomCode'])")

# Unirse a la sala
curl -X POST http://localhost:8088/games/rooms/join \
  -H "Authorization: Bearer $TOKEN2" \
  -H "Content-Type: application/json" \
  -d "{\"roomCode\":\"$CODE\",\"deckId\":2}"
# PASS: {"gameId":5,"status":"ACTIVE"}
# FAIL: 404 (sala no existe) o 410 (sala expirada) → verificar lógica de joinRoom
```

## Dependencias
PASO_S05_03 (GameEngine para crear la partida cuando 2 jugadores están listos).
