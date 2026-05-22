---
id: PASO_S01_02
equipo: B
bloque: 1
dep: [PASO_S00_06, PASO_S01_01]
siguiente: PASO_S01_03
context_files:
  - GLOSARIO.md
  - CONVENCIONES.md
  - CONTRATOS_API.md
  - MOCKS_FRONTEND.md
  - Codemon_Login.html
outputs:
  - front/src/app/auth/pages/login/login.component.ts
  - front/src/app/auth/pages/login/login.component.html
  - front/src/app/auth/pages/login/login.component.scss
  - front/src/app/auth/pages/register/register.component.ts
  - front/src/app/auth/pages/register/register.component.html
  - front/src/app/auth/pages/register/register.component.scss
  - front/src/app/auth/pages/verify-email/verify-email.component.ts
  - front/src/app/auth/pages/verify-email/verify-email.component.html
  - front/src/app/auth/services/auth.service.ts
  - front/src/app/auth/interceptors/mock-auth.interceptor.ts
  - front/src/app/auth/models/auth.models.ts
---

# PASO 1B.1 — Auth UI (Login + Register + Verify Email)
**Grupo legacy:** 1B — Frontend Core | **Equipo:** B | **Dificultad:** 🟡 | **Tiempo:** 4–5 h

## Navegación
← **Anterior:** [PASO_S00_06](PASO_S00_06.md) — Proyecto Angular creado
→ **Siguiente:** [PASO_S01_03.md](PASO_S01_03.md) — App shell + navegación

---

## Qué construye este paso

Las tres pantallas de autenticación del usuario (Login, Register, Verify Email) con validación reactiva, manejo de errores y modo mock para trabajar sin backend. Al finalizar, un usuario puede registrarse, verificar su email con código OTP de 6 dígitos, e iniciar sesión obteniendo un JWT — todo contra mocks o contra el backend real cuando esté disponible.

---

## Prerrequisitos

- PASO_S00_06 completado: proyecto Angular 21+ creado en `~/codemon/front/` con `environment.ts` que incluye `apiUrl`, `useMocks` (boolean), `mockDelayMs`.
- PASO_S01_01 puede estar en progreso por Equipo A; este paso usa MockInterceptor mientras tanto.
- `MOCKS_FRONTEND.md` cargado: define el mockInterceptor base y los JSON canónicos de `/api/auth/*`.

---

## Contratos a respetar

### Endpoints REST consumidos (definidos en CONTRATOS_API.md)
| Verbo + Path | Request | Response | Códigos |
|---|---|---|---|
| `POST /api/auth/register` | `{ email, password }` | `{ message, userId }` | 201, 409 (email duplicado), 400 |
| `POST /api/auth/login` | `{ email, password, rememberMe }` | `AuthResponse` | 200, 401, 400 |
| `POST /api/auth/verify-email` | `{ code }` | `AuthResponse` | 200, 400 (código inválido) |
| `POST /api/auth/resend-verification` | `{}` (auth header con token temporal) | `{ message }` | 200, 429 (rate limited) |

### Modelos TypeScript obligatorios (`auth.models.ts`)
```typescript
export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  user: User;
}

export interface User {
  id: number;
  email: string;
  username: string;
  emailVerified: boolean;
}

export interface LoginRequest { email: string; password: string; rememberMe: boolean; }
export interface RegisterRequest { email: string; password: string; }
export interface VerifyEmailRequest { code: string; }
```

> Estos nombres y campos coinciden con los DTOs Java de PASO_S01_01 (sección 6 de [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md)). NO inventar variantes (`LoginDto`, `AuthResult`, etc.).

### Servicios y archivos a crear (FQN)
| Archivo | Tipo | Métodos públicos |
|---|---|---|
| `front/src/app/auth/services/auth.service.ts` | `@Injectable({ providedIn: 'root' })` | `login(req)`, `register(req)`, `verifyEmail(code)`, `resendCode()`, `logout()`, `isAuthenticated()`, `currentUser$: Observable<User \| null>` |
| `front/src/app/auth/interceptors/mock-auth.interceptor.ts` | `HttpInterceptor` (functional) | intercepta solo si `environment.useMocks === true` |
| `front/src/app/auth/pages/login/login.component.ts` | Standalone Component | `loginForm: FormGroup`, `onSubmit()` |
| `front/src/app/auth/pages/register/register.component.ts` | Standalone Component | `registerForm: FormGroup`, `passwordStrength`, `onSubmit()` |
| `front/src/app/auth/pages/verify-email/verify-email.component.ts` | Standalone Component | `verifyForm: FormGroup`, `resendCountdown`, `onSubmit()`, `resendCode()` |

