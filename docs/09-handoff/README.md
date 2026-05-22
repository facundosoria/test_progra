# Codemon - paquete de handoff

Esta carpeta contiene las fuentes Markdown de handoff por equipos y un generador reproducible de PDFs. Los PDFs son artefactos generados localmente y no se versionan en Git.

## Archivos fuente

| Fuente | PDF local generado |
|---|---|
| `CODEMON_HANDOFF_COMPLETO.md` | `CODEMON_HANDOFF_COMPLETO.pdf` |
| `CODEMON_EQUIPO_A_BACKEND_CORE.md` | `CODEMON_EQUIPO_A_BACKEND_CORE.pdf` |
| `CODEMON_EQUIPO_B_FRONTEND.md` | `CODEMON_EQUIPO_B_FRONTEND.pdf` |
| `CODEMON_EQUIPO_C_DEVOPS_BACKEND_AUX.md` | `CODEMON_EQUIPO_C_DEVOPS_BACKEND_AUX.pdf` |
| `CODEMON_CHECKLIST_EJECUTIVA.md` | `CODEMON_CHECKLIST_EJECUTIVA.pdf` |

## Regenerar PDFs

Desde la raiz del proyecto:

```bash
python3 docs/09-handoff/generar_pdfs.py
```

El generador usa solo la biblioteca estandar de Python. Si el equipo prefiere una salida editorial mas rica, estas mismas fuentes pueden exportarse con Pandoc, Playwright o una herramienta equivalente.

> Nota: los PDFs generados quedan ignorados por `.gitignore`. Para actualizar el paquete, editar primero los `.md` y regenerar los PDFs solo para distribucion local.

## Fuentes canonicas usadas

- `CONTRIBUTING.md`
- `docs/08-desarrollo-con-ia/README.md`
- `docs/02-planificacion/README.md`
- `docs/02-planificacion/00_guia/GITHUB_PROJECT_WORKFLOW.md`
- `docs/02-planificacion/01_backlog/PRODUCT_BACKLOG.md`
- `docs/02-planificacion/01_backlog/BACKLOG.md`
- `docs/02-planificacion/02_sprints/SPRINTS.md`
- `docs/02-planificacion/04_proceso/EQUIPOS.md`
- `docs/03-equipos/GUIA_EQUIPO_A.md`
- `docs/03-equipos/GUIA_EQUIPO_B.md`
- `docs/03-equipos/GUIA_EQUIPO_C.md`
- `docs/02-planificacion/02_sprints/CHECKLIST_ENTREGA.md`
- `docs/02-planificacion/04_proceso/DOD.md`
