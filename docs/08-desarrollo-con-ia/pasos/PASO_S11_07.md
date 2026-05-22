---
id: PASO_S11_07
equipo: B
bloque: 11
dep: [PASO_S11_06]
context_files:
  - CONVENCIONES.md
outputs:
  - front/src/styles/_responsive.scss
  - front/src/app/core/services/viewport.service.ts
---

# PASO 5B.3 — Responsive Design + Mobile Optimization
**Grupo legacy:** 5B — Frontend Final | **Equipo:** B | **Dificultad:** 🟡 | **Tiempo:** 2–3 h

## Navegación
← **Anterior:** [PASO_S11_06](PASO_S11_06.md) — E2E Tests  
→ **Siguiente:** ✅ FIN del frontend

---

## Qué construye este paso

Optimización responsive para **mobile, tablet y desktop**:

1. **Breakpoints CSS:**
   - Mobile: 320px - 767px
   - Tablet: 768px - 1023px
   - Desktop: 1024px+

2. **ViewportService:**
   - Observable para detectar cambios de viewport
   - `isMobile$`, `isTablet$`, `isDesktop$`

3. **Ajustes por componente:**
   - **Sidebar:** Colapsa a bottom nav en mobile
   - **Deck Builder:** Stack vertical en mobile
   - **Card Grid:** 2 columnas en mobile, 4 en tablet, 6 en desktop
   - **Modals:** Fullscreen en mobile

---

## Prompt listo para el agente

```markdown
Requisitos:

1. **_responsive.scss (variables globales):**
   ```scss
   // Breakpoints
   $breakpoint-mobile: 767px;
   $breakpoint-tablet: 1023px;

   // Mixins
   @mixin mobile {
     @media (max-width: $breakpoint-mobile) {
       @content;
     }
   }

   @mixin tablet {
     @media (min-width: #{$breakpoint-mobile + 1}) and (max-width: $breakpoint-tablet) {
       @content;
     }
   }

   @mixin desktop {
     @media (min-width: #{$breakpoint-tablet + 1}) {
       @content;
     }
   }

   @mixin mobile-and-tablet {
     @media (max-width: $breakpoint-tablet) {
       @content;
     }
   }
   ```

2. **ViewportService:**
   ```typescript
   @Injectable({ providedIn: 'root' })
   export class ViewportService {
     private resizeSubject = new Subject<void>();
     
     isMobile$ = this.resizeSubject.pipe(
       startWith(null),
       map(() => window.innerWidth <= 767),
       distinctUntilChanged(),
       shareReplay(1)
     );

     isTablet$ = this.resizeSubject.pipe(
       startWith(null),
       map(() => window.innerWidth > 767 && window.innerWidth <= 1023),
       distinctUntilChanged(),
       shareReplay(1)
     );

     isDesktop$ = this.resizeSubject.pipe(
       startWith(null),
       map(() => window.innerWidth > 1023),
       distinctUntilChanged(),
       shareReplay(1)
     );

     constructor() {
       fromEvent(window, 'resize')
         .pipe(debounceTime(100))
         .subscribe(() => this.resizeSubject.next());
     }
   }
   ```

3. **Sidebar responsive (bottom nav en mobile):**
   ```scss
   .sidebar {
     // Desktop: sidebar vertical
     width: 72px;
     flex-direction: column;

     @include mobile {
       // Mobile: bottom nav horizontal
       width: 100%;
       height: 60px;
       flex-direction: row;
       position: fixed;
       bottom: 0;
       left: 0;
       z-index: 100;
       border-right: none;
       border-top: 1px solid var(--border);
     }
   }

   .nav-btn {
     @include mobile {
       flex: 1;
       height: 100%;
       border-radius: 0;
     }
   }
   ```

4. **Card Grid responsive:**
   ```scss
   .card-grid {
     display: grid;
     gap: 16px;

     // Desktop: 6 columnas
     grid-template-columns: repeat(6, 1fr);

     @include tablet {
       // Tablet: 4 columnas
       grid-template-columns: repeat(4, 1fr);
     }

     @include mobile {
       // Mobile: 2 columnas
       grid-template-columns: repeat(2, 1fr);
       gap: 12px;
     }
   }
   ```

5. **Deck Builder responsive:**
   ```scss
   .deck-builder {
     display: flex;
     gap: 20px;

     @include mobile {
       flex-direction: column;
     }
   }

   .card-pool-panel {
     flex: 2;

     @include mobile {
       flex: 1;
       max-height: 50vh;
     }
   }

   .deck-panel {
     flex: 1;

     @include mobile {
       flex: 1;
     }
   }
   ```

6. **Modals fullscreen en mobile:**
   ```scss
   .overlay-backdrop {
     @include mobile {
       padding: 0;
     }
   }

   .overlay-panel {
     max-width: 800px;
     padding: 40px;

     @include mobile {
       max-width: 100%;
       width: 100%;
       height: 100%;
       border-radius: 0;
       padding: 20px;
     }
   }
   ```

7. **Login card responsive:**
   ```scss
   .login-card {
     width: 440px;
     padding: 48px 44px 40px;

     @include mobile {
       width: 90%;
       padding: 32px 24px;
     }
   }
   ```

8. **Touch-friendly buttons:**
   ```scss
   .action-primary,
   .action-secondary {
     min-height: 44px; // iOS accessibility guideline

     @include mobile {
       font-size: 16px; // Evita auto-zoom en iOS
       padding: 14px 20px;
     }
   }
   ```

9. **Usar ViewportService en componentes:**
   ```typescript
   export class SidebarComponent implements OnInit {
     isMobile$ = this.viewportService.isMobile$;

     constructor(private viewportService: ViewportService) {}
   }
   ```

   Template:
   ```html
   <aside class="sidebar" [class.mobile]="isMobile$ | async">
     <!-- Nav buttons -->
   </aside>
   ```

Entregables:
- [ ] _responsive.scss con mixins
- [ ] ViewportService funcional
- [ ] Sidebar → bottom nav en mobile
- [ ] Card grids responsive
- [ ] Modals fullscreen en mobile
- [ ] Touch targets >= 44px
- [ ] Forms no hacen auto-zoom en iOS
```

---

## Checklist de Testing Responsive

### Mobile (iPhone 13, 390px)
- [ ] Sidebar se convierte en bottom nav
- [ ] Card grid muestra 2 columnas
- [ ] Deck Builder stack vertical
- [ ] Modals ocupan fullscreen
- [ ] Buttons >= 44px de alto
- [ ] No hay scroll horizontal
- [ ] Login card cabe en viewport

### Tablet (iPad, 768px)
- [ ] Sidebar vertical visible
- [ ] Card grid muestra 4 columnas
- [ ] Deck Builder lado a lado
- [ ] Modals centrados con padding

### Desktop (1920px)
- [ ] Card grid muestra 6 columnas
- [ ] Todo el espacio aprovechado
- [ ] Hover states funcionan

---

## Criterios de aceptación

✅ App funcional en 3 breakpoints  
✅ Sidebar responsive (bottom nav mobile)  
✅ Card grids adaptativos  
✅ Modals fullscreen en mobile  
✅ Touch targets >= 44px  
✅ No auto-zoom en iOS
