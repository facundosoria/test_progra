---
id: PASO_S01_03
equipo: B
bloque: 1
dep: [PASO_S01_02]
siguiente: PASO_S02_01
context_files:
  - CONVENCIONES.md
  - Codemon_Launcher.html (diseño de referencia)
outputs:
  - front/src/app/core/components/sidebar/sidebar.component.ts
  - front/src/app/core/components/topbar/topbar.component.ts
  - front/src/app/core/guards/auth.guard.ts
  - front/src/app/core/layouts/main-layout/main-layout.component.ts
  - front/src/app/app.routes.ts
---

# PASO 1B.2 — App Shell + Navegación + Guards
**Grupo legacy:** 1B — Frontend Core | **Equipo:** B | **Dificultad:** 🟡 | **Tiempo:** 2–3 h

## Navegación
← **Anterior:** [PASO_S01_02](PASO_S01_02.md) — Auth UI  
→ **Siguiente:** [PASO_S02_04](PASO_S02_04.md) — Deck Builder UI

---

## Qué construye este paso

La **estructura principal de navegación** de la aplicación después del login:

1. **MainLayoutComponent:**
   - Layout con sidebar + topbar + content area
   - Outlet para rutas anidadas
   - Background animado (partículas flotantes)

2. **SidebarComponent:**
   - Navegación vertical con iconos
   - Botones: Play, Cards, Decks, Collection, Shop, Leaderboard, Settings
   - Active state visual (barra dorada a la izquierda)
   - Logo de Codemon en la parte superior
   - Logout button en la parte inferior

3. **TopbarComponent:**
   - Título de la sección actual
   - User chip (avatar + username + rank)
   - Coin counter (icono + cantidad)
   - Dropdown menu: Profile, Settings, Logout

4. **AuthGuard:**
   - Protege rutas privadas
   - Redirecciona a `/auth/login` si no autenticado
   - Verifica token válido usando `AuthService.isAuthenticated()`

5. **Routing principal:**
   ```
   /auth/login           → LoginComponent
   /auth/register        → RegisterComponent
   /auth/verify-email    → VerifyEmailComponent
   /launcher             → MainLayout (protegido por AuthGuard)
     /launcher/play      → PlayComponent (placeholder)
     /launcher/cards     → CardsComponent (PASO_S02_05)
     /launcher/decks     → DecksComponent (PASO_S02_04)
     /launcher/shop      → ShopComponent (PASO_S08_06)
   ```

---

## Prompt listo para el agente

