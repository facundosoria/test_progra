---
id: PASO_S11_03
equipo: A
bloque: 11
dep: [PASO_S11_02, PASO_S05_02]
siguiente: PASO_S11_04
context_files:
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/game/bot/personality/BotPersonality.java
  - api/src/main/java/com/codemon/game/bot/personality/BotPersonalityConfig.java
  - api/src/main/java/com/codemon/game/bot/personality/BotChatService.java
  - api/src/test/java/com/codemon/game/bot/BotChatServiceTest.java
---

# PASO 6.3 — Personalidades del Bot con chat

> 🧩 **EXTRA — Feature adicional al juego base**
> El bot ya funciona (PASO_S05_02). Este paso agrega personalidad y mensajes de chat durante la partida. Es una feature de ambientación — no afecta la lógica del juego pero enriquece la experiencia. Requiere que `PASO_S11_02` (chat backend) esté completo.

**Grupo legacy:** 6 — Features Extra | **Equipo:** A | **Dificultad:** 🟢 | **Tiempo:** 2–3 h

## Navegación
← **Anterior:** [PASO_S11_02](PASO_S11_02.md) — Chat en partida backend
→ **Siguiente:** [PASO_S11_04](PASO_S11_04.md) — Wallet balance endpoint

## Qué construye este paso

Tres personalidades de bot con frases contextuales visibles en inglés. En momentos clave de la partida (inicio, KO propio, KO rival, victoria, derrota), el bot envía un mensaje de chat via `GameChatService.sendBotMessage()`.

## Las tres personalidades

### Hernán — El confiado
Arranca creyendo que ganó, se desmorona si pierde.

### Santoro — El estratega pretencioso
Habla como si supiera lo que hace. Se contradice.

### Ramiro — El despistado caótico
No entiende bien qué está pasando pero igual participa.

## Implementación

### Enum de personalidades

```java
public enum BotPersonality {
    HERNAN, SANTORO, RAMIRO;

    public static BotPersonality random() {
        return values()[new Random().nextInt(values().length)];
    }
}
```

### Configuración de frases

```java
@Component
public class BotPersonalityConfig {

    // Mapa: personalidad → evento → lista de frases posibles
    private static final Map<BotPersonality, Map<ChatEvent, List<String>>> PHRASES = Map.of(

        BotPersonality.HERNAN, Map.of(
            ChatEvent.GAME_START,    List.of("Ya ganamos, es solo formalidad.", "Esto está ganado.", "¿Vos sabés jugar?"),
            ChatEvent.BOT_KO_RIVAL,  List.of("Como esperaba.", "Demasiado fácil.", "¿Eso era todo?"),
            ChatEvent.BOT_LOSES_KO,  List.of("No importa, igual gano.", "Eso estuvo raro.", "Error mío, nada más."),
            ChatEvent.BOT_WINS,      List.of("Como siempre.", "No era difícil.", "Próxima vez traé un mazo mejor."),
            ChatEvent.BOT_LOSES,     List.of("El mazo estaba arreglado.", "No contaba con eso.", "Circunstancias.")
        ),

        BotPersonality.SANTORO, Map.of(
            ChatEvent.GAME_START,    List.of("Analicé tu mazo. Ya sé cómo termina esto.", "Interesante elección de mazo.", "Vamos a ver qué tan bueno sos."),
            ChatEvent.BOT_KO_RIVAL,  List.of("Exactamente como lo planeé.", "El daño era calculado.", "Eficiencia táctica."),
            ChatEvent.BOT_LOSES_KO,  List.of("Era parte del plan.", "Permití ese KO estratégicamente.", "Sacrificio necesario."),
            ChatEvent.BOT_WINS,      List.of("Victoria táctica. Como siempre.", "El análisis previo fue clave.", "Estudié bien tu mazo."),
            ChatEvent.BOT_LOSES,     List.of("Variables no contempladas.", "Deberé revisar mi estrategia.", "Interesante. No esperaba eso.")
        ),

        BotPersonality.RAMIRO, Map.of(
            ChatEvent.GAME_START,    List.of("¿Esto cómo se juega?", "Esperen, ¿tengo que hacer algo?", "Dale, empecemos."),
            ChatEvent.BOT_KO_RIVAL,  List.of("¡Uh! ¿Eso era bueno?", "¿Lo hice bien?", "Creo que hice algo bien."),
            ChatEvent.BOT_LOSES_KO,  List.of("¿Qué pasó?", "Ah... eso dolió.", "No entendí bien qué hice."),
            ChatEvent.BOT_WINS,      List.of("¡Gané! ¿Gané?", "Eso estuvo bien supongo.", "Bueno, chau."),
            ChatEvent.BOT_LOSES,     List.of("¿Perdí?", "Ah, bueno.", "La próxima aprendo a jugar.")
        )
    );

    public String getPhrase(BotPersonality personality, ChatEvent event) {
        List<String> options = PHRASES.get(personality).get(event);
        return options.get(new Random().nextInt(options.size()));
    }
}
```

### Servicio de chat del bot

```java
@Service
public class BotChatService {

    private final GameChatService chatService;
    private final BotPersonalityConfig personalityConfig;

    // Llamado desde BotTurnService cuando ocurre un evento relevante
    public void onGameEvent(GameContext ctx, ChatEvent event) {
        if (ctx.getBotPersonality() == null) return;

        String phrase = personalityConfig.getPhrase(ctx.getBotPersonality(), event);

        // Delay aleatorio para que parezca natural (1-3s)
        CompletableFuture.delayedExecutor(
            1000 + new Random().nextInt(2000), TimeUnit.MILLISECONDS
        ).execute(() ->
            chatService.sendBotMessage(ctx.getGameId(), ctx.getBotUsername(), phrase)
        );
    }
}
```

### Enum de eventos de chat

```java
public enum ChatEvent {
    GAME_START,
    BOT_KO_RIVAL,    // el bot hace KO al Pokémon del rival
    BOT_LOSES_KO,    // el rival hace KO al Pokémon del bot
    BOT_WINS,
    BOT_LOSES
}
```

## Integración con GameContext

Agregar campos a `GameContext`:

```java
private BotPersonality botPersonality;   // asignada en startGame()
private String botUsername;              // "Hernán", "Santoro" o "Ramiro"
```

En `GameEngine.startGame()` (PVE):
```java
BotPersonality personality = BotPersonality.random();
ctx.setBotPersonality(personality);
ctx.setBotUsername(personality.name().charAt(0) + 
    personality.name().substring(1).toLowerCase());
```

## Integración en AttackPipeline (CheckKnockoutHandler)

En `CheckKnockoutHandler.proceed()`, cuando se detecta KO:

```java
// Si el KO fue causado por el bot
if (ctx.getBotPlayerId().equals(request.getAttackerId())) {
    botChatService.onGameEvent(ctx, ChatEvent.BOT_KO_RIVAL);
}
// Si el KO fue sufrido por el bot
if (ctx.getBotPlayerId().equals(request.getDefenderId())) {
    botChatService.onGameEvent(ctx, ChatEvent.BOT_LOSES_KO);
}
```

## Verificación

```bash
./mvnw test -Dtest=BotChatServiceTest

# Test: en una partida PVE, el bot debe enviar al menos 1 mensaje
# Test: los mensajes corresponden a la personalidad asignada
# Test: el delay entre evento y mensaje es >= 1s
```
