# Historial Operativo de PASOS — Codemon TCG

Este archivo es la bitacora cronologica del avance real de los `PASO_*.md`. A diferencia de `ESTADO_PASOS.md`, que muestra el estado actual, este historial conserva que cambio, cuando, quien lo hizo, que se verifico y que quedo pendiente.

## Regla principal

Agregar una entrada al historial cada vez que ocurra cualquiera de estos eventos:

- Un paso cambia de estado: `TODO`, `READY`, `IN_PROGRESS`, `PAUSED`, `BLOCKED`, `REVIEW`, `DONE`.
- Se pausa un paso a mitad de trabajo.
- Se detecta o resuelve un bloqueo.
- Se ejecuta `./verify_paso.sh PASO_Sxx_xx`.
- Se completa una entrega al siguiente paso.
- Se cierra un smoke test o gate.

No editar entradas viejas salvo para corregir errores de tipeo evidentes. Si una situacion cambia, agregar una nueva entrada.

## Formato de entrada

```md
### YYYY-MM-DD HH:mm — PASO_Sxx_xx — ESTADO_NUEVO

- Responsable: Nombre / Equipo / Agente
- HU afectadas: HU-xx-xx / TT-xx-xx / sin HU directa
- Issue HU: #123 / pendiente
- Estado anterior: TODO | READY | IN_PROGRESS | PAUSED | BLOCKED | REVIEW | DONE
- Estado nuevo: TODO | READY | IN_PROGRESS | PAUSED | BLOCKED | REVIEW | DONE
- Project status anterior: Backlog | Pendiente | En progreso | En revision | Done | Blocked | no aplica
- Project status nuevo: Backlog | Pendiente | En progreso | En revision | Done | Blocked | no aplica
- Rama/commit: <branch o hash>
- Archivos tocados:
  - ruta/al/archivo
- Avance real:
  - Que quedo hecho
  - Que falta
- Checks ejecutados:
  - comando -> PASS/FAIL
- Evidencia de verificacion:
  - resumen del resultado, enlace a PR, salida relevante o motivo de bloqueo
- Bloqueos:
  - ninguno / descripcion
- Proxima accion:
  - accion exacta para retomar
```

## Entradas

### 2026-05-20 15:45 — PASO_S11_08 — DONE

- Responsable: Codex / Equipo C / Agente
- HU afectadas: TT-10-21
- Issue HU: pendiente
- Estado anterior: TODO
- Estado nuevo: DONE
- Project status anterior: Pendiente
- Project status nuevo: Done
- Rama/commit: pendiente de commit
- Archivos tocados:
  - `docker-compose.prod.yml`
  - `front/nginx.prod.conf`
  - `.env.production.example`
  - `docs/07-infraestructura/GATEWAY_PRODUCCION_HTTPS.md`
  - `docs/08-desarrollo-con-ia/pasos/PASO_S11_08.md`
  - `docs/08-desarrollo-con-ia/TRAZABILIDAD_PASOS_HU.yml`
  - `docs/08-desarrollo-con-ia/TRAZABILIDAD_PASOS_HU.md`
  - `docs/08-desarrollo-con-ia/ESTADO_PASOS.md`
  - `docs/08-desarrollo-con-ia/README.md`
  - `docs/02-planificacion/01_backlog/epicas_y_user_stories.csv`
  - `docs/02-planificacion/00_guia/LISTADO_COMPLETO_ARCHIVOS.md`
  - `docs/02-planificacion/03_epicas/EPIC-10-INFRA/EPIC.md`
  - `docs/02-planificacion/02_sprints/CHECKLIST_ENTREGA.md`
  - `README.md`
  - `docs/01-producto/TECNOLOGIAS.md`
  - `docs/07-infraestructura/GATEWAY_LOCAL.md`
  - `.gitignore`
  - `scripts/verify_paso.sh`
- Avance real:
  - Se implemento overlay productivo HTTPS con Nginx TLS.
  - Se agrego Nginx productivo con redireccion `80 -> 443`, TLS y soporte WebSocket.
  - Se agrego plantilla productiva `.env.production.example`.
  - Se documento el deploy productivo HTTPS y se mantuvo local en HTTP.
  - Se agrego `TT-10-21` y su trazabilidad a EPIC-10.
- Checks ejecutados:
  - `docker compose --env-file .env.production.example -f docker-compose.yml -f docker-compose.prod.yml config` -> PASS
  - `./scripts/verify_paso.sh PASO_S11_08` -> PASS (11 PASS, 0 FAIL)
  - `scripts/validate-traceability.sh` -> PASS
