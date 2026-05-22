# Backlog Master — Codemon TCG

> Generado el: 2026-05-17
> Fuente: Analisis de documentacion del proyecto (36+ archivos .md)
> Metodologia: Epicas → Historias de Usuario → Tarjetas funcionales

> **GitHub Projects v2:** Cada tarjeta tiene un bloque `GITHUB-ISSUE` con metadatos
> para que los agentes MCP puedan crear los issues automáticamente.
> El campo `github-issue: null` se actualiza con el número de issue real una vez creado.
> Ver `.github/project-fields.yml` para el contrato completo de campos.

---

## Indice de Epicas

| ID | Epica | Tarjetas |
|----|-------|---------|
| EPIC-01 | Autenticacion y Seguridad | 4 |
| EPIC-02 | Catalogo y Coleccion de Cartas | 3 |
| EPIC-03 | Constructor de Mazos | 3 |
| EPIC-04 | Motor de Juego | 5 |
| EPIC-05 | Multijugador y Matchmaking | 3 |
| EPIC-06 | Tablero y Experiencia de Juego | 4 |
| EPIC-07 | Tienda y Monetizacion | 3 |
| EPIC-08 | Bot e Inteligencia Artificial | 3 |
| EPIC-09 | Social y Comunidad | 4 |
| EPIC-10 | Infraestructura y DevOps | 5 |
| EPIC-11 | Calidad y Testing | 3 |
| **Total** | | **40** |

---

## EPIC-01 — Autenticacion y Seguridad

Permite que los jugadores creen cuentas seguras, verifiquen su identidad, inicien sesion (incluyendo redes sociales) y mantengan sesion activa con expiracion de tokens. Sin esta epica nadie puede acceder al resto del producto.

---

## Tarjeta: Registro, Login, Logout y Renovacion de Sesion

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-01
hu-ids: [HU-01-01, HU-01-03, HU-01-04, HU-01-05]
sprint: S1
milestone: "S1 — Auth básica"
team: Equipo A
story-points: 13
priority: Alta
labels: [Backend, Frontend, DB, Testing]
branch: feature/auth/hu-01-basica-registro-login
depends-on: []
blocks: [HU-02-01, HU-03-01, HU-04-01]
github-issue: null
-->

**Epica:** EPIC-01 — Autenticacion y Seguridad
**Historias relacionadas:** HU-01-01, HU-01-03, HU-01-04, HU-01-05
**Descripcion:** Implementar el flujo basico de autenticacion local: un visitante puede crear una cuenta con email y password, iniciar sesion recibiendo JWT + refresh token, cerrar sesion revocando el token, y renovar su sesion transparentemente sin reingresar credenciales. Es el primer entregable funcional del proyecto y bloquea a todos los demas.
**Prioridad:** Alta
**Labels:** `Backend` `Frontend` `DB` `Testing`
**Rama sugerida:** `feature/auth-basica-registro-login`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-01-AUTH/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S01_01.md`, `docs/02-planificacion/02_sprints/SPRINTS.md`

**Checklist tecnico:**
- [ ] Entidad `User` con campos `email`, `passwordHash` (BCrypt cost 10), `emailVerified`, `role`, `league`, `skillRating`, `virtualCurrencyBalance`
- [ ] Migraciones Flyway V2-V3 para tablas `email_verifications` y `refresh_tokens`
- [ ] `POST /auth/register` valida email unico + password (>=8 chars, 1 mayuscula, 1 numero); responde 201 o 409
- [ ] `POST /auth/login` devuelve `accessToken` JWT (15 min, HS256) + `refreshToken` UUID (7 dias); persiste refresh en BD
- [ ] `POST /auth/logout` revoca el refresh token (`revoked=true`) atomicamente
- [ ] `POST /auth/refresh` valida refresh no revocado ni expirado; emite nuevo access token
- [ ] `JwtTokenProvider`, `JwtAuthenticationFilter` y `SecurityConfig` con rutas publicas configuradas
- [ ] `HttpJwtInterceptor` Angular: detecta 401 `TOKEN_EXPIRED`, llama refresh, reintenta request original
- [ ] `AuthGuard` y `EmailVerifiedGuard` en Angular para proteger rutas
- [ ] Passwords no expuestas en logs ni en respuestas
- [ ] Tests unitarios `AuthService` + `JwtTokenProvider` (cobertura >= 85%)
- [ ] Tests de integracion con Testcontainers: registro → login → refresh → logout

**Criterios de aceptacion:**
- Registro exitoso devuelve 201; email duplicado devuelve 409 `EMAIL_ALREADY_REGISTERED`
- Login correcto devuelve JWT de 15 min + refresh de 7 dias; credenciales incorrectas devuelven 401 sin distinguir campo
- Logout revoca el refresh; reusar ese refresh devuelve 401
- Interceptor Angular renueva sesion sin mostrar pantalla de login al usuario
- P95 de login < 300 ms; P95 de registro < 500 ms

---

## Tarjeta: Verificacion de Email y 2FA

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-01
hu-ids: [HU-01-02, HU-01-06]
sprint: S8
milestone: "S8 — Tienda + 2FA + métricas"
team: Equipo C
story-points: 10
priority: Alta
labels: [Backend, Frontend, Testing]
branch: feature/auth/hu-01-verificacion-2fa
depends-on: [HU-01-01]
blocks: []
github-issue: null
-->

**Epica:** EPIC-01 — Autenticacion y Seguridad
**Historias relacionadas:** HU-01-02, HU-01-06
**Descripcion:** Tras registrarse, el usuario recibe un codigo de 6 digitos por email para verificar su cuenta. En el flujo de 2FA, cada login requiere ese segundo codigo. Ambos mecanismos usan rate-limit para prevenir fuerza bruta. El mailer se configura con Mailtrap en dev.
**Prioridad:** Alta
**Labels:** `Backend` `Frontend` `Testing`
**Rama sugerida:** `feature/auth-verificacion-2fa`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-01-AUTH/EPIC.md`, `docs/02-planificacion/02_sprints/SPRINTS.md`

**Checklist tecnico:**
- [ ] `EmailService` con `@Async` + SMTP Mailtrap (dev) / SMTP real (prod) via env vars
- [ ] `POST /auth/verify-email` valida codigo BCrypt; devuelve accessToken + refreshToken al verificar
- [ ] Codigo expira a los 30 min (columna `expiresAt` en `email_verifications`); intentos fallidos bloquean 15 min tras 5 errores
- [ ] `POST /auth/resend-code` con rate-limit 1 envio cada 60 s (Bucket4j)
- [ ] Flujo 2FA: `POST /auth/login` con 2FA activo devuelve `requires2FA=true` + `verificationToken` temporal (sin tokens definitivos)
- [ ] `POST /auth/2fa/verify` valida `verificationToken` + codigo; emite accessToken + refreshToken definitivos
- [ ] Bucket4j rate-limit en `verify-email` y `resend-code` (Redis-backed para no perder estado en reinicios)
- [ ] Tests: 5 intentos fallidos → 429; 1 resend antes de 60 s → 429; replay de codigo expirado → 410

**Criterios de aceptacion:**
- Email con codigo llega en < 30 segundos tras el registro
- Codigo correcto establece `emailVerified=true` y retorna tokens
- 5 intentos fallidos consecutivos bloquean 15 min (mensaje `TOO_MANY_ATTEMPTS`)
- Login con 2FA activo no emite tokens definitivos hasta completar segundo factor
- Mailtrap captura emails en dev; variables SMTP definidas para prod

---

## Tarjeta: Login con Google y GitHub (OAuth2)

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-01
hu-ids: [HU-01-07]
sprint: S10
milestone: "S10 — OAuth + Perfil"
team: Equipo C
story-points: 8
priority: Media
labels: [Backend, Frontend, Testing]
branch: feature/auth/hu-01-07-oauth2-social
depends-on: [HU-01-01, HU-01-03]
blocks: []
github-issue: null
-->

**Epica:** EPIC-01 — Autenticacion y Seguridad
**Historias relacionadas:** HU-01-07
**Descripcion:** Los usuarios pueden entrar con su cuenta Google o GitHub. El backend genera su propio JWT (nunca guarda el token del proveedor). Si el email ya existe en la plataforma, se vincula sin duplicar cuenta.
**Prioridad:** Media
**Labels:** `Backend` `Frontend` `Testing`
**Rama sugerida:** `feature/auth-oauth2-social`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-01-AUTH/EPIC.md`, `docs/02-planificacion/02_sprints/SPRINTS.md`

**Checklist tecnico:**
- [ ] Configurar Spring Security OAuth2 Client con Google + GitHub (secrets via env vars `GOOGLE_CLIENT_ID/SECRET`, `GITHUB_CLIENT_ID/SECRET`)
- [ ] `OAuth2AuthenticationSuccessHandler`: genera JWT propio; usuario nuevo → `emailVerified=true`, `passwordHash=null`; usuario existente con mismo email → vincula sin duplicar
- [ ] Callback `/auth/callback?token=...&refreshToken=...` en Angular para recibir tokens
- [ ] Botones "Continuar con Google" y "Continuar con GitHub" en pantalla de login
- [ ] Si GitHub no expone email publico → error claro al usuario
- [ ] Tests con mock server OAuth2 (Testcontainers o WireMock)
- [ ] URIs de redirect registradas en consolas Google/GitHub

**Criterios de aceptacion:**
- Boton social redirige a proveedor; tras autorizar, usuario queda logueado con JWT propio
- Usuario nuevo via OAuth2 tiene `emailVerified=true` y puede usar la plataforma de inmediato
- Usuario existente con mismo email no duplica cuenta
- JWT del proveedor nunca se guarda ni se reusa

---

## Tarjeta: Infraestructura de Seguridad Transversal (CORS, Rate Limit, Secrets)

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-01
hu-ids: [HU-01-01, HU-01-03, HU-01-06]
sprint: S1
milestone: "S1 — Auth básica"
team: Equipo A
story-points: 5
priority: Alta
labels: [Backend, DevOps]
branch: feature/auth/hu-01-seguridad-transversal
depends-on: []
blocks: []
github-issue: null
-->

**Epica:** EPIC-01 — Autenticacion y Seguridad
**Historias relacionadas:** HU-01-01, HU-01-03, HU-01-06
**Descripcion:** Configuracion de CORS, gestion de secrets via variables de entorno, y rate-limit general en endpoints de auth. Habilita que el frontend Angular en `localhost:8088` pueda comunicarse con la API sin bloqueos, y que la plataforma resista ataques de fuerza bruta.
**Prioridad:** Alta
**Labels:** `Backend` `DevOps`
**Rama sugerida:** `feature/auth-seguridad-transversal`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-01-AUTH/EPIC.md`, `docs/07-infraestructura/GATEWAY_LOCAL.md`

**Checklist tecnico:**
- [ ] `SecurityConfig` configura CORS permitiendo `CORS_ALLOWED_ORIGINS` desde env var
- [ ] JWT secret (`codemon.jwt.secret`) >= 32 chars desde env var; nunca hardcodeado
- [ ] Bucket4j bean con almacenamiento Redis (no en memoria) para rate-limit distribuido
- [ ] Rate-limit en endpoints criticos: `POST /auth/login` (10 req/min/IP), `POST /auth/register` (5 req/min/IP)
- [ ] Errores de servidor no exponen stack traces al usuario (`@ControllerAdvice` global)
- [ ] Verificar con `git grep` que no hay secrets hardcodeados en el codigo

**Criterios de aceptacion:**
- CORS permite llamadas desde `http://localhost:8088`; bloquea origins no registrados
- Fuerza bruta de login (> 10 req/min) devuelve 429
- `JWT_SECRET` ausente en `.env` → aplicacion no arranca (falla rapido)
- `git grep -E "(password|secret|token).*=.*['\"]"` no encuentra secrets en codigo fuente

---

## EPIC-02 — Catalogo y Coleccion de Cartas

Permite a los jugadores explorar las 146 cartas del set XY1 y ver que cartas tienen en su coleccion personal. Sin catalogo no se pueden armar mazos ni vender sobres.

