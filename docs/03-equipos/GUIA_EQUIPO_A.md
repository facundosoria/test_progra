# GUÍA COMPLETA — EQUIPO A: Backend Core (Motor de Juego)
**Proyecto:** Codemon TCG  
**Rol del equipo:** Construir el núcleo del sistema — autenticación, dominio de cartas y mazos, y el motor de juego completo con WebSocket  
**Composición recomendada:** 2 desarrolladores backend senior  
**Tiempo total estimado:** 75–80 horas de trabajo  
**Archivos de referencia:** [README.md](../02-planificacion/README.md) · [EQUIPOS.md](../02-planificacion/04_proceso/EQUIPOS.md)

> Nota de estructura: los archivos referenciados a lo largo de esta guia (`CONVENCIONES.md`, `SCHEMA_BD.sql`, `GLOSARIO.md`, `PATRONES_DISENO.md`, etc.) viven en `docs/` organizados por tema. Para mapear cada archivo a su carpeta exacta, ver [docs/INDICE.md](../INDICE.md). Para el workflow con IA, ver [docs/08-desarrollo-con-ia/README.md](../08-desarrollo-con-ia/README.md).

---

## 1. CONOCIMIENTOS PREVIOS OBLIGATORIOS

Antes de escribir una sola línea de código, ambos integrantes del equipo deben dominar los siguientes temas. No son "buenos para tener" — sin estos conocimientos el proyecto fallará.

### Java 21
- [ ] Records (`record GameAction(...)`) — se usan ampliamente como DTOs inmutables
- [ ] Sealed classes / Pattern matching — no se usan directamente, pero el código del motor los referencia
- [ ] `var` y streams — el motor usa streams para filtrar cartas del mazo
- [ ] `UUID.randomUUID()` — cada `InPlayPokemon` tiene un `instanceId` UUID (CRÍTICO — no confundir con `cardId`)

### Spring Boot 3.3.x
- [ ] `@Service`, `@Repository`, `@Controller`, `@RestController`
- [ ] Inyección por constructor con `@RequiredArgsConstructor` (Lombok) — **nunca `@Autowired` en campos**
- [ ] `@Transactional` — cuándo usarlo y en qué capa (Service, no Controller)
- [ ] `@Scheduled` — para el cleanup de salas expiradas (no aplica a este equipo directamente pero el contexto importa)
- [ ] Spring Actuator + Prometheus Micrometer (para métricas)

### Spring Security 6 + JWT
- [ ] `SecurityFilterChain` con `HttpSecurity`
- [ ] `OncePerRequestFilter` para validar JWT en cada request
- [ ] `jjwt 0.12.x` — generar y validar tokens (`Jwts.builder()`, `Jwts.parserBuilder()`)
- [ ] Diferencia entre `accessToken` (corto, stateless) y `refreshToken` (largo, en BD)
- [ ] Rutas públicas vs. protegidas en `SecurityConfig`

### JPA + Flyway
- [ ] `@Entity`, `@Table`, `@Column`, `@ManyToOne`, `@OneToMany`, `@Enumerated`
- [ ] `@CreationTimestamp`, `@UpdateTimestamp` (Hibernate)
- [ ] `JpaRepository<T, ID>` y consultas JPQL personalizadas
- [ ] Flyway: naming convention `V1__nombre.sql`, **nunca modificar migraciones ya ejecutadas**
- [ ] `ddl-auto: validate` — Flyway crea el schema, JPA solo lo valida

### Patrones de diseño (LEER COMPLETO `PATRONES_DISENO.md` antes de la cadena de motor S3-S5)
- [ ] **STATE** — cada fase del turno es una clase que implementa `GameState`
- [ ] **STRATEGY** — efectos de ataques (veneno, quemadura, parálisis) son estrategias intercambiables
- [ ] **CHAIN OF RESPONSIBILITY** — el AttackPipeline son 9 handlers encadenados
- [ ] **OBSERVER** — `GameEventPublisher` emite eventos que escuchan WebSocket, log y métricas
- [ ] **FACADE** — `GameEngine` es la única entrada desde los controllers; oculta toda la complejidad interna
- [ ] **REPOSITORY** — Spring Data JPA; una interfaz por entidad

