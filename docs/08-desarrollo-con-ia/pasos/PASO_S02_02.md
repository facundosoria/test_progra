---
id: PASO_S02_02
equipo: A
bloque: 2
dep: [PASO_S00_05, PASO_S00_03]
siguiente: PASO_S02_03
context_files:
  - CARTAS_E_IMAGENES.md
  - BD_Y_TABLAS.md
  - xy1.json
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/cards/entity/Card.java
  - api/src/main/java/com/codemon/cards/repository/CardRepository.java
  - api/src/main/java/com/codemon/cards/service/CardService.java
  - api/src/main/java/com/codemon/cards/controller/CardController.java
  - api/src/main/java/com/codemon/shared/config/MinioConfig.java
  - api/src/main/java/com/codemon/shared/seed/MinioService.java
  - api/src/main/java/com/codemon/shared/seed/CardSeedRunner.java
  - api/src/test/java/com/codemon/cards/CardServiceTest.java
---

# PASO 1.3 — Catálogo de cartas + MinIO + seed
**Grupo legacy:** 1 — Features Core | **Equipo:** A | **Dificultad:** 🔴 | **Tiempo:** 5–7 h

## Navegación
← **Anterior:** [PASO_S01_01](PASO_S01_01.md) — Autenticación JWT funcional
→ **Siguiente:** [PASO_S02_03](PASO_S02_03.md) — Deck Builder CRUD (Equipo A: backend, Equipo B: frontend)

## Archivos a cargar junto a este
- `CARTAS_E_IMAGENES.md` — estrategia completa de imágenes con MinIO
- `SCHEMA_BD.sql` → bloque V3 (tabla cards_catalog)
- `xy1.json` — fuente real del set XY1; copiarlo como `api/src/main/resources/seed/cards.json`

## Qué construye este paso
La entidad Card con su mapeo a PostgreSQL (incluyendo tipos JSON y arrays), MinioService para gestionar imágenes, CardSeedRunner que descarga las 146 imágenes y las sube a MinIO al primer arranque, y el endpoint de listado de cartas.

## Prompt listo para el agente

```
Implementá el catálogo de cartas para el proyecto Codemon TCG.

Usá `docs/05-referencia-tecnica/xy1.json` como fuente real del seed. El archivo contiene 146 cartas XY1 y todas incluyen `images.small` e `images.large`; en `PASO_S00_05` se copia al proyecto Spring Boot como `api/src/main/resources/seed/cards.json`.

Schema de BD para las cartas:
[pegá el bloque V3 de SCHEMA_BD.sql]

Estrategia de imágenes:
[pegá el contenido de CARTAS_E_IMAGENES.md]

Implementá en el paquete com.codemon:

1. cards/entity/Card.java
   - Mapea exactamente la tabla cards_catalog
   - Los campos que son arrays simples (types, subtypes, retreatCost) usan @Type para PostgreSQL TEXT[]
   - Los campos que son arrays de objetos (attacks, weaknesses, resistances, abilities) usan @JdbcTypeCode(SqlTypes.JSON)
   - hp viene como String en el JSON pero se guarda como Integer, convertir en el seed
   - Agregar la dependencia hypersistence-utils-63 al pom.xml para soportar tipos PostgreSQL

2. shared/config/MinioConfig.java
   - Bean de MinioClient usando propiedades codemon.minio.*

3. shared/seed/MinioService.java
   - uploadFile(String objectName, byte[] data, String contentType): sube a MinIO
   - getPublicUrl(String objectName): retorna URL pública

4. shared/seed/CardSeedRunner.java implements CommandLineRunner
   - Anotado con @Profile("!test") para no correr en tests
   - Si cardRepository.count() > 0, retornar sin hacer nada
   - Leer classpath:seed/cards.json con ObjectMapper
   - Para cada carta:
     a. Mapear el JSON a la entidad Card
     b. Descargar imagen small y large con RestTemplate (timeout 10s, retry 3 veces)
     c. Subir a MinIO con ruta: {setCode}/small/{cardId}.png y {setCode}/large/{cardId}.png
     d. Setear image_small_url e image_large_url con la URL pública de MinIO
     e. Guardar en BD
   - Loguear progreso cada 10 cartas: "Procesando carta X/146"

5. cards/controller/CardController.java
   - GET /cards → lista paginada con filtros: ?name=, ?supertype=, ?rarity=, ?page=0, ?size=20
   - GET /cards/{id} → carta por ID

6. cards/service/CardService.java
   - findAll(String name, String supertype, String rarity, Pageable page)
   - findById(String id)

Tests:
- CardServiceTest.java → buscar por nombre, por tipo, por rareza
- Verificar que CardSeedRunner NO corre si ya hay cartas en BD

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea
```
api/src/main/java/com/codemon/cards/
  entity/Card.java
  repository/CardRepository.java
  service/CardService.java
  controller/CardController.java
