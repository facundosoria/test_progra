# BD_Y_TABLAS.md - Cómo Gestionar la Base de Datos

---

## REGLAS GENERALES

Antes de tocar una sola tabla, estas 5 reglas te van a evitar el 90% de los problemas:

### 1. Flyway: NUNCA edites una migración ya ejecutada

```
V1__users.sql  ← ya ejecutada → NUNCA la toques
V2__2fa.sql    ← ya ejecutada → NUNCA la toques
V3__cards.sql  ← nueva        → esta sí podés escribir
```

Si necesitás cambiar algo de una migración vieja, creás una nueva:

```
V3_1__fix_cards_index.sql   ← para arreglar algo de V3
```

### 2. Una migración por tema/feature

```
V1__users_auth.sql       ← solo lo de auth
V2__2fa.sql              ← solo email_verifications
V3__cards.sql            ← solo cartas y sets
```

No mezcles todo en un solo archivo gigante.

### 3. Toda columna nullable debe tener razón de ser

Si no sabés si puede ser null, preguntate: "¿puede existir un registro sin este campo?". Si la respuesta es no → NOT NULL.

### 4. Siempre FK con nombre explícito

```sql
-- ❌ Mal (nombre auto-generado, difícil de debuggear)
FOREIGN KEY (user_id) REFERENCES users(id)

-- ✅ Bien (nombre explícito)
CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users(id)
```

### 5. Índices en campos que filtrás frecuentemente

```sql
-- Si hacés esto en código:
WHERE status = 'WAITING' AND user_id = 123

-- Entonces necesitás esto en BD:
CREATE INDEX idx_queue_user_status ON queue_entries(user_id, status);
```

---

## MAPA COMPLETO DE TABLAS

### Grupo 1: Autenticación

```
users
├── id, username, email, password_hash
├── email_verified (bool) ← empieza en false
├── virtual_currency_balance (int)
├── skill_rating (int, default 1000)
├── wins, losses, draws
└── created_at, updated_at

refresh_tokens
├── id, user_id (FK users)
├── token_hash, expires_at, revoked_at
└── created_at

email_verifications
├── id, user_id (FK users, UNIQUE)  ← 1 por usuario
├── code_hash, code_expires_at
├── attempts_count, blocked_until
└── created_at
```

### Grupo 2: Cartas (generado con IA desde tu JSON)

```
card_sets
├── id (PK, ej: "xy1")
├── name, series, total_cards
├── release_date
├── logo_url, symbol_url   ← URLs a MinIO
└── created_at

cards_catalog
├── id (PK, ej: "xy1-1")
├── name, number, set_id (FK card_sets)
├── supertype ("Pokémon", "Trainer", "Energy")
├── subtypes TEXT[]         ← array nativo Postgres
├── types TEXT[]            ← ["Grass", "Fire"]
├── rarity
├── hp (nullable, null si Trainer/Energy)
├── evolves_from (nullable)
├── evolves_to TEXT[] (nullable)
├── converted_retreat_cost (nullable)
├── attacks JSONB           ← [{name, cost[], damage, text}]
├── weaknesses JSONB        ← [{type, value}]
├── resistances JSONB       ← [{type, value}]
├── abilities JSONB         ← [{name, text, type}]
├── rules JSONB             ← ["When this is KO..."]
├── image_small_url         ← URL a MinIO
├── image_large_url         ← URL a MinIO
├── artist
├── national_pokedex_numbers INT[]
└── created_at
```

### Grupo 3: Mazos

```
decks
├── id, user_id (FK users, nullable para starters)
├── name, description
├── is_favorite, is_starter
└── created_at, updated_at

deck_cards
├── id
├── deck_id (FK decks)
├── card_id (FK cards_catalog)
├── quantity (CHECK > 0)
└── UNIQUE(deck_id, card_id)
```

### Grupo 4: Monetización

```
booster_packs (definición de tipos de sobres)
├── id, name, description
├── price_usd, price_coins
├── cards_per_pack (default 10)
├── rarity_distribution JSONB  ← {"COMMON": 60, "UNCOMMON": 25, "RARE": 12, "HOLO": 3}
└── created_at

booster_pack_cards (qué cartas pueden salir en cada tipo de sobre)
├── id
├── booster_pack_id (FK booster_packs)
├── card_id (FK cards_catalog)
└── rarity

user_booster_packs (sobres que posee cada usuario)
├── id
├── user_id (FK users)
├── booster_pack_id (FK booster_packs)
├── obtained_at, opened_at (null si no abrió)
└── obtained_from ("PURCHASE", "DAILY", "REWARD")

user_collection (cartas coleccionadas)
├── id
├── user_id (FK users)
├── card_id (FK cards_catalog)
├── quantity (CHECK > 0)
├── obtained_date
└── UNIQUE(user_id, card_id)

payment_records
├── id
├── user_id (FK users)
├── amount_usd, amount_coins
├── mp_preference_id, mp_transaction_id (UNIQUE)
├── status (PENDING|COMPLETED|FAILED|CANCELLED)
├── booster_pack_id (FK, nullable)
├── quantity
└── created_at, completed_at, webhook_received_at

user_payments_webhooks (log de idempotencia)
├── id
├── mp_event_id (UNIQUE) ← clave para evitar procesar dos veces
├── payload JSONB
├── processed (bool)
└── created_at, processed_at
```

