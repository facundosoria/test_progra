# EPIC-08 — Bot e Inteligencia Artificial

## 1. Resumen

- **Valor de negocio:** los jugadores pueden practicar contra IA con dificultades crecientes y personalidades, sin depender de tener un humano disponible. Tambien aporta el chat en partida (vs bot o entre humanos).
- **Roles involucrados:** Jugador autenticado, Bot.
- **Sprints donde se completa:** S5 (Bot EASY base), S11 (MEDIUM/HARD + personalidades + chat).
- **Equipos:** A.

## 2. Historias de Usuario

### HU-08-01 — Jugar contra Bot EASY
**Como** jugador novato, **quiero** un rival que tome decisiones validas pero aleatorias, **para** aprender el juego sin presion.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: `BotEasy` retorna acciones aleatorias entre las validas (`getAvailableActions()`).
- AC2: Si no hay accion valida, retorna `END_TURN` (nunca lista vacia).
- AC3: Delay 500-1000 ms entre acciones del bot (UX).
- AC4: Una partida PvE EASY llega a `GAME_OVER` sin excepciones 500.
- AC5: Bot llamado automaticamente por `GameEngine` cuando es turno de "BOT".

**RNF:**
- RNF-Robustez: nunca loop infinito, fallback `END_TURN` garantizado.

**Sprint:** S5.

---

### HU-08-02 — Jugar contra Bot MEDIUM (greedy)
**Como** jugador con cierta experiencia, **quiero** un bot que elija la accion con mejor outcome inmediato, **para** ponerme a prueba.

**Story Points:** 8

**Criterios de Aceptacion:**
- AC1: `BotMedium` evalua todas las acciones validas y elige la de mayor "score" inmediato (dano, KO, premios).
- AC2: Funcion de scoring documentada y testeable.
- AC3: Mantiene fallback `END_TURN`.
- AC4: Tiempo de decision por turno < 2 s.

**Sprint:** S11.

---

### HU-08-03 — Jugar contra Bot HARD (minimax)
**Como** jugador avanzado, **quiero** un bot que planifique varios turnos, **para** un desafio real.

**Story Points:** 13

**Criterios de Aceptacion:**
- AC1: `BotHard` usa minimax con profundidad 3 + poda alfa-beta.
- AC2: Heuristica considera: HP propios y rivales, premios, energias en mano, mazo restante.
- AC3: Tiempo de decision < 5 s con timeout y fallback a Medium si se excede.
- AC4: Tests unitarios verifican que prefiere KO ahora vs KO en 2 turnos cuando es factible.

**Sprint:** S11.

---

### HU-08-04 — Elegir personalidad del bot
**Como** jugador, **quiero** elegir entre 3 personalidades (Hernan / Santoro / Ramiro), **para** que el bot tenga estilo propio.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: Selector en lobby PvE de personalidad.
- AC2: Cada personalidad tiene un set de mensajes para `GAME_START`, `ATTACK`, `KO`, `GAME_OVER`.
- AC3: Personalidad afecta solo el chat, no la dificultad.
- AC4: Personalidad seedeada en BD (tabla `bot_personalities` o JSON config).

**Sprint:** S11.

---

### HU-08-05 — Recibir mensajes con personalidad durante la partida
**Como** jugador, **quiero** que el bot me hable durante la partida, **para** que se sienta menos robotico.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: `BotChatService` con minimo 3 triggers: `GAME_START`, `ATTACK`, `KO`.
- AC2: Delay 1-3 s entre mensajes del bot (naturalidad).
- AC3: Mensaje guardado en `game_chat_messages` con `senderType=BOT`.
- AC4: Frontend renderiza el mensaje con label "Bot" y color distinto.
- AC5: Rate limit 1 mensaje por segundo por usuario en chat humano.

**RNF:**
- RNF-Privacidad: solo los participantes de la partida ven los mensajes.

**Sprint:** S11.

## 3. Tareas Tecnicas

| ID | Tarea | Origen | Equipo | SP | Sprint |
|---|---|---|---|---|---|
| TT-08-01 | `BotEasy` con `getAvailableActions()` y delay | PASO_S05_02 | A | 5 | S5 |
| TT-08-02 | `BotMedium` con funcion de scoring greedy | PASO_S11_01 | A | 8 | S11 |
| TT-08-03 | `BotHard` con minimax + alpha-beta | PASO_S11_01 | A | 13 | S11 |
| TT-08-04 | Tabla `game_chat_messages` indexada + endpoint POST | PASO_S11_02 | A | 3 | S11 |
| TT-08-05 | `BotChatService` con triggers `GAME_START/ATTACK/KO` | PASO_S11_02 | A | 3 | S11 |
| TT-08-06 | Personalidades (Hernan, Santoro, Ramiro) en JSON config | PASO_S11_03 | A | 3 | S11 |

## 4. Contratos involucrados

- REST: `POST /games/{id}/chat`, `GET /games/{id}/chat`.
- STOMP: `/topic/game/{gameId}/chat` (`CHAT_MESSAGE`).

## 5. Definition of Done especifico

- Test: 100 partidas PvE EASY consecutivas sin excepcion.
- Test: BotMedium prefiere KO inmediato vs dano de 50 sin KO.
- Test: BotHard timeout-safe (no bloquea backend).
- Cobertura `Bot*` ≥ 75%.
- Hereda [DOD.md](../../04_proceso/DOD.md) global.
