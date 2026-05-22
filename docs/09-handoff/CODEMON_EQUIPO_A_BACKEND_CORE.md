# Codemon TCG - Anexo Equipo A Backend Core

Version: 1.0  
Fecha: 2026-05-19
Cobertura estimada: 42% del proyecto base

## 1. Responsabilidad

Equipo A es responsable del backend core: proyecto Spring Boot, Flyway, autenticacion base, catalogo de cartas, mazos, motor de juego y WebSocket STOMP.

El camino critico principal esta en `EPIC-04` durante S3-S5. La cadena `PASO_S03_01` a `PASO_S05_03` es secuencial y debe cuidarse como entrega de alto riesgo.

## 2. Sistema pre seteado

Antes de iniciar, confirmar:

| Requisito | Verificacion |
|---|---|
| Java 21 | `java -version` |
| Maven 3 | `mvn -version` |
| Docker Desktop activo | `docker ps` |
| PostgreSQL, Redis y MinIO arriba | `docker compose ps` |
| Repo en `~/codemon/` | `pwd` |
| `.env` generado desde `.env.example` | revisar variables de API, BD, Redis, MinIO y JWT |

Conocimientos esperados: Spring Boot, Spring Security, JPA, Flyway, testing, WebSocket STOMP y patrones State, Strategy, Chain, Observer y Facade.

## 3. Documentos obligatorios

- `CONTRIBUTING.md`
- `docs/08-desarrollo-con-ia/README.md`
- `docs/08-desarrollo-con-ia/CONVENCIONES.md`
- `docs/02-planificacion/README.md`
- `docs/02-planificacion/01_backlog/BACKLOG.md`
- `docs/02-planificacion/02_sprints/SPRINTS.md`
- `docs/02-planificacion/03_epicas/EPIC-04-MOTOR/EPIC.md`
- `docs/03-equipos/GUIA_EQUIPO_A.md`
- Antes de iniciar `EPIC-04` / S3-S5: `REGLAS_INDEX.md`, `01-setup.md`, `02-turn-flow.md`, `03-combat.md`, `04-win-conditions.md`, `PATRONES_DISENO.md`, `GAME_ENGINE_DETALLES.md`

## 4. Orden operativo

| Orden | Paso | Objetivo |
|---|---|---|
| 1 | `PASO_S00_01.md` | Liderar contratos API, WebSocket y mocks. |
| 2 | `PASO_S00_04.md` | Crear proyecto Spring Boot. |
| 3 | `PASO_S00_05.md` | Migraciones Flyway y seed base. |
| 4 | `PASO_S02_01.md` | Validacion de mazos. |
| 5 | `PASO_S01_01.md` | Auth JWT. |
| 6 | `PASO_S02_02.md` | Catalogo de cartas, seed XY1 y MinIO. |
| 7 | `PASO_S02_03.md` | Backend de mazos. |
| 8 | `PASO_S03_01.md` a `PASO_S05_03.md` | Motor completo y WebSocket. |

No avanzar a `PASO_S03_01` sin leer las reglas del motor. Parece lento, pero evita errores caros en turnos, premios, KO y condiciones.

## 5. Prompt modelo para IA

```text
Sos el agente de implementacion del proyecto Codemon TCG.
Carga docs/08-desarrollo-con-ia/CONVENCIONES.md.
Voy a implementar PASO_X del Equipo A.
Lee el YAML del paso, carga solo sus context_files usando docs/08-desarrollo-con-ia/README.md.
Implementa unicamente este paso.
No avances al paso siguiente.
Ejecuta la verificacion indicada.
Informa archivos modificados, tests corridos, resultado y bloqueo si existe.
```

## 6. Verificaciones clave

| Gate | Verificacion |
|---|---|
| GATE 0 | `./mvnw clean compile`, health de API, Flyway aplicado. |
| GATE 1a | Register, login, refresh y endpoint protegido con JWT. |
| GATE 1b | Seed de 146 cartas desde `xy1.json`, imagenes en MinIO, URLs en `cards_catalog`. |
| GATE 2 | Partida PvE completa, eventos STOMP y estado consistente. |
| Dependencia de GATE 6 | El resultado de partidas queda disponible para ranking/ligas del Equipo C. |

Comandos frecuentes:

```bash
cd ~/codemon/api && ./mvnw test
cd ~/codemon/api && ./mvnw spring-boot:run
curl http://localhost:8080/actuator/health
```

## 7. Handoff que debe entregar A

Para cada gate, completar:

```text
Gate:
Equipo que entrega: A
Equipo que espera:
Pasos completados:
Comandos de verificacion:
Resultado esperado:
Riesgos o deuda:
Proximo paso desbloqueado:
```

Minimo aceptable para entregar a B: contrato estable, endpoint probado, payload real y ejemplo de respuesta.