### WebSocket STOMP
- [ ] Configurar `WebSocketMessageBrokerConfigurer` en Spring
- [ ] Diferencia entre `/topic/` (broadcast) y `/queue/` (punto a punto)
- [ ] `SimpMessagingTemplate` para enviar mensajes desde el servidor
- [ ] Autenticación en WebSocket (cómo inyectar el JWT en el handshake)

### Reglas del juego Codemon (LEER en este orden exacto):
> **Total de lectura: ~3 horas. No saltear. Evita 20 horas de debug.**

1. `REGLAS_INDEX.md` — 15 min
2. `01-setup.md` — 30 min
3. `02-turn-flow.md` — 30 min
4. `03-combat.md` — 45 min ← más importante
5. `04-win-conditions.md` — 15 min
6. `05-deck-validation.md` — 20 min
7. `PATRONES_DISENO.md` — 45 min ← segundo más importante
8. `GAME_ENGINE_DETALLES.md` — 45 min ← tercero más importante

---

## 2. CONOCIMIENTOS A ADQUIRIR DURANTE EL PROCESO

Estos temas se aprenden haciendo. El equipo los irá encontrando paso a paso:

- **MinIO Java SDK** — cargar imágenes de cartas (se usa en PASO_S02_02)
- **Testcontainers** — tests de integración con PostgreSQL real (se introduce en PASO_S01_01 y se profundiza en PASO_S05_03)
- **Redis + Spring Data Redis** — para la serialización del estado de matchmaking (EQUIPO C lo lidera, pero el Equipo A provee el API que Redis consume)
- **JaCoCo** — cobertura de tests. Se configura en `pom.xml` una sola vez; los tests se van acumulando
- **Swagger/OpenAPI** — las anotaciones `@Operation`, `@ApiResponse` se agregan al documentar endpoints

---

## 3. ARCHIVOS DE REFERENCIA POR PASO

> Regla: **cargá solo los archivos indicados para cada paso.** Cargar todo a la vez satura el contexto del agente de IA.

| Paso | Archivos obligatorios a cargar |
|------|-------------------------------|
| PASO_S00_01 | `06-system-logic.md`, `SCHEMA_BD.sql`, `ESPECIFICACION_PRODUCTO.md` |
| PASO_S00_04 | `CONVENCIONES.md` (el prompt es autocontenido) |
| PASO_S00_05 | `SCHEMA_BD.sql` completo |
| PASO_S02_01 | `05-deck-validation.md`, `SCHEMA_BD.sql` bloque V3 |
| PASO_S01_01 | `SCHEMA_BD.sql` bloques V1+V2, `CONVENCIONES.md` |
| PASO_S02_02 | `SCHEMA_BD.sql` bloque V1, `CARTAS_E_IMAGENES.md` |
| PASO_S02_03 | `SCHEMA_BD.sql` bloque V3, `05-deck-validation.md` |
| PASO_S03_01 | `PATRONES_DISENO.md` sección STATE, `SCHEMA_BD.sql` bloque V9 |
| PASO_S03_03 | `01-setup.md`, `PATRONES_DISENO.md` sección STATE |
| PASO_S03_04 | `02-turn-flow.md` sección Fase 1, `GAME_ENGINE_DETALLES.md` D-01 |
| PASO_S03_05 | `02-turn-flow.md` sección Fase 2 completa |
| PASO_S04_01 | `03-combat.md` sección cálculo de daño, `GAME_ENGINE_DETALLES.md` C-01 a C-03 |
| PASO_S04_02 | `03-combat.md` completo, `PATRONES_DISENO.md` sección CHAIN + STRATEGY, `GAME_ENGINE_DETALLES.md` C-01 a C-05 |
| PASO_S05_01 | `02-turn-flow.md` sección "paso entre turnos" |
| PASO_S03_02 | `04-win-conditions.md` completo |
| PASO_S05_02 | `GAME_ENGINE_DETALLES.md` sección Bot |
| PASO_S05_03 | `06-system-logic.md` completo, `PATRONES_DISENO.md` sección OBSERVER+FACADE |

---

## 4. ESTRUCTURA DE CARPETAS DEL PROYECTO

Todo el backend vive en `~/codemon/api/`. El Equipo A crea y gestiona esta carpeta completa.