- Evidencia de verificacion:
  - Compose productivo resuelve con `front` exponiendo solo `80` y `443`; servicios internos sin puertos publicados en el overlay.
- Bloqueos:
  - ninguno
- Proxima accion:
  - En servidor real, montar certificados validos y ejecutar la verificacion manual de `GATEWAY_PRODUCCION_HTTPS.md`.

### 2026-05-20 15:30 — PASO_S11_08 — TODO

- Responsable: Codex / Equipo C / Agente
- HU afectadas: TT-10-21
- Issue HU: pendiente
- Estado anterior: no existia
- Estado nuevo: TODO
- Project status anterior: no aplica
- Project status nuevo: Pendiente
- Rama/commit: pendiente de commit
- Archivos tocados:
  - `docs/08-desarrollo-con-ia/pasos/PASO_S11_08.md`
  - `docker-compose.prod.yml`
  - `front/nginx.prod.conf`
  - `.env.production.example`
  - `docs/07-infraestructura/GATEWAY_PRODUCCION_HTTPS.md`
  - `docs/08-desarrollo-con-ia/TRAZABILIDAD_PASOS_HU.yml`
  - `docs/08-desarrollo-con-ia/ESTADO_PASOS.md`
  - `docs/02-planificacion/03_epicas/EPIC-10-INFRA/EPIC.md`
- Avance real:
  - Se creo el paso para que un agente implemente y verifique HTTPS productivo.
  - Se asocio el paso a `TT-10-21` dentro de EPIC-10.
  - Se mantuvo el entorno local en `http://localhost:8088`.
- Checks ejecutados:
  - pendiente de verificacion automatizada
- Evidencia de verificacion:
  - pendiente
- Bloqueos:
  - ninguno
- Proxima accion:
  - Ejecutar `./scripts/verify_paso.sh PASO_S11_08` y validar `docker compose --env-file .env.production.example -f docker-compose.yml -f docker-compose.prod.yml config`.

### 2026-05-17 — PROCESO — DONE

- Responsable: Codex
- Estado anterior: politica mixta de idioma
- Estado nuevo: politica de implementacion en ingles
- Rama/commit: pendiente de commit
- Archivos tocados:
  - `docs/08-desarrollo-con-ia/CONVENCIONES.md`
  - `docs/02-planificacion/04_proceso/DOD.md`
  - `docs/02-planificacion/02_sprints/CHECKLIST_ENTREGA.md`
  - `docs/08-desarrollo-con-ia/README.md`
  - `docs/08-desarrollo-con-ia/pasos/PASO_TEMPLATE.md`
  - `docs/04-diseno-ui/*.html`
  - referencias de reglas/pasos con strings runtime visibles
- Avance real:
  - Se reemplazo la regla mixta previa por implementacion completa en ingles.
  - Se mantuvo la documentacion `.md` en español, con snippets y strings runtime en ingles.
  - Se tradujeron textos visibles de UI en los HTML de referencia.
- Checks ejecutados:
  - busqueda de reglas contradictorias de idioma -> PASS
  - busqueda de textos visibles en español dentro de `docs/04-diseno-ui` -> PASS
- Bloqueos:
  - ninguno
- Proxima accion:
  - Al implementar cualquier PASO, aplicar la politica: documentacion `.md` en español; codigo, runtime y UI visible en ingles.

### 2026-05-17 — PROCESO — READY

- Responsable: Codex
- Estado anterior: sin tablero operativo
- Estado nuevo: seguimiento documental creado
- Rama/commit: pendiente de commit
- Archivos tocados:
  - `docs/08-desarrollo-con-ia/ESTADO_PASOS.md`
  - `docs/08-desarrollo-con-ia/HISTORIAL_PASOS.md`
  - `docs/08-desarrollo-con-ia/README.md`
- Avance real:
  - Se agrego tablero actual de pasos.
  - Se agrego historial cronologico de cambios de estado.
  - Se conecto el flujo de agentes con el seguimiento operativo.
- Checks ejecutados:
  - revision documental manual -> PASS
- Bloqueos:
  - ninguno
- Proxima accion:
  - Al iniciar `PASO_S00_01`, marcarlo `IN_PROGRESS` en `ESTADO_PASOS.md` y agregar nueva entrada en este historial.
