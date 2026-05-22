# 04 — Condiciones de Victoria

## ¿Qué hace este documento?
Define las 3 condiciones de victoria (premios agotados, mazo vacío, sin Pokémon) y cómo resolver el caso especial de Muerte Súbita cuando ambos jugadores cumplen condiciones simultáneamente. Es la lógica del `VictoryConditionChecker`.

**Implementado en:** `game/victory/VictoryConditionChecker.java`
**Eventos emitidos:** `GAME_OVER`, `SUDDEN_DEATH_START`, `PRIZES_SET`
**Referencia:** R-WIN-01 a R-WIN-04

# 04 — Condiciones de Victoria

**Alcance:** Cómo termina la partida y cómo resolver empates simultáneos.
**Referencia de reglas:** R-WIN-01 a R-WIN-04.

---

## Las tres condiciones de victoria

Un jugador gana la partida si ocurre cualquiera de estas tres condiciones:

| ID | Condición | Cuándo verificar |
|---|---|---|
| R-WIN-01 | Tomó todas sus cartas de Premio | Tras cada KO |
| R-WIN-02 | El oponente no puede robar al inicio de su turno | Al inicio de cada turno |
| R-WIN-03 | El oponente no tiene Pokémon en juego | Tras cada KO o efecto que retire Pokémon |

---

## R-WIN-01 — Tomar todos los Premios

Cuando un jugador toma su última carta de Premio, gana la partida inmediatamente.

### El sistema DEBE
- Verificar tras cada KO si el jugador que tomó el premio(s) ya no tiene más Premios.
- Si el contador de Premios llega a 0, declarar la victoria inmediatamente.
- Detener la partida al instante (no continuar con otras resoluciones).

### El sistema NO DEBE
- Permitir que la partida continúe después de que un jugador tomó su último Premio.

---

## R-WIN-02 — Mazo vacío al inicio del turno

Si un jugador no puede robar su carta obligatoria al inicio de su turno porque el mazo está vacío, pierde.

### El sistema DEBE
- Verificar si el mazo tiene al menos 1 carta antes del robo obligatorio de inicio de turno.
- Si el mazo está vacío en ese momento: declarar la derrota del jugador activo.

### El sistema NO DEBE
- Declarar derrota si el mazo se vacía por un **efecto de carta** durante el turno (no al inicio). En ese caso, simplemente no hay más cartas para robar y el juego continúa.
- Declarar derrota al inicio del turno si quedan 0 cartas en mano pero el mazo tiene cartas (la condición es solo sobre el robo del mazo).

---

## R-WIN-03 — Sin Pokémon en juego

Si un jugador no tiene ningún Pokémon en juego (ni en posición Activo ni en Banca), pierde.

### El sistema DEBE
- Verificar esta condición inmediatamente después de cualquier evento que pueda dejar sin Pokémon al jugador:
  - Tras un KO donde el dueño no tiene Pokémon en Banca para reemplazar el Activo.
  - Tras cualquier efecto de carta que retire Pokémon de la zona de juego.
- Declarar derrota si el jugador no tiene ningún Pokémon en juego.

### El sistema NO DEBE
- Continuar la partida si un jugador no tiene Pokémon Activo y no tiene Banca para reemplazarlo.
- Dar tiempo extra al jugador para buscar un Pokémon (la derrota es inmediata).

---

## R-WIN-04 — Muerte Súbita (Sudden Death)

Si ambos jugadores cumplen una condición de victoria/derrota en el mismo momento, se juega Muerte Súbita.

**Ejemplo típico:** el último Pokémon de ambos jugadores se noquean mutuamente en el mismo turno.

### Proceso de Muerte Súbita

### El sistema DEBE
1. Detectar que ambas condiciones de derrota se cumplen simultáneamente.
2. Iniciar una nueva partida completa con las mismas reglas de setup (ver `01-setup.md`), pero con **1 sola carta de Premio** por jugador en lugar de 6.
3. Realizar nuevo coin flip para determinar quién va primero.
4. El primer jugador que tome su única carta de Premio gana la partida completa.
5. Si la Muerte Súbita también termina simultáneamente, repetir otra Muerte Súbita hasta que haya ganador.

### El sistema NO DEBE
- Declarar empate (el empate no existe en el Pokémon TCG oficial).
- Saltarse el Coin Flip en la Muerte Súbita.
- Usar 6 cartas de Premio en la Muerte Súbita.

---

## Caso especial — Doble condición de victoria

Si un jugador cumple **dos** condiciones de victoria al mismo tiempo y el oponente cumple solo **una**, el primero gana directamente sin Muerte Súbita.

**Ejemplo:** El jugador A toma su último Premio (R-WIN-01) y el oponente queda sin Pokémon en juego (R-WIN-03), pero el jugador A ya ganó por R-WIN-01 antes de que se evalúe la situación del oponente.

### El sistema DEBE
- Evaluar todas las condiciones de victoria simultáneamente.
- Si un jugador cumple más condiciones que el otro, declararlo ganador directamente.

### El sistema NO DEBE
- Iniciar Muerte Súbita cuando un jugador tiene ventaja en el número de condiciones cumplidas.

---

## Resumen de verificación por evento

| Evento en juego | Condiciones a verificar |
|---|---|
| Pokémon KO | R-WIN-01 (premios del rival), R-WIN-03 (Pokémon del dueño del KO) |
| Inicio de turno | R-WIN-02 (mazo vacío) |
| Efecto de carta retira Pokémon | R-WIN-03 |
| Ambas condiciones simultáneas | R-WIN-04 (Muerte Súbita) |
