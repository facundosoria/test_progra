---
id: PASO_S05_SMOKE
equipo: A
bloque: 5
dep: [PASO_S03_01, PASO_S03_02, PASO_S03_03, PASO_S03_04, PASO_S03_05, PASO_S04_01, PASO_S04_02, PASO_S05_01, PASO_S05_02, PASO_S05_03]
siguiente: PASO_S06_01
context_files:
  - GLOSARIO.md
  - CONVENCIONES.md
  - 06-system-logic.md
outputs: []
---

# PASO S5.SMOKE — Validación integral del Motor de Juego (GATE 2)
**Grupo legacy:** 2 | **Sprint:** S5 | **Equipo:** A | **Dificultad:** 🟡 | **Tiempo:** 45 min

## Navegación
← **Anterior:** [PASO_S05_03](PASO_S05_03.md) — GameEngine completo
→ **Siguiente:** [PASO_S07_01](PASO_S07_01.md) — Salas privadas (paralelo a PASO_S05_04)

---

## Qué valida este paso

El **GATE 2** del proyecto: una partida PvE end-to-end (setup → turnos → ataque → KO → victoria) con WebSocket emitiendo eventos correctos y privacidad respetada. Es el checkpoint más crítico del proyecto.

---

## Verificación automatizada

```bash
API="http://localhost:8088"
TOKEN="${TOKEN:?ejecutar: TOKEN=\$(curl -X POST $API/api/auth/login ... | jq -r .accessToken)}"

# 1. Cobertura mínima del motor (RNF-03)
cd ~/codemon/api && ./mvnw test jacoco:report                                         # PASS si: BUILD SUCCESS
grep -A1 'DamageCalculator' target/site/jacoco/index.html | grep -oE '[0-9]+%' | head -1 | awk '{gsub("%",""); if ($1>=90) exit 0; else exit 1}'  # PASS si: ≥90%
# Repetir para StatusEffectManager, AttackPipeline, VictoryConditionChecker

# 2. Crear partida PvE
GAME=$(curl -fs -X POST "$API/api/games" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"deckId":1,"matchType":"PVE","botDifficulty":"EASY"}')
echo "$GAME" | grep -q '"gameId"'                                                       # PASS si: tiene gameId
GAME_ID=$(echo "$GAME" | grep -oE '"gameId":[0-9]+' | cut -d':' -f2)

# 3. Estado sanitizado: rival no ve hand del jugador, nadie ve deck ni prizes
STATE=$(curl -fs "$API/api/games/$GAME_ID/state" -H "Authorization: Bearer $TOKEN")
echo "$STATE" | grep -q '"hand":\[' || echo "$STATE" | grep -q '"handCount":'           # jugador SÍ ve su hand
echo "$STATE" | grep -qE '"deck":(null|\[\])'                                            # PASS si: deck oculto
echo "$STATE" | grep -qE '"prizes":(null|\[\])'                                          # PASS si: prizes oculto
echo "$STATE" | grep -q '"deckSize":'                                                    # PASS si: solo size visible
echo "$STATE" | grep -q '"prizesCount":'                                                 # PASS si: solo count visible

# 4. Acción fuera de turno → 403
HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/api/games/$GAME_ID/action" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"type":"DECLARE_ATTACK","playerId":999}')
test "$HTTP" = "403"                                                                      # PASS si: 403

# 5. Eventos WebSocket emiten con formato canónico (eventType, gameId numérico, timestamp)
# Manual con cliente STOMP o test integración:
# - Suscribirse a /topic/game/$GAME_ID
# - Verificar al menos un evento con campos: eventType (SCREAMING_SNAKE_CASE), gameId (number), timestamp (ISO 8601), payload (object)

# 6. CARD_DRAWN solo llega al dueño (privacy crítica)
# Manual: dos suscriptores STOMP, uno como player1, otro como player2
# - player1 hace acción que dispara CARD_DRAWN
# - player1 RECIBE CARD_DRAWN en /user/queue/game con cardId
# - player2 NO recibe CARD_DRAWN; ve solo deckRemaining en evento público

# 7. Partida completa termina con GAME_OVER
# Test de integración (no curl): correr una partida automática hasta el final
./mvnw test -Dtest=GameEngineIntegrationTest                                              # PASS si: BUILD SUCCESS

# 8. Snapshot de partida persistido en BD
docker exec codemon_postgres psql -U codemon_user -d codemon_db -tAc \
  "SELECT count(*) FROM game_state_snapshots WHERE game_id = $GAME_ID" | awk '$1>=1 {exit 0} {exit 1}'  # PASS si: ≥1 snapshot

# 9. Eventos persistidos en game_events
docker exec codemon_postgres psql -U codemon_user -d codemon_db -tAc \
  "SELECT count(*) FROM game_events WHERE game_id = $GAME_ID" | awk '$1>=1 {exit 0} {exit 1}'  # PASS si: ≥1 evento
```