### Rutas Angular
- `/auth/login` → LoginComponent
- `/auth/register` → RegisterComponent
- `/auth/verify-email` → VerifyEmailComponent
- Lazy-loaded vía `loadComponent`. Sin NgModule.

---

## Instrucciones para el agente

> **Doctrina:** estas son instrucciones para construir el PASO. Resolvé la implementación a tu criterio respetando los contratos de arriba. NO copiar implementaciones de otras fuentes; el código debe nacer de estas instrucciones.

### 1. Modelos
Crear `auth.models.ts` con las interfaces declaradas en la sección "Contratos a respetar". Sin lógica.

### 2. AuthService
- `@Injectable({ providedIn: 'root' })`. Inyectar `HttpClient` y `Router`.
- Persistir `accessToken` y `refreshToken` en `localStorage` (claves: `codemon_access_token`, `codemon_refresh_token`).
- `currentUser$` es un `BehaviorSubject<User | null>` expuesto como Observable.
- Al inicializar, intentar reconstruir `currentUser` desde el token (decodificar payload JWT base64) si no expiró.
- `isAuthenticated()` valida la expiración del JWT (campo `exp` × 1000 vs `Date.now()`).
- `logout()` limpia localStorage, emite `null` en `currentUser$`, navega a `/auth/login`.

### 3. MockAuthInterceptor
- **Functional interceptor** (Angular 21+ API), no clase con `@Injectable()`.
- Si `environment.useMocks === false`, hacer passthrough.
- Mocks por endpoint: ver [MOCKS_FRONTEND.md](../../05-referencia-tecnica/MOCKS_FRONTEND.md) para los JSON canónicos. Casos a cubrir:
  - `/api/auth/login`: éxito 200, fallo 401 (credenciales inválidas)
  - `/api/auth/register`: éxito 201; 409 si el email es `duplicate@test.com`
  - `/api/auth/verify-email`: éxito 200 si code `=== '123456'`; 400 en otros casos
  - `/api/auth/resend-verification`: éxito 200 con cooldown
- Aplicar delay configurable (`environment.mockDelayMs`, default 500ms).
- Registrar el interceptor en `app.config.ts` con `provideHttpClient(withInterceptors([mockAuthInterceptor]))`.

### 4. LoginComponent
- Formulario reactivo (`FormBuilder`) con: `email` (required + email), `password` (required + minLength 8), `rememberMe` (boolean).
- Estado: `isLoading`, `errorMessage`, `showSuccessOverlay`.
- En submit válido: llamar `authService.login()`, mostrar overlay de éxito 1.5s y navegar a `/launcher`.
- En error: mostrar `errorMessage` con texto del backend o "Credenciales inválidas" como fallback.
- Botones sociales (Google/GitHub) deshabilitados con tooltip "Disponible próximamente" — implementación real en PASO_S10_02.

### 5. RegisterComponent
- Formulario con: `email` (required + email), `password` (required + minLength 8), `confirmPassword` (required), `acceptTerms` (requiredTrue).
- **Validador custom `passwordMatch`** a nivel del FormGroup que falla si `password !== confirmPassword`.
- **Indicador de fortaleza** (`passwordStrength: 0..4`):
  - +1 si longitud ≥ 8
  - +1 si tiene minúscula y mayúscula
  - +1 si tiene dígito
  - +1 si tiene símbolo
- En submit exitoso: navegar a `/auth/verify-email` pasando el email por router state.

### 6. VerifyEmailComponent
- Formulario con un solo control `code: required + pattern /^\d{6}$/`.
- Countdown de 60s para el botón "Reenviar código":
  - Inicia al `ngOnInit` y al hacer reenvío exitoso.
  - **Limpiar el `setInterval` en `ngOnDestroy`** (regla obligatoria del proyecto, ver CONVENCIONES.md).
- En submit exitoso: navegar a `/launcher`.
- En error: mostrar mensaje "Código inválido o expirado".

### 7. Estilos
- Seguir `Codemon_Login.html` (variables CSS, holographic border, tabs, success overlay).
- Mobile-first responsive (breakpoint en 768px).

---

## Casos borde / errores comunes

| Síntoma | Causa | Solución |
|---|---|---|
| Login funciona en local pero falla con backend real | `environment.useMocks` quedó en `true` | cambiar a `false` antes de probar contra API real |
| `passwordMismatch` no se actualiza al tipear | el validador está en cada control, no en el FormGroup | mover a `{ validators: [passwordMatch] }` del FormGroup |
| Memory leak del countdown | `setInterval` no se limpia en `ngOnDestroy` | guardar la referencia y llamar `clearInterval` |
| Token expirado y el usuario sigue en la app | `isAuthenticated()` no se llamó en el guard | implementar `AuthGuard` en PASO_S01_03 |
| `atob()` falla con tokens no-base64 | malformado o vacío | wrap en `try/catch`, devolver `false` |
| Mock interceptor en producción | falta el guard `if (!environment.useMocks)` | retornar `next(req)` siempre que `useMocks === false` |

