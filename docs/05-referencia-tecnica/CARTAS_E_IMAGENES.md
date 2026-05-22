# CARTAS_E_IMAGENES.md - Estrategia de Cartas, Imágenes y Base de Datos

---

## FUENTE CANONICA DEL SEED

El handoff incluye `xy1.json` en `docs/05-referencia-tecnica/xy1.json`. Ese archivo es la fuente real del set XY1: contiene 146 cartas y cada carta trae `images.small` e `images.large` apuntando a `images.pokemontcg.io`.

Durante el setup se copia como `api/src/main/resources/seed/cards.json`, porque ese es el nombre que lee `CardSeedRunner` dentro de Spring Boot.

La estructura de cada carta es parecida a esta:

```json
{
  "id": "xy1-1",
  "name": "Venusaur-EX",
  "supertype": "Pokémon",
  "subtypes": ["Basic", "EX"],
  "hp": "180",
  "types": ["Grass"],
  "evolvesFrom": null,
  "attacks": [
    {
      "name": "Frog Hop",
      "cost": ["Grass", "Colorless", "Colorless"],
      "convertedEnergyCost": 3,
      "damage": "40+",
      "text": "Flip a coin. If heads, this attack does 40 more damage."
    }
  ],
  "weaknesses": [{ "type": "Fire", "value": "×2" }],
  "resistances": [],
  "retreatCost": ["Colorless", "Colorless", "Colorless", "Colorless"],
  "number": "1",
  "artist": "Eske Yoshinob",
  "rarity": "Rare Holo EX",
  "nationalPokedexNumbers": [3],
  "images": {
    "small": "https://images.pokemontcg.io/xy1/1.png",
    "large": "https://images.pokemontcg.io/xy1/1_hires.png"
  }
}
```

---

## PREGUNTA 1: ¿DÓNDE GUARDO LAS IMÁGENES?

### Opción A: Usar la URL externa directamente ❌ NO recomendado

```
Tu app → muestra URL → https://images.pokemontcg.io/xy1/1.png
```

**Problema:** Si esa API externa cae, todas tus cartas se rompen. No tenés control.
No recomendado para un TPI que tiene que funcionar en una presentación.

---

### Opción B: Guardar imágenes en PostgreSQL (BYTEA) ❌ NO recomendado

```sql
card_images (
  card_id VARCHAR,
  image_data BYTEA,   -- ← imagen completa guardada acá
  ...
)
```

**Problema:** Las imágenes en la BD son una mala práctica conocida:
- Enlentece TODAS las queries aunque no uses imágenes
- Hace backups enormes
- PostgreSQL no está diseñado para servir archivos binarios grandes
- Mata el connection pool

---

### Opción C: Guardar en disco del servidor ⚠️ Funciona pero no escala

```
/home/ubuntu/codemon/card-assets/
  small/xy1-1.png
  large/xy1-1_hires.png
```

**Problema:** Si el servidor se mueve o resetea, perdés los archivos. No es reproducible.

---

### ✅ Opción D: MinIO (RECOMENDADA para este proyecto)

**MinIO** es un servidor de objetos compatible con S3 que corre en Docker. Es exactamente lo que usan en producción empresas grandes, pero gratis y local.

```
xy1.json → copiar como seed/cards.json → tu script seed → descarga imagen de pokemontcg.io
                                        ↓
                              guarda en MinIO (Docker)
                                        ↓
PostgreSQL guarda: card_id, minio_url="http://localhost:8088/minio/codemon-cards/xy1-1.png"
                                        ↓
                    Frontend pide imagen → Nginx gateway → MinIO la sirve
```