---

## Definition of Done — GATE 2

- [ ] Los 9 checks automatizados pasan
- [ ] Cobertura ≥ 90% en DamageCalculator, StatusEffectManager, AttackPipeline, VictoryConditionChecker
- [ ] Cobertura global del motor ≥ 80%
- [ ] Una partida PvE end-to-end (setup → turnos → ataque → KO → victoria) corre sin errores 500 en logs
- [ ] El "Checklist final del motor completo" de [PASO_S05_03.md](PASO_S05_03.md) está marcado al 100%
- [ ] PASO_S05_04 (frontend tablero) puede arrancar — el contrato WebSocket está estable

---

## Verificación del Card Handler Registry (checks adicionales)

Estos checks validan el sistema de efectos por carta (ver `PATRON_CARD_HANDLER.md`):

```bash
# 10. Ataque que ignora debilidad — Greninja Mist Slash
# Setup: defensor con weakness al agua (×2), Greninja ataca con Mist Slash (60 daño base)
# PASS: DAMAGE_DEALT.finalDamage == 60 (no 120 — weakness ignorada)
# FAIL: finalDamage == 120 → ApplyAttackerEffectsHandler no setea ignoreWeakness

# 11. Harden de Kakuna — prevención de daño por marker
# Setup: Kakuna usa Harden; oponente ataca con 40 daño en su próximo turno
# PASS: Kakuna no recibe daño (40 ≤ 60 threshold de Harden)
# FAIL: Kakuna recibe daño → marker no se setea o KakunaHandler no intercepta DealDamage

# 12. Marker limpiado correctamente en EndPhase
# Setup: Kakuna usó Harden → oponente termina su turno
# PASS: en el turno siguiente del oponente, Kakuna SÍ recibe daño normalmente
# FAIL: Kakuna sigue protegido → marker no se limpia en onEndTurn

# 13. Trevenant Forest's Curse bloquea Items
# Setup: Trevenant como Activo del jugador A
# PASS: jugador B intenta PLAY_ITEM → error 400 "Forest's Curse..."
# FAIL: Item se juega normalmente → onBeforePlayItem no se propaga en MainPhaseState

# 14. Slurpuff Sweet Veil previene condiciones
# Setup: Slurpuff en Banca, Activo propio tiene Fairy Energy
# PASS: oponente aplica POISONED → Activo no queda envenenado
# FAIL: Activo queda envenenado → onBeforeApplyStatus no se propaga en StatusEffectManager

# 15. Furfrou Fur Coat reduce 20 después de W/R
# Setup: Furfrou como Activo (sin weakness/resistance relevante)
#        Oponente ataca con 60 daño base
# PASS: DAMAGE_DEALT.finalDamage == 40 (60 - 20 de Fur Coat)
# FAIL: finalDamage == 60 → ApplyDefenderEffectsHandler no propaga o FurfouHandler no intercepta

# 16. Snapshot con markers sobrevive deserialización
# Setup: Kakuna usa Harden → snapshot guardado → simular reconexión (cargar desde snapshot)
# PASS: board.active.marker.hasMarker("KAKUNA_HARDEN") == true después de deserializar
# FAIL: marker se pierde → campo Marker tiene @Transient o @JsonIgnore

# 17. Slurpuff emite STATUS_BLOCKED (no STATUS_APPLIED) y la UI lo recibe
# Setup: Slurpuff en Banca propia, Pokémon Activo con 1 Energía Hada adjunta
# Oponente ataca con efecto que aplicaría POISONED
# PASS:
#   - se publica STATUS_BLOCKED con targetPokemonName, blockingAbilityName="Sweet Veil", blockingCardId
#   - NO se publica STATUS_APPLIED
#   - el daño del ataque sí se aplica (el bloqueo afecta solo al efecto secundario, no al daño)
# FAIL:
#   - STATUS_APPLIED publicado → onBeforeApplyStatus no se propaga o ctx.isBlocked() ignorado
#   - STATUS_BLOCKED ausente → StatusEffectManager no emite el evento
#   - el daño del ataque no se aplica → el bloqueo se confundió con cancelar el ataque

# 18. Arbok Gastro Acid bloquea USE_ABILITY del target afectado
# Setup: Arbok ataca con Gastro Acid contra Pokémon X → marker GASTRO_ACID_MARKER
#        en el slot del target. Turno siguiente del oponente: dueño de X intenta USE_ABILITY
# PASS: error 400 con mensaje del hook onBeforeUseAbility (GameActionException de ArbokHandler)
# FAIL:
#   - la habilidad se ejecuta normalmente → MainPhaseState no propaga onBeforeUseAbility
#   - error 500 en el log → CardHandler.onBeforeUseAbility no existe en la interfaz
```

