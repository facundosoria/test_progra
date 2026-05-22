# 03 — Combate

## ¿Qué hace este documento?
Define el pipeline de ataque completo (9 pasos), el cálculo de daño en 6 pasos (base → efectos atacante → debilidad → resistencia → efectos defensor → resultado final), las 5 condiciones especiales con sus reglas de acumulación, y el proceso de KO. Es la lógica del `AttackPipeline` (Chain of Responsibility) y las `AttackEffectStrategy` (Strategy).

**Implementado en:** `game/engine/pipeline/` y `game/engine/strategy/effects/`
**Eventos emitidos:** `ATTACK_DECLARED`, `DAMAGE_DEALT`, `STATUS_APPLIED`, `STATUS_REMOVED`, `POKEMON_KO`, `PRIZE_TAKEN`, `COIN_FLIP`
**Referencia:** R-DMG-01 a R-DMG-05, R-STATUS-01 a R-STATUS-06, R-KO-01 a R-KO-02

# 03 — Combate

**Alcance:** Cálculo de daño, modificadores, condiciones especiales y proceso de KO.
**Referencia de reglas:** R-DMG-01 a R-DMG-05, R-STATUS-01 a R-STATUS-06, R-KO-01 a R-KO-02.

---

## Pipeline de ataque

Para ataques que involucran daño o efectos complejos, el sistema ejecuta los pasos en este orden:

1. Verificar precondiciones del atacante (Energías, estado Dormido/Paralizado, Confusión).
2. Ejecutar chequeo de Confusión si aplica.
3. Resolver elecciones que requiera el ataque (ej. elegir un Pokémon de Banca del oponente).
4. Ejecutar requisitos del ataque (ej. lanzar moneda si el ataque lo requiere).
5. Aplicar efectos que alteren o cancelen el ataque (ej. efectos de turno anterior).
6. Calcular y aplicar daño (ver sección de cálculo).
7. Aplicar efectos post-daño (condiciones especiales, efectos secundarios del ataque).
8. Verificar KOs.
9. Resolver premios y reemplazo de Pokémon Activo si hubo KO.

---

## Cálculo de daño

### Tipos de daño: normal vs. contadores directos

Algunos ataques hacen "X de daño" (daño normal, sujeto a modificadores).
Otros ataques dicen explícitamente "poner X contadores de daño" (daño directo, sin modificadores).

### El sistema DEBE
- Identificar si el ataque hace daño normal (campo `damage` con valor numérico) o coloca contadores directamente (indicado en el campo `text`).
- Para **contadores directos**: colocar los contadores inmediatamente, sin aplicar Debilidad, Resistencia ni ningún otro modificador. Detener el cálculo aquí.
- Para **daño normal**: continuar con el pipeline de 6 pasos.

### El sistema NO DEBE
- Aplicar Debilidad o Resistencia a contadores de daño colocados directamente.

---

### Paso 1 — Daño base

El daño base es el valor numérico del campo `damage` del ataque.

| Valor en `damage` | Significado |
|---|---|
| `"60"` | 60 de daño fijo |
| `"60+"` | 60 + modificador condicional descrito en `text` |
| `""` (vacío) | El ataque no hace daño directo (solo efecto) |

### El sistema DEBE
- Leer el valor numérico de `damage` como daño base.
- Si `damage` está vacío o es 0, detener el cálculo de daño (pero aplicar los efectos del `text`).

---

### Paso 2 — Efectos en el atacante (antes de Debilidad/Resistencia)

Aplicar efectos de Trainer cards, Energías u otros efectos activos que aumenten el daño antes de aplicar modificadores.

### El sistema DEBE
- Aplicar cualquier bonus de daño activo sobre el Pokémon atacante antes de calcular Debilidad.
- Verificar si hay efectos continuos del turno anterior que modifiquen el daño.

### El sistema NO DEBE
- Aplicar estos efectos después de la Debilidad o Resistencia (deben ir antes).

---

### Paso 3 — Debilidad (Weakness)

Si el Pokémon Activo **defensor** tiene debilidad al tipo del atacante, multiplicar el daño por 2.

- Campo del defensor: `weaknesses` (array de `{type, value}`)
- Campo del atacante: `types`

### El sistema DEBE
- Verificar si el tipo del atacante (`types`) coincide con el `type` de alguna entrada en `weaknesses` del defensor.
- Si coincide, multiplicar el daño acumulado por el valor indicado (generalmente ×2).
- Aplicar Debilidad **solo al Pokémon Activo defensor**. El daño a Pokémon en Banca nunca aplica Debilidad.