---

## Tarjeta: Seed de Cartas y Servicio de Imagenes en MinIO

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-02
hu-ids: [HU-02-01, HU-02-02, HU-02-03]
sprint: S2
milestone: "S2 — Catálogo + Mazos"
team: Equipo A
story-points: 13
priority: Alta
labels: [Backend, DB, DevOps]
branch: feature/catalogo/hu-02-seed-minio
depends-on: []
blocks: [HU-03-01]
github-issue: null
-->

**Epica:** EPIC-02 — Catalogo y Coleccion de Cartas
**Historias relacionadas:** HU-02-01, HU-02-02, HU-02-03
**Descripcion:** Al primer arranque el sistema carga las 146 cartas XY1 en la BD y sube las 292 imagenes (small + large) a MinIO. La entidad `Card` almacena `attacks`, `weaknesses` y `resistances` como JSON. Las imagenes se sirven via Nginx en `localhost:8088/minio/...`.
**Prioridad:** Alta
**Labels:** `Backend` `DB` `DevOps`
**Rama sugerida:** `feature/catalogo-seed-minio`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-02-COLECCION/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S02_01.md`

**Checklist tecnico:**
- [ ] Entidad `Card` con campos: `cardId`, `name`, `supertype`, `subtypes[]`, `types[]`, `rarity`, `hp`, `attacks` (JSON), `weaknesses` (JSON), `resistances` (JSON), `retreatCost`, `imageSmallUrl`, `imageLargeUrl`
- [ ] Indices en `(name)`, `(rarity)`, `(supertype)` para filtros eficientes
- [ ] `CardSeedRunner` idempotente: carga 146 cartas del set XY1 desde `cards.json` solo si `COUNT(*) = 0`
- [ ] `MinioService.uploadFile()`: descarga 292 imagenes de pokemontcg.io y las sube al bucket `codemon-cards`
- [ ] `MINIO_PUBLIC_URL` como prefijo de URLs en BD (`http://localhost:8088/minio/...`)
- [ ] Si MinIO no responde, grid muestra placeholder y registra warning (no falla hard)
- [ ] `SELECT COUNT(*) FROM cards_catalog = 146` verificado en test de integracion

**Criterios de aceptacion:**
- Al iniciar con BD vacia, `CardSeedRunner` carga exactamente 146 cartas
- Las 292 imagenes son accesibles via HTTP 200 desde `localhost:8088/minio/...`
- Seed es idempotente: segunda ejecucion no duplica cartas
- Cache-control 1 ano en respuestas de imagenes desde Nginx

---

## Tarjeta: API y UI del Catalogo de Cartas con Filtros

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-02
hu-ids: [HU-02-01, HU-02-02, HU-02-03]
sprint: S2
milestone: "S2 — Catálogo + Mazos"
team: Equipo A
story-points: 11
priority: Alta
labels: [Backend, Frontend, Testing]
branch: feature/catalogo/hu-02-api-ui-filtros
depends-on: [HU-02-01]
blocks: [HU-03-01]
github-issue: null
-->

**Epica:** EPIC-02 — Catalogo y Coleccion de Cartas
**Historias relacionadas:** HU-02-01, HU-02-02, HU-02-03
**Descripcion:** Endpoint REST paginado para listar y filtrar las 146 cartas, mas vista de detalle. El frontend Angular muestra un grid con filtros combinables (nombre, tipo, rareza, supertype) y la pagina de detalle con todos los atributos de la carta incluyendo ataques y debilidades.
**Prioridad:** Alta
**Labels:** `Backend` `Frontend` `Testing`
**Rama sugerida:** `feature/catalogo-api-ui`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-02-COLECCION/EPIC.md`

**Checklist tecnico:**
- [ ] `GET /cards?page=0&size=20&name=&supertype=&type=&rarity=` con filtros combinables (case-insensitive, substring en nombre)
- [ ] `GET /cards/{cardId}` devuelve todos los atributos incluyendo `attacks[]`, `weaknesses[]`, `resistances[]`, `retreatCost`; 404 si no existe
- [ ] Filtros reflejados en URL de Angular (deep-link via query params)
- [ ] Debounce de 300 ms en el input de busqueda
- [ ] Estado vacio amigable cuando no hay resultados
- [ ] `CardCatalogComponent`: grid paginado con lazy loading de imagenes
- [ ] `CardDetailComponent`: imagen large + todos los atributos en formato legible
- [ ] P95 backend < 250 ms; verificado en test de performance

**Criterios de aceptacion:**
- `GET /cards` retorna `totalElements=146`, `totalPages=8` con `size=20`
- Filtros combinados reducen resultados correctamente; sin resultados muestra mensaje amigable
- UI funciona en Chrome, Firefox y Safari (escritorio + mobile)
- Busqueda por nombre es case-insensitive y soporta substring

---

## Tarjeta: Coleccion Personal y Estadisticas

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-02
hu-ids: [HU-02-04, HU-02-05]
sprint: S8
milestone: "S8 — Tienda + 2FA + métricas"
team: Equipo C
story-points: 8
priority: Media
labels: [Backend, Frontend, DB]
branch: feature/catalogo/hu-02-coleccion-stats
depends-on: [HU-02-01, HU-07-03]
blocks: []
github-issue: null
-->

**Epica:** EPIC-02 — Catalogo y Coleccion de Cartas
**Historias relacionadas:** HU-02-04, HU-02-05
**Descripcion:** Cada jugador puede ver las cartas que posee (con cantidades) y estadisticas de su coleccion (% completado, cartas faltantes por rareza). La coleccion se alimenta de la apertura de sobres (EPIC-07). Usa una vista materializada para el calculo de estadisticas.
**Prioridad:** Media
**Labels:** `Backend` `Frontend` `DB`
**Rama sugerida:** `feature/coleccion-personal-stats`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-02-COLECCION/EPIC.md`

**Checklist tecnico:**
- [ ] Tabla `user_collection` con indice unico `(user_id, card_id)` y campo `quantity`
- [ ] `GET /users/me/collection?page=0&size=20&rarity=&supertype=` con filtros
- [ ] Toggle "ver todo el set" que incluye cartas con `quantity=0`
- [ ] Vista materializada `user_collection_stats` con `totalOwned`, `totalUnique`, `completionPct`, `missingByRarity`
- [ ] `GET /users/me/collection/stats` consume la vista materializada
- [ ] Vista se refresca async (`REFRESH MATERIALIZED VIEW CONCURRENTLY`) al abrir sobre
- [ ] `CollectionViewComponent` Angular con filtros por rareza y barra de progreso
- [ ] Solo el dueno puede ver su coleccion completa con cantidades (403 para otros)

**Criterios de aceptacion:**
- `GET /users/me/collection` devuelve cartas del usuario con su `quantity`
- `GET /users/me/collection/stats` devuelve `completionPct` correcto
- Vista materializada se actualiza al abrir un sobre
- Un usuario no puede ver la coleccion detallada de otro (403)

---

## EPIC-03 — Constructor de Mazos

Permite a los jugadores armar y editar mazos validos de 60 cartas para usar en partidas. Es prerequisito para EPIC-04 (motor) y EPIC-05 (matchmaking).

---

## Tarjeta: CRUD de Mazos y Validador de Reglas TCG

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-03
hu-ids: [HU-03-01, HU-03-03, HU-03-04, HU-03-05, HU-03-06]
sprint: S2
milestone: "S2 — Catálogo + Mazos"
team: Equipo A
story-points: 15
priority: Alta
labels: [Backend, DB, Testing]
branch: feature/mazos/hu-03-crud-validador
depends-on: [HU-02-01]
blocks: [HU-04-01, HU-05-01]
github-issue: null
-->

**Epica:** EPIC-03 — Constructor de Mazos
**Historias relacionadas:** HU-03-01, HU-03-03, HU-03-04, HU-03-05, HU-03-06
**Descripcion:** Backend completo de gestion de mazos: crear, leer, actualizar, eliminar, marcar favorito y copiar starters. El `DeckValidationService` implementa las 5 reglas TCG en Java puro (sin BD) y se testea con cobertura >= 90%.
**Prioridad:** Alta
**Labels:** `Backend` `DB` `Testing`
**Rama sugerida:** `feature/mazos-crud-validador`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-03-MAZOS/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S02_01.md`

**Checklist tecnico:**
- [ ] Entidades `Deck` (con `ownerId`, `name`, `isFavorite`, `isStarter`) y `DeckCard` (`deckId`, `cardId`, `quantity`)
- [ ] `POST /decks` crea mazo vacio; limite 20 mazos por usuario → 422 al exceder
- [ ] `PUT /decks/{id}` actualiza cartas; verifica pertenencia (`403` si no es dueno)
- [ ] `DELETE /decks/{id}` borra con confirmacion; bloquea borrado de starters del sistema → 422
- [ ] `PUT /decks/{id}/favorite` toggle; deselecciona automaticamente el favorito anterior
- [ ] `GET /decks/starters` lista 3 mazos del sistema; `POST /decks/starters/{id}/copy` clona al usuario
- [ ] Seed de 3 mazos starter en `ApplicationRunner` si no existen
- [ ] `DeckValidationService` puro Java (sin BD): R-DECK-01 (60 cartas), R-DECK-02 (1+ Basico), R-DECK-03 (max 4 copias excepto Energia Basica), R-DECK-04 (max 4 Energias Especiales), R-DECK-05 (max 1 ACE SPEC)
- [ ] `POST /decks/{id}/validate` devuelve lista COMPLETA de errores (no solo el primero)
- [ ] Tests unitarios `DeckValidationService` >= 90% cobertura con casos validos y casos de error por cada regla
- [ ] Tests integracion: ver mazo ajeno → 403; eliminar starter → 422; limite 20 mazos → 422

**Criterios de aceptacion:**
- CRUD completo de mazos funcionando end-to-end
- Las 5 reglas TCG validan correctamente (casos felices y de error)
- Solo el dueno puede modificar o borrar su mazo
- 3 mazos starter disponibles y copiables
- `DeckValidationService` cobertura >= 90% en JaCoCo

---

## Tarjeta: UI Deck Builder con Drag and Drop

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-03
hu-ids: [HU-03-02, HU-03-03]
sprint: S2
milestone: "S2 — Catálogo + Mazos"
team: Equipo B
story-points: 13
priority: Alta
labels: [Frontend, Testing]
branch: feature/mazos/hu-03-deck-builder-ui
depends-on: [HU-03-01, HU-02-01]
blocks: []
github-issue: null
-->

**Epica:** EPIC-03 — Constructor de Mazos
**Historias relacionadas:** HU-03-02, HU-03-03
**Descripcion:** Componente Angular del constructor de mazos: catalogo a la izquierda, mazo a la derecha, drag and drop con `@angular/cdk/drag-drop`. La validacion TCG corre en tiempo real y muestra errores especificos. Los cambios persisten al backend con debounce de 1 segundo.
**Prioridad:** Alta
**Labels:** `Frontend` `Testing`
**Rama sugerida:** `feature/deck-builder-ui`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-03-MAZOS/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S02_04.md`

**Checklist tecnico:**
- [ ] `DeckBuilderComponent` con layout de dos columnas: catalogo (filtrable) a la izquierda, mazo a la derecha
- [ ] Integrar `@angular/cdk/drag-drop` para arrastrar cartas del catalogo al mazo y viceversa
- [ ] Drag de carta al mazo: `quantity++`; drop fuera: `quantity--`
- [ ] Debounce de 1 s en `PUT /decks/{id}` al detectar cambios
- [ ] Validacion TCG en tiempo real (llamada a `POST /decks/{id}/validate`): mostrar cada error con la regla violada
- [ ] Contador visible de cartas totales (X/60)
- [ ] Feedback visual de drag: cursor grabbing, sombra en zona de drop
- [ ] Drag & drop verificado en Chrome, Firefox, Safari (escritorio + tablet)