### Grupo 5: Matchmaking y Lobby

```
skill_ratings
├── id
├── user_id (FK users, UNIQUE)
├── current_rating (default 1000)
├── wins, losses, total_games
└── updated_at

queue_entries
├── id
├── user_id (FK users)
├── deck_id (FK decks)
├── skill_rating (copia del rating al momento de entrar)
├── join_time
└── status (WAITING|MATCHED|CANCELLED|TIMEOUT)

game_rooms
├── id
├── creator_id (FK users)
├── room_code (VARCHAR(6), UNIQUE)
├── status (WAITING|ACTIVE|FINISHED|EXPIRED)
├── expires_at
└── created_at

game_room_players
├── id
├── room_id (FK game_rooms)
├── user_id (FK users)
├── deck_id (FK decks)
└── join_time
```

### Grupo 6: Juego

```
games
├── id
├── match_type (QUEUE|ROOM|PVE)
├── room_code (nullable, solo si ROOM)
├── player1_id, player1_deck_id (FK)
├── player2_id, player2_deck_id (FK, nullable si PVE)
├── bot_difficulty (EASY|MEDIUM|HARD, nullable)
├── bot_personality (HERNAN|SANTORO|RAMIRO, nullable)
├── status (WAITING|SETUP|ACTIVE|FINISHED|ABANDONED)
├── current_turn_player_id (FK users, nullable)
├── turn_number (default 0)
├── winner_id (FK users, nullable)
└── started_at, ended_at, created_at

game_state_snapshots
├── id
├── game_id (FK games)
├── turn_number
├── state_json JSONB  ← estado completo del tablero
└── created_at

game_events
├── id
├── game_id (FK games)
├── event_type (ATTACK|KO|PRIZE_TAKEN|STATUS_APPLIED|...)
├── payload JSONB
└── created_at

game_chat_messages
├── id
├── game_id (FK games)
├── user_id (FK users, nullable si es BOT)
├── username
├── message (VARCHAR 200)
├── message_type (USER|BOT|SYSTEM)
└── created_at
```

### Grupo 7: Vistas Materializadas

```
leaderboard (MATERIALIZED VIEW)
├── user_id, username
├── skill_rating, wins, losses, draws
├── total_games
└── win_percentage

user_collection_stats (MATERIALIZED VIEW)
├── user_id
├── unique_cards, total_cards
└── common_count, uncommon_count, rare_count, holo_count
```

---

## CÓMO USAR IA PARA GENERAR LAS TABLAS

### Para las cartas (el caso más útil)

El handoff ya incluye la fuente real en `docs/05-referencia-tecnica/xy1.json`. Tiene 146 cartas XY1 y todas incluyen `images.small` e `images.large`; durante `PASO_S00_05` se copia como `api/src/main/resources/seed/cards.json`.

**Prompt exacto para darle a la IA:**

```
Tengo este JSON de una carta de Pokemon TCG:

Usá una carta de docs/05-referencia-tecnica/xy1.json como ejemplo.

Necesito que generes:

1. Un CREATE TABLE cards_catalog para PostgreSQL que maneje correctamente:
   - Campos simples como strings e ints
   - Arrays simples (types, subtypes, retreatCost) como TEXT[] de PostgreSQL
   - Arrays de objetos (attacks, weaknesses, resistances, abilities) como JSONB
   - URLs de imágenes como VARCHAR(500) (NO bytea)
   - Todos los campos con el tipo más apropiado
   - NOT NULL donde tenga sentido, nullable donde no

2. Un CREATE TABLE card_sets para los datos del set

3. Los índices necesarios para:
   - Búsqueda por nombre (full text search)
   - Filtrar por supertype, rarity
   - Filtrar por types (array)

4. Un ejemplo de INSERT con los datos de la carta que te pegué

Usá snake_case para los nombres de columnas.
```

### Para las demás tablas

**Prompt para el resto:**