---

## Tests obligatorios

> Cobertura mínima: ≥ 80% en `auth/`. Escribir tests Jasmine/Karma con `TestBed` y mocks de `HttpClient`.

- `LoginComponent.deshabilita_submit_si_form_invalido` — el botón no debe permitir submit con form inválido.
- `LoginComponent.muestra_error_en_credenciales_invalidas` — al recibir 401, `errorMessage` se setea.
- `LoginComponent.navega_a_launcher_en_exito` — verifica que `Router.navigate` fue llamado con `['/launcher']`.
- `RegisterComponent.passwordMismatch_si_passwords_distintos` — el FormGroup tiene el error.
- `RegisterComponent.passwordStrength_calcula_4_para_password_complejo` — `Aa1!testpwd` debe dar 4.
- `VerifyEmailComponent.countdown_decrementa_cada_segundo` — usar `fakeAsync` + `tick`.
- `VerifyEmailComponent.limpia_interval_en_destroy` — verificar que `ngOnDestroy` no deja timers activos.
- `AuthService.login_persiste_token_en_localStorage` — tras éxito, `localStorage.getItem('codemon_access_token')` no es null.
- `AuthService.isAuthenticated_falso_con_token_expirado` — token con `exp` en el pasado debe retornar false.
- `AuthService.logout_limpia_localStorage_y_navega` — verifica clear + navigate.
- `MockAuthInterceptor.passthrough_si_useMocks_false` — en ese modo, no debe interceptar.
- `MockAuthInterceptor.responde_409_para_duplicate_test_com` — verifica el caso de email duplicado.

---

## Verificación automatizada

```bash
cd ~/codemon/front

# Compilación TypeScript estricta — debe pasar sin errores
npx tsc --noEmit                                                   # PASS si: sin errores

# Build Angular (modo desarrollo) — debe pasar
ng build --configuration development                                # PASS si: BUILD SUCCESS

# Tests unitarios — todos verdes
ng test --watch=false --browsers=ChromeHeadless                     # PASS si: todos pasan

# Outputs declarados existen
test -f src/app/auth/services/auth.service.ts                       # PASS si: existe
test -f src/app/auth/interceptors/mock-auth.interceptor.ts          # PASS si: existe
test -f src/app/auth/pages/login/login.component.ts                 # PASS si: existe
test -f src/app/auth/pages/register/register.component.ts           # PASS si: existe
test -f src/app/auth/pages/verify-email/verify-email.component.ts   # PASS si: existe
test -f src/app/auth/models/auth.models.ts                          # PASS si: existe

# Verificación funcional con mocks (corriendo `ng serve` en otra terminal):
# 1. Navegar a http://localhost:8088/auth/login y submitear cualquier email + password ≥ 8 chars → debe ir a /launcher
# 2. Navegar a /auth/register con email "duplicate@test.com" → debe mostrar error 409
# 3. Navegar a /auth/verify-email, ingresar "123456" → debe ir a /launcher
```

---

## Entrega al siguiente paso

Tras completar este PASO, el siguiente (PASO_S01_03 — App Shell) puede asumir:

- **Servicios disponibles**: `AuthService` autoinyectable con `currentUser$`, `isAuthenticated()`, `logout()`.
- **Rutas funcionales**: `/auth/login`, `/auth/register`, `/auth/verify-email`.
- **Persistencia de sesión**: tokens en `localStorage` con claves `codemon_access_token` y `codemon_refresh_token`.
- **Modo mock activo**: `environment.useMocks === true` por defecto; flujos auth funcionan sin backend real.
- **Modelos exportados**: `User`, `AuthResponse` desde `auth/models/auth.models.ts` — el resto de la app debe reutilizarlos, no redefinirlos.
- **Compatible con backend real**: cuando PASO_S01_01 esté terminado, basta con `useMocks: false` para conectar al backend sin cambios de código.

---

## Definition of Done

- [ ] Todos los archivos de `outputs:` existen
- [ ] `./verify_paso.sh PASO_S01_02` retorna exit 0
- [ ] Tests obligatorios pasan con cobertura ≥ 80% en `src/app/auth/`
- [ ] Sin TODOs ni FIXMEs en el código entregado
- [ ] Naming respeta [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md): clases `*Component`, `*Service`, `User`, `AuthResponse`, paquetes en kebab-case
- [ ] `environment.useMocks` flag funciona: a `true` usa el mock, a `false` golpea el backend
- [ ] La sección "Entrega al siguiente paso" refleja el estado real