**Criterios de aceptacion:**
- Arrastrar una carta al mazo la agrega; arrastrarla de vuelta la quita
- Los errores de validacion aparecen en tiempo real con el nombre de la regla violada
- Los cambios se guardan automaticamente (debounce 1 s) sin boton de "guardar"
- Drop invalido (mazo ya tiene 4 copias) se rechaza visualmente

---

## Tarjeta: Seleccion de Mazo en Lobby y Preseleccion de Favorito

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-03
hu-ids: [HU-03-05, HU-06-04]
sprint: S6
milestone: "S6 — Tablero pulido + Lobby"
team: Equipo B
story-points: 5
priority: Media
labels: [Frontend, Backend]
branch: feature/mazos/hu-03-selector-lobby
depends-on: [HU-03-01, HU-06-04]
blocks: []
github-issue: null
-->

**Epica:** EPIC-03 — Constructor de Mazos
**Historias relacionadas:** HU-03-05, HU-06-04
**Descripcion:** En el lobby de juego, el selector de mazo preselecciona el favorito del jugador. Si no tiene favorito, muestra el primero. La validacion bloquea entrar a la cola con un mazo invalido.
**Prioridad:** Media
**Labels:** `Frontend` `Backend`
**Rama sugerida:** `feature/mazo-selector-lobby`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-03-MAZOS/EPIC.md`, `docs/02-planificacion/03_epicas/EPIC-06-TABLERO/EPIC.md`

**Checklist tecnico:**
- [ ] `GET /decks` incluye campo `isFavorite` y `isValid` (resultado de la ultima validacion)
- [ ] Selector de mazo en lobby ordena por `isFavorite DESC` para preseleccionar el favorito
- [ ] Boton "Entrar a cola" deshabilitado si el mazo seleccionado no es valido (tooltip explicativo)
- [ ] Indicador visual de mazo favorito (estrella) en la lista de mazos del perfil

**Criterios de aceptacion:**
- Lobby preselecciona el mazo marcado como favorito
- No se puede iniciar una partida con un mazo invalido (boton deshabilitado con razon)
- La estrella de favorito se actualiza inmediatamente en la UI al togglear

---

## EPIC-04 — Motor de Juego

Implementa todas las reglas del TCG XY1: setup de partida, turnos (robar, jugar Pokemon, adjuntar energia, evolucionar, atacar, retirar), condiciones de victoria y el calculo de dano. Es la columna vertebral del producto.

---

## Tarjeta: Andamiaje del Motor y Setup de Partida

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-04
hu-ids: [HU-04-01, HU-04-02]
sprint: S3
milestone: "S3 — Motor: setup + turnos"
team: Equipo A
story-points: 10
priority: Alta
labels: [Backend, Testing]
branch: feature/motor/hu-04-andamiaje-setup
depends-on: [HU-03-01]
blocks: [HU-04-03, HU-04-06]
github-issue: null
-->

**Epica:** EPIC-04 — Motor de Juego
**Historias relacionadas:** HU-04-01, HU-04-02
**Descripcion:** Estructura de clases del motor (State Machine, GameContext, GameState), la fase de Setup (barajado con SecureRandom, mano de 7 cartas, mulligan completo, 6 premios, coin flip) y DrawPhaseState. La invariante `deck + hand + prizes == 60` debe verificarse en tests.
**Prioridad:** Alta
**Labels:** `Backend` `Testing`
**Rama sugerida:** `feature/motor-andamiaje-setup`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-04-MOTOR/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S03_01.md`

**Checklist tecnico:**
- [ ] Interfaces `GameState` con metodos `onEnter()`, `onExit()`, `processAction()`, `getAvailableActions()`
- [ ] `GameContext` como facade que delega al estado actual; mantiene `currentState` y transiciona
- [ ] `SetupState`: barajado con `SecureRandom`, mano de 7 cartas, mulligan Caso A y B, 6 premios, coin flip para primer turno
- [ ] Invariante verificada en tests: `deck.size() + hand.size() + prizes.size() == 60`
- [ ] `getState()` sanitiza: `hand` rival = null, `deck` ambos = null (solo `deckSize`), `prizes` = null (solo `prizesCount`)
- [ ] `DrawPhaseState`: verifica mazo vacio ANTES del robo (trigger de R-WIN-02), mueve primera carta a mano, incrementa `turnsInPlay` de todos los Pokemon, resetea `evolvedThisTurn=false`
- [ ] `POST /games` crea partida; `GET /games/{id}/state` devuelve estado sanitizado
- [ ] Tests cobertura `SetupState` >= 90%; tests parametrizados para ambos casos de mulligan

**Criterios de aceptacion:**
- Partida creada via API arranca con setup correcto (mano de 7, 6 premios, coin flip)
- Mulligan Caso B: el rival con Basico roba `mulliganCount - 1` cartas extra
- `GET /games/{id}/state` como player1 no expone la mano de player2
- `deck + hand + prizes == 60` verificado con test de integracion

---

## Tarjeta: Main Phase — Acciones de Turno

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-04
hu-ids: [HU-04-03, HU-04-04, HU-04-05, HU-04-07]
sprint: S3
milestone: "S3 — Motor: setup + turnos"
team: Equipo A
story-points: 12
priority: Alta
labels: [Backend, Testing]
branch: feature/motor/hu-04-main-phase
depends-on: [HU-04-01]
blocks: [HU-04-06]
github-issue: null
-->

**Epica:** EPIC-04 — Motor de Juego
**Historias relacionadas:** HU-04-03, HU-04-04, HU-04-05, HU-04-07
**Descripcion:** `MainPhaseState` implementa las 6 acciones de turno: jugar Pokemon Basico al banco, adjuntar energia (max 1 por turno, DCE cuenta como 2 Colorless), evolucionar Pokemon (con restricciones de `turnsInPlay` y Mega Evolucion), y retirar el activo pagando retreat cost.
**Prioridad:** Alta
**Labels:** `Backend` `Testing`
**Rama sugerida:** `feature/motor-main-phase`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-04-MOTOR/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S03_05.md`

**Checklist tecnico:**
- [ ] `PLAY_BASIC_POKEMON`: rechaza Stage 1 directo; banco lleno (5) → 422 `BENCH_FULL`; asigna `instanceId` UUID; evento `POKEMON_PLAYED`
- [ ] `ATTACH_ENERGY`: flag `energyAttachedThisTurn`; Double Colorless = 2 Colorless; segunda energia → 422 `ENERGY_ALREADY_ATTACHED`; evento `ENERGY_ATTACHED`
- [ ] `EVOLVE_POKEMON`: valida `turnsInPlay >= 1` y `!evolvedThisTurn`; cura condiciones especiales (dano permanece); Mega Evolucion → `transitionTo(EndPhaseState)`; conserva tools y energias
- [ ] `RETREAT`: bloqueado si activo esta ASLEEP o PARALYZED; max 1 por turno (`retreatedThisTurn`); cura condiciones al retirar; dano NO cambia; descarta energias segun `retreatCost`
- [ ] Validacion de accion: turno del jugador correcto; accion permitida en el estado actual
- [ ] Evento `END_TURN` para cerrar la Main Phase
- [ ] Tests unitarios por cada accion con casos validos, invalidos y edge cases (banco lleno, evolucion invalida, etc.)

**Criterios de aceptacion:**
- Jugar Stage 1 directamente (sin Basico) devuelve error claro
- Segunda energia en el mismo turno devuelve 422 `ENERGY_ALREADY_ATTACHED`
- Mega Evolucion termina el turno inmediatamente
- Retirar mientras ASLEEP o PARALYZED es rechazado
- Acciones de otro jugador en turno ajeno son rechazadas

---

## Tarjeta: AttackPipeline, DamageCalculator y Condiciones de Status

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-04
hu-ids: [HU-04-06, HU-04-07]
sprint: S4
milestone: "S4 — Motor: combate"
team: Equipo A
story-points: 24
priority: Alta
labels: [Backend, Testing]
branch: feature/motor/hu-04-attack-pipeline
depends-on: [HU-04-03, HU-04-04, HU-04-05]
blocks: [HU-04-08, HU-04-09]
github-issue: null
-->

**Epica:** EPIC-04 — Motor de Juego
**Historias relacionadas:** HU-04-06, HU-04-07
**Descripcion:** El corazon del combate TCG: `AttackPipeline` con 9 handlers en orden estricto, `DamageCalculator` (weakness 2x, resistance -20, minimo 0), y `StatusEffectManager` (POISONED, BURNED, PARALYZED, CONFUSED, ASLEEP). Ambos devs de Equipo A trabajan juntos en esta tarea (21 SP, no dividir).
**Prioridad:** Alta
**Labels:** `Backend` `Testing`
**Rama sugerida:** `feature/motor-attack-pipeline`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-04-MOTOR/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S04_01.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S04_02.md`

**Checklist tecnico:**
- [ ] `AttackPipeline` con 9 handlers en orden: Validate → CalcBase → AttackerFX → Weakness → Resistance → DefenderFX → DealDamage → ExecuteEffect → CheckKO
- [ ] `DamageCalculator`: formula `(base + bonus_atacante) * weakness - resistance - reduccion_defensor`, minimo 0; dano directo omite weakness/resistance; dano a banca nunca aplica modificadores
- [ ] Verificacion de energias requeridas: tipos especificos antes de Colorless
- [ ] `StatusEffectManager`: POISONED (10 dano entre turnos), BURNED (20 + coin flip para curar), PARALYZED (pierde turno + se cura al final), CONFUSED (30 dano a si mismo en coin flip), ASLEEP (coin flip para despertar)
- [ ] Confusion: el 30 dano se aplica SIN usar la weakness del propio Pokemon
- [ ] Primer turno del jugador 1: `firstTurnAttackBlocked=true`
- [ ] `EndPhaseState`: aplica efectos de status entre turnos, transiciona al `DrawPhaseState` del rival
- [ ] `DamageCalculator` >= 90% cobertura, `StatusEffectManager` >= 90%, `AttackPipeline` >= 90%
- [ ] Snapshot async en `game_state_snapshots` tras cada `ATTACK`, `KO`, `STATUS_APPLIED`

**Criterios de aceptacion:**
- Los 9 handlers se ejecutan en orden estricto y el resultado es correcto
- Weakness duplica el dano; resistance resta 20; minimo de dano es 0
- Confusion aplica 30 dano directo al propio Pokemon (sin weakness)
- Jugador 1 no puede atacar en su primer turno
- Cobertura >= 90% en los 3 componentes criticos

---

## Tarjeta: Condiciones de Victoria y Fin de Partida

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-04
hu-ids: [HU-04-08, HU-04-09]
sprint: S5
milestone: "S5 — PvE jugable"
team: Equipo A
story-points: 8
priority: Alta
labels: [Backend, DB, Testing]
branch: feature/motor/hu-04-victoria-fin-partida
depends-on: [HU-04-06]
blocks: [HU-08-01, HU-05-01]
github-issue: null
-->

