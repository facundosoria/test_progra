# Plan de Sprints — Codemon TCG

> 12 sprints de 1 semana, cada uno con un Sprint Goal claro y un entregable demoable. Cada sprint se cierra con Sprint Review (demo) y Retrospectiva.

---

## Marco

- **Duracion sprint:** 1 semana (lunes a viernes; demo + retro el viernes).
- **Equipos en paralelo:** A (backend nucleo), B (frontend), C (auxiliar + DevOps).
- **Capacidad combinada estimada:** ~120 SP/sprint (variable por composicion del equipo).
- **Definicion de listo (DoR):** cada HU debe tener AC + RNF + estimacion antes del Sprint Planning.
- **Definicion de hecho (DoD):** ver [DOD.md](../04_proceso/DOD.md).

---

## Sprint 0 — Kickoff: Infraestructura y Contratos

- **Sprint Goal:** la infraestructura del proyecto corre y los contratos API/WS estan acordados entre los 3 equipos.
- **Entregable demoable:** `docker --context colima compose up -d --build` levanta todos los servicios; `curl localhost:8088/actuator/health` devuelve UP; `http://localhost:8088` carga Angular; CONTRATOS_API.md y PROTOCOLO_WEBSOCKET.md aprobados.
- **Epicas tocadas:** EPIC-10, EPIC-11 (CI/CD setup).
- **HU/TT incluidas:**
  - TT-10-01..15 (toda la epica de infra)
  - TT-11-06 (Checkstyle + ESLint), TT-11-07 (GH Actions), TT-11-08 (branch protection)
  - TT-01-02 (migraciones de auth/refresh tokens en V2-V3)
- **Capacity:** ~50 SP (sprint corto, tiempo dedicado a setup).
- **Riesgos:** falta de credenciales MP sandbox, problemas con MinIO o Docker en macs M1/M2.

---

## Sprint 1 — Autenticacion basica

- **Sprint Goal:** un usuario puede registrarse, loguearse y mantener sesion.
- **Entregable demoable:** registro → login → home protegido. Tokens persistidos. Logout funcional. Sesion renovada automaticamente.
- **Epicas tocadas:** EPIC-01 (parcial).
- **HU incluidas:** HU-01-01, HU-01-03, HU-01-04, HU-01-05.
- **TT incluidas:** TT-01-03, TT-01-04, TT-01-05.
- **Out of scope (sprint):** 2FA y OAuth2 (van en S8 y S10).
- **Capacity:** ~80 SP.

---

## Sprint 2 — Catalogo y Mazos

- **Sprint Goal:** un usuario logueado ve las 146 cartas y arma un mazo valido.
- **Entregable demoable:** grid del catalogo con filtros + Deck Builder con drag & drop + validacion de 60 cartas en tiempo real + guardado en BD.
- **Epicas tocadas:** EPIC-02 (parcial), EPIC-03 (completa).
- **HU incluidas:** HU-02-01, HU-02-02, HU-02-03, HU-03-01, HU-03-02, HU-03-03, HU-03-04, HU-03-05, HU-03-06.
- **TT incluidas:** TT-02-01..04, TT-03-01..04.
- **Capacity:** ~110 SP.
- **GATE 1b:** API de cartas y mazos funcionando end-to-end con frontend real.

---

## Sprint 3 — Motor: setup + turnos sin combate

- **Sprint Goal:** una partida arranca con setup TCG correcto y los turnos avanzan hasta antes del combate.
- **Entregable demoable:** API permite crear partida PvE; setup con mulligan + premios; jugar Basico, adjuntar energia, evolucionar via API; transiciones de estado verificadas con tests.
- **Epicas tocadas:** EPIC-04 (parcial).
- **HU incluidas:** HU-04-01, HU-04-02, HU-04-03, HU-04-04, HU-04-05.
- **TT incluidas:** TT-04-00, TT-04-01, TT-04-02, TT-04-03, TT-04-04, TT-11-01 (JaCoCo), TT-11-02 (Testcontainers).
- **Capacity:** ~110 SP. ALTO RIESGO: motor es complejo.
- **No demoable en UI todavia:** se demuestra con JSONs / Swagger / tests.

