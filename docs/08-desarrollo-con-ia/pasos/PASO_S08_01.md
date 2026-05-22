---
id: PASO_S08_01
equipo: C
bloque: 8
dep: [PASO_S02_02, PASO_S01_01, PASO_S00_03]
siguiente: PASO_S08_02 PASO_S08_03, PASO_S09_03]
context_files:
  - BD_Y_TABLAS.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/booster/entity/BoosterPack.java
  - api/src/main/java/com/codemon/booster/entity/BoosterPackCard.java
  - api/src/main/java/com/codemon/booster/entity/UserBoosterPack.java
  - api/src/main/java/com/codemon/booster/entity/UserCollection.java
  - api/src/main/java/com/codemon/booster/repository/BoosterPackRepository.java
  - api/src/main/java/com/codemon/booster/repository/UserBoosterPackRepository.java
  - api/src/main/java/com/codemon/booster/repository/UserCollectionRepository.java
  - api/src/main/java/com/codemon/booster/service/BoosterPackService.java
  - api/src/main/java/com/codemon/booster/service/CardGenerationService.java
  - api/src/main/java/com/codemon/booster/controller/BoosterPackController.java
  - api/src/main/java/com/codemon/collection/service/CollectionService.java
  - api/src/main/java/com/codemon/collection/controller/CollectionController.java
  - api/src/test/java/com/codemon/booster/BoosterPackServiceTest.java
---

# PASO 4.1 — Sobres y colección
**Grupo legacy:** 4 — Features Adicionales | **Equipo:** C | **Dificultad:** 🟡 | **Tiempo:** 4–5 h

## Navegación
← **Anterior:** [PASO_S07_02](PASO_S07_02.md) — Matchmaking cola ranked completado
→ **Siguiente (paralelo):** [PASO_S08_02](PASO_S08_02.md) · [PASO_S08_03](PASO_S08_03.md) · [PASO_S09_03](PASO_S09_03.md) — pueden ejecutarse en paralelo

## Archivos a cargar junto a este
- `SCHEMA_BD.sql` → bloque V5 (tablas booster_packs, user_booster_packs, user_collection)

## Qué construye este paso
Sistema de sobres de cartas con cooldown diario (Redis), distribución de rareza al abrir, y colección del usuario. También incluye el endpoint de colección con filtros y estadísticas.

## Prompt listo para el agente

```
Implementá el sistema de sobres y colección para Codemon TCG.
Spring Boot 3.3.x, Java 21, Redis para cooldowns.

Schema:
[pegá los bloques V5 de SCHEMA_BD.sql]

Implementá:

1. Entities: BoosterPack, BoosterPackCard, UserBoosterPack, UserCollection

2. BoosterPackService:
   openBoosterPack(userId, boosterPackEntryId):
   - Verificar sobre no abierto (status == SEALED)
   - Verificar cooldown: Redis key "booster:cooldown:{userId}" (TTL 24h)
     Si existe → error "Ya abriste tu sobre hoy"
   - Generar cartas según distribución de rareza del booster
     (el JSON rarity_distribution del booster define los %):
     10 cartas por sobre: 5 comunes, 3 poco comunes, 1 rara, 1 holo/rara
   - Agregar cada carta a user_collection (si ya existe, incrementar quantity)
   - Setear Redis key "booster:cooldown:{userId}" con TTL de 86400 segundos
   - Retornar las 10 cartas obtenidas

   getCooldownStatus(userId):
   - Consultar Redis: GET booster:cooldown:{userId}
   - Si existe: retornar tiempo restante hasta que expire
   - Si no existe: retornar "disponible"

3. CollectionService:
   getCollection(userId, supertype, rarity, page): paginado, filtros opcionales
   getStats(userId): usando la vista materializada user_collection_stats

4. Controllers:
   BoosterPackController:
   - GET  /booster-packs           → lista de sobres disponibles
   - POST /users/me/booster-packs/{id}/open  → abrir sobre
   - GET  /users/me/booster-packs/cooldown   → estado del cooldown

   CollectionController:
   - GET  /users/me/collection        → colección paginada con filtros
   - GET  /users/me/collection/stats  → estadísticas de la colección

5. Seed: CommandLineRunner que cree 1 booster pack de tipo XY1 si no existe

TESTS:
- Abrir sobre → retorna exactamente 10 cartas
- Distribución de rareza respetada (al menos 1 de rareza alta)
- Segundo sobre mismo día → error de cooldown
- Colección se actualiza correctamente (quantity++ si ya existe la carta)
- getStats retorna porcentaje de completitud correcto

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea
```
api/src/main/java/com/codemon/booster/
  entity/BoosterPack.java
  entity/BoosterPackCard.java
  entity/UserBoosterPack.java
  entity/UserCollection.java
  repository/BoosterPackRepository.java
  repository/UserBoosterPackRepository.java
  repository/UserCollectionRepository.java
  service/BoosterPackService.java
  service/CardGenerationService.java
  controller/BoosterPackController.java
api/src/main/java/com/codemon/collection/
  service/CollectionService.java
  controller/CollectionController.java
api/src/test/java/com/codemon/booster/BoosterPackServiceTest.java
```

## Errores comunes

- **Cooldown no expira**: asegurarse de setear TTL en segundos (`SETEX key 86400 value`), no en milisegundos
- **Distribución de rareza no respetada**: implementar weighted random selection basado en los porcentajes del JSON
- **user_collection sin índice único**: si el índice (userId, cardId) no existe, puede insertar duplicados en vez de incrementar

## Verificación

```bash
TOKEN="eyJ..."

curl -X POST http://localhost:8088/users/me/booster-packs/1/open \
  -H "Authorization: Bearer $TOKEN"
# PASS: {"cardsObtained":[...exactamente 10 cartas...],"nextCooldown":"..."}
# FAIL: error o menos/más de 10 cartas → revisar CardGenerationService

# Segunda apertura el mismo día → error de cooldown
curl -X POST http://localhost:8088/users/me/booster-packs/1/open \
  -H "Authorization: Bearer $TOKEN"
# PASS: {"error":"Ya abriste tu sobre hoy. Próximo disponible en Xh"}
# FAIL: permite abrir → cooldown Redis no configurado correctamente

curl http://localhost:8088/users/me/collection \
  -H "Authorization: Bearer $TOKEN"
# PASS: {"content":[...],"totalElements":10}
# FAIL: totalElements=0 → user_collection no se actualizó al abrir el sobre
```

## Dependencias
PASO_S02_02 (cartas en BD), PASO_S01_01 (autenticación), PASO_S00_03 (Redis corriendo).
