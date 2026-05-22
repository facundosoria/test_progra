# Product Backlog — Codemon TCG

> Backlog priorizado por valor de negocio. Cada item apunta a su epica para ver detalle (HU + AC + RNF + tareas tecnicas). Los sprints se planifican en [SPRINTS.md](../02_sprints/SPRINTS.md).

---

## Mapeo a GitHub Projects v2

> **Terminología correcta para GitHub Projects v2:**

| Concepto del proyecto | Entidad GitHub | Nota |
|---|---|---|
| **Épica** | Issue con label `epic` | NO usar Milestone para épicas |
| **Sprint** | **Milestone** de GitHub (S0, S1 ... S11) | Cada sprint es un Milestone con due date |
| **Historia de Usuario** | Issue con label `historia`, linked al issue épica padre | El body referencia al issue de épica |
| **Tarea Técnica** | Checklist dentro del Issue de su HU | NO crear issue separado para TT |

> **Campos del Project v2:** Status, Priority, Type, Epic, Team, Story Points, Sprint
> Ver contratos completos en `.github/project-fields.yml`

> **Script de setup:** `scripts/setup-github-project.sh OWNER/REPO`
> Crea automáticamente todos los labels, milestones e issues de épica + HU.

---

## Resumen

- **9 epicas funcionales** (con HU)
- **2 epicas tecnicas** (solo tareas tecnicas)
- **~63 Historias de Usuario**
- **~80 Tareas Tecnicas**
- **12 sprints de 1 semana** = ~12 semanas de calendario
- **3 equipos en paralelo** (A backend nucleo, B frontend, C backend auxiliar + DevOps)

---

## Priorizacion (ordenadas por valor + secuenciales por dependencias)

| Prioridad | Epica | Valor de negocio | Sprint(s) | Milestone | Estado | GitHub Issue |
|---|---|---|---|---|---|---|
| 1 | [EPIC-10 — Infraestructura y DevOps](../03_epicas/EPIC-10-INFRA/EPIC.md) | Habilita todo el resto | S0 | S0 — Kickoff | TODO | — |
| 2 | [EPIC-01 — Autenticacion y Seguridad](../03_epicas/EPIC-01-AUTH/EPIC.md) | Sin auth no hay producto | S1, S8, S10 | S1 — Auth básica | TODO | — |
| 3 | [EPIC-02 — Catalogo y Coleccion](../03_epicas/EPIC-02-COLECCION/EPIC.md) | Mostrar las 146 cartas | S2, S8 | S2 — Catálogo + Mazos | TODO | — |
| 4 | [EPIC-03 — Constructor de Mazos](../03_epicas/EPIC-03-MAZOS/EPIC.md) | Sin mazos no se puede jugar | S2 | S2 — Catálogo + Mazos | TODO | — |
| 5 | [EPIC-04 — Motor de Juego](../03_epicas/EPIC-04-MOTOR/EPIC.md) | Corazon del producto | S3, S4, S5 | S3 — Motor: setup + turnos | TODO | — |
| 6 | [EPIC-06 — Tablero y UX de juego](../03_epicas/EPIC-06-TABLERO/EPIC.md) | Hace jugable el motor | S5, S6, S11 | S5 — PvE jugable | TODO | — |
| 7 | [EPIC-08 — Bot e IA](../03_epicas/EPIC-08-BOT/EPIC.md) | Practica sin humanos | S5, S11 | S5 — PvE jugable | TODO | — |
| 8 | [EPIC-05 — Multijugador y Matchmaking](../03_epicas/EPIC-05-MULTIJUGADOR/EPIC.md) | PvP en tiempo real | S7 | S7 — PvP en tiempo real | TODO | — |
| 9 | [EPIC-07 — Tienda y Monetizacion](../03_epicas/EPIC-07-TIENDA/EPIC.md) | Aporta revenue | S8, S10 | S8 — Tienda + 2FA + métricas | TODO | — |
| 10 | [EPIC-09 — Social y Comunidad](../03_epicas/EPIC-09-SOCIAL/EPIC.md) | Retencion y compromiso | S9, S10 | S9 — Social v1 | TODO | — |
| 11 | [EPIC-11 — Calidad y Testing](../03_epicas/EPIC-11-CALIDAD/EPIC.md) | Sostenibilidad y entrega | transversal + S11 | S11 — Pulido + bots + E2E | TODO | — |