**Epica:** EPIC-04 — Motor de Juego
**Historias relacionadas:** HU-04-08, HU-04-09
**Descripcion:** `VictoryConditionChecker` evalua las 3 condiciones de victoria (ultimos premios, mazo vacio, sin Pokemon), maneja muerte subita, actualiza ELO/liga solo en partidas QUEUE, y acredita coins a ambos jugadores (ganador +50, perdedor +10) en la misma transaccion que cierra la partida.
**Prioridad:** Alta
**Labels:** `Backend` `DB` `Testing`
**Rama sugerida:** `feature/motor-victoria-fin-partida`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-04-MOTOR/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S05_01.md`

**Checklist tecnico:**
- [ ] `VictoryConditionChecker.declareWinner()` evalua: R-WIN-01 (ultimo premio), R-WIN-02 (mazo vacio al inicio de turno), R-WIN-03 (sin Pokemon tras KO sin reemplazo)
- [ ] Ambos cumplen condicion simultaneamente → `SUDDEN_DEATH_START` (1 solo premio, no empate)
- [ ] KO normal → 1 premio; KO de EX o MEGA → 2 premios; carta KO + adjuntos van al descarte del dueno
- [ ] `GAME_OVER` event con `reason` (PRIZES / DECK_EMPTY / NO_POKEMON) emitido via STOMP
- [ ] ELO (`new = old + K*(result - expected)`) actualizado SOLO si `matchType=QUEUE`
- [ ] `wins/losses` actualizados en `users`; `REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard`
- [ ] `walletService.creditCoins(+50, reason=MATCH_REWARD)` al ganador y `creditCoins(+10)` al perdedor en partidas QUEUE/ROOM (skip en PVE); ambas operaciones en la misma transaccion que cambia el estado a FINISHED
- [ ] `VictoryConditionChecker` cobertura >= 90%
- [ ] Test E2E: partida PvE completa termina en `GAME_OVER` sin error 500

**Criterios de aceptacion:**
- Las 3 condiciones de victoria se detectan correctamente
- ELO se actualiza solo en partidas QUEUE
- Coins acreditados en la misma transaccion que cierra la partida; si falla, la partida no se cierra
- Partidas QUEUE y ROOM generan exactamente 2 filas en `wallet_transactions` al finalizar

---

## Tarjeta: GameEngine Facade y Exposicion via WebSocket STOMP

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-04
hu-ids: [HU-04-06, HU-04-09, HU-05-05]
sprint: S5
milestone: "S5 — PvE jugable"
team: Equipo A
story-points: 10
priority: Alta
labels: [Backend, Testing]
branch: feature/motor/hu-04-gameengine-websocket
depends-on: [HU-04-09]
blocks: [HU-05-05, HU-06-01]
github-issue: null
-->

**Epica:** EPIC-04 — Motor de Juego
**Historias relacionadas:** HU-04-06, HU-04-09, HU-05-05
**Descripcion:** `GameEngine` como facade que recibe acciones REST (`POST /games/{id}/action`) y las procesa en el estado actual, emitiendo eventos STOMP al topic publico y a colas privadas por usuario. Incluye `WebSocketConfig` con STOMP sobre SockJS.
**Prioridad:** Alta
**Labels:** `Backend` `Testing`
**Rama sugerida:** `feature/motor-gameengine-websocket`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-04-MOTOR/EPIC.md`, `docs/05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md`

**Checklist tecnico:**
- [ ] `WebSocketConfig` con STOMP sobre SockJS; endpoint `/ws`; topics `/topic/game/{gameId}` (publicos) y `/user/queue/game/{gameId}` (privados)
- [ ] `GameEngine.processAction()` delega al estado actual; concurrencia controlada (`synchronized` o `ReentrantLock` por `gameId`)
- [ ] Eventos publicos: `TURN_START`, `ATTACK`, `DAMAGE`, `KO`, `PRIZE_TAKEN`, `STATUS_APPLIED`, `GAME_OVER`, `SUDDEN_DEATH_START`, `POKEMON_PLAYED`, `ENERGY_ATTACHED`
- [ ] Eventos privados (solo al dueno): `CARD_DRAWN` con la carta robada
- [ ] `POST /games/{id}/action` valida autenticacion y pertenencia a la partida antes de delegar
- [ ] Test de concurrencia: 10 acciones simultaneas en la misma partida no producen estado inconsistente

**Criterios de aceptacion:**
- Acciones recibidas via REST se procesan y los eventos STOMP llegan al frontend en < 200 ms
- `CARD_DRAWN` solo llega al jugador que roba (no al rival)
- 10 acciones concurrentes no producen race condition en el estado de la partida

---

## EPIC-05 — Multijugador y Matchmaking

Permite que dos jugadores se enfrenten online via sala privada con codigo o cola ranked, con emparejamiento por ELO y partida en tiempo real via WebSocket.

---

## Tarjeta: Salas Privadas con Codigo

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-05
hu-ids: [HU-05-01, HU-05-02]
sprint: S7
milestone: "S7 — PvP en tiempo real"
team: Equipo C
story-points: 8
priority: Alta
labels: [Backend, Frontend, Testing]
branch: feature/multijugador/hu-05-salas-privadas
depends-on: [HU-04-09]
blocks: []
github-issue: null
-->

**Epica:** EPIC-05 — Multijugador y Matchmaking
**Historias relacionadas:** HU-05-01, HU-05-02
**Descripcion:** Un jugador crea una sala con un codigo alfanumerico de 6 caracteres y lo comparte. Al unirse el segundo jugador, se crea automaticamente el Game y ambos reciben el `gameId` via WebSocket. Las salas expiradas se limpian cada minuto.
**Prioridad:** Alta
**Labels:** `Backend` `Frontend` `Testing`
**Rama sugerida:** `feature/multijugador-salas-privadas`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-05-MULTIJUGADOR/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S07_01.md`

**Checklist tecnico:**
- [ ] `POST /games/rooms/create` genera codigo `[A-Z0-9]` de 6 chars; reintenta hasta 5 veces ante colision
- [ ] Sala expira en 10 min sin segundo jugador (campo `expiresAt`)
- [ ] `POST /games/rooms/join` con `code` valido y no expirado crea el Game (transaccional, evita doble Game con 2 joins simultaneos)
- [ ] `DELETE /games/rooms/{id}` solo para el creador
- [ ] `@Scheduled(fixedRate=60000)` limpia salas expiradas
- [ ] STOMP emite `ROOM_FULL` a `/topic/room/{code}` con `gameId` cuando llega el segundo jugador
- [ ] Codigo expirado → 410; inexistente → 404
- [ ] UI muestra el codigo generado y "Esperando rival..." con countdown
- [ ] Test transaccional: 2 joins simultaneos no crean 2 Games

**Criterios de aceptacion:**
- Sala creada tiene codigo unico de 6 chars `[A-Z0-9]`
- Al unirse el segundo jugador ambos reciben `gameId` via WebSocket inmediatamente
- Salas de mas de 10 min sin segundo jugador son eliminadas por el scheduler
- Dos jugadores uniendo simultaneamente no duplican el Game

---

## Tarjeta: Cola Ranked con Matchmaking ELO

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-05
hu-ids: [HU-05-03, HU-05-04]
sprint: S7
milestone: "S7 — PvP en tiempo real"
team: Equipo C
story-points: 10
priority: Alta
labels: [Backend, Frontend, Testing]
branch: feature/multijugador/hu-05-cola-ranked
depends-on: [HU-05-01]
blocks: []
github-issue: null
-->

**Epica:** EPIC-05 — Multijugador y Matchmaking
**Historias relacionadas:** HU-05-03, HU-05-04
**Descripcion:** Los jugadores entran a una cola Redis (sorted set por skillRating). El algoritmo de ventana expande el rango de busqueda (+50 cada 5 segundos) hasta encontrar un rival. Lock distribuido Redis evita doble match entre instancias. Post-partida se recalcula el ELO.
**Prioridad:** Alta
**Labels:** `Backend` `Frontend` `Testing`
**Rama sugerida:** `feature/matchmaking-cola-ranked`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-05-MULTIJUGADOR/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S07_02.md`

**Checklist tecnico:**
- [ ] `POST /matchmaking/queue/join` con `deckId` valido; agrega al sorted set Redis con score = `skillRating` (default 1000 si sin rating)
- [ ] `DELETE /matchmaking/queue/leave`; error 409 si ya hay match formado
- [ ] Algoritmo de ventana: ±100 inicial, expande +50 cada 5 s, max ±300
- [ ] Timeout 30 s sin match → emite `QUEUE_TIMEOUT` a `/user/{userId}/queue/matchmaking`
- [ ] Match encontrado → emite `MATCH_FOUND` con `gameId` y `opponentUsername`
- [ ] Lock Redis distribuido (`SET NX EX 5`) para evitar doble match entre instancias
- [ ] Calculo ELO: `new = old + K * (result - expected)` post-partida QUEUE
- [ ] Usuario ya en cola → 409 `ALREADY_IN_QUEUE`
- [ ] UI con timer de busqueda y boton "Cancelar busqueda"
- [ ] Test: 2 usuarios con rating cercano → match en < 3 s
- [ ] Test de race condition: 2 instancias del backend no generan doble match (Testcontainers + 2 nodos)

**Criterios de aceptacion:**
- Entrar a la cola con rating similar resulta en match en < 3 s
- `QUEUE_TIMEOUT` emitido a los 30 s si no hay match
- Doble match imposible con 2 instancias del backend concurrentes
- ELO solo se actualiza en partidas `matchType=QUEUE`

---

## Tarjeta: Reconexion y Sincronizacion de Estado WebSocket

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-05
hu-ids: [HU-05-05]
sprint: S7
milestone: "S7 — PvP en tiempo real"
team: Equipo B
story-points: 5
priority: Alta
labels: [Frontend, Testing]
branch: feature/multijugador/hu-05-reconexion-ws
depends-on: [HU-05-01, HU-04-09]
blocks: [HU-06-01]
github-issue: null
-->

**Epica:** EPIC-05 — Multijugador y Matchmaking
**Historias relacionadas:** HU-05-05
**Descripcion:** El cliente Angular se suscribe a STOMP y maneja reconexion automatica. Si el usuario recarga la pagina o pierde conexion, recupera el estado completo via `GET /games/{id}/state` y resubscribe a los topics. `ngOnDestroy` desconecta sin memory leaks.
**Prioridad:** Alta
**Labels:** `Frontend` `Testing`
**Rama sugerida:** `feature/websocket-reconexion-sync`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-05-MULTIJUGADOR/EPIC.md`, `docs/02-planificacion/03_epicas/EPIC-06-TABLERO/EPIC.md`

**Checklist tecnico:**
- [ ] `WebSocketService` Angular: conexion STOMP sobre SockJS a `/ws`
- [ ] Suscripcion a `/topic/game/{gameId}` (eventos publicos) y `/user/queue/game` (privados)
- [ ] Suscripcion a `/user/{userId}/queue/matchmaking` (MATCH_FOUND, QUEUE_TIMEOUT)
- [ ] Al reconectar (deteccion de desconexion): `GET /games/{id}/state` + resubscribe a todos los topics
- [ ] `ngOnDestroy` desconecta el cliente STOMP y cancela todas las subscripciones
- [ ] Validado en DevTools: sin event listeners colgados tras navegar fuera del tablero
- [ ] Test de carga: 50 clientes WebSocket concurrentes sin degradacion (Gatling o k6)

**Criterios de aceptacion:**
- Recargar el browser durante una partida recupera el estado correctamente
- `ngOnDestroy` elimina todas las subscripciones (verificado en DevTools)
- 50 partidas WebSocket concurrentes sin caida del servidor

---

## EPIC-06 — Tablero y Experiencia de Juego

Convierte el motor de juego en algo jugable: zonas del tablero visuales, drag and drop de cartas, animaciones de dano y KO, lobby con seleccion de modo, chat en partida y layout responsive.

---

## Tarjeta: Tablero de Juego con Zonas y Estado en Tiempo Real

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-06
hu-ids: [HU-06-01]
sprint: S5
milestone: "S5 — PvE jugable"
team: Equipo B
story-points: 5
priority: Alta
labels: [Frontend, Testing]
branch: feature/tablero/hu-06-tablero-zonas
depends-on: [HU-04-09, HU-05-05]
blocks: [HU-06-02, HU-06-03]
github-issue: null
-->

**Epica:** EPIC-06 — Tablero y Experiencia de Juego
**Historias relacionadas:** HU-06-01
**Descripcion:** `GameBoardComponent` Angular con todas las zonas del TCG: activo y banca del oponente (dorsos), activo y banca propios (imagenes reales), mano, premios, mazo y descarte. El estado se actualiza SOLO via eventos WebSocket (nunca optimista).
**Prioridad:** Alta
**Labels:** `Frontend` `Testing`
**Rama sugerida:** `feature/tablero-zonas-estado`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-06-TABLERO/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S05_04.md`

