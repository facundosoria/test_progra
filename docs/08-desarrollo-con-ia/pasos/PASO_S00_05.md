---
id: PASO_S00_05
equipo: A
bloque: 0
dep: [PASO_S00_04]
siguiente: PASO_S00_06
context_files:
  - BD_Y_TABLAS.md
  - xy1.json
  - CONVENCIONES.md
outputs:
  - api/src/main/resources/db/migration/V1__users_auth.sql
  - api/src/main/resources/db/migration/V2__email_verif.sql
  - api/src/main/resources/db/migration/V3__cards.sql
  - api/src/main/resources/db/migration/V4__decks.sql
  - api/src/main/resources/db/migration/V5__booster_collection.sql
  - api/src/main/resources/db/migration/V6__payments.sql
  - api/src/main/resources/db/migration/V7__matchmaking.sql
  - api/src/main/resources/db/migration/V8__rooms.sql
  - api/src/main/resources/db/migration/V9__games.sql
  - api/src/main/resources/db/migration/V10__chat.sql
  - api/src/main/resources/db/migration/V11__views.sql
  - api/src/main/resources/db/migration/V12__seed_cards.sql
  - api/src/main/resources/db/migration/V13__seed_starter_decks.sql
  - api/src/main/resources/db/migration/V14__seed_booster_packs.sql
  - api/src/main/resources/db/migration/V15__add_final_constraints.sql
---

# PASO 0.4 — Crear migraciones Flyway
**Grupo legacy:** 0 — Infraestructura | **Equipo:** A | **Dificultad:** 🟡 | **Tiempo:** 2–3 h

## Navegación
← **Anterior:** [PASO_S00_04](PASO_S00_04.md) — Spring Boot + application.yml configurado
→ **Siguiente:** [PASO_S02_01](PASO_S02_01.md) — Validación de mazos (DeckValidationService)

## Archivos a cargar junto a este
- `SCHEMA_BD.sql` (o `BD_Y_TABLAS.md`) — el schema completo
- `xy1.json` — fuente real de las 146 cartas XY1

## Qué construye este paso
Divide el schema SQL completo en 15 archivos de migración Flyway numerados. Flyway los ejecutará en orden al arrancar la API, creando todas las tablas, índices y vistas. Además deja listo el JSON real de cartas para que `CardSeedRunner` lo use en `PASO_S02_02`.

## Hacer

```bash
mkdir -p ~/codemon/api/src/main/resources/db/migration
mkdir -p ~/codemon/api/src/main/resources/seed
# Ejecutar desde la raiz del handoff Proyecto_Final.
# Copiar el JSON fuente como cards.json, que es el nombre que lee Spring Boot.
cp docs/05-referencia-tecnica/xy1.json ~/codemon/api/src/main/resources/seed/cards.json
```

## Prompt listo para el agente

```
Tengo el schema completo de mi proyecto en el SQL que te pegué arriba.

Necesito que lo dividas en exactamente 15 archivos de migración Flyway para PostgreSQL.
Cada archivo corresponde a un bloque comentado del SQL.

Para cada archivo:
- El nombre debe ser exactamente: V{N}__{descripcion_en_snake_case}.sql
- El contenido es el bloque SQL del SCHEMA_BD.sql que corresponde a ese número
- No modifiques ninguna línea del SQL, solo divídelo

Los 15 archivos que espero:
V1__users_auth.sql            → tabla users, refresh_tokens
V2__email_verif.sql           → tabla email_verifications
V3__cards.sql                 → tabla cards_catalog
V4__decks.sql                 → tablas decks, deck_cards
V5__booster_collection.sql    → tablas booster_packs, user_booster_packs, user_collection
V6__payments.sql              → tablas payment_records, payment_webhooks_log
V7__matchmaking.sql           → tablas queue_entries, skill_ratings
V8__rooms.sql                 → tablas game_rooms, game_room_players
V9__games.sql                 → tablas games, game_state_snapshots, game_events
V10__chat.sql                 → tabla game_chat_messages
V11__views.sql                → vistas materializadas leaderboard
V12__seed_cards.sql           → reservas/metadata de seed si hace falta; las 146 cartas se cargan desde seed/cards.json en PASO_S02_02
V13__seed_starter_decks.sql   → seed de mazos starter (si existe)
V14__seed_booster_packs.sql   → seed de sobres (si existe)
V15__add_final_constraints.sql → constraints adicionales (si existe)

Dame los archivos con su nombre y contenido completo.
Los archivos van en: api/src/main/resources/db/migration/

Aplicá las convenciones de CONVENCIONES.md.
```

## Archivos que crea
```
api/src/main/resources/db/migration/V1__users_auth.sql
api/src/main/resources/db/migration/V2__email_verif.sql
api/src/main/resources/db/migration/V3__cards.sql
api/src/main/resources/db/migration/V4__decks.sql
api/src/main/resources/db/migration/V5__booster_collection.sql
api/src/main/resources/db/migration/V6__payments.sql
api/src/main/resources/db/migration/V7__matchmaking.sql
api/src/main/resources/db/migration/V8__rooms.sql
api/src/main/resources/db/migration/V9__games.sql
api/src/main/resources/db/migration/V10__chat.sql
api/src/main/resources/db/migration/V11__views.sql
api/src/main/resources/db/migration/V12__seed_cards.sql
api/src/main/resources/db/migration/V13__seed_starter_decks.sql
api/src/main/resources/db/migration/V14__seed_booster_packs.sql
api/src/main/resources/db/migration/V15__add_final_constraints.sql
```

## Errores comunes

| Error | Causa | Solución |
|---|---|---|
| `Migration checksum mismatch` | Editaste un archivo ya ejecutado | `docker compose down -v && docker compose up postgres -d` |
| FK error al ejecutar | Tabla referenciada no existe aún | Verificar que el orden V1–V15 es correcto |
| `flyway_schema_history` bloqueada | Flyway corrió parcialmente | `docker compose down -v` para resetear |

## Verificación

```bash
cd ~/codemon/api && ./mvnw spring-boot:run
# PASS: logs contienen "Successfully applied 15 migrations to schema 'public'"
# FAIL: cualquier excepción Flyway o BUILD FAILURE

docker exec codemon_postgres psql -U codemon_user -d codemon_db -c "\dt" | wc -l
# PASS: número >= 22
# FAIL: número < 22 → alguna migración falló, revisar orden V1–V15
```

## Dependencias
PASO_S00_04 completado (proyecto Spring Boot con application.yml).
