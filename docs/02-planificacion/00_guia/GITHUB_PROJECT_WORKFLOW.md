# Workflow GitHub Projects y planificacion Codemon

Este documento explica como leer la relacion entre Scrum, GitHub Projects v2 y los artefactos del proyecto Codemon.

---

## Tabla de referencias y relaciones

| Concepto | Abreviatura | En el proyecto Codemon | En GitHub | Para que sirve | Ejemplo |
|---|---:|---|---|---|---|
| Epica | EPIC | Agrupa varias historias relacionadas por area funcional o tecnica | Issue con label `epic` | Organizar el producto por grandes areas de valor | `EPIC-01 — Autenticacion y Seguridad` |
| Historia de Usuario | HU | Funcionalidad expresada desde el punto de vista del usuario | Issue con label `historia` | Definir que valor se entrega al usuario | `HU-01-03 — Iniciar sesion` |
| Tarea Tecnica | TT | Trabajo tecnico necesario para habilitar una HU o una epica | Puede ser checklist dentro de una HU, o issue tecnico si el equipo lo decide | Implementar infraestructura, contratos, tests, configuracion o soporte tecnico | `TT-10-01 — Definir CONTRATOS_API.md` |
| Issue | Issue | Tarjeta de trabajo trazable | Issue de GitHub | Conversar, asignar responsable, linkear PRs y seguir avance | Issue de `HU-01-03` |
| Label | Label | Clasificacion del issue | Etiqueta de GitHub | Filtrar y entender tipo, area o prioridad visual | `epic`, `historia`, `bug`, `backend`, `frontend` |
| Sprint | S0, S1... | Periodo de trabajo de 1 semana | Milestone o Iteration de Project v2 | Agrupar lo que se planea entregar en una semana | `S1 — Autenticacion basica` |
| Story Points | SP | Estimacion relativa de esfuerzo, complejidad e incertidumbre | Campo numerico `Story Points` en Project v2 | Planificar capacidad y carga del sprint | `HU-01-03 = 3 SP` |
| Status | - | Estado del item en el flujo de trabajo | Campo `Status` de Project v2 | Saber si esta pendiente, en curso, revisado o terminado | `Backlog`, `En progreso`, `Done` |
| Priority | - | Importancia relativa del item | Campo `Priority` de Project v2 | Ordenar que se toma primero | `Alta`, `Media`, `Baja` |
| Team | - | Equipo responsable | Campo `Team` de Project v2 | Repartir trabajo entre equipos | `Equipo A`, `Equipo B`, `Equipo C`, `All` |
| Milestone | - | Puede representar un sprint o entrega | Milestone de GitHub | Agrupar issues por fecha objetivo | `S2 — Catalogo + Mazos` |
| Iteration | - | Puede representar un sprint si se usa Projects v2 | Campo Iteration de Project v2 | Gestionar ciclos repetidos tipo Scrum | Sprint semanal dentro del tablero |
| Pull Request | PR | Cambio de codigo que implementa una HU/TT | Pull Request de GitHub | Revisar, testear y mergear cambios | PR que cierra `HU-01-03` |

---

## Relacion principal

| Relacion | Lectura correcta |
|---|---|
| Una epica contiene varias HU | `EPIC-01` agrupa registro, login, logout, refresh token, 2FA y OAuth |
| Una HU puede tener varias TT | `HU-01-03 Iniciar sesion` puede requerir controlador, servicio, JWT, tests y UI |
| Una HU se gestiona como issue | La HU vive en el backlog, pero se trabaja como issue en GitHub |
| Una TT puede vivir dentro de una HU | En este proyecto se documento que las TT suelen ir como checklist dentro del issue de la HU |
| Un issue tiene labels | Los labels no son trabajo, solo clasifican el issue |
| Un issue se asigna a un sprint | El sprint dice cuando se va a trabajar |
| Un issue tiene SP | Los SP indican el tamanio relativo del trabajo |
| Un sprint suma SP | La suma de SP ayuda a ver si el sprint esta sobrecargado |
| Un PR implementa uno o mas issues | El PR debe referenciar el issue que resuelve |
| `Done` requiere cumplir DoD | No alcanza con terminar codigo; debe pasar Definition of Done |

---

## GitHub Projects v2 en este proyecto

Campos esperados del tablero:

| Campo | Tipo | Valores esperados | Ejemplo |
|---|---|---|---|
| `Status` | Single select | `Backlog`, `Pendiente`, `En progreso`, `En revision`, `Done`, `Blocked` | `En progreso` |
| `Priority` | Single select | `Alta`, `Media`, `Baja` | `Alta` |
| `Type` | Single select | `Epic`, `Historia`, `Bug`, `Spike` | `Historia` |
| `Epic` | Text | `EPIC-01` a `EPIC-11` | `EPIC-01` |
| `Team` | Single select | `Equipo A`, `Equipo B`, `Equipo C`, `All` | `Equipo A` |
| `Story Points` | Number | Fibonacci: `1`, `2`, `3`, `5`, `8`, `13`, `21` | `5` |
| `Sprint` | Iteration o texto controlado | `S0` a `S11` | `S1` |

Nota: `SP` significa `Story Points`. Los sprints se abrevian como `S0`, `S1`, `S2`, etc.

---

## Milestone o Iteration para sprints

GitHub permite manejar sprints de dos maneras:

| Opcion | Ventaja | Cuando conviene |
|---|---|---|
| Milestone | Simple, visible desde issues y PRs, facil para entrega por fecha | Si el proyecto esta centrado en un repositorio y quieren una gestion simple |
| Iteration de Project v2 | Mas agil, pensado para sprints repetidos, permite mover trabajo entre ciclos | Si van a usar GitHub Projects v2 como tablero Scrum principal |

En Codemon, la documentacion actual dice que el sprint puede mapearse a `Milestone`, y tambien aparece como campo `Sprint` dentro del Project v2. Lo importante es no duplicar decisiones contradictorias: si `S2` esta en Project v2, el Milestone tambien deberia decir `S2`.

---

## Manual de lectura

### 1. Leer primero el Product Backlog

Archivo principal:

- `docs/02-planificacion/01_backlog/PRODUCT_BACKLOG.md`

Sirve para ver:

- todas las epicas;
- las HU por epica;
- los SP de cada HU;
- el sprint asignado;
- la prioridad general del producto.

Lectura recomendada:

1. Buscar la epica.
2. Leer sus HU.
3. Mirar columna `SP`.
4. Mirar columna `Sprint`.
5. Ver si ya tiene issue de GitHub.

Ejemplo:

| HU | Nombre | SP | Sprint |
|---|---|---:|---|
| `HU-01-03` | Iniciar sesion | 3 | S1 |

Lectura: la historia `HU-01-03` pertenece a autenticacion, vale `3 SP` y se planifica para el sprint `S1`.

---

### 2. Leer despues el plan de sprints

Archivo principal:

- `docs/02-planificacion/02_sprints/SPRINTS.md`

Sirve para ver:

- objetivo del sprint;
- entregable demoable;
- HU incluidas;
- TT incluidas;
- capacidad estimada;
- riesgos.

Ejemplo:

`Sprint 1 — Autenticacion basica` incluye `HU-01-01`, `HU-01-03`, `HU-01-04` y `HU-01-05`.

Lectura: esas historias forman el alcance funcional del sprint. Si una no esta terminada, el objetivo del sprint puede quedar incompleto.

---

### 3. Leer la epica especifica

Archivo ejemplo:

- `docs/02-planificacion/03_epicas/EPIC-01-AUTH/EPIC.md`

Sirve para ver el detalle de una epica:

- contexto;
- HU asociadas;
- criterios de aceptacion;
- requisitos no funcionales;
- dependencias.

Lectura recomendada:

1. Confirmar que HU pertenece a esa epica.
2. Leer criterios de aceptacion.
3. Revisar requisitos no funcionales.
4. Identificar tareas tecnicas relacionadas.

---

### 4. Leer el CSV si hace falta una vista tabular

Archivo:

- `docs/02-planificacion/01_backlog/epicas_y_user_stories.csv`

Sirve para importar o sincronizar informacion:

- epica;
- HU;
- nombre;
- rol;
- deseo;
- beneficio;
- acceptance criteria;
- requisitos no funcionales;
- Story Points;
- sprint;
- equipo.

Lectura: es la version mas estructurada del backlog. Es util para automatizar cargas a GitHub Projects.

---

### 5. Leer el issue en GitHub