```
~/codemon/
├── api/                              ← Raíz del proyecto Spring Boot (EQUIPO A)
│   ├── pom.xml
│   ├── Dockerfile                    ← Copiar de Dockerfile.api de la raíz del proyecto
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/codemon/
│   │   │   │   ├── CodemonApiApplication.java
│   │   │   │   ├── auth/             ← PASO_S01_01 (JWT + seguridad)
│   │   │   │   │   ├── entity/
│   │   │   │   │   ├── repository/
│   │   │   │   │   ├── dto/
│   │   │   │   │   ├── service/
│   │   │   │   │   └── controller/
│   │   │   │   ├── cards/            ← PASO_S02_02 (catálogo + MinIO)
│   │   │   │   ├── decks/            ← PASO_S02_01 + PASO_S02_03
│   │   │   │   ├── game/             ← motor S3-S5
│   │   │   │   │   ├── controller/
│   │   │   │   │   ├── engine/
│   │   │   │   │   │   ├── GameState.java (interfaz)
│   │   │   │   │   │   ├── GameContext.java
│   │   │   │   │   │   ├── GameEngine.java (Facade)
│   │   │   │   │   │   ├── GameAction.java
│   │   │   │   │   │   ├── ActionType.java
│   │   │   │   │   │   ├── GameActionResult.java
│   │   │   │   │   │   ├── GameEvent.java
│   │   │   │   │   │   ├── model/    ← InPlayPokemon, PlayerBoard, GameBoard, StatusCondition
│   │   │   │   │   │   ├── state/    ← SetupState, DrawPhaseState, MainPhaseState, etc.
│   │   │   │   │   │   ├── pipeline/ ← AttackPipeline + 9 handlers
│   │   │   │   │   │   ├── strategy/ ← AttackEffectStrategy + implementaciones
│   │   │   │   │   │   └── observer/ ← GameEventPublisher + listeners
│   │   │   │   │   └── websocket/    ← PASO_S05_03 configuración WebSocket
│   │   │   │   ├── users/            ← Perfil y wallet
│   │   │   │   └── shared/           ← Seguridad, excepciones, configs
│   │   │   └── resources/
│   │   │       ├── application.yml   ← PASO_S00_04
│   │   │       └── db/migration/     ← PASO_S00_05 (Flyway V1 a V15)
│   │   └── test/
│   │       └── java/com/codemon/
│   │           ├── auth/
│   │           ├── decks/
│   │           └── game/engine/
└── front/                            ← Manejado por EQUIPO B
```

---

## 5. INSTRUCCIONES DE EJECUCIÓN — PASO A PASO

### PASO 0.0 — Contratos de API (TODOS juntos — Equipo A lidera)
**Duración:** 3–4 h | **Participan:** Los 3 equipos

**Rol del Equipo A:**
1. Presentar los modelos de `SCHEMA_BD.sql` a los otros equipos (cada tabla, sus campos, sus relaciones)
2. Definir los DTOs de request/response para cada endpoint (basarse en `ESPECIFICACION_PRODUCTO.md`)
3. Presentar `06-system-logic.md` y responder preguntas del Equipo B sobre los eventos WebSocket
4. Revisar y aprobar los JSON de mock generados por el Equipo B en `MOCKS_FRONTEND.md`
5. Firmar el documento final `CONTRATOS_API.md`

**Output obligatorio antes de avanzar:**
- `CONTRATOS_API.md` — revisado y aprobado por Equipo A
- `PROTOCOLO_WEBSOCKET.md` — escrito por Equipo A
- `MOCKS_FRONTEND.md` — validado por Equipo A

---

### PASO 0.3 — Proyecto Spring Boot
**Duración:** 1–2 h | **Ejecuta:** Dev 1 del Equipo A

```bash
# 1. Ir a start.spring.io y configurar:
#    Maven | Java 21 | Spring Boot 3.3.x
#    Group: com.codemon | Artifact: api
#    Dependencies: Spring Web, Spring Data JPA, Spring Security, 
#    Spring Boot Actuator, Validation, Lombok, PostgreSQL Driver,
#    Flyway Migration, Spring Data Redis, WebSocket, Java Mail Sender

# 2. Descomprimir en ~/codemon/api/

# 3. Copiar el Dockerfile
cp docs/07-infraestructura/Dockerfile.api ~/codemon/api/Dockerfile

# 4. Usar el prompt de PASO_S00_04.md para generar application.yml
# 5. Agregar dependencias extra al pom.xml (JWT, Swagger, MinIO, etc.)

# 6. Verificar compilación
cd ~/codemon/api && ./mvnw clean compile
# Esperado: BUILD SUCCESS
```