### El sistema NO DEBE
- Aplicar Debilidad al daño dirigido a Pokémon en Banca.
- Aplicar Debilidad si el ataque coloca contadores directos.
- Aplicar Debilidad si `request.isIgnoreWeakness() == true` (override por carta — ver R-IGN-01 más abajo).

---

### Paso 4 — Resistencia (Resistance)

Si el Pokémon Activo **defensor** tiene resistencia al tipo del atacante, restar 20 al daño.

- Campo del defensor: `resistances` (array de `{type, value}`)

### El sistema DEBE
- Verificar si el tipo del atacante coincide con el `type` de alguna entrada en `resistances` del defensor.
- Si coincide, restar el valor indicado (generalmente 20) al daño acumulado.
- Aplicar Resistencia **solo al Pokémon Activo defensor**. El daño a Pokémon en Banca nunca aplica Resistencia.

### El sistema NO DEBE
- Aplicar Resistencia al daño dirigido a Pokémon en Banca.
- Permitir que el daño baje de 0 por Resistencia (mínimo: 0).
- Aplicar Resistencia si `request.isIgnoreResistance() == true` (override por carta — ver R-IGN-01 más abajo).

---

### Paso 5 — Efectos en el defensor (después de Debilidad/Resistencia)

Aplicar efectos de Habilidades, Tools u otras cartas activas en el Pokémon defensor que reduzcan el daño después de los modificadores.

### El sistema DEBE
- Aplicar estos efectos de reducción después de calcular Debilidad y Resistencia.

### El sistema NO DEBE
- Aplicar estos efectos antes de Debilidad/Resistencia.
- Propagar al `CardHandlerRegistry` si `request.isIgnoreDefenderEffects() == true` (ver R-IGN-01 / R-DEFENDER-01 más abajo). Esto afecta a Greninja / Mist Slash, que ignora también efectos como Furfrou Fur Coat.

---

### Paso 6 — Resultado final

### El sistema DEBE
- Verificar que el daño final no sea negativo. Si es menor a 0, establecerlo en 0.
- Colocar 1 contador de daño por cada 10 puntos de daño final.
- Si el daño final es 0, no colocar ningún contador.

---

## Condiciones Especiales

Las condiciones especiales solo afectan al **Pokémon Activo**. Se eliminan al moverse a la Banca o al evolucionar.

### Clasificación de condiciones

| Tipo | Condición | Método de registro |
|---|---|---|
| De rotación | Dormido, Confuso, Paralizado | Rotan la carta; se reemplazan entre sí |
| De marcador | Envenenado, Quemado | Usan marcadores; coexisten con otras |

---

### Envenenado (Poisoned)

- **Efecto entre turnos:** colocar 1 contador de daño (10 HP de daño) en el Pokémon envenenado.
- **Se elimina:** al retirarse o evolucionar.

### El sistema DEBE
- Colocar exactamente 1 contador por cada paso entre turnos mientras el Pokémon esté envenenado.
- Eliminar el marcador de veneno cuando el Pokémon se retire a la Banca o evolucione.

### El sistema NO DEBE
- Permitir que un Pokémon tenga dos marcadores de veneno. Si ya está envenenado y recibe otra condición de veneno, el nuevo marcador reemplaza al viejo (sin cambio de efecto, pero se resetea si la nueva condición tiene variante).

---

### Quemado (Burned)

- **Efecto entre turnos:** lanzar moneda. Cruz → colocar 2 contadores de daño (20 HP). Cara → no ocurre daño.
- **El marcador de quema permanece** independientemente del resultado de la moneda.
- **Se elimina:** al retirarse o evolucionar.

### El sistema DEBE
- Lanzar moneda en el paso entre turnos para cada Pokémon quemado.
- Colocar 2 contadores si el resultado es Cruz.
- Mantener el marcador de quema activo tras el lanzamiento.
- Eliminar el marcador cuando el Pokémon se retire o evolucione.

### El sistema NO DEBE
- Eliminar el marcador de quema automáticamente si el resultado de la moneda es Cara.
- Permitir dos marcadores de quema en el mismo Pokémon.

---

### Dormido (Asleep)

- **Restricción:** el Pokémon no puede atacar ni retirarse mientras esté Dormido.
- **Efecto entre turnos:** lanzar moneda. Cara → el Pokémon se despierta (condición removida). Cruz → sigue Dormido.
- **Se elimina:** al despertarse por moneda, retirarse (por efecto de carta) o evolucionar.

### El sistema DEBE
- Bloquear ataque y retirada del Pokémon Dormido.
- Lanzar moneda en el paso entre turnos.
- Remover la condición si el resultado es Cara.

