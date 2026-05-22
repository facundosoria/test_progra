# Listado Completo de Archivos - Codemon TCG

> Este listado refleja la estructura del proyecto despues de adoptar metodologia **Scrum** en la carpeta `docs/02-planificacion/`.

## Raiz

| Ruta | Uso |
|---|---|
| `README.md` | Landing publica del proyecto |
| `CONTRIBUTING.md` | Guia operativa: orden de lectura, arranque y trabajo diario |
| `docker-compose.yml` | Stack completo (10 servicios) |
| `docker-compose.prod.yml` | Overlay productivo HTTPS (Nginx 80/443 + servicios internos sin puertos publicos) |
| `.env.example` | Plantilla de variables de entorno |
| `.env.production.example` | Plantilla de variables productivas HTTPS |
| `.gitignore` | Reglas de exclusion |
| `api/` | Backend Spring Boot (codigo fuente) |
| `front/` | Frontend Angular (codigo fuente) |
| `infra/` | Configuracion runtime (Prometheus, Grafana) |
| `scripts/` | Tooling: verify_paso, trazabilidad, sync con GitHub |
| `docs/` | Toda la documentacion del proyecto (9 capitulos tematicos) |
| `.github/` | Templates de issues, workflows y campos de GitHub Projects |
| `.claude/` | Configuracion local de Claude Code (no commit) |

## docs/

### 03-equipos (era 01_equipos + GUIA_PRIMER_DIA)

| Archivo | Uso |
|---|---|
| `docs/03-equipos/GUIA_EQUIPO_A.md` | Guia del backend core y motor de juego |
| `docs/03-equipos/GUIA_EQUIPO_B.md` | Guia del frontend Angular + Tailwind CSS |
| `docs/03-equipos/GUIA_EQUIPO_C.md` | Guia de backend auxiliar, DevOps e integraciones |

### 01-producto (era 02_producto)

| Archivo | Uso |
|---|---|
| `docs/01-producto/ESPECIFICACION_PRODUCTO.md` | Especificacion funcional del producto |
| `docs/01-producto/TECNOLOGIAS.md` | Explicacion del stack |
| `docs/01-producto/ESTRUCTURA_PROYECTO.md` | Estructura esperada del proyecto implementado |

### 02-planificacion (era 03_planificacion, Scrum)

#### Artefactos principales

| Archivo | Uso |
|---|---|
| `docs/02-planificacion/README.md` | Convenciones Scrum + mapa de la planificacion |
| `docs/02-planificacion/01_backlog/PRODUCT_BACKLOG.md` | Backlog priorizado por valor (11 epicas + ~63 HU) |
| `docs/02-planificacion/02_sprints/SPRINTS.md` | Plan de los 12 sprints con Sprint Goal y entregable |
| `docs/02-planificacion/01_backlog/BACKLOG.md` | Backlog operativo (vista por sprint) con HU + TT |
| `docs/02-planificacion/04_proceso/DOD.md` | Definition of Ready + Definition of Done global y por epica |
| `docs/02-planificacion/04_proceso/EQUIPOS.md` | Estructura de los 3 equipos + capacity + asignacion por sprint |
| `docs/02-planificacion/04_proceso/DEPENDENCIAS_EPICAS.md` | Mapa de dependencias entre epicas + gates de sincronizacion |
| `docs/02-planificacion/04_proceso/CONTRATOS_INDEX.md` | Mapeo endpoint REST / evento STOMP -> HU |
| `docs/02-planificacion/02_sprints/CHECKLIST_ENTREGA.md` | Items por sprint + entrega final |
| `docs/02-planificacion/01_backlog/epicas_y_user_stories.csv` | Volcado tabular para importar a Jira/Trello |
| `docs/02-planificacion/01_backlog/BACKLOG_REGLAS_POST_MVP.md` | Backlog de reglas TCG opcionales post-MVP |
| `docs/02-planificacion/00_guia/LISTADO_COMPLETO_ARCHIVOS.md` | Este listado |

#### Carpetas por epica

Cada carpeta contiene un unico `EPIC.md` con HU, AC, RNF, Tareas Tecnicas, contratos y DoD especifico.

