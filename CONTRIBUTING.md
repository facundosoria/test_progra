# Guia para contribuir - Codemon TCG

Esta guia es para desarrolladores nuevos, integrantes que vuelven al proyecto despues de un tiempo o agentes de IA que necesitan recuperar contexto operativo. La presentacion publica vive en [README.md](README.md); el mapa completo de documentacion vive en [docs/INDICE.md](docs/INDICE.md).

---

## Antes de empezar

Codemon TCG es un juego de cartas coleccionables inspirado en Pokemon, con backend Spring Boot, frontend Angular 21+ con Tailwind CSS 3, WebSocket para partidas en tiempo real e infraestructura Docker.

El repositorio esta organizado para trabajar con 3 equipos humanos en modelo Scrum y con agentes de IA, sin mezclar documentacion, reglas, pasos e infraestructura.

Lectura recomendada:

1. Si eres nuevo, lee [docs/03-equipos/GUIA_PRIMER_DIA.md](docs/03-equipos/GUIA_PRIMER_DIA.md).
2. Revisa el mapa general en [docs/INDICE.md](docs/INDICE.md).
3. Conoce la metodologia, gates y artefactos Scrum desde [docs/02-planificacion/README.md](docs/02-planificacion/README.md).
4. Revisa el backlog priorizado en [docs/02-planificacion/01_backlog/PRODUCT_BACKLOG.md](docs/02-planificacion/01_backlog/PRODUCT_BACKLOG.md).
5. Consulta el plan de sprints en [docs/02-planificacion/02_sprints/SPRINTS.md](docs/02-planificacion/02_sprints/SPRINTS.md).
6. Lee la guia del equipo correspondiente en [docs/03-equipos/](docs/03-equipos/).
7. Usa los disenos de [docs/04-diseno-ui/](docs/04-diseno-ui/) como referencia visual.

## Rutas rapidas

| Tema | Documento |
|---|---|
| Primer dia de un desarrollador | [docs/03-equipos/GUIA_PRIMER_DIA.md](docs/03-equipos/GUIA_PRIMER_DIA.md) |
| Especificacion funcional del producto | [docs/01-producto/ESPECIFICACION_PRODUCTO.md](docs/01-producto/ESPECIFICACION_PRODUCTO.md) |
| Stack tecnologico explicado | [docs/01-producto/TECNOLOGIAS.md](docs/01-producto/TECNOLOGIAS.md) |
| Planificacion Scrum, sprints, HU, epicas y gates | [docs/02-planificacion/README.md](docs/02-planificacion/README.md) |
| Product Backlog | [docs/02-planificacion/01_backlog/PRODUCT_BACKLOG.md](docs/02-planificacion/01_backlog/PRODUCT_BACKLOG.md) |
| Plan de sprints | [docs/02-planificacion/02_sprints/SPRINTS.md](docs/02-planificacion/02_sprints/SPRINTS.md) |
| Guias por equipo | [docs/03-equipos/](docs/03-equipos/) |
| Contratos API | [docs/05-referencia-tecnica/CONTRATOS_API.md](docs/05-referencia-tecnica/CONTRATOS_API.md) |
| Gateway local y troubleshooting | [docs/07-infraestructura/GATEWAY_LOCAL.md](docs/07-infraestructura/GATEWAY_LOCAL.md) |
| Desarrollo con agentes de IA | [docs/08-desarrollo-con-ia/README.md](docs/08-desarrollo-con-ia/README.md) |

---

## Arranque rapido

```bash
# 1. Variables de entorno
cp .env.example .env
# Editar .env: completar MP_ACCESS_TOKEN, EMAIL_USERNAME, EMAIL_PASSWORD

# 2. Levantar el stack completo
docker compose up -d --build

# 3. Abrir la aplicacion
open http://localhost:8088
```

Si usas Colima en macOS:

```bash
docker --context colima compose up -d --build
```

URL unica de la aplicacion local: **http://localhost:8088**

Ver [docs/07-infraestructura/GATEWAY_LOCAL.md](docs/07-infraestructura/GATEWAY_LOCAL.md) para rutas, troubleshooting y modo debug.

---

