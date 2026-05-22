# MONITOREO.md - Guía de Monitoreo con Grafana + Prometheus

## Stack de monitoreo

```
Spring Boot API
  └─ Micrometer (métricas automáticas + custom)
       └─ /actuator/prometheus (endpoint)
              └─ Prometheus (scrapea cada 15s)
                     └─ Grafana (dashboards)

PostgreSQL ──── postgres_exporter ──── Prometheus
Redis      ──── redis_exporter   ──── Prometheus
```

**URLs:**
- Grafana:    http://localhost:3000  (admin / codemon123)
- Prometheus: http://localhost:9090

---

## PASO 1 — Agregar dependencias al pom.xml

Dentro de `<dependencies>` en `api/pom.xml`, agregar:

```xml
<!-- Micrometer + Prometheus -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>

<!-- Actuator (expone /actuator/prometheus) -->
<!-- Ya debería estar, verificar: -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

---

## PASO 2 — Configurar Actuator en application.yml

Agregar en `api/src/main/resources/application.yml`:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health, info, prometheus, metrics
  endpoint:
    health:
      show-details: always
    prometheus:
      enabled: true
  metrics:
    tags:
      application: codemon-api
    export:
      prometheus:
        enabled: true
  prometheus:
    metrics:
      export:
        enabled: true
```

**Verificación:**
```bash
# Con la API corriendo:
curl http://localhost:8088/actuator/prometheus | head -30
# Debe mostrar métricas en formato Prometheus
```

---

## PASO 3 — Crear estructura de carpetas de monitoreo

```bash
mkdir -p infra/monitoring/grafana/provisioning/datasources
mkdir -p infra/monitoring/grafana/provisioning/dashboards

# Copiar archivos de configuración
cp prometheus.yml infra/monitoring/prometheus.yml
cp grafana-datasource.yml infra/monitoring/grafana/provisioning/datasources/datasource.yml
```

Crear `infra/monitoring/grafana/provisioning/dashboards/dashboard.yml`:

```yaml
apiVersion: 1

providers:
  - name: 'Codemon Dashboards'
    orgId: 1
    folder: 'Codemon'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    options:
      path: /etc/grafana/provisioning/dashboards
```

---

## PASO 4 — Crear métricas custom en Spring Boot

Crear `api/src/main/java/com/codemon/shared/metrics/CodemonMetrics.java`:

