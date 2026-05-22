# Codemon TCG - Anexo Equipo C DevOps y Backend Auxiliar

Version: 1.0  
Fecha: 2026-05-19
Cobertura estimada: 28% del proyecto base

## 1. Responsabilidad

Equipo C es responsable de herramientas, Docker, Redis, matchmaking, rooms, boosters, pagos, leaderboard, noticias, amigos, OAuth2, Grafana, Prometheus y hardening de seguridad.

Su trabajo desbloquea integraciones de Equipo B y reduce riesgo operativo para A.

## 2. Sistema pre seteado

Antes de iniciar, confirmar:

| Requisito | Verificacion |
|---|---|
| Docker Desktop | `docker ps` |
| Docker Compose | `docker compose version` |
| PostgreSQL | health y conexion |
| Redis | `redis-cli ping` |
| MinIO | health live |
| Java 21 y Maven | backend auxiliar |
| Credenciales sandbox Mercado Pago | variables en `.env` cuando toque pagos |
| Grafana/Prometheus | servicios levantados post setup |

Conocimientos esperados: Docker Compose, PostgreSQL, Redis ZSET, Spring JPA, scheduling, webhooks idempotentes, Mercado Pago sandbox, OAuth2, Prometheus y Grafana.

## 3. Documentos obligatorios

- `CONTRIBUTING.md`
- `docs/08-desarrollo-con-ia/README.md`
- `docs/08-desarrollo-con-ia/CONVENCIONES.md`
- `docs/07-infraestructura/.env.example`
- `docs/07-infraestructura/docker-compose.yml`
- `docs/03-equipos/GUIA_EQUIPO_C.md`
- `docs/02-planificacion/01_backlog/BACKLOG.md`
- `docs/02-planificacion/02_sprints/SPRINTS.md`
- `docs/02-planificacion/04_proceso/EQUIPOS.md`
- `docs/02-planificacion/02_sprints/CHECKLIST_ENTREGA.md`
- `docs/02-planificacion/04_proceso/DOD.md`

## 4. Orden operativo

| Orden | Paso | Objetivo |
|---|---|---|
| 1 | `PASO_S00_01.md` | Participar en contratos. |
| 2 | `PASO_S00_02.md` | Herramientas. |
| 3 | `PASO_S00_03.md` | Servicios Docker. |
| 4 | `PASO_S08_02.md` | Leaderboard. |
| 5 | `PASO_S09_03.md` | Noticias. |
| 6 | `PASO_S08_03.md` | 2FA email. |
| 7 | `PASO_S08_01.md` | Boosters y coleccion. |
| 8 | `PASO_S07_01.md` | Salas privadas. |
| 9 | `PASO_S07_02.md` | Matchmaking ranked con Redis. |
| 10 | `PASO_S08_04.md` | Mercado Pago y webhooks. |
| 11 | `PASO_S09_02.md` | Amigos y presencia. |
| 12 | `PASO_S09_01.md` | Ranking por ligas. |
| 13 | `PASO_S10_01.md` | OAuth2 Google/GitHub backend. |
| 14 | `PASO_S08_05.md` | Grafana y metricas. |

## 5. Prompt modelo para IA

```text
Sos el agente de implementacion del proyecto Codemon TCG.
Carga docs/08-desarrollo-con-ia/CONVENCIONES.md.
Voy a implementar PASO_X del Equipo C.
Lee el YAML del paso, carga solo sus context_files usando docs/08-desarrollo-con-ia/README.md.
Implementa unicamente este paso.
No modifiques contratos sin avisar a los equipos A y B.
Ejecuta la verificacion indicada.
Informa archivos modificados, tests corridos, resultado y bloqueo si existe.
```

## 6. Verificaciones clave

| Gate | Verificacion |
|---|---|
| GATE 0 | Servicios healthy: PostgreSQL, Redis, MinIO, Prometheus, Grafana. |
| GATE 3 | Salas privadas generan partidas integrables. |
| GATE 4 | Matchmaking ranked genera partidas integrables. |
| GATE 5 | Webhook de pagos idempotente, sobres y tienda integrables por B. |
| GATE 6 | Leaderboard, ligas, amigos y noticias funcionando con datos reales o seed. |
| GATE 7 | OAuth2 y perfil consolidado integrables por B. |
| Seguridad | OAuth2, secrets por env, CORS y endpoints protegidos revisados. |
| Observabilidad | `/actuator/prometheus` scrapeado por Prometheus y dashboard en Grafana. |

Comandos frecuentes:

```bash
docker compose ps
docker logs codemon_postgres
docker logs codemon_redis
curl http://localhost:8080/actuator/health
curl http://localhost:8080/actuator/prometheus
```

## 7. Handoff que debe entregar C

```text
Gate:
Equipo que entrega: C
Equipo que espera:
Pasos completados:
Comandos de verificacion:
Resultado esperado:
Riesgos o deuda:
Proximo paso desbloqueado:
```

Para pagos, nunca entregar solo "compila". Entregar evidencia de webhook idempotente, estado de pago persistido y rollback/duplicado controlado.
