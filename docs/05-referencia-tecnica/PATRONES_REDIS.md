# Codemon TCG — Patrones de uso de Redis

Redis 7 está provisionado en `docker-compose.yml` (puerto 6379). Este documento define los patrones de uso acordados para que cada PASO lo implemente de forma consistente.

---

## Conexión

Spring Boot se conecta vía **Spring Data Redis** + **Lettuce** (cliente por defecto).

```yaml
# application.yml
spring:
  data:
    redis:
      host: ${REDIS_HOST:localhost}
      port: 6379
```

```java
// Inyectar donde se use
@Autowired
private StringRedisTemplate redisTemplate;

// O con tipo genérico
@Autowired
private RedisTemplate<String, Object> redisTemplate;
```

---

## 1. Sesiones JWT (refresh token en lista negra)

**Caso de uso:** invalidar tokens JWT antes de su expiración (logout, cambio de contraseña, ban).

**Clave:** `blacklist:jwt:<jti>` (jti = JWT ID, UUID)
**Tipo:** String (valor `"1"`)
**TTL:** igual al tiempo restante del token

```java
// Al hacer logout
public void blacklistToken(String jti, long remainingSeconds) {
    redisTemplate.opsForValue().set(
        "blacklist:jwt:" + jti,
        "1",
        Duration.ofSeconds(remainingSeconds)
    );
}

// En el filtro JWT
public boolean isBlacklisted(String jti) {
    return Boolean.TRUE.equals(redisTemplate.hasKey("blacklist:jwt:" + jti));
}
```

**PASO que lo usa:** `PASO_S01_01` (auth JWT).

---

## 2. Cola de matchmaking ranked

**Caso de uso:** mantener la cola de jugadores esperando rival, ordenados por ELO.

**Clave:** `matchmaking:queue` (sorted set global)
**Tipo:** Sorted Set — `score = ELO del jugador`, `member = userId`
**TTL:** sin TTL (la cola es persistente; el jugador sale al cancelar o encontrar rival)

```java
// Entrar a la cola
public void enqueue(Long userId, double elo) {
    redisTemplate.opsForZSet().add("matchmaking:queue", userId.toString(), elo);
    // Guardar timestamp de entrada para timeout
    redisTemplate.opsForValue().set(
        "matchmaking:timestamp:" + userId, 
        String.valueOf(System.currentTimeMillis()),
        Duration.ofMinutes(10)
    );
}

// Buscar rival (rango ELO ±200)
public List<String> findCandidates(double elo, double range) {
    return new ArrayList<>(
        redisTemplate.opsForZSet().rangeByScore(
            "matchmaking:queue", elo - range, elo + range
        )
    );
}

// Salir de la cola
public void dequeue(Long userId) {
    redisTemplate.opsForZSet().remove("matchmaking:queue", userId.toString());
    redisTemplate.delete("matchmaking:timestamp:" + userId);
}
```

**PASO que lo usa:** `PASO_S07_02` (matchmaking ranked).

---

## 3. Presencia online de usuarios

**Caso de uso:** mostrar estado "En línea / Jugando / Desconectado" en la lista de amigos.

**Clave:** `presence:<userId>`
**Tipo:** String — valor: `"ONLINE"`, `"IN_GAME"`, `"OFFLINE"`
**TTL:** 90 segundos (se renueva con heartbeat cada 60s desde el frontend via WebSocket)

```java
// Actualizar presencia
public void setPresence(Long userId, String status) {
    redisTemplate.opsForValue().set(
        "presence:" + userId,
        status,
        Duration.ofSeconds(90)
    );
}

// Leer presencia
public String getPresence(Long userId) {
    String val = redisTemplate.opsForValue().get("presence:" + userId);
    return val != null ? val : "OFFLINE";
}

// Leer presencia en bulk (para lista de amigos)
public Map<Long, String> getBulkPresence(List<Long> userIds) {
    List<String> keys = userIds.stream()
        .map(id -> "presence:" + id)
        .toList();
    List<String> values = redisTemplate.opsForValue().multiGet(keys);
    Map<Long, String> result = new HashMap<>();
    for (int i = 0; i < userIds.size(); i++) {
        result.put(userIds.get(i), values.get(i) != null ? values.get(i) : "OFFLINE");
    }
    return result;
}
```

**PASO que lo usa:** `PASO_S09_02` (amigos + presencia).

---

## 4. Leaderboard global (caché de vista materializada)

**Caso de uso:** servir el ranking global rápido sin golpear la vista materializada de PostgreSQL en cada request.

**Clave:** `leaderboard:global` (sorted set)
**Tipo:** Sorted Set — `score = ELO`, `member = userId`
**TTL:** sin TTL; se actualiza al final de cada partida y con un job programado cada 5 min

```java
// Actualizar posición de un jugador tras partida
public void updateLeaderboard(Long userId, double newElo) {
    redisTemplate.opsForZSet().add("leaderboard:global", userId.toString(), newElo);
}

// Top N jugadores
public List<String> getTopN(int n) {
    return new ArrayList<>(
        redisTemplate.opsForZSet().reverseRange("leaderboard:global", 0, n - 1)
    );
}

// Posición de un jugador
public Long getRank(Long userId) {
    Long rank = redisTemplate.opsForZSet().reverseRank("leaderboard:global", userId.toString());
    return rank != null ? rank + 1 : null; // 1-indexed
}
```

**PASO que lo usa:** `PASO_S08_02` (leaderboard), `PASO_S09_01` (ligas), `PASO_S09_04` (frontend).

---

