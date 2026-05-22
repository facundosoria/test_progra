#!/usr/bin/env bash
# =============================================================================
# setup-github-project.sh — Codemon TCG
# Crea labels, milestones, issues de épica e issues de HU en el repo.
# El agregado de issues a GitHub Projects v2 se hace como paso posterior.
# Uso: ./scripts/setup-github-project.sh OWNER/REPO
# Ejemplo: ./scripts/setup-github-project.sh francobrizzio/codemon-tcg
# =============================================================================
set -euo pipefail

REPO="${1:-}"

# ── Validaciones ──────────────────────────────────────────────────────────────
if [[ -z "$REPO" ]]; then
  echo "ERROR: Falta el argumento OWNER/REPO"
  echo "Uso: $0 usuario/repo"
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "ERROR: gh CLI no está instalado. Instalalo desde https://cli.github.com/"
  exit 1
fi

if ! gh auth status &>/dev/null; then
  echo "ERROR: No estás autenticado con gh. Ejecutá: gh auth login"
  exit 1
fi

echo "========================================"
echo " Codemon TCG — GitHub Project Setup"
echo " Repo: $REPO"
echo "========================================"
echo ""

ISSUES_CREATED=0
LABELS_CREATED=0
MILESTONES_CREATED=0

# ── Helper functions ──────────────────────────────────────────────────────────

create_label() {
  local name="$1" color="$2" desc="$3"
  if gh label create "$name" --color "$color" --description "$desc" --repo "$REPO" 2>/dev/null; then
    echo "  [OK] Label: $name"
    ((++LABELS_CREATED))
  else
    echo "  [SKIP] Label ya existe: $name"
  fi
}

create_milestone() {
  local title="$1" due="$2" desc="$3"
  if gh api "repos/$REPO/milestones" \
    --method POST \
    --field title="$title" \
    --field due_on="${due}T23:59:59Z" \
    --field description="$desc" \
    --silent 2>/dev/null; then
    echo "  [OK] Milestone: $title"
    ((++MILESTONES_CREATED))
  else
    echo "  [SKIP] Milestone ya existe: $title"
  fi
}

get_milestone_number() {
  local title="$1"
  gh api "repos/$REPO/milestones" --paginate \
    --jq ".[] | select(.title == \"$title\") | .number" 2>/dev/null | head -1
}

create_epic_issue() {
  local title="$1" body="$2"
  local number
  number=$(gh issue create \
    --repo "$REPO" \
    --title "$title" \
    --body "$body" \
    --label "epic" \
    2>/dev/null | grep -o '[0-9]*$')
  echo "  [OK] Épica Issue #$number: $title"
  ((++ISSUES_CREATED))
  echo "$number"
}

create_hu_issue() {
  local title="$1" body="$2" milestone_title="$3" labels="$4"
  local milestone_num
  milestone_num=$(get_milestone_number "$milestone_title")
  local number
  if [[ -n "$milestone_num" ]]; then
    number=$(gh issue create \
      --repo "$REPO" \
      --title "$title" \
      --body "$body" \
      --label "$labels" \
      --milestone "$milestone_num" \
      2>/dev/null | grep -o '[0-9]*$')
  else
    number=$(gh issue create \
      --repo "$REPO" \
      --title "$title" \
      --body "$body" \
      --label "$labels" \
      2>/dev/null | grep -o '[0-9]*$')
  fi
  echo "  [OK] HU Issue #$number: $title"
  ((++ISSUES_CREATED))
}

# =============================================================================
# PASO 1: LABELS
# =============================================================================
echo ""
echo "─── PASO 1: Creando labels ───────────────────────────────────────────────"

create_label "epic"     "7B68EE" "Épica funcional — agrupa historias"
create_label "historia" "0075ca" "Historia de Usuario"
create_label "bug"      "d73a4a" "Error o comportamiento inesperado"
create_label "Backend"  "e4e669" "Trabajo en Spring Boot / Java"
create_label "Frontend" "0052cc" "Trabajo en Angular"
create_label "DB"       "5319e7" "Base de datos, migraciones Flyway, vistas"
create_label "Testing"  "006b75" "Tests unitarios, integración, E2E"
create_label "DevOps"   "e99695" "Docker, CI/CD, Nginx, infraestructura"
create_label "Deploy"   "f9d0c4" "Relacionado con despliegue a producción"
create_label "blocked"  "b60205" "Bloqueado por dependencia o impedimento externo"
create_label "hotfix"   "ff0000" "Fix urgente para producción"
create_label "in-review" "fbca04" "PR abierto, pendiente de code review"

# =============================================================================
# PASO 2: MILESTONES (Sprints)
# =============================================================================
echo ""
echo "─── PASO 2: Creando Milestones (Sprints) ────────────────────────────────"

create_milestone "S0 — Kickoff"             "2026-05-24" "Infraestructura corre y contratos acordados. docker compose up saludable."
create_milestone "S1 — Auth básica"         "2026-05-31" "Usuario puede registrarse, loguearse y mantener sesión."
create_milestone "S2 — Catálogo + Mazos"    "2026-06-07" "Grid 146 cartas + Deck Builder válido de 60 cartas."
create_milestone "S3 — Motor: setup + turnos" "2026-06-14" "Setup TCG + draw + main phase via API."
create_milestone "S4 — Motor: combate"      "2026-06-21" "AttackPipeline + KO + premios completos."
create_milestone "S5 — PvE jugable"         "2026-06-28" "UI mínima → bot easy → game over end-to-end."
create_milestone "S6 — Tablero pulido + Lobby" "2026-07-05" "Drag & drop completo + 3 tabs lobby + chat."
create_milestone "S7 — PvP en tiempo real"  "2026-07-12" "Sala privada + matchmaking ranked + WebSocket."
create_milestone "S8 — Tienda + 2FA + métricas" "2026-07-19" "MP sandbox + sobres + 2FA + Grafana."
create_milestone "S9 — Social v1"           "2026-07-26" "Ligas + amigos + leaderboard + noticias."
create_milestone "S10 — OAuth + Perfil"     "2026-08-02" "Google/GitHub + perfil consolidado + wallet history."
create_milestone "S11 — Pulido + bots + E2E" "2026-08-09" "Bot HARD + responsive + Playwright + carga. Demo final."

# =============================================================================
# PASO 3: ISSUES DE ÉPICA
# =============================================================================
echo ""
echo "─── PASO 3: Creando Issues de Épica ────────────────────────────────────"

# EPIC-01
create_epic_issue "[EPIC-01] Autenticación y Seguridad" "## EPIC-01 — Autenticación y Seguridad

Permite que los jugadores creen cuentas seguras, verifiquen su identidad, inicien sesión (incluyendo redes sociales) y mantengan sesión activa con expiración de tokens. Sin esta épica nadie puede acceder al resto del producto.

**Sprints:** S1, S8, S10
**Equipo:** Equipo A, Equipo C
**Prioridad:** Alta

## Historias de Usuario

- [ ] HU-01-01 Registro con email + password (SP: 5, S1)
- [ ] HU-01-02 Verificar cuenta via código email (SP: 5, S8)
- [ ] HU-01-03 Iniciar sesión (SP: 3, S1)
- [ ] HU-01-04 Cerrar sesión (SP: 2, S1)
- [ ] HU-01-05 Renovar sesión (refresh token) (SP: 3, S1)
- [ ] HU-01-06 2FA por email (SP: 5, S8)
- [ ] HU-01-07 Login con Google/GitHub (OAuth2) (SP: 8, S10)

## Definition of Done de la Épica
- Todas las HU están en estado Done
- Tests de integración con Testcontainers pasan
- Cobertura AuthService + JwtTokenProvider >= 85%
- Sin secrets hardcodeados en el código"

# EPIC-02
create_epic_issue "[EPIC-02] Catálogo y Colección de Cartas" "## EPIC-02 — Catálogo y Colección de Cartas

Permite a los jugadores explorar las 146 cartas del set XY1 y ver qué cartas tienen en su colección personal. Sin catálogo no se pueden armar mazos ni vender sobres.

**Sprints:** S2, S8
**Equipo:** Equipo A, Equipo B, Equipo C
**Prioridad:** Alta

## Historias de Usuario

- [ ] HU-02-01 Ver catálogo paginado (SP: 5, S2)
- [ ] HU-02-02 Filtrar y buscar cartas (SP: 3, S2)
- [ ] HU-02-03 Ver detalle de carta (SP: 3, S2)
- [ ] HU-02-04 Ver mi colección personal (SP: 5, S8)
- [ ] HU-02-05 Ver estadísticas de colección (SP: 3, S8)

## Definition of Done de la Épica
- 146 cartas disponibles en catálogo con imágenes en MinIO
- Colección personal con porcentaje de completado
- Seed idempotente verificado en test de integración"

# EPIC-03
create_epic_issue "[EPIC-03] Constructor de Mazos" "## EPIC-03 — Constructor de Mazos

Permite a los jugadores armar y editar mazos válidos de 60 cartas para usar en partidas. Es prerequisito para EPIC-04 (motor) y EPIC-05 (matchmaking).

**Sprints:** S2
**Equipo:** Equipo A, Equipo B
**Prioridad:** Alta

## Historias de Usuario

- [ ] HU-03-01 Crear mazo nuevo (SP: 3, S2)
- [ ] HU-03-02 Editar mazo con drag & drop (SP: 8, S2)
- [ ] HU-03-03 Validar mazo TCG (SP: 5, S2)
- [ ] HU-03-04 Eliminar mazo (SP: 2, S2)
- [ ] HU-03-05 Marcar mazo favorito (SP: 2, S2)
- [ ] HU-03-06 Copiar mazo starter (SP: 3, S2)

## Definition of Done de la Épica
- CRUD completo de mazos con las 5 reglas TCG validadas
- DeckValidationService cobertura >= 90%
- 3 mazos starter disponibles y copiables"

# EPIC-04
create_epic_issue "[EPIC-04] Motor de Juego" "## EPIC-04 — Motor de Juego

Implementa todas las reglas del TCG XY1: setup de partida, turnos (robar, jugar Pokémon, adjuntar energía, evolucionar, atacar, retirar), condiciones de victoria y el cálculo de daño. Es la columna vertebral del producto.

