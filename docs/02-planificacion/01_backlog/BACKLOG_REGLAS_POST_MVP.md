# Backlog — Reglas de juego opcionales (post-MVP)

Este backlog lista las **11 reglas del Pokémon TCG real** que el motor del MVP **no implementa todavía** y que pueden integrarse en iteraciones posteriores. No son bloqueantes para el lanzamiento del MVP (juego base + auth + ranking + shop) pero sí mejoran la fidelidad al TCG real.

> Las reglas críticas para el MVP (concesión, timeout, reconexión, energías especiales, habilidades pasivas vs activadas) ya están cubiertas en `docs/06-reglas-juego/07-edge-cases.md`, `03-combat.md` y `02-turn-flow.md`. **Este archivo es solo para lo OPCIONAL.**

---

## Cómo leer la tabla

- **Prioridad**: orden recomendado de implementación dentro del backlog. **Alta** = útil para una versión 1.1, **Media** = nice-to-have, **Baja** = solo si hay tiempo o demanda.
- **Dificultad**: esfuerzo estimado de implementación. **Trivial** ≈ <1 día, **Media** ≈ 1-3 días, **Compleja** ≈ semanas.
- **Toca a**: módulos del proyecto afectados.
- **PASO sugerido**: dónde encajaría un nuevo `PASO_*.md` para implementarla.

---

## Backlog priorizado

### 1. Stadium con efectos pasivos continuos
- **Prioridad**: Media
- **Dificultad**: Media
- **Estado actual**: el motor permite jugar Stadium pero no aplica modificadores continuos (ej. "all attacks do +20 damage" o "retreat costs 1 less").
- **Toca a**: `GAME_ENGINE_DETALLES.md` (T-05 extender), `AttackPipeline` (handler nuevo), `GameContext` (registrar Stadium activo con sus modificadores).
- **PASO sugerido**: extender PASO_S04_01 (DamageCalculator) para considerar el Stadium activo, o crear `PASO_S04_01b_stadium_modifiers.md`.

### 2. Mecánica completa de Pokémon Restaurados (revivir desde descarte)
- **Prioridad**: Media
- **Dificultad**: Media
- **Estado actual**: `R-RESTORED-02` y `R-RESTORED-03` los excluyen del mulligan pero no documentan cómo se "restauran" desde descarte vía cartas Trainer (ej. Fossil Excavator).
- **Toca a**: `02-turn-flow.md` (acción `RESTORE_POKEMON`), `docs/06-reglas-juego/05-deck-validation.md`, motor `MainPhaseState`.
- **PASO sugerido**: nuevo `PASO_S03_05b_restore_pokemon.md` (extiende MainPhaseState).

### 3. Switch instantáneo vía Trainer (sin costo de retirada)
- **Prioridad**: Baja
- **Dificultad**: Trivial
- **Estado actual**: solo existe `RETREAT` con costo de energías. Cartas como "Switch" o "Pokémon Catcher" del XY1 permiten cambiar Pokémon sin costo.
- **Toca a**: `02-turn-flow.md` (sección Retirada), motor `MainPhaseState`, parser de `text` de Trainers.
- **PASO sugerido**: ya cubierto por `PLAY_ITEM` / `PLAY_SUPPORTER` si se parsea el `text` correctamente. Documentar en `02-turn-flow.md` como caso borde.

### 4. Spectator mode (modo espectador)
- **Prioridad**: Baja
- **Dificultad**: Compleja
- **Estado actual**: solo los 2 jugadores reciben eventos. No hay forma de que un tercero observe partidas en curso.
- **Toca a**: `CONTRATOS_API.md` (`GET /api/games/{id}/spectate`), `PROTOCOLO_WEBSOCKET.md` (canal `/topic/spectate/{id}` con datos sanitizados), motor (lista de spectators), seguridad (ambos jugadores deben aceptar).
- **PASO sugerido**: nuevo `PASO_S11_PLUS_01_spectator.md` en post-MVP / S11+.

### 5. Replay / grabación completa de partida
- **Prioridad**: Baja
- **Dificultad**: Media
- **Estado actual**: `game_events` ya guarda todos los eventos pero no hay endpoint para reproducirlos en orden.
- **Toca a**: `CONTRATOS_API.md` (`GET /api/games/{id}/replay`), frontend (UI de replay con scrubber temporal).
- **PASO sugerido**: nuevo `PASO_S11_PLUS_02_replay.md` en post-MVP / S11+.