> ⚠️ **URLs de imágenes:** la BD debe guardar siempre URLs con el prefijo del gateway
> (`http://localhost:8088/minio/...`), nunca `localhost:9000` directo. MinIO no está
> expuesto públicamente; todo pasa por Nginx en el puerto 8088.
> `CardSeedRunner` usa la variable de entorno `MINIO_PUBLIC_URL` como prefijo, cuyo
> valor por defecto es `http://localhost:8088/minio`. Si la BD ya tiene URLs con
> `localhost:9000` de una ejecución anterior, corregirlas con:
> ```sql
> UPDATE cards_catalog
>   SET image_small_url = REPLACE(image_small_url, 'http://localhost:9000', 'http://localhost:8088/minio'),
>       image_large_url = REPLACE(image_large_url,  'http://localhost:9000', 'http://localhost:8088/minio');
> ```

**Ventajas:**
- ✅ Las imágenes viven en TU infraestructura (no dependés de nadie)
- ✅ Corre en Docker con una línea
- ✅ API compatible con S3 (si algún día vas a la nube, es 0 cambios)
- ✅ Sirve archivos estáticos muy rápido (mucho más que Spring Boot)
- ✅ No enlentece PostgreSQL
- ✅ Panel de administración web incluido (localhost:9001)
- ✅ Gratis y open source

**URLs finales (vía gateway):**
```
http://localhost:8088/minio/codemon-cards/xy1/small/xy1-1.png
http://localhost:8088/minio/codemon-cards/xy1/large/xy1-1_hires.png
```

---

## PREGUNTA 2: ¿CÓMO ESTRUCTURO LA TABLA DE CARTAS?

### Regla clave: los arrays y objetos van en JSONB

PostgreSQL tiene un tipo `JSONB` que guarda JSON de forma indexable y consultable. Es perfecto para campos como `attacks`, `weaknesses`, `types`, `subtypes`.

### Tabla `cards_catalog`

```sql
CREATE TABLE cards_catalog (
    -- Identificación
    id              VARCHAR(20) PRIMARY KEY,        -- "xy1-1"
    name            VARCHAR(255) NOT NULL,           -- "Venusaur-EX"
    number          VARCHAR(10),                    -- "1"

    -- Clasificación
    supertype       VARCHAR(50),                    -- "Pokémon", "Trainer", "Energy"
    subtypes        TEXT[],                         -- ["Basic", "EX"]  ← array nativo Postgres
    types           TEXT[],                         -- ["Grass"]
    rarity          VARCHAR(50),                    -- "Rare Holo EX"

    -- Set
    set_id          VARCHAR(20),                    -- "xy1"
    set_name        VARCHAR(100),                   -- "XY"
    set_series      VARCHAR(100),                   -- "XY"
    set_total       INT,                            -- 146

    -- Stats de Pokémon (null si es Trainer/Energy)
    hp              INT,                            -- 180
    evolves_from    VARCHAR(255),                   -- "Ivysaur"
    evolves_to      TEXT[],                         -- ["Mega Venusaur-EX"]
    converted_retreat_cost INT,                     -- 4

    -- Arrays complejos → JSONB
    attacks         JSONB,   -- [{name, cost[], damage, text}]
    weaknesses      JSONB,   -- [{type, value}]
    resistances     JSONB,   -- [{type, value}]
    abilities       JSONB,   -- [{name, text, type}]
    rules           JSONB,   -- ["When this Pokémon-EX is knocked out..."]

    -- Imágenes → URL a MinIO (NO el BYTEA)
    image_small_url VARCHAR(500),  -- "http://localhost:8088/minio/codemon-cards/xy1/small/xy1-1.png"
    image_large_url VARCHAR(500),  -- "http://localhost:8088/minio/codemon-cards/xy1/large/xy1-1_hires.png"

    -- Metadata
    artist          VARCHAR(255),
    national_pokedex_numbers INT[],  -- [3]
    legalities      JSONB,           -- {"unlimited": "Legal"}

    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices útiles para búsquedas frecuentes
CREATE INDEX idx_cards_name       ON cards_catalog USING gin(to_tsvector('english', name));
CREATE INDEX idx_cards_supertype  ON cards_catalog(supertype);
CREATE INDEX idx_cards_set_id     ON cards_catalog(set_id);
CREATE INDEX idx_cards_rarity     ON cards_catalog(rarity);
CREATE INDEX idx_cards_types      ON cards_catalog USING gin(types);
CREATE INDEX idx_cards_subtypes   ON cards_catalog USING gin(subtypes);
CREATE INDEX idx_cards_attacks    ON cards_catalog USING gin(attacks);
```

