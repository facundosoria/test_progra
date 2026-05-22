---
id: PASO_S02_SMOKE
equipo: A+B
bloque: 2
dep: [PASO_S02_01, PASO_S01_01, PASO_S02_02, PASO_S02_03, PASO_S01_02, PASO_S01_03, PASO_S02_04, PASO_S02_05]
siguiente: PASO_S03_01
context_files:
  - GLOSARIO.md
  - CONVENCIONES.md
outputs: []
---

# PASO S1-S2.SMOKE — Validación integral de Auth + Cartas + Mazos
**Grupo legacy:** 1/1B | **Sprint:** S1-S2 | **Equipo:** A+B | **Dificultad:** 🟢 | **Tiempo:** 30 min

## Navegación
← **Anterior:** [PASO_S02_05.md](PASO_S02_05.md)
→ **Siguiente:** [PASO_S03_01](PASO_S03_01.md) — GameContext + State Machine

---

## Qué valida este paso

Que el flujo end-to-end **Auth + Cartas + Mazos** funciona contra backend real (con `environment.useMocks=false`). Cubre GATE 1a y GATE 1b antes de arrancar el motor de juego.

---

## Verificación automatizada

```bash
API="http://localhost:8088"

# 1. Auth: registrar y loguear genera JWT válido
curl -fs -X POST "$API/api/auth/register" -H "Content-Type: application/json" -d '{"email":"smoke@test.com","password":"Test1234!"}' -o /dev/null  # PASS si: HTTP 201

LOGIN=$(curl -fs -X POST "$API/api/auth/login" -H "Content-Type: application/json" -d '{"email":"smoke@test.com","password":"Test1234!","rememberMe":false}')
echo "$LOGIN" | grep -q '"accessToken"'                                                                                                   # PASS si: tiene accessToken
TOKEN=$(echo "$LOGIN" | grep -oE '"accessToken":"[^"]+"' | cut -d'"' -f4)

# 2. Catálogo: 146 cartas XY1 con imágenes de MinIO
COUNT=$(curl -fs "$API/api/cards?size=200" | grep -oE '"id"' | wc -l)
test "$COUNT" -ge 146                                                          # PASS si: ≥146 cartas

# 3. Cada carta tiene imageSmallUrl apuntando a MinIO
curl -fs "$API/api/cards/xy1-1" | grep -q 'minio\|imageSmall'                  # PASS si: URL de MinIO

# 4. Mazo válido se acepta (60 cartas, sin errores)
DECK=$(curl -fs -X POST "$API/api/decks" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"name":"smoke-deck","cards":[{"cardId":"xy1-1","quantity":4}, ... ]}')  # nota: cargar 60 cartas reales
# PASS si: HTTP 201 y devuelve deckId

# 5. Mazo inválido (59 cartas) se rechaza con error específico
curl -fs -X POST "$API/api/decks" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"name":"bad","cards":[{"cardId":"xy1-1","quantity":59}]}' | grep -q '"error"'  # PASS si: tiene "error"

# 6. Endpoint protegido rechaza requests sin token
curl -fs -o /dev/null -w "%{http_code}" "$API/api/decks" | grep -q "401"       # PASS si: HTTP 401

# 7. Frontend compila + tests pasan
cd ~/codemon/front && ng test --watch=false --browsers=ChromeHeadless        # PASS si: BUILD SUCCESS

# 8. E2E mínimo (smoke): login → ver catálogo
# Manual o con Playwright (configurado en PASO_S11_06 si existe)
```

---

## Definition of Done — GATE 1a + GATE 1b

- [ ] Los 8 checks pasan
- [ ] Un usuario puede registrarse, verificar email (mock o real), y loguearse desde el frontend
- [ ] El catálogo muestra 146 cartas con imágenes funcionales
- [ ] Crear y validar un mazo desde el frontend funciona contra el backend real
- [ ] `environment.useMocks` puede ponerse a `false` y todo sigue funcionando
- [ ] Cobertura backend ≥ 80% en `auth`, `cards`, `decks`
- [ ] Cobertura frontend ≥ 80% en `auth`, `decks`, `cards`

---

## Si falla un check

| Check | Acción |
|---|---|
| Auth registro/login | revisar PASO_S01_01 (JWT secret ≥32 chars) |
| Catálogo < 146 | revisar `CardSeedRunner` de PASO_S02_02 (debe correr una sola vez) |
| Imágenes sin URL MinIO | revisar `MinioService` y bucket `codemon-cards` público |
| Mazo válido rechazado | revisar `DeckValidationService` de PASO_S02_01 |
| 401 sin token | revisar filtro JWT en `SecurityConfig` |