### El sistema NO DEBE
- Permitir atacar estando Dormido.
- Permitir retirarse estando Dormido (salvo efecto de carta que lo permita explícitamente).

---

### Paralizado (Paralyzed)

- **Restricción:** el Pokémon no puede atacar ni retirarse mientras esté Paralizado.
- **Se elimina:** automáticamente durante el **paso entre turnos** que sigue al turno del dueño (dura exactamente 1 turno completo del dueño). También se elimina al evolucionar o retirarse por efecto de carta.

### El sistema DEBE
- Bloquear ataque y retirada del Pokémon Paralizado.
- Registrar en qué turno fue paralizado.
- Eliminar la condición en el paso entre turnos posterior al turno del dueño.

### El sistema NO DEBE
- Permitir atacar estando Paralizado.
- Permitir retirarse estando Paralizado (salvo efecto de carta que lo permita).
- Mantener la parálisis más de 1 turno del dueño.

---

### Confuso (Confused)

- **Efecto al atacar:** antes de ejecutar el ataque, lanzar moneda.
  - Cara → el ataque se ejecuta normalmente.
  - Cruz → colocar 3 contadores de daño (30 HP) en el propio Pokémon Activo y el ataque falla sin efecto adicional.
- **Se elimina:** al retirarse o evolucionar.

### El sistema DEBE
- Lanzar moneda antes de ejecutar cualquier ataque del Pokémon Confuso.
- Si Cruz: aplicar 3 contadores al propio Pokémon y cancelar el ataque completamente.
- Si Cara: ejecutar el ataque normalmente.

### El sistema NO DEBE
- Aplicar los 3 contadores de Confusión como daño sujeto a Debilidad/Resistencia (son contadores directos).
- Omitir el chequeo de Confusión aunque el ataque haga 0 de daño.

---

### Inmunidad por habilidad pasiva (R-STATUS-IMMUNE)

Algunas habilidades pasivas otorgan inmunidad a una o más condiciones especiales. Antes de aplicar una condición, el motor DEBE consultar al `CardHandlerRegistry` mediante el hook `onBeforeApplyStatus`.

Si algún handler setea `ApplyStatusContext.blocked = true`:
- NO emitir `STATUS_APPLIED`.
- Emitir `STATUS_BLOCKED` con datos del Pokémon objetivo (`targetPokemonId`, `targetPokemonName`) y de la habilidad bloqueante (`blockingAbilityName`, `blockingCardId`). Ver `06-system-logic.md`.
- El ataque que intentó aplicar la condición se considera resuelto sin ese efecto secundario (el daño u otros efectos sí se aplican).

**Carta canónica en XY1:** Slurpuff / Sweet Veil — protege a todos los Pokémon propios con Energía Hada adjunta, incluso si Slurpuff está en Banca. Detalle de implementación en `GAME_ENGINE_DETALLES_PARTE2.md` SC-01.

> **UI:** el cliente debe renderizar `STATUS_BLOCKED` como **"It doesn't affect [Pokemon name]!"** (ver `06-system-logic.md`).

---

### Acumulación de condiciones

### El sistema DEBE
- Implementar que Dormido, Confuso y Paralizado se reemplazan mutuamente. Si un Pokémon tiene una de estas tres condiciones y recibe otra, la anterior desaparece y solo queda la nueva.
- Implementar que Envenenado y Quemado pueden coexistir entre sí y con cualquier condición de rotación.
- Permitir el estado: Envenenado + Quemado + (Dormido O Confuso O Paralizado) simultáneamente.

### El sistema NO DEBE
- Acumular más de una condición de rotación en el mismo Pokémon.
- Eliminar Envenenado o Quemado al aplicar una condición de rotación.

---

## Proceso de KO

Un Pokémon queda KO cuando sus contadores de daño (×10) son iguales o mayores a su HP.

### El sistema DEBE
1. Detectar el KO en el momento en que los contadores alcanzan o superan el HP.
2. Enviar el Pokémon KO y **todas** las cartas adjuntas (Energías, Tools) al descarte del dueño.
3. Permitir al rival tomar 1 carta de Premio de su propia zona de Premios y agregarla a su mano.
4. Si el Pokémon KO es un Pokémon-EX o una Mega Evolución: el rival toma **2** cartas de Premio en lugar de 1.
5. Obligar al dueño del Pokémon KO a elegir un Pokémon de su Banca como nuevo Activo.
6. Si el dueño no tiene Pokémon en Banca: declarar su derrota (ver `04-win-conditions.md`).
7. Verificar si el rival tomó su último Premio (condición de victoria, ver `04-win-conditions.md`).