**⚠️ ALERTA:** `JWT_SECRET` debe tener al menos 32 caracteres. Valor por defecto en desarrollo: `dev_secret_cambiar_en_prod_min32chars`

---

### PASO 0.4 — Migraciones Flyway
**Duración:** 2–3 h | **Ejecuta:** Dev 2 del Equipo A (mientras Dev 1 hace 0.3)

```bash
# 1. Cargar SCHEMA_BD.sql completo en el agente de IA junto al prompt de PASO_S00_05.md
# 2. El agente genera los archivos V1__xxx.sql a V15__xxx.sql
# 3. Ubicarlos en: api/src/main/resources/db/migration/
# 4. Verificar que Docker esté levantado
cd ~/codemon && docker compose up postgres redis minio minio_setup -d
# 5. Ejecutar migraciones
cd ~/codemon/api && ./mvnw flyway:migrate
# 6. Verificar tablas
docker exec -it codemon_postgres psql -U codemon_user -d codemon_db -c "\dt"
# Deben aparecer las 22 tablas
```

**REGLA DE ORO DE FLYWAY:** Una migración ejecutada **nunca se modifica**. Si cometiste un error, créa una nueva migración `V16__fix_xxx.sql` que corrija el problema. Modificar un archivo ya ejecutado causa `Migration checksum mismatch` y requiere `docker compose down -v` (borrás todo).

---

### PASO 1.1 — DeckValidationService
**Duración:** 3–4 h | **Ejecuta:** Dev 1 o Dev 2

```
# Prompt: cargar PASO_S02_01.md + 05-deck-validation.md + bloque V3 de SCHEMA_BD.sql
```

**Las 6 reglas a validar (todas en simultáneo — no fallar en la primera y parar):**
1. Exactamente 60 cartas
2. Mínimo 1 Pokémon Básico
3. Máximo 4 copias del mismo nombre (excepto Energía Básica: ilimitada)
4. Máximo 4 Energías Especiales
5. Máximo 1 carta ACE SPEC

**Test obligatorio:** El método `validate()` debe retornar **todos** los errores a la vez, no solo el primero.

---

### PASO 1.2 — JWT + Autenticación
**Duración:** 4–6 h | **Ejecuta:** Dev 1 (preferiblemente el más familiarizado con Spring Security)

```
# Prompt: cargar PASO_S01_01.md + CONVENCIONES.md + bloques V1+V2 de SCHEMA_BD.sql
```

**GATE 1a — Punto de entrega al Equipo B:**
Cuando estos endpoints estén funcionando, notificar al Equipo B para que integre auth real:
```bash
# Test rápido de que JWT funciona:
curl -X POST http://localhost:8088/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.com","password":"Test1234!"}'

curl -X POST http://localhost:8088/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usernameOrEmail":"test@test.com","password":"Test1234!"}'
# Debe retornar accessToken + refreshToken
```

**⚠️ Nota importante:** En este paso, `email_verified = TRUE` por defecto (el 2FA real se agrega en PASO_S08_03 por Equipo C). No bloquear registro por email.

---

### PASO 1.3 — Catálogo de cartas + MinIO
**Duración:** 5–7 h | **Ejecuta:** Dev 2 (mientras Dev 1 hace PASO_S01_01)

```
# Prompt: cargar PASO_S02_02.md + CARTAS_E_IMAGENES.md + bloque V1 de SCHEMA_BD.sql
```

El agente genera:
1. La entidad `Card.java` con todos los campos JSONB como `@Type(JsonBinaryType.class)`
2. El script de seed de 146 cartas leyendo `api/src/main/resources/seed/cards.json`, que es copia de `docs/05-referencia-tecnica/xy1.json`
3. `MinioService.java` para subir imágenes al bucket `codemon-cards`
4. `CardController.java` con paginación y filtros

**GATE 1b — Punto de entrega al Equipo B:**
```bash
# Test de que GET /api/cards devuelve cartas con imágenes:
TOKEN="eyJ..."
curl -H "Authorization: Bearer $TOKEN" http://localhost:8088/api/cards?page=0&size=10
# Debe retornar 10 cartas con imageSmallUrl apuntando a MinIO
```