```
Necesito que generes las migraciones Flyway (archivos V*.sql) para PostgreSQL de un
juego de Pokemon TCG online. Las tablas son:

[describí la tabla o pegá el listado de campos que necesitás]

Requerimientos:
- snake_case en nombres
- Constraints explícitos con nombre (CONSTRAINT nombre_fk FOREIGN KEY...)
- Índices en campos de filtro frecuente
- CHECKs en campos con valores limitados (como status)
- NOT NULL en campos obligatorios
- Comentarios breves en cada tabla explicando para qué sirve
```

### Cómo revisar el SQL generado por la IA (5 minutos)

Antes de pegarlo en una migración, chequeá:

```
✅ ¿Los tipos son correctos?
   TEXT[] para arrays simples, JSONB para arrays de objetos

✅ ¿Las FK tienen ON DELETE CASCADE/SET NULL según corresponda?
   users → FK con CASCADE (si borro usuario, borro sus datos)
   cards_catalog → FK con RESTRICT (no borrar cartas en uso)

✅ ¿Los CHECKs cubren todos los valores posibles?
   CHECK (status IN ('WAITING','ACTIVE','FINISHED'))

✅ ¿Hay índice en los campos del WHERE frecuente?
   WHERE user_id = ? AND status = 'WAITING'
   → INDEX ON (user_id, status)

✅ ¿UNIQUE donde debe ser único?
   email_verifications: UNIQUE(user_id)  ← 1 por usuario
   user_collection: UNIQUE(user_id, card_id)  ← 1 entrada por carta
```

---

## SEED DE CARTAS: FLUJO COMPLETO

### Estructura de archivos

```
api/src/main/resources/
├── db/migration/
│   ├── V1__users_auth.sql
│   ├── V2__email_verif.sql
│   ├── V3__cards_sets.sql    ← Flyway crea las tablas
│   └── ...
└── seed/
    └── cards.json            ← copia de docs/05-referencia-tecnica/xy1.json
```

### Qué hace el seed al arrancar

```
Spring Boot arranca
    ↓
Flyway aplica migraciones (crea tablas)
    ↓
CardSeedRunner detecta tabla vacía
    ↓
Lee seed/cards.json (copia de xy1.json, 146 cartas)
    ↓
Para cada carta:
  ├─ Inserta en cards_catalog (PostgreSQL)
  ├─ Descarga imagen small de pokemontcg.io
  ├─ Sube imagen small a MinIO
  ├─ Descarga imagen large de pokemontcg.io
  ├─ Sube imagen large a MinIO
  └─ Actualiza image_small_url e image_large_url en PostgreSQL
    ↓
API lista. 146 cartas cargadas.
```

### El frontend nunca habla con pokemontcg.io

```
ANTES (dependencia externa frágil):
Frontend → pide imagen → https://images.pokemontcg.io/xy1/1.png

DESPUÉS (todo en tu infraestructura, vía gateway):
Frontend → pide imagen → http://localhost:8088/minio/codemon-cards/xy1/small/xy1-1.png
                                              ↑
                              Nginx → MinIO (MinIO no está expuesto en :9000)
```

---

## CHECKLIST DE BD ANTES DE EMPEZAR A CODEAR

Antes de arrancar con los servicios Java, asegurate de tener esto:

```
✅ Docker levantado (postgres + redis + minio)
✅ Flyway configurado en application.yml
✅ V1 hasta V10 escritas y sin errores de sintaxis
✅ App arranca sin errores de Flyway
✅ Tablas visibles en psql con \dt
✅ Vistas materializadas visibles con \dm
✅ MinIO bucket "codemon-cards" creado y público
✅ xy1.json copiado como src/main/resources/seed/cards.json
✅ CardSeedRunner carga las cartas al arrancar
✅ Imágenes visibles en http://localhost:8088/minio/codemon-cards/... (vía gateway, no :9000 directo)
```

---

## RESUMEN: ¿Hago las tablas yo o con IA?

| Caso | Quién lo hace | Por qué |
|------|---------------|---------|
| Tabla `cards_catalog` desde tu JSON | **IA + revisión** | El JSON tiene estructura compleja, la IA lo mapea bien |
| Tablas de auth (users, tokens) | **IA + revisión** | Patrones estándar, la IA los conoce bien |
| Tablas de juego (games, snapshots) | **IA + revisión** | Describís la lógica, la IA genera la tabla |
| Migraciones Flyway | **Vos** las organizás | El orden y naming son decisiones tuyas |
| Índices críticos | **Vos** los definís | Dependen de tus queries específicas |
| Constraints de negocio | **Vos** los revisás | La IA puede no entender tu lógica de negocio |

**Conclusión: la IA genera el 80%, vos revisás y ajustás el 20% crítico.**
