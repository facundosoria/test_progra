# Estado Operativo de PASOS — Codemon TCG

Este archivo es el tablero vivo para coordinar trabajo entre personas y agentes de IA. Su objetivo es que cualquier companero pueda retomar un `PASO_Sxx_xx` a mitad de camino sin reconstruir el estado desde chats, commits o archivos sueltos.

Este archivo muestra el **estado actual**. El historial cronologico se conserva en [HISTORIAL_PASOS.md](HISTORIAL_PASOS.md).

## Reglas de uso

1. Antes de iniciar una sesion, leer este archivo junto con `COMO_USAR.md`, `CONVENCIONES.md`, `GLOSARIO.md` y `TRAZABILIDAD_PASOS_HU.yml`.
2. Antes de trabajar en un paso, revisar su estado, dependencias, bloqueos, HU/TT asociadas y proxima accion.
3. Si se empieza un paso, cambiar su estado a `IN_PROGRESS` y completar responsable, avance, fecha y proxima accion.
4. Si se pausa a mitad de trabajo, actualizar avance, ultimo commit o rama, archivos tocados, checks pendientes y bloqueos.
5. Si el paso termina, marcar `DONE` solo cuando pase `./verify_paso.sh PASO_Sxx_xx`, la Definition of Done este completa y la entrega al siguiente paso refleje el estado real.
6. Cuando un paso queda `DONE`, revisar los pasos dependientes y pasar a `READY` los que ya tengan todas sus dependencias completas.
7. Cada cambio de estado debe registrarse tambien en [HISTORIAL_PASOS.md](HISTORIAL_PASOS.md).
8. La relacion Paso -> HU/TT -> Epica se toma de [TRAZABILIDAD_PASOS_HU.yml](TRAZABILIDAD_PASOS_HU.yml); regenerar esta tabla con `scripts/generate-traceability-docs.sh` si cambia el YAML.
9. No borrar historial util de handoff; si una nota queda vieja, moverla a [HISTORIAL_PASOS.md](HISTORIAL_PASOS.md).

## Estados permitidos

| Estado | Significado |
|---|---|
| `TODO` | Existe el paso, pero todavia no esta listo para empezar o nadie lo tomo. |
| `READY` | Sus dependencias estan completas y puede comenzar. |
| `IN_PROGRESS` | Alguien o un agente esta trabajando en el paso. |
| `PAUSED` | Trabajo iniciado pero detenido; requiere handoff claro para continuar. |
| `BLOCKED` | No puede avanzar por una dependencia, decision, credencial, bug externo o contrato no resuelto. |
| `REVIEW` | Desarrollo terminado, pendiente de revision, smoke test, PR o validacion humana. |
| `DONE` | Verificacion automatizada y DoD completas. El siguiente paso puede asumir la entrega. |

## Como retomar un paso en progreso

Usar este prompt base con el agente:

```text
Sos el agente de implementacion del proyecto Codemon TCG.

Primero lee:
- docs/08-desarrollo-con-ia/README.md
- docs/08-desarrollo-con-ia/ESTADO_PASOS.md
- docs/08-desarrollo-con-ia/HISTORIAL_PASOS.md
- docs/08-desarrollo-con-ia/TRAZABILIDAD_PASOS_HU.yml
- docs/08-desarrollo-con-ia/TRAZABILIDAD_PASOS_HU.md
- docs/08-desarrollo-con-ia/CONVENCIONES.md
- docs/05-referencia-tecnica/GLOSARIO.md

Quiero retomar el paso PASO_Sxx_xx. Revisa su fila en ESTADO_PASOS.md, confirma sus HU/TT en TRAZABILIDAD_PASOS_HU.yml, lee el PASO correspondiente, carga sus context_files y continua desde "Proxima accion". Antes de terminar la sesion, actualiza ESTADO_PASOS.md con el avance real y agrega una entrada en HISTORIAL_PASOS.md con checks ejecutados, bloqueos y siguiente accion.
```

## Criterio para marcar DONE

Un paso solo puede pasar a `DONE` si se cumple todo esto:

- `./verify_paso.sh PASO_Sxx_xx` retorna exit 0.
- Todos los archivos declarados en `outputs:` existen.
- Tests obligatorios pasan.
- La `Definition of Done` del paso esta completa.
- La relacion Paso -> HU/TT -> Epica esta registrada en `TRAZABILIDAD_PASOS_HU.yml`.
- La seccion "Entrega al siguiente paso" del paso refleja lo que realmente quedo implementado.
- No quedan TODO/FIXME relacionados con el alcance del paso.
- Si el paso cierra un gate, el smoke correspondiente pasa.

## Handoff activo

