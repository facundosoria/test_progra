---
id: PASO_S08_04
equipo: C
bloque: 8
dep: [PASO_S01_01, PASO_S08_01]
siguiente: PASO_S08_05
context_files:
  - BD_Y_TABLAS.md
  - CODEMON_GUIAS_TECNICAS.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/payment/entity/PaymentRecord.java
  - api/src/main/java/com/codemon/payment/entity/WebhookLog.java
  - api/src/main/java/com/codemon/payment/repository/PaymentRecordRepository.java
  - api/src/main/java/com/codemon/payment/repository/WebhookLogRepository.java
  - api/src/main/java/com/codemon/payment/service/PaymentService.java
  - api/src/main/java/com/codemon/payment/service/WalletService.java
  - api/src/main/java/com/codemon/payment/controller/PaymentController.java
  - api/src/main/java/com/codemon/payment/controller/WebhookController.java
  - api/src/main/java/com/codemon/payment/config/MercadoPagoConfig.java
  - api/src/test/java/com/codemon/payment/PaymentServiceTest.java
---

# PASO 4.4 — Mercado Pago
**Grupo legacy:** 4 — Features Adicionales | **Equipo:** C | **Dificultad:** 🟡 | **Tiempo:** 4–5 h

## Navegación
← **Anterior:** [PASO_S08_02](PASO_S08_02.md) y [PASO_S08_03](PASO_S08_03.md) — Leaderboard y 2FA completados
→ **Siguiente:** [PASO_S08_05](PASO_S08_05.md) — Grafana + métricas custom

## Archivos a cargar junto a este
- `SCHEMA_BD.sql` → bloque V6 (tablas payment_records, payment_webhooks_log)
- `CODEMON_GUIAS_TECNICAS.md` → sección "Sistema de Pagos"

## Qué construye este paso
Integración con Mercado Pago para comprar coins virtuales con las que se compran sobres. Usa el SDK de sandbox, procesa webhooks con idempotencia para evitar acreditar coins dos veces.

## Flujo de pagos

```
Usuario → "Quiero comprar 3 sobres" → Backend
Backend → Crea preferencia → Mercado Pago API
Backend → Retorna URL de pago al frontend
Frontend → Redirige al usuario a la URL de MP
Usuario → Completa el pago en MP (sandbox)
MP → Envía webhook POST /webhooks/mercado-pago
Backend → Verifica idempotencia (mp_event_id en payment_webhooks_log)
Backend → Si no está procesado: acredita coins → crea sobres en inventario
```

## Prompt listo para el agente

```
Implementá la integración con Mercado Pago para Codemon TCG.
SDK: mercadopago sdk-java 2.1.27 (agregar al pom.xml)

Schema:
[pegá bloque V6 de SCHEMA_BD.sql]

Guía técnica completa:
[pegá sección "Sistema de Pagos" de CODEMON_GUIAS_TECNICAS.md]

Implementá:

1. MercadoPagoConfig.java (@Configuration):
   - Inicializar SDK con MercadoPagoConfig.setAccessToken(${codemon.mercadopago.access-token})
   - Bean de MercadoPago para inyección

2. PaymentService.java:
   createPreference(userId, boosterPackId, quantity):
   - Calcular precio: boosterPack.price * quantity
   - Crear Preference con SDK (sandbox en dev)
   - Guardar PaymentRecord en BD con status PENDING
   - Retornar init_point (URL de pago de MP)

   processWebhook(payload):
   CRÍTICO — IDEMPOTENCIA:
   - Verificar que mp_event_id NO está ya en payment_webhooks_log
   - Si ya existe → return sin procesar (MP puede enviar el mismo webhook dos veces)
   - Insertar en payment_webhooks_log ANTES de procesar
   - Si status == "approved":
     walletService.creditCoins(userId, coins calculados)
     boosterPackService.grantBoosterPacks(userId, boosterPackId, quantity)
   - Actualizar PaymentRecord con status final

3. WalletService.java:
   getBalance(userId): retorna coins del usuario
   creditCoins(userId, amount): @Transactional, sumar coins
   deductCoins(userId, amount): @Transactional, verificar saldo, restar

4. WebhookController.java (PÚBLICO — sin autenticación):
   POST /webhooks/mercado-pago → procesar webhook de MP

5. PaymentController.java:
   POST /payments/create-preference → createPreference
   GET  /users/me/wallet → saldo de coins

TESTS:
- Crear preferencia → retorna URL de sandbox que empieza con "https://sandbox..."
- Webhook approved → coins acreditados, sobres creados en inventario
- Mismo webhook dos veces → procesado solo una vez (idempotencia)
- Webhook rejected/cancelled → status FAILED, sin coins

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea
```
api/src/main/java/com/codemon/payment/
  entity/PaymentRecord.java
  entity/WebhookLog.java
  repository/PaymentRecordRepository.java
  repository/WebhookLogRepository.java
  service/PaymentService.java
  service/WalletService.java
  controller/PaymentController.java
  controller/WebhookController.java
  config/MercadoPagoConfig.java
