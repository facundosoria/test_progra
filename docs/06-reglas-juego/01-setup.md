# 01 — Setup Inicial

## ¿Qué hace este documento?
Define todo lo que ocurre **antes del primer turno**. Es el primer módulo que ejecuta el `GameEngine` cuando una partida pasa de `WAITING` a `SETUP`. Cubre el barajado, la mano inicial, el proceso de mulligan (incluyendo cartas extra al oponente), la colocación del Activo y Banca, las cartas de Premio, la revelación y el coin flip.

**Implementado en:** `game/engine/state/SetupState.java`
**Eventos emitidos:** `MULLIGAN`, `PRIZES_SET`, `COIN_FLIP`, `GAME_START`
**Referencia:** R-SETUP-01 a R-SETUP-09, R-RESTORED-02

# 01 — Setup Inicial

**Alcance:** Todo lo que ocurre antes del primer turno de la partida.
**Referencia de reglas:** R-SETUP-01 a R-SETUP-09, R-RESTORED-02.

---

## 1. Preparar el mazo

Cada jugador toma su mazo de exactamente 60 cartas y lo baraja.

### El sistema DEBE
- Confirmar que cada mazo tiene exactamente 60 cartas antes de iniciar el setup (ver `05-deck-validation.md`).
- Barajar el mazo aleatoriamente (orden completamente oculto para ambos jugadores).

### El sistema NO DEBE
- Iniciar el setup si un mazo no tiene exactamente 60 cartas.
- Revelar el orden del mazo en ningún momento salvo efecto de carta explícito.

---

## 2. Robar mano inicial

Cada jugador roba las 7 cartas superiores de su mazo.

### El sistema DEBE
- Transferir exactamente 7 cartas del mazo a la mano de cada jugador.
- Mantener la mano de cada jugador oculta para el oponente.

### El sistema NO DEBE
- Revelar la mano de ningún jugador al oponente durante este paso.

---

## 3. Verificar Pokémon Básico — Mulligan

Cada jugador verifica si tiene al menos 1 Pokémon Básico en mano.
Un Pokémon Básico es una carta con `supertype: "Pokémon"` y `subtypes` que incluye `"Basic"`.
Los Pokémon Restaurados (`subtypes: ["Restored"]`) **no** cuentan como Básicos.

### Caso A — Ninguno tiene Básico

### El sistema DEBE
- Detectar que ambos jugadores no tienen Básico.
- Hacer que ambos revelen sus manos simultáneamente.
- Barajar las manos de ambos de vuelta a sus mazos respectivos.
- Reiniciar el proceso completo de setup desde el paso 1 (nuevo barajado y nueva mano de 7).

### El sistema NO DEBE
- Registrar contadores de mulligan para ningún jugador en este caso (ambos reinician sin penalización cruzada).

---

### Caso B — Solo un jugador no tiene Básico

### El sistema DEBE
1. Detectar cuál jugador no tiene Básico y registrarlo como el jugador con mulligan.
2. Esperar a que el jugador SIN mulligan complete los pasos 4, 5 y 6 (colocar Activo, Banca y Premios) antes de que el jugador con mulligan revele su mano.
3. Hacer que el jugador con mulligan revele su mano y la baraje de vuelta al mazo.
4. Hacer que el jugador con mulligan robe 7 nuevas cartas.
5. Repetir los pasos 3–4 hasta que el jugador con mulligan tenga al menos 1 Básico en mano.
6. Por cada mulligan adicional que realizó el jugador con mulligan, permitir que el oponente robe 1 carta extra de su mazo.
7. Si alguna de esas cartas extra robadas por el oponente es un Pokémon Básico, permitir que el oponente la coloque inmediatamente en su Banca.

### El sistema NO DEBE
- Permitir que el jugador con mulligan revele su mano antes de que el oponente haya terminado su setup.
- Forzar al oponente a colocar en Banca las cartas extra (es opcional).
- Contar el primer mulligan para el conteo de cartas extra del oponente (el oponente roba 1 por cada mulligan *adicional*, no por el primero).

---

## 4. Colocar Pokémon Activo

Cada jugador elige 1 Pokémon Básico de su mano y lo coloca boca abajo en la zona Activo.

### El sistema DEBE
- Permitir al jugador elegir cuál de sus Básicos será el Activo.
- Colocar la carta boca abajo (no visible para el oponente) hasta el paso 7.

### El sistema NO DEBE
- Permitir colocar un Pokémon que no sea Básico como Activo.
- Permitir colocar un Pokémon Restaurado como Activo (no es Básico).
- Permitir colocar más de 1 Pokémon como Activo.

---

## 5. Colocar Pokémon en Banca (opcional)

Cada jugador puede colocar hasta 5 Pokémon Básicos adicionales boca abajo en su Banca.

### El sistema DEBE
- Permitir colocar entre 0 y 5 Pokémon Básicos en la Banca.
- Colocarlos boca abajo hasta el paso 7.

### El sistema NO DEBE
- Obligar al jugador a colocar Pokémon en Banca.
- Permitir colocar más de 5 Pokémon en Banca.
- Permitir colocar Evoluciones o Pokémon Restaurados en Banca durante el setup.

---

## 6. Colocar cartas de Premio

Cada jugador toma las 6 cartas superiores de su mazo y las coloca boca abajo como sus Premios (Prize Cards).

### El sistema DEBE
- Transferir exactamente las 6 cartas superiores del mazo a la zona de Premios, boca abajo.
- Mantener las cartas de Premio ocultas para ambos jugadores durante toda la partida hasta ser tomadas.

### El sistema NO DEBE
- Revelar qué cartas son los Premios en ningún momento (salvo efecto de carta explícito).
- Permitir que un jugador elija qué cartas poner como Premios.

---

## 7. Revelar Pokémon

Ambos jugadores dan vuelta simultáneamente todos sus Pokémon (Activo y Banca) para que sean visibles.

### El sistema DEBE
- Hacer visible el estado de todos los Pokémon en juego (Activo y Banca) para ambos jugadores.

---

## 8. Determinar quién empieza

Se lanza una moneda. El jugador que gane el lanzamiento decide quién juega primero.

### El sistema DEBE
- Realizar el lanzamiento de moneda de forma aleatoria (50/50).
- Permitir al ganador del lanzamiento elegir si quiere ir primero o segundo.
- Registrar cuál jugador va primero.

---

## 9. Restricción del primer turno

El jugador que va primero NO puede atacar en su primer turno.

### El sistema DEBE
- Registrar que el jugador inicial está en su "primer turno".
- Bloquear la acción de Atacar durante ese turno específico.

### El sistema NO DEBE
- Permitir ningún ataque en el primer turno del jugador inicial, bajo ninguna circunstancia.
- Aplicar esta restricción al segundo jugador (que puede atacar en su primer turno normalmente).
