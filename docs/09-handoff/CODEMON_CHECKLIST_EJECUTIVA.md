# Codemon TCG - Checklist ejecutiva de handoff

Version: 1.0  
Fecha: 2026-05-19
Audiencia: project manager, docente, lider tecnico

## 1. Lectura rapida

El proyecto es un handoff de implementacion, no una aplicacion terminada. Esta preparado para ejecutarse con tres equipos y agentes de IA, usando pasos acotados y gates de sincronizacion.

Distribucion estimada:

| Equipo | Cobertura | Foco |
|---|---|---|
| A | 42% | Backend core, motor, WebSocket. |
| B | 30% | Frontend Angular + Tailwind CSS y E2E. |
| C | 28% | DevOps, backend auxiliar e integraciones. |

## 2. Checklist de preparacion

| Item | Estado |
|---|---|
| `CONTRIBUTING.md` explica como entrar y trabajar en el proyecto | Pendiente/OK |
| `docs/08-desarrollo-con-ia/README.md` explica carga acotada para IA | Pendiente/OK |
| `docs/02-planificacion/README.md` es fuente canonica de navegacion | Pendiente/OK |
| `docs/02-planificacion/01_backlog/PRODUCT_BACKLOG.md` refleja alcance priorizado | Pendiente/OK |
| `docs/02-planificacion/02_sprints/SPRINTS.md` refleja plan sprint a sprint | Pendiente/OK |
| `docs/02-planificacion/00_guia/GITHUB_PROJECT_WORKFLOW.md` explica GitHub Projects, issues, labels, SP y sprints | Pendiente/OK |
| Los pasos existen en `docs/08-desarrollo-con-ia/pasos/` | Pendiente/OK |
| `xy1.json` existe en `docs/05-referencia-tecnica/` | Pendiente/OK |
| El flujo de imagenes usa MinIO + URLs en PostgreSQL | Pendiente/OK |
| No se usa almacenamiento binario de imagenes en PostgreSQL como estrategia activa | Pendiente/OK |

## 3. Gates ejecutivos

| Gate | Estado | Responsable | Criterio de aceptacion |
|---|---|---|---|
| GATE 0 | Abierto/Bloqueado/OK | A+B+C | Infra, proyectos base, contratos y mocks. |
| GATE 1a | Abierto/Bloqueado/OK | A -> B | Auth/JWT real. |
| GATE 1b | Abierto/Bloqueado/OK | A -> B | Cartas y mazos reales. |
| GATE 2 | Abierto/Bloqueado/OK | A -> B/C | GameEngine + WebSocket. |
| GATE 3 | Abierto/Bloqueado/OK | C -> B | Salas privadas. |
| GATE 4 | Abierto/Bloqueado/OK | C -> B | Matchmaking ranked. |
| GATE 5 | Abierto/Bloqueado/OK | C -> B | Mercado Pago + sobres + wallet/tienda. |
| GATE 6 | Abierto/Bloqueado/OK | C -> B | Leaderboard + ligas + amigos + noticias. |
| GATE 7 | Abierto/Bloqueado/OK | C -> B | OAuth2 + perfil consolidado. |
| GATE 8 | Abierto/Bloqueado/OK | A+B+C | Carga + Playwright + Lighthouse + entrega final. |

## 4. Riesgos principales

| Riesgo | Mitigacion |
|---|---|
| El motor de juego se subestima | `EPIC-04` / S3-S5 se ejecuta secuencialmente con lectura previa de reglas. |
| Frontend se acopla a mocks incorrectos | B usa `CONTRATOS_API.md` y valida gates antes de integrar. |
| Imagenes se guardan mal | Seed canonico: `xy1.json` -> `cards.json` -> descarga externa -> MinIO -> URLs en DB. |
| Pagos duplican efectos | C valida webhooks idempotentes. |
| Los agentes amplian scope | Cada prompt exige un solo `PASO`, `CONVENCIONES.md`, `context_files` y verificacion. |

## 5. Evidencia minima por gate

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

## 6. Cierre de paso obligatorio

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

## 7. Cadencia recomendada

| Reunicion | Duracion | Objetivo |
|---|---|---|
| Kickoff | 45 min | Alinear roles, repo, gates y protocolo IA. |
| Daily | 15 min | Gate actual, bloqueos y siguiente paso. |
| Revision de gate | 20 min | Evidencia, deuda y desbloqueo formal. |
| Cierre final | 60 min | Checklist completa, demo y riesgos residuales. |

## 8. Criterio final de aceptacion

El proyecto puede entregarse como handoff si:

- Cada equipo puede preparar su entorno y arrancar su primer paso sin preguntar.
- Las peticiones a IA siempre incluyen `PASO`, `CONVENCIONES.md`, `context_files` y verificacion.
- Todos los pasos referenciados existen.
- La estrategia de imagenes esta clara y no contradice la base de datos.
- La checklist permite saber que gate esta abierto, bloqueado o completado.
