# Codemon TCG - Handoff completo

Version: 1.0  
Fecha: 2026-05-19
Destino: equipos A, B y C de implementacion  
Objetivo: permitir que un programador reciba el proyecto, prepare su entorno, use un agente de IA con scope controlado y valide cada entrega antes de avanzar.

## 1. Como leer este paquete

1. Abrir `CONTRIBUTING.md` para entender la organizacion general y el arranque operativo.
2. Leer este manual durante los primeros 15 minutos del handoff.
3. Abrir el anexo del equipo correspondiente.
4. Para implementar, usar `docs/08-desarrollo-con-ia/README.md` y cargar un solo `PASO_*.md` por sesion.

Toda la documentacion vive bajo `docs/`, organizada por tema:

| Carpeta | Uso |
|---|---|
| `docs/01-producto/` | Que se construye, tecnologias y estructura del proyecto. |
| `docs/02-planificacion/` | Artefactos Scrum: backlog, sprints, epicas, equipos, dependencias, gitflow y workflow diario. |
| `docs/03-equipos/` | Guias de Equipo A, B, C + guia del primer dia. |
| `docs/04-diseno-ui/` | Mockups HTML de referencia visual. |
| `docs/05-referencia-tecnica/` | Contratos API, schema BD, glosario canonico, mocks, protocolo WebSocket, patrones. |
| `docs/06-reglas-juego/` | Reglas XY1 completas (7 archivos). |
| `docs/07-infraestructura/` | Dockerfiles de referencia, gateway local, nginx, monitoreo. |
| `docs/08-desarrollo-con-ia/` | Convenciones, sistema de PASOS, estado, historial, trazabilidad — workflow operativo con agentes de IA. |
| `docs/09-handoff/` | Handoff, checklist ejecutivo y documentos de entrega (esta carpeta). |

La fuente canonica de navegacion del plan es `docs/02-planificacion/README.md`. Para priorizacion y alcance se usan `docs/02-planificacion/01_backlog/PRODUCT_BACKLOG.md`, `docs/02-planificacion/01_backlog/BACKLOG.md` y `docs/02-planificacion/02_sprints/SPRINTS.md`. Para el detalle de cada HU, gana el `EPIC.md` correspondiente en `docs/02-planificacion/03_epicas/`.

## 2. Estado esperado del handoff

Este paquete no entrega una aplicacion terminada. Entrega un plan de implementacion ejecutable, dividido en pasos pequenos, con contexto tecnico suficiente para que equipos humanos y agentes de IA trabajen sin cargar todo el repositorio.

Estado de preparacion estimado:

| Area | Estado |
|---|---|
| Plan multi-equipo | Listo para ejecutar. |
| Pasos de agente | Listos y ubicados en `docs/08-desarrollo-con-ia/pasos/`. |
| Contexto tecnico | Listo en `docs/05-referencia-tecnica/`. |
| JSON de cartas XY1 | Listo en `docs/05-referencia-tecnica/xy1.json`. |
| Implementacion final | Pendiente. Debe ejecutarse paso a paso. |

## 3. Equipos y cobertura

`PASO_S00_01` es compartido. El porcentaje indica carga aproximada de trabajo del proyecto base.

| Equipo | Foco | Cobertura |
|---|---|---|
| Equipo A - Backend Core | Auth, catalogo, mazos, motor de juego, WebSocket | 42% |
| Equipo B - Frontend Angular + Tailwind CSS | UI, mocks, deck builder, tablero, lobby, shop, perfil, E2E | 30% |
| Equipo C - DevOps y Backend Auxiliar | Docker, Redis, matchmaking, pagos, leaderboard, noticias, OAuth2, Grafana | 28% |

## 4. Setup comun obligatorio

Cada maquina debe tener preinstalado:

| Herramienta | Uso |
|---|---|
| Java 21 | API Spring Boot. |
| Maven 3 | Build, tests y ejecucion backend. |
| Node.js 20 o superior | Frontend Angular y tooling (incluye instalar Tailwind CSS 3 vía `npm`). |
| Angular CLI | Desarrollo y build del frontend (Tailwind se integra en `src/styles.scss` y `tailwind.config.js`). |
| Docker Desktop | PostgreSQL, Redis, MinIO, Prometheus y Grafana. |
| Git | Branches, commits, sincronizacion. |
| Cliente PostgreSQL opcional | Debug de datos y queries. |

Carpeta local esperada: `~/codemon/`.

Servicios Docker esperados: PostgreSQL, Redis, MinIO, Prometheus y Grafana. Las variables se toman desde `docs/07-infraestructura/.env.example`.

Comandos base:

```bash
docker compose up postgres redis minio minio_setup prometheus grafana -d
cd ~/codemon/api && ./mvnw test
cd ~/codemon/front && ng build
```

## 5. Protocolo obligatorio de IA

El agente no debe recibir todo el proyecto. Debe recibir contexto acotado.

