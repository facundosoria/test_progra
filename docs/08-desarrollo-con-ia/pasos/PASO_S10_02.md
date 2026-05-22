---
id: PASO_S10_02
equipo: B
bloque: 10
dep: [PASO_S09_05, PASO_S09_01]
siguiente: PASO_S10_SMOKE
context_files:
  - CONTRATOS_API.md
  - CODEMON_GUIAS_TECNICAS.md (OAuth2 examples)
outputs:
  - front/src/app/auth/pages/oauth-callback/oauth-callback.component.ts
  - front/src/app/auth/services/oauth.service.ts
---

# PASO 5B.1 — OAuth2 Integration (Google + GitHub)
**Grupo legacy:** 5B — Frontend Final | **Equipo:** B | **Dificultad:** 🟡 | **Tiempo:** 2 h

## Navegación
← **Anterior:** [PASO_S09_05](PASO_S09_05.md) — Profile + Friends UI  
→ **Siguiente:** [PASO_S11_06](PASO_S11_06.md) — E2E Tests

---

## Qué construye este paso

Integración completa de OAuth2 con Google y GitHub:

1. **Botones sociales en LoginComponent:**
   - "Continue with Google"
   - "Continue with GitHub"
   - Click → redirección a proveedor OAuth2

2. **OAuthCallbackComponent:**
   - Ruta `/auth/callback` que recibe code de OAuth2
   - Intercambia code por tokens con backend
   - Redirección a `/launcher` si exitoso

3. **OAuthService:**
   - `loginWithGoogle(): void` → redirecciona
   - `loginWithGitHub(): void` → redirecciona
   - `handleCallback(code): Observable<AuthResponse>`

---

## Prompt listo para el agente

```markdown
Requisitos:

1. **Actualizar LoginComponent:**
   ```typescript
   export class LoginComponent {
     // ... código existente ...

     onSocialLogin(provider: 'google' | 'github') {
       this.oauthService.loginWith(provider);
     }
   }
   ```

   Template:
   ```html
   <!-- Después del divider "or continue with" -->
   <div class="social-row">
     <button class="social-btn" (click)="onSocialLogin('google')">
       <i class="icon-google"></i>
       Google
     </button>
     <button class="social-btn" (click)="onSocialLogin('github')">
       <i class="icon-github"></i>
       GitHub
     </button>
   </div>
   ```

2. **OAuthService:**
   ```typescript
   @Injectable({ providedIn: 'root' })
   export class OAuthService {
     private readonly API_URL = `${environment.apiUrl}/auth`;

     loginWith(provider: 'google' | 'github') {
       const redirectUri = `${window.location.origin}/auth/callback`;
       const state = this.generateState();
       
       localStorage.setItem('oauth_state', state);
       
       window.location.href = `${this.API_URL}/oauth2/${provider}?redirect_uri=${redirectUri}&state=${state}`;
     }

     handleCallback(code: string, state: string): Observable<AuthResponse> {
       const savedState = localStorage.getItem('oauth_state');
       
       if (state !== savedState) {
         return throwError(() => new Error('Invalid OAuth state'));
       }

       return this.http.post<AuthResponse>(`${this.API_URL}/oauth2/callback`, {
         code,
         state
       }).pipe(
         tap(() => localStorage.removeItem('oauth_state'))
       );
     }

     private generateState(): string {
       return Math.random().toString(36).substring(2, 15);
     }
   }
   ```

3. **OAuthCallbackComponent:**
   ```typescript
   export class OAuthCallbackComponent implements OnInit {
     ngOnInit() {
       const params = new URLSearchParams(window.location.search);
       const code = params.get('code');
       const state = params.get('state');
       const error = params.get('error');

       if (error) {
         alert(`OAuth error: ${error}`);
         this.router.navigate(['/auth/login']);
         return;
       }

       if (!code || !state) {
         alert('Invalid OAuth response');
         this.router.navigate(['/auth/login']);
         return;
       }

       this.oauthService.handleCallback(code, state).subscribe({
         next: (response) => {
           this.authService.setSession(response);
           this.router.navigate(['/launcher']);
         },
         error: (err) => {
           alert('OAuth login failed');
           this.router.navigate(['/auth/login']);
         }
       });
     }
   }
   ```

   Template:
   ```html
   <div class="oauth-callback">
     <div class="spinner"></div>
     <p>Completing sign in...</p>
   </div>
   ```

4. **Routing:**
   ```typescript
   // auth.routes.ts
   export const AUTH_ROUTES: Routes = [
     { path: 'login', component: LoginComponent },
     { path: 'callback', component: OAuthCallbackComponent },
     // ...
   ];
   ```

Entregables:
- [ ] Botones sociales funcionales
- [ ] OAuthService con redirección
- [ ] OAuthCallbackComponent con manejo de code
- [ ] State validation
```

---

## Criterios de aceptación

✅ Click en Google/GitHub → redirecciona  
✅ Callback procesa code correctamente  
✅ State validation funcional  
✅ Tokens guardados en localStorage
