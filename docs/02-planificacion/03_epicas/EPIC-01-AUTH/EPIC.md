# EPIC-01 — Autenticacion y Seguridad

## 1. Resumen

- **Valor de negocio:** los jugadores pueden crear una cuenta segura, verificarla, iniciar sesion (incluso con redes sociales) y mantener sesion activa con expiracion de tokens. Sin esta epica nadie puede usar el resto del producto.
- **Roles involucrados:** Jugador anonimo, Jugador autenticado, Sistema (envio de mails y validaciones).
- **Sprints donde se completa:** S1 (registro, login, logout, refresh) y S8 (2FA por email, OAuth2).
- **Equipos:** A (backend nucleo), B (frontend Angular), C (auxiliar para 2FA, OAuth2 y rate limit).

## 2. Historias de Usuario

### HU-01-01 — Registro con email y password
**Como** visitante anonimo, **quiero** crear una cuenta con email + password, **para** poder iniciar sesion y armar mazos.

**Story Points:** 5

**Criterios de Aceptacion (funcionales):**
- AC1: Dado un email valido y password >=8 chars con 1 mayuscula y 1 numero, cuando llamo `POST /auth/register`, entonces el sistema crea el usuario en estado `email_verified=false` y responde 201.
- AC2: Si el email ya esta registrado, el sistema responde 409 con mensaje `EMAIL_ALREADY_REGISTERED` sin filtrar info adicional.
- AC3: La password no se devuelve en ninguna respuesta ni se loguea.
- AC4: Tras registro exitoso el sistema dispara envio asincrono del codigo de verificacion (HU-01-02).

**Requerimientos No Funcionales:**
- RNF-Seguridad: hashing BCrypt cost 10 minimo; sin secrets en logs.
- RNF-Performance: P95 < 500 ms (registro + envio asincrono no bloqueante).
- RNF-Usabilidad: feedback de error de validacion de cliente < 200 ms post-submit.

**Dependencias:** TT-10-01 (BD migrada con tabla `users`), HU-01-02.
**Sprint:** S1.

---

### HU-01-02 — Verificar cuenta vio codigo enviado al email
**Como** usuario recien registrado, **quiero** confirmar mi email con un codigo de 6 digitos, **para** demostrar que el email es mio y poder loguearme.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: Recibo en mi email un codigo de 6 digitos numericos en menos de 30 segundos despues de registrarme.
- AC2: Al ingresar el codigo correcto en `POST /auth/verify-email`, mi cuenta queda con `email_verified=true` y recibo `accessToken + refreshToken`.
- AC3: El codigo expira a los 30 minutos; al expirarse, intentar usarlo devuelve 410 `CODE_EXPIRED`.
- AC4: Tras 5 intentos fallidos consecutivos, mi cuenta queda bloqueada 15 minutos para verificacion (mensaje `TOO_MANY_ATTEMPTS`).
- AC5: Existe `POST /auth/resend-code` con rate-limit de 1 envio cada 60 s.

**Requerimientos No Funcionales:**
- RNF-Seguridad: codigo generado con `SecureRandom`, hasheado con BCrypt en BD; rate-limit persistido (no en memoria volatil).
- RNF-Performance: envio de email asincrono (`@Async`).
- RNF-Privacidad: el bloqueo no debe revelar si el email existe.

**Dependencias:** HU-01-01, TT-01-01 (mailer SMTP / Mailtrap configurado).
**Sprint:** S8 (la verificacion estricta entra en S8; en S1 los registros van con `email_verified=true` temporal segun PASO_S01_01).

---

### HU-01-03 — Iniciar sesion
**Como** usuario verificado, **quiero** loguearme con email + password, **para** acceder a mi perfil, mazos y partidas.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: `POST /auth/login` con credenciales correctas devuelve `accessToken` (JWT, 15 min) y `refreshToken` (UUID, 7 dias).
- AC2: Credenciales incorrectas devuelven 401 `BAD_CREDENTIALS` sin distinguir si el email no existe o la password es incorrecta.
- AC3: Si `email_verified=false`, el login responde 403 `EMAIL_NOT_VERIFIED`.
- AC4: El refresh token se persiste en `refresh_tokens` con flag `revoked=false`.
- AC5: El frontend guarda los tokens y redirige a `/home`.

**RNF:**
- RNF-Seguridad: JWT firmado HS256, secret >=32 chars desde `codemon.jwt.secret`.
- RNF-Performance: P95 < 300 ms.

**Dependencias:** HU-01-01, HU-01-02.
**Sprint:** S1.

---

### HU-01-04 — Cerrar sesion (logout)
**Como** usuario logueado, **quiero** cerrar sesion, **para** que mi token deje de servir incluso si alguien lo copia.

**Story Points:** 2

**Criterios de Aceptacion:**
- AC1: `POST /auth/logout` revoca el refresh token actual (`revoked=true`).
- AC2: Tras logout, intentar usar ese refresh token responde 401.
- AC3: El frontend elimina los tokens del `localStorage` y redirige a `/auth/login`.

**RNF:**
- RNF-Seguridad: revocacion atomica en BD; sin race condition.
- RNF-Auditoria: registrar logout en metricas (`codemon_logout_total`).

**Dependencias:** HU-01-03.
**Sprint:** S1.

---

### HU-01-05 — Renovar sesion sin reingresar credenciales
**Como** usuario activo, **quiero** que mi sesion se renueve automaticamente al expirar el access token, **para** no tener que loguearme cada 15 minutos.