```java
@Component
public class CodemonMetrics {

    // ─────────────────────────────────────────
    // USUARIOS
    // ─────────────────────────────────────────

    // Cuántos usuarios se registraron (total acumulado)
    private final Counter usersRegistered;

    // Cuántos usuarios están conectados AHORA vía WebSocket
    private final AtomicInteger usersOnline;

    // ─────────────────────────────────────────
    // ECONOMÍA
    // ─────────────────────────────────────────

    // Total de Codemones (coins) vendidos en total
    private final Counter coinsPurchased;

    // Total de pesos reales recibidos
    private final Counter revenueArs;

    // Total de sobres comprados
    private final Counter boosterPacksBought;

    // Total de sobres abiertos
    private final Counter boosterPacksOpened;

    // ─────────────────────────────────────────
    // PARTIDAS
    // ─────────────────────────────────────────

    // Partidas iniciadas (con tag de tipo: QUEUE, ROOM, PVE)
    private final Counter gamesStarted;

    // Partidas terminadas con resultado (tag: WIN, DRAW, ABANDONED)
    private final Counter gamesFinished;

    // Partidas canceladas (usuario salió antes de empezar)
    private final Counter gamesCancelled;

    // Partidas activas en este momento
    private final AtomicInteger gamesActive;

    // Tiempo promedio de partida (Timer)
    private final Timer gameDuration;

    // ─────────────────────────────────────────
    // MATCHMAKING
    // ─────────────────────────────────────────

    // Usuarios en cola AHORA
    private final AtomicInteger queueSize;

    // Matches encontrados
    private final Counter matchesFound;

    // Timeouts en cola (30s sin match)
    private final Counter queueTimeouts;

    // Tiempo de espera promedio hasta encontrar match
    private final Timer matchmakingWaitTime;

    // ─────────────────────────────────────────
    // CHAT / BOT
    // ─────────────────────────────────────────

    // Mensajes de chat enviados (tag: USER, BOT)
    private final Counter chatMessagesSent;

    // ─────────────────────────────────────────
    // CONSTRUCTOR
    // ─────────────────────────────────────────

    public CodemonMetrics(MeterRegistry registry) {

        // Usuarios
        this.usersRegistered = Counter.builder("codemon.users.registered")
            .description("Total de usuarios registrados")
            .register(registry);

        Gauge.builder("codemon.users.online", usersOnline, AtomicInteger::get)
            .description("Usuarios conectados vía WebSocket ahora mismo")
            .register(registry);
        this.usersOnline = new AtomicInteger(0);

        // Economía
        this.coinsPurchased = Counter.builder("codemon.coins.purchased")
            .description("Total de Codemones (coins) vendidos")
            .register(registry);

        this.revenueArs = Counter.builder("codemon.revenue.ars")
            .description("Total de pesos argentinos recibidos")
            .unit("ARS")
            .register(registry);

        this.boosterPacksBought = Counter.builder("codemon.booster.bought")
            .description("Total de sobres comprados")
            .register(registry);

        this.boosterPacksOpened = Counter.builder("codemon.booster.opened")
            .description("Total de sobres abiertos")
            .register(registry);

        // Partidas
        this.gamesStarted = Counter.builder("codemon.games.started")
            .description("Partidas iniciadas")
            .register(registry);

        this.gamesFinished = Counter.builder("codemon.games.finished")
            .description("Partidas terminadas")
            .register(registry);

        this.gamesCancelled = Counter.builder("codemon.games.cancelled")
            .description("Partidas canceladas/abandonadas")
            .register(registry);

        Gauge.builder("codemon.games.active", gamesActive, AtomicInteger::get)
            .description("Partidas en curso ahora mismo")
            .register(registry);
        this.gamesActive = new AtomicInteger(0);

        this.gameDuration = Timer.builder("codemon.games.duration")
            .description("Duración de las partidas")
            .publishPercentiles(0.5, 0.90, 0.99)
            .register(registry);

        // Matchmaking
        Gauge.builder("codemon.queue.size", queueSize, AtomicInteger::get)
            .description("Usuarios en cola de matchmaking ahora mismo")
            .register(registry);
        this.queueSize = new AtomicInteger(0);

        this.matchesFound = Counter.builder("codemon.matchmaking.found")
            .description("Matches encontrados en cola")
            .register(registry);

        this.queueTimeouts = Counter.builder("codemon.matchmaking.timeouts")
            .description("Usuarios que se fueron de la cola por timeout")
            .register(registry);

        this.matchmakingWaitTime = Timer.builder("codemon.matchmaking.wait_time")
            .description("Tiempo de espera hasta encontrar match")
            .publishPercentiles(0.5, 0.90)
            .register(registry);

        // Chat
        this.chatMessagesSent = Counter.builder("codemon.chat.messages")
            .description("Mensajes de chat enviados")
            .register(registry);
    }

    // ─────────────────────────────────────────
    // MÉTODOS PÚBLICOS (llamados desde servicios)
    // ─────────────────────────────────────────

    public void recordUserRegistered()           { usersRegistered.increment(); }

    public void recordUserConnected()            { usersOnline.incrementAndGet(); }
    public void recordUserDisconnected()         { usersOnline.decrementAndGet(); }

    public void recordCoinsPurchased(long coins) { coinsPurchased.increment(coins); }
    public void recordRevenueArs(double amount)  { revenueArs.increment(amount); }

    public void recordBoosterBought(int qty)     { boosterPacksBought.increment(qty); }
    public void recordBoosterOpened()            { boosterPacksOpened.increment(); }

    public void recordGameStarted(String type) {
        gamesStarted.increment();
        gamesActive.incrementAndGet();
    }

    public void recordGameFinished(String result, Duration duration) {
        gamesFinished.increment();
        gamesActive.decrementAndGet();
        gameDuration.record(duration);
    }

    public void recordGameCancelled() {
        gamesCancelled.increment();
        gamesActive.decrementAndGet();
    }

    public void recordUserJoinedQueue()          { queueSize.incrementAndGet(); }
    public void recordUserLeftQueue()            { queueSize.decrementAndGet(); }

    public void recordMatchFound(Duration waitTime) {
        matchesFound.increment();
        queueSize.decrementAndGet();
        queueSize.decrementAndGet();
        matchmakingWaitTime.record(waitTime);
    }

    public void recordQueueTimeout() {
        queueTimeouts.increment();
        queueSize.decrementAndGet();
    }

    public void recordChatMessage(String type)   { chatMessagesSent.increment(); }
}
```

