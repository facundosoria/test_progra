# Gateway de Produccion HTTPS — Codemon TCG

Esta guia define como publicar Codemon en produccion con HTTPS. El entorno local sigue usando `http://localhost:8088`; no se configura HTTPS local por ahora.

## Objetivo

| Entorno | Entrada publica | WebSocket | TLS |
|---|---|---|---|
| Local | `http://localhost:8088` | `ws://localhost:8088/ws` | No |
| Produccion | `https://<dominio>` | `wss://<dominio>/ws` | Si, terminado en Nginx |

Nginx es el unico punto de entrada publico. Internamente, Nginx reenvia trafico por HTTP a los contenedores `api:8080` y `minio:9000`.

---

## Archivos involucrados

| Archivo | Funcion |
|---|---|
| `docker-compose.yml` | Stack local base. No cambia el flujo `localhost:8088`. |
| `docker-compose.prod.yml` | Overlay productivo: expone `80` y `443`, oculta puertos internos y monta certificados. |
| `front/nginx.prod.conf` | Configuracion Nginx productiva con redireccion HTTP -> HTTPS y TLS. |
| `.env.production.example` | Plantilla de variables productivas. No contiene secretos reales. |

---

## Certificados

Los certificados no se generan ni se commitean desde el repo. Deben venir de una fuente externa:

- Let's Encrypt / Certbot.
- Un proveedor cloud.
- Un proxy corporativo.
- Un certificado emitido por la organizacion.

Nginx espera estos archivos montados dentro del contenedor:

```text
/etc/nginx/certs/fullchain.pem
/etc/nginx/certs/privkey.pem
```

Por defecto, `docker-compose.prod.yml` monta `./infra/certs` como `/etc/nginx/certs`. Esa carpeta debe existir en el servidor, pero no debe versionarse.

Estructura esperada en el servidor:

```text
infra/
└── certs/
    ├── fullchain.pem
    └── privkey.pem
```

---

## Variables de entorno productivas

Crear el archivo real a partir de la plantilla:

```bash
cp .env.production.example .env.production
```

Valores obligatorios a revisar:

| Variable | Valor esperado |
|---|---|
| `PUBLIC_BASE_URL` | `https://<dominio>` |
| `MINIO_PUBLIC_URL` | `https://<dominio>/minio` |
| `CORS_ALLOWED_ORIGINS` | `https://<dominio>` |
| `TLS_CERTS_DIR` | Ruta local donde estan `fullchain.pem` y `privkey.pem` |
| `JWT_SECRET` | Secreto real, aleatorio, minimo 32 caracteres |
| `MP_SANDBOX` | `false` en produccion |

No usar `http://localhost:8088` en variables productivas.

---

## Deploy productivo

Desde la raiz del repo en el servidor:

```bash
docker compose --env-file .env.production \
  -f docker-compose.yml \
  -f docker-compose.prod.yml \
  up -d --build
```

Ver configuracion resuelta antes de levantar:

```bash
docker compose --env-file .env.production \
  -f docker-compose.yml \
  -f docker-compose.prod.yml \
  config
```

---

## Verificacion APB

### Configuracion

```bash
docker compose --env-file .env.production \
  -f docker-compose.yml \
  -f docker-compose.prod.yml \
  config

docker compose --env-file .env.production \
  -f docker-compose.yml \
  -f docker-compose.prod.yml \
  exec front nginx -t
```

### Redireccion HTTP a HTTPS

```bash
curl -I http://<dominio>
# Esperado: 301 o 308 hacia https://<dominio>
```

### HTTPS

```bash
curl -I https://<dominio>/
curl https://<dominio>/actuator/health
curl -I https://<dominio>/swagger-ui.html
curl -I https://<dominio>/minio/minio/health/live
```

### WebSocket

El cliente debe usar:

```text
wss://<dominio>/ws
```

No usar `ws://<dominio>/ws` en produccion.

---

## Errores comunes

| Sintoma | Causa probable | Solucion |
|---|---|---|
| Browser marca certificado invalido | Certificado vencido, dominio incorrecto o self-signed | Reemitir certificado para `<dominio>` y revisar `fullchain.pem`. |
| `curl https://<dominio>` falla con connection refused | Puerto `443` cerrado o contenedor `front` caido | Revisar firewall, DNS y `docker compose ps`. |
| HTTP no redirige a HTTPS | No se cargo `nginx.prod.conf` | Verificar volumen `./front/nginx.prod.conf:/etc/nginx/conf.d/default.conf:ro`. |
| WebSocket conecta en local pero no en produccion | Cliente usa `ws://` o Nginx no envia headers Upgrade | Usar `wss://<dominio>/ws` y verificar bloque `/ws/` de Nginx. |
| Imagenes guardadas con HTTP | `MINIO_PUBLIC_URL` productivo mal configurado | Usar `https://<dominio>/minio` y regenerar/actualizar URLs persistidas. |
| CORS bloquea frontend productivo | `CORS_ALLOWED_ORIGINS` no incluye el dominio HTTPS | Configurar exactamente `https://<dominio>`. |

---

## Regla de cierre

Produccion queda lista para HTTPS cuando:

- `docker-compose.prod.yml` expone solo `80` y `443`.
- `front/nginx.prod.conf` redirige HTTP a HTTPS.
- `front/nginx.prod.conf` sirve TLS con certificados montados.
- `/api`, `/ws`, `/minio`, `/actuator`, Swagger y la SPA funcionan por HTTPS.
- Las variables productivas no contienen `localhost`.
- No hay certificados ni secretos reales versionados.