**Story Points:** 3

**Criterios de Aceptacion:**
- AC1: `POST /auth/refresh` con refresh token valido emite un nuevo access token.
- AC2: Si el refresh token esta revocado o expirado, responde 401 `REFRESH_TOKEN_INVALID`.
- AC3: El interceptor del frontend detecta 401 con codigo `TOKEN_EXPIRED`, llama refresh y reintenta la request original transparente al usuario.

**RNF:**
- RNF-Performance: la renovacion debe ocurrir sin bloquear la UI > 200 ms.
- RNF-Seguridad: rotacion del refresh token opcional (post-MVP).

**Dependencias:** HU-01-03.
**Sprint:** S1.

---

### HU-01-06 — Segundo factor por email (2FA)
**Como** usuario que valora su cuenta, **quiero** que cada login me pida un codigo enviado al email, **para** evitar accesos no autorizados aunque alguien sepa mi password.

**Story Points:** 5

**Criterios de Aceptacion:**
- AC1: `POST /auth/login` con 2FA activo responde 200 con `requires2FA=true` y `verificationToken` temporal (sin tokens definitivos).
- AC2: El usuario recibe un codigo 2FA por email.
- AC3: `POST /auth/2fa/verify` con `verificationToken` + codigo correcto devuelve `accessToken + refreshToken`.
- AC4: 5 intentos fallidos bloquean 2FA por 15 minutos.

**RNF:**
- RNF-Seguridad: codigo de un solo uso; `verificationToken` invalido tras consumirse.
- RNF-Performance: envio asincrono.

**Dependencias:** HU-01-02, HU-01-03.
**Sprint:** S8.

---

### HU-01-07 — Login social con Google y GitHub (OAuth2)
**Como** usuario, **quiero** entrar con Google o GitHub, **para** no tener que crear otra cuenta.

**Story Points:** 8

**Criterios de Aceptacion:**
- AC1: Botones "Continuar con Google" y "Continuar con GitHub" en `/auth/login` redirigen a `/oauth2/authorization/{provider}`.
- AC2: Tras autorizar, el backend genera su propio JWT (no usa el token del proveedor).
- AC3: Usuario nuevo via OAuth: `email_verified=true`, `password_hash=null`, no rompe el login normal.
- AC4: Usuario existente con mismo email: se vincula sin duplicar cuenta.
- AC5: Si GitHub no expone email publico, se muestra error claro.
- AC6: El frontend recibe el token via `/auth/callback?token=...&refreshToken=...`.

**RNF:**
- RNF-Seguridad: el JWT del proveedor nunca se guarda; URIs registradas en consola Google/GitHub.
- RNF-Configuracion: secrets via env vars (`GOOGLE_CLIENT_ID/SECRET`, `GITHUB_CLIENT_ID/SECRET`).

**Dependencias:** HU-01-03.
**Sprint:** S10.

## 3. Tareas Tecnicas (no son HU)

| ID | Tarea | Origen | Equipo | SP | Sprint |
|---|---|---|---|---|---|
| TT-01-01 | Configurar SMTP (Mailtrap dev) y `EmailService` con `@Async` | PASO_S08_03 | C | 3 | S8 |
| TT-01-02 | Migracion Flyway de tabla `email_verifications` y `refresh_tokens` (V2-V3) | PASO_S00_05 | A | 2 | S0 |
| TT-01-03 | `JwtTokenProvider`, `JwtAuthenticationFilter` y `SecurityConfig` con rutas publicas | PASO_S01_01 | A | 5 | S1 |
| TT-01-04 | Interceptor Angular con refresh automatico (`HttpJwtInterceptor`) | PASO_S01_02, PASO_S01_03 | B | 3 | S1 |
| TT-01-05 | `AuthGuard` y `EmailVerifiedGuard` Angular | PASO_S01_03 | B | 2 | S1 / S8 |
| TT-01-06 | Bucket4j para rate-limit en `verify-email` y `resend-code` | PASO_S08_03 | C | 3 | S8 |
| TT-01-07 | Configuracion OAuth2 Google + GitHub en Spring Security | PASO_S10_01 | C | 5 | S10 |
| TT-01-08 | Componente `/auth/callback` y boton social Angular | PASO_S10_02 | B | 3 | S10 |

## 4. Contratos involucrados

- REST: `POST /auth/register`, `POST /auth/login`, `POST /auth/logout`, `POST /auth/refresh`, `POST /auth/verify-email`, `POST /auth/resend-code`, `POST /auth/2fa/verify`, `GET /auth/me`, `/oauth2/authorization/google`, `/oauth2/authorization/github`.
- STOMP: ninguno.
- Detalle completo: [CONTRATOS_API.md](../../../../docs/05-referencia-tecnica/CONTRATOS_API.md).

## 5. Definition of Done especifico

- Cobertura unitaria ≥ 85% en `AuthService`, `JwtTokenProvider`, `EmailService`.
- Tests integracion con Testcontainers cubriendo: registro, verify, login, logout, refresh, OAuth2 con servidor mock.
- Rate-limit verificado: 5 intentos verify → 429; 1 resend / 60 s.
- Mailtrap captura emails en dev; en prod variables SMTP definidas.
- Endpoints documentados en Swagger, ejemplos de payload listados.
- Hereda [DOD.md](../../04_proceso/DOD.md) global.
