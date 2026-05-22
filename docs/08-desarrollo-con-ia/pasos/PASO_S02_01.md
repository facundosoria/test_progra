---
id: PASO_S02_01
equipo: A
bloque: 2
dep: [PASO_S00_05]
siguiente: PASO_S02_02
context_files:
  - 05-deck-validation.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/decks/service/DeckValidationService.java
  - api/src/main/java/com/codemon/decks/service/ValidationResult.java
  - api/src/test/java/com/codemon/decks/DeckValidationServiceTest.java
---

# PASO 1.1 — Validación de mazos
**Grupo legacy:** 1 — Features Core | **Equipo:** A | **Dificultad:** 🟡 | **Tiempo:** 3–4 h

## Navegación
← **Anterior:** [PASO_S00_05](PASO_S00_05.md) — Migraciones Flyway aplicadas (tablas en BD)
→ **Siguiente:** [PASO_S02_02](PASO_S02_02.md) — Catálogo de cartas + MinIO + seed

## Archivos a cargar junto a este
- `05-deck-validation.md` — reglas completas de validación

## Qué construye este paso
El servicio que valida si un mazo cumple las reglas del juego. Es independiente del resto y tiene tests con ≥90% de cobertura.

## Prompt listo para el agente

```
Implementá el servicio de validación de mazos para un juego de Pokemon TCG en Java 21 con Spring Boot 3.x.

Reglas del juego (del documento que te pasé):
[pegá aquí el contenido de 05-deck-validation.md]

Implementá:
1. **NO crear una clase `Card` propia.** La entidad canónica `com.codemon.cards.entity.Card` se construye en PASO_S02_02 (dependencia inversa). En este paso, definí los métodos de validación contra una **interfaz mínima** que puede ser un `record` interno o una abstracción `CardForValidation` con solo: `String supertype`, `List<String> subtypes`, `String name`, `String rarity`. PASO_S02_02 hará que la entidad real implemente o sea adaptable a esta interfaz. Documentá esta decisión en un comentario de paquete.
2. La interfaz y clase `DeckValidationService` con un método `validate(List<CardForValidation> cards)` que retorna `ValidationResult`. La firma final puede usar la entidad real cuando PASO_S02_02 esté completo (refactor pequeño en PASO_S02_03).
3. `ValidationResult` con campos: `boolean valid`, `List<String> errors`
4. Un método por cada regla (R-DECK-01 hasta R-DECK-07)
5. El método principal ejecuta TODAS las validaciones y acumula TODOS los errores (no para en el primero)
6. Tests unitarios con JUnit 5 para cada regla incluyendo los casos del borde indicados en las reglas

Nombre de paquete: com.codemon.decks.service
Usá @Service de Spring.
No incluyas lógica de controlador HTTP, solo el servicio y sus tests.

Casos de test mínimos que deben pasar:
- Mazo de 59 cartas → error específico
- Mazo de 61 cartas → error específico
- Sin Pokémon Básico → error específico
- 5 copias de "Pikachu" → error con nombre y cantidad
- 2 cartas ACE SPEC → error
- 10 Energías Básicas → VÁLIDO (sin límite)
- 5 "Double Colorless Energy" (Energía Especial) → error
- Mazo con 3 errores distintos → retorna los 3 juntos

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea
```
api/src/main/java/com/codemon/decks/service/DeckValidationService.java
api/src/main/java/com/codemon/decks/service/ValidationResult.java
api/src/test/java/com/codemon/decks/DeckValidationServiceTest.java
```

## Errores comunes

- **Devolver solo el primer error**: usar `List<String> errors` y acumular todos antes de retornar
- **Energía Especial sin límite**: `subtypes.contains("Special")` SÍ tiene límite de 4
- **Pokémon Restaurados contados como Básicos**: deben excluirse, tienen `subtypes.contains("Restored")`
- **ACE SPEC**: límite de 1 por mazo, tienen `subtypes.contains("ACE SPEC")`

## Verificación

```bash
# Test directo sin servidor
./mvnw test -Dtest=DeckValidationServiceTest
# PASS: "BUILD SUCCESS", todos los tests en verde
# FAIL: cualquier test fallido → revisar lógica de acumulación de errores

# Cobertura
./mvnw test jacoco:report
# PASS: DeckValidationService muestra ≥90% en target/site/jacoco/index.html
# FAIL: cobertura < 90% → agregar casos de test faltantes

# Después de implementar el controller (PASO 1.4):
curl -X POST http://localhost:8088/decks/validate \
  -H "Content-Type: application/json" \
  -d '{"cards":[]}'
# PASS: {"valid":false,"errors":["El mazo debe tener exactamente 60 cartas","El mazo debe tener al menos 1 Pokémon Básico"]}
# FAIL: retorna solo un error (el servicio está parando en el primero)
```

## Dependencias
PASO_S00_05 completado (tablas creadas en BD).