### 6. Visibilidad exacta del proceso de mulligan para el rival
- **Prioridad**: Baja
- **Dificultad**: Trivial
- **Estado actual**: el rival ve solo el evento `MULLIGAN` con `mulliganCount` y `extraCardsDrawn`. No ve qué cartas robó originalmente el jugador (esto es correcto por privacidad), pero podría animarse mejor en el cliente.
- **Toca a**: solo frontend (UX/animaciones).
- **PASO sugerido**: refinamiento de `PASO_S05_04` (tablero), no requiere paso nuevo.

### 7. Coin flip cuando paralizado y forzado a atacar
- **Prioridad**: Baja
- **Dificultad**: Trivial
- **Estado actual**: la regla `R-STATUS-04` dice que paralizado bloquea ataque y retirada. No existe en XY1 una carta que fuerce a atacar mientras paralizado, pero en sets posteriores podría existir.
- **Toca a**: `03-combat.md` (caso borde en sección Paralizado), motor `AttackPhaseState`.
- **PASO sugerido**: documentar como caso borde en `03-combat.md` cuando se cargue un set que lo requiera.

### 8. Timing exacto de aplicación de status (inicio o final del turno)
- **Prioridad**: Media
- **Dificultad**: Trivial
- **Estado actual**: las reglas describen que las condiciones se aplican "entre turnos" pero no detallan si es al final del turno actual o al inicio del siguiente. Para implementación es ambiguo.
- **Toca a**: `03-combat.md` (sección Paso entre turnos), `02-turn-flow.md`.
- **PASO sugerido**: aclaración textual en las reglas, no requiere PASO nuevo.

### 9. Pokémon Tools: confirmación explícita de pérdida al KO
- **Prioridad**: Baja
- **Dificultad**: Trivial
- **Estado actual**: `R-KO-01` dice "todas las cartas adjuntas al descarte" — implícitamente incluye Tools. Convendría hacerlo explícito.
- **Toca a**: `03-combat.md` (sección Proceso de KO).
- **PASO sugerido**: aclaración textual, no requiere PASO nuevo.

### 10. "Sacar máximo de mazo" cuando piden más de las disponibles
- **Prioridad**: Baja
- **Dificultad**: Trivial
- **Estado actual**: `R-TURN-01` cubre el caso de mazo vacío al inicio del turno (R-WIN-02), pero no el de un efecto que pida "robar 5" cuando solo quedan 3.
- **Toca a**: `02-turn-flow.md` (sección Robo).
- **PASO sugerido**: aclaración textual en las reglas.

### 11. Reglas de empate alternativas (concesiones simultáneas, etc.)
- **Prioridad**: Baja
- **Dificultad**: Trivial
- **Estado actual**: `R-WIN-04` (Muerte Súbita) cubre KOs simultáneos. `07-edge-cases.md` cubre concesión simultánea (gana el primero en llegar). Quedan pendientes:
  - Empates por timeout simultáneo (ambos AFK)
  - Empates por desconexión simultánea sin reconexión (ya documentado en `07-edge-cases.md` con ELO neutral)
- **Toca a**: `07-edge-cases.md` (extender con casos de doble timeout).
- **PASO sugerido**: aclaración textual, no requiere PASO nuevo.

---

## Resumen de esfuerzo

| Prioridad | Cantidad | Esfuerzo total estimado |
|---|---|---|
| Media | 3 (#1, #2, #8) | 4-7 días |
| Baja | 8 (#3, #4, #5, #6, #7, #9, #10, #11) | 2-4 semanas (con #4 y #5 dominando) |

> **Recomendación:** abordar #1 (Stadium con efectos), #2 (Restaurados) y #8 (timing exacto) en una iteración 1.1 post-MVP. El resto puede esperar a feedback de usuarios reales.

---

## Estado del MVP

✅ **Reglas críticas cubiertas en MVP** (no están en este backlog):
- Concesión de partida (R-CONCEDE — `07-edge-cases.md`)
- Timeout de turno (R-TIMEOUT — `07-edge-cases.md`)
- Reconexión tras desconexión (R-RECONNECT — `07-edge-cases.md`)
- Energías especiales DCE/Rainbow (R-ENERGY-SPECIAL — `03-combat.md`)
- Habilidades pasivas vs activadas (R-ABILITY — `02-turn-flow.md`)

✅ **Inconsistencias técnicas resueltas** (no están en este backlog):
- MULLIGAN ahora incluye `extraCardsDrawn`
- TRAINER_PLAYED ahora incluye `replacedStadiumOwnerId`
- REPLACE_ACTIVE_AFTER_KO documentado en protocolo WS y enum de acciones
- `games.end_reason` agregado al schema BD con todos los valores posibles
