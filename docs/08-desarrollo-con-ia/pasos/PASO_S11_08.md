---
id: PASO_S11_08
equipo: C
bloque: 11
dep: [PASO_S00_03, PASO_S00_06, PASO_S11_06]
siguiente: CHECKLIST_ENTREGA
context_files:
  - GLOSARIO.md
  - CONVENCIONES.md
  - docker-compose.yml
  - nginx.conf
  - GATEWAY_LOCAL.md
outputs:
  - docker-compose.prod.yml
  - front/nginx.prod.conf
  - .env.production.example
  - docs/07-infraestructura/GATEWAY_PRODUCCION_HTTPS.md
---

# PASO S11.08 — Configurar HTTPS productivo en Nginx
**Grupo legacy:** 6 — Deploy final | **Equipo:** C | **Dificultad:** 🟡 | **Tiempo:** 2–3 h

## Navegación
← **Anterior:** [PASO_S11_06](PASO_S11_06.md) — Test de carga WebSocket  
→ **Siguiente:** [CHECKLIST_ENTREGA.md](../../02-planificacion/02_sprints/CHECKLIST_ENTREGA.md) — Gate final de entrega

---

## Qué construye este paso

Prepara el stack productivo para que el usuario acceda por `https://<dominio>` y WebSocket seguro `wss://<dominio>/ws`. El entorno local queda igual: `http://localhost:8088`.

---

## Trazabilidad

- HU principal: TT-10-21
- Issue HU: #pendiente
- Epica: EPIC-10
- Issue Epica: #pendiente
- Fuente normativa: [../TRAZABILIDAD_PASOS_HU.yml](../TRAZABILIDAD_PASOS_HU.yml)
- Vista humana: [../TRAZABILIDAD_PASOS_HU.md](../TRAZABILIDAD_PASOS_HU.md)
- Regla de cierre: la TT pasa a `Done` solo cuando este paso queda `DONE` y verificado.

---

## Prerrequisitos

- `PASO_S00_03` completado: existe el stack Docker local y el gateway Nginx en `localhost:8088`.
- `PASO_S00_06` completado: el frontend se compila y se sirve desde Nginx.
- `PASO_S11_06` completado: el producto soporta carga suficiente para entrega.
- Dominio productivo definido fuera del repo.
- Certificados TLS productivos disponibles fuera del repo.

---

## Contratos a respetar

### Accesos publicos

| Entorno | HTTP | HTTPS | WebSocket |
|---|---|---|---|
| Local | `http://localhost:8088` | No aplica | `ws://localhost:8088/ws` |
| Produccion | redirige a HTTPS | `https://<dominio>` | `wss://<dominio>/ws` |

### Archivos TLS esperados en el contenedor

| Archivo | Uso |
|---|---|
| `/etc/nginx/certs/fullchain.pem` | Certificado publico + cadena |
| `/etc/nginx/certs/privkey.pem` | Clave privada |

### Reglas no negociables

- No generar certificados reales desde el agente.
- No commitear certificados, claves privadas ni `.env.production`.
- No cambiar el flujo local `docker compose up -d --build` ni el puerto `8088`.
- No exponer publicamente API, PostgreSQL, Redis, MinIO, Prometheus ni Grafana en produccion.
- Mantener Nginx como unico punto de entrada publico.

---

## Politica de idioma

Este archivo `.md` se redacta en español. Los archivos de configuracion runtime (`docker-compose.prod.yml`, `nginx.prod.conf`, `.env.production.example`) deben usar nombres, comentarios y placeholders en ingles cuando formen parte del runtime o de la configuracion.

---

## Instrucciones para el agente

1. Crear `docker-compose.prod.yml` como overlay productivo del compose local.
2. En el servicio `front`, reemplazar el port mapping local por:
   - `80:80`
   - `443:443`
3. Montar `front/nginx.prod.conf` como `/etc/nginx/conf.d/default.conf`.
4. Montar el directorio de certificados, por defecto `./infra/certs`, como `/etc/nginx/certs:ro`.
5. En produccion, remover exposicion publica de servicios internos (`postgres`, `redis`, `minio`, `prometheus`, `grafana`).
6. Crear `front/nginx.prod.conf` con:
   - server `80` que redirige a HTTPS con `301` o `308`;
   - server `443 ssl http2`;
   - `ssl_certificate /etc/nginx/certs/fullchain.pem`;
   - `ssl_certificate_key /etc/nginx/certs/privkey.pem`;
   - proxy interno a `api:8080` para `/api/`, `/ws/`, `/actuator/`, Swagger y OpenAPI;
   - proxy interno a `minio:9000` para `/minio/`;
   - headers `Host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Host`, `X-Forwarded-Port`, `X-Forwarded-Proto`;
   - headers WebSocket `Upgrade` y `Connection`.
7. Crear `.env.production.example` con placeholders, sin secretos reales.
8. Crear `docs/07-infraestructura/GATEWAY_PRODUCCION_HTTPS.md` con instrucciones APB de certificados, variables, deploy y verificacion.
9. Actualizar documentacion global para distinguir `HTTP/WS local` de `HTTPS/WSS produccion`.
10. Agregar `.gitignore` para evitar certificados y claves privadas versionadas.