| Carpeta | Tipo | Foco |
|---|---|---|
| `docs/02-planificacion/03_epicas/EPIC-01-AUTH/` | Funcional | Autenticacion (registro, login, 2FA, OAuth2) |
| `docs/02-planificacion/03_epicas/EPIC-02-COLECCION/` | Funcional | Catalogo y coleccion personal de cartas |
| `docs/02-planificacion/03_epicas/EPIC-03-MAZOS/` | Funcional | Constructor de mazos con validacion TCG |
| `docs/02-planificacion/03_epicas/EPIC-04-MOTOR/` | Funcional | Motor de juego TCG completo |
| `docs/02-planificacion/03_epicas/EPIC-05-MULTIJUGADOR/` | Funcional | Salas privadas + matchmaking ranked |
| `docs/02-planificacion/03_epicas/EPIC-06-TABLERO/` | Funcional | UI tablero, lobby, drag&drop, animaciones, chat |
| `docs/02-planificacion/03_epicas/EPIC-07-TIENDA/` | Funcional | Mercado Pago, sobres, wallet |
| `docs/02-planificacion/03_epicas/EPIC-08-BOT/` | Funcional | Bots EASY/MEDIUM/HARD + personalidades + chat-bot |
| `docs/02-planificacion/03_epicas/EPIC-09-SOCIAL/` | Funcional | Perfil, amigos, leaderboard, ligas, noticias |
| `docs/02-planificacion/03_epicas/EPIC-10-INFRA/` | Tecnica | Docker, Flyway, Nginx, MinIO, Redis, Prometheus, Grafana |
| `docs/02-planificacion/03_epicas/EPIC-11-CALIDAD/` | Tecnica | Tests unit/integration/E2E, Lighthouse, carga, cobertura |

#### Archivos antiguos (deprecados, mantienen redirect)

| Archivo | Reemplazo |
|---|---|
| `docs/02-planificacion/99_deprecados/INDEX.md` | -> `../01_backlog/BACKLOG.md` + `../02_sprints/SPRINTS.md` + `../01_backlog/PRODUCT_BACKLOG.md` |
| `docs/02-planificacion/99_deprecados/MULTI_EQUIPO.md` | -> `../04_proceso/EQUIPOS.md` |
| `docs/02-planificacion/99_deprecados/ANALISIS_DEPENDENCIAS.md` | -> `../04_proceso/DEPENDENCIAS_EPICAS.md` |
| `docs/02-planificacion/99_deprecados/CODEMON_CHECKLIST.md` | -> `../02_sprints/CHECKLIST_ENTREGA.md` + `../04_proceso/DOD.md` |
| `docs/02-planificacion/99_deprecados/EPICAS_USER_STORIES_README.md` | -> `../README.md` |

### 04-diseno-ui (era 04_disenio_ui)

| Archivo | Uso |
|---|---|
| `docs/04-diseno-ui/Codemon_Login.html` | Referencia visual de login |
| `docs/04-diseno-ui/Codemon_Launcher.html` | Referencia visual del launcher |
| `docs/04-diseno-ui/Codemon_Game_Lobby.html` | Referencia visual del lobby |
| `docs/04-diseno-ui/Codemon_Battle_Arena.html` | Referencia visual del tablero |

### 09-handoff (era 05_handoff)

| Archivo | Uso |
|---|---|
| `docs/09-handoff/README.md` | Guia para generar y leer documentos de handoff |
| `docs/09-handoff/CODEMON_HANDOFF_COMPLETO.md` | Handoff completo del proyecto |
| `docs/09-handoff/CODEMON_EQUIPO_A_BACKEND_CORE.md` | Handoff del Equipo A |
| `docs/09-handoff/CODEMON_EQUIPO_B_FRONTEND.md` | Handoff del Equipo B |
| `docs/09-handoff/CODEMON_EQUIPO_C_DEVOPS_BACKEND_AUX.md` | Handoff del Equipo C |
| `docs/09-handoff/CODEMON_CHECKLIST_EJECUTIVA.md` | Checklist ejecutiva de entrega |
| `docs/09-handoff/generar_pdfs.py` | Script de generacion de PDFs |

> Los PDFs de handoff se generan localmente desde los `.md` y quedan ignorados por `.gitignore`; no se listan como archivos versionados.

## docs/ (continuacion)

### 05-referencia-tecnica + 08-desarrollo-con-ia (era 00_contexto_global, split por audiencia)

| Archivo | Uso |
|---|---|
| `docs/08-desarrollo-con-ia/CONVENCIONES.md` | Convenciones obligatorias para cada paso |
| `docs/05-referencia-tecnica/MOCKS_FRONTEND.md` | Mocks y estrategia mock-first |

### 06-reglas-juego (era 01_reglas_juego)

| Archivo | Uso |
|---|---|
| `docs/06-reglas-juego/REGLAS_INDEX.md` | Mapa de reglas |
| `docs/06-reglas-juego/01-setup.md` | Setup de partida |
| `docs/06-reglas-juego/02-turn-flow.md` | Flujo de turno |
| `docs/06-reglas-juego/03-combat.md` | Combate y dano |
| `docs/06-reglas-juego/04-win-conditions.md` | Condiciones de victoria |
| `docs/06-reglas-juego/05-deck-validation.md` | Validacion de mazos |
| `docs/06-reglas-juego/06-system-logic.md` | Eventos y logica del sistema |

