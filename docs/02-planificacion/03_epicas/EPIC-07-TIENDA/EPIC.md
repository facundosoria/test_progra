# EPIC-07 — Tienda y Monetizacion

## 1. Resumen

- **Valor de negocio:** los jugadores pueden comprar Codemon Coins con Mercado Pago y usarlas para abrir sobres con cartas, alimentando la coleccion (EPIC-02). Es la fuente de monetizacion del producto.
- **Roles involucrados:** Jugador autenticado, Mercado Pago (webhook), Sistema.
- **Sprints donde se completa:** S8.
- **Equipos:** C (backend pagos + sobres + wallet), B (UI shop + opener animado).

## 2. Historias de Usuario

### HU-07-01 — Ver mi balance de coins
**Como** jugador, **quiero** ver cuantos Codemon Coins tengo, **para** decidir si comprar mas o gastarlos.

**Story Points:** 2

**Criterios de Aceptacion:**
- AC1: `GET /users/me/wallet` devuelve `{balance, currency: "CODEMON_COINS"}`.
- AC2: La UI muestra el balance en el shell superior (siempre visible logueado).
- AC3: Se actualiza tras compra exitosa o apertura de sobre.

**Sprint:** S8.

---

### HU-07-02 — Comprar coins con Mercado Pago
**Como** jugador, **quiero** comprar coins con tarjeta via Mercado Pago, **para** poder comprar sobres.

**Story Points:** 8

**Criterios de Aceptacion:**
- AC1: `POST /payments/create-preference` con `packId` retorna URL de checkout MP (sandbox dev / produccion prod).
- AC2: Tras pago exitoso, MP envia webhook a `POST /webhooks/mercado-pago` (publico, sin JWT).
- AC3: El backend verifica idempotencia: `mp_event_id` ya procesado → ignora sin acreditar de nuevo.
- AC4: Pago aprobado → `walletService.creditCoins()` suma coins; estado `payment_records` = COMPLETED.
- AC5: La UI redirige a `/shop/success` con confirmacion.
- AC6: Pago rechazado o pendiente → estado registrado, sin coins acreditados.

**RNF:**
- RNF-Seguridad: webhook publico pero validado con firma MP (si MP la provee).
- RNF-Idempotencia: replay del mismo webhook no duplica coins (test).
- RNF-Auditoria: cada cambio de wallet queda registrado en `payment_records` con `mp_event_id` Y en `wallet_transactions` con `reason=PURCHASE`, `delta=+amountCoins`, `ref_table='payment_records'`, `ref_id=paymentId`, `balance_after` snapshot del balance posterior.

**Sprint:** S8.

---

### HU-07-03 — Comprar un sobre (booster pack)
**Como** jugador con coins, **quiero** comprar un sobre, **para** abrirlo y conseguir cartas.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: `GET /booster-packs` lista los sobres disponibles con precio en coins.
- AC2: `POST /users/me/booster-packs/buy/{packId}` descuenta coins y crea registro en `user_booster_packs` con `status=PENDING_OPEN`.
- AC3: Saldo insuficiente → 422 `INSUFFICIENT_FUNDS`.
- AC4: La transaccion atomica (mismo `@Transactional`) inserta fila en `wallet_transactions` con `reason=PACK_PURCHASE`, `delta=-pack.priceCoins`, `ref_table='booster_packs'`, `ref_id=packId`, `balance_after` snapshot del balance posterior. Sin esta fila, la deduccion debe rollbackear.

**RNF:**
- RNF-Concurrencia: `WalletService.deductCoins()` `@Transactional` con verificacion atomica.
- RNF-Auditoria: invariante `SUM(wallet_transactions.delta) WHERE user_id=X == users.virtual_currency_balance` validable por test de integracion.

**Sprint:** S8.

---

### HU-07-04 — Abrir un sobre con animacion
**Como** jugador, **quiero** abrir un sobre con una animacion de revelacion, **para** que sea emocionante.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: `POST /users/me/booster-packs/{id}/open` retorna exactamente 10 cartas con su rareza.
- AC2: Distribucion: 5 comunes, 3 poco comunes, 1 rara, 1 holografica.
- AC3: Las cartas se agregan a `user_collection` (incrementando `quantity` si ya existian).
- AC4: La UI muestra animacion de apertura carta por carta (revelar individual).
- AC5: Se aplica cooldown de 24 h.

