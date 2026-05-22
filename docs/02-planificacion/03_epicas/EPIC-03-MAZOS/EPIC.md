# EPIC-03 — Constructor de Mazos

## 1. Resumen

- **Valor de negocio:** los jugadores pueden armar y editar mazos validos de 60 cartas para usar en partidas. Es prerequisito para EPIC-04 (motor) y EPIC-05 (matchmaking).
- **Roles involucrados:** Jugador autenticado.
- **Sprints donde se completa:** S2.
- **Equipos:** A (backend CRUD + validador), B (drag & drop UI).

## 2. Historias de Usuario

### HU-03-01 — Crear un mazo nuevo
**Como** jugador, **quiero** crear un mazo nuevo desde cero, **para** personalizar mi estrategia.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: `POST /decks` con `{name, description}` crea un mazo vacio del usuario logueado.
- AC2: Devuelve 201 con `deckId`.
- AC3: Maximo 20 mazos por usuario; el 21o intento devuelve 422.

**RNF:**
- RNF-Seguridad: solo el dueno modifica el mazo (verificacion en cada endpoint).
- RNF-Performance: P95 < 200 ms.

**Sprint:** S2.

---

### HU-03-02 — Editar un mazo con drag & drop
**Como** jugador, **quiero** arrastrar cartas desde el catalogo a mi mazo, **para** armarlo visualmente.

**Story Points:** 8

**Criterios de Aceptacion:**
- AC1: La UI del Deck Builder muestra catalogo a la izquierda y mazo a la derecha.
- AC2: Drag de una carta al mazo aumenta su quantity en 1; drop fuera del mazo la quita.
- AC3: Cambios persisten via `PUT /decks/{id}` con debounce 1 s.
- AC4: La validacion (HU-03-03) corre en tiempo real y muestra errores especificos.

**RNF:**
- RNF-Usabilidad: feedback visual de drag (cursor, sombra) < 100 ms.
- RNF-Compatibilidad: funciona en Chrome, Firefox, Safari (escritorio + tablet).

**Dependencias:** HU-02-01, HU-03-01.
**Sprint:** S2.

---

### HU-03-03 — Validar que mi mazo cumpla las reglas TCG XY1
**Como** jugador, **quiero** que el sistema me avise si mi mazo es invalido, **para** no entrar a una partida con un mazo ilegal.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: R-DECK-01: el mazo tiene exactamente 60 cartas.
- AC2: R-DECK-02: tiene al menos 1 Pokemon Basico (excluye Restaurados).
- AC3: R-DECK-03: maximo 4 copias de cualquier carta excepto Energia Basica (ilimitada).
- AC4: R-DECK-04: maximo 4 Energias Especiales en total.
- AC5: R-DECK-05: maximo 1 ACE SPEC.
- AC6: `POST /decks/{id}/validate` devuelve la lista completa de errores (no solo el primero).
- AC7: La UI muestra cada error con la regla violada.

**RNF:**
- RNF-Calidad: `DeckValidationService` ≥ 90% cobertura JaCoCo.
- RNF-Performance: validacion < 50 ms (puro Java sin BD).

**Dependencias:** HU-03-02.
**Sprint:** S2.

---

### HU-03-04 — Eliminar un mazo
**Como** jugador, **quiero** borrar mazos que ya no uso, **para** mantener mi lista limpia.

**Story Points:** 2

**Criterios de Aceptacion:**
- AC1: `DELETE /decks/{id}` borra el mazo si pertenece al usuario.
- AC2: Borrar un starter de sistema devuelve 422 `CANNOT_DELETE_STARTER`.
- AC3: Borrar mazo de otro usuario devuelve 403.
- AC4: Confirmacion previa en la UI (modal).

**Sprint:** S2.

---

### HU-03-05 — Marcar un mazo como favorito
**Como** jugador, **quiero** marcar 1 mazo como favorito, **para** que sea el preseleccionado al entrar a la cola.

**Story Points:** 2

**Criterios de Aceptacion:**
- AC1: `PUT /decks/{id}/favorite` toggle del flag.
- AC2: Solo 1 mazo favorito por usuario; al marcar otro, se desmarca el anterior.
- AC3: La UI muestra estrella sobre el mazo favorito.

**Sprint:** S2.

---

### HU-03-06 — Copiar un mazo starter
**Como** jugador novato, **quiero** copiar uno de los 3 mazos starter, **para** empezar a jugar sin tener que armar uno.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: `GET /decks/starters` lista los 3 mazos starter del sistema.
- AC2: `POST /decks/starters/{id}/copy` clona el starter en mis mazos.
- AC3: El usuario debe tener las cartas del starter en su coleccion solo a nivel UI; backend permite copiar siempre (es educativo).
- AC4: El mazo copiado es editable (no es un starter del sistema).

**Sprint:** S2.

## 3. Tareas Tecnicas

| ID | Tarea | Origen | Equipo | SP | Sprint |
|---|---|---|---|---|---|
| TT-03-01 | `DeckValidationService` puro Java (5 reglas R-DECK-01..05) | PASO_S02_01 | A | 5 | S2 |
| TT-03-02 | Endpoints CRUD `/decks/**` con verificacion de pertenencia | PASO_S02_03 | A | 5 | S2 |
| TT-03-03 | Seed de 3 mazos starter al arranque si no existen | PASO_S02_03 | A | 2 | S2 |
| TT-03-04 | UI Deck Builder con `@angular/cdk/drag-drop` | PASO_S02_04 | B | 8 | S2 |

## 4. Contratos involucrados

- REST: `POST /decks`, `GET /decks`, `GET /decks/{id}`, `PUT /decks/{id}`, `DELETE /decks/{id}`, `POST /decks/{id}/validate`, `PUT /decks/{id}/favorite`, `GET /decks/starters`, `POST /decks/starters/{id}/copy`.
- STOMP: ninguno.

## 5. Definition of Done especifico

- 5 reglas R-DECK-01..05 testeadas con casos felices y de error.
- Cobertura `DeckValidationService` ≥ 90%.
- Drag & drop verificado manualmente en Chrome y Firefox.
- Tests integracion CRUD: ver mazo ajeno → 403; eliminar starter → 422.
- 3 mazos starter cargados via seed y validan correctamente.
- Hereda [DOD.md](../../04_proceso/DOD.md) global.
