---
id: PASO_S08_SMOKE
equipo: B+C
bloque: 8
dep: [PASO_S08_01, PASO_S08_02, PASO_S08_03, PASO_S08_04, PASO_S08_05, PASO_S08_06, PASO_S09_04]
siguiente: PASO_S09_01
context_files:
  - GLOSARIO.md
  - CONVENCIONES.md
outputs: []
---

# PASO S8.SMOKE — Validación de Tienda + 2FA + Pagos + Métricas
**Grupo legacy:** 4 | **Sprint:** S8 | **Equipo:** B+C | **Dificultad:** 🟡 | **Tiempo:** 30 min

## Navegación
← **Anterior:** [PASO_S09_04.md](PASO_S09_04.md)
→ **Siguiente:** [PASO_S09_01](PASO_S09_01.md) — Sistema de ranking por ligas

---

## Qué valida este paso

Que las features económicas del MVP funcionan: comprar sobres con MercadoPago sandbox, abrir sobres y recibir cartas en colección, operar wallet/tienda, recibir 2FA por email y monitorear con Grafana.

---

## Verificación automatizada

```bash
API="http://localhost:8088"

# 1. Listar packs disponibles
curl -fs "$API/api/shop/packs" -H "Authorization: Bearer $TOKEN" | grep -q '"price"'      # PASS si: hay packs

# 2. Crear preferencia MercadoPago (sandbox)
PREF=$(curl -fs -X POST "$API/api/payments/create-preference" -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -d '{"packId":1}')
echo "$PREF" | grep -q '"initPoint"'                                                       # PASS si: tiene URL

# 3. Webhook idempotente (mismo paymentId no acredita dos veces)
WEBHOOK_PAYLOAD='{"action":"payment.updated","data":{"id":"123456789"}}'
curl -fs -X POST "$API/api/payments/webhook" -d "$WEBHOOK_PAYLOAD" -H "Content-Type: application/json"
curl -fs -X POST "$API/api/payments/webhook" -d "$WEBHOOK_PAYLOAD" -H "Content-Type: application/json"
docker exec codemon_postgres psql -U codemon_user -d codemon_db -tAc \
  "SELECT count(*) FROM payment_records WHERE external_payment_id='123456789' AND status='APPROVED'" | awk '$1==1 {exit 0} {exit 1}'  # PASS si: solo un registro APPROVED

# 4. Abrir un sobre da 5 cartas según rareza
OPEN=$(curl -fs -X POST "$API/api/shop/open-pack/1" -H "Authorization: Bearer $TOKEN")
echo "$OPEN" | grep -oE '"cardId":"[^"]+"' | wc -l | awk '$1==5 {exit 0} {exit 1}'         # PASS si: 5 cartas

# 5. Cartas se agregaron a user_collection
docker exec codemon_postgres psql -U codemon_user -d codemon_db -tAc \
  "SELECT count(*) FROM user_collection WHERE user_id=1" | awk '$1>=5 {exit 0} {exit 1}'   # PASS si: ≥5

# 6. Stats/leaderboard base responde con datos ordenados por ELO
curl -fs "$API/api/leaderboard?size=10" -H "Authorization: Bearer $TOKEN" | grep -q '"elo"'  # PASS si: tiene ELO

# 7. 2FA: enviar código por email
curl -fs -X POST "$API/api/auth/2fa/send" -H "Authorization: Bearer $TOKEN"                  # PASS si: HTTP 200
# Verificar manualmente que llegó al inbox configurado en EMAIL_FROM

# 8. Métricas Prometheus disponibles
curl -fs http://localhost:8088/actuator/prometheus | grep -q "codemon_"                     # PASS si: hay métricas custom

# 9. Grafana dashboard accesible
curl -fs http://localhost:3000/api/health | grep -q '"database":"ok"'                        # PASS si: Grafana up

# 10. Frontend Shop UI compila
cd ~/codemon/front && ng build --configuration development                                  # PASS si: BUILD SUCCESS
```

---

## Definition of Done — GATE 5

- [ ] Los 10 checks automatizados pasan
- [ ] Una compra simulada de sobre acredita coins y permite abrir el sobre
- [ ] Webhook MP es idempotente (mismo `external_payment_id` no acredita dos veces)
- [ ] Shop frontend muestra wallet, sobres y resultado de apertura
- [ ] 2FA por email funciona (enviado y verificado)
- [ ] Grafana muestra al menos las métricas: `http_server_requests`, `codemon_games_active`, `codemon_users_online`

---

## Si falla un check

| Check | Acción |
|---|---|
| Webhook duplica acreditación | revisar idempotencia con `payment_webhooks_log` (PASO_S08_04) |
| Sobre no da 5 cartas | revisar lógica de selección por rareza en `BoosterPackService` |
| Leaderboard sin datos | revisar vista materializada y refresh periódico |
| 2FA no llega | revisar `EMAIL_PASSWORD` (debe ser app password de Gmail, no la principal) |
| Métricas custom faltantes | revisar `MeterRegistry` en PASO_S08_05 |
