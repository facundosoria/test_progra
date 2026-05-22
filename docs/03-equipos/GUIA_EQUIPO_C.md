# GUÍA COMPLETA — EQUIPO C: Backend Auxiliar + DevOps
**Proyecto:** Codemon TCG  
**Rol del equipo:** Infraestructura, matchmaking, features adicionales, integraciones externas y monitoreo  
**Composición recomendada:** 1–2 desarrolladores backend mid (Java/Spring + algo de DevOps)  
**Tiempo total estimado:** 55–65 horas de trabajo  
**Archivos de referencia:** [README.md](../02-planificacion/README.md) · [EQUIPOS.md](../02-planificacion/04_proceso/EQUIPOS.md)

> Nota de estructura: los archivos referenciados a lo largo de esta guia (`docker-compose.yml` y `.env.example` viven en la raiz del repo; `SCHEMA_BD.sql`, `MONITOREO.md`, etc. viven en `docs/` organizados por tema). Para mapear cada archivo a su carpeta exacta, ver [docs/INDICE.md](../INDICE.md). Para el workflow con IA, ver [docs/08-desarrollo-con-ia/README.md](../08-desarrollo-con-ia/README.md).

---

## 1. CONOCIMIENTOS PREVIOS OBLIGATORIOS

### Java 21 + Spring Boot 3.3.x
- [ ] `@Service`, `@Repository`, `@RestController`, `@Scheduled`
- [ ] Inyección por constructor con `@RequiredArgsConstructor` (Lombok) — **nunca `@Autowired` en campos**
- [ ] `@Transactional` en métodos que modifican la BD (capa Service, no Controller)
- [ ] `@EnableScheduling` — para que `@Scheduled` funcione (configuración global)
- [ ] `@Value("${propiedad}")` — leer variables de configuración
- [ ] Spring Mail (`JavaMailSender`) para enviar emails

### Spring Data JPA
- [ ] `JpaRepository<T, ID>` con consultas JPQL personalizadas (`@Query`)
- [ ] Enumeraciones en BD: `@Enumerated(EnumType.STRING)`
- [ ] `@ManyToOne`, `@OneToMany`, `@OneToOne` — relaciones entre entidades
- [ ] `@CreationTimestamp`, `@UpdateTimestamp` (Hibernate)

### Spring Data Redis
- [ ] `RedisTemplate<String, String>` para operaciones básicas
- [ ] **Sorted Sets (ZSET)** — fundamental para el matchmaking. Operaciones: `zadd`, `zrangeByScore`, `zrem`, `zrank`
- [ ] `StringRedisTemplate` para simplificar operaciones con Strings
- [ ] TTL (time-to-live) en claves Redis — para expirar entradas de la cola de matchmaking

### Docker + Docker Compose
- [ ] Entender el `docker-compose.yml` del proyecto: 10 servicios, sus puertos, sus volúmenes y healthchecks
- [ ] `docker compose up -d`, `docker compose down`, `docker compose logs -f <servicio>`
- [ ] Variables de entorno en Docker Compose (referencia al `.env`)
- [ ] Volúmenes persistentes: qué datos se persisten y cuáles se pierden al `down -v`

### PostgreSQL básico
- [ ] `CREATE TABLE`, `CREATE INDEX`, vistas materializadas (`CREATE MATERIALIZED VIEW`)
- [ ] `REFRESH MATERIALIZED VIEW CONCURRENTLY` — para refrescar el leaderboard sin bloquear
- [ ] Índices para queries frecuentes (leaderboard, matchmaking)

### Mercado Pago SDK (Java)
- [ ] Flujo de pagos con preferencias (Checkout Pro)
- [ ] Webhooks: qué son, cómo verificarlos, idempotencia obligatoria
- [ ] Diferencia entre sandbox (`TEST-`) y producción

### Grafana + Prometheus
- [ ] Qué es el scraping de métricas
- [ ] Cómo crear un Dashboard en Grafana con una fuente de datos Prometheus
- [ ] Spring Boot Actuator: qué expone `/actuator/prometheus`
- [ ] Cómo usar `MeterRegistry` para métricas personalizadas

---

## 2. CONOCIMIENTOS A ADQUIRIR DURANTE EL PROCESO