**Sprints:** S3, S4, S5
**Equipo:** Equipo A
**Prioridad:** Alta

## Historias de Usuario

- [ ] HU-04-01 Iniciar partida con setup correcto (SP: 8, S3)
- [ ] HU-04-02 Robar carta al inicio del turno (SP: 2, S3)
- [ ] HU-04-03 Jugar Pokémon Básico al banco (SP: 3, S3)
- [ ] HU-04-04 Adjuntar energía (SP: 3, S3)
- [ ] HU-04-05 Evolucionar Pokémon (SP: 3, S3)
- [ ] HU-04-06 Atacar (9-handlers AttackPipeline) (SP: 21, S4)
- [ ] HU-04-07 Retirar Pokémon activo (SP: 3, S4)
- [ ] HU-04-08 Tomar premios al hacer KO (SP: 3, S4)
- [ ] HU-04-09 Ganar la partida (SP: 5, S5)

## Definition of Done de la Épica
- Partida PvE completa end-to-end sin errores
- DamageCalculator, AttackPipeline, VictoryConditionChecker >= 90% cobertura
- Invariante deck+hand+prizes==60 verificada"

# EPIC-05
create_epic_issue "[EPIC-05] Multijugador y Matchmaking" "## EPIC-05 — Multijugador y Matchmaking

Permite que dos jugadores se enfrenten online via sala privada con código o cola ranked, con emparejamiento por ELO y partida en tiempo real via WebSocket.

**Sprints:** S7
**Equipo:** Equipo C, Equipo A + B
**Prioridad:** Alta

## Historias de Usuario

- [ ] HU-05-01 Crear sala privada (SP: 5, S7)
- [ ] HU-05-02 Unirse a sala con código (SP: 3, S7)
- [ ] HU-05-03 Entrar a cola ranked (SP: 8, S7)
- [ ] HU-05-04 Cancelar cola (SP: 2, S7)
- [ ] HU-05-05 Recibir eventos en tiempo real (SP: 5, S7)

## Definition of Done de la Épica
- PvP funcional end-to-end con WebSocket
- Matchmaking ELO en < 3s para ratings similares
- Reconexión automática funcional"

# EPIC-06
create_epic_issue "[EPIC-06] Tablero y Experiencia de Juego" "## EPIC-06 — Tablero y Experiencia de Juego

Convierte el motor de juego en algo jugable: zonas del tablero visuales, drag and drop de cartas, animaciones de daño y KO, lobby con selección de modo, chat en partida y layout responsive.

**Sprints:** S5, S6, S11
**Equipo:** Equipo B
**Prioridad:** Alta

## Historias de Usuario

- [ ] HU-06-01 Ver zonas del tablero (SP: 5, S5/S6)
- [ ] HU-06-02 Drag & drop de cartas (SP: 8, S6)
- [ ] HU-06-03 Animaciones daño/KO/status (SP: 5, S6)
- [ ] HU-06-04 Lobby con selección de modo (SP: 5, S6)
- [ ] HU-06-05 Chat de partida (SP: 3, S6)
- [ ] HU-06-06 Responsive mobile/tablet/desktop (SP: 5, S11)

## Definition of Done de la Épica
- Tablero jugable con todas las zonas TCG
- Lighthouse mobile: Performance >= 80, Accessibility >= 90
- Drag & drop verificado en 3 browsers + tablet"

# EPIC-07
create_epic_issue "[EPIC-07] Tienda y Monetización" "## EPIC-07 — Tienda y Monetización

Permite a los jugadores comprar Codemon Coins con Mercado Pago y usarlas para comprar y abrir sobres de cartas, alimentando la colección. Incluye wallet, historial de pagos y cooldown de 24h entre sobres.

**Sprints:** S8, S10
**Equipo:** Equipo C, Equipo B
**Prioridad:** Alta

## Historias de Usuario

- [ ] HU-07-01 Ver balance de coins (SP: 2, S8)
- [ ] HU-07-02 Comprar coins con MP (SP: 8, S8)
- [ ] HU-07-03 Comprar sobre (SP: 5, S8)
- [ ] HU-07-04 Abrir sobre con animación (SP: 5, S8)
- [ ] HU-07-05 Cooldown 24h (SP: 3, S8)
- [ ] HU-07-06 Historial de pagos (SP: 3, S10)

## Definition of Done de la Épica
- Webhook MP idempotente verificado
- Invariante wallet: SUM(delta) == balance en users
- Cooldown 24h via Redis funcional"

# EPIC-08
create_epic_issue "[EPIC-08] Bot e Inteligencia Artificial" "## EPIC-08 — Bot e Inteligencia Artificial

Permite a los jugadores practicar contra IA con 3 dificultades (EASY aleatorio, MEDIUM greedy, HARD minimax) y 3 personalidades con mensajes en el chat de partida.

**Sprints:** S5, S11
**Equipo:** Equipo A
**Prioridad:** Media

## Historias de Usuario

- [ ] HU-08-01 Bot EASY (SP: 5, S5)
- [ ] HU-08-02 Bot MEDIUM (greedy) (SP: 8, S11)
- [ ] HU-08-03 Bot HARD (minimax) (SP: 13, S11)
- [ ] HU-08-04 Elegir personalidad (SP: 3, S11)
- [ ] HU-08-05 Mensajes con personalidad (SP: 5, S11)

## Definition of Done de la Épica
- 100 partidas PvE EASY sin excepción
- BotHard nunca bloquea el backend más de 5s
- Personalidades: Hernán, Santoro, Ramiro"

# EPIC-09
create_epic_issue "[EPIC-09] Social y Comunidad" "## EPIC-09 — Social y Comunidad

Permite a los jugadores construir su identidad (perfil consolidado), socializar (amigos con presencia en tiempo real), competir (leaderboard y ligas) y leer noticias del juego.

**Sprints:** S9, S10
**Equipo:** Equipo C, Equipo B
**Prioridad:** Media

## Historias de Usuario

- [ ] HU-09-01 Perfil consolidado (SP: 5, S10)
- [ ] HU-09-02 Perfil público de otro jugador (SP: 3, S10)
- [ ] HU-09-03 Solicitar amistad (SP: 5, S9)
- [ ] HU-09-04 Presencia en tiempo real (SP: 5, S9)
- [ ] HU-09-05 Leaderboard global (SP: 3, S9)
- [ ] HU-09-06 Mi posición en ranking (SP: 2, S9)
- [ ] HU-09-07 Progresión por ligas (SP: 5, S9)
- [ ] HU-09-08 Leer noticias (SP: 3, S9)

## Definition of Done de la Épica
- Leaderboard con vista materializada P95 < 200ms
- Presencia en tiempo real via Redis
- Perfil público no expone email ni coins"

# EPIC-10
create_epic_issue "[EPIC-10] Infraestructura y DevOps" "## EPIC-10 — Infraestructura y DevOps

Provee toda la base técnica que habilita el resto del proyecto: Docker Compose con 10 servicios, migraciones Flyway, Nginx como gateway, Redis con persistencia, monitoring con Prometheus/Grafana, y configuración de CI/CD.

**Sprints:** S0 (principalmente)
**Equipo:** Equipo C, Equipo A, Equipo B
**Prioridad:** Alta (primer sprint)

## Tareas Técnicas principales

- [ ] TT-10-01 Definir CONTRATOS_API.md (ALL, S0)
- [ ] TT-10-02 Definir PROTOCOLO_WEBSOCKET.md (ALL, S0)
- [ ] TT-10-05 docker-compose.yml con 10 servicios (C, S0)
- [ ] TT-10-06 Proyecto Spring Boot + application.yml (A, S0)
- [ ] TT-10-07 Migraciones Flyway V1-V16 (A, S0)
- [ ] TT-10-08 Proyecto Angular + features + mocks (B, S0)
- [ ] TT-10-10 Nginx reverse proxy + Dockerfile.front (C, S0)
- [ ] TT-11-07 GH Actions: tests + build/Docker (C, S0)

## Definition of Done de la Épica
- docker compose up saludable en < 90s
- Todos los healthchecks pasan
- CI/CD en verde con branch protection activa"

# EPIC-11
create_epic_issue "[EPIC-11] Calidad y Testing" "## EPIC-11 — Calidad y Testing

Garantiza que cada incremento sea entregable: cobertura JaCoCo, tests de integración con Testcontainers, suite Playwright E2E, Lighthouse de performance y test de carga de WebSocket.

**Sprints:** Transversal + S11
**Equipo:** All
**Prioridad:** Alta

## Tareas Técnicas principales

- [ ] TT-11-01 JaCoCo configurado (A, S3)
- [ ] TT-11-02 Configurar Testcontainers (A, S1)
- [ ] TT-11-04 Suite Playwright E2E (B, S11)
- [ ] TT-11-05 Lighthouse audit (B, S11)
- [ ] TT-11-06 Checkstyle + ESLint + Prettier (A/B, S0)
- [ ] TT-11-07 GH Actions: tests + build/Docker (C, S0)
- [ ] TT-11-08 Branch protection en main (C, S0)
- [ ] TT-11-09 Test de carga 50 partidas WebSocket (A, S11)
- [ ] TT-11-10 Documentación Swagger completa (A/C, S11)

## Definition of Done de la Épica
- Cobertura global >= 80%; componentes críticos >= 90%
- Suite Playwright pasa en headless Chrome + Firefox
- 50 partidas WebSocket concurrentes sin degradación > 30%"

# =============================================================================
# PASO 4: ISSUES DE HISTORIAS DE USUARIO — EPIC-01
# =============================================================================
echo ""
echo "─── PASO 4: Creando Issues de HU — EPIC-01 ─────────────────────────────"

create_hu_issue \
  "[HU-01-01] Registro con email + password" \
  "## HU-01-01 — Registro con email + password

**Épica:** EPIC-01 — Autenticación y Seguridad
**Sprint:** S1
**Story Points:** 5
**Equipo:** Equipo A
**Prioridad:** Alta

### Historia
Como visitante del sitio, quiero poder registrarme con mi email y contraseña para crear una cuenta en Codemon TCG.

