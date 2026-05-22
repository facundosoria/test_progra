# 02 — Flujo del Turno

## ¿Qué hace este documento?
Define la estructura de cada turno y el paso entre turnos. Es la lógica que el `TurnManager` y los estados `DrawPhaseState`, `MainPhaseState`, `AttackPhaseState` y `EndPhaseState` ejecutan en secuencia. Cubre las 3 fases (robar, acciones, atacar) y el procesamiento de condiciones especiales entre turnos.

**Implementado en:** `game/engine/state/` (DrawPhaseState, MainPhaseState, AttackPhaseState, EndPhaseState)
**Eventos emitidos:** `TURN_START`, `CARD_DRAWN`, `POKEMON_PLAYED`, `POKEMON_EVOLVED`, `ENERGY_ATTACHED`, `TRAINER_PLAYED`, `ABILITY_USED`, `RETREAT`, `BETWEEN_TURNS_DAMAGE`, `COIN_FLIP`
**Referencia:** R-TURN-01 a R-TURN-04b

# 02 — Flujo del Turno

**Alcance:** Todo lo que ocurre durante un turno y entre turnos.
**Referencia de reglas:** R-TURN-01 a R-TURN-04b.

---

## Estructura de un turno

Un turno tiene tres fases en orden estricto:
1. **Robar carta** (obligatorio)
2. **Acciones** (opcionales, en cualquier orden)
3. **Atacar y terminar** (opcional, pero termina el turno)

Después del turno se ejecuta el **Paso entre turnos** antes de que comience el turno del oponente.

---

## Fase 1 — Robar carta

Al inicio de cada turno, el jugador activo roba 1 carta de su mazo.

### El sistema DEBE
- Robar exactamente 1 carta del mazo al inicio del turno.
- Si el mazo está vacío al intentar robar, declarar derrota del jugador activo (ver `04-win-conditions.md`).

### El sistema NO DEBE
- Omitir el robo de carta al inicio del turno.
- Declarar derrota si un **efecto de carta** pide robar más cartas de las que quedan en el mazo: en ese caso, robar solo las disponibles y continuar normalmente. La derrota por mazo vacío aplica **únicamente** al robo obligatorio al inicio del turno.

---

## Fase 2 — Acciones del turno

Las acciones siguientes pueden realizarse en **cualquier orden** y **cuantas veces lo permita cada regla**. No hay un orden forzado entre ellas.

---

### 2a — Colocar Pokémon Básico en Banca

El jugador puede colocar Pokémon Básicos desde su mano a su Banca.

### El sistema DEBE
- Verificar que la carta es un Pokémon Básico (`supertype: "Pokémon"`, `subtypes` incluye `"Basic"`).
- Verificar que la Banca tiene espacio (máximo 5 Pokémon).
- Permitir colocar múltiples Básicos en el mismo turno.

### El sistema NO DEBE
- Permitir colocar cartas de Evolución directamente en Banca.
- Permitir colocar Pokémon Restaurados directamente en Banca desde la mano (requieren efecto de Item).
- Permitir colocar un sexto Pokémon en Banca cuando ya hay 5.

---

### 2b — Evolucionar Pokémon

El jugador puede evolucionar un Pokémon que ya está en juego colocando la carta de evolución encima.

Cadena de evolución: Basic → Stage 1 → Stage 2. El campo `evolvesFrom` de la carta de evolución indica de quién evoluciona.

### El sistema DEBE
- Verificar que la carta de evolución corresponde al Pokémon que está en juego según el campo `evolvesFrom`.
- Verificar que el Pokémon objetivo estuvo en juego desde el **inicio** de este turno (no fue jugado este turno).
- Verificar que el Pokémon objetivo **no fue evolucionado** en este mismo turno.
- Al evolucionar: eliminar todas las Condiciones Especiales del Pokémon (Dormido, Confuso, Paralizado, Envenenado, Quemado).
- Conservar los contadores de daño al evolucionar (el daño acumulado NO se cura).
- Permitir evolucionar múltiples Pokémon distintos en el mismo turno.

### El sistema NO DEBE
- Permitir evolucionar un Pokémon que fue colocado en juego en este mismo turno.
- Permitir evolucionar un Pokémon más de una vez por turno.
- Permitir saltarse un Stage (ej. de Basic directamente a Stage 2).
- Permitir usar una carta de Stage 1 sobre un Pokémon diferente al indicado en `evolvesFrom`.