- **Redis Sorted Sets para matchmaking:** El patrón de "buscar oponente por Elo" con `ZRANGEBYSCORE` se aprende en PASO_S07_02
- **Spring Mail + Gmail App Password:** Configurar autenticación SMTP de Gmail para desarrollo local. Se aprende en PASO_S08_03
- **OAuth2 en Spring Security 6:** La configuración de providers (Google/GitHub) es distinta a Spring Security 5. Se aprende en PASO_S10_01
- **Grafana Dashboard JSON:** Importar un dashboard desde un JSON es más fácil que crearlo desde cero. Se aprende en PASO_S08_05

---

## 3. ARCHIVOS DE REFERENCIA OBLIGATORIOS

| Archivo | Cuándo leerlo | Motivo |
|---------|--------------|--------|
| `CONVENCIONES.md` | Antes de todo | Reglas globales de código |
| `SCHEMA_BD.sql` | Antes de todo | Conocer TODAS las tablas, no solo las propias |
| `docker-compose.yml` | Antes de PASO_S00_03 | Entender los 10 servicios y su relación |
| `.env.example` | Antes de PASO_S00_03 | Variables de entorno necesarias |
| `MONITOREO.md` | Antes de PASO_S08_05 | Setup detallado de Grafana |
| `CODEMON_GUIAS_TECNICAS.md` | Consultar por sección | Código de ejemplo para MercadoPago, Email, OAuth2 |
| `CONTRATOS_API.md` | Antes de empezar S7 | Para saber qué endpoints debe producir este equipo |

---

## 4. ESTRUCTURA DE CARPETAS DEL PROYECTO

El Equipo C trabaja principalmente en la misma base de código del backend (`~/codemon/api/`) y en la infraestructura Docker:

```
~/codemon/
├── api/src/main/java/com/codemon/
│   ├── lobby/                           ← PASO_S07_01 (salas privadas)
│   │   ├── entity/
│   │   │   ├── GameRoom.java
│   │   │   └── GameRoomPlayer.java
│   │   ├── repository/
│   │   ├── service/RoomService.java
│   │   └── controller/RoomController.java
│   ├── matchmaking/                     ← PASO_S07_02 (cola ranked)
│   │   ├── service/MatchmakingService.java
│   │   └── controller/MatchmakingController.java
│   ├── booster/                         ← PASO_S08_01 (sobres)
│   │   ├── entity/
│   │   ├── service/BoosterPackService.java
│   │   └── controller/BoosterController.java
│   ├── leaderboard/                     ← PASO_S08_02
│   │   ├── service/LeaderboardService.java
│   │   └── controller/LeaderboardController.java
│   ├── payment/                         ← PASO_S08_04 (Mercado Pago)
│   │   ├── entity/
│   │   ├── service/PaymentService.java
│   │   ├── service/WalletService.java
│   │   ├── controller/PaymentController.java
│   │   └── controller/WebhookController.java
│   ├── metrics/                         ← PASO_S08_05 (métricas custom)
│   │   └── GameMetricsService.java
│   ├── ranking/                         ← PASO_S09_01 (ligas)
│   │   ├── entity/RankingHistory.java
│   │   └── service/LeagueService.java
│   ├── social/                          ← PASO_S09_02 (amigos)
│   │   ├── entity/Friendship.java
│   │   └── service/FriendshipService.java
│   ├── news/                            ← PASO_S09_03 (noticias)
│   │   ├── entity/NewsPost.java
│   │   └── controller/NewsController.java
│   └── oauth/                           ← PASO_S10_01 (OAuth2)
│       └── config/OAuth2Config.java
├── .env                                 ← CREAR desde .env.example
├── docker-compose.yml                   ← NO MODIFICAR sin consultar
├── prometheus.yml                       ← PASO_S08_05
└── grafana-datasource.yml               ← PASO_S08_05
```

---

## 5. INSTRUCCIONES DE EJECUCIÓN — PASO A PASO

### PASO 0.0 — Contratos de API (TODOS juntos)
**Duración:** 3–4 h | **Rol del Equipo C:**

