# 05 — Validación de Mazos

## ¿Qué hace este documento?
Define las 7 reglas de validación que un mazo debe cumplir antes de poder usarse en una partida. Importante: el sistema debe ejecutar **todas** las validaciones y devolver **todos** los errores juntos, no detenerse en el primero. Es la lógica del `DeckValidationService`.

**Implementado en:** `decks/service/DeckValidationService.java`
**Cuándo se ejecuta:** Al guardar un mazo (validación previa) y al iniciar una partida (validación final)
**Referencia:** R-DECK-01 a R-DECK-07, R-RESTORED-03

# 05 — Validación de Mazos

**Alcance:** Reglas que determinan si un mazo es válido para jugar. Se aplican antes de iniciar la partida.
**Referencia de reglas:** R-DECK-01 a R-DECK-07, R-RESTORED-03.

---

## Reglas de validación

Un mazo válido debe cumplir **todas** las reglas siguientes. Si incumple cualquiera, debe ser rechazado con un mensaje de error específico.

---

### R-DECK-01 — Exactamente 60 cartas

### El sistema DEBE
- Contar el total de cartas del mazo.
- Rechazar el mazo si el total es diferente de 60.
- Devolver mensaje: `"El mazo debe tener exactamente 60 cartas. Tiene: {n}"`.

### El sistema NO DEBE
- Aceptar mazos con 59 o menos cartas.
- Aceptar mazos con 61 o más cartas.

---

### R-DECK-02 — Mínimo 1 Pokémon Básico

Un Pokémon Básico válido tiene `supertype: "Pokémon"` y `subtypes` que incluye `"Basic"`.
Los Pokémon Restaurados (`subtypes: ["Restored"]`) **no** cuentan como Básicos para esta regla.

### El sistema DEBE
- Verificar que exista al menos 1 carta con `supertype == "Pokémon"` y `subtypes` conteniendo `"Basic"`.
- Rechazar el mazo si no hay ningún Básico.
- Devolver mensaje: `"El mazo debe contener al menos 1 Pokémon Básico."`.

### El sistema NO DEBE
- Contar Pokémon Restaurados como Básicos para satisfacer este requisito.
- Contar cartas de Stage 1 o Stage 2 como sustituto de Básicos.

---

### R-DECK-03 — Máximo 4 copias por nombre

Con excepción de las Energías Básicas (R-DECK-04), ninguna carta puede repetirse más de 4 veces en el mazo. La comparación se hace por el campo `name` de la carta.

#### Reglas de conteo de nombre

| Caso | Regla | Ejemplo |
|---|---|---|
| Símbolos al final del nombre | Son parte del nombre | "Venusaur-EX" ≠ "Venusaur" |
| La "M" de Mega | Es parte del nombre | "M Venusaur-EX" ≠ "Venusaur-EX" |
| Nombre del propietario | Es parte del nombre | "Misty's Gyarados" ≠ "Gyarados" |
| Delta Species (δ) | NO es parte del nombre | "Charizard δ" = "Charizard" para el conteo |

### El sistema DEBE
- Agrupar las cartas del mazo por su campo `name` exacto.
- Verificar que ningún grupo (que no sea Energía Básica) supere las 4 copias.
- Rechazar el mazo si alguna carta supera el límite.
- Devolver mensaje: `"Demasiadas copias de '{name}': {n}/4 permitidas."`.

### El sistema NO DEBE
- Contar Energías Básicas dentro de este límite.
- Ignorar la diferencia entre "Charizard" y "Charizard-EX" (son nombres distintos).
- Tratar el símbolo δ como parte del nombre para el conteo de copias.

---

### R-DECK-04 — Energías Básicas ilimitadas

Las Energías Básicas son cartas con `supertype: "Energy"` y `subtypes: ["Basic"]`.

### El sistema DEBE
- Permitir cualquier cantidad de copias de Energías Básicas en el mazo.
- Excluir las Energías Básicas del conteo de la regla R-DECK-03.

### El sistema NO DEBE
- Aplicar el límite de 4 copias a ninguna Energía Básica.

---

### R-DECK-05 — Máximo 1 carta ACE SPEC

Las cartas ACE SPEC tienen `subtypes` que incluye `"ACE SPEC"`.

### El sistema DEBE
- Verificar que el mazo no contenga más de 1 carta con `subtypes` incluyendo `"ACE SPEC"`.
- Rechazar el mazo si hay 2 o más ACE SPEC.
- Devolver mensaje: `"Solo se permite 1 carta ACE SPEC por mazo."`.

**Nota:** No hay cartas ACE SPEC en el set XY1, pero la regla debe estar implementada para compatibilidad con otros sets.

---

### R-DECK-06 — Pokémon Tools sin límite en mazo

Las Pokémon Tools tienen `supertype: "Trainer"` y `subtypes` que incluye `"Pokémon Tool"`.

### El sistema DEBE
- Aplicarles la regla general de máximo 4 copias del mismo nombre (R-DECK-03) como cualquier otra carta de Trainer.

**Nota:** La restricción de "solo 1 Tool por Pokémon en juego" es una regla de gameplay (ver `02-turn-flow.md`), no de construcción de mazo.

---

### R-DECK-07 — Máximo 4 Energías Especiales

Las Energías Especiales tienen `supertype: "Energy"` y `subtypes: ["Special"]`.
A diferencia de las Energías Básicas, **no son ilimitadas**.

### El sistema DEBE
- Aplicar la regla general de máximo 4 copias del mismo nombre a las Energías Especiales (R-DECK-03 ya lo cubre si el conteo de nombres está bien implementado).
- Asegurarse de que el sistema **no** exime a las Energías Especiales del límite de 4 copias.

### El sistema NO DEBE
- Tratar las Energías Especiales como Energías Básicas (no son ilimitadas).
- Permitir más de 4 copias de una misma Energía Especial.

---

### Pokémon Restaurados — Impacto en validación

### El sistema DEBE
- Verificar que el mazo tiene al menos 1 Pokémon Básico aunque el mazo contenga Pokémon Restaurados.
- Un mazo compuesto solo de Pokémon Restaurados (sin ningún Básico) es inválido.

### El sistema NO DEBE
- Contar Pokémon Restaurados para satisfacer el requisito de R-DECK-02.

---

## Resumen de validaciones y mensajes de error

| Regla | Condición de rechazo | Mensaje sugerido |
|---|---|---|
| R-DECK-01 | Total ≠ 60 | "El mazo debe tener exactamente 60 cartas. Tiene: {n}" |
| R-DECK-02 | Sin Pokémon Básico | "El mazo debe contener al menos 1 Pokémon Básico." |
| R-DECK-03 | Más de 4 copias de un nombre | "Demasiadas copias de '{name}': {n}/4 permitidas." |
| R-DECK-05 | Más de 1 ACE SPEC | "Solo se permite 1 carta ACE SPEC por mazo." |
| R-DECK-07 | Más de 4 copias de una Energía Especial | Cubierto por R-DECK-03 |
| R-RESTORED | Solo Restaurados, sin Básicos | Cubierto por R-DECK-02 |

### El sistema DEBE
- Ejecutar **todas** las validaciones y devolver **todos** los errores encontrados en una sola respuesta (no detenerse en el primer error).
- Devolver mensajes de error accionables que identifiquen la carta o regla específica incumplida.

### El sistema NO DEBE
- Aceptar el mazo si incumple aunque sea 1 regla.
- Devolver solo el primer error encontrado (el usuario debe ver todos los problemas a la vez).