**Caso especial — Mega Evolución:**
Cuando un Pokémon-EX se convierte en una Mega Evolución, el turno del jugador termina inmediatamente después de evolucionar (incluso si no atacó). El sistema debe aplicar esta restricción automáticamente.

---

### 2c — Adjuntar Energía

El jugador puede adjuntar 1 carta de Energía de su mano a cualquier Pokémon en juego (Activo o Banca).

### El sistema DEBE
- Registrar 1 adjunto de Energía por turno como límite.
- Verificar que el destino es un Pokémon en juego (Activo o en Banca del jugador activo).
- Registrar las Energías adjuntas por Pokémon para cálculos de costo de ataque y retirada.

### El sistema NO DEBE
- Permitir adjuntar más de 1 Energía por turno (regla base, salvo efecto de carta explícito).
- Permitir adjuntar Energía a un Pokémon del oponente (salvo efecto de carta explícito).

---

### 2d — Jugar cartas de Entrenador

#### Items
### El sistema DEBE
- Aplicar el efecto del Item inmediatamente al jugarlo.
- Enviar la carta al descarte del jugador después de aplicar el efecto.
- Permitir jugar cualquier cantidad de Items por turno.

---

#### Supporters
### El sistema DEBE
- Verificar que no se haya jugado otro Supporter en este turno.
- Aplicar el efecto inmediatamente y enviar la carta al descarte.
- Registrar que ya se usó 1 Supporter en este turno.

### El sistema NO DEBE
- Permitir jugar más de 1 Supporter por turno.

---

#### Stadiums
### El sistema DEBE
- Verificar que no haya ya un Stadium en juego con el mismo nombre.
- Si hay un Stadium diferente en juego, enviarlo al descarte antes de colocar el nuevo.
- Aplicar el efecto global del Stadium mientras permanezca en juego.
- Permitir solo 1 Stadium activo en total (zona compartida entre ambos jugadores).

### El sistema NO DEBE
- Permitir colocar un Stadium con el mismo nombre que el Stadium ya en juego.
- Permitir tener 2 Stadiums en juego simultáneamente.

---

#### Pokémon Tools
### El sistema DEBE
- Adjuntar la Tool al Pokémon destino.
- Verificar que el Pokémon destino no tenga ya una Tool adjunta.

### El sistema NO DEBE
- Permitir adjuntar más de 1 Tool por Pokémon.
- Remover la Tool al retirarse (la Tool permanece adjunta salvo efecto de carta).

---

### 2e — Retirar Pokémon Activo

El jugador puede mover su Pokémon Activo a la Banca y elegir un Pokémon de la Banca como nuevo Activo, pagando el costo de retirada.

Costo de retirada: cantidad de Energías a descartar del Pokémon Activo. Valor: campo `convertedRetreatCost` del JSON.

### El sistema DEBE
- Verificar que el jugador no se haya retirado en este turno.
- Verificar que el Pokémon Activo no está Dormido ni Paralizado.
- Verificar que el jugador tiene Energías suficientes adjuntas al Activo para pagar el costo.
- Descartar exactamente la cantidad de Energías indicada en `convertedRetreatCost`.
- Mover el Pokémon Activo a la Banca (conservando Energías restantes y daño).
- Permitir al jugador elegir cualquier Pokémon de su Banca como nuevo Activo.
- Al mover el Pokémon a la Banca: eliminar todas sus Condiciones Especiales.
- Registrar que ya se realizó 1 retirada en este turno.

### El sistema NO DEBE
- Permitir más de 1 retirada por turno.
- Permitir retirarse si el Pokémon está Dormido.
- Permitir retirarse si el Pokémon está Paralizado.
- Permitir retirarse si no hay Energías suficientes para pagar el costo (salvo costo 0).
- Eliminar el daño acumulado al retirarse (solo se eliminan las Condiciones Especiales).

---

### 2f — Usar Habilidades

Algunos Pokémon tienen Habilidades definidas en el campo `abilities` del JSON. En el set XY1 todas tienen `"type": "Ability"`, pero el campo `text` distingue su comportamiento. El motor debe clasificar cada habilidad en una de las dos categorías de R-ABILITY-01.