## Servicios y verificacion

Verificar que todo esta en pie:

```bash
curl http://localhost:8088/actuator/health
curl http://localhost:8088/api/cards?size=3
open http://localhost:8088/swagger-ui.html
open http://localhost:3000
```

| Servicio | URL | Credenciales |
|---|---|---|
| Aplicacion (gateway) | http://localhost:8088 | - |
| Swagger UI | http://localhost:8088/swagger-ui.html | - |
| Produccion HTTPS | https://<dominio> | certificados externos |
| Grafana | http://localhost:3000 | admin / codemon123 |
| Prometheus | http://localhost:9090 | - |
| MinIO Console | http://localhost:9001 | codemon / codemon123 |
| PostgreSQL | localhost:5433 | codemon_user / codemon_pass |

El entorno local no usa TLS. Para deploy productivo, Nginx termina HTTPS en `443`, redirige `80 -> 443` y mantiene WebSocket seguro por `wss://<dominio>/ws`.

Guia de deploy: [docs/07-infraestructura/GATEWAY_PRODUCCION_HTTPS.md](docs/07-infraestructura/GATEWAY_PRODUCCION_HTTPS.md).

---

## Comandos esenciales

| Quiero... | Comando | Notas |
|---|---|---|
| Levantar todos los servicios | `docker compose up -d --build` | Corre el stack en segundo plano |
| Ver estado de servicios | `docker compose ps` | Buscar servicios `healthy` o `running` |
| Ver logs del API | `docker compose logs -f api` | Logs en tiempo real |
| Ver logs del frontend | `docker compose logs -f front` | Logs en tiempo real |
| Parar servicios | `docker compose stop` | Conserva datos |
| Bajar contenedores | `docker compose down` | Conserva volumenes |
| Resetear datos locales | `docker compose down -v` | Borra volumenes locales |
| Entrar a PostgreSQL | `docker exec -it codemon_postgres psql -U codemon_user -d codemon_db` | Consola interactiva |
| Tests backend | `./mvnw test` | Desde `api/` |
| Frontend dev server | `ng serve` | Desde `front/` |

Mas detalle para primer dia y problemas comunes: [docs/03-equipos/GUIA_PRIMER_DIA.md](docs/03-equipos/GUIA_PRIMER_DIA.md).

---

## Estructura del repositorio

```text
codemon/
├── api/                         Backend Spring Boot (Java 21)
│   ├── src/
│   ├── pom.xml
│   └── Dockerfile
│
├── front/                       Frontend Angular 21+
│   ├── src/
│   ├── package.json
│   ├── nginx.conf               Config interna del contenedor Angular
│   └── Dockerfile
│
├── infra/
│   └── monitoring/              Prometheus + Grafana
│       ├── prometheus.yml
│       └── grafana/provisioning/
│
├── docker-compose.yml           Stack completo local
├── docker-compose.prod.yml      Overlay productivo HTTPS
├── .env.example                 Plantilla de variables de entorno
├── .env.production.example      Plantilla de variables productivas
├── README.md                    Landing publica del proyecto
├── CONTRIBUTING.md              Guia para desarrolladores
├── scripts/                     Tooling: verify, trazabilidad y sync con GitHub
│
└── docs/                        Toda la documentacion del proyecto
    ├── INDICE.md                Mapa de lectura por audiencia
    ├── 01-producto/             README completo, tecnologias, estructura
    ├── 02-planificacion/        Sprints, backlog, epicas, gitflow, workflow
    ├── 03-equipos/              Guias Equipo A, B, C + primer dia
    ├── 04-diseno-ui/            Mockups HTML (tablero, lobby, login, launcher)
    ├── 05-referencia-tecnica/   Contratos API, schema BD, glosario, mocks
    ├── 06-reglas-juego/         Reglas XY1 completas
    ├── 07-infraestructura/      Dockerfiles de referencia, nginx, monitoreo
    ├── 08-desarrollo-con-ia/    Convenciones, pasos, trazabilidad, estado
    └── 09-handoff/              Documentos de handoff por equipo
```

---

## Documentacion clave

