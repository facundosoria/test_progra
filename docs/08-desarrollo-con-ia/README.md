# Como Usar Esta Carpeta con IA

Esta carpeta contiene el material que un agente de IA necesita para implementar Codemon TCG paso a paso. No cargues todo el proyecto a la vez: cada `PASO_*.md` indica sus `context_files` obligatorios.

## Doctrina

Los `PASO_*.md` describen **qué construir**, no **cómo escribirlo línea por línea**. El agente tiene libertad para implementar siempre que respete los contratos declarados (firmas, nombres, endpoints, eventos WebSocket). Ver detalle en [CONVENCIONES.md](CONVENCIONES.md) sección "Doctrina: instrucciones precisas, NO código servido".

## Flujo por sesion

1. **Cargar siempre cuatro archivos base**:
   - [CONVENCIONES.md](CONVENCIONES.md) — convenciones técnicas globales y doctrina.
   - [../05-referencia-tecnica/GLOSARIO.md](../05-referencia-tecnica/GLOSARIO.md) — nombres canónicos de entidades, paquetes, DTOs y eventos. Sin esto, dos agentes pueden generar código incompatible.
   - [ESTADO_PASOS.md](ESTADO_PASOS.md) — tablero operativo de avance, handoff, bloqueos y proxima accion por PASO.
   - [HISTORIAL_PASOS.md](HISTORIAL_PASOS.md) — bitacora cronologica de cambios de estado, pausas, checks y handoffs.
   - [TRAZABILIDAD_PASOS_HU.yml](TRAZABILIDAD_PASOS_HU.yml) — fuente normativa Paso -> HU/TT -> Epica -> GitHub Project.
2. Revisar [TRAZABILIDAD_PASOS_HU.md](TRAZABILIDAD_PASOS_HU.md) para confirmar que HU/TT y epica cumple el PASO.
3. Revisar [ESTADO_PASOS.md](ESTADO_PASOS.md) para decidir si el PASO esta `READY`, `IN_PROGRESS`, `PAUSED`, `BLOCKED` o `DONE`.
4. Elegir un archivo de [pasos/](pasos/) según el orden de [../02-planificacion/01_backlog/BACKLOG.md](../02-planificacion/01_backlog/BACKLOG.md) y el estado real del tablero.
5. Leer el bloque YAML del paso y ubicar sus `context_files` usando la tabla de mapeo abajo.
6. Cargar solo esos archivos de contexto, no toda la documentación.
7. **Respetar los contratos** del PASO (sección "Contratos a respetar"). NO inventar nombres alternativos: usar los del GLOSARIO.
8. Implementar exactamente el alcance del paso.
9. Ejecutar `./verify_paso.sh PASO_X_Y` para correr los checks declarados.
10. Recorrer la sección "Definition of Done" del paso. No marcar como completo si algún check falla.
11. Si el paso desbloquea a otro equipo, completar la sección "Entrega al siguiente paso" del paso.
12. Antes de cerrar la sesion, actualizar [ESTADO_PASOS.md](ESTADO_PASOS.md) con estado, avance, commit/rama, checks, bloqueos y proxima accion.
13. Registrar el cambio en [HISTORIAL_PASOS.md](HISTORIAL_PASOS.md) cuando el paso cambie de estado, se pause, se bloquee, se verifique o se marque `DONE`.
14. Para cierre automatizado local/GitHub, usar `scripts/agent-complete-paso.sh PASO_X_Y`.

## Estructura estándar de un PASO

Cada nuevo PASO debe seguir [PASO_TEMPLATE.md](pasos/PASO_TEMPLATE.md). Las secciones obligatorias son:

| Sección | Propósito |
|---|---|
| YAML frontmatter | id, equipo, bloque, dep, siguiente, context_files (incluye `GLOSARIO.md` y `CONVENCIONES.md`), outputs |
| Navegación | Links a anterior y siguiente |
| Qué construye este paso | Outcome en lenguaje natural (no implementación) |
| Prerrequisitos | Qué debe estar listo antes |
| **Contratos a respetar** | Endpoints, clases, DTOs, eventos — los nombres exactos que NO se pueden cambiar |
| Instrucciones para el agente | Qué hacer, en imperativo. Pseudocódigo OK. NO bloques de código completos. |
| Casos borde / errores comunes | Tabla síntoma → causa → solución |
| Tests obligatorios | Lista de tests por NOMBRE (no su código) |
| **Verificación automatizada** | Comandos bash con exit code interpretable, parseable por `verify_paso.sh` |
| **Entrega al siguiente paso** | Lo que el siguiente PASO puede asumir |
| **Definition of Done** | Checklist final |