api/src/main/java/com/codemon/shared/
  config/MinioConfig.java
  seed/MinioService.java
  seed/CardSeedRunner.java
api/src/main/resources/seed/cards.json  (copia de docs/05-referencia-tecnica/xy1.json realizada en PASO 0.4)
api/src/test/java/com/codemon/cards/CardServiceTest.java
```

## Errores comunes

- **`hp` es String en JSON pero Integer en BD**: convertir en el CardSeedRunner con `Integer.parseInt(card.getHp())`
- **TEXT[] en JPA sin hypersistence-utils**: agregar `com.vladmihalcea:hypersistence-utils-hibernate-63` al pom.xml
- **CardSeedRunner corre dos veces**: agregar `if (cardRepository.count() > 0) { log.info("Cartas ya cargadas"); return; }`
- **Timeout descargando imágenes**: configurar RestTemplate con timeout de 10s y retry de 3 intentos
- **MinIO bucket no existe**: el `minio_setup` de Docker Compose lo crea; verificar que corrió exitosamente

## Verificación

```bash
# Al arrancar la API, en logs:
# PASS: aparece "Procesando carta 10/146" ... "146 cartas cargadas exitosamente."
# FAIL: excepción en CardSeedRunner → verificar conexión MinIO y formato de cards.json

# Datos en PostgreSQL
docker exec codemon_postgres psql -U codemon_user -d codemon_db \
  -c "SELECT id, name, image_small_url FROM cards_catalog LIMIT 3;"
# PASS: 3 filas con image_small_url no nulo
# FAIL: 0 filas → CardSeedRunner no corrió o hubo error silencioso

# Imagen accesible directamente en MinIO
curl -I http://localhost:8088/minio/codemon-cards/xy1/small/xy1-1.png
# PASS: HTTP/1.1 200 OK
# FAIL: 404 → imagen no subida a MinIO, revisar MinioService.uploadFile()

# API retorna cartas con URL
curl "http://localhost:8088/cards?page=0&size=3"
# PASS: {"content":[...],"totalElements":146}
# FAIL: totalElements=0 o error → revisar CardRepository y CardController
```

## Dependencias
PASO_S00_05 (tabla cards_catalog en BD), PASO_S00_03 (MinIO corriendo en Docker).

---

## Entrega al siguiente paso

Tras completar este PASO, los siguientes (PASO_S02_03, PASO_S02_05, PASO_S03_03) pueden asumir:

- **Endpoints REST disponibles**:
  - `GET /api/cards` con paginación y filtros (type, supertype, rarity, name)
  - `GET /api/cards/{id}` devuelve la carta completa con `imageSmallUrl` e `imageLargeUrl`
- **Bean Spring autowireable**: `CardRepository` (Spring Data JPA), `CardService`, `MinioService`
- **Entidad canónica `Card`** en `com.codemon.cards.entity.Card` (única clase Card del proyecto, ver [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md) sección 2)
- **BD poblada**: 146 cartas XY1 cargadas vía `CardSeedRunner` (idempotente — no duplica al reiniciar)
- **Imágenes en MinIO**: bucket `codemon-cards` con subcarpetas `xy1/small/` y `xy1/large/`, todas accesibles públicamente
- Para PASO_S02_01 (refactor): `DeckValidationService` puede pasar de la abstracción `CardForValidation` a consumir `Card` directamente

---

## Definition of Done

- [ ] Todos los archivos de `outputs:` existen
- [ ] `./verify_paso.sh PASO_S02_02` retorna exit 0
- [ ] BD tiene exactamente 146 cartas (`CardSeedRunner` idempotente: no duplica al reiniciar)
- [ ] Cada carta tiene `imageSmallUrl` e `imageLargeUrl` apuntando a MinIO
- [ ] Tests pasan con cobertura ≥ 80% en `com.codemon.cards`
- [ ] Sin TODOs ni FIXMEs
- [ ] Naming respeta [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md): `Card` único en `cards.entity`