## 5. Rate limiting (protección de endpoints sensibles)

**Caso de uso:** limitar intentos de login, registro y compra para evitar abuso.

**Clave:** `ratelimit:<endpoint>:<ip>` (ej: `ratelimit:login:192.168.1.1`)
**Tipo:** String (contador)
**TTL:** 60 segundos (ventana deslizante simple)

```java
// Incrementar contador (retorna el nuevo valor)
public long increment(String endpoint, String ip) {
    String key = "ratelimit:" + endpoint + ":" + ip;
    Long count = redisTemplate.opsForValue().increment(key);
    if (count == 1) {
        redisTemplate.expire(key, Duration.ofSeconds(60));
    }
    return count;
}

// En el filtro/controller: si count > limite → HTTP 429
```

**Límites acordados:**
| Endpoint | Límite | Ventana |
|---|---|---|
| `POST /api/auth/login` | 10 intentos | 60 s |
| `POST /api/auth/register` | 5 intentos | 60 s |
| `POST /api/payments/create` | 3 intentos | 60 s |

**PASO que lo usa:** `PASO_S01_01` (auth), `PASO_S08_04` (pagos).

---

## Convenciones de naming

| Patrón | Ejemplo |
|---|---|
| `blacklist:jwt:<jti>` | `blacklist:jwt:a1b2c3d4-...` |
| `matchmaking:queue` | (único, sorted set global) |
| `matchmaking:timestamp:<userId>` | `matchmaking:timestamp:42` |
| `presence:<userId>` | `presence:42` |
| `leaderboard:global` | (único, sorted set global) |
| `ratelimit:<endpoint>:<ip>` | `ratelimit:login:10.0.0.1` |

**Regla:** prefijo con `:` como separador. Nunca usar `/` o espacios en claves Redis.

---

## Monitoreo

```bash
# Ver todas las claves activas (dev only — no usar en producción)
docker exec codemon_redis redis-cli keys "*"

# Ver TTL de una clave
docker exec codemon_redis redis-cli ttl "presence:42"

# Ver top del leaderboard
docker exec codemon_redis redis-cli zrevrange "leaderboard:global" 0 9 WITHSCORES

# Info general
docker exec codemon_redis redis-cli info memory
```

El exporter de Redis (`redis_exporter`) ya está configurado en `docker-compose.yml` y expone métricas en `:9121/metrics` para Grafana.

---

## 7. Persistencia y operación

### 7.1 Persistencia (AOF + RDB)

Redis se ejecuta con **AOF habilitado** (`appendonly yes`, `appendfsync everysec`) y snapshots
RDB (`save 900 1` y `save 300 10`). Esto garantiza pérdida máxima de ~1 segundo de
escrituras ante caída. La configuración vive en el bloque `command:` del servicio `redis` en
`docs/07-infraestructura/docker-compose.yml`.

Implicaciones:
- La cola de matchmaking (`matchmaking:queue`) sobrevive reinicios.
- El blacklist de JWT (`blacklist:jwt:*`) sobrevive reinicios — fundamental por seguridad.
- El leaderboard caché (`leaderboard:global`) sobrevive y se complementa con refresh
  programado cada 5 min desde la vista materializada `leaderboard` en PostgreSQL.

### 7.2 Namespacing por entorno

Toda clave debe llevar prefijo de entorno: `<env>:<dominio>:<id>`.

| Entorno | Ejemplo de clave |
|---|---|
| `dev`     | `dev:presence:42` |
| `staging` | `staging:matchmaking:queue` |
| `prod`    | `prod:ratelimit:login:127.0.0.1` |

El prefijo se inyecta vía un `RedisKeyBuilder` (Spring `@Value("${app.env:dev}")`).
**Razón:** evita colisiones si dos entornos comparten instancia Redis por error y permite
flush selectivo por entorno (`redis-cli --scan --pattern "dev:*" | xargs redis-cli del`).

### 7.3 Estrategia de consistencia con PostgreSQL

El patrón es **cache-aside**: PostgreSQL es la fuente de verdad; Redis es caché de lectura
y estado efímero.

| Dato | Fuente de verdad | Caché Redis | Invalidación |
|---|---|---|---|
| Leaderboard | `MATERIALIZED VIEW leaderboard` (PG) | `leaderboard:global` (ZSET) | Write-on-event al fin de partida ranked + `REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard` cada 5 min |
| Presencia online | `users.last_seen_at` (PG) | `presence:<userId>` (TTL 90 s) | Job batch cada 5 min vuelca `presence:*` a `last_seen_at` |
| Cola matchmaking | — (efímero) | `matchmaking:queue` (ZSET) | Solo Redis. En reinicio se mantiene gracias a AOF |
| Blacklist JWT | — (efímero, expira con el token) | `blacklist:jwt:<jti>` | Auto-expira por TTL |
| Rate limiting | — (efímero) | `ratelimit:<endpoint>:<ip>` | Auto-expira por TTL 60 s |

### 7.4 Lock distribuido (multi-instancia)

Para producción multi-pod, el matchmaker usa `SET NX EX 5` en `<env>:lock:matchmaking:tick`
antes de cada tick para evitar dobles emparejamientos entre instancias. Convención:

```
<env>:lock:<recurso>   TTL ≤ 10 s
```

Implementar con `RedisLockRegistry` de Spring Integration (`spring-integration-redis`) para
que el lock se libere automáticamente si la JVM cae. Misma técnica para refresco de
leaderboard (`<env>:lock:leaderboard:refresh`) y purga de datos (`<env>:lock:purge:tick`).
