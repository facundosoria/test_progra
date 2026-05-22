# Codemon TCG - Anexo Equipo B Frontend Angular

Version: 1.0  
Fecha: 2026-05-19
Cobertura estimada: 30% del proyecto base

## 1. Responsabilidad

Equipo B es responsable del frontend Angular: UI mock-first, auth UI, app shell, deck builder, catalogo, tablero, lobby, shop, perfil, amigos, OAuth2, responsive y E2E.

La regla central es trabajar mock-first hasta que los gates reales esten disponibles. Los mocks no son deuda si respetan `CONTRATOS_API.md`.

## 2. Sistema pre seteado

Antes de iniciar, confirmar:

| Requisito | Verificacion |
|---|---|
| Node.js 20 o superior | `node -v` |
| Angular CLI | `ng version` |
| Docker Desktop activo | necesario para integracion real |
| Repo en `~/codemon/` | `pwd` |
| Dependencias Angular | `npm install` dentro de `front` cuando exista |

Conocimientos esperados: Angular standalone, TypeScript strict, RxJS, interceptores HTTP, guards, STOMP, CDK drag/drop, Tailwind CSS 3 (utility-first), FontAwesome y Playwright.

## 3. Documentos obligatorios

- `CONTRIBUTING.md`
- `docs/08-desarrollo-con-ia/README.md`
- `docs/08-desarrollo-con-ia/CONVENCIONES.md`
- `docs/05-referencia-tecnica/MOCKS_FRONTEND.md`
- `docs/05-referencia-tecnica/CONTRATOS_API.md`
- `docs/05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md`
- `docs/02-planificacion/01_backlog/BACKLOG.md`
- `docs/02-planificacion/02_sprints/SPRINTS.md`
- `docs/02-planificacion/03_epicas/EPIC-06-TABLERO/EPIC.md`
- `docs/03-equipos/GUIA_EQUIPO_B.md`

## 4. Orden operativo

| Orden | Paso | Objetivo |
|---|---|---|
| 1 | `PASO_S00_01.md` | Participar en contratos y mocks. |
| 2 | `PASO_S00_06.md` | Crear proyecto Angular. |
| 3 | `PASO_S01_02.md` | Login, registro y verificacion. |
| 4 | `PASO_S01_03.md` | Shell, rutas, guards y navegacion. |
| 5 | `PASO_S02_04.md` | Builder con drag/drop y validacion visual. |
| 6 | `PASO_S02_05.md` | Catalogo, filtros, imagenes. |
| 7 | `PASO_S05_04.md` | Tablero de juego real, post GATE 2. |
| 8 | `PASO_S06_01.md` | Lobby PvE, ranked y sala privada. |
| 9 | `PASO_S08_06.md` | Tienda y apertura de sobres. |
| 10 | `PASO_S09_04.md` | Leaderboard y noticias. |
| 11 | `PASO_S09_05.md` | Perfil y amigos. |
| 12 | `PASO_S10_02.md` | Integracion OAuth2. |
| 13 | `PASO_S11_06.md` | E2E con Playwright. |
| 14 | `PASO_S11_07.md` | Responsive y mobile. |

## 5. Estrategia mock-first

1. Implementar servicios Angular contra DTOs del contrato.
2. Usar mock interceptor mientras el backend no este listo.
3. Al abrir un gate, reemplazar mocks por endpoints reales sin cambiar componentes.
4. Registrar cualquier diferencia entre contrato y backend como bloqueo del gate.

Imagenes: el frontend debe consumir `imageSmallUrl` e `imageLargeUrl` desde la API. Esas URLs apuntan a MinIO despues del seed. No pedir ni usar endpoints binarios como estrategia activa.

## 6. Prompt modelo para IA

```text
Sos el agente de implementacion del proyecto Codemon TCG.
Carga docs/08-desarrollo-con-ia/CONVENCIONES.md.
Voy a implementar PASO_X del Equipo B.
Lee el YAML del paso, carga solo sus context_files usando docs/08-desarrollo-con-ia/README.md.
Trabaja mock-first si el gate real aun no esta disponible.
Implementa unicamente este paso.
Ejecuta ng build, tsc o la verificacion indicada.
Informa archivos modificados, tests corridos, resultado y bloqueo si existe.
```

## 7. Verificaciones clave

| Momento | Verificacion |
|---|---|
| Base Angular | `ng build` sin errores. |
| TypeScript | `npx tsc --noEmit` si aplica. |
| Auth | Login mock y luego login real post GATE 1a. |
| Catalogo | UI muestra imagenes MinIO post GATE 1b. |
| Tablero | Conexion WebSocket STOMP real post GATE 2. |
| Final | Playwright E2E cubre flujos principales. |

Comandos frecuentes:

```bash
cd ~/codemon/front && ng build
cd ~/codemon/front && npx tsc --noEmit
cd ~/codemon/front && npx playwright test
```

## 8. Handoff que debe pedir B

Antes de integrar un gate, pedir:

```text
Gate:
Equipo que entrega:
Equipo que espera: B
Pasos completados:
Comandos de verificacion:
Resultado esperado:
Riesgos o deuda:
Proximo paso desbloqueado:
```

Si el contrato cambia, B debe pedir confirmacion y actualizar mocks antes de modificar pantallas.