---

## Sprint 4 — Motor: combate completo

- **Sprint Goal:** los ataques resuelven correctamente con todas las reglas TCG (weakness, resistance, status, KO, premios).
- **Entregable demoable:** test integracion completo: setup → varios turnos → ataque con KO → premios tomados, sin pasar a EndPhase aun.
- **Epicas tocadas:** EPIC-04 (parcial).
- **HU incluidas:** HU-04-06, HU-04-07, HU-04-08.
- **TT incluidas:** TT-04-05, TT-04-06.
- **Capacity:** ~80 SP (TT-04-06 es 21 SP por si solo, los 2 devs A trabajan juntos).
- **GATE clave:** cobertura ≥ 90% en `DamageCalculator`, `StatusEffectManager`, `AttackPipeline`.

---

## Sprint 5 — Primera partida PvE jugable end-to-end

- **Sprint Goal:** un usuario juega una partida PvE completa contra Bot EASY desde la UI web.
- **Entregable demoable:** desde el lobby → crear partida PvE → ver tablero web minimo → jugar turnos drag & drop → derrotar al bot → game over.
- **Epicas tocadas:** EPIC-04 (cierra), EPIC-06 (parcial), EPIC-08 (Bot EASY).
- **HU incluidas:** HU-04-09, HU-08-01, HU-06-01 (basico).
- **TT incluidas:** TT-04-07, TT-04-08, TT-08-01, TT-06-01 (basico), TT-06-03.
- **Capacity:** ~110 SP.
- **GATE 2 critico:** `PASO_S05_03` (motor + WebSocket) entregado al frontend.

---

## Sprint 6 — Tablero pulido + Lobby

- **Sprint Goal:** el tablero se siente fluido, con drag & drop completo, animaciones, lobby con 3 modos y chat.
- **Entregable demoable:** PvE jugable con UX pulida, lobby con tabs PvE / Ranked (solo UI, sin matchmaking aun) / Sala privada.
- **Epicas tocadas:** EPIC-06 (cierra parcial, salvo responsive de S11).
- **HU incluidas:** HU-06-02, HU-06-03, HU-06-04, HU-06-05.
- **TT incluidas:** TT-06-02, TT-06-04, TT-06-05, TT-06-06.
- **Capacity:** ~95 SP.

---

## Sprint 7 — PvP en tiempo real

- **Sprint Goal:** dos humanos juegan una partida PvP via sala privada o cola ranked.
- **Entregable demoable:** crear sala privada → compartir codigo → ambos juegan; entrar a cola ranked → match → partida → ELO actualizado.
- **Epicas tocadas:** EPIC-05 (completa).
- **HU incluidas:** HU-05-01, HU-05-02, HU-05-03, HU-05-04, HU-05-05.
- **TT incluidas:** TT-05-01..06.
- **Capacity:** ~85 SP.
- **GATE 3:** salas privadas; **GATE 4:** matchmaking ranked.

---

## Sprint 8 — Tienda + 2FA + metricas

- **Sprint Goal:** un usuario verifica 2FA, compra coins via MP, abre sobres y la coleccion crece. Grafana muestra metricas.
- **Entregable demoable:** registro con verificacion email → login con 2FA → comprar coins → abrir sobre → ver coleccion crecer. Grafana muestra `codemon_users_registered_total`, `codemon_games_started_total`, `codemon_revenue_ars_total`.
- **Epicas tocadas:** EPIC-01 (cierra excepto OAuth), EPIC-07 (parcial), EPIC-02 (coleccion + stats), EPIC-10 (Grafana).
- **HU incluidas:** HU-01-02, HU-01-06, HU-07-01, HU-07-02, HU-07-03, HU-07-04, HU-07-05, HU-02-04, HU-02-05.
- **TT incluidas:** TT-01-01, TT-01-06, TT-02-05, TT-02-06, TT-07-01..09, TT-10-11..13.
- **Capacity:** ~120 SP (sprint cargado, considerar mover algo a S9 si entra justo).
- **GATE 5:** Mercado Pago sandbox + sobres + wallet/tienda funcionando end-to-end.

---