---

## Mapa Epica → HU (resumen)

### EPIC-01 — Autenticacion y Seguridad (7 HU)
| HU | Nombre | SP | Sprint | Issue # |
|---|---|---|---|---|
| HU-01-01 | Registro con email + password | 5 | S1 | — |
| HU-01-02 | Verificar cuenta via codigo email | 5 | S8 | — |
| HU-01-03 | Iniciar sesion | 3 | S1 | — |
| HU-01-04 | Cerrar sesion | 2 | S1 | — |
| HU-01-05 | Renovar sesion (refresh token) | 3 | S1 | — |
| HU-01-06 | 2FA por email | 5 | S8 | — |
| HU-01-07 | Login con Google/GitHub (OAuth2) | 8 | S10 | — |

### EPIC-02 — Catalogo y Coleccion (5 HU)
| HU | Nombre | SP | Sprint | Issue # |
|---|---|---|---|---|
| HU-02-01 | Ver catalogo paginado | 5 | S2 | — |
| HU-02-02 | Filtrar y buscar cartas | 3 | S2 | — |
| HU-02-03 | Ver detalle de carta | 3 | S2 | — |
| HU-02-04 | Ver mi coleccion personal | 5 | S8 | — |
| HU-02-05 | Ver estadisticas de coleccion | 3 | S8 | — |

### EPIC-03 — Constructor de Mazos (6 HU)
| HU | Nombre | SP | Sprint | Issue # |
|---|---|---|---|---|
| HU-03-01 | Crear mazo nuevo | 3 | S2 | — |
| HU-03-02 | Editar mazo con drag & drop | 8 | S2 | — |
| HU-03-03 | Validar mazo TCG | 5 | S2 | — |
| HU-03-04 | Eliminar mazo | 2 | S2 | — |
| HU-03-05 | Marcar mazo favorito | 2 | S2 | — |
| HU-03-06 | Copiar mazo starter | 3 | S2 | — |

### EPIC-04 — Motor de Juego (9 HU)
| HU | Nombre | SP | Sprint | Issue # |
|---|---|---|---|---|
| HU-04-01 | Iniciar partida con setup correcto | 8 | S3 | — |
| HU-04-02 | Robar carta al inicio del turno | 2 | S3 | — |
| HU-04-03 | Jugar Pokemon Basico al banco | 3 | S3 | — |
| HU-04-04 | Adjuntar energia | 3 | S3 | — |
| HU-04-05 | Evolucionar Pokemon | 3 | S3 | — |
| HU-04-06 | Atacar (9-handlers) | 21 | S4 | — |
| HU-04-07 | Retirar Pokemon activo | 3 | S4 | — |
| HU-04-08 | Tomar premios al hacer KO | 3 | S4 | — |
| HU-04-09 | Ganar la partida | 5 | S5 | — |

### EPIC-05 — Multijugador (5 HU)
| HU | Nombre | SP | Sprint | Issue # |
|---|---|---|---|---|
| HU-05-01 | Crear sala privada | 5 | S7 | — |
| HU-05-02 | Unirse a sala con codigo | 3 | S7 | — |
| HU-05-03 | Entrar a cola ranked | 8 | S7 | — |
| HU-05-04 | Cancelar cola | 2 | S7 | — |
| HU-05-05 | Recibir eventos en tiempo real | 5 | S7 | — |

### EPIC-06 — Tablero y UX (6 HU)
| HU | Nombre | SP | Sprint | Issue # |
|---|---|---|---|---|
| HU-06-01 | Ver zonas del tablero | 5 | S5/S6 | — |
| HU-06-02 | Drag & drop de cartas | 8 | S6 | — |
| HU-06-03 | Animaciones dano/KO/status | 5 | S6 | — |
| HU-06-04 | Lobby con seleccion de modo | 5 | S6 | — |
| HU-06-05 | Chat de partida | 3 | S6 | — |
| HU-06-06 | Responsive mobile/tablet/desktop | 5 | S11 | — |

### EPIC-07 — Tienda y Monetizacion (6 HU)
| HU | Nombre | SP | Sprint | Issue # |
|---|---|---|---|---|
| HU-07-01 | Ver balance de coins | 2 | S8 | — |
| HU-07-02 | Comprar coins con MP | 8 | S8 | — |
| HU-07-03 | Comprar sobre | 5 | S8 | — |
| HU-07-04 | Abrir sobre con animacion | 5 | S8 | — |
| HU-07-05 | Cooldown 24h | 3 | S8 | — |
| HU-07-06 | Historial de pagos | 3 | S10 | — |