1. Cargar siempre `docs/08-desarrollo-con-ia/CONVENCIONES.md`.
2. Elegir un solo archivo `docs/08-desarrollo-con-ia/pasos/PASO_X.md`.
3. Leer el YAML del paso.
4. Resolver `context_files` usando `docs/08-desarrollo-con-ia/README.md`.
5. Implementar solo el alcance del paso.
6. Ejecutar la verificacion indicada en el paso.
7. Informar archivos modificados, comandos corridos, resultado, tests y bloqueos.

Prompt base:

```text
Sos el agente de implementacion del proyecto Codemon TCG.
Carga CONVENCIONES.md.
Voy a implementar PASO_X.
Lee el YAML del paso, carga solo sus context_files usando COMO_USAR.md.
Implementa unicamente este paso.
Ejecuta la verificacion del paso.
Informa archivos modificados, tests corridos, resultado y bloqueo si existe.
```

## 6. Orden macro Scrum de implementacion

| Tramo | Objetivo | Equipos |
|---|---|---|
| S0 | Contratos, herramientas, Docker, Spring Boot, Angular y Flyway | A, B, C |
| S1-S2 | Auth basica, catalogo, mazos y UI base | A, B |
| S3-S5 | Motor, WebSocket y primera partida PvE jugable | A, B |
| S6-S8 | Tablero pulido, PvP, tienda, metricas, coleccion y 2FA | A, B, C |
| S9-S11 | Social, OAuth2, bots avanzados, responsive, E2E y cierre | A, B, C |

## 7. Gates de sincronizacion

| Gate | Entrega | Espera | Criterio |
|---|---|---|---|
| GATE 0 | Todos | Todos | Infra, proyectos base, contratos y mocks listos. |
| GATE 1a | A | B | Auth/JWT real disponible. |
| GATE 1b | A | B | Cartas y mazos reales disponibles. |
| GATE 2 | A | B y C | GameEngine + WebSocket STOMP completo. |
| GATE 3 | C | B | Salas privadas reales disponibles. |
| GATE 4 | C | B | Matchmaking ranked real disponible. |
| GATE 5 | C | B | Mercado Pago sandbox + sobres + wallet/tienda listos. |
| GATE 6 | C | B | Leaderboard + ligas + amigos + noticias reales disponibles. |
| GATE 7 | C | B | OAuth2 + perfil consolidado disponibles. |
| GATE 8 | Todos | Todos | Carga + Playwright + Lighthouse + cierre final OK. |

## 8. Flujo canonico de cartas e imagenes

La estrategia definitiva es MinIO + URLs publicas. No se guardan imagenes binarias en PostgreSQL como estrategia activa.

1. Fuente: `docs/05-referencia-tecnica/xy1.json`.
2. El set XY1 contiene 146 cartas.
3. Cada carta trae `images.small` e `images.large` con URLs externas de `images.pokemontcg.io`.
4. En setup se copia `xy1.json` como `api/src/main/resources/seed/cards.json`.
5. El seed descarga cada imagen externa una sola vez.
6. El seed sube imagenes a MinIO.
7. PostgreSQL guarda `image_small_url` e `image_large_url` en `cards_catalog` con el prefijo del gateway: `http://localhost:8088/minio/codemon-cards/...` (nunca `localhost:9000` directo, MinIO no está expuesto públicamente).

Este flujo reemplaza cualquier estrategia historica basada en almacenamiento binario de imagenes dentro de PostgreSQL.

## 9. Ritmo de trabajo recomendado

| Momento | Accion |
|---|---|
| Inicio del dia | Revisar sprint, gates, bloqueos y branch actual. |
| Antes de implementar | Confirmar `PASO_X`, context_files y verificacion. |
| Durante el paso | No mezclar pasos. No ampliar scope sin registrar deuda. |
| Cierre del paso | Completar plantilla de cierre y ejecutar verificacion. |
| Handoff | Avisar gate, pasos completados, comandos y riesgos. |

Plantilla de handoff:

```text
Gate:
Equipo que entrega:
Equipo que espera:
Pasos completados:
Comandos de verificacion:
Resultado esperado:
Riesgos o deuda:
Proximo paso desbloqueado:
```

Plantilla de cierre de paso:

```text
Paso:
Context files usados:
Archivos creados/modificados:
Comandos ejecutados:
Resultado:
Tests:
Pendientes:
Puede avanzar al siguiente paso: Si/No
```

## 10. Criterio de aceptacion del handoff

El handoff esta en condiciones cuando:

- Un equipo puede arrancar su primer paso sin pedir contexto adicional.
- El backlog, el plan de sprints y las epicas apuntan a la estructura actual de `docs/02-planificacion/`.
- Cada paso referenciado existe en `docs/08-desarrollo-con-ia/pasos/`.
- Toda peticion a IA indica `PASO`, `CONVENCIONES.md`, `context_files` y verificacion.
- El flujo de imagenes queda claro: `xy1.json` -> `seed/cards.json` -> descarga externa una vez -> MinIO -> PostgreSQL guarda URLs.
- La checklist ejecutiva permite saber que gate esta abierto, bloqueado o completado.
- No quedan referencias operativas a nombres, conteos o modelos de imagenes historicos como fuente canonica.
