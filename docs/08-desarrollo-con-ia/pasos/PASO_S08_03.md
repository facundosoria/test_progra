---
id: PASO_S08_03
equipo: C+B
bloque: 8
dep: [PASO_S01_01, PASO_S00_04]
siguiente: PASO_S08_04
context_files:
  - BD_Y_TABLAS.md
  - CODEMON_GUIAS_TECNICAS.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/auth/entity/EmailVerification.java
  - api/src/main/java/com/codemon/auth/repository/EmailVerificationRepository.java
  - api/src/main/java/com/codemon/auth/service/EmailVerificationService.java
  - api/src/main/java/com/codemon/auth/service/EmailService.java
  - api/src/main/java/com/codemon/auth/service/AuthService.java
  - api/src/main/java/com/codemon/auth/controller/AuthController.java
  - front/src/app/auth/pages/verify-email/verify-email.component.ts
  - front/src/app/auth/components/verification-code-input/verification-code-input.component.ts
  - front/src/app/shared/guards/email-verified.guard.ts
---

# PASO 4.3 — 2FA por email
**Grupo legacy:** 4 — Features Adicionales | **Equipo:** C (backend) + B (frontend) | **Dificultad:** 🟡 | **Tiempo:** 4–5 h

## Navegación
← **Anterior:** [PASO_S08_01](PASO_S08_01.md) — Sobres y colección (puede ejecutarse en paralelo con este paso)
→ **Siguiente:** [PASO_S08_04](PASO_S08_04.md) — Mercado Pago (requiere 4.2 y 4.3 completos)

## Archivos a cargar junto a este
- `SCHEMA_BD.sql` → bloque V2 (tabla email_verifications)
- `CODEMON_GUIAS_TECNICAS.md` → sección "2FA y Email Verification"

## Qué construye este paso
Verificación de email al registrarse: código de 6 dígitos con 30 minutos de validez, máximo 5 intentos antes de bloquear 15 minutos, rate limiting de 1 reenvío por minuto. Modifica el flujo de login para requerir email verificado.

## Prompt listo para el agente

```
Agregá verificación por email (2FA) al sistema de autenticación existente de Codemon TCG.
El AuthService ya existe. Ahora hay que modificarlo para que el registro requiera verificación.

Schema de la tabla email_verifications:
[pegá bloque V2 de SCHEMA_BD.sql]

Guía técnica de implementación:
[pegá sección "2FA y Email Verification" de CODEMON_GUIAS_TECNICAS.md]

Modificaciones necesarias:

1. Cambiar AuthService.register():
   - Setear email_verified = FALSE (antes era TRUE)
   - Crear EmailVerification con código hasheado
   - Enviar email async con EmailService

2. EmailVerificationService.java (nuevo):
   - generateCode(): 6 dígitos SecureRandom
   - createVerification(userId): hashear con BCrypt, guardar en BD, enviar email
   - validateCode(userId, code):
     Verificar hash, verificar no expirado (30 min desde created_at),
     Si 5 intentos fallidos: blockedUntil = now + 15 min (guardar en BD)
   - markEmailVerified(userId): email_verified = true, borrar EmailVerification
   - resendCode(userId): rate limit 1 por minuto (comparar created_at con ahora)

3. EmailService.java (@Service):
   sendVerificationCode(String email, String code) @Async
   Usar JavaMailSender con template HTML simple

4. Nuevos endpoints en AuthController:
   POST /auth/verify-email: { userId, code } → si OK retorna tokens
   POST /auth/resend-code: { userId } → rate limited

5. Modificar AuthService.login():
   Si user.email_verified == false → error "Verificá tu email antes de continuar"

6. Frontend - EmailVerifiedGuard (front/src/app/shared/guards/email-verified.guard.ts):
   Si usuario logueado pero email_verified == false → redirigir a /auth/verify-email

7. Frontend - Página verify-email (front/src/app/auth/pages/verify-email/):
   - 6 inputs numéricos que forman el código (auto-focus al siguiente al escribir)
   - Countdown de 30 minutos
   - Botón "Reenviar código" (deshabilitado los primeros 60 segundos)
   - Al completar los 6 dígitos, auto-submit

TESTS:
- Registro → email_verified=false, verification creada en BD
- Verify correcto → email_verified=true, retorna tokens
- Verify incorrecto 5 veces → bloqueado 15 min, error apropiado
- Verify expirado (código > 30 min) → error de expiración
- Login sin verificar → error "Verificá tu email"
- Resend en menos de 60 segundos → error rate limit

Aplicá las convenciones de CONVENCIONES.md.
```

## Clases que crea/modifica
```
api/src/main/java/com/codemon/auth/
  entity/EmailVerification.java (nuevo)
  repository/EmailVerificationRepository.java (nuevo)
  service/EmailVerificationService.java (nuevo)
  service/EmailService.java (nuevo)
  service/AuthService.java (modificar register y login)
  controller/AuthController.java (agregar /verify-email y /resend-code)
front/src/app/auth/
  pages/verify-email/verify-email.component.ts (nuevo)
  components/verification-code-input/verification-code-input.component.ts (nuevo)
front/src/app/shared/guards/email-verified.guard.ts (modificar)
```

## Errores comunes

- **Código en texto plano en BD**: usar BCrypt para hashear (`passwordEncoder.encode(code)`), verificar con `matches()`
- **Gmail bloqueando envíos**: para desarrollo usar Mailtrap.io (SMTP falso), no Gmail directamente
- **Rate limit sin persistencia**: el contador de intentos fallidos debe persistir en BD, no en memoria
- **Email no enviado async**: asegurarse de usar `@Async` y `@EnableAsync` en la configuración

## Verificación

```bash
# Registrar usuario → email_verified = false
curl -X POST http://localhost:8088/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"ash2","email":"ash2@test.com","password":"Test123!","confirmPassword":"Test123!"}'
# PASS: registro OK y email_verified=false en BD (verificar con SELECT)
# FAIL: error 500 → revisar @Async en EmailService y @EnableAsync en config

# Revisar Mailtrap para ver el código
# PASS: email recibido en Mailtrap con código de 6 dígitos
# FAIL: no llega email → verificar config SMTP en application.yml

# Verificar con el código recibido
curl -X POST http://localhost:8088/auth/verify-email \
  -H "Content-Type: application/json" \
  -d '{"userId":2,"code":"123456"}'
# PASS: {"accessToken":"eyJ...","refreshToken":"..."} → usuario verificado y autenticado
# FAIL: 400 → código incorrecto o expirado

# 5 intentos incorrectos → 429 Too Many Requests
# PASS: el 6to intento retorna 429 con "Bloqueado hasta..."
# FAIL: sigue intentando → contador de intentos no persiste en BD
```

## Dependencias
PASO_S01_01 (AuthService existente), PASO_S00_04 (application.yml con config de email).
