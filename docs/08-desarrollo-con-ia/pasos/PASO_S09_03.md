---
id: PASO_S09_03
equipo: C+B
bloque: 9
dep: [PASO_S01_01, PASO_S00_05]
siguiente: PASO_S09_04
context_files:
  - BD_Y_TABLAS.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/news/entity/NewsPost.java
  - api/src/main/java/com/codemon/news/repository/NewsPostRepository.java
  - api/src/main/java/com/codemon/news/service/NewsService.java
  - api/src/main/java/com/codemon/news/controller/NewsController.java
  - api/src/main/java/com/codemon/news/dto/NewsPostResponse.java
  - api/src/main/java/com/codemon/news/dto/CreateNewsRequest.java
  - front/src/app/news/pages/news-page/news-page.component.ts
  - front/src/app/news/components/news-card/news-card.component.ts
  - front/src/app/news/services/news.service.ts
---

# PASO 5.3 — Sección de noticias
**Grupo legacy:** 5 — Features Finales | **Equipo:** C (backend) + B (frontend) | **Dificultad:** 🟢 | **Tiempo:** 2–3 h

## Navegación
← **Anterior:** [PASO_S09_02](PASO_S09_02.md) — Sistema de amigos y presencia
→ **Siguiente:** [PASO_S10_01](PASO_S10_01.md) — OAuth2 login con Google y GitHub (paso final)

## Archivos a cargar junto a este
- `SCHEMA_BD.sql` → bloque V14 (tabla news_posts)

## Qué construye este paso
Sistema de noticias donde un admin puede publicar actualizaciones que todos los usuarios ven. Simple, paginado, con categorías.

## Prompt listo para el agente

```
Implementá la sección de noticias para Codemon TCG.
Spring Boot 3.x, Spring Data JPA.

Schema:
[pegá bloque V14 de SCHEMA_BD.sql]

Implementá:

1. NewsPost.java entity con campos:
   id, title, content, category (enum: UPDATE/EVENT/MAINTENANCE/ANNOUNCEMENT),
   authorId, published_at, is_pinned (boolean)

2. NewsService.java:
   createPost(Long authorId, String title, String content, String category):
   - Verificar que user.role == "ADMIN" (lanzar ForbiddenException si no)
   getPosts(String category, int page, int size):
   - Si category no es null: filtrar por categoría
   - Ordenado: is_pinned DESC, published_at DESC
   - Paginado
   getById(Long id)

3. NewsController.java:
   GET  /news?category=UPDATE&page=0&size=10  → público (sin autenticación)
   GET  /news/{id}                             → público
   POST /news                                  → solo ADMIN

4. Frontend - NewsComponent (src/app/news/):
   - Lista de noticias con título, categoría, fecha
   - Badge por categoría con colores:
     UPDATE → azul, EVENT → verde, MAINTENANCE → amarillo, ANNOUNCEMENT → púrpura
   - Click en noticia → modal o página de detalle con contenido completo
   - Noticias fijadas (is_pinned) aparecen primero

TESTS:
- Admin crea noticia → OK
- User normal crea noticia → 403 ForbiddenException
- getPosts paginado y ordenado (pinned primero, luego fecha DESC)
- getPosts con category filter → solo retorna esa categoría

Nota sobre admin: un usuario con role = 'ADMIN' puede crear noticias.
Agregar columna role VARCHAR(20) DEFAULT 'USER' a la tabla users (nueva migración si no existe).

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea
```
api/src/main/java/com/codemon/news/
  entity/NewsPost.java
  repository/NewsPostRepository.java
  service/NewsService.java
  controller/NewsController.java
  dto/NewsPostResponse.java
  dto/CreateNewsRequest.java
front/src/app/news/
  pages/news-page/news-page.component.ts + .html + .scss
  components/news-card/news-card.component.ts + .html + .scss
  services/news.service.ts
```

## Errores comunes

- **Olvidar paginación**: con muchas noticias, sin paginación la respuesta puede ser enorme
- **Verificación de rol en BD vs JWT**: verificar `user.role` desde la BD, no solo del token (el token puede estar desactualizado)
- **is_pinned no considerado en el sort**: `ORDER BY is_pinned DESC, published_at DESC` en el query

## Verificación

```bash
ADMIN_TOKEN="eyJ..."
TOKEN="eyJ..."

# Admin crea noticia
curl -X POST http://localhost:8088/news \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Nueva actualización","content":"Agregamos Gold rank!","category":"UPDATE"}'
# PASS: {"id":1,"title":"Nueva actualización","publishedAt":"..."}
# FAIL: 403 → usuario no tiene role=ADMIN en BD (actualizar directamente con SQL)

# Ver noticias (sin auth — público)
curl "http://localhost:8088/news?page=0&size=10"
# PASS: [{"id":1,"title":"Nueva actualización","category":"UPDATE",...}]
# FAIL: 401 → /news GET debe ser público en SecurityConfig

# User normal intenta crear noticia → 403
curl -X POST http://localhost:8088/news \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Hola","content":"test","category":"UPDATE"}'
# PASS: 403 Forbidden
# FAIL: 200 OK → verificación de rol no implementada en NewsService
```

## Dependencias
PASO_S01_01 (autenticación y rol de usuario), PASO_S00_05 (tabla news_posts en BD).
