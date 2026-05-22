---
id: PASO_S10_01
equipo: C+B
bloque: 10
dep: [PASO_S01_01, PASO_S00_04]
siguiente: PASO_S10_02
context_files:
  - BD_Y_TABLAS.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/auth/entity/UserOAuthAccount.java
  - api/src/main/java/com/codemon/auth/repository/UserOAuthAccountRepository.java
  - api/src/main/java/com/codemon/auth/service/OAuth2UserService.java
  - api/src/main/java/com/codemon/auth/handler/OAuth2SuccessHandler.java
  - api/src/main/java/com/codemon/auth/service/AuthService.java
  - api/src/main/java/com/codemon/shared/config/SecurityConfig.java
  - front/src/app/auth/pages/oauth-callback/oauth-callback.component.ts
  - front/src/app/auth/pages/login/login.component.html
  - api/src/test/java/com/codemon/auth/OAuth2UserServiceTest.java
---

# PASO 5.4 — Login con Google y GitHub (OAuth2)
**Grupo legacy:** 5 — Features Finales | **Equipo:** C (backend) + B (frontend) | **Dificultad:** 🔴 | **Tiempo:** 5–7 h

## Navegación
← **Anterior:** [PASO_S09_03](PASO_S09_03.md) — Sección de noticias completada
→ **Siguiente:** *(último paso del proyecto — pasar a QA final y CODEMON_CHECKLIST.md)*

## Archivos a cargar junto a este
- `SCHEMA_BD.sql` → bloque V15 (tabla user_oauth_accounts)

## Qué construye este paso
Login social con Google y GitHub. Si el usuario ya tiene cuenta con ese email, la vincula automáticamente. Si no, crea una cuenta nueva. El resultado final es un JWT propio del sistema (no el token de OAuth).

## Flujo OAuth2

```
Usuario hace clic "Iniciar con Google"
→ Frontend redirige a /oauth2/authorization/google
→ Google autentica al usuario
→ Spring redirige a /oauth2/callback con código de autorización
→ Spring intercambia código por datos del usuario (email, name, picture)
→ Backend: buscar UserOAuthAccount por (provider="google", providerId)
  Si existe → usar el User vinculado
  Si no existe → buscar User por email
    Si hay User → crear UserOAuthAccount (vincular)
    Si no hay → crear User nuevo (email_verified=TRUE, password_hash=NULL)
→ Backend genera JWT propio con JwtTokenProvider.generateAccessToken(user)
→ OAuth2SuccessHandler redirige a: {frontendUrl}/auth/callback?token={jwt}&refreshToken={refresh}
→ Frontend guarda el JWT y redirige a /home
```

## Prompt listo para el agente