### EPIC-08 — Bot e IA (5 HU)
| HU | Nombre | SP | Sprint | Issue # |
|---|---|---|---|---|
| HU-08-01 | Bot EASY | 5 | S5 | — |
| HU-08-02 | Bot MEDIUM (greedy) | 8 | S11 | — |
| HU-08-03 | Bot HARD (minimax) | 13 | S11 | — |
| HU-08-04 | Elegir personalidad | 3 | S11 | — |
| HU-08-05 | Mensajes con personalidad | 5 | S11 | — |

### EPIC-09 — Social y Comunidad (8 HU)
| HU | Nombre | SP | Sprint | Issue # |
|---|---|---|---|---|
| HU-09-01 | Perfil consolidado | 5 | S10 | — |
| HU-09-02 | Perfil publico de otro jugador | 3 | S10 | — |
| HU-09-03 | Solicitar amistad | 5 | S9 | — |
| HU-09-04 | Presencia en tiempo real | 5 | S9 | — |
| HU-09-05 | Leaderboard global | 3 | S9 | — |
| HU-09-06 | Mi posicion en ranking | 2 | S9 | — |
| HU-09-07 | Progresion por ligas | 5 | S9 | — |
| HU-09-08 | Leer noticias | 3 | S9 | — |

---

## Convenciones

- **HU IDs:** `HU-XX-YY` (XX = numero epica, YY = numero correlativo dentro de la epica).
- **TT IDs:** `TT-XX-YY` (mismo esquema).
- **Story Points:** escala Fibonacci 1, 2, 3, 5, 8, 13, 21.
- **Capacidad estimada por sprint:** ~120 SP combinando los 3 equipos en paralelo.
- **Estado:** TODO / IN PROGRESS / DONE / BLOCKED. Se mantiene en este archivo y en [epicas_y_user_stories.csv](epicas_y_user_stories.csv).

---

## Mantenimiento

Cada vez que se agregue, modifique o elimine una HU/TT, actualizar:
1. El `EPIC.md` correspondiente.
2. Esta tabla del `PRODUCT_BACKLOG.md`.
3. El [epicas_y_user_stories.csv](epicas_y_user_stories.csv).
4. El [SPRINTS.md](../02_sprints/SPRINTS.md) si afecta la planificacion del sprint.
5. El [BACKLOG.md](BACKLOG.md) (vista por sprint).
6. El `github-issue` en el bloque `<!-- GITHUB-ISSUE -->` del `docs/02-planificacion/backlog-master.md` cuando se cree el issue.

---

## Convenciones GitHub Projects v2

### Campos del Project v2

| Campo | Tipo | Valores |
|---|---|---|
| **Status** | Single select | Backlog / Pendiente / En progreso / En revisión / Done / Blocked |
| **Priority** | Single select | Alta / Media / Baja |
| **Type** | Single select | Epic / Historia / Bug / Spike |
| **Epic** | Text | EPIC-01 ... EPIC-11 |
| **Team** | Single select | Equipo A / Equipo B / Equipo C / All |
| **Story Points** | Number | Fibonacci: 1,2,3,5,8,13,21 |
| **Sprint** | Iteration | S0 — Kickoff ... S11 — Pulido + bots + E2E |

### Convención de ramas

| Tipo | Patrón | Ejemplo |
|---|---|---|
| Feature | `feature/{epic-slug}/{hu-id}-{desc}` | `feature/auth/hu-01-01-registro` |
| Fix | `fix/{issue-number}-{desc}` | `fix/42-deck-validation-error` |
| Hotfix | `hotfix/{issue-number}-{desc}` | `hotfix/99-payment-crash` |
| Épica | `epic/{epic-id-lowercase}` | `epic/epic-04` |

### Flujo de estados

```
Backlog → Pendiente → En progreso → En revisión → Done
                                         ↓
                                      Blocked
```

- **Backlog → Pendiente:** al inicio del sprint (Sprint Planning)
- **Pendiente → En progreso:** al crear la rama y hacer el primer commit
- **En progreso → En revisión:** al abrir el PR (automático via GitHub Action)
- **En revisión → Done:** al mergear el PR (automático via GitHub Action)