1. Participar en la revisión de los modelos de BD con el Equipo A
2. Proponer los endpoints que va a implementar (matchmaking, pagos, amigos, noticias)
3. Confirmar que los contratos de matchmaking tienen los campos que necesita el Equipo B
4. Preguntar al Equipo A: ¿Qué interface expone `GameEngine` para que `RoomService` pueda iniciar una partida?

---

### PASO 0.1 — Instalar herramientas
**Duración:** 30 min | **Ejecuta:** Dev del Equipo C

```bash
# En macOS (con Homebrew):
brew install openjdk@21 maven node
# En Linux (Ubuntu/Debian):
sudo apt install -y openjdk-21-jdk maven

# Verificar versiones
java -version  # → 21.x.x
mvn -version   # → 3.x.x
docker --version
docker compose version
```

---

### PASO 0.2 — Levantar Docker (infraestructura completa)
**Duración:** 15 min + tiempo de descarga de imágenes | **Ejecuta:** Dev del Equipo C

```bash
# 1. Crear el archivo .env desde el ejemplo
mkdir -p ~/codemon && cd ~/codemon
cp /ruta/docs/07-infraestructura/docker-compose.yml ~/codemon/
cp /ruta/docs/07-infraestructura/.env.example ~/codemon/.env

# 2. Editar .env con valores de desarrollo:
# DB_HOST=localhost
# DB_PORT=5432
# DB_NAME=codemon_db
# DB_USER=codemon_user
# DB_PASSWORD=codemon_pass
# REDIS_HOST=localhost
# REDIS_PORT=6379
# JWT_SECRET=dev_secret_cambiar_en_prod_min32chars
# MP_ACCESS_TOKEN=TEST-xxxx (obtener del panel sandbox de MP)
# MP_SANDBOX=true
# EMAIL_SMTP_HOST=smtp.gmail.com (o MailHog para desarrollo)
# ... (completar todos los campos)

# 3. Levantar todos los servicios
docker compose up -d

# 4. Verificar que todos están corriendo
docker compose ps
# Estado esperado: api (exit o starting), front (exit o starting),
# postgres (healthy), redis (running), minio (running), prometheus (running), grafana (running)

# 5. Verificar acceso a servicios:
curl http://localhost:8088/minio/health/live  # MinIO vía Nginx (9000 no está expuesto directamente)
docker exec -it codemon_postgres psql -U codemon_user -d codemon_db -c "SELECT version();"
redis-cli -h localhost -p 6379 PING  # → PONG
```

**⚠️ ALERTA:** El Equipo A necesita Docker corriendo para sus tests de integración. Notificar a Equipo A cuando Docker esté operativo.

---

### PASO 4.2 — Leaderboard
**Duración:** 2–3 h | **Ejecuta:** Dev del Equipo C | **Puede empezar tras GATE 0**

> Este paso puede empezar inmediatamente después del GATE 0, sin esperar nada.

```
# Prompt: cargar PASO_S08_02.md + SCHEMA_BD.sql (bloques de leaderboard y skill_ratings)
```

La vista materializada `leaderboard` ya está en el schema. El servicio solo necesita:
1. Ejecutar `SELECT * FROM leaderboard ORDER BY skill_rating DESC` con paginación
2. Un endpoint `GET /api/leaderboard?page=0&size=20`
3. Un `@Scheduled` que llame a `REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard` después de cada partida

**Preparación para GATE 6 — Notificar al Equipo B cuando esté listo:**
```bash
TOKEN="eyJ..."
curl -H "Authorization: Bearer $TOKEN" "http://localhost:8088/api/leaderboard?size=5"
# Debe retornar JSON con ranking
```

---

### PASO_S09_03 — Noticias
**Duración:** 2–3 h | **Ejecuta:** Dev del Equipo C | **Puede empezar tras GATE 0**

> También puede empezar inmediatamente, es el paso más simple del equipo.

```
# Prompt: cargar PASO_S09_03.md + SCHEMA_BD.sql bloque de news_posts
```

Dos endpoints:
- `GET /api/news` — público, con paginación y filtro por categoría
- `POST /api/news` — solo usuarios con rol ADMIN (agregar rol al schema de users si no existe)

---

### PASO_S08_03 — 2FA por email
**Duración:** 4–5 h | **Ejecuta:** Dev del Equipo C | **S8**