#### R-ABILITY-01 — Pasivas vs activadas

| Tipo | Cómo se reconoce en el `text` | Cuándo se ejecuta | ¿Consume acción? |
|---|---|---|---|
| **Activada** | El texto contiene patrones imperativos del jugador: "Once during your turn", "you may", "may use this Ability", "before your attack", etc. | Cuando el jugador envía `USE_ABILITY` durante la fase principal | No (no termina el turno) |
| **Pasiva (auto-trigger)** | El texto describe un trigger automático: "If this Pokémon is...", "When this Pokémon...", "Each time...", "As long as...", "Whenever...", etc. | El motor las dispara automáticamente al ocurrir el trigger | No (no requiere acción del jugador) |

#### R-ABILITY-02 — Identificación canónica

El motor parsea `text` con heurística léxica para clasificar:
- Si contiene `"Once during your turn"` o `"you may"` (imperativo al jugador) → activada.
- Si contiene `"If this Pokémon is"`, `"When"`, `"Each time"`, `"As long as"`, `"Whenever"` (trigger) → pasiva.
- En caso ambiguo, se trata como **pasiva** (más conservador: no hay acción de cliente requerida).

> En sets posteriores existe el `"type": "Poké-Power"` (activada) vs `"type": "Poké-Body"` (pasiva); aún no existen en XY1 pero el motor debe respetarlos si en el futuro se cargan otros sets.

#### R-ABILITY-03 — Momentos canónicos de trigger para habilidades pasivas

Las habilidades pasivas pueden activarse en estos momentos del flujo:

| Momento | Eventos asociados | Ejemplos en XY1 |
|---|---|---|
| Al entrar en juego un Pokémon | `POKEMON_PLAYED`, `POKEMON_EVOLVED` | "When you play this Pokémon..." |
| Al recibir daño | `DAMAGE_DEALT` (post-cálculo) | "If this Pokémon is damaged by an opponent's attack, put 3 damage counters on the Attacker" (Spiky Shield, Chesnaught) |
| Al ser KO el Pokémon con la habilidad | `POKEMON_KO` | "When this Pokémon is Knocked Out..." |
| Entre turnos | `BETWEEN_TURNS_DAMAGE` | "During each player's turn, if..." |
| Al atacar | `ATTACK_DECLARED` (pre-resolución) | "Each of this Pokémon's attacks does..." |
| Continuamente (modificadores) | Evaluado en cada cálculo de daño/costo | "As long as this Pokémon is your Active Pokémon, prevent..." |

El `GameEventPublisher` debe ofrecer hooks (Observer pattern) para que cada Pokémon en juego pueda inscribir listeners pasivos a los eventos relevantes. Cuando una habilidad pasiva se dispara, debe emitirse `ABILITY_USED` igual que las activadas (para visibilidad en el cliente).

### El sistema DEBE
- Clasificar cada habilidad como activada o pasiva al cargar la carta en juego (al `POKEMON_PLAYED` / `POKEMON_EVOLVED`).
- Para habilidades activadas: solo ejecutarlas al recibir `USE_ABILITY` con el `pokemonInstanceId` correcto.
- Para habilidades pasivas: registrar listeners y dispararlas automáticamente en el momento del trigger.
- Emitir `ABILITY_USED` en ambos casos (activada o pasiva), con el mismo formato definido en `06-system-logic.md`.
- Permitir múltiples Habilidades activadas por turno (de distintos Pokémon, o la misma si el `text` lo permite explícitamente).
- Permitir atacar en el mismo turno en que se usaron Habilidades (activadas o pasivas).
- Respetar restricciones "once per turn" (campo derivado del `text`) — el motor debe rastrear si una habilidad activada ya se usó este turno.

### El sistema NO DEBE
- Tratar las Habilidades como ataques (no terminan el turno).
- Permitir usar una Habilidad con restricción "once per turn" más de una vez por turno.
- Requerir acción `USE_ABILITY` para habilidades pasivas (es trigger automático).
- Suprimir el evento `ABILITY_USED` para pasivas (debe emitirse para que el cliente lo muestre).

---

#### R-ABILITY-04 — Habilidades que bloquean acciones del oponente

Algunas habilidades pasivas bloquean tipos de acción del oponente mientras el Pokémon con la habilidad está en juego (Activo o Banca, según diga el texto).