---

## PASO 5 — Usar las métricas en los servicios

### En `AuthService.java`:
```java
@Autowired CodemonMetrics metrics;

// Al registrar:
metrics.recordUserRegistered();
```

### En `WebSocketEventHandler.java` (cuando conecta/desconecta):
```java
@EventListener
public void handleSessionConnected(SessionConnectedEvent event) {
    metrics.recordUserConnected();
}

@EventListener
public void handleSessionDisconnected(SessionDisconnectEvent event) {
    metrics.recordUserDisconnected();
}
```

### En `PaymentService.java`:
```java
// Al completar un pago:
metrics.recordCoinsPurchased(payment.getAmountCoins());
metrics.recordRevenueArs(payment.getAmountUsd().doubleValue());
```

### En `BoosterPackService.java`:
```java
// Al comprar sobres:
metrics.recordBoosterBought(quantity);

// Al abrir sobre:
metrics.recordBoosterOpened();
```

### En `GameService.java`:
```java
// Al iniciar partida:
metrics.recordGameStarted(game.getMatchType());

// Al terminar partida:
Duration duration = Duration.between(game.getStartedAt(), LocalDateTime.now());
metrics.recordGameFinished(result, duration);

// Al cancelar:
metrics.recordGameCancelled();
```

### En `MatchmakingService.java`:
```java
// Al entrar a cola:
metrics.recordUserJoinedQueue();

// Al encontrar match:
Duration wait = Duration.between(entry.getJoinTime(), LocalDateTime.now());
metrics.recordMatchFound(wait);

// Al timeout:
metrics.recordQueueTimeout();
```

---

## PASO 6 — Levantar el stack de monitoreo

```bash
# Desde la raíz del proyecto
docker compose up -d prometheus grafana postgres_exporter redis_exporter

# Verificar que levantaron
docker compose ps
# Todos deben estar "running"

# Verificar que Prometheus scrapea la API
# (API debe estar corriendo en localhost:8080)
curl http://localhost:9090/targets
# Debe mostrar codemon-api como UP
```

---

## PASO 7 — Configurar Dashboards en Grafana

### Acceder a Grafana

1. Abrir http://localhost:3000
2. Login: `admin` / `codemon123`
3. Ir a **Dashboards → New → New Dashboard**

### Crear Dashboard: Negocio

Crear un dashboard llamado **"Codemon - Negocio"** con estos paneles:

#### Panel 1: Usuarios Online (Stat)
```promql
codemon_users_online
```
- Type: **Stat**
- Título: "Usuarios Conectados Ahora"
- Color: Verde si > 0

#### Panel 2: Partidas Activas (Stat)
```promql
codemon_games_active
```
- Type: **Stat**
- Título: "Partidas en Curso"
- Color: Azul

#### Panel 3: Usuarios en Cola (Stat)
```promql
codemon_queue_size
```
- Type: **Stat**
- Título: "En Cola de Matchmaking"

#### Panel 4: Usuarios Registrados (Time Series)
```promql
increase(codemon_users_registered_total[1h])
```
- Type: **Time Series**
- Título: "Registros por hora"

#### Panel 5: Partidas Iniciadas hoy (Time Series)
```promql
increase(codemon_games_started_total[1h])
```
- Type: **Time Series**
- Título: "Partidas por hora"

#### Panel 6: Partidas Canceladas vs Terminadas (Bar Chart)
```promql
increase(codemon_games_finished_total[24h])    # label: "Terminadas"
increase(codemon_games_cancelled_total[24h])   # label: "Canceladas"
```
- Type: **Bar Chart**
- Título: "Resultado de partidas (24h)"