---

## Casos borde / errores comunes

| Sintoma | Causa | Solucion |
|---|---|---|
| El navegador muestra certificado invalido | Certificado no corresponde a `<dominio>` o esta vencido | Reemitir certificado y montar `fullchain.pem` correcto. |
| El puerto `8088` aparece en produccion | Se uso solo `docker-compose.yml` o no se reemplazaron puertos | Levantar con `-f docker-compose.yml -f docker-compose.prod.yml`. |
| WebSocket falla solo en produccion | Cliente usa `ws://` o falta `Upgrade` en Nginx | Usar `wss://<dominio>/ws` y revisar location `/ws/`. |
| Imagenes salen con `http://localhost:8088` | `MINIO_PUBLIC_URL` productivo mal configurado | Usar `https://<dominio>/minio`. |
| CORS bloquea la app | `CORS_ALLOWED_ORIGINS` no coincide con el dominio HTTPS | Usar exactamente `https://<dominio>`. |
| Certificados aparecen en Git | `.gitignore` incompleto o carpeta incorrecta | Ignorar `infra/certs/`, `*.pem`, `*.key` y retirar secretos del index. |

---

## Tests obligatorios

- `ComposeProdConfigTest.configuracion_compose_productiva_es_valida` — `docker compose` resuelve el overlay sin error.
- `NginxProdConfigTest.redirige_http_a_https` — la config contiene redireccion `80 -> HTTPS`.
- `NginxProdConfigTest.configura_tls_y_certificados_montados` — la config usa `fullchain.pem` y `privkey.pem`.
- `NginxProdConfigTest.preserve_websocket_upgrade_headers` — `/ws/` mantiene `Upgrade` y `Connection`.
- `DocsProdHttpsTest.documenta_local_vs_produccion` — docs distinguen HTTP local de HTTPS productivo.

---

## Verificación automatizada

```bash
test -f docker-compose.prod.yml
test -f front/nginx.prod.conf
test -f .env.production.example
test -f docs/07-infraestructura/GATEWAY_PRODUCCION_HTTPS.md
docker compose --env-file .env.production.example -f docker-compose.yml -f docker-compose.prod.yml config >/dev/null
grep -q 'listen 443 ssl http2' front/nginx.prod.conf
grep -q 'return 308 https://$host$request_uri' front/nginx.prod.conf
grep -q 'ssl_certificate     /etc/nginx/certs/fullchain.pem;' front/nginx.prod.conf
grep -q 'ssl_certificate_key /etc/nginx/certs/privkey.pem;' front/nginx.prod.conf
grep -q 'proxy_set_header Upgrade $http_upgrade;' front/nginx.prod.conf
grep -q 'PUBLIC_BASE_URL=https://<dominio>' .env.production.example
```

---

## Verificación manual de deploy

Ejecutar solo en un servidor con dominio y certificados reales:

```bash
docker compose --env-file .env.production -f docker-compose.yml -f docker-compose.prod.yml exec front nginx -t
curl -I http://<dominio>
curl -I https://<dominio>/
curl https://<dominio>/actuator/health
curl -I https://<dominio>/swagger-ui.html
curl -I https://<dominio>/minio/minio/health/live
```

Validar WebSocket externo con cliente STOMP apuntando a:

```text
wss://<dominio>/ws
```

---

## Entrega al siguiente paso

- Produccion queda documentada para `https://<dominio>`.
- `docker-compose.prod.yml` permite levantar el stack productivo con `80/443`.
- `front/nginx.prod.conf` termina TLS y proxya internamente a API y MinIO.
- `.env.production.example` define variables productivas sin secretos reales.
- `GATEWAY_PRODUCCION_HTTPS.md` deja instrucciones APB para deploy y verificacion.

---

## Actualizacion de seguimiento

Al cerrar, pausar o bloquear este paso:

- Verificar que la relacion Paso -> TT -> Epica exista en [../TRAZABILIDAD_PASOS_HU.yml](../TRAZABILIDAD_PASOS_HU.yml).
- Actualizar [../ESTADO_PASOS.md](../ESTADO_PASOS.md) con estado, avance, responsable, commit/rama, bloqueos y proxima accion.
- Agregar una entrada en [../HISTORIAL_PASOS.md](../HISTORIAL_PASOS.md) con checks ejecutados, resultado, archivos tocados y handoff.
- Si este paso queda `DONE`, revisar el checklist de entrega final.

---

## Definition of Done

- [ ] Todos los archivos de `outputs:` existen.
- [ ] `./scripts/verify_paso.sh PASO_S11_08` retorna exit 0.
- [ ] `docker compose --env-file .env.production.example -f docker-compose.yml -f docker-compose.prod.yml config` retorna exit 0.
- [ ] Nginx productivo redirige HTTP a HTTPS.
- [ ] Nginx productivo preserva WebSocket por `/ws/`.
- [ ] Variables productivas usan `https://<dominio>`, no `localhost`.
- [ ] Certificados y claves privadas estan ignorados por Git.
- [ ] Documentacion local y productiva queda separada.
- [ ] Trazabilidad Paso -> TT -> Epica revisada.