Completar esta seccion cuando un paso quede a mitad de trabajo.

| Campo | Valor |
|---|---|
| Paso activo | - |
| Responsable actual | - |
| Fecha/hora de pausa | - |
| Rama o commit base | - |
| Archivos tocados | - |
| Que ya esta hecho | - |
| Que falta | - |
| Checks ejecutados | - |
| Checks fallando | - |
| Bloqueos | - |
| Proxima accion exacta | - |

Cuando esta seccion se actualice, agregar tambien una entrada en [HISTORIAL_PASOS.md](HISTORIAL_PASOS.md) con el motivo de la pausa.

## Tablero de pasos

> Inicialmente todo queda `TODO`, excepto `PASO_S00_01`, que queda `READY` como primer punto de entrada. Actualizar esta tabla al avanzar.

| Paso | HU | Issue HU | Epica | Requerido para Done | Estado | Equipo | Avance | Responsable | Ultimo commit/rama | Bloqueos | Proxima accion |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- | --- |
| PASO_S00_01 | TT-10-01<br>TT-10-02<br>TT-10-03 | pendiente | EPIC-10 | Si | DONE | ALL | 100% | Codex | develop | - | Outputs existen: CONTRATOS_API.md, PROTOCOLO_WEBSOCKET.md, MOCKS_FRONTEND.md |
| PASO_S00_02 | TT-10-05 | pendiente | EPIC-10 | Si | DONE | C | 100% | Codex | develop | - | Herramientas verificadas: Java 21, Maven, Node 20, Angular CLI, Docker |
| PASO_S00_03 | TT-10-05 | pendiente | EPIC-10 | Si | DONE | C | 100% | Codex | develop | - | Docker Compose levantado; .env creado; todos los servicios healthy |
| PASO_S00_04 | TT-10-05 | pendiente | EPIC-10 | Si | DONE | A | 100% | Codex | develop | - | pom.xml actualizado; application.yml/dev/prod creados; Dockerfile copiado |
| PASO_S00_05 | TT-10-07 | pendiente | EPIC-10 | Si | DONE | A | 100% | Codex | develop | - | V1-V15 migraciones creadas; cards.json copiado a seed/; 28 tablas en BD |
| PASO_S00_06 | TT-10-03 | pendiente | EPIC-10 | Si | DONE | B | 100% | Codex | develop | - | Tailwind CSS 3 + STOMP + Lucide + FA instalados; environments creados; estructura de features lista |
| PASO_S00_07 | TT-10-05 | pendiente | EPIC-10 | Si | DONE | C | 100% | Codex | develop | - | 10/10 smoke tests PASS — GATE 0 desbloqueado |
| PASO_S00_SMOKE | sin HU directa | pendiente | EPIC-10 | No | DONE | ALL | 100% | Codex | develop | - | GATE 0 PASS: gateway, API health, ping, PG, Redis, MinIO, Prometheus, Grafana, tablas, Swagger |
| PASO_S01_01 | HU-01-01<br>HU-01-03<br>HU-01-04<br>HU-01-05 | pendiente | EPIC-01 | Si | READY | A | 0% | - | develop | - | Implementar auth backend |
| PASO_S01_02 | HU-01-01<br>HU-01-02<br>HU-01-03<br>HU-01-05 | pendiente | EPIC-01 | Si | READY | B | 0% | - | develop | - | Implementar auth UI con mocks/back real |
| PASO_S01_03 | HU-01-04 | pendiente | EPIC-01 | Si | TODO | B | 0% | - | - | Depende de PASO_S01_02 | Implementar app shell y guards |
| PASO_S02_01 | HU-03-03 | pendiente | EPIC-03 | Si | TODO | A | 0% | - | - | Depende de PASO_S00_05 | Implementar validacion de mazos |
| PASO_S02_02 | HU-02-01<br>HU-02-02<br>HU-02-03 | pendiente | EPIC-02 | Si | TODO | A | 0% | - | - | Depende de PASO_S00_05 | Implementar catalogo y seed de cartas |
| PASO_S02_03 | HU-03-01<br>HU-03-04<br>HU-03-05<br>HU-03-06 | pendiente | EPIC-03 | Si | TODO | A | 0% | - | - | Depende de PASO_S02_01/PASO_S01_01/PASO_S02_02 | Implementar CRUD de mazos |
| PASO_S02_04 | HU-03-02<br>HU-03-03 | pendiente | EPIC-03 | Si | TODO | B | 0% | - | - | Depende de PASO_S01_03/PASO_S02_03 | Implementar deck builder |
| PASO_S02_05 | HU-02-01<br>HU-02-02<br>HU-02-03 | pendiente | EPIC-02 | Si | TODO | B | 0% | - | - | Depende de PASO_S02_02 | Implementar catalogo UI |
| PASO_S02_SMOKE | sin HU directa | pendiente | - | No | TODO | ALL | 0% | - | - | Depende de S01/S02 completo | Ejecutar GATE 1a/1b auth + cartas + mazos |
| PASO_S03_01 | HU-04-01 | pendiente | EPIC-04 | Si | TODO | A | 0% | - | - | Depende de PASO_S02_03 | Implementar skeleton del motor |
| PASO_S03_02 | HU-04-09 | pendiente | EPIC-04 | Si | TODO | A | 0% | - | - | Depende de PASO_S03_01 | Implementar condiciones de victoria |
| PASO_S03_03 | HU-04-01 | pendiente | EPIC-04 | Si | TODO | A | 0% | - | - | Depende de PASO_S03_01/PASO_S02_03 | Implementar setup de partida |
| PASO_S03_04 | HU-04-02 | pendiente | EPIC-04 | Si | TODO | A | 0% | - | - | Depende de PASO_S03_01 | Implementar draw phase |
| PASO_S03_05 | HU-04-03<br>HU-04-04<br>HU-04-05 | pendiente | EPIC-04 | Si | TODO | A | 0% | - | - | Depende de PASO_S03_01/PASO_S03_04 | Implementar main phase |
| PASO_S04_01 | HU-04-06 | pendiente | EPIC-04 | Si | TODO | A | 0% | - | - | Depende de PASO_S03_01/PASO_S03_05 | Implementar DamageCalculator y StatusEffectManager |
| PASO_S04_02 | HU-04-06 | pendiente | EPIC-04 | Si | TODO | A | 0% | - | - | Depende de PASO_S04_01 | Implementar AttackPipeline |
| PASO_S04_03 | HU-04-06<br>HU-04-07<br>HU-04-08 | pendiente | EPIC-04 | Si | TODO | A | 0% | - | - | Depende de PASO_S04_02 | Integrar retreat y premios |
| PASO_S05_01 | HU-04-09 | pendiente | EPIC-04 | Si | TODO | A | 0% | - | - | Depende de S03/S04 motor | Implementar EndPhase |
| PASO_S05_02 | HU-08-01 | pendiente | EPIC-08 | Si | TODO | A | 0% | - | - | Depende de PASO_S05_01 y motor base | Implementar Bot EASY |
| PASO_S05_03 | HU-05-05 | pendiente | EPIC-05 | Si | TODO | A | 0% | - | - | Depende de PASO_S05_01/PASO_S05_02 | Implementar GameEngine facade + WS |
| PASO_S05_04 | HU-06-01 | pendiente | EPIC-06 | Si | TODO | B | 0% | - | - | Depende de PASO_S05_03 | Implementar tablero minimo |
| PASO_S05_SMOKE | sin HU directa | pendiente | - | No | TODO | ALL | 0% | - | - | Depende de S05 completo | Ejecutar GATE 2 PvE end-to-end |
| PASO_S06_01 | HU-06-04 | pendiente | EPIC-06 | Si | TODO | B | 0% | - | - | Depende de PASO_S02_05/PASO_S07_01/PASO_S07_02 segun modo | Implementar lobby UI |
| PASO_S07_01 | HU-05-01<br>HU-05-02 | pendiente | EPIC-05 | Si | TODO | C | 0% | - | - | Depende de PASO_S05_03 | Implementar salas privadas |
| PASO_S07_02 | HU-05-03<br>HU-05-04 | pendiente | EPIC-05 | Si | TODO | C | 0% | - | - | Depende de PASO_S05_03 | Implementar matchmaking ranked |
| PASO_S07_SMOKE | sin HU directa | pendiente | - | No | TODO | ALL | 0% | - | - | Depende de S07 completo | Ejecutar GATE 3/4 PvP |
| PASO_S08_01 | HU-02-04<br>HU-07-03<br>HU-07-04<br>HU-07-05 | pendiente | EPIC-02<br>EPIC-07 | Si | TODO | C | 0% | - | - | Depende de PASO_S02_02/PASO_S01_01/PASO_S00_03 | Implementar sobres y coleccion |
| PASO_S08_02 | HU-02-05<br>HU-09-05<br>HU-09-06 | pendiente | EPIC-02<br>EPIC-09 | Si | TODO | C | 0% | - | - | Depende de PASO_S08_01 | Implementar stats/leaderboard base |
| PASO_S08_03 | HU-01-02<br>HU-01-06 | pendiente | EPIC-01 | Si | TODO | C | 0% | - | - | Depende de PASO_S01_01 — marcar READY cuando S01_01 este DONE | Implementar email/2FA |
| PASO_S08_04 | HU-07-01<br>HU-07-02<br>HU-07-06 | pendiente | EPIC-07 | Si | TODO | C | 0% | - | - | Depende de PASO_S08_01/PASO_S01_01 | Implementar Mercado Pago y wallet |
| PASO_S08_05 | TT-10-12 | pendiente | EPIC-10 | Si | TODO | C | 0% | - | - | Depende de infra y servicios metricados | Implementar Prometheus/Grafana |
| PASO_S08_06 | HU-07-01<br>HU-07-03<br>HU-07-04<br>HU-07-05 | pendiente | EPIC-07 | Si | TODO | B | 0% | - | - | Depende de PASO_S06_01/PASO_S08_04 | Implementar shop UI |
| PASO_S08_SMOKE | sin HU directa | pendiente | - | No | TODO | ALL | 0% | - | - | Depende de S08 completo | Ejecutar GATE 5 tienda + 2FA + metricas |
| PASO_S09_01 | HU-09-07 | pendiente | EPIC-09 | Si | TODO | C | 0% | - | - | Depende de PASO_S03_02/PASO_S00_05 | Implementar ligas |
| PASO_S09_02 | HU-09-03<br>HU-09-04 | pendiente | EPIC-09 | Si | TODO | C | 0% | - | - | Depende de PASO_S01_01 | Implementar amigos y presencia |
| PASO_S09_03 | HU-09-08 | pendiente | EPIC-09 | Si | TODO | C | 0% | - | - | Depende de PASO_S01_01 | Implementar noticias |
| PASO_S09_04 | HU-09-05<br>HU-09-06<br>HU-09-08 | pendiente | EPIC-09 | Si | TODO | B | 0% | - | - | Depende de PASO_S08_06/PASO_S09_03 | Implementar leaderboard/news UI |
| PASO_S09_05 | HU-09-03<br>HU-09-04 | pendiente | EPIC-09 | Si | TODO | B | 0% | - | - | Depende de PASO_S09_02/PASO_S09_04 | Implementar profile/friends UI |
| PASO_S10_01 | HU-01-07 | pendiente | EPIC-01 | Si | TODO | C | 0% | - | - | Depende de PASO_S01_01 | Implementar OAuth backend |
| PASO_S10_02 | HU-01-07 | pendiente | EPIC-01 | Si | TODO | B | 0% | - | - | Depende de PASO_S10_01/PASO_S01_03 | Implementar OAuth UI callback |
| PASO_S10_SMOKE | sin HU directa | pendiente | - | No | TODO | ALL | 0% | - | - | Depende de S09/S10 completo | Ejecutar GATE 6/7 social + OAuth + perfil |
| PASO_S11_01 | HU-08-02<br>HU-08-03 | pendiente | EPIC-08 | Si | TODO | A | 0% | - | - | Depende de PASO_S05_02 | Implementar bots avanzados |
| PASO_S11_02 | HU-06-05<br>HU-08-05 | pendiente | EPIC-06<br>EPIC-08 | Si | TODO | A | 0% | - | - | Depende de PASO_S05_03 | Implementar chat backend |
| PASO_S11_03 | HU-08-04<br>HU-08-05 | pendiente | EPIC-08 | Si | TODO | A | 0% | - | - | Depende de PASO_S11_02/PASO_S05_02 | Implementar personalidad del bot |
| PASO_S11_04 | HU-07-01<br>HU-07-06 | pendiente | EPIC-07 | Si | TODO | C/B | 0% | - | - | Depende de PASO_S08_04 | Implementar wallet endpoint/UI |
| PASO_S11_05 | HU-09-01<br>HU-09-02 | pendiente | EPIC-09 | Si | TODO | C/B | 0% | - | - | Depende de PASO_S09_01/PASO_S09_02 | Implementar perfil consolidado |
| PASO_S11_06 | TT-11-04<br>TT-11-09 | pendiente | EPIC-11 | Si | TODO | A/B | 0% | - | - | Depende de MVP funcional | Implementar E2E y carga |
| PASO_S11_07 | HU-06-06<br>TT-11-05 | pendiente | EPIC-06<br>EPIC-11 | Si | TODO | B | 0% | - | - | Depende de UI principal | Implementar responsive y Lighthouse |
| PASO_S11_08 | TT-10-21 | pendiente | EPIC-10 | Si | DONE | C | 100% | Codex | pendiente de commit | - | Validar en servidor real con dominio y certificados productivos |

## Historial breve

| Fecha | Paso | Cambio | Autor |
|---|---|---|---|
| 2026-05-17 | - | Creacion del tablero operativo de pasos | Codex |
