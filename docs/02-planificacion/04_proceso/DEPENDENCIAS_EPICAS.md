# Dependencias entre Epicas

> Reemplaza al antiguo `ANALISIS_DEPENDENCIAS.md` (orientado a dependencias entre PASOs). Ahora documenta dependencias entre **epicas funcionales** y los gates de sincronizacion.

> Para la cadena tecnica detallada de los `PASO_*.md` ver [BACKLOG.md](../01_backlog/BACKLOG.md) (orden por sprint) o los `EPIC.md` individuales (referencias a PASOs).

---

## Mapa de dependencias entre Epicas

```
EPIC-10 (Infra)           ← S0, prerequisito de TODO
    ↓
EPIC-01 (Auth)            ← S1, requiere infra
    ↓
EPIC-02 (Cards)  &  EPIC-03 (Mazos)   ← S2, requieren auth para "mis mazos"
    ↓                ↓
        EPIC-04 (Motor)             ← S3-S5, requiere mazos validos
            ↓
   EPIC-06 (Tablero)   &   EPIC-08 (Bot EASY)   ← S5-S6, requieren motor + WS
            ↓                       ↓
        EPIC-05 (Multijugador)     ← S7, requiere tablero + motor + WS
            ↓
        EPIC-07 (Tienda)           ← S8, paralelo con motor 2FA
            ↓
        EPIC-09 (Social)           ← S9-S10, requiere motor (ligas) + auth (perfil)
            ↓
        EPIC-08 (Bot avanzado)     ← S11, mejora opcional post base
            ↓
        EPIC-11 (Calidad)          ← transversal, consolida en S11
```

---

## Dependencias detalladas

### EPIC-10 — Infraestructura
- **Depende de:** nada (es la base).
- **Bloquea:** TODO.

### EPIC-01 — Autenticacion
- **Depende de:** EPIC-10 (BD migrada con tablas `users`, `email_verifications`, `refresh_tokens`).
- **Bloquea:** acceso a cualquier endpoint protegido.
- **Sub-dependencias internas:**
  - HU-01-02 (verificar email) requiere TT-01-01 (SMTP configurado).
  - HU-01-06 (2FA) requiere HU-01-02 ya implementada.
  - HU-01-07 (OAuth2) requiere HU-01-03 (login normal) y secrets de Google/GitHub.

### EPIC-02 — Catalogo y Coleccion
- **Depende de:** EPIC-10 (MinIO + tabla `cards_catalog`), EPIC-01 (auth para `me/collection`).
- **Bloquea:** EPIC-03 (sin cartas en BD no se arman mazos), EPIC-07 (sin coleccion no tiene sentido abrir sobres).
- **Notas:**
  - HU-02-01..03 solo requieren catalogo; NO dependen de la coleccion personal.
  - HU-02-04..05 (coleccion personal) dependen de EPIC-07 (sobres) para tener cartas.

### EPIC-03 — Constructor de Mazos
- **Depende de:** EPIC-01 (auth), EPIC-02 (catalogo).
- **Bloquea:** EPIC-04 (motor necesita mazos validos).
- **Notas:**
  - TT-03-01 (`DeckValidationService`) es **independiente** de BD: puede empezarse antes de que EPIC-02 termine. Solo los **tests integrales** de EPIC-03 requieren cartas reales.

### EPIC-04 — Motor de Juego
- **Depende de:** EPIC-03 (mazos validos), EPIC-10 (BD para snapshots).
- **Bloquea:** EPIC-05, EPIC-06, EPIC-08, EPIC-09 (ligas).
- **Cadena interna obligatoria:**
  ```
  TT-04-00 → TT-04-01 → TT-04-02 → TT-04-03 → TT-04-04 → TT-04-05 → TT-04-06 → TT-04-07 → TT-04-08
  ```
  - TT-04-05 (DamageCalculator) es **independiente**, puede testarse solo.
  - TT-04-06 (AttackPipeline) requiere los 2 devs A trabajando juntos: NO dividir.
  - **GATE 2 critico:** TT-04-08 (GameEngine + WS) desbloquea EPIC-06 (tablero real) y EPIC-05 (matchmaking).