---

### PASO 1.4 (backend) — Deck Builder CRUD
**Duración:** 2–3 h | **Ejecuta:** Dev 1 o Dev 2

```
# Prompt: cargar PASO_S02_03.md + bloque V3 de SCHEMA_BD.sql + DeckValidationService ya implementado
```

Este paso crea la parte backend del Deck Builder. El Equipo B hace la parte frontend simultáneamente.

**Test de integración completo:**
```bash
TOKEN="eyJ..."
# Crear mazo
DECK=$(curl -X POST http://localhost:8088/api/decks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","cards":[{"cardId":"xy1-96","quantity":60}]}')
DECK_ID=$(echo $DECK | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")

# Validar mazo (debe fallar por no tener Pokémon básico)
curl -X POST http://localhost:8088/api/decks/$DECK_ID/validate \
  -H "Authorization: Bearer $TOKEN"
# {"valid":false,"errors":["El mazo debe contener al menos 1 Pokémon Básico"]}
```

---

### PASO 2.0 — GameContext + State Machine (andamiaje)
**Duración:** 2–3 h | **Ejecuta:** Dev 1

> **ALTO:** Antes de este paso, AMBOS devs deben haber leído `PATRONES_DISENO.md` completo y los 6 documentos de reglas. Sin eso no continuar.

```
# Prompt: cargar PASO_S03_01.md + sección STATE de PATRONES_DISENO.md + bloque V9 de SCHEMA_BD.sql
```

**El `instanceId` de `InPlayPokemon` es CRÍTICO:**
```java
// ✅ CORRECTO — cada Pokémon en juego tiene su propio ID único
String instanceId = UUID.randomUUID().toString();

// ❌ INCORRECTO — puede haber 2 Charizard-EX en juego al mismo tiempo
// Nunca usar cardId como identificador de estado en juego
```

**Test obligatorio después de este paso:**
```bash
./mvnw test -pl api -Dtest=GameContextTest
# BUILD SUCCESS, 2 tests pasando
```

---

### PASO 2.1 — SetupState
**Duración:** 5–7 h | **Ejecuta:** Dev 2 (Dev 1 puede hacer PASO_S02_03 o empezar a leer reglas de combate)

```
# Prompt: cargar PASO_S03_03.md + 01-setup.md completo
```

**Lógica del mulligan (crítica, difícil de debuggear):**
- Si **ambos** jugadores no tienen básico → ambos barajean y roban nueva mano (sin penalización)
- Si **solo uno** no tiene básico → ese jugador baraja y roba; el **oponente** roba 1 carta extra por cada mulligan adicional
- El jugador inicial **no puede atacar** en su primer turno: `ctx.firstTurnAttackBlocked = true`

---

### PASO 2.2 — DrawPhaseState
**Duración:** 1–2 h | **Ejecuta:** Dev 1 o Dev 2

```
# Prompt: cargar PASO_S03_04.md + sección Fase 1 de 02-turn-flow.md + D-01 de GAME_ENGINE_DETALLES.md
```

**Caso borde crítico:** Si el mazo del jugador está vacío cuando debe robar → `GAME_OVER` con reason `DECK_EMPTY`. Este es uno de los tres caminos de victoria.

---

### PASO 2.3 — MainPhaseState (el más largo del bloque)
**Duración:** 8–10 h | **Ejecuta:** Ambos devs colaborando

```
# Prompt: cargar PASO_S03_05.md + sección Fase 2 de 02-turn-flow.md completa
```

**Las 6 acciones del turno principal (cada una con sus restricciones):**

| Acción | Restricción |
|--------|-------------|
| Jugar Pokémon Básico | Máx 5 en Banca; solo desde la mano |
| Evolucionar Pokémon | No en el mismo turno que fue jugado; `turnsInPlay >= 1` |
| Adjuntar Energía | **Máx 1 por turno**; verificar `energyAttachedThisTurn` |
| Jugar Trainer | Item: ilimitados; Supporter: **máx 1** (`supporterPlayedThisTurn`); Stadium: reemplaza el anterior |
| Retirar Pokémon | **Máx 1 por turno** (`retreatedThisTurn`); mover energías a Banca al retirar |
| Usar Habilidad | Según carta; puede tener restricciones propias |