```markdown
Contexto:
Sos el Equipo B del proyecto Codemon TCG. Acabás de completar las pantallas de autenticación (PASO_S01_02). Ahora necesitás crear el **app shell** — la estructura de navegación principal que los usuarios verán después de loguearse.

El diseño de referencia está en Codemon_Launcher.html.

Estructura del módulo:
front/src/app/core/
├── components/
│   ├── sidebar/
│   │   ├── sidebar.component.ts
│   │   ├── sidebar.component.html
│   │   └── sidebar.component.scss
│   └── topbar/
│       ├── topbar.component.ts
│       ├── topbar.component.html
│       └── topbar.component.scss
├── guards/
│   └── auth.guard.ts
└── layouts/
    └── main-layout/
        ├── main-layout.component.ts
        ├── main-layout.component.html
        └── main-layout.component.scss

Requisitos técnicos:

1. **MainLayoutComponent (wrapper principal):**
   ```typescript
   @Component({
     selector: 'app-main-layout',
     standalone: true,
     imports: [CommonModule, RouterOutlet, SidebarComponent, TopbarComponent],
     template: `
       <div class="layout">
         <app-sidebar />
         <div class="main">
           <app-topbar />
           <div class="content">
             <router-outlet />
           </div>
         </div>
       </div>
       <canvas id="bgCanvas"></canvas>
     `
   })
   export class MainLayoutComponent implements OnInit, OnDestroy {
     ngOnInit() {
       this.initBackgroundAnimation();
     }

     ngOnDestroy() {
       this.destroyBackgroundAnimation();
     }

     private initBackgroundAnimation() {
       // Similar a Codemon_Launcher.html
       // Partículas flotantes, estrellas, orbs
     }
   }
   ```

2. **SidebarComponent:**
   ```typescript
   interface NavItem {
     id: string;
     label: string;
     icon: string;
     route: string;
   }

   export class SidebarComponent {
     navItems: NavItem[] = [
       { id: 'play', label: 'Play', icon: 'gamepad', route: '/launcher/play' },
       { id: 'cards', label: 'Cards', icon: 'layers', route: '/launcher/cards' },
       { id: 'decks', label: 'Decks', icon: 'folder', route: '/launcher/decks' },
       { id: 'collection', label: 'Collection', icon: 'grid', route: '/launcher/collection' },
       { id: 'shop', label: 'Shop', icon: 'shopping-bag', route: '/launcher/shop' },
       { id: 'leaderboard', label: 'Leaderboard', icon: 'trophy', route: '/launcher/leaderboard' },
     ];

     bottomItems: NavItem[] = [
       { id: 'settings', label: 'Settings', icon: 'settings', route: '/launcher/settings' },
     ];

     activeRoute = '';

     constructor(private router: Router) {
       this.router.events.pipe(
         filter(event => event instanceof NavigationEnd)
       ).subscribe(() => {
         this.activeRoute = this.router.url;
       });
     }

     onLogout() {
       if (confirm('¿Seguro que querés cerrar sesión?')) {
         this.authService.logout();
       }
     }
   }
   ```

   HTML template:
   ```html
   <aside class="sidebar">
     <!-- Logo -->
     <div class="sidebar-logo">
       <svg><!-- Codemon logo SVG --></svg>
     </div>

     <div class="sidebar-divider"></div>

     <!-- Nav buttons -->
     <button
       *ngFor="let item of navItems"
       class="nav-btn"
       [class.active]="activeRoute.startsWith(item.route)"
       [routerLink]="item.route"
     >
       <i class="icon-{{ item.icon }}"></i>
       <span class="nav-label">{{ item.label }}</span>
     </button>

     <!-- Bottom section -->
     <div class="sidebar-bottom">
       <div class="sidebar-divider"></div>
       
       <button
         *ngFor="let item of bottomItems"
         class="nav-btn"
         [class.active]="activeRoute.startsWith(item.route)"
         [routerLink]="item.route"
       >
         <i class="icon-{{ item.icon }}"></i>
         <span class="nav-label">{{ item.label }}</span>
       </button>

       <button class="nav-btn" (click)="onLogout()">
         <i class="icon-logout"></i>
         <span class="nav-label">Logout</span>
       </button>
     </div>
   </aside>
   ```

   SCSS:
   ```scss
   .sidebar {
     width: 72px;
     background: rgba(10, 10, 15, 0.85);
     border-right: 1px solid var(--border);
     display: flex;
     flex-direction: column;
     align-items: center;
     padding: 16px 0;
     gap: 4px;
     backdrop-filter: blur(20px);
     z-index: 10;
   }

   .nav-btn {
     width: 48px;
     height: 48px;
     border-radius: 12px;
     border: none;
     background: transparent;
     color: var(--text-dim);
     cursor: pointer;
     display: flex;
     flex-direction: column;
     align-items: center;
     justify-content: center;
     gap: 3px;
     transition: all 0.2s ease;
     position: relative;

     &:hover {
       color: var(--text-secondary);
       background: rgba(255, 255, 255, 0.04);
     }

     &.active {
       color: var(--gold);
       background: rgba(201, 162, 39, 0.1);

       &::before {
         content: '';
         position: absolute;
         left: -1px;
         top: 50%;
         transform: translateY(-50%);
         width: 3px;
         height: 24px;
         background: var(--gold);
         border-radius: 0 3px 3px 0;
       }
     }
   }

   .nav-label {
     font-family: 'Cinzel', serif;
     font-size: 7px;
     letter-spacing: 0.05em;
     text-transform: uppercase;
     line-height: 1;
   }

   .sidebar-bottom {
     margin-top: auto;
     display: flex;
     flex-direction: column;
     align-items: center;
     gap: 4px;
   }
   ```

3. **TopbarComponent:**
   ```typescript
   export class TopbarComponent implements OnInit {
     currentUser$ = this.authService.currentUser$;
     coins = 1250; // Mock — en PASO_S08_04 vendrá del backend
     showUserMenu = false;
     currentSection = '';

     constructor(
       private authService: AuthService,
       private router: Router
     ) {
       this.router.events.pipe(
         filter(event => event instanceof NavigationEnd)
       ).subscribe(() => {
         this.updateCurrentSection();
       });
     }

     ngOnInit() {
       this.updateCurrentSection();
     }

     private updateCurrentSection() {
       const url = this.router.url;
       if (url.includes('/play')) this.currentSection = 'Play';
       else if (url.includes('/cards')) this.currentSection = 'Cards';
       else if (url.includes('/decks')) this.currentSection = 'Decks';
       else if (url.includes('/collection')) this.currentSection = 'Collection';
       else if (url.includes('/shop')) this.currentSection = 'Shop';
       else if (url.includes('/leaderboard')) this.currentSection = 'Leaderboard';
       else if (url.includes('/settings')) this.currentSection = 'Settings';
       else this.currentSection = 'Launcher';
     }

     toggleUserMenu() {
       this.showUserMenu = !this.showUserMenu;
     }

     onProfile() {
       this.router.navigate(['/launcher/profile']);
       this.showUserMenu = false;
     }

     onSettings() {
       this.router.navigate(['/launcher/settings']);
       this.showUserMenu = false;
     }

     onLogout() {
       this.showUserMenu = false;
       if (confirm('¿Seguro que querés cerrar sesión?')) {
         this.authService.logout();
       }
     }
   }
   ```

   HTML template:
   ```html
   <header class="topbar">
     <h1 class="topbar-title">{{ currentSection }}</h1>

     <div class="topbar-sep"></div>

     <!-- Coin counter -->
     <div class="coin-counter">
       <span class="coin-icon">
         <svg><!-- Coin icon --></svg>
       </span>
       <span class="coin-amount">{{ coins | number }}</span>
     </div>

     <!-- User chip -->
     <div class="trainer-menu-wrap">
       <div class="trainer-chip" (click)="toggleUserMenu()">
         <div class="trainer-avatar">
           {{ (currentUser$ | async)?.username?.charAt(0)?.toUpperCase() || '?' }}
         </div>
         <div class="trainer-info">
           <div class="trainer-name">{{ (currentUser$ | async)?.username || 'Guest' }}</div>
           <div class="trainer-rank">Rank: Bronze</div>
         </div>
       </div>

       <!-- Dropdown menu -->
       <div class="trainer-dropdown" *ngIf="showUserMenu">
         <button class="menu-item" (click)="onProfile()">
           <i class="icon-user"></i>
           Profile
         </button>
         <button class="menu-item" (click)="onSettings()">
           <i class="icon-settings"></i>
           Settings
         </button>
         <div class="dropdown-sep"></div>
         <button class="menu-item danger" (click)="onLogout()">
           <i class="icon-logout"></i>
           Logout
         </button>
       </div>
     </div>
   </header>
   ```

4. **AuthGuard:**
   ```typescript
   import { inject } from '@angular/core';
   import { Router } from '@angular/router';
   import { AuthService } from '@auth/services/auth.service';

   export const authGuard = () => {
     const authService = inject(AuthService);
     const router = inject(Router);

     if (authService.isAuthenticated()) {
       return true;
     }

     // Guardar URL original para redireccionar después del login
     const returnUrl = router.routerState.snapshot.url;
     router.navigate(['/auth/login'], {
       queryParams: { returnUrl }
     });
     return false;
   };
   ```

5. **Routing principal (app.routes.ts):**
   ```typescript
   import { Routes } from '@angular/router';
   import { authGuard } from '@core/guards/auth.guard';

   export const routes: Routes = [
     {
       path: '',
       redirectTo: '/launcher/play',
       pathMatch: 'full'
     },
     {
       path: 'auth',
       loadChildren: () => import('./auth/auth.routes').then(m => m.AUTH_ROUTES)
     },
     {
       path: 'launcher',
       component: MainLayoutComponent,
       canActivate: [authGuard],
       children: [
         {
           path: '',
           redirectTo: 'play',
           pathMatch: 'full'
         },
         {
           path: 'play',
           loadComponent: () => import('./pages/play/play.component').then(m => m.PlayComponent)
         },
         {
           path: 'cards',
           loadComponent: () => import('./pages/cards/cards.component').then(m => m.CardsComponent)
         },
         {
           path: 'decks',
           loadComponent: () => import('./pages/decks/decks.component').then(m => m.DecksComponent)
         },
         {
           path: 'collection',
           loadComponent: () => import('./pages/collection/collection.component').then(m => m.CollectionComponent)
         },
         {
           path: 'shop',
           loadComponent: () => import('./pages/shop/shop.component').then(m => m.ShopComponent)
         },
         {
           path: 'leaderboard',
           loadComponent: () => import('./pages/leaderboard/leaderboard.component').then(m => m.LeaderboardComponent)
         },
         {
           path: 'settings',
           loadComponent: () => import('./pages/settings/settings.component').then(m => m.SettingsComponent)
         },
         {
           path: 'profile',
           loadComponent: () => import('./pages/profile/profile.component').then(m => m.ProfileComponent)
         }
       ]
     },
     {
       path: '**',
       redirectTo: '/launcher/play'
     }
   ];
   ```

6. **Placeholder components:**
   Crear componentes placeholder simples para cada ruta que todavía no tiene implementación:

   ```typescript
   // pages/play/play.component.ts
   @Component({
     selector: 'app-play',
     standalone: true,
     template: `
       <div class="placeholder-page">
         <h2>Play</h2>
         <p>Esta sección se implementará en PASO_S06_01 (Lobby UI)</p>
       </div>
     `
   })
   export class PlayComponent {}

   // pages/collection/collection.component.ts
   @Component({
     selector: 'app-collection',
     standalone: true,
     template: `
       <div class="placeholder-page">
         <h2>Collection</h2>
         <p>Esta sección se implementará en futuros pasos</p>
       </div>
     `
   })
   export class CollectionComponent {}

   // ...otros placeholders similares
   ```

7. **Icons:**
   Usar Lucide Icons (ya disponible en Angular 21):
   ```typescript
   import { LucideAngularModule, Gamepad2, Layers, Folder, Grid3x3, ShoppingBag, Trophy, Settings, LogOut, User } from 'lucide-angular';
   ```

8. **Background animation:**
   Copiar el código de animación de `Codemon_Launcher.html`:
   - Canvas con partículas flotantes
   - Estrellas parpadeantes
   - Orbs con radial gradient
   - Cards holográficas flotando

Entregables:
- [ ] MainLayoutComponent con sidebar + topbar + router-outlet
- [ ] SidebarComponent con navegación funcional
- [ ] TopbarComponent con user menu dropdown
- [ ] AuthGuard protegiendo rutas
- [ ] Routing principal con lazy loading
- [ ] Placeholder components para todas las rutas
- [ ] Background animation suave (60 FPS)
```