**Checklist tecnico:**
- [ ] `GameBoardComponent` con zonas: zona oponente (activo + banca como dorsos, contadores de mano/mazo/premios), zona propia (activo + banca con imagenes, mano visible, premios boca abajo)
- [ ] HP de cada Pokemon visible en numero y barra de progreso
- [ ] Iconos de condicion (POISONED llama, BURNED fuego, PARALYZED rayos, CONFUSED espiral, ASLEEP luna) sobre el Pokemon afectado
- [ ] Estado renderizado desde evento WebSocket; nunca se modifica localmente antes de confirmacion del servidor
- [ ] Contraste AA en HP y condiciones (accesibilidad)
- [ ] Render < 16 ms por frame (sin layout thrashing; usar trackBy en `*ngFor`)

**Criterios de aceptacion:**
- Todas las zonas del tablero son visibles y distinguibles
- HP y condiciones se actualizan en tiempo real al recibir eventos WebSocket
- La mano del oponente se muestra como dorsos (sin revelar cartas)
- Contraste AA en todos los elementos de informacion critica

---

## Tarjeta: Drag and Drop de Cartas en el Tablero

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-06
hu-ids: [HU-06-02]
sprint: S6
milestone: "S6 — Tablero pulido + Lobby"
team: Equipo B
story-points: 8
priority: Alta
labels: [Frontend, Testing]
branch: feature/tablero/hu-06-drag-drop
depends-on: [HU-06-01]
blocks: []
github-issue: null
-->

**Epica:** EPIC-06 — Tablero y Experiencia de Juego
**Historias relacionadas:** HU-06-02
**Descripcion:** Drag de cartas desde la mano del jugador al tablero: energia al activo/banca (`ATTACH_ENERGY`), Pokemon Basico al banco (`PLAY_BASIC_POKEMON`), Stage 1/2 sobre el Basico correcto (`EVOLVE_POKEMON`). Drop invalido hace rebotar la carta a la mano.
**Prioridad:** Alta
**Labels:** `Frontend` `Testing`
**Rama sugerida:** `feature/tablero-drag-drop`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-06-TABLERO/EPIC.md`

**Checklist tecnico:**
- [ ] `@angular/cdk/drag-drop` en `GameBoardComponent`
- [ ] Drag de energia a activo/banca → `POST /games/{id}/action {type: ATTACH_ENERGY}`
- [ ] Drag de Pokemon Basico a banco → `POST /games/{id}/action {type: PLAY_BASIC_POKEMON}`
- [ ] Drag de Stage 1/2 sobre el Basico compatible → `POST /games/{id}/action {type: EVOLVE_POKEMON}`
- [ ] Drop invalido: carta anima de vuelta a la mano (bounce animation CSS)
- [ ] La UI espera confirmacion via WebSocket antes de actualizar el estado (no optimista)
- [ ] Feedback visual durante drag: cursor grabbing, zona de drop resaltada
- [ ] Verificado en Chrome, Firefox, Safari escritorio y tablet (touch events)

**Criterios de aceptacion:**
- Drag y drop de energia, Pokemon Basico y evolucion funcionan correctamente
- Drop invalido no cambia el estado y la carta regresa visualmente a la mano
- Funcionamiento verificado en 3 browsers + tablet con touch

---

## Tarjeta: Animaciones, Lobby con 3 Modos y Chat de Partida

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-06
hu-ids: [HU-06-03, HU-06-04, HU-06-05]
sprint: S6
milestone: "S6 — Tablero pulido + Lobby"
team: Equipo B
story-points: 13
priority: Media
labels: [Frontend]
branch: feature/tablero/hu-06-animaciones-lobby-chat
depends-on: [HU-06-01]
blocks: [HU-08-04]
github-issue: null
-->

**Epica:** EPIC-06 — Tablero y Experiencia de Juego
**Historias relacionadas:** HU-06-03, HU-06-04, HU-06-05
**Descripcion:** Animaciones de dano (shake + numero flotante), KO (fade out) y status (icono pulsante). Lobby con 3 tabs (PvE, Ranked, Sala privada). `ChatWindowComponent` sanitizado con rate limit visual y distincion entre mensajes de usuario, bot y sistema.
**Prioridad:** Media
**Labels:** `Frontend`
**Rama sugerida:** `feature/tablero-animaciones-lobby-chat`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-06-TABLERO/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S06_01.md`

**Checklist tecnico:**
- [ ] Animaciones via CSS transforms (GPU, no JS layout): shake en dano + numero flotante, fade out en KO, icono pulsante en status
- [ ] Soporte `prefers-reduced-motion` para deshabilitar animaciones
- [ ] Toast notifications: "Tomaste 1 premio", "Es tu turno", "Confusion: 30 a ti mismo"
- [ ] Toggle de sonido en settings (opcional)
- [ ] `LobbyComponent` con 3 tabs: PvE (selector dificultad), Ranked (selector mazo + entrar cola), Sala privada (input codigo + crear)
- [ ] Timer de espera visible en cola ranked
- [ ] `ChatWindowComponent`: scroll automatico al ultimo mensaje, tipos USER/BOT/SYSTEM con colores distintos
- [ ] Sanitizacion de HTML en mensajes de chat (Angular DomSanitizer)
- [ ] Rate limit visual: input bloqueado 1 s post-envio; limite 100 caracteres
- [ ] Input deshabilitado cuando la partida esta `FINISHED`

**Criterios de aceptacion:**
- Animaciones de dano y KO se ven fluidas sin afectar el framerate
- Lobby permite navegar entre los 3 modos correctamente
- Chat muestra mensajes de usuario, bot y sistema con estilos diferenciados
- Mensajes con HTML malicioso se sanitizan correctamente

---

## Tarjeta: Responsive Mobile, Tablet y Desktop

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-06
hu-ids: [HU-06-06]
sprint: S11
milestone: "S11 — Pulido + bots + E2E"
team: Equipo B
story-points: 5
priority: Media
labels: [Frontend, Testing]
branch: feature/tablero/hu-06-responsive
depends-on: [HU-06-01]
blocks: []
github-issue: null
-->

**Epica:** EPIC-06 — Tablero y Experiencia de Juego
**Historias relacionadas:** HU-06-06
**Descripcion:** El tablero y todas las pantallas se adaptan a mobile (>= 360 px), tablet y desktop usando Tailwind CSS (utilidades `grid`/`flex` + prefijos responsive `sm:`/`md:`/`lg:`). En mobile el tablero reorganiza las zonas en stack vertical. Drag and drop funciona con touch. Lighthouse mobile >= 80 Performance / >= 90 Accessibility.
**Prioridad:** Media
**Labels:** `Frontend` `Testing`
**Rama sugerida:** `feature/tablero-responsive`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-06-TABLERO/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S11_07.md`

**Checklist tecnico:**
- [ ] Layout responsive con utilidades Tailwind y prefijos `sm:`/`md:`/`lg:`/`xl:` (breakpoints 640/768/1024/1280)
- [ ] Tablero: layout horizontal en desktop, stack vertical en mobile
- [ ] Sin scroll horizontal en pantallas >= 360 px
- [ ] Touch events para drag and drop en tablet (CDK soporta pointer events)
- [ ] Lazy loading de rutas no criticas en Angular (reducir bundle inicial)
- [ ] First Contentful Paint < 2 s en 3G (simulacion DevTools)
- [ ] Lighthouse mobile: Performance >= 80, Accessibility >= 90
- [ ] Verificado en Chrome mobile DevTools + tablet real

**Criterios de aceptacion:**
- La app es usable en pantallas desde 360 px sin scroll horizontal
- Drag and drop funciona con touch en tablet
- Lighthouse mobile pasa los thresholds (Performance >= 80, Accessibility >= 90)

---

## EPIC-07 — Tienda y Monetizacion

Permite a los jugadores comprar Codemon Coins con Mercado Pago y usarlas para comprar y abrir sobres de cartas, alimentando la coleccion. Incluye wallet, historial de pagos y cooldown de 24 h entre sobres.

---

## Tarjeta: Integracion Mercado Pago y Sistema de Wallet

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-07
hu-ids: [HU-07-01, HU-07-02, HU-07-06]
sprint: S8
milestone: "S8 — Tienda + 2FA + métricas"
team: Equipo C
story-points: 13
priority: Alta
labels: [Backend, DB, Testing]
branch: feature/tienda/hu-07-mercado-pago-wallet
depends-on: [HU-01-01]
blocks: [HU-07-03]
github-issue: null
-->

**Epica:** EPIC-07 — Tienda y Monetizacion
**Historias relacionadas:** HU-07-01, HU-07-02, HU-07-06
**Descripcion:** `PaymentService` crea preferencias MP y el webhook publico recibe la confirmacion de pago. El `WalletService` registra cada movimiento en `wallet_transactions` con idempotencia (mismo `mp_event_id` no duplica coins). El historial de pagos es visible en el perfil.
**Prioridad:** Alta
**Labels:** `Backend` `DB` `Testing`
**Rama sugerida:** `feature/tienda-mercado-pago-wallet`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-07-TIENDA/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S08_04.md`

**Checklist tecnico:**
- [ ] Migracion Flyway para tabla `wallet_transactions` (columns: `userId`, `reason`, `delta`, `refTable`, `refId`, `balanceAfter`, `createdAt`) con indices `(user_id, created_at DESC)`, `(reason)`, `(ref_table, ref_id)` — V6.5
- [ ] Tabla `payment_records` y `payment_webhooks_log` con campo `mp_event_id` UNIQUE para idempotencia
- [ ] `PaymentService.createPreference()` con MP SDK; sandbox en dev, produccion en prod via env vars
- [ ] `POST /webhooks/mercado-pago` (publico, sin JWT): valida firma MP; idempotencia por `mp_event_id`; pago aprobado → `walletService.creditCoins(reason=PURCHASE, ref_table='payment_records', ref_id=paymentId, balanceAfter=snapshot)`
- [ ] `WalletService.creditCoins()` y `deductCoins()` `@Transactional`: actualiza `users.virtual_currency_balance` Y registra fila en `wallet_transactions` en la misma transaccion
- [ ] `GET /users/me/wallet` devuelve balance actual
- [ ] `GET /users/me/payments?page=0&size=10` solo para el dueno (403 para otros)
- [ ] Rate-limit `POST /payments/create-preference` 10 req/min/usuario
- [ ] Test: replay del mismo `mp_event_id` no duplica coins
- [ ] Test de invariante: `SUM(wallet_transactions.delta) WHERE user_id=X == users.virtual_currency_balance`
- [ ] Cobertura `PaymentService` >= 85%

**Criterios de aceptacion:**
- Webhook MP idempotente: mismo evento procesado 2 veces no duplica coins
- Balance en `users` siempre coincide con la suma de `wallet_transactions.delta`
- Solo el dueno puede ver su historial de pagos
- `POST /payments/create-preference` rechaza mas de 10 req/min por usuario

---

## Tarjeta: Compra y Apertura de Sobres con Animacion

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-07
hu-ids: [HU-07-03, HU-07-04, HU-07-05]
sprint: S8
milestone: "S8 — Tienda + 2FA + métricas"
team: Equipo C
story-points: 13
priority: Alta
labels: [Backend, Frontend, DB, Testing]
branch: feature/tienda/hu-07-sobres-apertura
depends-on: [HU-07-02, HU-02-01]
blocks: [HU-02-04]
github-issue: null
-->