**Test obligatorio:**
```bash
./mvnw test -pl api -Dtest=MainPhaseStateTest
```

---

### PASO 2.4 — DamageCalculator + StatusEffectManager
**Duración:** 4–6 h | **Ejecuta:** Dev 2 (mientras Dev 1 termina/refina PASO_S03_05)

```
# Prompt: cargar PASO_S04_01.md + sección cálculo de daño de 03-combat.md + C-01 a C-03 de GAME_ENGINE_DETALLES.md
```

**Pipeline de cálculo de daño (orden estricto):**
1. `baseDamage` del ataque
2. Si `isDirect` → no aplica debilidad ni resistencia (saltar pasos 3 y 4)
3. Debilidad: `×2` si el tipo del atacante coincide con la debilidad del defensor
4. Resistencia: `-20` si el tipo del atacante coincide con la resistencia del defensor
5. Efectos adicionales del atacante
6. Reducción del defensor

**Test obligatorio — cobertura ≥ 90%:**
```bash
./mvnw test -pl api -Dtest=DamageCalculatorTest
```

---

### PASO 2.5 — AttackPipeline (EL MÁS DIFÍCIL — 12–15 h)
**Duración:** 12–15 h | **Ejecuta:** AMBOS devs juntos

> ⚠️ **Este es el paso más complejo del proyecto.** Leer `C-01` a `C-05` de `GAME_ENGINE_DETALLES.md` antes de empezar. No saltear ninguna sección.

```
# Prompt: cargar PASO_S04_02.md + 03-combat.md completo + 
#         secciones CHAIN + STRATEGY de PATRONES_DISENO.md + 
#         C-01 a C-05 de GAME_ENGINE_DETALLES.md
```

**Los 9 handlers en orden estricto:**
```
Handler 1: ValidateAttackHandler      → ¿Puede atacar? (dormido, paralizado, primer turno, energías, confuso)
Handler 2: CalculateBaseDamageHandler → parseDamage(), detectar isDirect
Handler 3: ApplyAttackerEffectsHandler→ bonuses del atacante
Handler 4: ApplyWeaknessHandler       → ×2 si aplica (SKIP si isDirect)
Handler 5: ApplyResistanceHandler     → -20 si aplica (SKIP si isDirect)
Handler 6: ApplyDefenderEffectsHandler→ reducciones del defensor
Handler 7: DealDamageHandler          → defender.damage += finalDamage; emitir DAMAGE_DEALT
Handler 8: ExecuteAttackEffectHandler → resolver estrategia de efecto del ataque
Handler 9: CheckKnockoutHandler       → defender.hp <= 0 → procesar KO y premios
```

**Casos borde del KO (implementar exactamente así):**
```java
// ✅ El RIVAL (atacante) toma premios de SU PROPIO tablero de premios
String prize = rivalBoard.prizes.remove(0); // de las prizes del atacante
rivalBoard.hand.add(prize);
rivalBoard.prizesCount--;

// ✅ Pokémon-EX o Mega EX entregan 2 premios, no 1
int prizesToTake = isPokemonEXorMEGA(defender) ? 2 : 1;

// ✅ Verificar victoria INMEDIATAMENTE después de tomar premios
if (rivalBoard.prizesCount == 0) → GAME_OVER (PRIZES)
```

**Test crítico — cobertura ≥ 90%:**
```bash
./mvnw test -pl api -Dtest=AttackPipelineTest
```

---

### PASO 2.6 — EndPhaseState
**Duración:** 3–4 h | **Ejecuta:** Dev 1 o Dev 2

```
# Prompt: cargar PASO_S05_01.md + sección "paso entre turnos" de 02-turn-flow.md
```

**Orden de resolución entre turnos (fijo, no alterar):**
1. Veneno → daño automático 10 HP
2. Quemado → tirar moneda: cara = 20 HP de daño; cruz = marcador permanece
3. Dormido → tirar moneda: cara = despierta; cruz = sigue dormido
4. Paralizado → la condición expira automáticamente al inicio del siguiente turno
5. Verificar KOs por daño residual

---

### PASO 2.7 — VictoryConditionChecker
**Duración:** 2–3 h | **Ejecuta:** Dev 2

```
# Prompt: cargar PASO_S03_02.md + 04-win-conditions.md completo
```

