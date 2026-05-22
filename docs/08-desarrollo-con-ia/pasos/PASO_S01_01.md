---
id: PASO_S01_01
equipo: A
bloque: 1
dep: [PASO_S00_05]
siguiente: PASO_S01_02
context_files:
  - BD_Y_TABLAS.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/auth/entity/User.java
  - api/src/main/java/com/codemon/auth/entity/RefreshToken.java
  - api/src/main/java/com/codemon/auth/repository/UserRepository.java
  - api/src/main/java/com/codemon/auth/repository/RefreshTokenRepository.java
  - api/src/main/java/com/codemon/auth/dto/RegisterRequest.java
  - api/src/main/java/com/codemon/auth/dto/LoginRequest.java
  - api/src/main/java/com/codemon/auth/dto/AuthResponse.java
  - api/src/main/java/com/codemon/auth/dto/RefreshTokenRequest.java
  - api/src/main/java/com/codemon/auth/service/JwtTokenProvider.java
  - api/src/main/java/com/codemon/auth/service/AuthService.java
  - api/src/main/java/com/codemon/auth/controller/AuthController.java
  - api/src/main/java/com/codemon/shared/security/JwtAuthenticationFilter.java
  - api/src/main/java/com/codemon/shared/config/SecurityConfig.java
  - api/src/main/java/com/codemon/shared/exception/GlobalExceptionHandler.java
  - api/src/test/java/com/codemon/auth/AuthServiceTest.java
---

# PASO 1.2 — Autenticación básica (sin 2FA)
**Grupo legacy:** 1 — Features Core | **Equipo:** A | **Dificultad:** 🟡 | **Tiempo:** 4–6 h

## Navegación
← **Anterior:** [PASO_S00_SMOKE](PASO_S00_SMOKE.md) — Sprint 0 completado (infra lista)
→ **Siguiente:** [PASO_S01_02](PASO_S01_02.md) — Auth UI Angular (login, registro)

## Archivos a cargar junto a este
- `SCHEMA_BD.sql` → bloque V1 (tabla users, refresh_tokens) y bloque V2 (solo para referencia de estructura)

## Qué construye este paso
El sistema completo de autenticación: registro, login, refresh token y logout con JWT. Sin verificación de email por ahora (se agrega en PASO_S08_03).

## Prompt listo para el agente

```
Implementá la autenticación básica para un proyecto Spring Boot 3.3.x con Java 21.
Stack: Spring Security 6, JWT (jjwt 0.12.6), Spring Data JPA, PostgreSQL.

Schema de BD:
[pegá el bloque V1 de SCHEMA_BD.sql]

Implementá estas clases en el paquete com.codemon.auth:

ENTITIES:
- User.java → mapea la tabla "users" con todos sus campos
- RefreshToken.java → mapea "refresh_tokens"

REPOSITORIES:
- UserRepository.java → findByEmail, findByUsername, existsByEmail, existsByUsername
- RefreshTokenRepository.java → findByTokenHash, deleteByUserId

DTOs:
- RegisterRequest.java → username, email, password, confirmPassword (con validaciones @NotBlank, @Email, @Size)
- LoginRequest.java → email, password
- AuthResponse.java → accessToken, refreshToken, expiresIn
- RefreshTokenRequest.java → refreshToken

SERVICIOS:
- JwtTokenProvider.java → generateAccessToken(User), generateRefreshToken(), validateToken(token), extractUserId(token)
  El secreto viene de @Value("${codemon.jwt.secret}")
- AuthService.java → register(RegisterRequest), login(LoginRequest), refresh(String refreshToken), logout(String refreshToken)
  IMPORTANTE: en register, setear email_verified = TRUE por ahora (2FA se agrega después)

SEGURIDAD:
- JwtAuthenticationFilter.java → extiende OncePerRequestFilter, lee el header Authorization: Bearer {token}
- SecurityConfig.java → rutas públicas: /auth/**, /cards/**, /swagger-ui/**, /v3/api-docs/**
  Rutas protegidas: todo lo demás

CONTROLADOR:
- AuthController.java → POST /auth/register, POST /auth/login, POST /auth/refresh, POST /auth/logout
- GlobalExceptionHandler.java → maneja UsernameNotFoundException, BadCredentialsException, etc.

TESTS - AuthServiceTest.java:
- register exitoso → user creado, email_verified=true
- login exitoso → retorna tokens
- password incorrecta → BadCredentialsException
- email duplicado → error apropiado
- refresh token válido → nuevo access token
- refresh token inválido → error

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea
```
api/src/main/java/com/codemon/auth/
  entity/User.java
  entity/RefreshToken.java
  repository/UserRepository.java
  repository/RefreshTokenRepository.java
  dto/RegisterRequest.java
  dto/LoginRequest.java
  dto/AuthResponse.java
  dto/RefreshTokenRequest.java
  service/JwtTokenProvider.java
  service/AuthService.java
  controller/AuthController.java
