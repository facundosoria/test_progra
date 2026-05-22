---
id: PASO_S07_02
equipo: C
bloque: 7
dep: [PASO_S05_03]
siguiente: PASO_S07_SMOKE
context_files:
  - BD_Y_TABLAS.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/lobby/entity/QueueEntry.java
  - api/src/main/java/com/codemon/lobby/entity/SkillRating.java
  - api/src/main/java/com/codemon/lobby/repository/QueueEntryRepository.java
  - api/src/main/java/com/codemon/lobby/repository/SkillRatingRepository.java
  - api/src/main/java/com/codemon/lobby/service/MatchmakingService.java
  - api/src/main/java/com/codemon/lobby/controller/MatchmakingController.java
  - api/src/test/java/com/codemon/lobby/MatchmakingServiceTest.java
---

# PASO 3.2 — Matchmaking cola ranked
**Grupo legacy:** 3 — Matchmaking + Frontend | **Equipo:** C | **Dificultad:** 🔴 | **Tiempo:** 5–7 h

## Navegación
← **Anterior:** [PASO_S05_03](PASO_S05_03.md) — GameEngine completo + WebSocket (GATE 2 desbloqueado)
→ **Siguiente:** [PASO_S08_01](PASO_S08_01.md) — Sobres y colección (Equipo C continúa en features)

> ⚠️ **Aclaración de dependencia:** Este paso puede ejecutarse en **paralelo** con [PASO_S07_01](PASO_S07_01.md) (Salas privadas). Ambos dependen solo de `PASO_S05_03` y son features independientes — no se necesitan mutuamente para ser implementados. La dependencia en `PASO_S07_01` fue eliminada para permitir que el Equipo C trabaje en ambos simultáneamente.

## Archivos a cargar junto a este
- `SCHEMA_BD.sql` → bloque V7 (tablas queue_entries, skill_ratings)

## Qué construye este paso
Cola de matchmaking con skill rating. Empareja automáticamente a jugadores cercanos en rating, con ventana de búsqueda que se expande con el tiempo. Usa Redis sorted set y lock para evitar race conditions.

## Algoritmo de matchmaking

```
Cola Redis: sorted set redisKeyBuilder.build("matchmaking", "queue")
            (produce <env>:matchmaking:queue — ver PATRONES_REDIS.md sec 7.2)
            score = skill_rating

Cron job cada 3 segundos:
  Adquirir lock distribuido via RedisLockRegistry:
    Lock lock = redisLockRegistry.obtain("lock:matchmaking:tick");
    if (!lock.tryLock(0, 5, SECONDS)) return;
    (clave real: <env>:lock:matchmaking:tick — ver PATRONES_REDIS.md sec 7.4)
  Si no obtuvo lock → saltar (otra instancia ya está procesando)

  Para cada usuario en la cola:
    secondsWaiting = now - entryTime
    window = min(100 + (secondsWaiting / 5) * 50, 300)
    buscar en sorted set: ZRANGEBYSCORE [rating-window, rating+window]
    Si encontró un par (que no sea el mismo usuario):
      createGame(user1, user2, matchType:"QUEUE")
      ZREM <queue> user1 user2
      Emitir MATCH_FOUND a /user/{userId}/queue/matchmaking
    Si secondsWaiting >= 30:
      ZREM <queue> userId
      Emitir QUEUE_TIMEOUT a /user/{userId}/queue/matchmaking
```

## Prompt listo para el agente

```
Implementá el sistema de matchmaking con cola ranked para Codemon TCG.
Java 21, Spring Boot, Redis (sorted set), cron job.

Schema:
[pegá bloque V7 de SCHEMA_BD.sql]

Requerimientos:
- Sorted set en Redis con key construida via `redisKeyBuilder.build("matchmaking", "queue")` (resuelve a `<env>:matchmaking:queue`, prefijo de entorno automatico — ver PATRONES_REDIS.md sec 7.2). NUNCA hardcodear "matchmaking:queue".
- Algoritmo de ventana: initial ±100, expande ±50 cada 5 segundos sin match, máximo ±300
- Timeout: 30 segundos sin match → cancelar, emitir QUEUE_TIMEOUT
- Cron job @Scheduled(fixedRate=3000): busca pares en la cola
- Lock distribuido via `RedisLockRegistry` de `spring-integration-redis` (NO `SETNX` raw): clave logica `lock:matchmaking:tick`, TTL 5s. Implementacion: `redisLockRegistry.obtain("lock:matchmaking:tick").tryLock(0, 5, SECONDS)` — ver PATRONES_REDIS.md sec 7.4.

ENTITIES: QueueEntry.java, SkillRating.java
REPOSITORIES: QueueEntryRepository.java, SkillRatingRepository.java

MatchmakingService.java:
- joinQueue(Long userId, Long deckId) → QueueEntry
  Validar que no esté ya en cola
  ZADD redisKeyBuilder.build("matchmaking","queue") {skillRating} {userId}
- leaveQueue(Long userId)
  ZREM redisKeyBuilder.build("matchmaking","queue") {userId}
- findMatches() → @Scheduled(fixedRate=3000)
  Adquirir lock distribuido: redisLockRegistry.obtain("lock:matchmaking:tick").tryLock(0,5,SECONDS)
  Para cada usuario en cola: buscar par dentro de la ventana
  Si encontrado: crearGame, remover ambos del sorted set
  Si timeout: cancelar, emitir QUEUE_TIMEOUT
  finally { lock.unlock(); }
- calculateWindow(int secondsWaiting): 100 + (secondsWaiting/5)*50, max 300

Notificaciones WebSocket:
- MATCH_FOUND: /user/{userId}/queue/matchmaking con {gameId, opponentUsername}
- QUEUE_TIMEOUT: /user/{userId}/queue/matchmaking

MatchmakingController.java:
- POST   /games/queue/join    → joinQueue
- DELETE /games/queue         → leaveQueue
- GET    /games/queue/status  → estado actual del usuario en cola

TESTS:
- Dos usuarios con skill rating similar → match en ~3 segundos (integración)
- Usuario solo en cola → timeout a los 30 segundos
- Race condition: lock evita que dos jobs creen dos games del mismo par
- joinQueue con usuario ya en cola → error apropiado

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea
```
api/src/main/java/com/codemon/lobby/
  entity/QueueEntry.java
  entity/SkillRating.java
  repository/QueueEntryRepository.java
  repository/SkillRatingRepository.java
  service/MatchmakingService.java
  controller/MatchmakingController.java