> El Equipo A necesita este paso para completar el flujo de registro con verificación.

```
# Prompt: cargar PASO_S08_03.md + SCHEMA_BD.sql bloque email_verifications + CODEMON_GUIAS_TECNICAS.md sección Email
```

**Configuración para desarrollo local (usar MailHog — no requiere cuenta Gmail):**
```yaml
# En application-dev.yml:
spring:
  mail:
    host: localhost
    port: 1025  # MailHog SMTP
    username: ""
    password: ""
```

```bash
# Levantar MailHog (intercepta emails en desarrollo)
docker run -d -p 1025:1025 -p 8025:8025 mailhog/mailhog
# Ver emails en: http://localhost:8025
```

**Para producción/staging (Gmail App Password):**
1. Activar 2FA en la cuenta de Gmail del proyecto
2. Ir a `Seguridad → Contraseñas de aplicaciones`
3. Generar contraseña de app y poner en `EMAIL_PASSWORD` del `.env`

**Lógica del código de verificación:**
- 6 dígitos numéricos, válido por 15 minutos
- Máximo 3 intentos antes de bloquear
- El código se guarda como hash en `email_verifications`

---

### PASO_S08_01 — Sobres de cartas (estructura BD + lógica)
**Duración:** 3–4 h | **Ejecuta:** Dev del Equipo C | **S8**

```
# Prompt: cargar PASO_S08_01.md + SCHEMA_BD.sql bloques booster_packs, user_booster_packs, user_collection
```

Dos partes:
1. **Estructura BD** — seed de los sobres disponibles (tabla `booster_packs`)
2. **Lógica de apertura** — distribución aleatoria de rarezas según `rarity_distribution` JSONB:
   ```json
   {
     "Common": 6,
     "Uncommon": 3,
     "Rare": 1
   }
   ```

---

### PASO_S07_01 — Salas privadas
**Duración:** 3–4 h | **Ejecuta:** Dev del Equipo C | **S7**

> **Requiere:** Equipo A PASO_S01_01 (JWT auth) operativo.

```
# Prompt: cargar PASO_S07_01.md + SCHEMA_BD.sql bloque V8 (game_rooms, game_room_players)
```

**Puntos críticos de implementación:**
1. **Código de sala único:** verificar en BD antes de guardar; regenerar si hay colisión (máx 5 intentos)
2. **Expiración automática:** `@Scheduled(fixedRate=60000)` que marca como `EXPIRED` las salas con `expires_at < NOW()`
3. **2 jugadores listos → crear partida:** llamar a `gameEngine.startGame()` (Equipo A lo provee en PASO_S05_03)
4. **Race condition:** Si dos usuarios se unen simultáneamente, usar `@Transactional` con lock

```bash
# Verificación:
TOKEN1="eyJ..."
TOKEN2="eyJ..."

# Crear sala (usuario 1)
ROOM=$(curl -s -X POST http://localhost:8088/api/rooms \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json" \
  -d '{"deckId":1}')
CODE=$(echo $ROOM | python3 -c "import sys,json; print(json.load(sys.stdin)['roomCode'])")
echo "Código de sala: $CODE"  # Ej: ABC123

# Unirse a la sala (usuario 2)
curl -X POST http://localhost:8088/api/rooms/$CODE/join \
  -H "Authorization: Bearer $TOKEN2" \
  -H "Content-Type: application/json" \
  -d '{"deckId":2}'
# Debe retornar gameId si la partida se creó
```

**GATE 3 — Notificar al Equipo B cuando esté listo.**

---

### PASO_S07_02 — Matchmaking ranked (Redis Sorted Set)
**Duración:** 5–7 h | **Ejecuta:** Dev del Equipo C | **S7**

> **Requiere:** PASO_S07_01 terminado.

```
# Prompt: cargar PASO_S07_02.md + SCHEMA_BD.sql bloque skill_ratings + queue_entries
```