### El sistema NO DEBE
- Aplicar Debilidad/Resistencia a los contadores de daño ya acumulados (solo al daño nuevo).
- Permitir que un Pokémon con HP en 0 o menos permanezca en juego.
- Olvidar descartar las cartas adjuntas (Energías y Tools) junto con el Pokémon KO.
- Permitir al dueño del KO elegir no reemplazar el Activo si tiene Pokémon en Banca (es obligatorio).

---

## Referencia rápida — Campos JSON para combate

| Campo JSON | Uso en combate |
|---|---|
| `hp` | Umbral de KO. Si contadores × 10 >= hp → KO |
| `types` | Tipo del atacante (para verificar Debilidad/Resistencia del defensor) |
| `attacks[].cost` | Energías necesarias para usar el ataque |
| `attacks[].damage` | Daño base del ataque |
| `attacks[].text` | Efectos adicionales (condiciones especiales, contadores directos, etc.) |
| `weaknesses` | `[{type, value}]` — Debilidad del defensor |
| `resistances` | `[{type, value}]` — Resistencia del defensor |
| `convertedRetreatCost` | Número de Energías a descartar para retirarse |
| `abilities` | Habilidades activables del Pokémon |
| `rules` | Reglas especiales (ej. "When Pokémon-EX is KO, opponent takes 2 Prize cards") |

---

## R-ENERGY-SPECIAL — Energías especiales y cobertura de costo

Las cartas de Energía Especial (`supertype: "Energy"` con `subtypes: ["Special"]` en el JSON) cubren el costo de ataques y retiradas según reglas particulares por carta. Este apartado define las dos energías especiales más comunes del set XY1 y la regla general.

### R-ENERGY-SPECIAL-01 — Double Colorless Energy (DCE)

- **Provee:** 2 unidades de energía Colorless cuando está adherida a un Pokémon.
- **Cuenta como:** 2 Colorless al verificar costos de ataque y de retirada.
- **No cuenta como:** ningún tipo específico (Fuego, Agua, etc.). Si un ataque pide "1 Fuego + 1 Colorless", una DCE adherida cubre solo el Colorless; el Fuego sigue faltando.
- **Una sola carta = dos energías:** al adherirse, ocupa un solo "slot" de carta pero suma 2 al conteo de energías del Pokémon a efectos de costo.

### R-ENERGY-SPECIAL-02 — Rainbow Energy

- **Provee:** 1 unidad de energía de cualquier tipo, elegida en el momento del cálculo del costo.
- **Cuenta como:** el tipo necesario para satisfacer el costo. Si el Pokémon necesita Fuego, Rainbow cuenta como Fuego; si necesita Agua, cuenta como Agua. Se evalúa por costo individual, no por carta.
- **Daño colateral al adherir:** al ejecutar `ATTACH_ENERGY` con Rainbow, el Pokémon receptor recibe 1 contador de daño (10 HP). Este daño solo se aplica una vez (al adherir), no entre turnos.
- **Caso borde:** si el Pokémon ya tenía 9 contadores y el daño colateral lo lleva a 10, queda KO inmediatamente al adherir Rainbow. Sigue las reglas normales de KO (R-KO-01).

### R-ENERGY-SPECIAL-03 — Reglas comunes a todas las energías especiales

- **Descarte al KO:** las energías especiales adheridas a un Pokémon KO van al descarte del dueño junto con el resto de cartas adjuntas, igual que las energías básicas.
- **Descarte al retirar:** se descartan según `convertedRetreatCost`, contando su valor de cobertura (DCE = 2, Rainbow = 1, otras según `text`). Una DCE puede pagar sola una retirada de costo 2.
- **Validación de mazo:** límite máximo de 4 energías especiales por mazo (R-DECK-07).
- **No cuentan como básicas:** las energías especiales NO son "Energía Básica" para reglas que pidan específicamente Energía Básica (algunos efectos de Trainer).

### El sistema DEBE
- Al verificar costo de ataque, asignar primero las energías de tipo específico requerido por el ataque y resolver Colorless al final con cualquier energía sobrante (incluidas DCE y Rainbow).
- Aplicar el contador de daño de Rainbow inmediatamente al `ATTACH_ENERGY`: emitir primero `ENERGY_ATTACHED` y luego `DAMAGE_DEALT` con `baseDamage = 10`, `weaknessApplied = false`, `resistanceApplied = false` (daño directo, R-DMG-04).
- Permitir al jugador elegir el orden de descarte de energías al retirar cuando hay varias combinaciones válidas que cubren el costo (UI muestra selector).