Cuando la HU ya existe como issue, GitHub se vuelve la vista operativa.

En el issue deberia verse:

- titulo con ID de HU o EPIC;
- descripcion;
- criterios de aceptacion;
- labels;
- milestone o sprint;
- campos del Project v2;
- checklist tecnico;
- PRs vinculados.

Ejemplo de titulo:

`[HU-01-03] Iniciar sesion`

Labels esperados:

- `historia`
- `auth`
- `backend`
- `frontend` si aplica

Campos esperados:

- `Type = Historia`
- `Epic = EPIC-01`
- `Story Points = 3`
- `Sprint = S1`
- `Team = Equipo A`

---

### 6. Leer el PR

El PR muestra la implementacion.

Debe responder:

- que issue cierra;
- que archivos cambia;
- que tests se corrieron;
- que queda fuera de alcance.

Buenas referencias en el PR:

- `Closes #12`
- `Refs HU-01-03`
- `Sprint: S1`

Lectura: si el PR no referencia un issue o HU, se pierde trazabilidad.

---

## Flujo recomendado de trabajo

| Paso | Accion | Artefacto |
|---:|---|---|
| 1 | Definir o revisar epica | `EPIC-xx/EPIC.md` |
| 2 | Definir HU con criterios de aceptacion | `PRODUCT_BACKLOG.md` y CSV |
| 3 | Asignar SP, sprint y equipo | `PRODUCT_BACKLOG.md`, `SPRINTS.md`, Project v2 |
| 4 | Crear issue en GitHub | Issue con labels y campos |
| 5 | Mover issue a `En progreso` | Project v2 |
| 6 | Crear rama desde `develop` segun GitFlow | Ver [GITFLOW.md](GITFLOW.md) — naming: `feature/epic-slug/hu-id-desc` |
| 7 | Implementar y abrir PR | Pull Request |
| 8 | Revisar tests y DoD | `DOD.md` |
| 9 | Mergear PR | GitHub |
| 10 | Mover issue a `Done` | Project v2 |

---

## Ejemplo completo

| Nivel | Ejemplo | Que significa |
|---|---|---|
| Epica | `EPIC-01 — Autenticacion y Seguridad` | Area funcional de autenticacion |
| HU | `HU-01-03 — Iniciar sesion` | El usuario puede loguearse |
| SP | `3` | Trabajo chico/medio, relativamente claro |
| Sprint | `S1` | Se planifica en Autenticacion basica |
| Team | `Equipo A` | Responsable principal backend nucleo |
| Issue | `[HU-01-03] Iniciar sesion` | Tarjeta operativa en GitHub |
| Labels | `historia`, `auth`, `backend` | Clasificacion del issue |
| PR | `feature/auth/hu-01-03-login` | Implementacion concreta |
| Done | Issue cerrado + DoD cumplido | Trabajo terminado |

> Para gates de sincronizacion entre equipos, usar la matriz canonica en [DEPENDENCIAS_EPICAS.md](../04_proceso/DEPENDENCIAS_EPICAS.md#gates-de-sincronizacion).

---

## Como no confundirse

| Confusion comun | Correccion |
|---|---|
| `SP` significa sprint | No. `SP` significa Story Points |
| Sprint se abrevia `SP` | No. En este proyecto se usa `S0`, `S1`, `S2` |
| Label es una tarea | No. Label solo clasifica |
| Issue y HU son lo mismo | No exactamente. La HU es el contenido funcional; el issue es la tarjeta de gestion |
| Milestone siempre es epica | No. En este proyecto las epicas son issues con label `epic`; los milestones pueden representar sprints |
| Una TT siempre tiene que ser issue separado | No. En este proyecto se recomienda checklist dentro de la HU, salvo que el equipo decida separarla |
| `Done` es solo codigo terminado | No. Debe cumplir criterios de aceptacion, tests y Definition of Done |

---

## Regla corta para presentar

En Codemon, las epicas agrupan historias. Las historias y epicas se gestionan como issues en GitHub. Los labels clasifican esos issues. Los Story Points estiman tamanio relativo. Los sprints se nombran `S0` a `S11` y pueden manejarse como Milestones o como Iterations de Project v2. El Project v2 funciona como tablero operativo para ver estado, prioridad, equipo, sprint y avance.