**El algoritmo de matchmaking con Redis Sorted Set:**
```
Cola en Redis: ZSET "matchmaking:queue"
  key: userId
  score: skillRating del jugador

Cuando un jugador entra a la cola:
  ZADD matchmaking:queue <skillRating> <userId>

Búsqueda de oponente (cada 5 segundos, @Scheduled):
  Para cada jugador en la cola:
    rango = [skillRating - 100, skillRating + 100]
    candidatos = ZRANGEBYSCORE matchmaking:queue rango
    Si hay candidatos (excluyendo el propio userId):
      tomar el primer candidato
      crear la partida
      remover ambos de la cola: ZREM matchmaking:queue userId candidatoId

El rango se amplía cada 30 segundos sin match (para no esperar indefinidamente):
  turno 1: ±100 puntos
  turno 2: ±200 puntos
  turno 3: ±400 puntos
```

```java
// Ejemplo de uso con RedisTemplate
@Service
@RequiredArgsConstructor
public class MatchmakingService {
    private final StringRedisTemplate redisTemplate;
    
    private static final String QUEUE_KEY = "matchmaking:queue";
    
    public void joinQueue(Long userId, int skillRating) {
        redisTemplate.opsForZSet().add(QUEUE_KEY, userId.toString(), skillRating);
    }
    
    public void leaveQueue(Long userId) {
        redisTemplate.opsForZSet().remove(QUEUE_KEY, userId.toString());
    }
    
    @Scheduled(fixedRate = 5000)  // cada 5 segundos
    public void processMatchmaking() {
        // Obtener todos los jugadores en la cola
        Set<String> players = redisTemplate.opsForZSet().range(QUEUE_KEY, 0, -1);
        // ... lógica de matching
    }
}
```

**GATE 3 — Notificar al Equipo B cuando PASO_S07_01 + PASO_S07_02 estén listos.**

---

### PASO_S08_04 — Mercado Pago
**Duración:** 4–5 h | **Ejecuta:** Dev del Equipo C | **S8 / GATE 5**

> **Requiere:** PASO_S08_01 terminado (para crear sobres al procesar el pago).

```
# Prompt: cargar PASO_S08_04.md + SCHEMA_BD.sql bloque V6 + 
#         CODEMON_GUIAS_TECNICAS.md sección "Sistema de Pagos"
```

**Pasos para obtener las credenciales de sandbox:**
1. Ir a `developers.mercadopago.com`
2. Crear una cuenta de test (buyer y seller separados)
3. Copiar el `TEST-access-token` al `.env` como `MP_ACCESS_TOKEN`
4. Usar tarjeta de test: número `4509 9535 6623 3704`, CVV `123`, vencimiento `11/25`

**La idempotencia es obligatoria — no negociable:**
```java
// ❌ INCORRECTO — puede procesar el mismo webhook dos veces
@PostMapping("/webhooks/mercado-pago")
public void processWebhook(@RequestBody Map<String, Object> payload) {
    String mpEventId = payload.get("data").get("id").toString();
    // Procesar directamente...
    walletService.creditCoins(userId, amount);  // ← puede ejecutarse 2 veces si MP reintenta
}

// ✅ CORRECTO — verificar idempotencia PRIMERO
@PostMapping("/webhooks/mercado-pago")
public void processWebhook(@RequestBody Map<String, Object> payload) {
    String mpEventId = extractEventId(payload);
    
    if (webhookLogRepository.existsByMpEventId(mpEventId)) {
        return;  // Ya procesado — MP está reintentando
    }
    
    // Insertar en log ANTES de procesar
    webhookLogRepository.save(new WebhookLog(mpEventId));
    
    // Ahora sí procesar
    if ("approved".equals(getPaymentStatus(mpEventId))) {
        walletService.creditCoins(userId, amount);
    }
}
```

**GATE 5 — Notificar al Equipo B cuando esté listo.**

---

### PASO_S09_02 — Sistema de amigos
**Duración:** 4–5 h | **Ejecuta:** Dev del Equipo C | **S9 / GATE 6**

> **Requiere:** Equipo A PASO_S01_01 (JWT auth).

```
# Prompt: cargar PASO_S09_02.md + SCHEMA_BD.sql tabla friendships
```

La tabla `friendships` tiene una restricción `UNIQUE(requester_id, receiver_id)` y un `CHECK(requester_id != receiver_id)`. El servicio debe manejar correctamente el caso donde A envía solicitud a B y B intenta enviar solicitud a A (son la misma relación).

---