#### Panel 7: Tasa de cancelación (Gauge)
```promql
(
  increase(codemon_games_cancelled_total[24h])
  /
  (increase(codemon_games_started_total[24h]) + 0.001)
) * 100
```
- Type: **Gauge**
- Título: "% Partidas Canceladas (24h)"
- Umbrales: 0-20% verde, 20-40% amarillo, >40% rojo

#### Panel 8: Total Coins Vendidas (Stat)
```promql
codemon_coins_purchased_total
```
- Type: **Stat**
- Título: "Total Codemones Vendidos"

#### Panel 9: Ingresos en ARS (Time Series)
```promql
increase(codemon_revenue_ars_total[1d])
```
- Type: **Time Series**
- Título: "Ingresos por día (ARS)"

#### Panel 10: Sobres Abiertos vs Comprados (Time Series)
```promql
increase(codemon_booster_bought_total[1h])    # label: "Comprados"
increase(codemon_booster_opened_total[1h])    # label: "Abiertos"
```
- Type: **Time Series**
- Título: "Sobres (por hora)"

#### Panel 11: Tiempo de espera en matchmaking (Heatmap)
```promql
codemon_matchmaking_wait_time_seconds_bucket
```
- Type: **Heatmap**
- Título: "Tiempo de espera en cola"

#### Panel 12: Mensajes de chat (Time Series)
```promql
increase(codemon_chat_messages_total[1h])
```
- Type: **Time Series**
- Título: "Mensajes de chat por hora"

---

### Crear Dashboard: Sistema

Dashboard llamado **"Codemon - Sistema"**:

#### Panel 1: CPU del proceso Java (Gauge)
```promql
process_cpu_usage{application="codemon-api"} * 100
```
- Type: **Gauge**
- Título: "CPU del proceso (%)"
- Umbrales: 0-60% verde, 60-80% amarillo, >80% rojo

#### Panel 2: Memoria heap JVM (Time Series)
```promql
jvm_memory_used_bytes{area="heap", application="codemon-api"}
/
jvm_memory_max_bytes{area="heap", application="codemon-api"}
* 100
```
- Type: **Time Series**
- Título: "Heap JVM usado (%)"
- Umbrales: >80% rojo

#### Panel 3: Memoria fuera del heap (Time Series)
```promql
jvm_memory_used_bytes{area="nonheap", application="codemon-api"}
```
- Type: **Time Series**
- Título: "Non-Heap JVM (bytes)"

#### Panel 4: Threads activos (Stat)
```promql
jvm_threads_live_threads{application="codemon-api"}
```
- Type: **Stat**
- Título: "Threads JVM activos"

#### Panel 5: Garbage Collector (Time Series)
```promql
increase(jvm_gc_pause_seconds_sum{application="codemon-api"}[1m])
```
- Type: **Time Series**
- Título: "GC pauses (segundos por minuto)"

#### Panel 6: Latencia HTTP por endpoint (Heatmap)
```promql
http_server_requests_seconds_bucket{application="codemon-api"}
```
- Type: **Heatmap**
- Título: "Latencia de requests HTTP"

#### Panel 7: Requests por segundo (Time Series)
```promql
rate(http_server_requests_seconds_count{application="codemon-api"}[1m])
```
- Type: **Time Series**
- Título: "Requests/segundo"

#### Panel 8: Errores HTTP 5xx (Time Series)
```promql
rate(http_server_requests_seconds_count{status=~"5..", application="codemon-api"}[1m])
```
- Type: **Time Series**
- Título: "Errores 5xx por minuto"
- Color: Rojo

#### Panel 9: Pool de conexiones a BD (Time Series)
```promql
hikaricp_connections_active{application="codemon-api"}
hikaricp_connections_max{application="codemon-api"}
```
- Type: **Time Series**
- Título: "Conexiones HikariCP (activas vs máximo)"

#### Panel 10: Cache (hits vs misses) (Time Series)
```promql
increase(cache_gets_total{result="hit", application="codemon-api"}[1m])
increase(cache_gets_total{result="miss", application="codemon-api"}[1m])
```
- Type: **Time Series**
- Título: "Cache hits vs misses"