**Epica:** EPIC-07 — Tienda y Monetizacion
**Historias relacionadas:** HU-07-03, HU-07-04, HU-07-05
**Descripcion:** Los jugadores compran sobres con Codemon Coins y los abren con una animacion de revelacion carta por carta. La apertura genera exactamente 10 cartas con distribucion por rareza (SecureRandom), agrega las cartas a la coleccion y aplica cooldown de 24 h via Redis.
**Prioridad:** Alta
**Labels:** `Backend` `Frontend` `DB` `Testing`
**Rama sugerida:** `feature/tienda-sobres-apertura`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-07-TIENDA/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S08_01.md`

**Checklist tecnico:**
- [ ] Seed: 1 booster pack tipo XY1 con precio en coins si no existe
- [ ] `GET /booster-packs` lista sobres disponibles con precio
- [ ] `POST /users/me/booster-packs/buy/{packId}` `@Transactional`: descuenta coins via `deductCoins(reason=PACK_PURCHASE, delta=-price, ref_table='booster_packs', ref_id=packId, balanceAfter=snapshot)` + crea registro en `user_booster_packs` con `status=PENDING_OPEN`; saldo insuficiente → 422 antes de tocar nada
- [ ] `POST /users/me/booster-packs/{id}/open`: genera 10 cartas con `SecureRandom` (5 comunes, 3 poco comunes, 1 rara, 1 holografica); agrega a `user_collection` (upsert quantity); aplica cooldown Redis `booster:cooldown:{userId}` TTL 86400 s; refresca `user_collection_stats` async
- [ ] `GET /users/me/booster-packs/cooldown` devuelve `secondsRemaining`
- [ ] Durante cooldown, intentar abrir → 429 `BOOSTER_COOLDOWN` con `retryAfter`
- [ ] UI `/shop`: listado de sobres con precio + boton comprar
- [ ] `BoosterPackOpener` Angular: animacion de revelacion carta por carta
- [ ] `WalletDisplay` en shell de la app (siempre visible cuando logueado)
- [ ] Countdown "Proximo sobre en HH:MM:SS"
- [ ] Test estadistico: 1000 sobres → distribucion de rareza ±5% del objetivo

**Criterios de aceptacion:**
- Compra debita coins y crea `user_booster_pack` atomicamente
- Apertura agrega exactamente 10 cartas con la distribucion correcta
- Cooldown de 24 h impide abrir otro sobre (429 con countdown)
- Animacion de revelacion carta por carta es fluida

---

## EPIC-08 — Bot e Inteligencia Artificial

Permite a los jugadores practicar contra IA con 3 dificultades (EASY aleatorio, MEDIUM greedy, HARD minimax) y 3 personalidades con mensajes en el chat de partida.

---

## Tarjeta: Bot EASY y Integracion con el Motor

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-08
hu-ids: [HU-08-01]
sprint: S5
milestone: "S5 — PvE jugable"
team: Equipo A
story-points: 5
priority: Alta
labels: [Backend, Testing]
branch: feature/bot/hu-08-01-bot-easy
depends-on: [HU-04-09]
blocks: [HU-06-01, HU-08-02]
github-issue: null
-->

**Epica:** EPIC-08 — Bot e Inteligencia Artificial
**Historias relacionadas:** HU-08-01
**Descripcion:** `BotEasy` selecciona una accion aleatoria entre las validas (`getAvailableActions()`), con delay de 500-1000 ms para simular pensamiento. El motor llama automaticamente al bot cuando es el turno de "BOT". Garantia de no loop infinito via fallback `END_TURN`.
**Prioridad:** Alta
**Labels:** `Backend` `Testing`
**Rama sugerida:** `feature/bot-easy`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-08-BOT/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S05_02.md`

**Checklist tecnico:**
- [ ] Interface `BotStrategy` con metodo `chooseAction(GameContext ctx): GameAction`
- [ ] `BotEasy implements BotStrategy`: elige accion aleatoria de `getAvailableActions()`; lista vacia → retorna `END_TURN`
- [ ] Delay async 500-1000 ms antes de enviar la accion (simula "pensamiento")
- [ ] `GameEngine` detecta que es turno de BOT y llama `botService.playTurn(gameId, botPlayerId)`
- [ ] Garantia: `BotEasy` nunca retorna lista vacia ni entra en loop infinito
- [ ] Test: 100 partidas PvE EASY consecutivas sin excepcion 500

**Criterios de aceptacion:**
- Partida PvE EASY llega a `GAME_OVER` sin errores
- Bot responde en 500-1000 ms (ni instantaneo ni bloqueante)
- 100 partidas consecutivas sin excepcion

---

## Tarjeta: Bot MEDIUM (Greedy) y Bot HARD (Minimax)

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-08
hu-ids: [HU-08-02, HU-08-03]
sprint: S11
milestone: "S11 — Pulido + bots + E2E"
team: Equipo A
story-points: 21
priority: Media
labels: [Backend, Testing]
branch: feature/bot/hu-08-medium-hard
depends-on: [HU-08-01]
blocks: []
github-issue: null
-->

**Epica:** EPIC-08 — Bot e Inteligencia Artificial
**Historias relacionadas:** HU-08-02, HU-08-03
**Descripcion:** `BotMedium` evalua todas las acciones validas y elige la de mayor score inmediato (dano, KO, premios). `BotHard` usa minimax con profundidad 3 y poda alfa-beta, con timeout de 5 s y fallback a Medium si se excede. Ambos son testeables con funciones de scoring documentadas.
**Prioridad:** Media
**Labels:** `Backend` `Testing`
**Rama sugerida:** `feature/bot-medium-hard`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-08-BOT/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S11_01.md`

**Checklist tecnico:**
- [ ] `BotMedium implements BotStrategy`: funcion `scoreAction(action, ctx)` documentada; elige la accion de max score; fallback `END_TURN`; decision < 2 s
- [ ] `BotHard implements BotStrategy`: minimax con profundidad 3 + poda alfa-beta; heuristica considera HP propios/rivales, premios, energias, mazo restante; timeout 5 s → fallback a `BotMedium`
- [ ] Test: `BotMedium` prefiere KO inmediato vs dano de 50 sin KO
- [ ] Test: `BotHard` prefiere KO en 1 turno vs KO en 2 turnos cuando es factible
- [ ] Test: `BotHard` no bloquea el thread del backend (timeout-safe)
- [ ] Cobertura `Bot*` >= 75%

**Criterios de aceptacion:**
- `BotMedium` elige siempre la accion con mayor score inmediato
- `BotHard` nunca bloquea el backend mas de 5 s
- Tests de comportamiento documentan la funcion de scoring

---

## Tarjeta: Personalidades del Bot y Chat en Partida

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-08
hu-ids: [HU-08-04, HU-08-05]
sprint: S11
milestone: "S11 — Pulido + bots + E2E"
team: Equipo A
story-points: 8
priority: Baja
labels: [Backend, Frontend, DB]
branch: feature/bot/hu-08-personalidades-chat
depends-on: [HU-08-01, HU-06-05]
blocks: []
github-issue: null
-->

**Epica:** EPIC-08 — Bot e Inteligencia Artificial
**Historias relacionadas:** HU-08-04, HU-08-05
**Descripcion:** El jugador elige la personalidad del bot (Hernan, Santoro, Ramiro) en el lobby PvE. Durante la partida, `BotChatService` emite mensajes con delay natural (1-3 s) en los eventos `GAME_START`, `ATTACK` y `KO`. Los mensajes se guardan en `game_chat_messages`.
**Prioridad:** Baja
**Labels:** `Backend` `Frontend` `DB`
**Rama sugerida:** `feature/bot-personalidades-chat`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-08-BOT/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S11_02.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S11_03.md`

**Checklist tecnico:**
- [ ] Tabla `game_chat_messages` con campos `gameId`, `senderType` (USER/BOT/SYSTEM), `senderId`, `message`, `createdAt`; indice `(game_id, created_at)`
- [ ] Personalidades en JSON config: 3 personalidades con sets de mensajes por trigger (GAME_START, ATTACK, KO, GAME_OVER)
- [ ] `BotChatService` con minimo 3 triggers; delay async 1-3 s entre mensajes
- [ ] `POST /games/{id}/chat` para mensajes de usuario; rate limit 1 msg/s; max 100 chars
- [ ] `GET /games/{id}/chat` solo para participantes de la partida
- [ ] STOMP: `/topic/game/{gameId}/chat` emite `CHAT_MESSAGE`
- [ ] Selector de personalidad en lobby PvE
- [ ] `ChatWindowComponent` renderiza label "Bot" con color verde para mensajes del bot

**Criterios de aceptacion:**
- El bot envia mensajes en los 3 triggers con delay natural (no instantaneo)
- Usuario no puede ver el chat de una partida en la que no participa
- Rate limit de 1 msg/s bloquea visualmente el input en el frontend

---

## EPIC-09 — Social y Comunidad

Permite a los jugadores construir su identidad (perfil consolidado), socializar (amigos con presencia en tiempo real), competir (leaderboard y ligas) y leer noticias del juego.

---

## Tarjeta: Sistema de Ligas, Leaderboard y Ranking

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-09
hu-ids: [HU-09-05, HU-09-06, HU-09-07]
sprint: S9
milestone: "S9 — Social v1"
team: Equipo C
story-points: 10
priority: Alta
labels: [Backend, Frontend, DB, Testing]
branch: feature/social/hu-09-ligas-leaderboard
depends-on: [HU-04-09]
blocks: [HU-09-01]
github-issue: null
-->

**Epica:** EPIC-09 — Social y Comunidad
**Historias relacionadas:** HU-09-05, HU-09-06, HU-09-07
**Descripcion:** Al ganar una partida QUEUE o ROOM el jugador suma 25 puntos de ranking. Al cruzar umbrales (1000 = PLATA, 2500 = ORO) cambia de liga. La vista materializada `leaderboard` se refresca post-partida. El usuario puede ver su posicion exacta en el ranking.
**Prioridad:** Alta
**Labels:** `Backend` `Frontend` `DB` `Testing`
**Rama sugerida:** `feature/social-ligas-leaderboard`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-09-SOCIAL/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S09_01.md`

**Checklist tecnico:**
- [ ] Campo `users.league` con valores BRONCE/PLATA/ORO; campo `users.skillRating`
- [ ] Vista materializada `leaderboard` (V11) con indice unico; soporte `REFRESH MATERIALIZED VIEW CONCURRENTLY`
- [ ] `RankingService.addWinPoints()` invocado desde `VictoryConditionChecker.declareWinner()` en partidas QUEUE/ROOM
- [ ] +25 puntos en victoria; 0 en derrota; 0 en PvE
- [ ] Actualizar `users.league` al cruzar umbral (1000 → PLATA, 2500 → ORO)
- [ ] `GET /leaderboard?filter=pvp&page=0&size=50`: P95 < 200 ms via vista materializada
- [ ] `GET /users/me/ranking` devuelve `rank`, `points`, `league`, `nextLeague`, `pointsToNext`
- [ ] `LeaderboardComponent` y `RankingComponent` Angular con barra de progreso hacia siguiente liga
- [ ] Test: cruce de umbral 1000 → liga actualizada a PLATA
- [ ] Cobertura `RankingService` >= 80%

**Criterios de aceptacion:**
- Victoria en QUEUE suma 25 puntos; PvE no suma puntos
- Al acumular 1000 puntos, la liga cambia a PLATA automaticamente
- `GET /leaderboard` responde en < 200 ms (vista materializada)
- Leaderboard excluye partidas que no son QUEUE

---

## Tarjeta: Amigos y Presencia en Tiempo Real

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-09
hu-ids: [HU-09-03, HU-09-04]
sprint: S9
milestone: "S9 — Social v1"
team: Equipo C
story-points: 10
priority: Media
labels: [Backend, Frontend, Testing]
branch: feature/social/hu-09-amigos-presencia
depends-on: [HU-01-01]
blocks: []
github-issue: null
-->

**Epica:** EPIC-09 — Social y Comunidad
**Historias relacionadas:** HU-09-03, HU-09-04
**Descripcion:** Los jugadores pueden enviar, aceptar y rechazar solicitudes de amistad. La presencia (ONLINE/PLAYING/OFFLINE) se gestiona en Redis con TTL y heartbeat del frontend cada 2 minutos. El boton "Retar" crea una sala privada si el amigo esta ONLINE.
**Prioridad:** Media
**Labels:** `Backend` `Frontend` `Testing`
**Rama sugerida:** `feature/social-amigos-presencia`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-09-SOCIAL/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S09_02.md`

