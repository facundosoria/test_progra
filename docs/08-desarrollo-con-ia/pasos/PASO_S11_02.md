---
id: PASO_S11_02
equipo: A
bloque: 11
dep: [PASO_S05_03, PASO_S01_01]
siguiente: PASO_S11_03
context_files:
  - 06-system-logic.md
  - CONTRATOS_API.md
  - PROTOCOLO_WEBSOCKET.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/game/chat/entity/GameChatMessage.java
  - api/src/main/java/com/codemon/game/chat/repository/GameChatMessageRepository.java
  - api/src/main/java/com/codemon/game/chat/service/GameChatService.java
  - api/src/main/java/com/codemon/game/chat/controller/GameChatController.java
  - api/src/main/java/com/codemon/game/chat/dto/ChatMessageRequest.java
  - api/src/main/java/com/codemon/game/chat/dto/ChatMessageResponse.java
  - api/src/test/java/com/codemon/game/chat/GameChatServiceTest.java
---

# PASO 6.2 — Chat en partida (backend)

> 🧩 **EXTRA — Feature adicional al juego base**
> El juego funciona sin chat. La tabla `game_chat_messages` ya existe (migración V10 en `PASO_S00_05`), pero ningún paso anterior implementa los endpoints ni la entrega de mensajes por WebSocket. Este paso completa esa funcionalidad para que jugadores puedan comunicarse durante la partida.

**Grupo legacy:** 6 — Features Extra | **Equipo:** A | **Dificultad:** 🟡 | **Tiempo:** 3–4 h

## Navegación
← **Anterior:** [PASO_S11_01](PASO_S11_01.md) — Bot MEDIUM y HARD
→ **Siguiente:** [PASO_S11_03](PASO_S11_03.md) — Personalidades del Bot con chat

## Archivos a cargar junto a este
- `06-system-logic.md` → evento CHAT_MESSAGE (estructura y visibilidad)
- `PROTOCOLO_WEBSOCKET.md` → canales de publicación

## Qué construye este paso

Backend completo del chat en partida: persistencia de mensajes, endpoint REST para historial, y entrega en tiempo real vía WebSocket. Los mensajes son visibles para ambos jugadores. El componente `chat-window` del frontend ya existe en `PASO_S05_04` — este paso le da el backend.

## Entidad

```java
@Entity
@Table(name = "game_chat_messages")
public class GameChatMessage {
    @Id @GeneratedValue
    private UUID id;

    @Column(name = "game_id", nullable = false)
    private UUID gameId;

    @Column(name = "sender_id")          // null si es mensaje del bot
    private UUID senderId;

    @Column(name = "sender_username", nullable = false)
    private String senderUsername;

    @Column(nullable = false)
    private String message;

    @Column(name = "is_bot_message", nullable = false)
    private boolean isBotMessage;

    @Column(name = "sent_at", nullable = false)
    private Instant sentAt;
}
```

## Servicio

```java
@Service
public class GameChatService {

    // Enviar mensaje de un jugador
    public ChatMessageResponse sendMessage(UUID gameId, UUID senderId, String text) {
        // 1. Validar que la partida existe y el usuario participa en ella
        // 2. Validar longitud del mensaje (máx 200 caracteres)
        // 3. Sanitizar texto (strip HTML)
        // 4. Persistir en BD
        // 5. Publicar evento CHAT_MESSAGE vía WebSocket
        // 6. Retornar ChatMessageResponse
    }

    // Historial paginado (útil al reconectar)
    public Page<ChatMessageResponse> getHistory(UUID gameId, UUID requesterId, Pageable pageable) {
        // Validar que el requester participa en la partida
        // Retornar mensajes ordenados por sent_at ASC, máx 100 por página
    }
}
```

## Endpoint REST

```
POST /api/games/{gameId}/chat
Authorization: Bearer <token>
Body: { "message": "¡Buen movimiento!" }
Response 200: ChatMessageResponse
Response 400: mensaje vacío o > 200 chars
Response 403: usuario no participa en la partida
Response 404: partida no encontrada

GET /api/games/{gameId}/chat?page=0&size=50
Authorization: Bearer <token>
Response 200: Page<ChatMessageResponse>
```

## Evento WebSocket

Al recibir un mensaje, publicar en `/topic/game/{gameId}/chat` (canal público de la partida):

```json
{
  "type": "CHAT_MESSAGE",
  "gameId": "uuid",
  "senderId": "uuid",
  "senderUsername": "ash",
  "message": "¡Buen movimiento!",
  "isBotMessage": false,
  "sentAt": "2025-05-05T12:00:00Z"
}
```

## Integración con `PASO_S05_04` (frontend)

El componente `chat-window` del tablero debe:
1. Suscribirse a `/topic/game/{gameId}/chat` al montar
2. Al enviar → llamar `POST /api/games/{gameId}/chat`
3. Al reconectar → llamar `GET /api/games/{gameId}/chat?page=0` para recuperar historial

## Validaciones importantes

- Máximo 200 caracteres por mensaje (validar en backend y frontend)
- Un usuario solo puede chatear en partidas donde participa (verificar en BD)
- Rate limit: máximo 5 mensajes por segundo por usuario (usar Redis counter con TTL 1s)
- El mensaje del bot (`isBotMessage=true`) se envía por `GameChatService.sendBotMessage()` — ver `PASO_S11_03`

## Errores comunes

- **403 en partidas terminadas:** Decidir si el chat sigue habilitado post-partida (recomendado: sí, hasta 5 min después).
- **Flood de mensajes:** Sin rate limit, un usuario puede saturar el canal. Redis `INCR` + `EXPIRE` es suficiente.
- **Historial incompleto al reconectar:** Siempre cargar historial vía REST antes de activar la suscripción WebSocket.

## Verificación

```bash
./mvnw test -Dtest=GameChatServiceTest

# Verificar que el endpoint protege contra participantes externos
curl -X POST http://localhost:8088/api/games/{gameId}/chat \
  -H "Authorization: Bearer {tokenDeOtroUsuario}" \
  -d '{"message":"intruso"}' 
# Debe retornar 403
```