**Ejemplos en XY1:**
- **Trevenant / Forest's Curse**: "As long as this Pokémon is your Active Pokémon, your opponent can't play any Item cards from his or her hand." → bloquea `PLAY_ITEM` del oponente mientras Trevenant es el Activo.
- **Krookodile / Bother**: si la moneda del ataque sale cara, el oponente no puede jugar Supporters durante su próximo turno (con marker temporal).
- **Arbok / Gastro Acid**: el Pokémon Defensor no tiene Habilidades hasta el final del próximo turno propio (bloquea `USE_ABILITY` sobre el target afectado).

### El sistema DEBE
- Verificar, antes de ejecutar `PLAY_ITEM`, `PLAY_SUPPORTER`, `USE_ABILITY` o `DECLARE_ATTACK`, si alguna carta en juego tiene una habilidad o efecto activo que bloquea esa acción.
- Si está bloqueada, rechazar la acción mediante `GameActionException` con mensaje descriptivo (que llega a la UI del cliente como error 400).
- El bloqueo es dinámico: si el Pokémon con la habilidad bloqueante es KO o se retira, el bloqueo desaparece inmediatamente (excepto los markers temporales con `CLEAR_MARKER` que sobreviven hasta su EndPhase).

### El sistema NO DEBE
- Bloquear acciones del DUEÑO de la habilidad (solo bloquea al oponente, según el texto de cada carta).
- Aplicar el bloqueo cuando el Pokémon con la habilidad está en Banca y la habilidad especifica "as long as this Pokémon is your Active Pokémon".

> **Mecanismo:** todos estos bloqueos lanzan `GameActionException` desde el hook correspondiente del `CardHandler` (`onBeforePlayItem`, `onBeforePlaySupporter`, `onBeforeUseAbility`, `onBeforeAttackDeclared`). Ver `PATRON_CARD_HANDLER.md` § "Mecanismos de bloqueo: excepción vs flag".

---

#### R-ABILITY-05 — Habilidades que protegen Pokémon propios de efectos del oponente

Algunas habilidades pasivas hacen que ciertos efectos del oponente **no apliquen** sobre Pokémon propios. A diferencia de R-ABILITY-04, esto NO es un error del jugador atacante — el ataque se ejecuta correctamente, solo el efecto secundario no surte efecto.

**Ejemplo canónico en XY1:**
- **Slurpuff / Sweet Veil**: "Each of your Pokémon that has any Fairy Energy attached to it can't be affected by any Special Conditions." → bloquea aplicación de cualquier condición especial sobre Pokémon propios con Energía Hada adjunta. Slurpuff protege incluso desde Banca.

### El sistema DEBE
- Antes de aplicar una condición especial (`StatusEffectManager.applyStatus()`), propagar al `CardHandlerRegistry` el hook `onBeforeApplyStatus`.
- Si algún handler setea `ApplyStatusContext.blocked = true`: NO emitir `STATUS_APPLIED` y SÍ emitir `STATUS_BLOCKED` (ver `06-system-logic.md`).
- Re-evaluar la inmunidad al adherir energías o evolucionar (Sweet Veil además remueve condiciones existentes al activarse — ver `GAME_ENGINE_DETALLES_PARTE2.md` SC-01).

### El sistema NO DEBE
- Tratar el bloqueo como error del jugador atacante (no se rechaza el ataque, solo no se aplica el efecto secundario).
- Lanzar excepción desde `onBeforeApplyStatus` (usar el flag `ctx.setBlocked(true)`).

> **Mecanismo:** flag en el contexto, no excepción. La UI muestra **"It doesn't affect [Pokemon name]!"** (ver `06-system-logic.md` § STATUS_BLOCKED).

---

#### R-TURN-MARKER-01 — Efectos que duran "hasta el próximo turno"

Ciertos ataques producen efectos que persisten al siguiente turno del oponente o al siguiente turno propio. Estos efectos se implementan con el **sistema de markers** documentado en `PATRON_CARD_HANDLER.md` y `GAME_ENGINE_DETALLES_PARTE2.md` (PARTE 8).