### Tabla de sets (opcional pero prolija)

```sql
CREATE TABLE card_sets (
    id          VARCHAR(20) PRIMARY KEY,  -- "xy1"
    name        VARCHAR(100) NOT NULL,    -- "XY"
    series      VARCHAR(100),            -- "XY"
    total_cards INT,                     -- 146
    release_date DATE,
    logo_url    VARCHAR(500),
    symbol_url  VARCHAR(500),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE cards_catalog
    ADD CONSTRAINT fk_card_set
    FOREIGN KEY (set_id) REFERENCES card_sets(id);
```

---

## PREGUNTA 3: ¿CÓMO CARGO LOS DATOS?

### Flujo del seed

```
xy1.json (en el handoff; copiado como seed/cards.json dentro de Spring Boot)
    │
    ▼
Script Java (CommandLineRunner) o script bash
    │
    ├─ Lee cada carta del JSON
    ├─ Inserta en cards_catalog (PostgreSQL)
    └─ Descarga imagen de pokemontcg.io
           └─ Sube a MinIO bucket "codemon-cards"
                  └─ Guarda la URL en cards_catalog.image_small_url
```

### Seed en Java (Spring Boot CommandLineRunner)

Crear `api/src/main/java/com/codemon/shared/seed/CardSeedRunner.java`:

```java
@Component
@Profile("!test")  // No ejecuta en tests
public class CardSeedRunner implements CommandLineRunner {

    @Autowired CardRepository cardRepo;
    @Autowired MinioService minioService;
    @Value("classpath:seed/cards.json") Resource cardsJson;

    @Override
    public void run(String... args) throws Exception {
        // Solo seedea si la tabla está vacía
        if (cardRepo.count() > 0) {
            log.info("Cartas ya cargadas, saltando seed.");
            return;
        }

        log.info("Cargando cartas desde JSON...");
        ObjectMapper mapper = new ObjectMapper();
        List<CardSeedDTO> cards = mapper.readValue(
            cardsJson.getInputStream(),
            new TypeReference<List<CardSeedDTO>>() {}
        );

        for (CardSeedDTO dto : cards) {
            // 1. Descargar y subir imagen a MinIO
            String smallUrl = minioService.downloadAndUpload(
                dto.getImages().getSmall(),
                "xy1/small/" + dto.getId() + ".png"
            );
            String largeUrl = minioService.downloadAndUpload(
                dto.getImages().getLarge(),
                "xy1/large/" + dto.getId() + ".png"
            );

            // 2. Insertar carta en PostgreSQL
            Card card = mapDtoToEntity(dto, smallUrl, largeUrl);
            cardRepo.save(card);

            log.info("Carta cargada: {}", dto.getName());
        }

        log.info("✅ {} cartas cargadas exitosamente.", cards.size());
    }
}
```

Copiar `docs/05-referencia-tecnica/xy1.json` a `api/src/main/resources/seed/cards.json`.

---

## PREGUNTA 4: ¿USO IA PARA GENERAR LAS TABLAS?

### Respuesta corta: **Sí, con revisión manual.**

Para este proyecto es la mejor estrategia. Te explico por qué y cómo.

### ✅ Sí usar IA para:

**Generar el SQL inicial a partir del JSON**
Pasarle a la IA `docs/05-referencia-tecnica/xy1.json` y pedirle:
```
"Analizá este JSON de cartas de Pokemon TCG y generame:
1. El CREATE TABLE con los tipos correctos de PostgreSQL
2. Los índices necesarios para búsquedas por nombre, tipo, rareza
3. Un INSERT de ejemplo con una carta del JSON"
```

**Generar las otras tablas** (users, games, payments, etc.) a partir del README.

**Generar el CommandLineRunner** para seedear las cartas.

