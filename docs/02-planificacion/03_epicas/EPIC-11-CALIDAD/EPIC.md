# EPIC-11 — Calidad y Testing

> **Epica tecnica transversal.** No contiene Historias de Usuario; sus tareas se ejecutan en cada sprint y se consolidan al final.

## 1. Resumen

- **Valor habilitador:** garantiza que cada incremento sea entregable y mantenible. Los tests, la cobertura, el code review, el responsive y el E2E forman parte del Definition of Done de cada HU.
- **Roles involucrados:** todos los equipos.
- **Sprints donde se completa:** transversal (S1-S11) con consolidacion en S11.
- **Equipos:** A (cobertura motor), B (E2E + responsive), C (cobertura aux), todos en code review.

## 2. Tareas Tecnicas

| ID | Tarea | Origen | Equipo | SP | Sprint |
|---|---|---|---|---|---|
| TT-11-01 | Configurar JaCoCo para cobertura ≥ 80% global y ≥ 90% en motor | PASO_2_x | A | 2 | S3 |
| TT-11-02 | Configurar Testcontainers para tests integracion (PG + Redis + MinIO) | varios | A | 3 | S1 |
| TT-11-03 | Tests unitarios JUnit 5 + Mockito para todos los services | varios | A/C | 13 | transversal |
| TT-11-04 | Suite Playwright E2E: auth, mazos, partida PvE, partida PvP | PASO_S11_06 | B | 13 | S11 |
| TT-11-05 | Lighthouse score >= 80 Performance / >= 90 Accessibility | PASO_S11_07 | B | 3 | S11 |
| TT-11-06 | Code style: Checkstyle (Java) + ESLint/Prettier (TS) en CI | varios | A/B | 2 | S0 |
| TT-11-07 | GitHub Actions: workflow tests + workflow build/Docker | varios | C | 5 | S0 |
| TT-11-08 | Branch protection en `main` (requiere PR + ≥1 reviewer + tests verde) | varios | C | 1 | S0 |
| TT-11-09 | Test de carga WebSocket: 50 partidas concurrentes | PASO_S11_06 | A | 5 | S11 |
| TT-11-10 | Documentacion Swagger completa con ejemplos por endpoint | varios | A/C | 3 | transversal |

## 3. Cobertura objetivo por componente

| Componente | Minimo | Justificacion |
|---|---|---|
| Global | 80% | DoD obligatorio |
| `DeckValidationService` | 90% | Reglas TCG criticas |
| `DamageCalculator` | 90% | Logica matematica del juego |
| `StatusEffectManager` | 90% | Status complejos con interacciones |
| `AttackPipeline` | 90% | 9 handlers con orden estricto |
| `VictoryConditionChecker` | 90% | Determina ganador |
| `RuleValidator` | 90% | Validaciones de turno |
| `AuthService` | 85% | Seguridad |
| `PaymentService` | 85% | Idempotencia y dinero |
| `JwtTokenProvider` | 85% | Seguridad |
| Bots (`BotEasy`, `BotMedium`, `BotHard`) | 75% | Comportamiento aleatorio dificulta determinismo total |
| `BotChatService`, `NewsService`, `FriendsService` | 80% | Logica de negocio |

## 4. Tipos de tests requeridos

- **Unit (JUnit 5 + Mockito):** estructura Given → When → Then; mocks para Redis, MinIO, MP SDK.
- **Integration (Testcontainers):** flujos end-to-end backend con BD + Redis + MinIO reales.
- **E2E (Playwright):** auth → registro → login → ver mazos → entrar partida PvE → ganar.
- **Load (Gatling o k6):** 50 partidas WebSocket concurrentes sin degradacion > 30%.

## 5. Definition of Done especifico

- Cobertura JaCoCo ≥ 80% global; archivos criticos ≥ 90% (ver tabla).
- 0 warnings Checkstyle / ESLint en CI.
- Suite Playwright pasa en headless (Chrome + Firefox) en CI.
- Lighthouse mobile >= 80 Performance / >= 90 Accessibility.
- Test de carga ejecutado y reportado.
- Hereda [DOD.md](../../04_proceso/DOD.md) global.