**Efectos de "próximo turno del oponente" en XY1:**
- Prevención de daño (Kakuna Harden, Quilladin Scrunch, Aegislash King's Shield, Bunnelby/Diggersby Dig)
- Imposibilidad de atacar (Wigglytuff Hocus Pinkus)
- Imposibilidad de retirar (Zoroark Corner, Scolipede Poison Ring)
- Imposibilidad de usar Supporters (Krookodile Bother)
- Reducción de daño del defensor (Lunatone Moonblast)

**Efectos de "próximo turno propio" en XY1:**
- Imposibilidad de atacar (Rhyperior Rock Wrecker, Yveltal Darkness Blade, Xerneas-EX X Blast)
- Imposibilidad de usar un ataque específico (Aegislash King's Shield)
- Daño adicional (Bisharp Metal Wallop)

### El sistema DEBE
- Persistir los markers activos en el `state_json` del snapshot para sobrevivir reconexiones.
- Limpiar markers al final del turno correcto (ver GAME_ENGINE_DETALLES_PARTE2.md M-02, M-03). La limpieza ocurre en el **paso 0** del orden de paso entre turnos descripto más abajo (propagación `onEndTurn`).
- No limpiar markers de Pokémon al retirarse (solo `clearEffects()` limpia condiciones especiales, no markers del PlayerBoard).

---

Solo el Pokémon Activo puede atacar. Declarar un ataque termina el turno del jugador activo.

### El sistema DEBE
- Verificar que el Pokémon Activo no está Dormido ni Paralizado antes de permitir el ataque.
- Si el Pokémon Activo está Confuso, resolver el chequeo de Confusión antes de ejecutar el ataque:
  - Cara: el ataque se ejecuta normalmente.
  - Cruz: colocar 3 contadores de daño en el propio Pokémon Activo, el ataque no tiene efecto.
- Verificar que el jugador tiene adjuntas las Energías necesarias según el campo `cost` del ataque.
- Permitir al jugador elegir cuál ataque usar si el Pokémon tiene más de uno.
- Terminar el turno del jugador automáticamente al declarar el ataque.
- Delegar el cálculo de daño y efectos al módulo de combate (ver `03-combat.md`).

### El sistema NO DEBE
- Permitir atacar si el Pokémon Activo está Dormido.
- Permitir atacar si el Pokémon Activo está Paralizado.
- Permitir que un Pokémon de la Banca ataque.
- Permitir más de 1 ataque por turno.
- Permitir atacar al jugador inicial en su primer turno.
- Continuar con otras acciones después de declarar el ataque.

---

## Paso entre turnos (Between-turns step)

Ocurre **después** de que el turno activo termina y **antes** de que comience el turno del oponente.

Las condiciones especiales se resuelven en este orden fijo:

### El sistema DEBE
0. **Propagación `onEndTurn`**: invocar `CardHandlerRegistry.onEndTurn(EndTurnContext, ctx)` ANTES de procesar las condiciones especiales. Esto limpia markers de efectos de "próximo turno" (Kakuna Harden, Aegislash King's Shield, Krookodile Bother, Yveltal Darkness Blade, etc.) y desencadena cualquier efecto declarativo de fin de turno por las cartas en juego. Ver R-TURN-MARKER-01 y `GAME_ENGINE_DETALLES_PARTE2.md` M-02 / M-03.
1. Procesar **Envenenado**: colocar 1 contador de daño en cada Pokémon Activo envenenado.
2. Procesar **Quemado**: lanzar moneda. Cruz → colocar 2 contadores de daño. Cara → no ocurre nada. El marcador de quema permanece en ambos casos.
3. Procesar **Dormido**: lanzar moneda. Cara → el Pokémon se despierta (remover condición). Cruz → sigue Dormido.
4. Procesar **Paralizado**: si el Pokémon estaba Paralizado desde el inicio del turno que acaba de terminar, remover la condición automáticamente.
5. Verificar KOs causados por los efectos anteriores. Si un Pokémon queda KO por daño de condición especial, aplicar el proceso de KO completo (ver `03-combat.md`).

### El sistema NO DEBE
- Alterar el orden de procesamiento de condiciones especiales.
- Remover el marcador de quema automáticamente (se mantiene hasta que el Pokémon se retire o evolucione).
- Omitir la verificación de KOs al final del paso entre turnos.
- Aplicar el paso entre turnos antes del ataque (ocurre solo después de que el turno termina).
