---
id: PASO_S02_03
equipo: A+B
bloque: 2
dep: [PASO_S02_01, PASO_S01_01, PASO_S02_02]
siguiente: PASO_S02_04 PASO_S05_04]
context_files:
  - 05-deck-validation.md
  - BD_Y_TABLAS.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/decks/entity/Deck.java
  - api/src/main/java/com/codemon/decks/entity/DeckCard.java
  - api/src/main/java/com/codemon/decks/repository/DeckRepository.java
  - api/src/main/java/com/codemon/decks/repository/DeckCardRepository.java
  - api/src/main/java/com/codemon/decks/service/DeckService.java
  - api/src/main/java/com/codemon/decks/controller/DeckController.java
  - api/src/main/java/com/codemon/decks/dto/DeckCreateRequest.java
  - api/src/main/java/com/codemon/decks/dto/DeckUpdateRequest.java
  - api/src/main/java/com/codemon/decks/dto/DeckResponse.java
  - api/src/main/java/com/codemon/decks/dto/DeckDetailResponse.java
  - api/src/main/java/com/codemon/decks/dto/ValidationResponse.java
  - api/src/test/java/com/codemon/decks/DeckServiceTest.java
---

# PASO 1.4 — Deck Builder (CRUD)
**Grupo legacy:** 1 — Features Core | **Equipo:** A (backend) + B (frontend) | **Dificultad:** 🟡 | **Tiempo:** 4–5 h

## Navegación
← **Anterior:** [PASO_S02_02](PASO_S02_02.md) — Catálogo de cartas con MinIO y seed de 146 cartas
→ **Siguiente (A):** [PASO_S03_01](PASO_S03_01.md) — Game engine skeleton (State Machine)
→ **Siguiente (B):** [PASO_S05_04](PASO_S05_04.md) — Board de juego Angular (requiere GATE 2)

## Archivos a cargar junto a este
- `05-deck-validation.md` — reglas de validación
- `SCHEMA_BD.sql` → bloque V4 (tablas decks, deck_cards)

## Qué construye este paso
CRUD completo de mazos: crear, listar, editar, eliminar, validar y marcar como favorito. También crea 3 mazos starter del sistema que cualquier usuario puede copiar para empezar a jugar.

## Prompt listo para el agente

```
Implementá el CRUD de mazos para el proyecto Codemon TCG.
Spring Boot 3.3.x, Java 21, Spring Data JPA, PostgreSQL.

Schema:
[pegá bloque V4 de SCHEMA_BD.sql]

Reglas de validación (ya tengo DeckValidationService implementado):
[pegá 05-deck-validation.md]

Implementá en com.codemon.decks:

ENTITIES:
- Deck.java → tabla "decks" (user_id nullable para starters del sistema, is_starter boolean)
- DeckCard.java → tabla "deck_cards" (deck_id, card_id, quantity)

REPOSITORIES:
- DeckRepository.java → findByUserId, findByIsStarter
- DeckCardRepository.java → findByDeckId, deleteByDeckId

DTOs:
- DeckCreateRequest.java → name, description
- DeckUpdateRequest.java → name, description, cards: List<{cardId, quantity}>
- DeckResponse.java → id, name, cardCount, isFavorite, isStarter, isValid, errors
- DeckDetailResponse.java → DeckResponse + cards: List<{cardId, name, quantity, rarity}>
- ValidationResponse.java → valid, errors: List<String>

SERVICIO - DeckService.java:
- createDeck(Long userId, DeckCreateRequest) → DeckResponse
- getDecksByUser(Long userId) → List<DeckResponse>
- getDeckById(Long deckId, Long userId) → DeckDetailResponse
  (verificar que el deck pertenece al usuario O es starter)
- updateDeck(Long deckId, Long userId, DeckUpdateRequest) → DeckDetailResponse
  (solo si pertenece al usuario)
- deleteDeck(Long deckId, Long userId) → void
  (solo si pertenece al usuario y no es starter)
- validateDeck(Long deckId) → ValidationResponse
  (delega a DeckValidationService)
- toggleFavorite(Long deckId, Long userId) → Boolean
- getStarters() → List<DeckResponse>
- copyStarter(Long starterId, Long userId) → DeckResponse

CONTROLADOR - DeckController.java:
- POST   /decks                → createDeck
- GET    /decks                → getDecksByUser (userId del token JWT)
- GET    /decks/{id}           → getDeckById
- PUT    /decks/{id}           → updateDeck
- DELETE /decks/{id}           → deleteDeck
- POST   /decks/{id}/validate  → validateDeck
- PUT    /decks/{id}/favorite  → toggleFavorite
- GET    /decks/starters       → getStarters
- POST   /decks/{id}/copy      → copyStarter

SEED de starters: crear CommandLineRunner que cree 3 mazos starter si no existen
(usar cartas del set xy1: 20 Pokémon básicos + 20 energías + 20 trainers)

TESTS - DeckServiceTest.java:
- Crear mazo → OK
- Ver mazo de otro usuario → SecurityException (403)
- Validar mazo inválido → retorna errores
- Copiar starter → crea copia para el usuario
- Eliminar mazo starter → error

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea
```
api/src/main/java/com/codemon/decks/
  entity/Deck.java
  entity/DeckCard.java
  repository/DeckRepository.java
  repository/DeckCardRepository.java
  service/DeckService.java
  controller/DeckController.java
  dto/DeckCreateRequest.java
  dto/DeckUpdateRequest.java
  dto/DeckResponse.java
  dto/DeckDetailResponse.java
  dto/ValidationResponse.java
