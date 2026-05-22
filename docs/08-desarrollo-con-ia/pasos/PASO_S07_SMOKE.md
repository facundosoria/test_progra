---
id: PASO_S07_SMOKE
equipo: A+B+C
bloque: 7
dep: [PASO_S07_01, PASO_S07_02, PASO_S05_04, PASO_S06_01]
siguiente: PASO_S08_01
context_files:
  - GLOSARIO.md
  - CONVENCIONES.md
outputs: []
---

# PASO S7.SMOKE — Validación de Salas + Matchmaking + Tablero Frontend
**Grupo legacy:** 3 | **Sprint:** S7 | **Equipo:** TODOS | **Dificultad:** 🟡 | **Tiempo:** 30 min

## Navegación
← **Anterior:** [PASO_S06_01.md](PASO_S06_01.md)
→ **Siguiente:** [PASO_S08_01](PASO_S08_01.md) — Sobres + colección

---

## Qué valida este paso

Que dos clientes pueden jugar una **partida PvP en tiempo real** vía WebSocket: matchmaking ranked encuentra rival, frontend renderiza el tablero, las acciones del cliente llegan al backend y el estado se sincroniza para ambos jugadores.

---

## Verificación automatizada

```bash
API="http://localhost:8088"

# 1. Crear sala privada
ROOM=$(curl -fs -X POST "$API/api/rooms" -H "Authorization: Bearer $TOKEN_A" -d '{"deckId":1}')
echo "$ROOM" | grep -q '"code"'                                                     # PASS si: tiene code
CODE=$(echo "$ROOM" | grep -oE '"code":"[^"]+"' | cut -d'"' -f4)

# 2. Segundo jugador une la sala
curl -fs -X POST "$API/api/rooms/$CODE/join" -H "Authorization: Bearer $TOKEN_B" -d '{"deckId":2}' | grep -q '"gameId"'  # PASS

# 3. Matchmaking ranked: dos jugadores entran a la cola, el sistema crea partida
curl -fs -X POST "$API/api/matchmaking/queue" -H "Authorization: Bearer $TOKEN_A" -d '{"deckId":1}' | grep -q '"queued":true'   # PASS
curl -fs -X POST "$API/api/matchmaking/queue" -H "Authorization: Bearer $TOKEN_B" -d '{"deckId":2}' | grep -q '"queued":true'   # PASS
sleep 5
curl -fs "$API/api/matchmaking/status" -H "Authorization: Bearer $TOKEN_A" | grep -q '"matched":true'                            # PASS si: matched

# 4. Redis tiene la cola (verificar limpieza tras match)
docker exec codemon_redis redis-cli zcard "matchmaking:queue" | awk '$1==0 {exit 0} {exit 1}'  # PASS si: cola vacía tras match

# 5. Frontend tablero compila sin errores
cd ~/codemon/front && ng build --configuration development                          # PASS si: BUILD SUCCESS

# 6. Tests E2E del tablero (Playwright si está configurado)
# Manual: dos navegadores, login con dos usuarios, crear sala, unirse, jugar 1 turno
# Verificar:
# - Ambos ven el tablero sincronizado
# - Acciones de un jugador aparecen en el otro vía WebSocket
# - CARD_DRAWN solo aparece para el dueño
# - Reconexión funciona (cerrar tab, reabrir, ver estado restaurado)

# 7. Eventos WebSocket llegan al frontend con campos correctos
# Inspector del navegador → Network → WS → ver primer mensaje:
# - eventType: string (SCREAMING_SNAKE_CASE)
# - gameId: number
# - timestamp: string ISO 8601
# - payload: object
```

---

## Definition of Done — GATE 3 + GATE 4

- [ ] Salas privadas funcionan (crear, unirse, comenzar partida)
- [ ] Matchmaking ranked encuentra rival cuando hay 2+ en cola con ELO compatible
- [ ] Cola Redis se limpia tras match (sorted set vacío)
- [ ] Frontend del tablero conecta vía WebSocket y mantiene estado sincronizado
- [ ] Reconexión tras desconexión recupera estado (vía `GET /api/games/{id}/state`)
- [ ] Eventos WebSocket cumplen formato canónico (sección 4 de [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md))
- [ ] Privacy: CARD_DRAWN solo al dueño verificado en navegador

---

## Si falla un check

| Check | Acción |
|---|---|
| Matchmaking nunca matchea | revisar PASO_S07_02 (rango ELO ±200, criterio de búsqueda) |
| Cola Redis no se limpia | revisar `dequeue` en `QueueService` |
| Frontend no recibe eventos | revisar URL WS (en Docker es `/ws`, no `ws://localhost`) |
| Eventos con `type` en lugar de `eventType` | el frontend está leyendo el campo equivocado — alinear con [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md) |
| CARD_DRAWN visible al rival | bug crítico — revisar `convertAndSendToUser` vs `convertAndSend` |
