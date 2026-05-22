---
id: PASO_S00_04
equipo: A
bloque: 0
dep: [PASO_S00_03]
siguiente: PASO_S00_05
context_files:
  - CONVENCIONES.md
outputs:
  - api/src/main/resources/application.yml
  - api/src/main/resources/application-dev.yml
  - api/src/main/resources/application-prod.yml
  - api/pom.xml
---

# PASO 0.3 — Crear proyecto Spring Boot
**Grupo legacy:** 0 — Infraestructura | **Equipo:** A | **Dificultad:** 🟢 | **Tiempo:** 1–2 h

## Navegación
← **Anterior:** [PASO_S00_03](PASO_S00_03.md) — Servicios Docker levantados (PostgreSQL, Redis, MinIO)
→ **Siguiente:** [PASO_S00_05](PASO_S00_05.md) — Crear migraciones Flyway (15 archivos SQL)

## Archivos a cargar junto a este
Ninguno — el prompt es autocontenido.

## Qué construye este paso
Genera el proyecto Spring Boot base desde Spring Initializr y configura el `application.yml` con todas las variables de entorno del proyecto.

## Hacer

1. Ir a [https://start.spring.io](https://start.spring.io):
   - Maven | Java 21 | Spring Boot 3.3.x
   - Group: `com.codemon` | Artifact: `api`
   - Dependencies: Spring Web, Spring Data JPA, Spring Security, Spring Boot Actuator, Validation, Lombok, PostgreSQL Driver, Flyway Migration, Spring Data Redis, WebSocket, Java Mail Sender
2. GENERATE → extraer en `~/codemon/api/`
3. Agregar dependencias extra en `pom.xml` (JWT, Swagger, MinIO, Prometheus, Testcontainers, JaCoCo, OAuth2)
4. Copiar `Dockerfile.api` → `~/codemon/api/Dockerfile`
5. Usar el prompt de abajo para generar el `application.yml`

## Prompt listo para el agente

```
Creá el archivo application.yml para un proyecto Spring Boot 3.3.x con Java 21 llamado "codemon-api".

El proyecto usa:
- PostgreSQL (variables de entorno: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD)
- Redis (REDIS_HOST, REDIS_PORT)
- Flyway con migraciones en classpath:db/migration
- Spring Mail (EMAIL_SMTP_HOST, EMAIL_SMTP_PORT, EMAIL_USERNAME, EMAIL_PASSWORD)
- Actuator con endpoints: health, info, prometheus, metrics
- Swagger en /swagger-ui.html
- ddl-auto: validate (Flyway maneja el schema)
- open-in-view: false
- Sin SQL en los logs (show-sql: false)
- server.forward-headers-strategy: native
  (Spring confía en X-Forwarded-Proto que envía Nginx; sin esto, en producción Spring
  piensa que está en HTTP aunque el usuario esté en HTTPS — rompe OAuth2 y redirects)

Propiedades custom bajo el prefijo "codemon":
- jwt.secret (JWT_SECRET, default: dev_secret_cambiar_en_prod_min32chars)
- jwt.expiry-ms (JWT_EXPIRY_MS, default: 900000)
- jwt.refresh-expiry-ms (REFRESH_TOKEN_EXPIRY_MS, default: 604800000)
- minio.endpoint (http://MINIO_HOST:MINIO_PORT)
- minio.access-key (MINIO_USER)
- minio.secret-key (MINIO_PASSWORD)
- minio.bucket (MINIO_BUCKET)
- minio.public-url (MINIO_PUBLIC_URL)
- cors.allowed-origins (CORS_ALLOWED_ORIGINS, default: http://localhost:8088)
- mercadopago.access-token (MP_ACCESS_TOKEN)
- mercadopago.sandbox (MP_SANDBOX, default: true)

Todos los valores deben leer de variables de entorno con valores por defecto sensatos para desarrollo local.

Aplicá las convenciones de CONVENCIONES.md.
```

## Archivos que crea/modifica
```
api/src/main/resources/application.yml
api/src/main/resources/application-dev.yml
api/src/main/resources/application-prod.yml
api/pom.xml  (con dependencias extra)
```

## Errores comunes

- `mvn compile` falla con "source release 21 requires target release 21" → verificar `java -version` es 21
- YAML mal indentado → usar exactamente 2 espacios, nunca tabs
- `JWT_SECRET` menor a 32 caracteres → error al iniciar la API

## Verificación

```bash
cd ~/codemon/api && ./mvnw clean compile
# PASS: "BUILD SUCCESS"
# FAIL: cualquier error de compilación → revisar pom.xml y application.yml
```

## Dependencias
PASO_S00_03 completado (Docker con infra levantada).