## Sprint 9 — Social v1: ligas, amigos, leaderboard, noticias

- **Sprint Goal:** los jugadores compiten via ligas y leaderboard, agregan amigos con presencia, y leen noticias del juego.
- **Entregable demoable:** ganar partida ranked → +25 puntos liga → cruzar umbral → liga actualizada. Enviar solicitud → aceptar → ver presencia ONLINE/PLAYING. Leaderboard top 50. Lista de noticias con badges.
- **Epicas tocadas:** EPIC-09 (parcial).
- **HU incluidas:** HU-09-03, HU-09-04, HU-09-05, HU-09-06, HU-09-07, HU-09-08.
- **TT incluidas:** TT-09-01..05, TT-09-08..10.
- **Capacity:** ~85 SP.
- **GATE 6:** leaderboard + ligas + amigos + noticias integrados con frontend real.

---

## Sprint 10 — OAuth2 + Perfil consolidado + Wallet

- **Sprint Goal:** los jugadores entran con Google/GitHub y tienen un perfil consolidado con todos sus datos.
- **Entregable demoable:** "Continuar con Google" → ingresar a la cuenta. Perfil con stats + coleccion + historial de pagos + wallet visible.
- **Epicas tocadas:** EPIC-01 (cierra OAuth), EPIC-09 (cierra perfil), EPIC-07 (cierra historial).
- **HU incluidas:** HU-01-07, HU-09-01, HU-09-02, HU-07-06.
- **TT incluidas:** TT-01-07, TT-01-08, TT-09-06, TT-09-07.
- **Capacity:** ~70 SP.
- **GATE 7:** OAuth2 + perfil consolidado + wallet history funcionando desde UI.

---

## Sprint 11 — Pulido + bots avanzados + E2E

- **Sprint Goal:** la app esta lista para entrega: bots avanzados, responsive mobile, suite Playwright pasa, test de carga ok.
- **Entregable demoable:** Bot HARD desafiante con personalidad + chat. App fluida en mobile. Suite E2E completa pasa. Reporte de carga 50 partidas concurrentes.
- **Epicas tocadas:** EPIC-08 (cierra), EPIC-06 (cierra responsive), EPIC-11 (cierra).
- **HU incluidas:** HU-08-02, HU-08-03, HU-08-04, HU-08-05, HU-06-06.
- **TT incluidas:** TT-08-02..06, TT-06-07, TT-11-04, TT-11-05, TT-11-09, TT-11-10.
- **Capacity:** ~95 SP.
- **GATE 8:** carga + Playwright + Lighthouse + checklist final de entrega.
- **Demo final + entrega.**

---

## Resumen de capacity

| Sprint | SP planeados | Riesgo |
|---|---|---|
| S0 | 50 | bajo |
| S1 | 80 | bajo |
| S2 | 110 | medio |
| S3 | 110 | **alto** (motor) |
| S4 | 80 | **alto** (AttackPipeline) |
| S5 | 110 | medio |
| S6 | 95 | medio |
| S7 | 85 | medio |
| S8 | 120 | **alto** (sprint cargado) |
| S9 | 85 | bajo |
| S10 | 70 | bajo |
| S11 | 95 | medio |
| **Total** | **~1090 SP** | — |

---

## Eventos Scrum

| Evento | Cuando | Duracion |
|---|---|---|
| Sprint Planning | Lunes 9:00 | 1 h |
| Daily Stand-up | Cada dia 9:30 | 15 min |
| Sprint Review (demo) | Viernes 14:00 | 45 min |
| Sprint Retrospective | Viernes 15:00 | 45 min |
| Refinamiento backlog | Miercoles 14:00 | 1 h |

---

## Mantenimiento

- Al cerrar cada sprint, actualizar el campo `Estado` en [PRODUCT_BACKLOG.md](../01_backlog/PRODUCT_BACKLOG.md) y `Sprint` en [epicas_y_user_stories.csv](../01_backlog/epicas_y_user_stories.csv).
- HU no completadas en su sprint vuelven al backlog y se replanifican en el siguiente Sprint Planning.
- Si se agregan HU intra-sprint (interrupcion), documentar en la retrospectiva el impacto.