**RNF:**
- RNF-Performance: vista materializada `user_collection_stats` se refresca async.
- RNF-Justicia: la generacion usa `SecureRandom`.

**Sprint:** S8.

---

### HU-07-05 — Esperar cooldown de 24 h tras abrir sobre
**Como** sistema, **queremos** limitar 1 sobre cada 24 h, **para** mantener un ritmo de progreso saludable.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: Cooldown en Redis: `booster:cooldown:{userId}` con TTL 86400 s.
- AC2: `GET /users/me/booster-packs/cooldown` devuelve `secondsRemaining`.
- AC3: Intentar abrir un sobre durante cooldown → 429 `BOOSTER_COOLDOWN` con `retryAfter`.
- AC4: La UI muestra contador "Proximo sobre disponible en HH:MM:SS".

**Sprint:** S8.

---

### HU-07-06 — Ver historial de pagos
**Como** jugador, **quiero** ver mis ultimas transacciones, **para** auditar mis gastos.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: `GET /users/me/payments?page=0&size=10` devuelve mis pagos ordenados por fecha desc.
- AC2: Campos: `paymentId`, `amount`, `currency`, `status`, `createdAt`, `mpEventId`.
- AC3: Solo el dueno ve sus pagos.

**Sprint:** S10 (junto al perfil consolidado).

## 3. Tareas Tecnicas

| ID | Tarea | Origen | Equipo | SP | Sprint |
|---|---|---|---|---|---|
| TT-07-01 | Mercado Pago SDK + `PaymentService.createPreference()` | PASO_S08_04 | C | 5 | S8 |
| TT-07-02 | Webhook `/webhooks/mercado-pago` con tabla `payment_webhooks_log` (idempotencia) | PASO_S08_04 | C | 5 | S8 |
| TT-07-03 | `WalletService.creditCoins`/`deductCoins` `@Transactional` que actualiza `users.virtual_currency_balance` Y registra fila en `wallet_transactions` (reason, delta, ref, balance_after) en la misma transaccion | PASO_S08_04 | C | 5 | S8 |
| TT-07-10 | Migracion Flyway con tabla `wallet_transactions` (reasons: PURCHASE, PACK_PURCHASE, MATCH_REWARD, DAILY_REWARD, PROMO, REFUND, ADMIN_ADJUST) + indices `(user_id, created_at DESC)`, `(reason)`, `(ref_table, ref_id)` | SCHEMA_BD.sql V6.5 | A | 2 | S8 |
| TT-07-04 | `BoosterPackService.openPack()` con `SecureRandom` y distribucion por rareza | PASO_S08_01 | C | 5 | S8 |
| TT-07-05 | Redis cooldown 24h con TTL | PASO_S08_01 | C | 2 | S8 |
| TT-07-06 | Seed: 1 booster pack tipo XY1 si no existe | PASO_S08_01 | C | 1 | S8 |
| TT-07-07 | UI `/shop` con listado de sobres + boton comprar | PASO_S08_06 | B | 5 | S8 |
| TT-07-08 | UI `BoosterPackOpener` con animacion de revelacion | PASO_S08_06 | B | 5 | S8 |
| TT-07-09 | UI `WalletDisplay` en shell + historial de pagos | PASO_S11_04 | B | 3 | S8/S10 |

## 4. Contratos involucrados

- REST: `GET /booster-packs`, `POST /users/me/booster-packs/buy/{id}`, `POST /users/me/booster-packs/{id}/open`, `GET /users/me/booster-packs/cooldown`, `POST /payments/create-preference`, `POST /webhooks/mercado-pago` (publico), `GET /users/me/wallet`, `GET /users/me/payments`.
- STOMP: `/user/queue/wallet` (`WALLET_UPDATED`).

## 5. Definition of Done especifico

- Webhook idempotente verificado: replay del mismo `mp_event_id` no duplica coins.
- Distribucion de rareza verificada con test estadistico (1000 sobres → ratio ±5%).
- Test integracion: pago aprobado → coins acreditados → sobre abierto → coleccion incrementada.
- Test integridad wallet: tras N operaciones, `SUM(wallet_transactions.delta) WHERE user_id=X == users.virtual_currency_balance` debe ser TRUE para todo usuario.
- Rate-limit `create-preference` 10 req/min/usuario.
- Cobertura `PaymentService` ≥ 85%.
- Hereda [DOD.md](../../04_proceso/DOD.md) global.