**Las 3 condiciones de victoria:**
1. `prizesCount == 0` → ganó el que tomó todos los premios
2. `deck.isEmpty() AND hand.isEmpty()` → pierde el que no puede robar al inicio de su turno
3. `active == null AND bench.isEmpty()` → pierde el que queda sin Pokémon en juego

**Muerte súbita:** Si ambas condiciones se cumplen simultáneamente → nueva partida con 1 premio por jugador.

---

### PASO 2.8 — Bot IA
**Duración:** 3–5 h | **Ejecuta:** Dev 1

```
# Prompt: cargar PASO_S05_02.md + sección Bot de GAME_ENGINE_DETALLES.md
```

**3 niveles de dificultad:**
- `EASY` — acciones completamente aleatorias entre las válidas
- `MEDIUM` — heurísticas básicas (atacar si puede, jugar el Pokémon con más HP)
- `HARD` — minimax simplificado (bonus)

**3 personalidades (solo afectan delay y mensajes de chat):**
- `HERNAN` — agresivo, mucho texto en chat
- `SANTORO` — silencioso y calculador
- `RAMIRO` — errático, a veces pasa turno sin razón

---

### PASO 2.9 — GameEngine completo + WebSocket (GATE 2)
**Duración:** 3–5 h | **Ejecuta:** Ambos devs

```
# Prompt: cargar PASO_S05_03.md + 06-system-logic.md completo + 
#         secciones OBSERVER + FACADE de PATRONES_DISENO.md
```

> **Este paso produce el GATE 2 — el output más esperado por el Equipo B.**  
> Notificar inmediatamente al Equipo B cuando el WebSocket esté funcionando.

**Configuración WebSocket mínima:**
```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*")
                .withSockJS();
    }
    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic", "/queue");
        config.setApplicationDestinationPrefixes("/app");
        config.setUserDestinationPrefix("/user");
    }
}
```

**Test del GameEngine completo:**
```bash
# Iniciar partida PvE y jugar un turno completo:
TOKEN="eyJ..."
GAME=$(curl -X POST http://localhost:8088/api/games/pve \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"deckId":1,"botDifficulty":"EASY","botPersonality":"HERNAN"}')
echo $GAME  # {"gameId":"...","status":"SETUP","webSocketTopic":"/topic/game/..."}
```

---

## 6. ESTIMACIÓN DE TIEMPO DETALLADA

| Paso | Dev asignado | Horas mín | Horas máx | Observaciones |
|------|-------------|-----------|-----------|---------------|
| PASO_S00_01 | Ambos | 3 | 4 | Reunión conjunta |
| PASO_S00_04 | Dev 1 | 1 | 2 | Paralelo con 0.4 |
| PASO_S00_05 | Dev 2 | 2 | 3 | Paralelo con 0.3 |
| PASO_S02_01 | Indistinto | 3 | 4 | |
| PASO_S01_01 | Dev 1 | 4 | 6 | Gate 1a |
| PASO_S02_02 | Dev 2 | 5 | 7 | Gate 1b |
| PASO_S02_03 (be) | Indistinto | 2 | 3 | |
| PASO_S03_01 | Dev 1 | 2 | 3 | Base de todo el motor |
| PASO_S03_03 | Dev 2 | 5 | 7 | |
| PASO_S03_04 | Indistinto | 1 | 2 | |
| PASO_S03_05 | Ambos | 8 | 10 | El más largo del motor |
| PASO_S04_01 | Dev 2 | 4 | 6 | Cobertura ≥ 90% |
| PASO_S04_02 | **Ambos** | 12 | 15 | 🔥 NO dividir — trabajar juntos |
| PASO_S05_01 | Dev 1 | 3 | 4 | |
| PASO_S03_02 | Dev 2 | 2 | 3 | |
| PASO_S05_02 | Dev 1 | 3 | 5 | |
| PASO_S05_03 | Ambos | 3 | 5 | Gate 2 — notificar a Equipo B |
| **TOTAL** | | **63** | **89** | Media: ~76h |

---

## 7. GATES QUE ESTE EQUIPO PRODUCE