## Trazabilidad Paso -> HU/TT -> Epica

La trazabilidad evita que un agente cierre una HU por intuicion. La fuente de verdad es [TRAZABILIDAD_PASOS_HU.yml](TRAZABILIDAD_PASOS_HU.yml); la vista humana se genera en [TRAZABILIDAD_PASOS_HU.md](TRAZABILIDAD_PASOS_HU.md).

Reglas operativas:

- Todo `PASO_*.md` debe tener al menos una relacion en el YAML.
- Una HU/TT puede depender de varios pasos requeridos.
- Un paso puede aportar a varias HU/TT.
- Una HU/TT solo puede pasar a `Done` si todos sus pasos con `required_for_hu_done: true` estan `DONE`.
- Los smoke tests y gates pueden figurar como `sin HU directa`: validan integracion, pero no cierran HU por si solos.
- GitHub Projects solo se actualiza cuando la relacion tiene `hu_issue_number` y `github_sync: true`.

Comandos:

```bash
scripts/generate-traceability-docs.sh
scripts/validate-traceability.sh
scripts/sync-traceability-github.sh --dry-run
scripts/agent-complete-paso.sh PASO_S01_01 --dry-run
scripts/agent-complete-paso.sh PASO_S01_01
```

## Política de idioma para implementación

- Los archivos `.md` de `docs/` (todas las subcarpetas) se escriben en español.
- Toda implementación debe estar en inglés: código, comentarios, logs, errores, tests, mocks, fixtures, datos seed visibles al usuario y UI visible.
- Los snippets, contratos, payloads de ejemplo y strings runtime incluidos dentro de `.md` deben usar inglés, aunque la explicación que los rodea esté en español.
- Los HTML de [../04-diseno-ui/](../04-diseno-ui/) son referencia de UI y sus textos visibles también deben estar en inglés.

## Smoke tests por sprint

Al terminar cada sprint (o grupo de sprints), correr el smoke test correspondiente antes de avanzar:

| Sprint(s) | Smoke | Gate |
|---|---|---|
| S0 | [PASO_S00_SMOKE.md](pasos/PASO_S00_SMOKE.md) | GATE 0 — infra completa |
| S1 + S2 | [PASO_S02_SMOKE.md](pasos/PASO_S02_SMOKE.md) | GATE 1a/1b — auth + cartas + mazos end-to-end |
| S3 + S4 + S5 | [PASO_S05_SMOKE.md](pasos/PASO_S05_SMOKE.md) | GATE 2 — motor de juego completo |
| S5 + S6 + S7 | [PASO_S07_SMOKE.md](pasos/PASO_S07_SMOKE.md) | GATE 3/4 — salas privadas + matchmaking + tablero PvP |
| S8 | [PASO_S08_SMOKE.md](pasos/PASO_S08_SMOKE.md) | GATE 5 — Mercado Pago + sobres + wallet/tienda |
| S9 + S10 | [PASO_S10_SMOKE.md](pasos/PASO_S10_SMOKE.md) | GATE 6/7 — social + OAuth + perfil |
| S11 | [CHECKLIST_ENTREGA.md](../02-planificacion/02_sprints/CHECKLIST_ENTREGA.md) | GATE 8 — carga + Playwright + Lighthouse |

## Mapeo de context_files

Las rutas de esta tabla están pensadas desde un archivo dentro de `pasos/`.