api/src/test/java/com/codemon/decks/DeckServiceTest.java
```

## Errores comunes

- **N+1 queries al cargar cartas del mazo**: usar `@EntityGraph` o `JOIN FETCH` en el repository
- **Acceso al mazo de otro usuario**: verificar `deck.getUserId().equals(userId)` en TODO endpoint que modifica
- **Starters sin `user_id`**: la columna es nullable para los mazos del sistema; verificar que JPA acepta null
- **`copyStarter` duplica el mazo starter**: crear una copia con nuevo `id` y el `userId` del usuario solicitante

## Verificación

```bash
TOKEN="eyJ..."  # access token del login

# Crear mazo
curl -X POST http://localhost:8088/decks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Mi mazo"}'
# PASS: {"id":1,"name":"Mi mazo","cardCount":0,"isValid":false}
# FAIL: 401 → token inválido; 403 → SecurityConfig mal configurada

# Ver starters
curl http://localhost:8088/decks/starters \
  -H "Authorization: Bearer $TOKEN"
# PASS: lista de 3 starters
# FAIL: lista vacía → CommandLineRunner de starters no corrió

# Copiar starter
curl -X POST http://localhost:8088/decks/1/copy \
  -H "Authorization: Bearer $TOKEN"
# PASS: {"id":4,"name":"Copia de Starter Fuego","isStarter":false}
# FAIL: 403 o 404 → verificar lógica de copyStarter en DeckService
```

## Dependencias
PASO_S02_01 (DeckValidationService), PASO_S01_01 (autenticación con JWT), PASO_S02_02 (cartas en BD para el seed de starters).

---

## Entrega al siguiente paso

Tras completar este PASO, los siguientes (PASO_S02_04, PASO_S03_03) pueden asumir:

- **Endpoints REST disponibles**:
  - `GET /api/decks` (mazos del usuario autenticado)
  - `POST /api/decks` (crear mazo, validación al guardar)
  - `GET /api/decks/{id}` (detalle)
  - `PUT /api/decks/{id}` (actualizar)
  - `DELETE /api/decks/{id}`
  - `GET /api/decks/starters` (3 mazos starter del sistema)
  - `POST /api/decks/{id}/copy` (copia un starter al usuario)
- **Bean Spring autowireable**: `DeckService` con validación integrada
- **Entidades**: `Deck` y `DeckCard` en `com.codemon.decks.entity` (relación many-to-many con cantidad)
- **Mazos starter** sembrados en BD (3 mazos: Fuego, Agua, Planta) listos para copiar
- Para PASO_S03_03 (SetupState): se puede pedir `deckId` y obtener `List<Card>` para inicializar la partida

---

## Definition of Done

- [ ] Todos los archivos de `outputs:` existen
- [ ] `./verify_paso.sh PASO_S02_03` retorna exit 0
- [ ] Crear mazo válido devuelve 201; mazo inválido devuelve 400 con detalles
- [ ] Solo el dueño puede modificar/eliminar su mazo (verificar 403 con otro JWT)
- [ ] Los 3 starters están sembrados y son visibles vía `GET /api/decks/starters`
- [ ] Tests pasan con cobertura ≥ 80% en `com.codemon.decks`
- [ ] Sin TODOs ni FIXMEs
- [ ] Naming respeta [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md)