**Checklist tecnico:**
- [ ] Tabla `friendships` con estados PENDING/ACCEPTED/REJECTED e indices
- [ ] `POST /friends/request {targetUserId}`: no permite solicitud a si mismo ni duplicada
- [ ] `PUT /friends/{requestId}/accept` solo para el receptor; `PUT /friends/{requestId}/reject`; `DELETE /friends/{id}`
- [ ] STOMP emite `FRIEND_REQUEST_RECEIVED` a `/user/queue/social` del receptor
- [ ] Redis key `user:presence:{userId}` con TTL 5 min; heartbeat frontend cada 2 min (`PATCH /users/me/presence`)
- [ ] `setPlaying(userId, gameId)` al iniciar partida; restaurar a ONLINE al finalizar
- [ ] `GET /friends` devuelve amigos ACCEPTED con `presenceStatus` (solo amigos ven mi presencia)
- [ ] Boton "Retar" visible solo si amigo esta ONLINE; crea sala privada y emite `FRIEND_CHALLENGE`
- [ ] `FriendsListComponent` con iconos de presencia (ONLINE verde, PLAYING azul, OFFLINE gris)
- [ ] Test: solicitud duplicada → error; solicitud a si mismo → error

**Criterios de aceptacion:**
- Solo el receptor puede aceptar una solicitud
- Estado PLAYING se activa al iniciar partida y vuelve a ONLINE al terminar
- Solo amigos ven la presencia del jugador
- Boton "Retar" deshabilitado si el amigo no esta ONLINE

---

## Tarjeta: Perfil Consolidado y Perfil Publico

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-09
hu-ids: [HU-09-01, HU-09-02]
sprint: S10
milestone: "S10 — OAuth + Perfil"
team: Equipo C
story-points: 8
priority: Media
labels: [Backend, Frontend, DB]
branch: feature/social/hu-09-perfil-consolidado
depends-on: [HU-09-07, HU-02-05]
blocks: []
github-issue: null
-->

**Epica:** EPIC-09 — Social y Comunidad
**Historias relacionadas:** HU-09-01, HU-09-02
**Descripcion:** El jugador tiene una pagina de perfil con todos sus datos (stats, coleccion, historial de ultimas 10 partidas). Los perfiles publicos de otros jugadores muestran solo datos no sensibles. La query de historial usa indices parciales para no hacer full scan en la tabla `games`.
**Prioridad:** Media
**Labels:** `Backend` `Frontend` `DB`
**Rama sugerida:** `feature/social-perfil-consolidado`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-09-SOCIAL/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S11_05.md`

**Checklist tecnico:**
- [ ] Indices parciales en `games`: `idx_g_p1_history (player1_id, status, ended_at DESC) WHERE status IN ('FINISHED','ABANDONED')` y `idx_g_p2_history` equivalente para player2
- [ ] `GET /users/me/profile`: union de los 2 indices parciales para `recentGames[]`; verificar con `EXPLAIN ANALYZE` que usa index scan (no seq scan)
- [ ] Response incluye: `username`, `email`, `wins`, `losses`, `winRate`, `skillRating`, `league`, `coins`, `collectionStats`, `recentGames[]` (ultimas 10)
- [ ] `GET /users/{userId}/profile` (publico): solo `username`, `wins`, `losses`, `winRate`, `skillRating`, `league`, `presenceStatus`; sin email ni coins
- [ ] `ProfileComponent` Angular: avatar placeholder, badge de liga, barra de coleccion, tabla de ultimas partidas
- [ ] P95 `GET /users/me/profile` < 400 ms

**Criterios de aceptacion:**
- Perfil propio incluye todos los datos; perfil ajeno no expone email ni coins
- `EXPLAIN ANALYZE` confirma uso de indices parciales (no seq scan en `games`)
- P95 del endpoint < 400 ms

---

## Tarjeta: Noticias y Panel de Administracion

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-09
hu-ids: [HU-09-08]
sprint: S9
milestone: "S9 — Social v1"
team: Equipo C
story-points: 3
priority: Baja
labels: [Backend, Frontend, Testing]
branch: feature/social/hu-09-noticias
depends-on: [HU-01-01]
blocks: []
github-issue: null
-->

**Epica:** EPIC-09 — Social y Comunidad
**Historias relacionadas:** HU-09-08
**Descripcion:** Los jugadores pueden leer noticias del juego (publico, sin auth). Solo admins pueden publicar. Las noticias pinned aparecen siempre primero. Las categorias tienen colores distintos en la UI. La verificacion de rol admin se hace contra BD (no solo JWT).
**Prioridad:** Baja
**Labels:** `Backend` `Frontend` `Testing`
**Rama sugerida:** `feature/social-noticias`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-09-SOCIAL/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S09_03.md`

**Checklist tecnico:**
- [ ] Tabla `news` con campos `title`, `body`, `category` (UPDATE/EVENT/MAINTENANCE/ANNOUNCEMENT), `isPinned`, `publishedAt`
- [ ] `GET /news?category=&page=0&size=10` es PUBLICO (sin auth); ordenado `isPinned DESC, publishedAt DESC`
- [ ] `POST /news` verifica `role=ADMIN` contra BD (no solo en JWT); 403 para usuarios normales
- [ ] `NewsComponent` Angular: badge por categoria con color, noticias pinned marcadas visualmente
- [ ] Test: usuario normal intenta `POST /news` → 403
- [ ] Test: noticias `isPinned=true` aparecen primero

**Criterios de aceptacion:**
- `GET /news` es accesible sin autenticacion
- `POST /news` con usuario normal devuelve 403
- Noticias pinned siempre encabezan la lista
- Badge de categoria con color visible en la UI

---

## EPIC-10 — Infraestructura y DevOps

Provee toda la base tecnica que habilita el resto del proyecto: Docker Compose con 10 servicios, migraciones Flyway, Nginx como gateway, Redis con persistencia, monitoring con Prometheus/Grafana, y configuracion de CI/CD.

---

## Tarjeta: Docker Compose y Arranque Local Full Stack

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-10
hu-ids: []
sprint: S0
milestone: "S0 — Kickoff"
team: Equipo C
story-points: 7
priority: Alta
labels: [DevOps, Backend]
branch: feature/infra/docker-compose
depends-on: []
blocks: [HU-01-01]
github-issue: null
-->