| Nombre en `context_files:` | Ruta nueva |
|---|---|
| `GLOSARIO.md` | `../05-referencia-tecnica/GLOSARIO.md` |
| `CONVENCIONES.md` | `../CONVENCIONES.md` |
| `MOCKS_FRONTEND.md` | `../05-referencia-tecnica/MOCKS_FRONTEND.md` |
| `REGLAS_INDEX.md` | `../06-reglas-juego/REGLAS_INDEX.md` |
| `01-setup.md` | `../06-reglas-juego/01-setup.md` |
| `02-turn-flow.md` | `../06-reglas-juego/02-turn-flow.md` |
| `03-combat.md` | `../06-reglas-juego/03-combat.md` |
| `04-win-conditions.md` | `../06-reglas-juego/04-win-conditions.md` |
| `05-deck-validation.md` | `../06-reglas-juego/05-deck-validation.md` |
| `06-system-logic.md` | `../06-reglas-juego/06-system-logic.md` |
| `PATRONES_DISENO.md` | `../05-referencia-tecnica/PATRONES_DISENO.md` |
| `PATRONES_REDIS.md` | `../05-referencia-tecnica/PATRONES_REDIS.md` |
| `GAME_ENGINE_DETALLES.md` | `../05-referencia-tecnica/GAME_ENGINE_DETALLES.md` |
| `CODEMON_GUIAS_TECNICAS.md` | `../05-referencia-tecnica/CODEMON_GUIAS_TECNICAS.md` |
| `CARTAS_E_IMAGENES.md` | `../05-referencia-tecnica/CARTAS_E_IMAGENES.md` |
| `xy1.json` | `../05-referencia-tecnica/xy1.json` |
| `ESPECIFICACION_PRODUCTO.md` | `../../01-producto/ESPECIFICACION_PRODUCTO.md` |
| `ESTRUCTURA_PROYECTO.md` | `../../01-producto/ESTRUCTURA_PROYECTO.md` |
| `Codemon_Login.html` | `../../04-diseno-ui/Codemon_Login.html` |
| `Codemon_Launcher.html` | `../../04-diseno-ui/Codemon_Launcher.html` |
| `Codemon_Game_Lobby.html` | `../../04-diseno-ui/Codemon_Game_Lobby.html` |
| `Codemon_Battle_Arena.html` | `../../04-diseno-ui/Codemon_Battle_Arena.html` |
| `MONITOREO.md` | `../05-referencia-tecnica/MONITOREO.md` |
| `BD_Y_TABLAS.md` | `../05-referencia-tecnica/BD_Y_TABLAS.md` |
| `CONTRATOS_API.md` | `../05-referencia-tecnica/CONTRATOS_API.md` |
| `PROTOCOLO_WEBSOCKET.md` | `../05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md` |
| `SCHEMA_BD.sql` | `../05-referencia-tecnica/SCHEMA_BD.sql` |
| `.env.example` | `../07-infraestructura/.env.example` |
| `docker-compose.yml` | `../07-infraestructura/docker-compose.yml` |
| `docker-compose.prod.yml` | `../../docker-compose.prod.yml` |
| `Dockerfile.api` | `../07-infraestructura/Dockerfile.api` |
| `Dockerfile.front` | `../07-infraestructura/Dockerfile.front` |
| `nginx.conf` | `../07-infraestructura/nginx.conf` |
| `nginx.prod.conf` | `../../front/nginx.prod.conf` |
| `GATEWAY_LOCAL.md` | `../07-infraestructura/GATEWAY_LOCAL.md` |
| `GATEWAY_PRODUCCION_HTTPS.md` | `../07-infraestructura/GATEWAY_PRODUCCION_HTTPS.md` |
| `.env.production.example` | `../../.env.production.example` |
| `prometheus.yml` | `../07-infraestructura/prometheus.yml` |
| `grafana-datasource.yml` | `../07-infraestructura/grafana-datasource.yml` |

## Verificación automatizada — verify_paso.sh

Para cada PASO existe un script unificado que ejecuta los checks declarados:

```bash
# Desde la raiz del repo
./scripts/verify_paso.sh PASO_S01_01          # ejecuta los checks
./scripts/verify_paso.sh PASO_S01_01 --dry-run # solo lista los comandos
./scripts/verify_paso.sh --list             # lista todos los pasos disponibles
```

El script lee la sección `## Verificación automatizada` del PASO_*.md y ejecuta cada línea bash. Cada línea debe terminar con un comando que devuelva exit 0 (PASS) o exit ≠ 0 (FAIL). Comentarios inline (`# PASS si: ...`) se ignoran al ejecutar pero documentan el resultado esperado.

## Prompt de ejemplo