| Gate | Paso | Qué notificar al Equipo B | Cómo verificar antes de notificar |
|------|------|--------------------------|----------------------------------|
| **GATE 1a** | PASO_S01_01 | JWT funcionando: `POST /api/auth/login` retorna tokens | Correr curl de login y obtener accessToken |
| **GATE 1b** | PASO_S02_02 + 1.4 | API cartas: `GET /api/cards` con imágenes + API mazos completa | Correr curls de cartas y CRUD de mazos |
| **GATE 2** | PASO_S05_03 | WebSocket STOMP completo + GameEngine funcional | Jugar partida PvE completa de inicio a fin |
| **Dependencia de GATE 6** | PASO_S05_03 | Misma notificación del GATE 2 | Equipo C necesita el motor para integrar ligas en S9 |

**Cómo notificar:** Mensaje en el canal de comunicación del equipo con el comando de verificación que el otro equipo puede ejecutar.

---

## 8. DEPENDENCIAS DE OTROS EQUIPOS (LO QUE ESPERA EL EQUIPO A)

| De quién | Qué necesita | Para qué paso | Cuándo llega |
|----------|-------------|---------------|-------------|
| Equipo C | 2FA por email (PASO_S08_03) | Integrar en AuthService | S8 |
| Equipo C | Docker corriendo (PASO_S00_03) | Para hacer tests de integración | S0 |

---

## 9. COMANDOS DE USO DIARIO

```bash
# Levantar infra (correr SIEMPRE antes de desarrollar)
cd ~/codemon
docker compose up postgres redis minio minio_setup prometheus grafana -d

# Correr la API en modo desarrollo (hot reload)
cd ~/codemon/api && ./mvnw spring-boot:run

# Correr todos los tests
cd ~/codemon/api && ./mvnw test

# Ver cobertura (abrir en browser: api/target/site/jacoco/index.html)
cd ~/codemon/api && ./mvnw test jacoco:report

# Solo tests del motor de juego
cd ~/codemon/api && ./mvnw test -Dtest="GameContext*,AttackPipeline*,DamageCalculator*,Setup*"

# Logs en tiempo real
docker compose logs -f api

# Conectar a PostgreSQL
docker exec -it codemon_postgres psql -U codemon_user -d codemon_db
# \dt — ver tablas
# \q  — salir

# Reset de BD (⚠️ borra todo, usar solo si Flyway está roto)
docker compose down -v && docker compose up postgres redis minio minio_setup -d
```

---

## 10. REGLAS DE TRABAJO INTERNO DEL EQUIPO A

1. **Nunca pushear a `main` sin que los tests pasen.** `./mvnw test` debe dar `BUILD SUCCESS`.
2. **PASO_S04_02 se hace entre ambos.** No dividirlo ni asignarlo a un solo dev.
3. **El orden PASO_S03_01 → PASO_S03_02/03/04/05 → PASO_S04_* → PASO_S05_* es obligatorio.** No paralelizar la cadena del motor S3-S5.
4. **Cada PASO termina cuando sus tests pasan,** no cuando el código compila.
5. **Notificar a los otros equipos inmediatamente** cuando un Gate esté listo.
6. **Si una migración de Flyway ya fue ejecutada, no se toca.** Crear una nueva migración.
7. **Cobertura mínima antes de entregar:** Global ≥ 80%, `DamageCalculator` ≥ 90%, `AuthService` ≥ 85%.

---

## 11. SEÑALES DE ALERTA (bugs comunes a detectar temprano)

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| `UnsupportedOperationException` en ArrayList | Usaste `List.of()` en vez de `new ArrayList<>()` | Reemplazar en `PlayerBoard` y `GameContext` |
| 2 Pokémon del mismo tipo confundidos entre sí | Usaste `cardId` como identificador en juego | Cambiar a `instanceId` (UUID) |
| Daño de Pokémon-EX no da 2 premios | No verificar `isPokemonEX()` en `CheckKnockoutHandler` | Agregar verificación por `subtypes` |
| WebSocket funciona en dev pero no en Docker | URL hardcodeada en lugar de `environment.wsUrl` | Usar variable de entorno en el cliente |
| `Migration checksum mismatch` | Editaste un SQL ya ejecutado | `docker compose down -v` + nueva migración |
| `JWT_SECRET too short` al iniciar | Secret menor a 32 chars | Cambiar en `.env` o `application.yml` |
| Confusión: el Pokémon atacó al oponente en vez de a sí mismo | Bug en `ValidateAttackHandler` | Releer lógica de confusión en `03-combat.md` |
