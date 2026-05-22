# Tabla comparativa: Pasos ↔ Sprints

Referencia de la reorganización de los archivos `PASO_*.md` al esquema sprint-based (`PASO_Sxx_nn`).

**Leyenda:**
- 🔄 Reordenado — cambió de posición en la secuencia respecto al bloque original
- ✂️ Nota de alcance multi-sprint agregada
- ✅ Renombrado en la misma posición relativa (solo cambio de nombre)

---

## Sprint 0 — Infraestructura y contratos

| Paso nuevo | Paso viejo | Cambio |
|---|---|---|
| `PASO_S00_01` | `PASO_0_0` | ✅ |
| `PASO_S00_02` | `PASO_0_1` | ✅ |
| `PASO_S00_03` | `PASO_0_2` | ✅ |
| `PASO_S00_04` | `PASO_0_3` | ✅ |
| `PASO_S00_05` | `PASO_0_4` | ✅ |
| `PASO_S00_06` | `PASO_0_5` | ✅ |
| `PASO_S00_07` | `PASO_0_6` | ✅ |
| `PASO_S00_SMOKE` | `PASO_0_SMOKE` | ✅ |

---

## Sprint 1 — Autenticación básica

| Paso nuevo | Paso viejo | Cambio |
|---|---|---|
| `PASO_S01_01` | `PASO_1_2` | 🔄 Era el paso **1.2** (después de Deck Validation), ahora es el primero del sprint |
| `PASO_S01_02` | `PASO_1B_1` | ✅ |
| `PASO_S01_03` | `PASO_1B_2` | ✅ |

---

## Sprint 2 — Catálogo y Mazos

| Paso nuevo | Paso viejo | Cambio |
|---|---|---|
| `PASO_S02_01` | `PASO_1_1` | 🔄 Era el paso **1.1** (primero del bloque), ahora arranca en Sprint 2 |
| `PASO_S02_02` | `PASO_1_3` | ✅ |
| `PASO_S02_03` | `PASO_1_4` | ✅ |
| `PASO_S02_04` | `PASO_1B_3` | ✅ |
| `PASO_S02_05` | `PASO_1B_4` | 🔄 Se corrigió bug en `dep:` — dependía de `SetupState` (S3), ahora depende correctamente de `PASO_S02_02` (Cards) |
| `PASO_S02_SMOKE` | `PASO_1_SMOKE` | ✅ |

---

## Sprint 3 — Motor: setup + turnos

| Paso nuevo | Paso viejo | Cambio |
|---|---|---|
| `PASO_S03_01` | `PASO_2_0` | ✅ |
| `PASO_S03_02` | `PASO_2_1` | ✅ |
| `PASO_S03_03` | `PASO_2_2` | ✅ |
| `PASO_S03_04` | `PASO_2_3` | ✅ |
| `PASO_S03_05` | `PASO_2_4` | ✅ |

---

## Sprint 4 — Motor: combate completo

| Paso nuevo | Paso viejo | Cambio |
|---|---|---|
| `PASO_S04_01` | `PASO_2_5` | ✅ |
| `PASO_S04_02` | `PASO_2_6` | ✅ |
| `PASO_S04_03` | `PASO_2_HANDLERS` | 🔄 Los deps originales sugerían colocarlo después de S5; se adelantó a S4 donde corresponde lógicamente |

---

## Sprint 5 — Primera partida PvE jugable

| Paso nuevo | Paso viejo | Cambio |
|---|---|---|
| `PASO_S05_01` | `PASO_2_7` | ✅ |
| `PASO_S05_02` | `PASO_2_8` | ✅ |
| `PASO_S05_03` | `PASO_2_9` | ✅ |
| `PASO_S05_04` ✂️ | `PASO_3_3` | 🔄 Era bloque 3 (sugería Sprint 7+). Adelantado a S5. Ahora tiene **nota de alcance**: S5 = tablero básico + WebSocket; S6 = drag&drop + animaciones + chat |
| `PASO_S05_SMOKE` | `PASO_2_SMOKE` | ✅ |