### PASO_S09_01 — Sistema de ligas (requiere GATE 2, cierra en GATE 6)
**Duración:** 2–3 h | **Ejecuta:** Dev del Equipo C | **S9 / GATE 6**

> **Requiere:** Equipo A PASO_S05_03 (GameEngine completo — GATE 2).

```
# Prompt: cargar PASO_S09_01.md + SCHEMA_BD.sql tabla ranking_history
```

Las ligas son:
- **BRONCE:** 0–999 puntos Elo
- **PLATA:** 1000–1499 puntos
- **ORO:** 1500+ puntos

Al terminar una partida, el `GameEngine` del Equipo A llama a `LeagueService.recordResult(gameId, winnerId, loserId)`, que:
1. Calcula los puntos de Elo ganados/perdidos
2. Guarda en `ranking_history`
3. Actualiza `skill_ratings`
4. Refresca la vista materializada `leaderboard`

---

### PASO_S08_05 — Grafana + métricas
**Duración:** 3–4 h | **Ejecuta:** Dev del Equipo C | **S8 / GATE 5**

```
# Cargar: MONITOREO.md completo + prometheus.yml + grafana-datasource.yml
```

**Métricas custom a registrar desde Spring Boot:**
```java
@Service
@RequiredArgsConstructor
public class GameMetricsService {
    private final MeterRegistry meterRegistry;
    
    // Contador de partidas iniciadas
    public void recordGameStarted(String matchType) {
        meterRegistry.counter("codemon.games.started",
            "matchType", matchType).increment();
    }
    
    // Duración de partida
    public void recordGameDuration(long durationSeconds) {
        meterRegistry.timer("codemon.games.duration")
            .record(durationSeconds, TimeUnit.SECONDS);
    }
    
    // Gauge de jugadores en cola
    public void updateQueueSize(int size) {
        meterRegistry.gauge("codemon.matchmaking.queue.size", size);
    }
}
```

**Dashboard sugerido en Grafana:**
1. Partidas activas en este momento
2. Partidas por hora (últimas 24h)
3. Tamaño de la cola de matchmaking
4. Usuarios conectados por WebSocket
5. Tiempo promedio de partida
6. Tasa de pagos exitosos vs. fallidos

**Acceso a Grafana:** `http://localhost:3000` — usuario: `admin`, contraseña: `codemon123`

---

### PASO_S10_01 — OAuth2 (Google + GitHub)
**Duración:** 5–7 h | **Ejecuta:** Dev del Equipo C | **S10 / GATE 7**

```
# Prompt: cargar PASO_S10_01.md + SCHEMA_BD.sql tabla user_oauth_accounts + 
#         CODEMON_GUIAS_TECNICAS.md sección OAuth2
```

**Configurar credenciales de Google:**
1. Ir a `console.cloud.google.com` → Credenciales → Crear ID de cliente OAuth
2. Tipo: `Aplicación web`
3. URI de redirección autorizada: `http://localhost:8088/login/oauth2/code/google`
4. Copiar `client-id` y `client-secret` al `.env`

**Configurar credenciales de GitHub:**
1. Ir a `github.com/settings/developers` → New OAuth App
2. Homepage URL: `http://localhost:8088`
3. Callback URL: `http://localhost:8088/login/oauth2/code/github`
4. Copiar `client-id` y `client-secret`

**application.yml (OAuth2):**
```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          google:
            client-id: ${GOOGLE_CLIENT_ID}
            client-secret: ${GOOGLE_CLIENT_SECRET}
            scope: email, profile
          github:
            client-id: ${GITHUB_CLIENT_ID}
            client-secret: ${GITHUB_CLIENT_SECRET}
            scope: user:email
```

---

## 6. ESTIMACIÓN DE TIEMPO DETALLADA