**Epica:** EPIC-10 — Infraestructura y DevOps
**Historias relacionadas:** (epica tecnica, sin HU)
**Descripcion:** Configurar el `docker-compose.yml` con todos los servicios necesarios: Postgres, Redis, MinIO, MinIO setup, Prometheus, Grafana, postgres_exporter, redis_exporter, api y front. Nginx como gateway unico en `localhost:8088`. Variables sensibles en `.env`.
**Prioridad:** Alta
**Labels:** `DevOps` `Backend`
**Rama sugerida:** `feature/infra-docker-compose`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-10-INFRA/EPIC.md`, `docs/07-infraestructura/GATEWAY_LOCAL.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S00_03.md`

**Checklist tecnico:**
- [ ] `docker-compose.yml` con 10 servicios y healthchecks; todos sanos antes de levantar API (`condition: service_healthy`)
- [ ] Nginx reverse proxy: `/api/*` → `api:8080`, `/ws/*` → `api:8080`, `/minio/*` → `minio:9000`, `/` → Angular SPA; configurado en puerto externo 8088
- [ ] Redis con persistencia: `appendonly yes`, `appendfsync everysec`, RDB `save 900 1`, `save 300 10`
- [ ] MinIO setup service que crea el bucket `codemon-cards` al primer arranque
- [ ] `.env.example` con todas las variables (JWT_SECRET, MP_ACCESS_TOKEN, CORS_ALLOWED_ORIGINS, MINIO_PUBLIC_URL, DB_PASSWORD, etc.)
- [ ] `.gitignore` incluye `.env`, `target/`, `node_modules/`, `*.class`
- [ ] Smoke test: `docker compose up -d --build` levanta todos en < 90 s; `curl localhost:8088/actuator/health` → `{status: UP, db: UP, redis: UP}`
- [ ] Verificar: `docker exec codemon_redis redis-cli CONFIG GET appendonly` → `yes`

**Criterios de aceptacion:**
- Un solo comando `docker --context colima compose up -d --build` levanta todo el stack
- Todos los healthchecks pasan; la API esta UP con DB y Redis conectados
- `http://localhost:8088` carga la SPA Angular
- Ningun secret hardcodeado en archivos versionados

---

## Tarjeta: Proyecto Spring Boot y Migraciones Flyway

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-10
hu-ids: []
sprint: S0
milestone: "S0 — Kickoff"
team: Equipo A
story-points: 8
priority: Alta
labels: [Backend, DB, DevOps]
branch: feature/infra/spring-flyway
depends-on: []
blocks: [HU-01-01]
github-issue: null
-->

**Epica:** EPIC-10 — Infraestructura y DevOps
**Historias relacionadas:** (epica tecnica, sin HU)
**Descripcion:** Scaffold del proyecto Spring Boot 3.x con `application.yml` por perfil (dev/staging/prod), todas las migraciones Flyway V1-V16 (25 tablas, 2 vistas materializadas, funcion `purge_expired_data()`), configuracion de Redis con `RedisKeyBuilder` y locks distribuidos.
**Prioridad:** Alta
**Labels:** `Backend` `DB` `DevOps`
**Rama sugerida:** `feature/infra-spring-flyway`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-10-INFRA/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S00_04.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S00_05.md`, `docs/05-referencia-tecnica/BD_Y_TABLAS.md`

**Checklist tecnico:**
- [ ] Proyecto Spring Boot 3.x con Maven; `application.yml` con env vars para todos los parametros configurables
- [ ] Flyway V1-V16: 25 tablas (users, refresh_tokens, email_verifications, cards_catalog, decks, deck_cards, games, game_events, game_state_snapshots, booster_packs, user_booster_packs, user_collection, wallet_transactions, payment_records, payment_webhooks_log, friendships, news, bot_personalities, game_chat_messages, leaderboard view, user_collection_stats view, etc.)
- [ ] Funcion SQL `purge_expired_data()` que limpia game_events (90d), snapshots (30d), payment_webhooks_log (180d)
- [ ] `RedisKeyBuilder` bean con prefijo de entorno (`<env>:<dominio>:<id>`)
- [ ] `RedisLockRegistry` bean (`spring-integration-redis`) para locks distribuidos
- [ ] `MaintenanceJob.@Scheduled(cron="0 0 4 * * *")` con lock Redis que invoca `purge_expired_data()`
- [ ] `WalletConsistencyJob.@Scheduled(cron="0 0 5 * * *")` que valida invariante wallet y alerta a Prometheus
- [ ] Test: `SELECT COUNT(*) FROM information_schema.tables WHERE schema='public' >= 25`
- [ ] `MaintenanceJob` y `WalletConsistencyJob` visibles en `actuator/scheduledtasks`

**Criterios de aceptacion:**
- Flyway migra desde cero sin errores; todas las tablas existen al arranque
- `redisKeyBuilder.build("presence", "42")` produce `dev:presence:42` en perfil dev
- `MaintenanceJob` y `WalletConsistencyJob` aparecen en `/actuator/scheduledtasks`
- `purge_expired_data()` retorna 3 filas con conteos por tabla en test de integracion

---

## Tarjeta: Proyecto Angular y Contratos de API/WebSocket

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-10
hu-ids: []
sprint: S0
milestone: "S0 — Kickoff"
team: Equipo B
story-points: 8
priority: Alta
labels: [Frontend, DevOps]
branch: feature/infra/angular-contratos
depends-on: []
blocks: [HU-01-01]
github-issue: null
-->

**Epica:** EPIC-10 — Infraestructura y DevOps
**Historias relacionadas:** (epica tecnica, sin HU)
**Descripcion:** Scaffold del proyecto Angular 21 con feature folders, mock interceptor para desarrollo paralelo del frontend, y los 3 documentos de contrato (`CONTRATOS_API.md`, `PROTOCOLO_WEBSOCKET.md`, `MOCKS_FRONTEND.md`) acordados entre los 3 equipos en Sprint 0.
**Prioridad:** Alta
**Labels:** `Frontend` `DevOps`
**Rama sugerida:** `feature/infra-angular-contratos`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-10-INFRA/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S00_01.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S00_06.md`

**Checklist tecnico:**
- [ ] Proyecto Angular 21 con feature folders: `auth/`, `catalog/`, `decks/`, `game/`, `shop/`, `social/`, `shared/`
- [ ] Lazy loading de rutas con `loadComponent` / `loadChildren`
- [ ] Mock interceptor HTTP que sirve respuestas del `MOCKS_FRONTEND.md` cuando `USE_MOCK=true`
- [ ] `CONTRATOS_API.md` con todos los endpoints REST, DTOs de request/response y codigos de estado
- [ ] `PROTOCOLO_WEBSOCKET.md` con todos los eventos STOMP, formato de payload y canal (publico/privado)
- [ ] `MOCKS_FRONTEND.md` con JSONs de ejemplo por endpoint para que Equipo B trabaje en paralelo
- [ ] `Dockerfile.front` con build Angular + servido por Nginx
- [ ] Todos los contratos revisados y aprobados por los 3 equipos antes de comenzar S1

**Criterios de aceptacion:**
- `http://localhost:8088` carga la SPA Angular con el mock interceptor activo
- Los 3 documentos de contrato existen, son coherentes entre si y aprobados por los 3 equipos
- Los servicios Angular tipados contra los contratos (no `any`)

---

## Tarjeta: Monitoring con Prometheus, Grafana y Metricas Custom

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-10
hu-ids: []
sprint: S8
milestone: "S8 — Tienda + 2FA + métricas"
team: Equipo C
story-points: 11
priority: Media
labels: [DevOps, Backend]
branch: feature/infra/monitoring-grafana
depends-on: []
blocks: []
github-issue: null
-->

**Epica:** EPIC-10 — Infraestructura y DevOps
**Historias relacionadas:** (epica tecnica, sin HU)
**Descripcion:** Configurar Prometheus + Grafana con datasource automatico. Exponer metricas custom `codemon_*` (counters de usuarios registrados, partidas iniciadas, revenue, logouts). Dashboard Grafana con 4 paneles (sistema, BD, Redis, business KPIs).
**Prioridad:** Media
**Labels:** `DevOps` `Backend`
**Rama sugerida:** `feature/infra-monitoring-grafana`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-10-INFRA/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S08_05.md`

**Checklist tecnico:**
- [ ] Prometheus scrapeando `api:8080/actuator/prometheus` y exporters (postgres, redis)
- [ ] Grafana con datasource Prometheus preconfigurado via provisioning
- [ ] Metricas custom en Spring: `codemon_users_registered_total` (Counter), `codemon_games_started_total` (Counter), `codemon_revenue_ars_total` (Counter), `codemon_logout_total` (Counter), `codemon_active_games` (Gauge), `codemon_action_duration_seconds` (Timer)
- [ ] Dashboard Grafana con 4 paneles: sistema (CPU/mem), BD (conexiones/query time), Redis (hit rate/memoria), business (partidas/hora, revenue, usuarios activos)
- [ ] Al menos 1 panel muestra `rate(codemon_games_started_total[5m])` visible en Grafana

**Criterios de aceptacion:**
- Grafana muestra datos en tiempo real desde Prometheus
- Las metricas `codemon_*` aparecen en `localhost:8088/actuator/prometheus`
- Dashboard con los 4 paneles funcionales

---

## Tarjeta: CI/CD con GitHub Actions y Branch Protection

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-10
hu-ids: []
sprint: S0
milestone: "S0 — Kickoff"
team: Equipo C
story-points: 8
priority: Alta
labels: [DevOps, Testing]
branch: feature/infra/ci-cd-github-actions
depends-on: []
blocks: []
github-issue: null
-->

**Epica:** EPIC-10 — Infraestructura y DevOps
**Historias relacionadas:** (epica tecnica, sin HU)
**Descripcion:** Configurar GitHub Actions con dos workflows: uno que corre tests en cada PR, y otro que construye y publica las imagenes Docker. Code style automatico (Checkstyle Java + ESLint TypeScript). Branch protection en `main` requiere PR aprobada y tests en verde.
**Prioridad:** Alta
**Labels:** `DevOps` `Testing`
**Rama sugerida:** `feature/infra-ci-cd-github-actions`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-10-INFRA/EPIC.md`, `docs/02-planificacion/03_epicas/EPIC-11-CALIDAD/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S00_07.md`

**Checklist tecnico:**
- [ ] Workflow `ci-tests.yml`: en cada PR a `main` → `./mvnw test` + `npm test`; falla si tests no pasan
- [ ] Workflow `docker-build.yml`: en merge a `main` → `docker build` + `docker push` (registry configurable)
- [ ] Checkstyle (Java) configurado como plugin Maven; falla build con warnings
- [ ] ESLint + Prettier (TypeScript) configurados; falla build con errores
- [ ] Branch protection en `main`: requiere PR + >= 1 reviewer aprobado + status checks (CI) en verde; sin push directo a main
- [ ] Smoke test en CI: `curl localhost:8080/actuator/health` despues del build

**Criterios de aceptacion:**
- Cada PR a `main` ejecuta los tests automaticamente
- PR con tests fallidos no puede mergearse
- Push directo a `main` bloqueado (branch protection activa)
- 0 warnings Checkstyle / ESLint en CI

---

## EPIC-11 — Calidad y Testing

Garantiza que cada incremento sea entregable: cobertura JaCoCo, tests de integracion con Testcontainers, suite Playwright E2E, Lighthouse de performance y test de carga de WebSocket.

---

## Tarjeta: Cobertura JaCoCo y Tests de Integracion con Testcontainers

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-11
hu-ids: []
sprint: S3
milestone: "S3 — Motor: setup + turnos"
team: Equipo A
story-points: 8
priority: Alta
labels: [Backend, Testing]
branch: feature/calidad/jacoco-testcontainers
depends-on: []
blocks: []
github-issue: null
-->

**Epica:** EPIC-11 — Calidad y Testing
**Historias relacionadas:** (epica tecnica, transversal)
**Descripcion:** Configurar JaCoCo con umbrales de cobertura (80% global, 90% en componentes criticos del motor). Tests de integracion con Testcontainers para Postgres + Redis + MinIO. Tests unitarios JUnit 5 + Mockito para todos los services criticos.
**Prioridad:** Alta
**Labels:** `Backend` `Testing`
**Rama sugerida:** `feature/calidad-jacoco-testcontainers`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-11-CALIDAD/EPIC.md`, `docs/02-planificacion/04_proceso/DOD.md`

**Checklist tecnico:**
- [ ] Plugin JaCoCo configurado en `pom.xml` con goal `check` que falla el build si la cobertura cae debajo de umbral
- [ ] Cobertura global >= 80%; cobertura en `DamageCalculator`, `StatusEffectManager`, `AttackPipeline`, `VictoryConditionChecker`, `RuleValidator`, `DeckValidationService` >= 90%; `AuthService`, `JwtTokenProvider`, `PaymentService` >= 85%
- [ ] Testcontainers: `@Testcontainers` + `@Container PostgreSQLContainer`, `RedisContainer`, `MinIOContainer` en tests de integracion
- [ ] Tests unitarios estructura Given → When → Then; mocks para Redis, MinIO, MP SDK con Mockito
- [ ] `./mvnw test` y `npm test` pasan en local y CI sin modificaciones de entorno
- [ ] Swagger documentado con ejemplos de request/response por cada endpoint

**Criterios de aceptacion:**
- Build falla si cobertura cae debajo de los umbrales configurados
- Tests de integracion corren con BD, Redis y MinIO reales en contenedores
- `./mvnw test` pasa en entorno limpio (CI)

---

## Tarjeta: Suite E2E con Playwright y Lighthouse

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-11
hu-ids: [HU-06-06]
sprint: S11
milestone: "S11 — Pulido + bots + E2E"
team: Equipo B
story-points: 16
priority: Media
labels: [Frontend, Testing]
branch: feature/calidad/playwright-lighthouse
depends-on: [HU-06-06]
blocks: []
github-issue: null
-->

**Epica:** EPIC-11 — Calidad y Testing
**Historias relacionadas:** HU-06-06
**Descripcion:** Suite Playwright que cubre los flujos criticos end-to-end: auth (registro + login), mazos (crear + editar), partida PvE (lobby → tablero → game over) y compra de sobre (shop → abrir → coleccion). Lighthouse verifica Performance >= 80 y Accessibility >= 90 en mobile.
**Prioridad:** Media
**Labels:** `Frontend` `Testing`
**Rama sugerida:** `feature/calidad-playwright-lighthouse`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-11-CALIDAD/EPIC.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S11_06.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S11_07.md`

**Checklist tecnico:**
- [ ] Playwright configurado con browsers Chrome + Firefox en modo headless
- [ ] Test E2E `auth.spec.ts`: registro → verificacion email → login → logout
- [ ] Test E2E `decks.spec.ts`: crear mazo → agregar cartas via drag drop → validar → guardar
- [ ] Test E2E `pve-game.spec.ts`: lobby → seleccionar bot EASY → tablero → jugar turno → game over
- [ ] Test E2E `shop.spec.ts`: ver shop → comprar sobre → animacion apertura → coleccion incrementa
- [ ] Suite corre en CI en cada PR (Playwright en GitHub Actions con Xvfb o Docker)
- [ ] Lighthouse CLI en CI: score Performance >= 80, Accessibility >= 90 en mobile; falla el build si no se alcanza

**Criterios de aceptacion:**
- Suite Playwright pasa en headless (Chrome + Firefox) en CI
- Lighthouse mobile pasa los thresholds (P >= 80, A >= 90)
- Los 4 flujos criticos tienen cobertura E2E

---

## Tarjeta: Test de Carga WebSocket y Documentacion Final

<!-- GITHUB-ISSUE
type: historia
epic: EPIC-11
hu-ids: [HU-05-05]
sprint: S11
milestone: "S11 — Pulido + bots + E2E"
team: Equipo A
story-points: 11
priority: Media
labels: [Backend, Testing, DevOps]
branch: feature/calidad/test-carga-docs
depends-on: [HU-05-05]
blocks: []
github-issue: null
-->

**Epica:** EPIC-11 — Calidad y Testing
**Historias relacionadas:** HU-05-05
**Descripcion:** Test de carga con 50 partidas WebSocket concurrentes sin degradacion > 30% en latencia. El reporte se guarda en `REPORTE_CARGA.md`. Swagger completo con ejemplos. Checklist de entrega final verificada en Sprint 11.
**Prioridad:** Media
**Labels:** `Backend` `Testing` `DevOps`
**Rama sugerida:** `feature/calidad-test-carga-docs`
**Archivos fuente:** `docs/02-planificacion/03_epicas/EPIC-11-CALIDAD/EPIC.md`, `docs/02-planificacion/02_sprints/CHECKLIST_ENTREGA.md`, `docs/08-desarrollo-con-ia/pasos/PASO_S11_06.md`

**Checklist tecnico:**
- [ ] Script Gatling o k6 que simula 50 clientes WebSocket conectados jugando partidas simultaneas
- [ ] Umbral: latencia P95 de eventos STOMP no se degrada mas del 30% bajo carga vs baseline
- [ ] Reporte de carga guardado en `docs/08-desarrollo-con-ia/pasos/REPORTE_CARGA.md` con graficas de latencia, throughput y errores
- [ ] Swagger (`/swagger-ui.html`) con todos los endpoints documentados: request, response, codigos de error, ejemplos de payload
- [ ] `PROTOCOLO_WEBSOCKET.md` actualizado con todos los eventos STOMP finales
- [ ] Checklist `CHECKLIST_ENTREGA.md` verificada item por item antes del demo final
- [ ] Demo final ejecutable end-to-end sin errores: registro → login → mazo → partida PvE → partida PvP → compra de sobre

**Criterios de aceptacion:**
- 50 partidas WebSocket concurrentes sin errores y degradacion < 30%
- Swagger completo y navegable (sin endpoints sin documentar)
- Demo final ejecutable de inicio a fin sin errores
- Todas las HU de S0-S11 en estado DONE antes del demo

---

*Fin del Backlog Master — Codemon TCG*
*Total: 40 tarjetas funcionales agrupadas en 11 epicas*