---

## Sprint 6 — Tablero pulido + Lobby

| Paso nuevo | Paso viejo | Cambio |
|---|---|---|
| `PASO_S06_01` ✂️ | `PASO_3B_1` | 🔄 Era bloque 3B (sin sprint claro). Asignado a S6 con **nota de alcance**: S6 = UI con mocks; S7 = integrar API real de matchmaking |

---

## Sprint 7 — PvP en tiempo real

| Paso nuevo | Paso viejo | Cambio |
|---|---|---|
| `PASO_S07_01` | `PASO_3_1` | ✅ |
| `PASO_S07_02` | `PASO_3_2` | ✅ |
| `PASO_S07_SMOKE` | `PASO_3_SMOKE` | ✅ |

---

## Sprint 8 — Tienda + 2FA + métricas

| Paso nuevo | Paso viejo | Cambio |
|---|---|---|
| `PASO_S08_01` | `PASO_4_1` | ✅ |
| `PASO_S08_02` | `PASO_4_2` | ✅ |
| `PASO_S08_03` | `PASO_4_3` | ✅ |
| `PASO_S08_04` | `PASO_4_4` | ✅ |
| `PASO_S08_05` | `PASO_4_5` | ✅ |
| `PASO_S08_06` | `PASO_4B_1` | ✅ |
| `PASO_S08_SMOKE` | `PASO_4_SMOKE` | ✅ |

---

## Sprint 9 — Social v1

| Paso nuevo | Paso viejo | Cambio |
|---|---|---|
| `PASO_S09_01` | `PASO_5_1` | ✅ |
| `PASO_S09_02` | `PASO_5_2` | ✅ |
| `PASO_S09_03` | `PASO_5_3` | ✅ |
| `PASO_S09_04` | `PASO_4B_2` | 🔄 Era bloque **4B** (agrupado con tienda de S8). Movido a S9 donde realmente se ejecuta |
| `PASO_S09_05` ✂️ | `PASO_5B_1` | 🔄 Tenía dep cruzada S9+S10. Ahora tiene **nota de alcance**: S9 = FriendsComponent; S10 = ProfileComponent |

---

## Sprint 10 — OAuth2 + Perfil

| Paso nuevo | Paso viejo | Cambio |
|---|---|---|
| `PASO_S10_01` | `PASO_5_4` | ✅ |
| `PASO_S10_02` | `PASO_5B_2` | ✅ |
| `PASO_S10_SMOKE` | `PASO_5_SMOKE` | ✅ |

---

## Sprint 11 — Pulido + bots + E2E

| Paso nuevo | Paso viejo | Cambio |
|---|---|---|
| `PASO_S11_01` | `PASO_6_1` | ✅ |
| `PASO_S11_02` | `PASO_6_2` | ✅ |
| `PASO_S11_03` | `PASO_6_3` | ✅ |
| `PASO_S11_04` | `PASO_6_4` | ✅ |
| `PASO_S11_05` | `PASO_6_5` | ✅ |
| `PASO_S11_06` | `PASO_5B_3` | 🔄 Era bloque 5B. Movido a S11 donde se ejecuta |
| `PASO_S11_07` | `PASO_5B_4` | 🔄 Era bloque 5B. Movido a S11 donde se ejecuta |

---

## Resumen de cambios

| Tipo | Cantidad | Archivos afectados |
|---|---|---|
| 🔄 Reordenados | **9** | S01_01, S02_01, S02_05 (bug dep), S04_03, S05_04, S06_01, S09_04, S11_06, S11_07 |
| ✂️ Nota de alcance multi-sprint agregada | **3** | S05_04, S06_01, S09_05 |
| ✅ Solo renombrados | **45** | todos los demás |
| 📄 Archivos externos actualizados | **30** | BACKLOG, SPRINTS, EPICs, GUÍAs, COMO\_USAR, etc. |