### Descripción técnica
Implementar el endpoint \`POST /auth/register\` que valida email único, password segura (>=8 chars, 1 mayúscula, 1 número), hashea con BCrypt cost 10, crea el usuario con \`emailVerified=false\` y retorna 201 o 409.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-01-01 Entidad \`User\` con campos email, passwordHash, emailVerified, role, league, skillRating, virtualCurrencyBalance
- [ ] TT-01-02 Migraciones Flyway V2-V3 para tablas email_verifications y refresh_tokens
- [ ] TT-01-03 \`POST /auth/register\`: valida email único + password; responde 201 o 409
- [ ] TT-01-04 BCrypt cost 10 para el hash de password
- [ ] TT-01-05 Tests unitarios AuthService >= 85% cobertura

### Criterios de aceptación
- Registro exitoso devuelve 201
- Email duplicado devuelve 409 \`EMAIL_ALREADY_REGISTERED\`
- Password < 8 chars o sin mayúscula o sin número devuelve 400 con mensaje claro
- Password no aparece en logs ni en respuestas
- P95 de registro < 500ms

### Rama sugerida
\`feature/auth/hu-01-01-registro\`

### Depende de
Ninguna (primer issue del proyecto)" \
  "S1 — Auth básica" \
  "historia,Backend,DB,Testing"

create_hu_issue \
  "[HU-01-02] Verificar cuenta via código email" \
  "## HU-01-02 — Verificar cuenta via código email

**Épica:** EPIC-01 — Autenticación y Seguridad
**Sprint:** S8
**Story Points:** 5
**Equipo:** Equipo C
**Prioridad:** Alta

### Historia
Como usuario recién registrado, quiero recibir un código de verificación por email para confirmar mi cuenta y poder acceder a la plataforma.

### Descripción técnica
Tras registrarse, el sistema envía un código de 6 dígitos al email del usuario. El endpoint \`POST /auth/verify-email\` valida el código con BCrypt y establece \`emailVerified=true\`. Rate-limit de 5 intentos antes de bloquear 15 minutos.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-01-01 EmailService con @Async + SMTP Mailtrap (dev) / SMTP real (prod) via env vars
- [ ] TT-01-02 POST /auth/verify-email valida código BCrypt; devuelve accessToken + refreshToken al verificar
- [ ] TT-01-03 Código expira a los 30 min; 5 intentos fallidos bloquean 15 min (Bucket4j)
- [ ] TT-01-04 POST /auth/resend-code con rate-limit 1 envío cada 60s
- [ ] TT-01-05 Tests: 5 intentos fallidos → 429; replay expirado → 410

### Criterios de aceptación
- Email con código llega en < 30 segundos
- Código correcto establece emailVerified=true y retorna tokens
- 5 intentos fallidos bloquean 15 min con mensaje TOO_MANY_ATTEMPTS
- Resend antes de 60s devuelve 429

### Rama sugerida
\`feature/auth/hu-01-02-verificacion-email\`

### Depende de
HU-01-01" \
  "S8 — Tienda + 2FA + métricas" \
  "historia,Backend,Frontend,Testing"

create_hu_issue \
  "[HU-01-03] Iniciar sesión" \
  "## HU-01-03 — Iniciar sesión

**Épica:** EPIC-01 — Autenticación y Seguridad
**Sprint:** S1
**Story Points:** 3
**Equipo:** Equipo A
**Prioridad:** Alta

### Historia
Como usuario registrado, quiero poder iniciar sesión con mi email y contraseña para acceder a mi cuenta de Codemon TCG.

### Descripción técnica
\`POST /auth/login\` verifica credenciales y devuelve accessToken JWT (15 min, HS256) + refreshToken UUID (7 días) almacenado en BD.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-01-03 POST /auth/login devuelve accessToken JWT + refreshToken UUID
- [ ] TT-01-04 JwtTokenProvider + JwtAuthenticationFilter + SecurityConfig
- [ ] TT-01-05 Rate-limit 10 req/min/IP en /auth/login (Bucket4j + Redis)
- [ ] TT-01-06 Tests integración: login correcto → 200 con tokens; credenciales incorrectas → 401

### Criterios de aceptación
- Login correcto devuelve JWT de 15 min + refresh de 7 días
- Credenciales incorrectas devuelven 401 sin distinguir si el email existe (evitar enumeración)
- Más de 10 req/min desde la misma IP devuelve 429
- P95 de login < 300ms

### Rama sugerida
\`feature/auth/hu-01-03-login\`

### Depende de
HU-01-01" \
  "S1 — Auth básica" \
  "historia,Backend,Testing"

create_hu_issue \
  "[HU-01-04] Cerrar sesión" \
  "## HU-01-04 — Cerrar sesión

**Épica:** EPIC-01 — Autenticación y Seguridad
**Sprint:** S1
**Story Points:** 2
**Equipo:** Equipo A
**Prioridad:** Alta

### Historia
Como usuario autenticado, quiero poder cerrar sesión para que mi token quede invalidado y nadie pueda acceder a mi cuenta si me olvido la sesión abierta.

### Descripción técnica
\`POST /auth/logout\` revoca el refresh token (revoked=true) atómicamente en BD. El accessToken expirado naturalmente en 15 min (sin blacklist).

### Checklist técnico (Tareas Técnicas)
- [ ] TT-01-03 POST /auth/logout revoca el refresh token (revoked=true)
- [ ] TT-01-04 Test: logout → reusar ese refresh → 401 REFRESH_TOKEN_REVOKED

### Criterios de aceptación
- Logout revoca el refresh token en BD
- Reusar ese refresh token devuelve 401
- El endpoint requiere JWT válido (no accesible sin autenticación)

### Rama sugerida
\`feature/auth/hu-01-04-logout\`

### Depende de
HU-01-03" \
  "S1 — Auth básica" \
  "historia,Backend,Testing"

create_hu_issue \
  "[HU-01-05] Renovar sesión (refresh token)" \
  "## HU-01-05 — Renovar sesión (refresh token)

**Épica:** EPIC-01 — Autenticación y Seguridad
**Sprint:** S1
**Story Points:** 3
**Equipo:** Equipo A
**Prioridad:** Alta

### Historia
Como usuario con sesión activa, quiero que mi sesión se renueve automáticamente sin que tenga que volver a ingresar mis credenciales, para tener una experiencia fluida.

### Descripción técnica
El interceptor Angular detecta el 401 TOKEN_EXPIRED, llama a \`POST /auth/refresh\` con el refresh token, obtiene un nuevo accessToken y reintenta el request original de forma transparente.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-01-03 POST /auth/refresh valida refresh no revocado ni expirado; emite nuevo accessToken
- [ ] TT-01-04 HttpJwtInterceptor Angular: detecta 401 TOKEN_EXPIRED, llama refresh, reintenta request original
- [ ] TT-01-05 AuthGuard y EmailVerifiedGuard en Angular para proteger rutas
- [ ] TT-01-06 Test integración: registro → login → refresh → logout

### Criterios de aceptación
- Interceptor Angular renueva sesión sin mostrar pantalla de login al usuario
- Refresh revocado o expirado devuelve 401 (el usuario ve pantalla de login)
- La cadena completa registro → login → refresh → logout funciona en test de integración

### Rama sugerida
\`feature/auth/hu-01-05-refresh-token\`

### Depende de
HU-01-03, HU-01-04" \
  "S1 — Auth básica" \
  "historia,Backend,Frontend,Testing"

create_hu_issue \
  "[HU-01-06] 2FA por email" \
  "## HU-01-06 — 2FA por email

**Épica:** EPIC-01 — Autenticación y Seguridad
**Sprint:** S8
**Story Points:** 5
**Equipo:** Equipo C
**Prioridad:** Alta

### Historia
Como usuario con 2FA activado, quiero que al iniciar sesión me pidan un segundo código de verificación enviado a mi email, para aumentar la seguridad de mi cuenta.

### Descripción técnica
Login con 2FA activo devuelve requires2FA=true + verificationToken temporal (sin tokens definitivos). El segundo endpoint valida el código y emite los tokens definitivos. Rate-limit Redis-backed para prevenir fuerza bruta.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-01-06 Flujo 2FA: POST /auth/login con 2FA activo devuelve requires2FA=true + verificationToken temporal
- [ ] TT-01-07 POST /auth/2fa/verify valida verificationToken + código; emite accessToken + refreshToken definitivos
- [ ] TT-01-08 Bucket4j rate-limit en verify-email y resend-code (Redis-backed)
- [ ] TT-01-09 Tests: 5 intentos fallidos → 429; login con 2FA activo no emite tokens definitivos hasta completar 2FA

### Criterios de aceptación
- Login con 2FA activo NO emite tokens definitivos hasta completar segundo factor
- Verificación correcta emite tokens completos
- 5 intentos fallidos bloquean 15 min
- Rate-limit persistente en Redis (sobrevive reinicios del server)

### Rama sugerida
\`feature/auth/hu-01-06-2fa\`

### Depende de
HU-01-02" \
  "S8 — Tienda + 2FA + métricas" \
  "historia,Backend,Frontend,Testing"

create_hu_issue \
  "[HU-01-07] Login con Google/GitHub (OAuth2)" \
  "## HU-01-07 — Login con Google/GitHub (OAuth2)

**Épica:** EPIC-01 — Autenticación y Seguridad
**Sprint:** S10
**Story Points:** 8
**Equipo:** Equipo C + Equipo B
**Prioridad:** Media

### Historia
Como usuario, quiero poder entrar con mi cuenta de Google o GitHub para registrarme y autenticarme sin necesidad de crear una contraseña.

### Descripción técnica
Spring Security OAuth2 Client con Google + GitHub. El backend genera su propio JWT (nunca guarda el token del proveedor). Si el email ya existe, se vincula sin duplicar cuenta.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-01-07 Configurar Spring Security OAuth2 Client con Google + GitHub (secrets via env vars)
- [ ] TT-01-08 OAuth2AuthenticationSuccessHandler: genera JWT propio; usuario nuevo → emailVerified=true; usuario existente → vincula
- [ ] TT-01-09 Callback /auth/callback?token=...&refreshToken=... en Angular
- [ ] TT-01-10 Botones 'Continuar con Google' y 'Continuar con GitHub' en pantalla de login
- [ ] TT-01-11 Tests con mock server OAuth2 (WireMock)

### Criterios de aceptación
- Botón social redirige al proveedor; tras autorizar, usuario queda logueado con JWT propio
- Usuario nuevo via OAuth2 tiene emailVerified=true
- Usuario existente con mismo email no duplica cuenta
- JWT del proveedor nunca se guarda

### Rama sugerida
\`feature/auth/hu-01-07-oauth2\`

### Depende de
HU-01-01, HU-01-03" \
  "S10 — OAuth + Perfil" \
  "historia,Backend,Frontend,Testing"

# =============================================================================
# PASO 5: ISSUES DE HU — EPIC-02
# =============================================================================
echo ""
echo "─── PASO 5: Creando Issues de HU — EPIC-02 ─────────────────────────────"

create_hu_issue \
  "[HU-02-01] Ver catálogo paginado de cartas" \
  "## HU-02-01 — Ver catálogo paginado de cartas

**Épica:** EPIC-02 — Catálogo y Colección de Cartas
**Sprint:** S2
**Story Points:** 5
**Equipo:** Equipo A + Equipo B
**Prioridad:** Alta

### Historia
Como jugador autenticado, quiero ver todas las cartas del juego en un grid paginado para explorar el catálogo completo de Codemon TCG.

### Descripción técnica
Endpoint REST paginado GET /cards con el componente Angular CardCatalogComponent. Seed de 146 cartas XY1 + imágenes en MinIO.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-02-01 Entidad Card con campos: cardId, name, supertype, subtypes[], types[], rarity, hp, attacks (JSON), weaknesses (JSON), resistances (JSON), retreatCost, imageSmallUrl, imageLargeUrl
- [ ] TT-02-02 Índices en (name), (rarity), (supertype)
- [ ] TT-02-03 CardSeedRunner idempotente: carga 146 cartas solo si COUNT(*) = 0
- [ ] TT-02-04 MinioService.uploadFile(): 292 imágenes al bucket codemon-cards
- [ ] TT-02-05 GET /cards?page=0&size=20 con paginación
- [ ] TT-02-06 CardCatalogComponent: grid paginado con lazy loading de imágenes
- [ ] TT-02-07 Test: SELECT COUNT(*) FROM cards_catalog = 146

### Criterios de aceptación
- GET /cards retorna totalElements=146, totalPages=8 con size=20
- Imágenes accesibles via HTTP 200 desde localhost:8088/minio/...
- Seed idempotente: segunda ejecución no duplica cartas
- UI funciona en Chrome, Firefox y Safari

### Rama sugerida
\`feature/catalogo/hu-02-01-catalogo-paginado\`

### Depende de
HU-01-01 (auth)" \
  "S2 — Catálogo + Mazos" \
  "historia,Backend,Frontend,DB,Testing"

create_hu_issue \
  "[HU-02-02] Filtrar y buscar cartas" \
  "## HU-02-02 — Filtrar y buscar cartas

**Épica:** EPIC-02 — Catálogo y Colección de Cartas
**Sprint:** S2
**Story Points:** 3
**Equipo:** Equipo A + Equipo B
**Prioridad:** Alta

### Historia
Como jugador, quiero poder filtrar las cartas por nombre, tipo, rareza y supertype para encontrar rápidamente la carta que busco.

### Descripción técnica
Parámetros de filtro combinables en GET /cards con case-insensitive y substring en nombre. Los filtros se reflejan en la URL de Angular (deep-link). Debounce de 300ms en el input de búsqueda.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-02-05 GET /cards?name=&supertype=&type=&rarity= con filtros combinables (case-insensitive, substring)
- [ ] TT-02-06 Filtros reflejados en URL de Angular (deep-link via query params)
- [ ] TT-02-07 Debounce de 300ms en input de búsqueda
- [ ] TT-02-08 Estado vacío amigable cuando no hay resultados

### Criterios de aceptación
- Filtros combinados reducen resultados correctamente
- Sin resultados muestra mensaje amigable
- Búsqueda por nombre es case-insensitive y soporta substring
- P95 backend < 250ms

### Rama sugerida
\`feature/catalogo/hu-02-02-filtros\`

### Depende de
HU-02-01" \
  "S2 — Catálogo + Mazos" \
  "historia,Backend,Frontend,Testing"

create_hu_issue \
  "[HU-02-03] Ver detalle de carta" \
  "## HU-02-03 — Ver detalle de carta

**Épica:** EPIC-02 — Catálogo y Colección de Cartas
**Sprint:** S2
**Story Points:** 3
**Equipo:** Equipo A + Equipo B
**Prioridad:** Alta

### Historia
Como jugador, quiero ver el detalle completo de una carta (imagen grande, ataques, debilidades, resistencias) para conocer sus estadísticas antes de incluirla en mi mazo.

### Descripción técnica
Endpoint GET /cards/{cardId} devuelve todos los atributos incluyendo attacks[], weaknesses[], resistances[], retreatCost. 404 si no existe.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-02-09 GET /cards/{cardId} con 404 si no existe
- [ ] TT-02-10 CardDetailComponent: imagen large + todos los atributos en formato legible

### Criterios de aceptación
- Página de detalle muestra imagen large + todos los atributos de la carta
- ID inválido devuelve 404 con mensaje claro
- Navegación de catálogo a detalle y vuelta funciona correctamente

### Rama sugerida
\`feature/catalogo/hu-02-03-detalle\`

### Depende de
HU-02-01" \
  "S2 — Catálogo + Mazos" \
  "historia,Backend,Frontend"

create_hu_issue \
  "[HU-02-04] Ver mi colección personal" \
  "## HU-02-04 — Ver mi colección personal

**Épica:** EPIC-02 — Catálogo y Colección de Cartas
**Sprint:** S8
**Story Points:** 5
**Equipo:** Equipo C + Equipo B
**Prioridad:** Media

### Historia
Como jugador, quiero ver las cartas que poseo con su cantidad para saber qué tengo disponible para mis mazos.

### Descripción técnica
GET /users/me/collection paginado y filtrable. Tabla user_collection con índice único (user_id, card_id) y campo quantity. Toggle 'ver todo el set' incluye cartas con quantity=0.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-02-05 Tabla user_collection con índice único (user_id, card_id) y quantity
- [ ] TT-02-06 GET /users/me/collection?page=0&size=20&rarity=&supertype= con filtros
- [ ] TT-02-07 Toggle 'ver todo el set' con cartas quantity=0
- [ ] TT-02-08 Solo el dueño puede ver su colección (403 para otros)
- [ ] TT-02-09 CollectionViewComponent Angular con filtros y barra de progreso

### Criterios de aceptación
- GET /users/me/collection devuelve cartas del usuario con su quantity
- Un usuario no puede ver la colección de otro (403)
- Toggle 'ver todo el set' muestra las 146 cartas (incluyendo las no poseídas)

### Rama sugerida
\`feature/catalogo/hu-02-04-coleccion-personal\`

### Depende de
HU-02-01, HU-07-03 (para tener cartas)" \
  "S8 — Tienda + 2FA + métricas" \
  "historia,Backend,Frontend,DB"

create_hu_issue \
  "[HU-02-05] Ver estadísticas de colección" \
  "## HU-02-05 — Ver estadísticas de colección

**Épica:** EPIC-02 — Catálogo y Colección de Cartas
**Sprint:** S8
**Story Points:** 3
**Equipo:** Equipo C + Equipo B
**Prioridad:** Baja

### Historia
Como jugador, quiero ver estadísticas de mi colección (% completado, cartas por rareza) para saber cuánto me falta para completar el set.

### Descripción técnica
Vista materializada user_collection_stats con totalOwned, totalUnique, completionPct, missingByRarity. Se refresca async al abrir un sobre.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-02-06 Vista materializada user_collection_stats
- [ ] TT-02-07 GET /users/me/collection/stats consume la vista materializada
- [ ] TT-02-08 REFRESH MATERIALIZED VIEW CONCURRENTLY al abrir sobre

### Criterios de aceptación
- GET /users/me/collection/stats devuelve completionPct correcto
- Vista materializada se actualiza al abrir un sobre
- Response incluye breakdown por rareza

### Rama sugerida
\`feature/catalogo/hu-02-05-stats-coleccion\`

### Depende de
HU-02-04" \
  "S8 — Tienda + 2FA + métricas" \
  "historia,Backend,Frontend,DB"

# =============================================================================
# PASO 6: ISSUES DE HU — EPIC-03
# =============================================================================
echo ""
echo "─── PASO 6: Creando Issues de HU — EPIC-03 ─────────────────────────────"

create_hu_issue \
  "[HU-03-01] Crear mazo nuevo" \
  "## HU-03-01 — Crear mazo nuevo

**Épica:** EPIC-03 — Constructor de Mazos
**Sprint:** S2
**Story Points:** 3
**Equipo:** Equipo A
**Prioridad:** Alta

### Historia
Como jugador, quiero crear un mazo nuevo con un nombre personalizado para empezar a armar mi estrategia de juego.

### Descripción técnica
POST /decks crea mazo vacío. Límite de 20 mazos por usuario → 422 al exceder.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-03-01 Entidades Deck (ownerId, name, isFavorite, isStarter) y DeckCard (deckId, cardId, quantity)
- [ ] TT-03-02 POST /decks crea mazo vacío; límite 20 mazos por usuario → 422
- [ ] TT-03-03 Seed de 3 mazos starter en ApplicationRunner
- [ ] TT-03-04 GET /decks/starters lista 3 mazos del sistema

### Criterios de aceptación
- Crear mazo exitoso devuelve 201 con el mazo creado
- Al superar 20 mazos, devuelve 422 con mensaje claro
- 3 mazos starter disponibles desde el inicio

### Rama sugerida
\`feature/mazos/hu-03-01-crear-mazo\`

### Depende de
HU-01-01 (auth)" \
  "S2 — Catálogo + Mazos" \
  "historia,Backend,DB,Testing"

create_hu_issue \
  "[HU-03-02] Editar mazo con drag & drop" \
  "## HU-03-02 — Editar mazo con drag & drop

**Épica:** EPIC-03 — Constructor de Mazos
**Sprint:** S2
**Story Points:** 8
**Equipo:** Equipo B
**Prioridad:** Alta

### Historia
Como jugador, quiero editar mi mazo arrastrando y soltando cartas desde el catálogo para construir mi estrategia de forma visual e intuitiva.

### Descripción técnica
DeckBuilderComponent Angular con layout dos columnas. @angular/cdk/drag-drop para arrastrar cartas. Debounce 1s en PUT /decks/{id}. Validación TCG en tiempo real.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-03-04 DeckBuilderComponent con layout catálogo (izq) + mazo (der)
- [ ] TT-03-05 Integrar @angular/cdk/drag-drop para arrastrar cartas
- [ ] TT-03-06 Debounce de 1s en PUT /decks/{id}
- [ ] TT-03-07 Contador visible de cartas totales (X/60)
- [ ] TT-03-08 Feedback visual de drag (cursor grabbing, sombra en drop zone)
- [ ] TT-03-09 Verificado en Chrome, Firefox, Safari (escritorio + tablet)

### Criterios de aceptación
- Arrastrar una carta al mazo la agrega; arrastrarla de vuelta la quita
- Los cambios se guardan automáticamente (debounce 1s) sin botón de 'guardar'
- Drop inválido (mazo ya tiene 4 copias) se rechaza visualmente

### Rama sugerida
\`feature/mazos/hu-03-02-deck-builder-dnd\`

### Depende de
HU-03-01, HU-02-01" \
  "S2 — Catálogo + Mazos" \
  "historia,Frontend,Testing"

create_hu_issue \
  "[HU-03-03] Validar mazo con reglas TCG" \
  "## HU-03-03 — Validar mazo con reglas TCG

**Épica:** EPIC-03 — Constructor de Mazos
**Sprint:** S2
**Story Points:** 5
**Equipo:** Equipo A
**Prioridad:** Alta

### Historia
Como jugador, quiero que el sistema valide mi mazo contra las reglas del TCG en tiempo real para asegurarme de que es válido antes de usarlo en partidas.

### Descripción técnica
DeckValidationService puro Java (sin BD) implementa las 5 reglas TCG. POST /decks/{id}/validate devuelve lista COMPLETA de errores. Cobertura >= 90%.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-03-01 DeckValidationService puro Java: R-DECK-01 (60 cartas), R-DECK-02 (1+ Básico), R-DECK-03 (max 4 copias excepto Energía Básica), R-DECK-04 (max 4 Energías Especiales), R-DECK-05 (max 1 ACE SPEC)
- [ ] TT-03-02 POST /decks/{id}/validate devuelve lista COMPLETA de errores
- [ ] TT-03-03 Validación TCG en tiempo real en UI (llamada a validate con debounce)
- [ ] TT-03-04 Tests unitarios DeckValidationService >= 90% cobertura

### Criterios de aceptación
- Las 5 reglas TCG validan correctamente (casos felices y de error)
- La respuesta incluye TODOS los errores (no solo el primero)
- DeckValidationService cobertura >= 90% en JaCoCo
- Errores muestran el nombre de la regla violada en la UI

### Rama sugerida
\`feature/mazos/hu-03-03-validacion-tcg\`

### Depende de
HU-03-01" \
  "S2 — Catálogo + Mazos" \
  "historia,Backend,Testing"

create_hu_issue \
  "[HU-03-04] Eliminar mazo" \
  "## HU-03-04 — Eliminar mazo

**Épica:** EPIC-03 — Constructor de Mazos
**Sprint:** S2
**Story Points:** 2
**Equipo:** Equipo A
**Prioridad:** Media

### Historia
Como jugador, quiero poder eliminar un mazo que ya no uso para mantener mi lista organizada.

### Descripción técnica
DELETE /decks/{id} verifica pertenencia (403 si no es dueño). Bloquea borrado de starters del sistema (422). Solicita confirmación en UI.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-03-02 DELETE /decks/{id} verifica pertenencia → 403 si no es dueño
- [ ] TT-03-03 Bloquea borrado de starters del sistema → 422
- [ ] TT-03-04 Diálogo de confirmación en UI antes de borrar

### Criterios de aceptación
- Solo el dueño puede borrar su mazo (403 para otros)
- Los mazos starter del sistema no se pueden borrar (422)
- Confirmación requerida antes de borrado definitivo

### Rama sugerida
\`feature/mazos/hu-03-04-eliminar-mazo\`

### Depende de
HU-03-01" \
  "S2 — Catálogo + Mazos" \
  "historia,Backend,Frontend"

create_hu_issue \
  "[HU-03-05] Marcar mazo como favorito" \
  "## HU-03-05 — Marcar mazo como favorito

**Épica:** EPIC-03 — Constructor de Mazos
**Sprint:** S2
**Story Points:** 2
**Equipo:** Equipo A
**Prioridad:** Media

### Historia
Como jugador, quiero marcar uno de mis mazos como favorito para que sea preseleccionado automáticamente en el lobby.

### Descripción técnica
PUT /decks/{id}/favorite toggle que deselecciona automáticamente el favorito anterior. GET /decks incluye isFavorite y el lobby ordena por isFavorite DESC.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-03-05 PUT /decks/{id}/favorite toggle; deselecciona favorito anterior
- [ ] TT-03-06 GET /decks incluye isFavorite e isValid
- [ ] TT-03-07 Indicador visual de mazo favorito (estrella) en lista de mazos

### Criterios de aceptación
- Solo un mazo puede ser favorito a la vez
- La estrella se actualiza inmediatamente en la UI
- El lobby preselecciona el mazo favorito

### Rama sugerida
\`feature/mazos/hu-03-05-favorito\`

### Depende de
HU-03-01" \
  "S2 — Catálogo + Mazos" \
  "historia,Backend,Frontend"

create_hu_issue \
  "[HU-03-06] Copiar mazo starter" \
  "## HU-03-06 — Copiar mazo starter

**Épica:** EPIC-03 — Constructor de Mazos
**Sprint:** S2
**Story Points:** 3
**Equipo:** Equipo A
**Prioridad:** Media

### Historia
Como jugador nuevo, quiero poder copiar uno de los mazos starter predefinidos para tener un mazo listo para jugar sin necesidad de armarlo desde cero.

### Descripción técnica
GET /decks/starters lista 3 mazos del sistema. POST /decks/starters/{id}/copy clona el mazo al usuario (usando quota de 20 mazos).

### Checklist técnico (Tareas Técnicas)
- [ ] TT-03-03 Seed de 3 mazos starter en ApplicationRunner si no existen
- [ ] TT-03-08 POST /decks/starters/{id}/copy clona al usuario; respeta límite de 20
- [ ] TT-03-09 UI muestra lista de starters con botón 'Copiar'

### Criterios de aceptación
- 3 mazos starter disponibles siempre
- Copiar un starter crea un mazo propio editable
- El mazo copiado ocupa un slot del límite de 20

### Rama sugerida
\`feature/mazos/hu-03-06-copiar-starter\`

### Depende de
HU-03-01" \
  "S2 — Catálogo + Mazos" \
  "historia,Backend,Frontend"

# =============================================================================
# PASO 7: ISSUES DE HU — EPIC-04 (completo)
# =============================================================================
echo ""
echo "─── PASO 7: Creando Issues de HU — EPIC-04 ─────────────────────────────"

create_hu_issue \
  "[HU-04-01] Iniciar partida con setup TCG correcto" \
  "## HU-04-01 — Iniciar partida con setup TCG correcto

**Épica:** EPIC-04 — Motor de Juego
**Sprint:** S3
**Story Points:** 8
**Equipo:** Equipo A
**Prioridad:** Alta

### Historia
Como jugador, quiero que al iniciar una partida el setup se realice correctamente (barajado, mano de 7, 6 premios, mulligan, coin flip) para que la partida sea justa y siga las reglas del TCG.

### Descripción técnica
GameContext + StateMachine + SetupState con SecureRandom, mulligan Caso A y B, 6 premios, coin flip para primer turno. Invariante deck+hand+prizes==60 verificada.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-04-00 Interfaces GameState + GameContext facade
- [ ] TT-04-01 SetupState: barajado con SecureRandom, mano de 7, mulligan A y B, 6 premios, coin flip
- [ ] TT-04-02 Invariante deck.size() + hand.size() + prizes.size() == 60 en tests
- [ ] TT-04-03 getState() sanitiza: hand rival=null, deck ambos=null (solo deckSize), prizes=null (solo prizesCount)
- [ ] TT-04-04 POST /games crea partida; GET /games/{id}/state devuelve estado sanitizado
- [ ] TT-04-05 Tests cobertura SetupState >= 90%; tests parametrizados para ambos casos de mulligan

### Criterios de aceptación
- Partida creada via API arranca con setup correcto (mano de 7, 6 premios, coin flip)
- Mulligan Caso B: el rival con Básico roba mulliganCount-1 cartas extra
- GET /games/{id}/state como player1 no expone la mano de player2
- deck+hand+prizes==60 verificado con test de integración

### Rama sugerida
\`feature/motor/hu-04-01-setup\`

### Depende de
HU-03-01 (necesita mazos válidos)" \
  "S3 — Motor: setup + turnos" \
  "historia,Backend,Testing"

create_hu_issue \
  "[HU-04-06] Atacar (AttackPipeline con 9 handlers)" \
  "## HU-04-06 — Atacar (AttackPipeline con 9 handlers)

**Épica:** EPIC-04 — Motor de Juego
**Sprint:** S4
**Story Points:** 21
**Equipo:** Equipo A (los 2 devs juntos)
**Prioridad:** Alta

### Historia
Como jugador, quiero poder atacar con mi Pokémon activo para infligir daño al rival y ganar premios cuando lo noqueo.

### Descripción técnica
AttackPipeline con 9 handlers en orden estricto. DamageCalculator (weakness 2x, resistance -20, mínimo 0). StatusEffectManager (POISONED, BURNED, PARALYZED, CONFUSED, ASLEEP). Ambos devs de Equipo A trabajan juntos (21 SP, no dividir).

### Checklist técnico (Tareas Técnicas)
- [ ] TT-04-05 DamageCalculator: fórmula (base+bonus_atacante)*weakness-resistance-reducción_defensor, mínimo 0
- [ ] TT-04-06 AttackPipeline con 9 handlers en orden: Validate → CalcBase → AttackerFX → Weakness → Resistance → DefenderFX → DealDamage → ExecuteEffect → CheckKO
- [ ] TT-04-07 Verificación de energías requeridas: tipos específicos antes de Colorless
- [ ] TT-04-08 StatusEffectManager: POISONED (10 dmg), BURNED (20+flip), PARALYZED (pierde turno), CONFUSED (30 self+flip), ASLEEP (flip para despertar)
- [ ] TT-04-09 Confusion: 30 daño SIN usar weakness del propio Pokémon
- [ ] TT-04-10 Primer turno del jugador 1: firstTurnAttackBlocked=true
- [ ] TT-04-11 DamageCalculator >= 90% cobertura, StatusEffectManager >= 90%, AttackPipeline >= 90%

### Criterios de aceptación
- Los 9 handlers se ejecutan en orden estricto
- Weakness duplica el daño; resistance resta 20; mínimo de daño es 0
- Confusion aplica 30 daño directo al propio Pokémon (sin weakness)
- Jugador 1 no puede atacar en su primer turno
- Cobertura >= 90% en los 3 componentes críticos

### Rama sugerida
\`feature/motor/hu-04-06-attack-pipeline\`

### Depende de
HU-04-03, HU-04-04, HU-04-05" \
  "S4 — Motor: combate" \
  "historia,Backend,Testing"

create_hu_issue \
  "[HU-04-09] Ganar la partida (condiciones de victoria)" \
  "## HU-04-09 — Ganar la partida (condiciones de victoria)

**Épica:** EPIC-04 — Motor de Juego
**Sprint:** S5
**Story Points:** 5
**Equipo:** Equipo A
**Prioridad:** Alta

### Historia
Como jugador, quiero que el sistema detecte y declare al ganador automáticamente cuando se cumpla alguna de las condiciones de victoria del TCG.

### Descripción técnica
VictoryConditionChecker con las 3 condiciones (últimos premios, mazo vacío, sin Pokémon), muerte súbita, actualización ELO solo en QUEUE, y acreditación de coins en la misma transacción.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-04-07 VictoryConditionChecker: R-WIN-01 (último premio), R-WIN-02 (mazo vacío), R-WIN-03 (sin Pokémon)
- [ ] TT-04-08 Muerte súbita: ambos cumplen condición → SUDDEN_DEATH_START (1 solo premio)
- [ ] TT-04-09 GAME_OVER event con reason (PRIZES/DECK_EMPTY/NO_POKEMON) via STOMP
- [ ] TT-04-10 ELO actualizado SOLO si matchType=QUEUE
- [ ] TT-04-11 walletService.creditCoins(+50 ganador, +10 perdedor) en la misma transacción que cierra partida
- [ ] TT-04-12 VictoryConditionChecker cobertura >= 90%

### Criterios de aceptación
- Las 3 condiciones de victoria se detectan correctamente
- ELO se actualiza solo en partidas QUEUE
- Coins acreditados en la misma transacción que cierra la partida
- Partidas QUEUE y ROOM generan exactamente 2 filas en wallet_transactions

### Rama sugerida
\`feature/motor/hu-04-09-victoria\`

### Depende de
HU-04-06, HU-04-07, HU-04-08" \
  "S5 — PvE jugable" \
  "historia,Backend,DB,Testing"

# Resto HU-04 (04-02, 04-03, 04-04, 04-05, 04-07, 04-08)
for hu_data in \
  "HU-04-02|Robar carta al inicio del turno|DrawPhaseState verifica mazo vacío ANTES del robo (R-WIN-02), mueve primera carta a mano, incrementa turnsInPlay.|S3|2|A|S3 — Motor: setup + turnos|historia,Backend,Testing|HU-04-01" \
  "HU-04-03|Jugar Pokémon Básico al banco|PLAY_BASIC_POKEMON: rechaza Stage 1 directo; banco lleno (5) → 422 BENCH_FULL; asigna instanceId UUID.|S3|3|A|S3 — Motor: setup + turnos|historia,Backend,Testing|HU-04-01" \
  "HU-04-04|Adjuntar energía|ATTACH_ENERGY: flag energyAttachedThisTurn; DCE = 2 Colorless; segunda energía → 422 ENERGY_ALREADY_ATTACHED.|S3|3|A|S3 — Motor: setup + turnos|historia,Backend,Testing|HU-04-03" \
  "HU-04-05|Evolucionar Pokémon|EVOLVE_POKEMON: valida turnsInPlay >= 1 y !evolvedThisTurn; Mega Evolución → transición a EndPhaseState.|S3|3|A|S3 — Motor: setup + turnos|historia,Backend,Testing|HU-04-03" \
  "HU-04-07|Retirar Pokémon activo|RETREAT: bloqueado si activo está ASLEEP o PARALYZED; max 1 por turno; descarta energías según retreatCost.|S4|3|A|S4 — Motor: combate|historia,Backend,Testing|HU-04-06" \
  "HU-04-08|Tomar premios al hacer KO|KO normal → 1 premio; KO de EX o MEGA → 2 premios; carta KO + adjuntos van al descarte del dueño.|S4|3|A|S4 — Motor: combate|historia,Backend,Testing|HU-04-06"; do
  IFS='|' read -r hu_id hu_name hu_desc sprint sp equipo milestone labels depends <<< "$hu_data"
  create_hu_issue \
    "[$hu_id] $hu_name" \
    "## $hu_id — $hu_name

**Épica:** EPIC-04 — Motor de Juego
**Sprint:** $sprint
**Story Points:** $sp
**Equipo:** Equipo $equipo
**Prioridad:** Alta

### Historia
Como jugador, quiero $hu_name para que la partida siga las reglas del TCG XY1.

### Descripción técnica
$hu_desc

### Checklist técnico (Tareas Técnicas)
- [ ] Implementar lógica de $hu_name en el estado correspondiente del motor
- [ ] Tests unitarios con casos válidos, inválidos y edge cases
- [ ] Cobertura >= 90% en el componente

### Criterios de aceptación
- La acción funciona correctamente según las reglas del TCG
- Acciones inválidas devuelven error descriptivo
- Acciones de otro jugador en turno ajeno son rechazadas

### Rama sugerida
\`feature/motor/${hu_id,,}-${hu_name// /-}\`

### Depende de
$depends" \
    "$milestone" \
    "$labels"
done

# =============================================================================
# PASO 8: HU REPRESENTATIVAS EPIC-05 a EPIC-11
# =============================================================================
echo ""
echo "─── PASO 8: HU representativas EPIC-05 a EPIC-11 ───────────────────────"

# EPIC-05 — Todas las HU
create_hu_issue \
  "[HU-05-01] Crear sala privada con código" \
  "## HU-05-01 — Crear sala privada con código

**Épica:** EPIC-05 — Multijugador y Matchmaking
**Sprint:** S7
**Story Points:** 5
**Equipo:** Equipo C
**Prioridad:** Alta

### Historia
Como jugador, quiero crear una sala privada con un código alfanumérico para invitar a un amigo específico a jugar.

### Descripción técnica
POST /games/rooms/create genera código [A-Z0-9] de 6 chars. Sala expira en 10 min sin segundo jugador. STOMP emite ROOM_FULL con gameId cuando llega el segundo jugador.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-05-01 POST /games/rooms/create genera código único de 6 chars [A-Z0-9]
- [ ] TT-05-02 Sala expira en 10 min (campo expiresAt)
- [ ] TT-05-03 @Scheduled(fixedRate=60000) limpia salas expiradas
- [ ] TT-05-04 STOMP emite ROOM_FULL a /topic/room/{code} con gameId
- [ ] TT-05-05 UI muestra código generado con countdown y 'Esperando rival...'
- [ ] TT-05-06 Test transaccional: 2 joins simultáneos no crean 2 Games

### Criterios de aceptación
- Sala creada tiene código único de 6 chars [A-Z0-9]
- Al unirse el segundo jugador ambos reciben gameId via WebSocket
- Salas de más de 10 min sin rival son eliminadas
- Dos jugadores uniéndose simultáneamente no duplican el Game

### Rama sugerida
\`feature/multijugador/hu-05-01-salas-privadas\`

### Depende de
HU-04-09 (motor completo), HU-03-01 (mazos)" \
  "S7 — PvP en tiempo real" \
  "historia,Backend,Frontend,Testing"

create_hu_issue \
  "[HU-05-03] Entrar a cola ranked con matchmaking ELO" \
  "## HU-05-03 — Entrar a cola ranked con matchmaking ELO

**Épica:** EPIC-05 — Multijugador y Matchmaking
**Sprint:** S7
**Story Points:** 8
**Equipo:** Equipo C
**Prioridad:** Alta

### Historia
Como jugador, quiero poder entrar a una cola de matchmaking para que el sistema me empareje automáticamente con un rival de nivel similar.

### Descripción técnica
Cola Redis sorted set por skillRating. Algoritmo de ventana expande ±50 cada 5s. Lock distribuido Redis evita doble match entre instancias. Timeout 30s.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-05-03 POST /matchmaking/queue/join con deckId válido; sorted set Redis con score=skillRating
- [ ] TT-05-04 Algoritmo de ventana: ±100 inicial, +50 cada 5s, max ±300
- [ ] TT-05-05 Timeout 30s → QUEUE_TIMEOUT a /user/{userId}/queue/matchmaking
- [ ] TT-05-06 Match encontrado → MATCH_FOUND con gameId y opponentUsername
- [ ] TT-05-07 Lock Redis distribuido (SET NX EX 5) para evitar doble match
- [ ] TT-05-08 Test: 2 usuarios con rating similar → match en < 3s

### Criterios de aceptación
- Rating similar resulta en match en < 3s
- QUEUE_TIMEOUT emitido a los 30s si no hay match
- Doble match imposible con 2 instancias del backend
- ELO se actualiza solo en partidas matchType=QUEUE

### Rama sugerida
\`feature/multijugador/hu-05-03-cola-ranked\`

### Depende de
HU-05-01" \
  "S7 — PvP en tiempo real" \
  "historia,Backend,Frontend,Testing"

create_hu_issue \
  "[HU-05-05] Reconexión y sincronización WebSocket" \
  "## HU-05-05 — Reconexión y sincronización WebSocket

**Épica:** EPIC-05 — Multijugador y Matchmaking
**Sprint:** S7
**Story Points:** 5
**Equipo:** Equipo A + Equipo B
**Prioridad:** Alta

### Historia
Como jugador en una partida online, quiero que si pierdo la conexión o recargo la página, mi estado de juego se recupere automáticamente para no perder la partida.

### Descripción técnica
WebSocketService Angular con reconexión automática. Al reconectar: GET /games/{id}/state + resubscribe a todos los topics. ngOnDestroy desconecta sin memory leaks.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-05-09 WebSocketService Angular: conexión STOMP sobre SockJS a /ws
- [ ] TT-05-10 Al reconectar: GET /games/{id}/state + resubscribe
- [ ] TT-05-11 ngOnDestroy desconecta y cancela todas las subscripciones
- [ ] TT-05-12 Test de carga: 50 clientes WebSocket concurrentes sin degradación

### Criterios de aceptación
- Recargar browser durante partida recupera el estado correctamente
- ngOnDestroy elimina todas las subscripciones (verificado en DevTools)
- 50 partidas WebSocket concurrentes sin caída del servidor

### Rama sugerida
\`feature/multijugador/hu-05-05-reconexion-ws\`

### Depende de
HU-05-01, HU-04-09" \
  "S7 — PvP en tiempo real" \
  "historia,Frontend,Testing"

# HU-05-02 y HU-05-04 simplificadas
for hu_data in \
  "HU-05-02|Unirse a sala con código|Como jugador, quiero unirme a una sala privada ingresando el código que me compartió mi amigo.|S7|3|C|S7 — PvP en tiempo real|historia,Backend,Frontend,Testing|HU-05-01" \
  "HU-05-04|Cancelar cola de matchmaking|Como jugador en cola, quiero poder cancelar la búsqueda de rival si cambio de opinión.|S7|2|C|S7 — PvP en tiempo real|historia,Backend,Frontend|HU-05-03"; do
  IFS='|' read -r hu_id hu_name hu_historia sprint sp equipo milestone labels depends <<< "$hu_data"
  create_hu_issue \
    "[$hu_id] $hu_name" \
    "## $hu_id — $hu_name

**Épica:** EPIC-05 — Multijugador y Matchmaking
**Sprint:** $sprint
**Story Points:** $sp
**Equipo:** Equipo $equipo
**Prioridad:** Alta

### Historia
$hu_historia

### Checklist técnico (Tareas Técnicas)
- [ ] Implementar endpoint correspondiente
- [ ] Tests de integración
- [ ] UI de confirmación

### Criterios de aceptación
- Funcionalidad implementada según descripción
- Tests pasan en CI

### Depende de
$depends" \
    "$milestone" \
    "$labels"
done

# EPIC-06 — HU principal
create_hu_issue \
  "[HU-06-01] Ver zonas del tablero en tiempo real" \
  "## HU-06-01 — Ver zonas del tablero en tiempo real

**Épica:** EPIC-06 — Tablero y Experiencia de Juego
**Sprint:** S5/S6
**Story Points:** 5
**Equipo:** Equipo B
**Prioridad:** Alta

### Historia
Como jugador en una partida, quiero ver todas las zonas del tablero actualizadas en tiempo real para conocer el estado completo de la partida.

### Descripción técnica
GameBoardComponent Angular con todas las zonas del TCG. Estado actualizado SOLO via eventos WebSocket (nunca optimista). Contraste AA en HP y condiciones.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-06-01 GameBoardComponent con zonas: oponente (activo+banca como dorsos, contadores), propia (activo+banca con imágenes, mano, premios)
- [ ] TT-06-02 HP visible en número y barra de progreso
- [ ] TT-06-03 Iconos de condición (POISONED, BURNED, PARALYZED, CONFUSED, ASLEEP)
- [ ] TT-06-04 Estado renderizado desde evento WebSocket (nunca modificado localmente antes de confirmación)
- [ ] TT-06-05 Contraste AA en HP y condiciones (accesibilidad)
- [ ] TT-06-06 Render < 16ms por frame (trackBy en *ngFor)

### Criterios de aceptación
- Todas las zonas del tablero son visibles y distinguibles
- HP y condiciones se actualizan en tiempo real vía WebSocket
- La mano del oponente se muestra como dorsos (sin revelar cartas)
- Contraste AA en todos los elementos de información crítica

### Rama sugerida
\`feature/tablero/hu-06-01-zonas-tablero\`

### Depende de
HU-04-09 (motor con WebSocket), HU-05-05" \
  "S5 — PvE jugable" \
  "historia,Frontend,Testing"

# Resto HU-06
for hu_data in \
  "HU-06-02|Drag & drop de cartas en el tablero|Como jugador, quiero arrastrar cartas desde mi mano al tablero para jugar Pokémon, adjuntar energías y evolucionar.|S6|8|B|S6 — Tablero pulido + Lobby|historia,Frontend,Testing|HU-06-01" \
  "HU-06-03|Animaciones de daño, KO y status|Como jugador, quiero ver animaciones cuando se inflije daño, hay un KO o se aplica una condición de status.|S6|5|B|S6 — Tablero pulido + Lobby|historia,Frontend|HU-06-01" \
  "HU-06-04|Lobby con selección de 3 modos de juego|Como jugador, quiero acceder a un lobby con 3 modos (PvE, Ranked, Sala privada) para elegir cómo quiero jugar.|S6|5|B|S6 — Tablero pulido + Lobby|historia,Frontend|HU-03-05" \
  "HU-06-05|Chat de partida en tiempo real|Como jugador, quiero enviar mensajes en el chat durante la partida para comunicarme con mi rival o con el bot.|S6|3|B|S6 — Tablero pulido + Lobby|historia,Frontend,Backend|HU-06-01" \
  "HU-06-06|Layout responsive mobile/tablet/desktop|Como jugador mobile, quiero que el tablero sea usable en pantallas desde 360px para jugar desde cualquier dispositivo.|S11|5|B|S11 — Pulido + bots + E2E|historia,Frontend,Testing|HU-06-01"; do
  IFS='|' read -r hu_id hu_name hu_historia sprint sp equipo milestone labels depends <<< "$hu_data"
  create_hu_issue \
    "[$hu_id] $hu_name" \
    "## $hu_id — $hu_name

**Épica:** EPIC-06 — Tablero y Experiencia de Juego
**Sprint:** $sprint
**Story Points:** $sp
**Equipo:** Equipo $equipo

### Historia
$hu_historia

### Checklist técnico (Tareas Técnicas)
- [ ] Implementar componente/funcionalidad correspondiente
- [ ] Tests en Chrome, Firefox y Safari
- [ ] Verificar en mobile/tablet si aplica

### Criterios de aceptación
- Funcionalidad implementada según descripción
- Tests de compatibilidad pasan
- Sin regresiones en funcionalidades existentes

### Depende de
$depends" \
    "$milestone" \
    "$labels"
done

# EPIC-07 — HU principal
create_hu_issue \
  "[HU-07-02] Comprar Codemon Coins con Mercado Pago" \
  "## HU-07-02 — Comprar Codemon Coins con Mercado Pago

**Épica:** EPIC-07 — Tienda y Monetización
**Sprint:** S8
**Story Points:** 8
**Equipo:** Equipo C
**Prioridad:** Alta

### Historia
Como jugador, quiero comprar Codemon Coins usando Mercado Pago para poder adquirir sobres de cartas y ampliar mi colección.

### Descripción técnica
PaymentService crea preferencias MP. Webhook público recibe confirmación. WalletService idempotente (mismo mp_event_id no duplica coins). MP sandbox en dev.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-07-01 Tabla wallet_transactions con índices; tabla payment_records con mp_event_id UNIQUE
- [ ] TT-07-02 PaymentService.createPreference() con MP SDK; sandbox en dev
- [ ] TT-07-03 POST /webhooks/mercado-pago (público, sin JWT): valida firma MP; idempotencia por mp_event_id
- [ ] TT-07-04 WalletService.creditCoins() @Transactional: actualiza balance Y registra fila
- [ ] TT-07-05 GET /users/me/wallet devuelve balance actual
- [ ] TT-07-06 Test: replay del mismo mp_event_id no duplica coins
- [ ] TT-07-07 Test invariante: SUM(wallet_transactions.delta) == users.virtual_currency_balance

### Criterios de aceptación
- Webhook MP idempotente: mismo evento procesado 2 veces no duplica coins
- Balance en users siempre coincide con la suma de wallet_transactions.delta
- Rate-limit 10 req/min/usuario en crear preferencia

### Rama sugerida
\`feature/tienda/hu-07-02-mercado-pago\`

### Depende de
HU-01-01 (auth)" \
  "S8 — Tienda + 2FA + métricas" \
  "historia,Backend,DB,Testing"

# Resto HU-07
for hu_data in \
  "HU-07-01|Ver balance de coins en wallet|Como jugador, quiero ver mi balance de Codemon Coins en todo momento para saber cuánto puedo gastar.|S8|2|C+B|S8 — Tienda + 2FA + métricas|historia,Backend,Frontend|HU-07-02" \
  "HU-07-03|Comprar sobre de cartas con coins|Como jugador, quiero comprar un sobre con mis Codemon Coins para obtener nuevas cartas.|S8|5|C|S8 — Tienda + 2FA + métricas|historia,Backend,DB,Testing|HU-07-02" \
  "HU-07-04|Abrir sobre con animación de revelación|Como jugador, quiero ver una animación de revelación carta por carta al abrir un sobre para que sea emocionante.|S8|5|C+B|S8 — Tienda + 2FA + métricas|historia,Backend,Frontend|HU-07-03" \
  "HU-07-05|Cooldown de 24h entre sobres|Como sistema, quiero aplicar un cooldown de 24h entre aperturas de sobre para controlar la distribución de cartas.|S8|3|C|S8 — Tienda + 2FA + métricas|historia,Backend|HU-07-04" \
  "HU-07-06|Ver historial de pagos|Como jugador, quiero ver el historial de mis pagos y transacciones de wallet para tener control de mis gastos.|S10|3|C+B|S10 — OAuth + Perfil|historia,Backend,Frontend|HU-07-02"; do
  IFS='|' read -r hu_id hu_name hu_historia sprint sp equipo milestone labels depends <<< "$hu_data"
  create_hu_issue \
    "[$hu_id] $hu_name" \
    "## $hu_id — $hu_name

**Épica:** EPIC-07 — Tienda y Monetización
**Sprint:** $sprint
**Story Points:** $sp
**Equipo:** Equipo $equipo

### Historia
$hu_historia

### Checklist técnico (Tareas Técnicas)
- [ ] Implementar endpoint y lógica de negocio
- [ ] Tests de integración con escenarios de error
- [ ] UI correspondiente

### Criterios de aceptación
- Funcionalidad implementada según descripción
- Tests pasan incluyendo casos de error y edge cases

### Depende de
$depends" \
    "$milestone" \
    "$labels"
done

# EPIC-08 — HU principal
create_hu_issue \
  "[HU-08-01] Bot EASY — oponente aleatorio" \
  "## HU-08-01 — Bot EASY — oponente aleatorio

**Épica:** EPIC-08 — Bot e Inteligencia Artificial
**Sprint:** S5
**Story Points:** 5
**Equipo:** Equipo A
**Prioridad:** Alta

### Historia
Como jugador, quiero practicar contra un bot de dificultad fácil que tome decisiones aleatorias para aprender el juego sin presión.

### Descripción técnica
BotEasy implementa BotStrategy eligiendo acción aleatoria de getAvailableActions(). Delay async 500-1000ms. Garantía de no loop infinito via fallback END_TURN.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-08-01 Interface BotStrategy con chooseAction(GameContext): GameAction
- [ ] TT-08-02 BotEasy: elige acción aleatoria de getAvailableActions(); vacía → END_TURN
- [ ] TT-08-03 Delay async 500-1000ms (simula pensamiento)
- [ ] TT-08-04 GameEngine detecta turno de BOT y llama botService.playTurn()
- [ ] TT-08-05 Test: 100 partidas PvE EASY consecutivas sin excepción 500

### Criterios de aceptación
- Partida PvE EASY llega a GAME_OVER sin errores
- Bot responde en 500-1000ms
- 100 partidas consecutivas sin excepción

### Rama sugerida
\`feature/bot/hu-08-01-bot-easy\`

### Depende de
HU-04-09 (motor completo)" \
  "S5 — PvE jugable" \
  "historia,Backend,Testing"

# Resto HU-08
for hu_data in \
  "HU-08-02|Bot MEDIUM con estrategia greedy|Como jugador, quiero practicar contra un bot de dificultad media que tome la mejor decisión inmediata para un desafío mayor.|S11|8|A|S11 — Pulido + bots + E2E|historia,Backend,Testing|HU-08-01" \
  "HU-08-03|Bot HARD con algoritmo minimax|Como jugador avanzado, quiero practicar contra un bot difícil que planifique varios turnos para el mayor desafío posible.|S11|13|A|S11 — Pulido + bots + E2E|historia,Backend,Testing|HU-08-02" \
  "HU-08-04|Elegir personalidad del bot en el lobby PvE|Como jugador, quiero elegir la personalidad del bot antes de la partida para una experiencia más personalizada.|S11|3|A|S11 — Pulido + bots + E2E|historia,Backend,Frontend|HU-08-01" \
  "HU-08-05|Mensajes del bot con personalidad en el chat|Como jugador, quiero que el bot envíe mensajes en el chat con su personalidad durante la partida.|S11|5|A|S11 — Pulido + bots + E2E|historia,Backend,Frontend|HU-08-04"; do
  IFS='|' read -r hu_id hu_name hu_historia sprint sp equipo milestone labels depends <<< "$hu_data"
  create_hu_issue \
    "[$hu_id] $hu_name" \
    "## $hu_id — $hu_name

**Épica:** EPIC-08 — Bot e Inteligencia Artificial
**Sprint:** $sprint
**Story Points:** $sp
**Equipo:** Equipo $equipo

### Historia
$hu_historia

### Checklist técnico (Tareas Técnicas)
- [ ] Implementar BotStrategy correspondiente
- [ ] Tests de comportamiento documentados
- [ ] Garantía de no bloqueo del backend

### Criterios de aceptación
- Funcionalidad implementada según descripción
- Tests de comportamiento pasan
- Sin bloqueo del thread del backend

### Depende de
$depends" \
    "$milestone" \
    "$labels"
done

# EPIC-09 — HU principal
create_hu_issue \
  "[HU-09-07] Progresión por ligas (Bronce/Plata/Oro)" \
  "## HU-09-07 — Progresión por ligas (Bronce/Plata/Oro)

**Épica:** EPIC-09 — Social y Comunidad
**Sprint:** S9
**Story Points:** 5
**Equipo:** Equipo C + Equipo B
**Prioridad:** Alta

### Historia
Como jugador competitivo, quiero ganar puntos de ranking al ganar partidas y subir de liga (Bronce → Plata → Oro) para tener un objetivo de progresión claro.

### Descripción técnica
+25 puntos en victoria en QUEUE/ROOM. Liga cambia al cruzar umbrales (1000=PLATA, 2500=ORO). Vista materializada leaderboard con REFRESH CONCURRENTLY.

### Checklist técnico (Tareas Técnicas)
- [ ] TT-09-01 Campo users.league con BRONCE/PLATA/ORO; campo users.skillRating
- [ ] TT-09-02 Vista materializada leaderboard (V11) con índice único
- [ ] TT-09-03 RankingService.addWinPoints() desde VictoryConditionChecker en QUEUE/ROOM
- [ ] TT-09-04 +25 puntos en victoria; 0 en derrota; 0 en PvE
- [ ] TT-09-05 Actualizar users.league al cruzar umbral
- [ ] TT-09-06 GET /leaderboard?filter=pvp P95 < 200ms via vista materializada
- [ ] TT-09-07 Test: cruce de umbral 1000 → liga PLATA

### Criterios de aceptación
- Victoria en QUEUE suma 25 puntos; PvE no suma
- Al acumular 1000 puntos la liga cambia a PLATA
- GET /leaderboard responde en < 200ms
- Leaderboard excluye partidas que no son QUEUE

### Rama sugerida
\`feature/social/hu-09-07-ligas-ranking\`

### Depende de
HU-04-09 (victoria), HU-09-05" \
  "S9 — Social v1" \
  "historia,Backend,Frontend,DB,Testing"

# Resto HU-09
for hu_data in \
  "HU-09-01|Perfil consolidado propio|Como jugador, quiero ver mi perfil con todas mis estadísticas, colección y últimas partidas en un solo lugar.|S10|5|C+B|S10 — OAuth + Perfil|historia,Backend,Frontend,DB|HU-09-07" \
  "HU-09-02|Perfil público de otro jugador|Como jugador, quiero ver el perfil público de otro jugador para conocer sus estadísticas sin ver datos privados.|S10|3|C+B|S10 — OAuth + Perfil|historia,Backend,Frontend|HU-09-01" \
  "HU-09-03|Solicitar y gestionar amistad|Como jugador, quiero enviar y recibir solicitudes de amistad para construir mi red social en Codemon TCG.|S9|5|C+B|S9 — Social v1|historia,Backend,Frontend,Testing|HU-01-01" \
  "HU-09-04|Presencia en tiempo real de amigos|Como jugador, quiero ver si mis amigos están online, jugando o desconectados en tiempo real.|S9|5|C+B|S9 — Social v1|historia,Backend,Frontend|HU-09-03" \
  "HU-09-05|Leaderboard global|Como jugador, quiero ver el ranking global de los mejores jugadores para saber mi posición relativa.|S9|3|C+B|S9 — Social v1|historia,Backend,Frontend,DB|HU-09-07" \
  "HU-09-06|Mi posición en el ranking|Como jugador, quiero ver mi posición exacta en el ranking con puntos y liga actual.|S9|2|C+B|S9 — Social v1|historia,Backend,Frontend|HU-09-05" \
  "HU-09-08|Leer noticias del juego|Como jugador, quiero leer las últimas noticias de Codemon TCG para estar al tanto de actualizaciones y eventos.|S9|3|C+B|S9 — Social v1|historia,Backend,Frontend|HU-01-01"; do
  IFS='|' read -r hu_id hu_name hu_historia sprint sp equipo milestone labels depends <<< "$hu_data"
  create_hu_issue \
    "[$hu_id] $hu_name" \
    "## $hu_id — $hu_name

**Épica:** EPIC-09 — Social y Comunidad
**Sprint:** $sprint
**Story Points:** $sp
**Equipo:** Equipo $equipo

### Historia
$hu_historia

### Checklist técnico (Tareas Técnicas)
- [ ] Implementar endpoint y lógica de negocio
- [ ] UI correspondiente
- [ ] Tests de autorización (403 para datos privados)

### Criterios de aceptación
- Funcionalidad implementada según descripción
- Datos privados no expuestos a terceros
- Tests pasan en CI

### Depende de
$depends" \
    "$milestone" \
    "$labels"
done

# =============================================================================
# RESUMEN FINAL
# =============================================================================
echo ""
echo "========================================"
echo " SETUP COMPLETADO"
echo "========================================"
echo " Labels creados:      $LABELS_CREATED"
echo " Milestones creados:  $MILESTONES_CREATED"
echo " Issues creados:      $ISSUES_CREATED"
echo ""
echo " Próximos pasos:"
echo " 1. Crear el GitHub Project v2 manualmente en:"
echo "    https://github.com/$REPO/projects"
echo " 2. Agregar todos los issues al Project con:"
echo "    gh project item-add <PROJECT_NUM> --owner <OWNER> --url <ISSUE_URL>"
echo " 3. Configurar los campos del Project según .github/project-fields.yml"
echo " 4. Setear GH_PROJECT_NUMBER en los variables del repo para el workflow"
echo "    gh variable set GH_PROJECT_NUMBER --body '1' --repo $REPO"
echo ""
echo " Documentación: .github/project-fields.yml"
echo "========================================"
