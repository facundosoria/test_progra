---
id: PASO_S09_01
equipo: C
bloque: 9
dep: [PASO_S03_02, PASO_S00_05]
siguiente: PASO_S09_02
context_files:
  - BD_Y_TABLAS.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/users/entity/UserLeague.java
  - api/src/main/java/com/codemon/users/service/RankingService.java
  - api/src/test/java/com/codemon/users/RankingServiceTest.java
---

# PASO 5.1 — Sistema de ranking por ligas
**Grupo legacy:** 5 — Features Finales | **Equipo:** C | **Dificultad:** 🟢 | **Tiempo:** 2–3 h

## Navegación
← **Anterior:** [PASO_S08_05](PASO_S08_05.md) — Grafana + métricas custom completados
→ **Siguiente:** [PASO_S09_02](PASO_S09_02.md) — Sistema de amigos y presencia

## Archivos a cargar junto a este
- `SCHEMA_BD.sql` → bloque V12 (tabla ranking_history, columnas nuevas en users)

## Qué construye este paso
Sistema de ligas paralelo al ELO: BRONCE/PLATA/ORO con puntos fijos por victoria en partidas ranked. Independiente del ELO (que mide habilidad relativa), esto mide progreso acumulado.

## Ligas y puntos

```
BRONCE  → 0 a 999 puntos    | +25 por victoria en QUEUE o ROOM
PLATA   → 1000 a 2499 puntos | +25 por victoria en QUEUE o ROOM
ORO     → 2500+ puntos       | +25 por victoria en QUEUE o ROOM
Derrota → sin cambio de puntos
PVE     → sin efecto en ranking de ligas
```

## Prompt listo para el agente

```
Implementá el sistema de ranking por ligas para Codemon TCG.

Schema:
[pegá bloque V12 de SCHEMA_BD.sql]

Ligas y reglas:
- BRONZE: 0–999 puntos
- SILVER: 1000–2499 puntos
- GOLD: 2500+ puntos
- Victoria en partida QUEUE o ROOM: +25 puntos
- Derrota: sin cambio
- PVE: sin efecto

Implementá:

1. UserLeague.java (enum): BRONZE, SILVER, GOLD con thresholds

2. RankingService.java (@Service):
   addWinPoints(Long userId, Long gameId):
   - Agregar 25 puntos a users.ranking_points
   - Recalcular liga: si cruza threshold, actualizar users.league
   - Insertar registro en ranking_history
   getRankingInfo(Long userId):
   - Retornar {points, league, nextLeague, pointsToNext}
   calculateLeague(int points):
   - Retornar la liga correspondiente según threshold

3. Modificar VictoryConditionChecker.declareWinner():
   Si matchType == "QUEUE" o "ROOM":
     rankingService.addWinPoints(winnerId, gameId)
   Si matchType == "PVE":
     no llamar (sin efecto)

4. UserController (agregar endpoint):
   GET /users/me/ranking → {points, league, nextLeague, pointsToNext}

TESTS:
- Victoria en QUEUE → +25 puntos
- Victoria en ROOM → +25 puntos
- Derrota → sin cambio
- Victoria en PVE → sin cambio
- 1000 puntos → liga cambia a SILVER
- 2500 puntos → liga cambia a GOLD
- getRankingInfo retorna pointsToNext correcto

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea/modifica
```
api/src/main/java/com/codemon/users/
  entity/UserLeague.java (enum, nuevo)
  service/RankingService.java (nuevo)
  controller/UserController.java (modificar, agregar GET /users/me/ranking)
api/src/main/java/com/codemon/game/victory/VictoryConditionChecker.java (modificar)
api/src/test/java/com/codemon/users/RankingServiceTest.java
```

## Errores comunes

- **Sumar puntos en PVE**: verificar `matchType.equals("QUEUE") || matchType.equals("ROOM")`
- **No actualizar la liga al cruzar threshold**: el campo `league` en `users` debe actualizarse cada vez que cambian los puntos
- **Inconsistencia entre ELO y liga**: son dos sistemas independientes; el ELO sube/baja, la liga solo sube con puntos

## Verificación

```bash
TOKEN="eyJ..."

# Después de ganar una partida QUEUE
curl http://localhost:8088/users/me/ranking \
  -H "Authorization: Bearer $TOKEN"
# PASS: {"points":25,"league":"BRONZE","nextLeague":"SILVER","pointsToNext":975}
# FAIL: points=0 → VictoryConditionChecker no llama a RankingService; verificar matchType

# Después de 40 victorias en QUEUE (1000 puntos)
# PASS: {"points":1000,"league":"SILVER","nextLeague":"GOLD","pointsToNext":1500}
# FAIL: liga no cambia → calculateLeague() no actualiza el campo league en users
```

## Dependencias
PASO_S03_02 (VictoryConditionChecker para invocar RankingService), PASO_S00_05 (V12 con tabla ranking_history).