| Documento | Para que sirve |
|---|---|
| [README.md](README.md) | Landing publica del proyecto |
| [docs/INDICE.md](docs/INDICE.md) | Mapa completo de documentacion |
| [docs/03-equipos/GUIA_PRIMER_DIA.md](docs/03-equipos/GUIA_PRIMER_DIA.md) | Prerequisitos, levantar el proyecto y comandos esenciales |
| [docs/01-producto/ESPECIFICACION_PRODUCTO.md](docs/01-producto/ESPECIFICACION_PRODUCTO.md) | Especificacion funcional, features y requerimientos |
| [docs/01-producto/TECNOLOGIAS.md](docs/01-producto/TECNOLOGIAS.md) | Explicacion de tecnologias usadas |
| [docs/01-producto/ESTRUCTURA_PROYECTO.md](docs/01-producto/ESTRUCTURA_PROYECTO.md) | Estructura detallada de backend, frontend, infra y docs |
| [docs/02-planificacion/README.md](docs/02-planificacion/README.md) | Mapa general Scrum, epicas, sprints y gates |
| [docs/02-planificacion/00_guia/GITHUB_PROJECT_WORKFLOW.md](docs/02-planificacion/00_guia/GITHUB_PROJECT_WORKFLOW.md) | Issues, labels, story points, sprints y campos de GitHub Projects |
| [docs/02-planificacion/00_guia/GITFLOW.md](docs/02-planificacion/00_guia/GITFLOW.md) | Estrategia de ramas: main, develop, feature, release, hotfix |
| [docs/02-planificacion/00_guia/WORKFLOW_DIARIO.md](docs/02-planificacion/00_guia/WORKFLOW_DIARIO.md) | Ritual diario: fetch, rama, commits, PR y review |
| [docs/02-planificacion/01_backlog/PRODUCT_BACKLOG.md](docs/02-planificacion/01_backlog/PRODUCT_BACKLOG.md) | Historias de usuario priorizadas |
| [docs/02-planificacion/02_sprints/SPRINTS.md](docs/02-planificacion/02_sprints/SPRINTS.md) | Plan de 12 sprints, capacidad y gates de sincronizacion |
| [docs/03-equipos/GUIA_EQUIPO_A.md](docs/03-equipos/GUIA_EQUIPO_A.md) | Backend core: auth, cartas, mazos, motor de juego |
| [docs/03-equipos/GUIA_EQUIPO_B.md](docs/03-equipos/GUIA_EQUIPO_B.md) | Frontend Angular: UI, tablero, lobby, shop |
| [docs/03-equipos/GUIA_EQUIPO_C.md](docs/03-equipos/GUIA_EQUIPO_C.md) | DevOps + backend auxiliar: matchmaking, pagos, monitoreo |
| [docs/05-referencia-tecnica/CONTRATOS_API.md](docs/05-referencia-tecnica/CONTRATOS_API.md) | Endpoints REST con ejemplos |
| [docs/05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md](docs/05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md) | Eventos STOMP |
| [docs/05-referencia-tecnica/SCHEMA_BD.sql](docs/05-referencia-tecnica/SCHEMA_BD.sql) | Schema SQL completo |
| [docs/05-referencia-tecnica/GAME_ENGINE_DETALLES.md](docs/05-referencia-tecnica/GAME_ENGINE_DETALLES.md) | Motor de juego, reglas, dano, condiciones especiales y bot |
| [docs/07-infraestructura/GATEWAY_LOCAL.md](docs/07-infraestructura/GATEWAY_LOCAL.md) | Rutas, troubleshooting y debug local |

---

## Equipos de trabajo

| Equipo | Foco | Guia |
|---|---|---|
| Equipo A - Backend Core | Auth, cartas, mazos, motor de juego y WebSocket | [docs/03-equipos/GUIA_EQUIPO_A.md](docs/03-equipos/GUIA_EQUIPO_A.md) |
| Equipo B - Frontend | Angular UI, tablero, lobby, shop y E2E | [docs/03-equipos/GUIA_EQUIPO_B.md](docs/03-equipos/GUIA_EQUIPO_B.md) |
| Equipo C - DevOps + Backend Aux | Docker, matchmaking, pagos, ranking y monitoreo | [docs/03-equipos/GUIA_EQUIPO_C.md](docs/03-equipos/GUIA_EQUIPO_C.md) |

