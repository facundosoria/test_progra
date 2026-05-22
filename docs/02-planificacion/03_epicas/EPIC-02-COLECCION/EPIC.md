# EPIC-02 — Catalogo y Coleccion de Cartas

## 1. Resumen

- **Valor de negocio:** los jugadores pueden explorar las 146 cartas del set XY1 y ver que cartas tienen en su coleccion personal. Sin catalogo no se pueden armar mazos ni vender sobres.
- **Roles involucrados:** Jugador autenticado.
- **Sprints donde se completa:** S2 (catalogo + filtros + detalle); la coleccion personal se enriquece en S8 cuando entran los sobres.
- **Equipos:** A (backend catalogo + seed + MinIO), B (frontend grid y filtros).

## 2. Historias de Usuario

### HU-02-01 — Ver el catalogo paginado de cartas XY1
**Como** jugador autenticado, **quiero** ver una grilla con las 146 cartas XY1, **para** conocer que cartas existen en el juego.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: `GET /cards?page=0&size=20` responde 200 con `content[]`, `totalElements=146`, `totalPages=8`.
- AC2: Cada carta incluye `cardId`, `name`, `supertype`, `subtypes`, `rarity`, `imageSmallUrl`, `imageLargeUrl`.
- AC3: La UI carga la primera pagina < 1.5 s y permite paginar.
- AC4: Las imagenes se sirven desde MinIO (`localhost:9000/codemon-cards/...`).

**RNF:**
- RNF-Performance: P95 backend < 250 ms; cache en CDN/Nginx para las imagenes (cache-control 1 ano).
- RNF-Disponibilidad: si MinIO no responde, el grid muestra placeholder y log de warning.
- RNF-Almacenamiento: imagenes nunca van en BD; siempre en MinIO.

**Dependencias:** TT-02-01 (seed XY1), TT-02-02 (MinIO).
**Sprint:** S2.

---

### HU-02-02 — Filtrar y buscar cartas
**Como** jugador, **quiero** filtrar el catalogo por nombre, tipo, rareza y supertype, **para** encontrar rapido las cartas que me interesan.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: Filtros combinables: `?name=`, `?supertype=`, `?type=`, `?rarity=`.
- AC2: Busqueda por nombre es case-insensitive y soporta substring.
- AC3: La UI debouncea la busqueda 300 ms.
- AC4: Sin resultados muestra estado vacio amigable.

**RNF:**
- RNF-Performance: indices BD en `(name)`, `(rarity)`, `(supertype)`.
- RNF-Usabilidad: filtros se reflejan en la URL (deep-link).

**Dependencias:** HU-02-01.
**Sprint:** S2.

---

### HU-02-03 — Ver detalle de una carta
**Como** jugador, **quiero** abrir el detalle de una carta, **para** leer atributos completos (HP, ataques, weakness, resistance, retreat cost).

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: `GET /cards/{cardId}` devuelve la carta con `attacks[]` (con `cost`, `damage`, `text`), `weaknesses[]`, `resistances[]`, `retreatCost`.
- AC2: La UI muestra la imagen large.
- AC3: Si la carta no existe, 404.

**RNF:**
- RNF-Usabilidad: vista mobile-friendly.

**Dependencias:** HU-02-01.
**Sprint:** S2.

---

### HU-02-04 — Ver mi coleccion personal
**Como** jugador, **quiero** ver las cartas que poseo y en que cantidad, **para** saber cuales me faltan.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: `GET /users/me/collection?page=0&size=20` devuelve mis cartas con `quantity`.
- AC2: Cartas que no poseo no aparecen (o aparecen con `quantity=0` segun toggle "ver todo el set").
- AC3: Filtros por rareza y supertype igual que el catalogo.

**RNF:**
- RNF-Performance: indice unico en `(user_id, card_id)`.
- RNF-Privacidad: solo el dueno puede ver su coleccion completa con cantidades.

**Dependencias:** HU-02-01, EPIC-07 (para tener cartas via sobres).
**Sprint:** S8.

---

### HU-02-05 — Ver estadisticas de mi coleccion
**Como** jugador, **quiero** ver % de coleccion completada y cuantas faltan por rareza, **para** decidir cuantos sobres comprar.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: `GET /users/me/collection/stats` devuelve `totalOwned`, `totalUnique`, `completionPct`, `missingByRarity`.
- AC2: Stats se calculan via vista materializada `user_collection_stats`.

**RNF:**
- RNF-Performance: vista materializada refrescada al abrir sobre.

**Dependencias:** HU-02-04.
**Sprint:** S8.

## 3. Tareas Tecnicas

| ID | Tarea | Origen | Equipo | SP | Sprint |
|---|---|---|---|---|---|
| TT-02-01 | `CardSeedRunner` carga 146 cartas XY1 al primer arranque (idempotente) | PASO_S02_02 | A | 5 | S2 |
| TT-02-02 | `MinioService.uploadFile()` + descarga inicial de 292 imagenes pokemontcg.io | PASO_S02_02 | A | 5 | S2 |
| TT-02-03 | Entidad `Card` con campos JSON (`attacks`, `weaknesses`) y arrays (`types`, `subtypes`) | PASO_S02_02 | A | 3 | S2 |
| TT-02-04 | UI `CardCatalog` con grid + filtros + paginacion | PASO_S02_05 | B | 5 | S2 |
| TT-02-05 | UI `CollectionView` con filtros por rareza | PASO_S08_01 (frontend), PASO_S09_04 | B | 3 | S8 |
| TT-02-06 | Vista materializada `user_collection_stats` (V11) | PASO_S08_02 | C | 2 | S8 |

## 4. Contratos involucrados

- REST: `GET /cards`, `GET /cards/{id}`, `GET /users/me/collection`, `GET /users/me/collection/stats`.
- STOMP: ninguno.

## 5. Definition of Done especifico

- 146 cartas seedadas y verificadas (`SELECT COUNT(*) FROM cards_catalog = 146`).
- 292 imagenes en MinIO accesibles via HTTP 200.
- Filtros combinables testeados unitariamente.
- Cobertura `CardService` ≥ 80%.
- UI verificada en mobile + desktop.
- Hereda [DOD.md](../../04_proceso/DOD.md) global.