### 05-referencia-tecnica (era 02_referencia_tecnica)

| Archivo | Uso |
|---|---|
| `docs/05-referencia-tecnica/PATRONES_DISENO.md` | Patrones de diseno del sistema |
| `docs/05-referencia-tecnica/GAME_ENGINE_DETALLES.md` | Casos borde del motor |
| `docs/05-referencia-tecnica/CODEMON_GUIAS_TECNICAS.md` | Guias tecnicas por feature |
| `docs/05-referencia-tecnica/CARTAS_E_IMAGENES.md` | Estrategia de cartas e imagenes |
| `docs/05-referencia-tecnica/xy1.json` | Fuente real del seed XY1: 146 cartas |
| `docs/05-referencia-tecnica/MONITOREO.md` | Monitoreo y Grafana |
| `docs/05-referencia-tecnica/BD_Y_TABLAS.md` | Explicacion de BD |
| `docs/05-referencia-tecnica/CONTRATOS_API.md` | Contratos REST |
| `docs/05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md` | Contrato WebSocket |
| `docs/05-referencia-tecnica/SCHEMA_BD.sql` | Schema SQL completo |

### 07-infraestructura (era 03_infraestructura)

| Archivo | Uso |
|---|---|
| `docs/07-infraestructura/docker-compose.yml` | Orquestacion local/entrega |
| `docs/07-infraestructura/Dockerfile.api` | Imagen de la API |
| `docs/07-infraestructura/Dockerfile.front` | Imagen del frontend |
| `docs/07-infraestructura/.env.example` | Variables de entorno de ejemplo |
| `docs/07-infraestructura/nginx.conf` | Configuracion Nginx frontend |
| `docs/07-infraestructura/GATEWAY_LOCAL.md` | Guia APB del gateway local HTTP |
| `docs/07-infraestructura/GATEWAY_PRODUCCION_HTTPS.md` | Guia APB del gateway productivo HTTPS |
| `docs/07-infraestructura/prometheus.yml` | Configuracion Prometheus |
| `docs/07-infraestructura/grafana-datasource.yml` | Datasource de Grafana |

### 08-desarrollo-con-ia/pasos (era 04_pasos)

Todos los `PASO_*.md` siguen siendo guias tecnicas de implementacion. Cada Tarea Tecnica del backlog Scrum los referencia desde su `EPIC.md`.
La columna "Grupo legacy" conserva el vocabulario historico de los `PASO_*.md`; la lectura operativa actual se hace por sprint.

| Grupo legacy de PASOs | Archivos | Sprint(s) que lo absorbe |
|---|---|---|
| Grupo 0 legacy | `PASO_S00_01.md` a `PASO_S00_07.md` | S0 |
| Grupo 1 legacy | `PASO_S02_01.md` a `PASO_S02_03.md` | S2 |
| Grupo 1B legacy | `PASO_S01_02.md` a `PASO_S02_05.md` | S1, S2 |
| Grupo 2 legacy | `PASO_S03_01.md` a `PASO_S05_03.md` | S3, S4, S5 |
| Grupo 3 legacy | `PASO_S07_01.md` a `PASO_S05_04.md` | S5 (3_3 parcial), S7 |
| Grupo 3B legacy | `PASO_S06_01.md` | S6, S7 |
| Grupo 4 legacy | `PASO_S08_01.md` a `PASO_S08_05.md` | S8 |
| Grupo 4B legacy | `PASO_S08_06.md`, `PASO_S09_04.md` | S8, S9 |
| Grupo 5 legacy | `PASO_S09_01.md` a `PASO_S10_01.md` | S9, S10 |
| Grupo 5B legacy | `PASO_S09_05.md` a `PASO_S11_07.md` | S9, S10, S11 |
| Grupo 6 legacy | `PASO_S11_01.md` a `PASO_S11_05.md` | S11 |

## Entradas principales

| Necesidad | Archivo |
|---|---|
| Entender el proyecto como visitante | `README.md` |
| Empezar a trabajar en el proyecto | `CONTRIBUTING.md` |
| Navegar documentacion humana | `docs/INDICE.md` |
| Coordinar el sprint actual | `docs/02-planificacion/02_sprints/SPRINTS.md` y `BACKLOG.md` |
| Detallar una HU/TT | `docs/02-planificacion/03_epicas/EPIC-XX-NOMBRE/EPIC.md` |
| Trabajar con IA | `docs/08-desarrollo-con-ia/README.md` |
| Implementar un paso | `docs/08-desarrollo-con-ia/pasos/PASO_*.md` |