| Paso | Horas mín | Horas máx | Etapa | Observaciones |
|------|-----------|-----------|-------|---------------|
| PASO_S00_01 (reunión) | 3 | 4 | 0 | Conjunto |
| PASO_S00_02 (herramientas) | 0.5 | 0.5 | 0 | |
| PASO_S00_03 (Docker) | 1 | 2 | 0 | Gate 0 |
| PASO_S08_02 (leaderboard) | 2 | 3 | 1 | Gate 1c |
| PASO_S09_03 (noticias) | 2 | 3 | 1 | Gate 1c |
| PASO_S08_03 (2FA email) | 4 | 5 | 1 | Equipo A lo integra |
| PASO_S08_01 (sobres) | 3 | 4 | 1-2 | |
| PASO_S07_01 (salas) | 3 | 4 | 2 | Gate 3 parcial |
| PASO_S07_02 (matchmaking) | 5 | 7 | 2 | Gate 3 completo |
| PASO_S08_04 (Mercado Pago) | 4 | 5 | 2 | Gate 4 |
| PASO_S09_02 (amigos) | 4 | 5 | 2 | |
| PASO_S09_01 (ligas) | 2 | 3 | 3 | Requiere Gate 5 |
| PASO_S10_01 (OAuth2) | 5 | 7 | 3 | |
| PASO_S08_05 (Grafana) | 3 | 4 | 3 | |
| Review de seguridad | 2 | 2 | 3 | Rate limiting, CORS |
| **TOTAL** | **43** | **58** | | Media: ~50h |

---

## 7. ORDEN RECOMENDADO DE EJECUCIÓN

El Equipo C tiene mucha libertad en el orden porque la mayoría de sus features son independientes. Este orden maximiza la utilidad para los otros equipos:

```
Día 1:   PASO_S00_01 + PASO_S00_02 + PASO_S00_03   (infra lista para todos)
Día 2:   PASO_S08_02 + PASO_S09_03              (Gate 1c — desbloquea Equipo B)
Día 3:   PASO_S08_03                          (2FA que Equipo A necesita integrar)
Días 4-5: PASO_S08_01                         (base para pagos)
Días 5-6: PASO_S07_01 → PASO_S07_02             (Gate 3 — Lobby real para Equipo B)
Días 6-7: PASO_S08_04                         (Gate 4 — Shop real para Equipo B)
Día 7-8: PASO_S09_02                          (amigos)
Día 9:   PASO_S09_01 (esperar Gate 5)
Día 9-10: PASO_S10_01                         (OAuth2)
Día 10:  PASO_S08_05                          (Grafana — solo requiere que la app esté corriendo)
Día 10:  Review de seguridad
```

---

## 8. GATES QUE PRODUCE EL EQUIPO C

| Gate | Pasos | Qué desbloquea | Cómo verificar |
|------|-------|---------------|----------------|
| **GATE 0** | PASO_S00_03 | Todos pueden desarrollar | `docker compose ps` muestra todo healthy |
| **GATE 3** | PASO_S07_01 | Equipo B integra salas privadas | Test de crear sala + unirse |
| **GATE 4** | PASO_S07_02 | Equipo B integra matchmaking ranked | Test de matchmaking queue |
| **GATE 5** | PASO_S08_01 + PASO_S08_04 | Equipo B integra Shop real | Test de crear preferencia MP + abrir sobre |
| **GATE 6** | PASO_S09_01 + PASO_S09_02 + PASO_S09_03 | Equipo B integra social real | `GET /api/leaderboard`, ligas, amigos y news retornan datos |
| **GATE 7** | PASO_S10_01 + PASO_S11_05 | Equipo B integra OAuth2 y perfil | OAuth redirige y perfil consolidado responde |

---

## 9. DEPENDENCIAS DEL EQUIPO C DE OTROS EQUIPOS

| De quién | Qué necesita | Para qué | Cuándo llega |
|----------|-------------|----------|-------------|
| Equipo A | JWT auth (PASO_S01_01) — GATE 1a | PASO_S07_01 y PASO_S09_02 requieren usuarios autenticados | S1 |
| Equipo A | GameEngine completo (PASO_S05_03) — GATE 2 | PASO_S07_01 para iniciar partidas al completar sala / PASO_S09_01 para ligas | S5 |

---

## 10. COMANDOS DE USO DIARIO