---

### Crear Dashboard: PostgreSQL

Dashboard llamado **"Codemon - PostgreSQL"**:

#### Panel 1: Conexiones activas (Gauge)
```promql
pg_stat_activity_count{state="active"}
```

#### Panel 2: Transacciones por segundo (Time Series)
```promql
rate(pg_stat_database_xact_commit{datname="codemon_db"}[1m])
+ rate(pg_stat_database_xact_rollback{datname="codemon_db"}[1m])
```
- Título: "Transacciones/segundo"

#### Panel 3: Rollbacks (Time Series)
```promql
rate(pg_stat_database_xact_rollback{datname="codemon_db"}[5m])
```
- Título: "Rollbacks por minuto"
- Color: Amarillo si > 0

#### Panel 4: Cache hit ratio (Gauge)
```promql
pg_stat_database_blks_hit{datname="codemon_db"}
/
(pg_stat_database_blks_hit{datname="codemon_db"} + pg_stat_database_blks_read{datname="codemon_db"})
* 100
```
- Título: "Cache hit ratio (%)"
- Umbrales: <90% rojo, 90-99% amarillo, >99% verde

#### Panel 5: Tamaño de la BD (Stat)
```promql
pg_database_size_bytes{datname="codemon_db"}
```
- Título: "Tamaño de la BD"
- Unit: bytes

#### Panel 6: Deadlocks (Time Series)
```promql
increase(pg_stat_database_deadlocks{datname="codemon_db"}[5m])
```
- Título: "Deadlocks (cada 5 min)"
- Color: Rojo si > 0 (alerta)

---

### Crear Dashboard: Redis

Dashboard llamado **"Codemon - Redis"**:

#### Panel 1: Memoria usada (Gauge)
```promql
redis_memory_used_bytes / redis_memory_max_bytes * 100
```
- Título: "Memoria Redis (%)"

#### Panel 2: Keys totales (Stat)
```promql
redis_db_keys
```
- Título: "Keys en Redis"

#### Panel 3: Operaciones por segundo (Time Series)
```promql
rate(redis_commands_processed_total[1m])
```
- Título: "Operaciones/segundo"

#### Panel 4: Usuarios en matchmaking queue (Stat)
```promql
redis_db_keys{db="db0"}
```
- Título: "Items en Redis (incluye cola matchmaking)"

#### Panel 5: Hit ratio (Gauge)
```promql
redis_keyspace_hits_total
/
(redis_keyspace_hits_total + redis_keyspace_misses_total)
* 100
```
- Título: "Cache hit ratio (%)"

---

## PASO 8 — Configurar Alertas en Grafana (Opcional pero recomendado)

Ir a **Alerting → Alert Rules → New Alert Rule**

### Alerta 1: API caída
```promql
up{job="codemon-api"} == 0
```
- Condición: cuando `up == 0` por más de 30 segundos
- Título: "⚠️ API de Codemon caída"

### Alerta 2: CPU alta
```promql
process_cpu_usage{application="codemon-api"} > 0.85
```
- Condición: cuando CPU > 85% por más de 2 minutos
- Título: "⚠️ CPU alta en API"

### Alerta 3: Heap JVM alto
```promql
jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"} > 0.9
```
- Condición: cuando heap > 90% por más de 1 minuto
- Título: "⚠️ Memoria JVM alta"

### Alerta 4: Muchos errores 5xx
```promql
rate(http_server_requests_seconds_count{status=~"5.."}[5m]) > 0.1
```
- Condición: más de 6 errores 5xx en 5 minutos
- Título: "⚠️ Errores de servidor detectados"

### Alerta 5: Tasa de cancelación alta
```promql
(
  increase(codemon_games_cancelled_total[1h])
  /
  increase(codemon_games_started_total[1h])
) > 0.5
```
- Condición: más del 50% de partidas canceladas en 1 hora
- Título: "⚠️ Alta tasa de cancelación de partidas"

---

## Resumen de métricas por categoría

### Negocio

