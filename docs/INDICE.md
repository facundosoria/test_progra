# Indice de la documentacion

Esta carpeta `docs/` contiene toda la documentacion del proyecto Codemon TCG bajo metodologia **Scrum** (sprints de 1 semana, 3 equipos en paralelo) e incluye el material operativo para trabajar con agentes de IA.

> **Nuevo en el proyecto?** Leer primero [03-equipos/GUIA_PRIMER_DIA.md](03-equipos/GUIA_PRIMER_DIA.md) — prerequisitos, levantar el proyecto y comandos esenciales.

## Que hay en cada carpeta

| Carpeta | Contenido | Para que sirve |
|---|---|---|
| [01-producto/](01-producto/) | README completo, tecnologias y estructura del proyecto | Entender que se construye, con que stack y con que arquitectura |
| [02-planificacion/](02-planificacion/) | Artefactos Scrum: epicas, HU, sprints, DoD, backlog, equipos, dependencias, gitflow, workflow | Ejecutar y coordinar el proyecto bajo Scrum (sprints de 1 semana) |
| [03-equipos/](03-equipos/) | Guias del Equipo A, B y C + guia del primer dia | Saber responsabilidades, conocimientos previos y orden de trabajo por equipo |
| [04-diseno-ui/](04-diseno-ui/) | HTMLs de referencia visual | Alinear pantallas, layout y experiencia del frontend |
| [05-referencia-tecnica/](05-referencia-tecnica/) | Contratos API, schema BD, glosario canonico, mocks, protocolo WebSocket, patrones | Implementar con naming y contratos consistentes |
| [06-reglas-juego/](06-reglas-juego/) | Reglas XY1 completas (setup, turno, combate, victoria, validacion, logica, edge cases) | Implementar el motor de juego segun reglas oficiales del set XY1 |
| [07-infraestructura/](07-infraestructura/) | Dockerfiles de referencia, gateway local, nginx, monitoreo | Levantar, debuguear y monitorear el stack |
| [08-desarrollo-con-ia/](08-desarrollo-con-ia/) | Convenciones, sistema de PASOS, estado, historial, trazabilidad HU<->Paso<->GitHub | Construir el proyecto con agentes de IA bajo contratos estrictos |
| [09-handoff/](09-handoff/) | Handoff, checklist ejecutivo y documentos de entrega | Preparar la entrega final sin mezclarla con la ejecucion diaria |

## Flujo de lectura recomendado

1. Leer [02-planificacion/README.md](02-planificacion/README.md) para entender la metodologia Scrum aplicada, el mapa general y los gates.
2. Revisar [02-planificacion/01_backlog/PRODUCT_BACKLOG.md](02-planificacion/01_backlog/PRODUCT_BACKLOG.md) (priorizacion) y [02-planificacion/02_sprints/SPRINTS.md](02-planificacion/02_sprints/SPRINTS.md) (plan sprint a sprint).
3. Consultar [02-planificacion/04_proceso/EQUIPOS.md](02-planificacion/04_proceso/EQUIPOS.md) para trabajo paralelo y [02-planificacion/04_proceso/DEPENDENCIAS_EPICAS.md](02-planificacion/04_proceso/DEPENDENCIAS_EPICAS.md) para la matriz canonica de gates.
4. Leer la guia del equipo correspondiente: [Equipo A](03-equipos/GUIA_EQUIPO_A.md), [Equipo B](03-equipos/GUIA_EQUIPO_B.md) o [Equipo C](03-equipos/GUIA_EQUIPO_C.md).
5. Para detalle de una HU/TT especifica, abrir el `EPIC.md` correspondiente en [02-planificacion/03_epicas/](02-planificacion/03_epicas/).
6. [01-producto/ESPECIFICACION_PRODUCTO.md](01-producto/ESPECIFICACION_PRODUCTO.md) cuando haga falta la especificacion funcional del producto.
7. [02-planificacion/02_sprints/CHECKLIST_ENTREGA.md](02-planificacion/02_sprints/CHECKLIST_ENTREGA.md) y [02-planificacion/04_proceso/DOD.md](02-planificacion/04_proceso/DOD.md) como criterio de cierre.

## Artefactos Scrum clave

| Artefacto | Archivo |
|---|---|
| Convenciones y mapa de la planificacion | [02-planificacion/README.md](02-planificacion/README.md) |
| Product Backlog priorizado | [02-planificacion/01_backlog/PRODUCT_BACKLOG.md](02-planificacion/01_backlog/PRODUCT_BACKLOG.md) |
| Plan de los 12 sprints | [02-planificacion/02_sprints/SPRINTS.md](02-planificacion/02_sprints/SPRINTS.md) |
| Backlog operativo (vista por sprint) | [02-planificacion/01_backlog/BACKLOG.md](02-planificacion/01_backlog/BACKLOG.md) |
| Definition of Done | [02-planificacion/04_proceso/DOD.md](02-planificacion/04_proceso/DOD.md) |
| Equipos y capacity | [02-planificacion/04_proceso/EQUIPOS.md](02-planificacion/04_proceso/EQUIPOS.md) |
| Dependencias entre epicas + Gates | [02-planificacion/04_proceso/DEPENDENCIAS_EPICAS.md](02-planificacion/04_proceso/DEPENDENCIAS_EPICAS.md) |
| Checklist de entrega | [02-planificacion/02_sprints/CHECKLIST_ENTREGA.md](02-planificacion/02_sprints/CHECKLIST_ENTREGA.md) |
| Indice contratos REST/STOMP -> HU | [02-planificacion/04_proceso/CONTRATOS_INDEX.md](02-planificacion/04_proceso/CONTRATOS_INDEX.md) |
| CSV importable | [02-planificacion/01_backlog/epicas_y_user_stories.csv](02-planificacion/01_backlog/epicas_y_user_stories.csv) |
| Estado operativo de PASOS | [08-desarrollo-con-ia/ESTADO_PASOS.md](08-desarrollo-con-ia/ESTADO_PASOS.md) |
| Historial operativo de PASOS | [08-desarrollo-con-ia/HISTORIAL_PASOS.md](08-desarrollo-con-ia/HISTORIAL_PASOS.md) |

## Puntos importantes

- Los archivos de implementacion paso a paso estan en [08-desarrollo-con-ia/pasos/](08-desarrollo-con-ia/pasos/) y se citan desde las **Tareas Tecnicas** de cada `EPIC.md`.
- El avance real de esos pasos se controla en [08-desarrollo-con-ia/ESTADO_PASOS.md](08-desarrollo-con-ia/ESTADO_PASOS.md) y su historial en [08-desarrollo-con-ia/HISTORIAL_PASOS.md](08-desarrollo-con-ia/HISTORIAL_PASOS.md).
- Las reglas del juego viven en [06-reglas-juego/](06-reglas-juego/) y la referencia tecnica (contratos, schema, glosario, mocks) en [05-referencia-tecnica/](05-referencia-tecnica/).
- La infraestructura de referencia (Dockerfiles, nginx, monitoreo) esta en [07-infraestructura/](07-infraestructura/).
- Si vas a trabajar con una IA, usa primero [08-desarrollo-con-ia/README.md](08-desarrollo-con-ia/README.md).
- Los archivos antiguos (`INDEX.md`, `MULTI_EQUIPO.md`, `ANALISIS_DEPENDENCIAS.md`, `CODEMON_CHECKLIST.md`, `EPICAS_USER_STORIES_README.md`) ahora son redirects al artefacto Scrum equivalente, conservados en [02-planificacion/99_deprecados/](02-planificacion/99_deprecados/).