api/src/main/java/com/codemon/shared/
  security/JwtAuthenticationFilter.java
  config/SecurityConfig.java
  exception/GlobalExceptionHandler.java
api/src/test/java/com/codemon/auth/AuthServiceTest.java
```

## Errores comunes

- **Circular dependency en SecurityConfig**: usar `@Lazy` en la inyección de `AuthService`
- **JWT_SECRET menor a 32 chars**: error al iniciar, el secreto debe ser al menos 256 bits
- **BCrypt rounds muy altos**: usar 10 (default), valores más altos hacen el login lento en tests
- **email_verified = false por defecto**: recordar setearlo a `true` en register (2FA viene después)

## Verificación

```bash
TOKEN=$(curl -s -X POST http://localhost:8088/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"ash","email":"ash@test.com","password":"Test123!","confirmPassword":"Test123!"}' \
  | python3 -c "import sys,json; print('')")
echo "Registro: OK"
# PASS: "Registro: OK" (sin error 4xx)
# FAIL: {"error":"..."} → revisar validaciones de RegisterRequest

TOKENS=$(curl -s -X POST http://localhost:8088/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ash@test.com","password":"Test123!"}')
echo $TOKENS | python3 -m json.tool
# PASS: {"accessToken":"eyJ...","refreshToken":"...","expiresIn":900}
# FAIL: 401 → verificar email_verified=true en register

# Endpoint protegido sin token → 401
curl -s -o /dev/null -w "%{http_code}" http://localhost:8088/decks
# PASS: 401
# FAIL: 200 o 403 → revisar SecurityConfig (rutas protegidas)
```

## Dependencias
PASO_S00_05 completado (tabla users en BD).

---

## Entrega al siguiente paso

Tras completar este PASO, los siguientes (PASO_S02_02, PASO_S01_02, PASO_S08_03) pueden asumir:

- **Endpoints REST disponibles** (ver [CONTRATOS_API.md](../../05-referencia-tecnica/CONTRATOS_API.md)):
  - `POST /api/auth/register` → 201 con `{message, userId}`
  - `POST /api/auth/login` → 200 con `AuthResponse {accessToken, refreshToken, user}`
  - `POST /api/auth/refresh` → 200 con tokens nuevos
  - `POST /api/auth/logout` → 200 (invalida refresh token)
- **Bean Spring autowireable**: `JwtService` con métodos `generateAccessToken(User)`, `validateToken(String)`, `extractClaims(String)`
- **Filtro de seguridad activo**: `SecurityConfig` protege todas las rutas excepto `/api/auth/**` y `/actuator/**`
- **Tabla `users`** poblada con campos del [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md) sección 2
- **Tabla `refresh_tokens`** funcional para rotación
- Para PASO_S08_03: el `User` tiene `emailVerified` flag listo para extender con código 2FA

---

## Definition of Done

- [ ] Todos los archivos de `outputs:` existen
- [ ] `./verify_paso.sh PASO_S01_01` retorna exit 0
- [ ] Tests pasan con cobertura ≥ 80% en `com.codemon.auth`
- [ ] El endpoint `/api/auth/login` con credenciales válidas devuelve JWT que funciona en endpoints protegidos
- [ ] Endpoints protegidos sin Authorization header devuelven 401
- [ ] Naming respeta [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md): `User`, `RefreshToken`, `JwtService`, `AuthController` en paquetes correctos
- [ ] Sin TODOs ni FIXMEs en el código entregado