```text
Sos el agente de implementación del proyecto Codemon TCG.

Cargá primero estos cuatro archivos sin excepción:
- docs/08-desarrollo-con-ia/CONVENCIONES.md
- docs/05-referencia-tecnica/GLOSARIO.md
- docs/08-desarrollo-con-ia/ESTADO_PASOS.md
- docs/08-desarrollo-con-ia/HISTORIAL_PASOS.md

Voy a implementar docs/08-desarrollo-con-ia/pasos/PASO_S04_01.md. Leé su YAML, identificá los
context_files y cargalos desde las rutas indicadas en docs/08-desarrollo-con-ia/README.md.

Reglas de implementación:
1. Respetar los contratos declarados en la sección "Contratos a respetar" del PASO.
2. Usar los nombres canónicos del GLOSARIO (entidades, paquetes, DTOs, eventos).
3. NO copiar código de otros lugares: el código debe nacer de las instrucciones del PASO.
4. Implementar SOLO el alcance del PASO_S04_01; no tocar archivos fuera de su sección outputs.
5. Antes de declarar terminado: ejecutar ./verify_paso.sh PASO_S04_01 y revisar la
   "Definition of Done" del paso. Reportar cualquier check que falle.
6. Antes de cerrar la sesión: actualizar docs/08-desarrollo-con-ia/ESTADO_PASOS.md con el estado real
   del paso, checks ejecutados, bloqueos y próxima acción.
7. Registrar en docs/08-desarrollo-con-ia/HISTORIAL_PASOS.md el cambio realizado, incluso si el paso
   queda pausado o bloqueado.
8. Asegurar que todo código, comentario, log, error, test, dato runtime y texto visible de UI
   generado por el paso esté en inglés.
```

## Criterio antes de pasar al siguiente paso

- `./verify_paso.sh PASO_X_Y` retorna exit 0 (todos los checks PASS).
- Todos los archivos de la sección `outputs:` existen.
- La sección "Definition of Done" del PASO está completa.
- La sección "Entrega al siguiente paso" refleja el estado real (endpoints, beans, datos disponibles).
- Los contratos usados coinciden con [GLOSARIO.md](../05-referencia-tecnica/GLOSARIO.md), [CONTRATOS_API.md](../05-referencia-tecnica/CONTRATOS_API.md) y [PROTOCOLO_WEBSOCKET.md](../05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md).
- Si el paso cierra un sprint o gate, el smoke/checklist correspondiente pasa.
- `ESTADO_PASOS.md` queda actualizado con estado actual, avance y proxima accion.
- `HISTORIAL_PASOS.md` contiene una entrada con checks ejecutados y resultado.
- Todo código, comentario, log, error, test, dato runtime y texto visible de UI queda en inglés.

## Coordinación entre equipos

| Gate | Smoke | Entrega | Desbloquea |
|---|---|---|---|
| GATE 0 | [PASO_S00_SMOKE](pasos/PASO_S00_SMOKE.md) | Infra, contratos, mocks, proyectos base | Inicio del desarrollo por equipos |
| GATE 1a | — | Auth/JWT real (PASO_S01_01) | Equipo B integra login real |
| GATE 1b | — | Cartas y mazos reales (PASO_S02_02, PASO_S02_03) | Equipo B integra deck builder y catálogo |
| GATE 2 | [PASO_S05_SMOKE](pasos/PASO_S05_SMOKE.md) | GameEngine + WebSocket completo (PASO_S05_03) | Equipo B integra tablero real (PASO_S05_04) |
| GATE 3 | [PASO_S07_SMOKE](pasos/PASO_S07_SMOKE.md) | Salas privadas reales (PASO_S07_01) | Equipo B integra lobby con salas |
| GATE 4 | [PASO_S07_SMOKE](pasos/PASO_S07_SMOKE.md) | Matchmaking ranked real (PASO_S07_02) | Equipo B integra cola ranked |
| GATE 5 | [PASO_S08_SMOKE](pasos/PASO_S08_SMOKE.md) | Mercado Pago + sobres + wallet/tienda | Equipo B integra tienda real |
| GATE 6 | [PASO_S10_SMOKE](pasos/PASO_S10_SMOKE.md) | Leaderboard + ligas + amigos + noticias | Equipo B integra social real |
| GATE 7 | [PASO_S10_SMOKE](pasos/PASO_S10_SMOKE.md) | OAuth2 + perfil consolidado | Equipo B integra login social y perfil |
| GATE 8 | [CHECKLIST_ENTREGA](../02-planificacion/02_sprints/CHECKLIST_ENTREGA.md) | Carga + Playwright + Lighthouse | Cierre del MVP |

Cuando haya duda entre avanzar rápido o proteger un contrato entre equipos, **proteger el contrato**. El ahorro de contexto no sirve si después rompe la integración.

## PASO con la nueva doctrina (referencia)

[PASO_S01_02.md](pasos/PASO_S01_02.md) y [PASO_TEMPLATE.md](pasos/PASO_TEMPLATE.md) son los modelos para la doctrina actual. Los PASOS legacy todavía pueden tener bloques de código extensos; al refactorizarlos, mover el código a archivos de referencia técnica y dejar solo contratos + instrucciones en el PASO.