---

## Si falla un check de Card Handler

| Check | Acción |
|---|---|
| #10 — ignoreWeakness no funciona | Verificar que `ApplyAttackerEffectsHandler` está en la cadena ANTES de `ApplyWeaknessHandler` en `AttackPipeline.buildChain()` |
| #11 — Harden no previene daño | Verificar que `KakunaHandler` está registrado como `@Component` y que `CardHandlerRegistry.getActiveHandlers()` lo retorna |
| #12 — Marker no se limpia | Verificar que `EndPhaseState.onEnter()` llama `registry...forEach(h -> h.onEndTurn(...))` ANTES de `switchActivePlayer()` |
| #13 — Trevenant no bloquea | Verificar que `MainPhaseState.handleAction(PLAY_ITEM)` propaga `onBeforePlayItem` antes de ejecutar el Item |
| #14 — Slurpuff no previene | Verificar que `StatusEffectManager.applyStatus()` propaga y chequea `statusCtx.isBlocked()` |
| #15 — Furfrou no reduce | Verificar que `ApplyDefenderEffectsHandler` está entre `ApplyResistanceHandler` y `DealDamageHandler` en la cadena |
| #16 — Marker no serializa | Verificar que `Marker.java` NO tiene `@Transient` ni `@JsonIgnore`, y se inicializa en constructor |
| #17 — STATUS_BLOCKED no se emite | Verificar que `StatusEffectManager.applyStatus()` chequea `ctx.isBlocked()` ANTES de emitir `STATUS_APPLIED`, y publica `STATUS_BLOCKED` cuando isBlocked. Verificar que el evento incluye `targetPokemonName` y `blockingAbilityName` |
| #18 — Arbok no bloquea Habilidad | Verificar que la interfaz `CardHandler` incluye `onBeforeUseAbility(AbilityContext, GameContext)` y que `MainPhaseState.handleAction(USE_ABILITY)` propaga el hook ANTES de ejecutar la habilidad |

---

## Si falla un check

| Check | Acción |
|---|---|
| Cobertura < 90% en componentes críticos | escribir tests de los casos del checklist de PASO_S05_03 |
| 403 fuera de turno no funciona | revisar `processAction` en PASO_S05_03 |
| CARD_DRAWN público | revisar `event.isPrivate()` en `GameEventPublisher` |
| Eventos sin `eventType` (frontend lo lee como `type`) | revisar [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md) sección 4 — el campo es `eventType` no `type` |
| Snapshots no persisten | revisar `@Async` y la ejecución de `persistSnapshotAsync` |