### EPIC-05 — Multijugador
- **Depende de:** EPIC-04 (motor + WS), EPIC-10 (Redis), EPIC-01 (usuarios autenticados).
- **Bloquea:** ranking real (EPIC-09 puntos solo se dan en QUEUE).

### EPIC-06 — Tablero y UX
- **Depende de:** EPIC-04 (motor + WS), EPIC-03 (mazos para entrar a partida).
- **Bloquea:** experiencia jugable end-to-end.
- **Notas:**
  - HU-06-01 (zonas) puede empezarse con mocks antes de GATE 2.
  - HU-06-02..05 requieren motor entregado.
  - HU-06-06 (responsive) es transversal y se aborda en S11.

### EPIC-07 — Tienda y Monetizacion
- **Depende de:** EPIC-01 (auth + 2FA), EPIC-10 (Redis cooldown), EPIC-02 (cartas para los sobres).
- **Bloquea:** crecimiento de coleccion (HU-02-04..05 cobran sentido cuando hay sobres).

### EPIC-08 — Bot e IA
- **Depende de:** EPIC-04 (motor entregado).
- **Notas:**
  - Bot EASY (HU-08-01) entra en S5 como parte del entregable de motor.
  - Bots MEDIUM/HARD (HU-08-02..03) entran en S11 (post base).
  - Chat-bot (HU-08-05) requiere tabla `game_chat_messages` y motor con eventos `ATTACK`/`KO`/`GAME_OVER`.

### EPIC-09 — Social y Comunidad
- **Depende de:** EPIC-04 (ligas requieren `VictoryConditionChecker.declareWinner`), EPIC-01 (perfil), EPIC-05 (ranked games para leaderboard).
- **Sub-dependencias internas:**
  - HU-09-07 (ligas) depende de HU-04-09 (declareWinner integrado).
  - HU-09-04 (presencia) depende de TT-09-03 (Redis presence).
  - HU-09-01 (perfil consolidado) depende de HU-09-05..07 (stats), HU-02-05 (collection stats), HU-07-06 (historial pagos).

### EPIC-11 — Calidad y Testing
- **Transversal:** se aplica desde S0 (CI/CD) y se consolida en S11.

---

## Gates de sincronizacion

| Gate | Sprint | Que valida | Quien participa |
|---|---|---|---|
| **GATE 0** | S0 | Infra completa, contratos firmados, smoke test | TODOS |
| **GATE 1a** | S1 | Auth end-to-end (login funciona desde frontend) | A → B |
| **GATE 1b** | S2 | Mazos end-to-end (crear mazo valido desde UI) | A → B |
| **GATE 2** | S5 | Motor + WS completos (partida PvE jugable end-to-end) | A → B, C |
| **GATE 3** | S7 | Salas privadas (2 humanos jugando con codigo) | C → B |
| **GATE 4** | S7 | Matchmaking ranked | C → B |
| **GATE 5** | S8 | Mercado Pago sandbox + sobres + wallet/tienda (compra acreditada) | C → B |
| **GATE 6** | S9 | Leaderboard + ligas + amigos + noticias | C → B |
| **GATE 7** | S10 | OAuth2 + perfil consolidado | C → B |
| **GATE 8** | S11 | Test de carga + Playwright + Lighthouse OK | TODOS |

---

## Estrategia para evitar bloqueos

1. **Mock-first:** B comienza UI con mocks definidos en MOCKS_FRONTEND.md mientras A construye el endpoint real. Cambia a real cuando pasa el gate.
2. **Contratos antes de codigo:** ningun endpoint se implementa sin estar firmado en CONTRATOS_API.md.
3. **Refinamiento de backlog miercoles:** asegura que el sprint siguiente tiene HU listas (DoR) sin bloqueos imprevistos.
4. **Daily de gate inminente:** la semana en la que vence un gate, los equipos involucrados sincronizan diariamente.

---

## Mantenimiento

Si se agrega una nueva HU o TT con dependencias hacia otra epica, actualizar:
- El `EPIC.md` correspondiente (campo `Dependencias`).
- Este archivo (mapa visual y dependencias detalladas).
- El [SPRINTS.md](../02_sprints/SPRINTS.md) si afecta orden de sprint.
