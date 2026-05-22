# EPIC-06 — Tablero y Experiencia de Juego

## 1. Resumen

- **Valor de negocio:** la UI del tablero hace que el motor (EPIC-04) sea jugable: zonas, cartas, drag & drop, animaciones, lobby, chat. Sin tablero el motor existe pero nadie puede usarlo.
- **Roles involucrados:** Jugador autenticado.
- **Sprints donde se completa:** S5 (tablero minimo PvE), S6 (tablero pulido + lobby).
- **Equipos:** B (todo).

## 2. Historias de Usuario

### HU-06-01 — Ver mi mano, activo, banco, premios y descarte
**Como** jugador, **quiero** ver todas las zonas del tablero claramente diferenciadas, **para** entender el estado de la partida.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: Zona oponente: activo (HP, energias, condicion), banca con dorsos, contadores de mano/mazo/premios.
- AC2: Zona propia: activo y banca con imagenes reales, mano con cartas visibles, premios boca abajo.
- AC3: Estado actualizado SOLO via WebSocket (nunca optimista).
- AC4: HP de cada Pokemon visible en numeros y barra.
- AC5: Marcadores de condicion (POISONED, BURNED, etc.) visibles con icono.

**RNF:**
- RNF-Performance: render < 16 ms por frame.
- RNF-Accesibilidad: contraste AA en HP y condiciones.

**Sprint:** S5 (basico) / S6 (pulido).

---

### HU-06-02 — Arrastrar cartas desde mi mano al tablero
**Como** jugador, **quiero** arrastrar cartas de mi mano al activo o banca, **para** jugar Pokemon, evolucionar, adjuntar energia.

**Story Points:** 8

**Criterios de Aceptacion:**
- AC1: Drag de energia al activo dispara `ATTACH_ENERGY`.
- AC2: Drag de Basico al banco dispara `PLAY_BASIC_POKEMON`.
- AC3: Drag de Stage1/Stage2 sobre el Basico correcto dispara `EVOLVE_POKEMON`.
- AC4: Drop invalido se rechaza visualmente (carta vuelve a la mano con bounce).
- AC5: La accion se manda al backend y la UI espera el evento WebSocket de confirmacion.

**RNF:**
- RNF-Compatibilidad: `@angular/cdk/drag-drop` funcionando en Chrome, Firefox, Safari.

**Sprint:** S6.

---

### HU-06-03 — Ver animaciones de dano, KO y status
**Como** jugador, **quiero** ver animaciones cuando algo importante pasa, **para** que el juego se sienta dinamico.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: Dano: shake + numero flotante con cantidad.
- AC2: KO: fade out + sonido opcional (toggle en settings).
- AC3: Status: icono pulsante sobre el Pokemon afectado.
- AC4: Toast notifications: "Tomaste 1 premio", "Es tu turno", "Confusion: 30 a ti mismo".

**RNF:**
- RNF-Performance: animaciones via CSS transforms (GPU), no via JS layout.
- RNF-Accesibilidad: opcion de reducir movimiento (`prefers-reduced-motion`).

**Sprint:** S6.

---

### HU-06-04 — Lobby con seleccion de modo
**Como** jugador, **quiero** ver el lobby con 3 opciones (PvE, Ranked, Sala privada), **para** elegir como jugar.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: Tabs "PvE", "Ranked PvP", "Sala privada".
- AC2: PvE: selector de dificultad bot (EASY hoy, MEDIUM/HARD futuro).
- AC3: Ranked: selector de mazo + boton "Entrar a la cola".
- AC4: Sala privada: input de codigo + boton "Crear sala".
- AC5: La UI deshabilita opciones que requieran features no entregadas (grayed out con tooltip).

**RNF:**
- RNF-Usabilidad: estado de cola visible con timer.

**Sprint:** S6.

---

### HU-06-05 — Ver chat de la partida
**Como** jugador, **quiero** ver mensajes (sistema, bot, oponente) durante la partida, **para** entender que pasa o socializar.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: Componente `ChatWindow` con scroll automatico al ultimo mensaje.
- AC2: Tipos: USER (azul), BOT (verde con label "Bot"), SYSTEM (gris italico).
- AC3: Input deshabilitado si la partida esta `FINISHED`.
- AC4: Limite de 100 caracteres por mensaje.
- AC5: Rate limit 1 mensaje/segundo (visual: input bloqueado 1 s post-envio).

**RNF:**
- RNF-Seguridad: sanitizar HTML del mensaje (Angular sanitizer).

**Dependencias:** EPIC-08 (chat-bot) opcional, sistema funciona solo.
**Sprint:** S6.

---

### HU-06-06 — Usar la app responsive (mobile/tablet/desktop)
**Como** jugador, **quiero** que el juego funcione en mi celular, tablet y PC, **para** jugar desde cualquier dispositivo.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: Layout adaptable con Tailwind CSS (`grid`/`flex` + breakpoints `sm`/`md`/`lg`).
- AC2: Tablero re-organiza zonas en mobile (vertical stack).
- AC3: Drag & drop funcional con touch en tablet.
- AC4: Sin scroll horizontal en pantallas >= 360 px.

**RNF:**
- RNF-Performance: First Contentful Paint < 2 s en 3G.
- RNF-Calidad: Lighthouse score >= 80 en Performance, >= 90 en Accessibility.

**Sprint:** S11.

## 3. Tareas Tecnicas

| ID | Tarea | Origen | Equipo | SP | Sprint |
|---|---|---|---|---|---|
| TT-06-01 | `GameBoardComponent` con zonas: oponente / activo / banca / mano / premios / descarte | PASO_S05_04 | B | 13 | S5+S6 |
| TT-06-02 | Drag & drop con `@angular/cdk/drag-drop` | PASO_S05_04 | B | 8 | S6 |
| TT-06-03 | `WebSocketService` (STOMP + SockJS) con reconexion y resync via `getState()` | PASO_S05_04 | B | 5 | S5 |
| TT-06-04 | `LobbyComponent` con 3 tabs y selector de mazo | PASO_S06_01 | B | 5 | S6 |
| TT-06-05 | `ChatWindowComponent` con sanitizacion + rate limit visual | PASO_S05_04 | B | 3 | S6 |
| TT-06-06 | Animaciones CSS y toast notifications | PASO_S05_04 | B | 5 | S6 |
| TT-06-07 | Responsive con utilidades responsive de Tailwind (`sm:`/`md:`/`lg:`) | PASO_S11_07 | B | 3 | S11 |

## 4. Contratos involucrados

- Consume todos los endpoints REST y eventos STOMP de EPIC-04 y EPIC-05.

## 5. Definition of Done especifico

- Lighthouse mobile >= 80 Performance / >= 90 Accessibility.
- Drag & drop verificado en Chrome, Firefox, Safari y tablet (touch).
- `ngOnDestroy` desconecta WebSocket (sin memory leak validado en DevTools).
- Test manual: partida PvE completa desde lobby → tablero → game over.
- Hereda [DOD.md](../../04_proceso/DOD.md) global.