```bash
# Estado de todos los servicios Docker
cd ~/codemon && docker compose ps

# Logs de un servicio específico
docker compose logs -f postgres
docker compose logs -f api

# Reiniciar un servicio
docker compose restart redis

# Ver qué hay en Redis
redis-cli -h localhost -p 6379
> KEYS *              # ver todas las claves
> ZRANGE matchmaking:queue 0 -1 WITHSCORES  # ver cola de matchmaking
> DEL matchmaking:queue  # limpiar la cola

# Conectar a PostgreSQL
docker exec -it codemon_postgres psql -U codemon_user -d codemon_db
# Comandos útiles:
# \dt             → listar tablas
# \d leaderboard  → describir la vista
# SELECT * FROM leaderboard LIMIT 5;
# REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard;
# \q              → salir

# Correr tests del Equipo C
cd ~/codemon/api && ./mvnw test -Dtest="RoomService*,Matchmaking*,Payment*"

# Ver métricas de Prometheus (desarrollo)
curl http://localhost:8088/actuator/prometheus | grep codemon

# Acceder a Grafana
open http://localhost:3000  # admin / codemon123

# Reset completo de infra (⚠️ borra todos los datos)
docker compose down -v && docker compose up -d
```

---

## 11. REGLAS DE TRABAJO INTERNO DEL EQUIPO C

1. **La idempotencia en webhooks es obligatoria.** Un pago aprobado que se procesa dos veces significa dinero o coins dobles.
2. **No modificar `docker-compose.yml` sin consultar a los otros equipos.** Cualquier cambio de puerto o configuración rompe el entorno de todos.
3. **Las migraciones de Flyway son permanentes.** Si hay que cambiar algo ya migrado, crear una nueva migración.
4. **Redis es volátil.** No guardar nada en Redis que no se pueda reconstruir (la cola de matchmaking puede vaciarse sin problema — los jugadores se re-encolan).
5. **El Equipo C notifica inmediatamente** cuando Docker está listo (GATE 0) porque los otros equipos lo necesitan para sus tests.
6. **Probar el webhook de MercadoPago en sandbox** antes de declarar PASO_S08_04 terminado. Un webhook no probado no está terminado.

---

## 12. SEÑALES DE ALERTA

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| `@Scheduled` no ejecuta | Falta `@EnableScheduling` en clase de configuración | Agregar `@EnableScheduling` a `CodemonApiApplication.java` |
| Mismo webhook procesado dos veces | No verificaste idempotencia antes de procesar | Insertar en `payment_webhooks_log` ANTES de acreditar coins |
| Redis devuelve null en el matchmaking | Clave de Redis diferente entre `add` y `range` | Verificar que `QUEUE_KEY` sea la misma constante en todos los métodos |
| Salas no expiran | `@Scheduled` no encuentra el method o hay error silencioso | Ver logs de la app; verificar que no hay exception swallowed |
| OAuth2 redirige a 404 | URI de callback no registrada en Google/GitHub Console | Agregar `http://localhost:8080/login/oauth2/code/google` en el portal |
| `REFRESH MATERIALIZED VIEW` bloquea tablas | Sin `CONCURRENTLY` | Siempre usar `REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard` |
| Email no llega en producción | Gmail bloquea "apps menos seguras" | Usar App Password (no la contraseña normal de Gmail) |
| `Flyway migration checksum mismatch` | Editaste un archivo SQL ya ejecutado | Crear nueva migración, no modificar la existente |

---

## 13. SEGURIDAD — CHECKLIST ANTES DE ETAPA 4

El Equipo C lidera la review de seguridad antes del QA final:

```
Rate Limiting (Bucket4j):
□ POST /api/auth/login → máx 5 intentos por IP en 15 minutos
□ POST /api/auth/register → máx 3 registros por IP por hora
□ POST /api/auth/verify-email → máx 3 intentos por código (ya en la lógica del servicio)

Exposición de datos:
□ POST /api/payments/webhook es público y SIN autenticación JWT (MP lo llama directamente)
□ GET /api/cards es público (no requiere autenticación para ver el catálogo)
□ Ningún endpoint expone contraseñas ni refresh tokens en respuestas de error

CORS:
□ `CORS_ALLOWED_ORIGINS` en .env solo incluye los dominios del frontend
□ En producción: `http://localhost:4200` NO está en la lista de origins permitidos

Headers de seguridad (Spring Security defaults):
□ X-Frame-Options: DENY
□ X-Content-Type-Options: nosniff
□ Content-Security-Policy configurado
```