---

## Contexto adicional

### Click outside para cerrar dropdown

Usar `@HostListener` o RxJS para cerrar el user menu cuando se hace click afuera:

```typescript
@HostListener('document:click', ['$event'])
onDocumentClick(event: MouseEvent) {
  const target = event.target as HTMLElement;
  if (!target.closest('.trainer-menu-wrap')) {
    this.showUserMenu = false;
  }
}
```

### Return URL después de login

El `AuthGuard` guarda la URL original en query params:
```typescript
// En LoginComponent, después de login exitoso:
ngOnInit() {
  this.returnUrl = this.route.snapshot.queryParams['returnUrl'] || '/launcher/play';
}

onSubmit() {
  this.authService.login(...).subscribe({
    next: () => {
      this.router.navigateByUrl(this.returnUrl);
    }
  });
}
```

### Preparación para notificaciones (PASO_S10_02)

El topbar debe tener espacio reservado para un botón de notificaciones:
```html
<!-- Después del coin counter -->
<button class="notification-btn" disabled>
  <i class="icon-bell"></i>
  <span class="notification-badge">3</span> <!-- Para futuro -->
</button>
```

---

## Tests sugeridos

### Unit Tests

```typescript
describe('AuthGuard', () => {
  it('should allow access if authenticated', () => {
    spyOn(authService, 'isAuthenticated').and.returnValue(true);
    const result = authGuard();
    expect(result).toBe(true);
  });

  it('should redirect to login if not authenticated', () => {
    spyOn(authService, 'isAuthenticated').and.returnValue(false);
    spyOn(router, 'navigate');
    authGuard();
    expect(router.navigate).toHaveBeenCalledWith(['/auth/login'], jasmine.any(Object));
  });
});

describe('SidebarComponent', () => {
  it('should highlight active route', () => {
    router.navigate(['/launcher/cards']);
    fixture.detectChanges();
    expect(component.activeRoute).toBe('/launcher/cards');
  });

  it('should confirm before logout', () => {
    spyOn(window, 'confirm').and.returnValue(false);
    spyOn(authService, 'logout');
    component.onLogout();
    expect(authService.logout).not.toHaveBeenCalled();
  });
});

describe('TopbarComponent', () => {
  it('should toggle user menu on click', () => {
    expect(component.showUserMenu).toBe(false);
    component.toggleUserMenu();
    expect(component.showUserMenu).toBe(true);
  });

  it('should update current section on route change', () => {
    router.navigate(['/launcher/decks']);
    expect(component.currentSection).toBe('Decks');
  });
});
```