api/src/test/java/com/codemon/lobby/MatchmakingServiceTest.java
```

## Errores comunes

- **Race condition en cron job**: dos instancias pueden crear dos games del mismo par → usar `RedisLockRegistry` (NO `SETNX` raw); el bean libera el lock automaticamente si la JVM cae.
- **Clave Redis sin prefijo de entorno**: si ves `matchmaking:queue` en lugar de `<env>:matchmaking:queue`, es un bug — siempre usar `RedisKeyBuilder`.
- **ELO fórmula incorrecta**: `new = old + 32 * (result - 1/(1 + 10^((opp-self)/400)))` donde result=1 si ganó, 0 si perdió
- **Usuario en cola sin skill rating**: crear un rating inicial de 1000 si no existe

## Verificación

```bash
TOKEN1="eyJ..."
TOKEN2="eyJ..."

# Usuario 1 se une a la cola
curl -X POST http://localhost:8088/games/queue/join \
  -H "Authorization: Bearer $TOKEN1" -d '{"deckId":1}'
# PASS: {"position":1,"estimatedWait":"..."}
# FAIL: 409 → usuario ya en cola; 400 → deck inválido

# Usuario 2 se une (en cliente separado para ver WebSocket)
curl -X POST http://localhost:8088/games/queue/join \
  -H "Authorization: Bearer $TOKEN2" -d '{"deckId":2}'

# Ambos reciben via WebSocket en ~3 segundos:
# PASS: {"type":"MATCH_FOUND","gameId":6,"opponentUsername":"misty"}
# FAIL: no llega el evento → verificar @Scheduled(fixedRate=3000) y lock Redis
```

## Dependencias
PASO_S05_03 (GameEngine para crear la partida), PASO_S07_01 (RoomService como referencia de creación de partidas).

---

## Entrega al siguiente paso

Tras completar este PASO, los siguientes (PASO_S06_01, PASO_S09_01) pueden asumir:

- **Endpoints REST disponibles**:
  - `POST /api/matchmaking/queue` (entrar a la cola con `deckId`)
  - `DELETE /api/matchmaking/queue` (salir de la cola)
  - `GET /api/matchmaking/status` (estado actual: `queued`, `matched`, `gameId` si aplica)
- **Bean Spring autowireable**: `MatchmakingService` con `enqueue`, `dequeue`, `findMatch`
- **Redis sorted set `<env>:matchmaking:queue`** con `score = ELO`, `member = userId`. Clave construida via `RedisKeyBuilder.build("matchmaking","queue")` (ver [PATRONES_REDIS.md](../../05-referencia-tecnica/PATRONES_REDIS.md) sec 7.2).
- **Lock distribuido**: `RedisLockRegistry` con clave `lock:matchmaking:tick` (PATRONES_REDIS.md sec 7.4) protege el `@Scheduled`.
- **Job programado** (`@Scheduled(fixedRate=3000)`) que matchea jugadores con ELO compatible (±200) y crea partida via `GameEngine`
- **Evento WebSocket `MATCH_FOUND`** notifica a ambos jugadores con `gameId` y datos del oponente (formato canónico de [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md) sección 4)
- Para PASO_S09_01 (ligas): el ELO del jugador se actualiza tras cada partida ranked

---

## Definition of Done

- [ ] Todos los archivos de `outputs:` existen
- [ ] `./verify_paso.sh PASO_S07_02` retorna exit 0
- [ ] Dos usuarios en cola con ELO compatible son matcheados en ≤6 segundos
- [ ] Cancelar cola (`DELETE /api/matchmaking/queue`) elimina entrada del sorted set Redis
- [ ] Matchmaking respeta lock distribuido (no crea partida duplicada con dos pods)
- [ ] Tests pasan con cobertura ≥ 80% en `com.codemon.matchmaking`
- [ ] Sin TODOs ni FIXMEs
- [ ] Naming respeta [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md)
- [ ] Patrones Redis siguen [PATRONES_REDIS.md](../../05-referencia-tecnica/PATRONES_REDIS.md)