| Métrica | Tipo | Descripción |
|---------|------|-------------|
| `codemon_users_online` | Gauge | Usuarios conectados vía WebSocket ahora |
| `codemon_users_registered_total` | Counter | Total registros históricos |
| `codemon_coins_purchased_total` | Counter | Codemones vendidos (acumulado) |
| `codemon_revenue_ars_total` | Counter | Pesos recibidos (acumulado) |
| `codemon_booster_bought_total` | Counter | Sobres comprados |
| `codemon_booster_opened_total` | Counter | Sobres abiertos |
| `codemon_games_started_total` | Counter | Partidas iniciadas |
| `codemon_games_finished_total` | Counter | Partidas terminadas |
| `codemon_games_cancelled_total` | Counter | Partidas canceladas |
| `codemon_games_active` | Gauge | Partidas en curso ahora mismo |
| `codemon_games_duration_seconds` | Timer | Duración de partidas (p50, p90, p99) |
| `codemon_queue_size` | Gauge | Usuarios en cola ahora |
| `codemon_matchmaking_found_total` | Counter | Matches encontrados |
| `codemon_matchmaking_timeouts_total` | Counter | Timeouts en cola |
| `codemon_matchmaking_wait_time_seconds` | Timer | Tiempo de espera en cola |
| `codemon_chat_messages_total` | Counter | Mensajes de chat enviados |

### Sistema (automáticas, Micrometer)

| Métrica | Descripción |
|---------|-------------|
| `process_cpu_usage` | CPU del proceso Java (0-1) |
| `jvm_memory_used_bytes` | Memoria JVM usada |
| `jvm_memory_max_bytes` | Límite de memoria JVM |
| `jvm_threads_live_threads` | Threads activos |
| `jvm_gc_pause_seconds` | Tiempo en Garbage Collection |
| `http_server_requests_seconds` | Latencia de endpoints HTTP |
| `hikaricp_connections_active` | Conexiones activas a BD |
| `hikaricp_connections_max` | Máximo de conexiones configurado |
| `cache_gets_total` | Hits/misses de caché |

### PostgreSQL (postgres_exporter)

| Métrica | Descripción |
|---------|-------------|
| `pg_stat_activity_count` | Conexiones activas |
| `pg_stat_database_xact_commit` | Transacciones/segundo |
| `pg_stat_database_xact_rollback` | Rollbacks/segundo |
| `pg_stat_database_deadlocks` | Deadlocks detectados |
| `pg_database_size_bytes` | Tamaño de la BD |
| `pg_stat_database_blks_hit` | Cache hits de BD |

### Redis (redis_exporter)

| Métrica | Descripción |
|---------|-------------|
| `redis_memory_used_bytes` | Memoria usada |
| `redis_db_keys` | Keys almacenadas |
| `redis_commands_processed_total` | Operaciones/segundo |
| `redis_keyspace_hits_total` | Cache hits |
| `redis_keyspace_misses_total` | Cache misses |

---

## Verificación final del stack de monitoreo

```bash
# 1. Todos los servicios corriendo
docker compose ps
# Esperado: postgres, redis, prometheus, grafana, postgres_exporter, redis_exporter → all healthy

# 2. Prometheus recibe métricas de la API
curl http://localhost:9090/api/v1/query?query=up
# Esperado: codemon-api con value [1]

# 3. Métricas custom visibles
curl http://localhost:8088/actuator/prometheus | grep codemon
# Esperado: todas las métricas con prefijo codemon_

# 4. Grafana accesible
curl http://localhost:3000/api/health
# Esperado: {"commit":"...","database":"ok","version":"..."}
```

---

## Checklist de Monitoreo

- [ ] Dependencias Micrometer + Actuator en pom.xml
- [ ] Endpoint `/actuator/prometheus` responde
- [ ] `prometheus.yml` configurado con el target de la API
- [ ] Prometheus, Grafana, exporters en `docker-compose.yml`
- [ ] `CodemonMetrics.java` creado con todas las métricas
- [ ] Métricas llamadas desde los servicios correspondientes
- [ ] 4 Dashboards creados en Grafana: Negocio, Sistema, PostgreSQL, Redis
- [ ] Alertas configuradas (API caída, CPU alta, errores 5xx)
- [ ] `grafana-datasource.yml` en provisioning (Prometheus datasource auto)