### E2E Tests

```typescript
test('should navigate through sidebar', async ({ page }) => {
  await page.goto('/launcher/play');
  
  await page.click('button:has-text("Cards")');
  await expect(page).toHaveURL('/launcher/cards');
  
  await page.click('button:has-text("Decks")');
  await expect(page).toHaveURL('/launcher/decks');
});

test('should logout from user menu', async ({ page }) => {
  await page.goto('/launcher/play');
  
  await page.click('.trainer-chip');
  await expect(page.locator('.trainer-dropdown')).toBeVisible();
  
  page.on('dialog', dialog => dialog.accept());
  await page.click('.menu-item.danger');
  
  await expect(page).toHaveURL('/auth/login');
});

test('should protect routes with auth guard', async ({ page }) => {
  // Clear tokens
  await page.evaluate(() => {
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
  });
  
  await page.goto('/launcher/decks');
  
  // Should redirect to login
  await expect(page).toHaveURL(/\/auth\/login/);
});
```

---

## Errores comunes

### 1. **Sidebar no muestra active state**
**Síntoma:** Todos los botones tienen el mismo color  
**Causa:** `router.url` no se actualiza en tiempo real  
**Solución:**
```typescript
constructor(private router: Router) {
  this.router.events.pipe(
    filter(event => event instanceof NavigationEnd)
  ).subscribe((event: NavigationEnd) => {
    this.activeRoute = event.urlAfterRedirects;
  });
}
```