**Generar DTOs** que mapeen el JSON a Java.

### ❌ No confiar ciegamente en la IA para:

- **Constraints de integridad:** Revisar que las FK sean correctas
- **Tipos de datos:** Confirmar que `JSONB` es lo correcto para arrays complejos
- **Índices:** La IA puede no saber qué campos consultás más
- **Convenciones:** snake_case en BD, camelCase en Java

### Workflow recomendado para las tablas

```
Paso 1: Pasarle `xy1.json` a la IA
         └─ Pedirle el CREATE TABLE completo

Paso 2: Revisás el SQL (5-10 minutos)
         ├─ ¿Los tipos son correctos?
         ├─ ¿Hay índices en campos de búsqueda frecuente?
         └─ ¿Las constraints tienen sentido?

Paso 3: Guardás como V3__add_cards.sql (Flyway)

Paso 4: Levantás la app → Flyway aplica la migración

Paso 5: Verificás en PostgreSQL:
         \d cards_catalog
```

---

## PREGUNTA 5: ¿CÓMO GESTIONO TODA LA INFRA?

### La respuesta es Docker Compose + Flyway + Seed

```
docker-compose.yml
├── postgres         → BD principal
├── redis            → Cache + matchmaking queue
├── minio            → Imágenes de cartas
├── prometheus       → Métricas
└── grafana          → Dashboards

api/ (Spring Boot)
└── src/main/resources/
    ├── db/migration/
    │   ├── V1__users_auth.sql
    │   ├── V2__2fa.sql
    │   ├── V3__cards_sets.sql       ← generado con IA revisado
    │   ├── V4__decks.sql
    │   ├── V5__payments.sql
    │   ├── V6__booster.sql
    │   ├── V7__matchmaking.sql
    │   ├── V8__games.sql
    │   ├── V9__chat.sql
    │   └── V10__views_indexes.sql
    └── seed/
        └── cards.json               ← copia de docs/05-referencia-tecnica/xy1.json
```

### Orden de ejecución al arrancar

```
1. docker compose up -d
   → PostgreSQL, Redis, MinIO, Prometheus, Grafana corren

2. ./mvnw spring-boot:run
   → Flyway aplica migraciones V1-V10 (crea tablas)
   → CardSeedRunner corre (carga cartas de JSON + sube imágenes a MinIO)
   → API queda lista

3. ng serve
   → Frontend arranca
   → Cuando muestra una carta, pide imagen a MinIO directamente
```

---

## RESUMEN DE DECISIONES

| Pregunta | Decisión | Por qué |
|----------|----------|---------|
| ¿Dónde guardo imágenes? | **MinIO** | Propio, rápido, S3-compatible, Docker |
| ¿Guardo imágenes en PostgreSQL? | **No** | Mala práctica, lento, voluminoso |
| ¿Uso URL externa? | **No** (en producción) | Dependencia externa frágil |
| ¿Cómo estructuro cartas? | **JSONB para arrays** | `attacks`, `weaknesses`, `types` en JSONB |
| ¿Hago las tablas yo o con IA? | **IA + revisión manual** | Rápido y correcto |
| ¿Cómo cargo los datos? | **Flyway + CommandLineRunner** | Reproducible, automático |
| ¿Cómo organizo la infra? | **Docker Compose** | Un solo comando levanta todo |

---

## PRÓXIMOS PASOS CONCRETOS

1. **Usá `docs/05-referencia-tecnica/xy1.json`** como fuente del seed
   → Te genero el `CREATE TABLE` exacto para tu estructura

2. **Agrego MinIO al `docker-compose.yml`**
   → Ya lo tenés configurado listo para usar

3. **Creo el `CardSeedRunner.java`** que lee el JSON y sube imágenes a MinIO

4. **Creo el `MinioService.java`** que maneja la subida/bajada de archivos

5. **Creo la migración `V3__add_cards.sql`** con la tabla exacta

Cuando tengas el JSON disponible podemos arrancar con esto.