La fuente canonica de estructura, capacity, asignacion por sprint y gates entre equipos es [docs/02-planificacion/04_proceso/EQUIPOS.md](docs/02-planificacion/04_proceso/EQUIPOS.md).

---

## Metodologia y planificacion

El proyecto sigue Scrum con sprints semanales, 3 equipos en paralelo y gates de sincronizacion. La implementacion tambien esta guiada por pasos discretos en `docs/08-desarrollo-con-ia/pasos/`, con trazabilidad hacia historias de usuario y epicas.

Fuentes canonicas:

- Planificacion Scrum: [docs/02-planificacion/README.md](docs/02-planificacion/README.md)
- Product Backlog: [docs/02-planificacion/01_backlog/PRODUCT_BACKLOG.md](docs/02-planificacion/01_backlog/PRODUCT_BACKLOG.md)
- Plan de sprints: [docs/02-planificacion/02_sprints/SPRINTS.md](docs/02-planificacion/02_sprints/SPRINTS.md)
- Dependencias y gates: [docs/02-planificacion/04_proceso/DEPENDENCIAS_EPICAS.md](docs/02-planificacion/04_proceso/DEPENDENCIAS_EPICAS.md)
- Definition of Done: [docs/02-planificacion/04_proceso/DOD.md](docs/02-planificacion/04_proceso/DOD.md)
- Workflow diario: [docs/02-planificacion/00_guia/WORKFLOW_DIARIO.md](docs/02-planificacion/00_guia/WORKFLOW_DIARIO.md)
- GitFlow: [docs/02-planificacion/00_guia/GITFLOW.md](docs/02-planificacion/00_guia/GITFLOW.md)

---

## Desarrollo con IA

Para construir o continuar el proyecto con agentes de IA, entrar a [docs/08-desarrollo-con-ia/README.md](docs/08-desarrollo-con-ia/README.md).

Ese documento explica que cargar antes de cada sesion, como usar los `PASO_*.md`, donde estan los `context_files` y que verificar antes de avanzar al siguiente paso.

Para continuidad entre companeros y agentes:

- [docs/08-desarrollo-con-ia/ESTADO_PASOS.md](docs/08-desarrollo-con-ia/ESTADO_PASOS.md) muestra estado actual, avance, bloqueos y proxima accion.
- [docs/08-desarrollo-con-ia/HISTORIAL_PASOS.md](docs/08-desarrollo-con-ia/HISTORIAL_PASOS.md) conserva la bitacora de cambios de estado, pausas, checks y handoffs.
- [docs/08-desarrollo-con-ia/TRAZABILIDAD_PASOS_HU.yml](docs/08-desarrollo-con-ia/TRAZABILIDAD_PASOS_HU.yml) es la fuente de verdad Paso -> HU/TT -> Epica -> GitHub Project.
- [docs/08-desarrollo-con-ia/TRAZABILIDAD_PASOS_HU.md](docs/08-desarrollo-con-ia/TRAZABILIDAD_PASOS_HU.md) es la vista humana de esa trazabilidad.

---

## Troubleshooting

| Problema | Donde mirar |
|---|---|
| El stack no levanta | `docker compose ps` y `docker compose logs -f <servicio>` |
| La API responde `DOWN` | Logs de `api` y `postgres` |
| El frontend no carga en `8088` | Logs de `front` y guia [GATEWAY_LOCAL.md](docs/07-infraestructura/GATEWAY_LOCAL.md) |
| Puerto ocupado | Revisar procesos locales usando el puerto |
| Error con dependencias frontend | Ejecutar `npm install` desde `front/` |
| Error de Flyway/checksum | Ver guia de primer dia antes de resetear volumenes |

Referencias completas:

- [docs/03-equipos/GUIA_PRIMER_DIA.md](docs/03-equipos/GUIA_PRIMER_DIA.md)
- [docs/07-infraestructura/GATEWAY_LOCAL.md](docs/07-infraestructura/GATEWAY_LOCAL.md)