### 2. **User menu no se cierra al hacer click afuera**
**Síntoma:** Dropdown permanece abierto  
**Causa:** No hay listener en document  
**Solución:**
```typescript
@HostListener('document:click', ['$event'])
onDocumentClick(event: MouseEvent) {
  const target = event.target as HTMLElement;
  const isInsideMenu = target.closest('.trainer-menu-wrap');
  if (!isInsideMenu) {
    this.showUserMenu = false;
  }
}
```

### 3. **Background animation causa lag**
**Síntoma:** FPS bajo, animación entrecortada  
**Causa:** Demasiadas partículas o sin requestAnimationFrame  
**Solución:**
```typescript
private animationFrameId?: number;

private startAnimation() {
  const animate = () => {
    this.drawFrame();
    this.animationFrameId = requestAnimationFrame(animate);
  };
  animate();
}

ngOnDestroy() {
  if (this.animationFrameId) {
    cancelAnimationFrame(this.animationFrameId);
  }
}
```

### 4. **Guard redirecciona a login pero pierde returnUrl**
**Síntoma:** Después de login, va a `/launcher/play` en vez de la URL original  
**Causa:** `queryParams` no se preservan  
**Solución:**
```typescript
// AuthGuard
const returnUrl = router.routerState.snapshot.url;
router.navigate(['/auth/login'], {
  queryParams: { returnUrl },
  queryParamsHandling: 'merge' // ← importante
});
```

