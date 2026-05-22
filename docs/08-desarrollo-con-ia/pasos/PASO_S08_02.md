---
id: PASO_S08_02
equipo: C
bloque: 8
dep: [PASO_S03_02, PASO_S00_05]
siguiente: PASO_S08_03
context_files:
  - BD_Y_TABLAS.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/users/service/LeaderboardService.java
  - api/src/main/java/com/codemon/users/controller/LeaderboardController.java
  - api/src/main/java/com/codemon/users/dto/UserStatsResponse.java
  - api/src/main/java/com/codemon/users/dto/RecentGameResponse.java
  - api/src/main/java/com/codemon/users/dto/LeaderboardEntryResponse.java
  - api/src/test/java/com/codemon/users/LeaderboardServiceTest.java
---

# PASO 4.2 — Leaderboard
**Grupo legacy:** 4 — Features Adicionales | **Equipo:** C | **Dificultad:** 🟢 | **Tiempo:** 2–3 h

## Navegación
← **Anterior:** [PASO_S08_01](PASO_S08_01.md) — Sobres y colección (puede ejecutarse en paralelo con este paso)
→ **Siguiente:** [PASO_S08_04](PASO_S08_04.md) — Mercado Pago (requiere 4.2 y 4.3 completos)

## Archivos a cargar junto a este
- `SCHEMA_BD.sql` → bloque V11 (vista materializada leaderboard)

## Qué construye este paso
El leaderboard usando la vista materializada de PostgreSQL. También expone estadísticas por usuario y el historial de partidas recientes.

## Prompt listo para el agente

```
Implementá el leaderboard para Codemon TCG.
Spring Boot 3.3.x, Java 21, PostgreSQL con vista materializada.

Schema de la vista materializada y tablas relacionadas:
[pegá bloque V11 de SCHEMA_BD.sql]

Implementá:

1. LeaderboardService:
   getLeaderboard(filter, page):
   - filter = "pvp" → solo partidas donde matchType == "QUEUE"
   - filter = "all" → todas las partidas
   - Paginado: page, size (default 50 por página)
   - Ordenado por skillRating DESC
   - Leer de la vista materializada "leaderboard"

   getUserStats(Long userId):
   - wins, losses, draws, winRate (calculado), skillRating, rankingPoints, league
   - Cargar de la vista + tabla users

   getRecentGames(Long userId):
   - Últimas 10 partidas del usuario
   - Incluir: opponentUsername, result (WIN/LOSS/DRAW), date, matchType

2. LeaderboardController:
   GET /leaderboard?filter=pvp&page=0&size=50
   GET /users/{id}/stats
   GET /users/{id}/recent-games

3. El REFRESH ya está en VictoryConditionChecker.declareWinner():
   "REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard"
   (No reimplementar, solo verificar que existe)

TESTS:
- getLeaderboard ordenado por skillRating DESC
- filter=pvp excluye partidas PVE (matchType != "QUEUE")
- getUserStats retorna winRate correcto: wins/(wins+losses)
- getRecentGames retorna máximo 10 partidas

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea
```
api/src/main/java/com/codemon/users/
  service/LeaderboardService.java
  controller/LeaderboardController.java
  dto/UserStatsResponse.java
  dto/RecentGameResponse.java
  dto/LeaderboardEntryResponse.java
api/src/test/java/com/codemon/users/LeaderboardServiceTest.java
```

## Errores comunes

- **Vista materializada no existe**: se crea en `V11__views.sql`; verificar que Flyway la ejecutó
- **CONCURRENT refresh sin índice único**: la vista materializada necesita un índice único para usar `CONCURRENTLY`; verificar que existe en `V11`
- **winRate con división por cero**: usar `CASE WHEN (wins+losses) == 0 THEN 0.0 ELSE wins/(wins+losses) END`

## Verificación

```bash
TOKEN="eyJ..."

curl "http://localhost:8088/leaderboard?filter=pvp" \
  -H "Authorization: Bearer $TOKEN"
# PASS: [{"rank":1,"username":"ash","skillRating":1050,"wins":3,"losses":1,"winRate":0.75}]
# FAIL: lista vacía → vista materializada no tiene datos o no se ejecutó REFRESH

curl "http://localhost:8088/users/1/stats" \
  -H "Authorization: Bearer $TOKEN"
# PASS: {"wins":3,"losses":1,"winRate":0.75,"skillRating":1050}
# FAIL: winRate=null o NaN → revisar división por cero en LeaderboardService

curl "http://localhost:8088/users/1/recent-games" \
  -H "Authorization: Bearer $TOKEN"
# PASS: lista de hasta 10 partidas con resultado y fecha
# FAIL: lista vacía con partidas jugadas → verificar query en GameRepository
```

## Dependencias
PASO_S03_02 (VictoryConditionChecker que actualiza el leaderboard), PASO_S00_05 (V11 con la vista materializada).