```
Implementá OAuth2 login con Google y GitHub para Codemon TCG.
Spring Boot 3.x, spring-boot-starter-oauth2-client.

Schema de tabla de cuentas OAuth:
[pegá bloque V15 de SCHEMA_BD.sql]

Implementá:

1. Dependencia a agregar en pom.xml:
   spring-boot-starter-oauth2-client

2. En application.yml, agregar:
   spring:
     security:
       oauth2:
         client:
           registration:
             google:
               client-id: ${GOOGLE_CLIENT_ID}
               client-secret: ${GOOGLE_CLIENT_SECRET}
               scope: email, profile
             github:
               client-id: ${GITHUB_CLIENT_ID}
               client-secret: ${GITHUB_CLIENT_SECRET}
               scope: user:email

3. UserOAuthAccount.java entity + UserOAuthAccountRepository
   Campos: id, userId, provider ("GOOGLE"|"GITHUB"), providerId, createdAt

4. OAuth2UserService.java (implements DefaultOAuth2UserService):
   loadUser(OAuth2UserRequest request):
   a. Extraer email y providerId del OAuth2User (manejo especial para GitHub: GitHub no siempre retorna email público)
   b. Buscar UserOAuthAccount por (provider, providerId)
   c. Si existe → retornar el User vinculado (actualizar last_seen_at)
   d. Si no → buscar User por email
      Si hay → crear UserOAuthAccount (vincular)
      Si no → crear User: username = parte local del email (ash@gmail.com → "ash"), verificar unicidad, email_verified=TRUE, password_hash=NULL
   e. Retornar el User

5. OAuth2SuccessHandler.java (implements AuthenticationSuccessHandler):
   - Generar JWT y refresh token con JwtTokenProvider
   - Redirigir a: ${codemon.cors.allowed-origins}/auth/callback?token={jwt}&refreshToken={refresh}

6. Modificar SecurityConfig.java:
   .oauth2Login()
     .userInfoEndpoint().userService(oAuth2UserService)
     .successHandler(oAuth2SuccessHandler)
   Agregar permitAll() para /oauth2/** y /login/oauth2/**

7. Frontend - auth/callback component (src/app/auth/pages/oauth-callback/):
   - Leer ?token= y ?refreshToken= de la URL
   - Guardar en localStorage (igual que el login normal)
   - Redirigir a /home

8. Modificar login.component.html:
   Agregar botones:
   <a href="/oauth2/authorization/google"
      class="inline-flex items-center justify-center gap-2 w-full px-4 py-2 rounded border border-red-500 text-red-600 hover:bg-red-50 transition">
     Continuar con Google
   </a>
   <a href="/oauth2/authorization/github"
      class="inline-flex items-center justify-center gap-2 w-full px-4 py-2 rounded border border-gray-800 text-gray-800 hover:bg-gray-100 transition">
     Continuar con GitHub
   </a>

TESTS:
- Nuevo usuario con Google → User creado, email_verified=true, password_hash=null
- Usuario existente con mismo email vía Google → vinculado, no duplicado
- Usuario OAuth sin contraseña → login normal con contraseña falla
- Username auto-generado si hay colisión (ash → ash2 → ash3)
- GitHub sin email público → manejar con error descriptivo

Variables de entorno a agregar en .env:
GOOGLE_CLIENT_ID=tu-google-client-id
GOOGLE_CLIENT_SECRET=tu-google-client-secret
GITHUB_CLIENT_ID=tu-github-client-id
GITHUB_CLIENT_SECRET=tu-github-client-secret

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea/modifica
```
api/src/main/java/com/codemon/auth/
  entity/UserOAuthAccount.java (nuevo)
  repository/UserOAuthAccountRepository.java (nuevo)
  service/OAuth2UserService.java (nuevo)
  handler/OAuth2SuccessHandler.java (nuevo)
  service/AuthService.java (modificar: soportar password_hash null)
api/src/main/java/com/codemon/shared/
  config/SecurityConfig.java (modificar: agregar oauth2Login)
front/src/app/auth/
  pages/oauth-callback/oauth-callback.component.ts (nuevo)
  pages/login/login.component.html (modificar: agregar botones OAuth)
api/src/test/java/com/codemon/auth/OAuth2UserServiceTest.java
```

## Errores comunes

- **Google no acepta localhost como redirect URI**: en Google Console, agregar `http://localhost:8088` como "Authorized redirect URI"
- **Email del OAuth difiere del registro manual**: vincular siempre por email, no por provider_id
- **GitHub sin email público**: usar la API de GitHub para obtener emails privados, o mostrar error descriptivo
- **password_hash null rompe el login normal**: en `AuthService.login()`, verificar que `password_hash` no es null antes de comparar

## Verificación

```bash
# Abrir en browser: http://localhost:8088/oauth2/authorization/google
# PASS: redirige a Google → tras login → llega a http://localhost:8088/auth/callback?token=eyJ...
# FAIL: error "redirect_uri_mismatch" → agregar http://localhost:8088 en Google Console

# Verificar con el token recibido
curl -H "Authorization: Bearer TOKEN_OAUTH" http://localhost:8088/users/me
# PASS: {"id":5,"username":"ash_google","email":"ash@gmail.com","oauthProvider":"GOOGLE"}
# FAIL: 401 → token OAuth2 generado incorrectamente por OAuth2SuccessHandler
```

## Dependencias
PASO_S01_01 (JwtTokenProvider, AuthService), PASO_S00_04 (SecurityConfig existente a modificar).