### 5. **Icons no se muestran**
**Síntoma:** Cuadrados vacíos en vez de iconos  
**Causa:** Lucide no importado correctamente  
**Solución:**
```typescript
// sidebar.component.ts
import { LucideAngularModule, Gamepad2, Layers, ... } from 'lucide-angular';

@Component({
  imports: [
    CommonModule,
    RouterModule,
    LucideAngularModule.pick({ Gamepad2, Layers, ... })
  ]
})
```

### 6. **Lazy loading falla con "Cannot find module"**
**Síntoma:** Error en consola al navegar  
**Causa:** Path incorrecto en `loadComponent`  
**Solución:**
```typescript
// Usar paths relativos correctos
loadComponent: () => import('./pages/play/play.component').then(m => m.PlayComponent)

// O usar path aliases (tsconfig.json)
loadComponent: () => import('@pages/play/play.component').then(m => m.PlayComponent)
```

---

## Verificación manual

### Checklist de QA

#### Navegación
- [ ] Sidebar: todos los botones navegan correctamente
- [ ] Active state se actualiza al cambiar de ruta
- [ ] Logout button muestra confirmación
- [ ] Logo de Codemon visible en parte superior del sidebar

#### Topbar
- [ ] Título cambia según la ruta actual
- [ ] User chip muestra username y avatar
- [ ] Coin counter muestra cantidad formateada (1,250)
- [ ] Dropdown menu se abre/cierra al hacer click
- [ ] Dropdown se cierra al hacer click afuera
- [ ] Profile, Settings, Logout funcionan correctamente

#### AuthGuard
- [ ] Rutas protegidas redirigen a login si no autenticado
- [ ] returnUrl se preserva en query params
- [ ] Después de login, redirecciona a returnUrl original
- [ ] Usuario autenticado puede acceder sin problemas

#### Responsive
- [ ] Sidebar mantiene ancho fijo 72px en mobile
- [ ] Topbar se ajusta en mobile (título más corto)
- [ ] Content area usa todo el espacio disponible

#### Performance
- [ ] Background animation corre a 60 FPS
- [ ] Sin memory leaks (verificar con Chrome DevTools)
- [ ] Lazy loading funciona (módulos se cargan solo cuando se navega)

---

## Criterios de aceptación

### ✅ Obligatorios

1. **Funcionalidad:**
   - Sidebar y topbar renderizados correctamente
   - Navegación funcional entre todas las rutas
   - AuthGuard protege rutas privadas
   - Logout funciona y limpia tokens
   - User menu dropdown se abre/cierra

2. **UX/UI:**
   - Diseño sigue Codemon_Launcher.html
   - Active states visuales claros
   - Animaciones suaves (no jank)
   - Background no distrae del contenido

3. **Código:**
   - Componentes standalone
   - Lazy loading configurado
   - Guards funcionales
   - TypeScript estricto

4. **Testing:**
   - Unit tests para guard y componentes
   - E2E tests para navegación

### 🎯 Opcionales

- Keyboard navigation (Tab, Enter en sidebar)
- Tooltips en botones del sidebar
- Transition animations entre rutas
- Collapse sidebar en mobile

---

## Notas finales

### Handoff para PASO_S02_04 (Deck Builder)

El Deck Builder necesitará:
- Ruta `/launcher/decks` ya configurada
- TopbarComponent actualizando título a "Decks"
- Sidebar marcando "Decks" como activo

### Handoff para PASO_S06_01 (Lobby)

El Lobby necesitará:
- Ruta `/launcher/play` ya configurada
- Poder acceder desde sidebar
- User info disponible en topbar