### El sistema NO DEBE
- Permitir que una DCE cubra costos de tipo específico (Fuego, Agua, Eléctrico, etc.).
- Aplicar el daño colateral de Rainbow más de una vez por adhesión.
- Aplicar Debilidad/Resistencia al daño colateral de Rainbow.
- Contar las energías especiales como "Energía Básica" para efectos que pidan específicamente básicas.

> **Nota técnica:** otras energías especiales del set XY1 (ej. Strong Energy, Herbal Energy, etc.) siguen el mismo patrón: el `text` de la carta declara qué tipo provee y qué efectos colaterales tiene. El motor debe parsear `text` para implementar cada caso particular.

---

## R-IGN — Ataques que ignoran Debilidad y/o Resistencia

Algunos ataques declaran explícitamente en su `text` que el daño no está afectado por Debilidad, Resistencia, o ambas. Esto es distinto del daño a Banca (que tampoco aplica W/R) — es una propiedad del ataque mismo.

### R-IGN-01 — Identificación de ataques con ignore

El texto del ataque contiene frases como:
- `"This attack's damage isn't affected by Weakness, Resistance, or any other effects on your opponent's Active Pokémon."` → ignora Debilidad, Resistencia, Y efectos del defensor
- `"This attack's damage isn't affected by Weakness or Resistance."` → ignora ambas
- `"This attack's damage isn't affected by Resistance."` → ignora solo Resistencia

**Cartas XY1 con este efecto:**

| Carta | Ataque | Ignora W | Ignora R | Ignora efectos defensor |
|---|---|---|---|---|
| Greninja | Mist Slash | ✓ | ✓ | ✓ |
| Rhyperior | Rock Wrecker | ✓ | ✓ | — |
| Dugtrio | Rock Tumble | — | ✓ | — |
| Inkay | Puncture | — | ✓ | — |
| Malamar | Puncture | — | ✓ | — |
| Aegislash | Buster Swing | — | ✓ | — |

### El sistema DEBE
- Representar estos flags como campos booleanos en `AttackRequest`: `ignoreWeakness`, `ignoreResistance`, `ignoreDefenderEffects` (todos `false` por defecto).
- Setear los flags ANTES de que `ApplyWeaknessHandler` y `ApplyResistanceHandler` corran (en el handler `ApplyAttackerEffectsHandler`).
- Si `ignoreWeakness = true`: saltear completamente el cálculo de Debilidad.
- Si `ignoreResistance = true`: saltear completamente el cálculo de Resistencia.
- Si `ignoreDefenderEffects = true`: saltear `ApplyDefenderEffectsHandler` (no llamar a los card handlers del defensor).

### El sistema NO DEBE
- Confundir "daño a Banca sin W/R" (siempre, por regla) con "ignoreWeakness flag" (solo cuando el texto del ataque lo especifica).
- Setear los flags después de que ApplyWeaknessHandler ya corrió (el daño ya estaría calculado mal).

> **Implementación:** ver `GAME_ENGINE_DETALLES_PARTE2.md` sección I-01, I-02, I-03 y `PATRON_CARD_HANDLER.md`.

---

## R-DEFENDER — Efectos del defensor que modifican el daño recibido

Además de Debilidad y Resistencia (que están en el JSON de la carta), algunas habilidades pasivas reducen o modifican el daño que recibe el Pokémon. Estos efectos se aplican en el **Paso 5** del cálculo de daño (después de Debilidad y Resistencia).

### R-DEFENDER-01 — Furfrou Fur Coat (ejemplo canónico)

`"Any damage done to this Pokémon by attacks is reduced by 20 (after applying Weakness and Resistance)."`

Este es el patrón de referencia para efectos de reducción del defensor:
- Se aplica **después** de Debilidad y Resistencia.
- Solo aplica a daño de ataques (no a contadores directos, no a daño por condiciones especiales entre turnos).
- El daño final nunca puede ser negativo.
- Si el ataque tiene `ignoreDefenderEffects = true`, este efecto es ignorado.

### El sistema DEBE
- Aplicar reducciones del defensor en `ApplyDefenderEffectsHandler`, entre `ApplyResistanceHandler` y `DealDamageHandler`.
- Verificar si `request.isIgnoreDefenderEffects()` antes de propagar al `CardHandlerRegistry`.
- Garantizar que el daño final sea `max(0, damage - reduction)`.

### El sistema NO DEBE
- Aplicar reducciones del defensor antes de Debilidad/Resistencia.
- Aplicar Fur Coat a daño directo (`isDirect = true` en el request).

> **Implementación:** ver `GAME_ENGINE_DETALLES_PARTE2.md` sección DS-01 y `PATRON_CARD_HANDLER.md` hook `onBeforeDamageApplied`.