api/src/test/java/com/codemon/payment/PaymentServiceTest.java
```

## Errores comunes

- **Webhook duplicado acredita coins dos veces**: implementar idempotencia ANTES de procesar, no después
- **Webhook con access_token equivocado**: usar `TEST-` prefix para sandbox, producción sin prefix
- **URL de callback en localhost**: en producción, la URL de success/failure debe ser la URL real del frontend
- **Webhook llega antes que el usuario confirme**: siempre verificar el estado consultando la API de MP, no solo confiar en el webhook

## Verificación

```bash
TOKEN="eyJ..."

# Crear preferencia de pago
curl -X POST http://localhost:8088/payments/create-preference \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"boosterPackId":1,"quantity":1}'
# PASS: {"paymentUrl":"https://sandbox.mercadopago.com.ar/...","preferenceId":"..."}
# FAIL: 500 o paymentUrl no empieza con "https://sandbox" → verificar MP_ACCESS_TOKEN en .env

# Ver saldo
curl http://localhost:8088/users/me/wallet \
  -H "Authorization: Bearer $TOKEN"
# PASS: {"coins":0,"transactions":[]}
# FAIL: 404 → endpoint no configurado en PaymentController

# Simular webhook de pago aprobado (en desarrollo con ngrok o Mailtrap)
curl -X POST http://localhost:8088/webhooks/mercado-pago \
  -H "Content-Type: application/json" \
  -d '{"action":"payment.created","data":{"id":"12345"}}'
# PASS: 200 OK → webhook procesado (verificar coins actualizados en wallet)
# FAIL: 401 → WebhookController debe ser público (sin autenticación)
```

## Dependencias
PASO_S01_01 (autenticación), PASO_S08_01 (BoosterPackService para crear sobres al comprar).

---

## Entrega al siguiente paso

Tras completar este PASO, los siguientes (PASO_S08_06, PASO_S11_04) pueden asumir:

- **Endpoints REST disponibles**:
  - `POST /api/payments/create-preference` (crea preferencia MP, devuelve `paymentUrl` con `initPoint`)
  - `POST /webhooks/mercado-pago` (público, sin auth, recibe notificaciones MP)
  - `GET /api/wallet` o `GET /users/me/wallet` (balance y transacciones del usuario autenticado)
- **Bean Spring autowireable**: `PaymentService`, `WalletService`, `MercadoPagoConfig`
- **Idempotencia garantizada**: misma `external_payment_id` no acredita coins dos veces (registrada en `payment_webhooks_log`)
- **Tabla `payment_records`** registra cada transacción con estado (`PENDING`, `APPROVED`, `REJECTED`)
- **Webhook seguro**: valida firma de Mercado Pago antes de procesar
- Para PASO_S08_06 (Shop UI): el frontend redirige al `paymentUrl` y al volver verifica el estado en `/api/wallet`

---

## Definition of Done

- [ ] Todos los archivos de `outputs:` existen
- [ ] `./verify_paso.sh PASO_S08_04` retorna exit 0
- [ ] Compra sandbox completa acredita coins en `wallet`
- [ ] Webhook duplicado NO acredita dos veces (verificar con curl × 2)
- [ ] Webhook con firma inválida rechaza con 400
- [ ] Tests pasan con cobertura ≥ 80% en `com.codemon.payment`
- [ ] Sin TODOs ni FIXMEs
- [ ] Naming respeta [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md)
- [ ] `MP_ACCESS_TOKEN` documentado en `.env.example` (con valor TEST-* para sandbox)
