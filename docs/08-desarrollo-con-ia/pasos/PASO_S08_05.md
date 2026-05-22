---
id: PASO_S08_05
equipo: C
bloque: 8
dep: [PASO_S00_03, PASO_S01_01, PASO_S05_03, PASO_S07_02, PASO_S08_04]
siguiente: PASO_S08_06
context_files:
  - MONITOREO.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/shared/metrics/CodemonMetrics.java
---

# PASO 4.5 — Grafana + métricas custom
**Grupo legacy:** 4 — Features Adicionales | **Equipo:** C | **Dificultad:** 🟡 | **Tiempo:** 3–4 h

## Navegación
← **Anterior:** [PASO_S08_04](PASO_S08_04.md) — Mercado Pago integrado
→ **Siguiente:** [PASO_S09_01](PASO_S09_01.md) — Sistema de ranking por ligas

## Archivos a cargar junto a este
- `MONITOREO.md` — completo (setup de Grafana, métricas a implementar, queries PromQL)

## Qué construye este paso
Métricas de negocio custom con Micrometer expuestas en `/actuator/prometheus` y accesibles desde Grafana. Incluye counters (partidas, pagos, usuarios), gauges (usuarios online, partidas activas) y timers (duración de partidas).

## Prompt listo para el agente

```
Implementá las métricas custom de Codemon TCG para Grafana.
Spring Boot 3.x, Micrometer, Prometheus registry.

Guía completa de métricas y dashboards:
[pegá MONITOREO.md completo]

Implementá:

1. CodemonMetrics.java (@Component):
   Counters (MeterRegistry.counter()):
   - codemon_users_registered_total
   - codemon_coins_purchased_total (con tag "currency")
   - codemon_revenue_ars_total
   - codemon_boosters_bought_total
   - codemon_boosters_opened_total
   - codemon_games_started_total (con tag "match_type": pvp/pve/room)
   - codemon_games_finished_total
   - codemon_games_cancelled_total
   - codemon_matches_found_total
   - codemon_queue_timeouts_total
   - codemon_chat_messages_total

   Gauges (MeterRegistry.gauge() con AtomicInteger):
   - codemon_users_online (AtomicInteger)
   - codemon_games_active (AtomicInteger)
   - codemon_queue_size (AtomicInteger)

   Timers (MeterRegistry.timer()):
   - codemon_game_duration_seconds
   - codemon_matchmaking_wait_seconds

2. Agregar llamadas a CodemonMetrics desde los servicios existentes:
   - AuthService.register() → metrics.incrementUsersRegistered()
   - GameEngine.startGame() → metrics.incrementGamesStarted(matchType), metrics.incrementGamesActive()
   - VictoryConditionChecker.declareWinner() → metrics.incrementGamesFinished(), metrics.decrementGamesActive()
   - MatchmakingService.findMatches() → metrics.incrementMatchesFound()
   - MatchmakingService (timeout) → metrics.incrementQueueTimeouts()
   - PaymentService.processWebhook() → metrics.incrementCoinsPurchased(), metrics.incrementRevenueArs()
   - WebSocket connect → metrics.incrementUsersOnline()
   - WebSocket disconnect → metrics.decrementUsersOnline()

3. Verificar que application.yml tiene:
   management:
     endpoints:
       web:
         exposure:
           include: health,info,prometheus,metrics
     metrics:
       export:
         prometheus:
           enabled: true

TESTS:
No requiere tests unitarios específicos — verificar via el endpoint de Prometheus.

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea/modifica
```
api/src/main/java/com/codemon/shared/metrics/CodemonMetrics.java (nuevo)
api/src/main/java/com/codemon/auth/service/AuthService.java (modificar)
api/src/main/java/com/codemon/game/engine/GameEngine.java (modificar)
api/src/main/java/com/codemon/game/victory/VictoryConditionChecker.java (modificar)
api/src/main/java/com/codemon/lobby/service/MatchmakingService.java (modificar)
api/src/main/java/com/codemon/payment/service/PaymentService.java (modificar)
```

## Errores comunes

- **Gauge con valor que se pierde**: los gauges deben referenciar `AtomicInteger` o un proveedor, no un valor directo
- **Prefix incorrecto**: asegurarse de que todas las métricas usan el prefijo `codemon_` para filtrarlas en Grafana
- **Counter nunca decrece**: los counters solo suben; para valores que suben y bajan usar Gauge (como usuarios online)

## Verificación

```bash
# Verificar que las métricas custom se exponen
curl http://localhost:8088/actuator/prometheus | grep codemon_
# PASS: aparecen líneas como:
#   codemon_users_registered_total 0.0
#   codemon_games_active 0.0
#   codemon_games_started_total{match_type="pvp"} 0.0
# FAIL: sin output → endpoint prometheus no expuesto, revisar management.endpoints en application.yml

# Grafana en http://localhost:3000 (user: admin, pass: codemon123)
# Crear dashboard con query PromQL:
# rate(codemon_games_started_total[5m])  → partidas por segundo
# codemon_users_online                   → gauge de usuarios online
```

## Dependencias
PASO_S00_03 (Prometheus y Grafana corriendo en Docker), PASO_S01_01, PASO_S05_03, PASO_S07_02, PASO_S08_04 (servicios que reportan métricas).
