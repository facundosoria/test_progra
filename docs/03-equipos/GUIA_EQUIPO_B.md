# GUÍA COMPLETA — EQUIPO B: Frontend
**Proyecto:** Codemon TCG  
**Rol del equipo:** Construir toda la interfaz de usuario en Angular — desde el login hasta el tablero de juego en tiempo real  
**Composición recomendada:** 1–2 desarrolladores frontend (Angular/TypeScript)  
**Tiempo total estimado:** 55–65 horas de trabajo  
**Archivos de referencia:** [README.md](../02-planificacion/README.md) · [EQUIPOS.md](../02-planificacion/04_proceso/EQUIPOS.md)

> Nota de estructura: los archivos referenciados a lo largo de esta guia (`CONTRATOS_API.md`, `MOCKS_FRONTEND.md`, `PROTOCOLO_WEBSOCKET.md`, etc.) viven en `docs/` organizados por tema. Para mapear cada archivo a su carpeta exacta, ver [docs/INDICE.md](../INDICE.md). Para el workflow con IA, ver [docs/08-desarrollo-con-ia/README.md](../08-desarrollo-con-ia/README.md).

---

## 1. CONOCIMIENTOS PREVIOS OBLIGATORIOS

### Angular 21+ — Standalone Components
Este proyecto usa **Standalone Components** exclusivamente. No hay `NgModule`.
- [ ] `@Component({ standalone: true, imports: [...] })` — cada componente declara sus propias dependencias
- [ ] `RouterModule` y rutas lazy-loading con `loadComponent()`
- [ ] `inject()` en lugar de inyección por constructor donde sea más limpio
- [ ] `@Input()`, `@Output()`, `@ViewChild()` — comunicación entre componentes
- [ ] `ngOnInit()`, `ngOnDestroy()` — lifecycle hooks (ngOnDestroy es CRÍTICO para cleanup de WebSocket)
- [ ] `AsyncPipe` (`| async`) — suscribirse a Observables en el template sin memory leaks

### TypeScript Strict
El proyecto usa `strict: true` en `tsconfig.json`. Esto significa:
- [ ] **No hay `any` implícito.** Todo tiene tipo declarado.
- [ ] **No hay null no controlado.** Usar Optional chaining (`?.`) y nullish coalescing (`??`)
- [ ] **Interfaces para todos los DTOs** — basarse en `CONTRATOS_API.md`
- [ ] Enums para tipos conocidos: `ActionType`, `StatusCondition`, `GameEventType`

### RxJS (Reactivity)
- [ ] `Observable`, `Subject`, `BehaviorSubject` — diferencias y cuándo usar cada uno
- [ ] `takeUntil(this.destroy$)` — patrón para cleanup de suscripciones en `ngOnDestroy`
- [ ] `switchMap`, `mergeMap`, `catchError` — manejo de errores en cadenas de HTTP
- [ ] `of()`, `from()`, `delay()` — para el MockInterceptor
- [ ] `combineLatest` — para combinar el estado del juego con la info del usuario

### HTTP + Interceptores
- [ ] `HttpClient` con `provideHttpClient(withInterceptors([]))` (nueva API funcional)
- [ ] Interceptor para agregar `Authorization: Bearer <token>` a todos los requests
- [ ] Interceptor de mock (se configura en `MOCKS_FRONTEND.md`) — **fundamental para el modo de desarrollo**
- [ ] Manejo de errores HTTP: 401 → redirigir a login; 403 → mostrar error; 500 → notificación genérica

### STOMP/WebSocket
- [ ] `@stomp/stompjs` con `SockJS` como fallback
- [ ] Diferencia entre `/topic/` (broadcast público) y `/user/queue/` (privado)
- [ ] Reconnect automático en caso de desconexión
- [ ] Cleanup: siempre llamar `client.deactivate()` en `ngOnDestroy`

### Angular CDK — Drag & Drop
- [ ] `CdkDragDrop` — eventos `(cdkDropListDropped)`
- [ ] `cdkDropList` como zona de drop, `cdkDrag` como elemento arrastrable
- [ ] `cdkDropListConnectedTo` — conectar la mano con los slots del tablero
- [ ] Predicado `cdkDropListEnterPredicate` — validar si una carta puede soltarse en un destino

### Convención sobre clases CSS en templates

> Todas las clases CSS que aparecen en los ejemplos de los PASOS (`deck-list-container`, `action-primary`, `overlay-backdrop`, `progress-track`, `menu-item`, etc.) son **clases custom del proyecto Codemon**. Ningún framework CSS preexistente las provee — el desarrollador debe definirlas en el `*.component.scss` del componente correspondiente componiéndolas con `@apply` y utilidades Tailwind. Ejemplo:
>
> ```scss
> .action-primary {
>   @apply inline-flex items-center justify-center gap-2 px-4 py-2 rounded
>          bg-blue-600 text-white font-medium hover:bg-blue-700
>          focus:outline-none focus:ring-2 focus:ring-blue-500
>          disabled:opacity-50 disabled:cursor-not-allowed transition;
> }
> ```
>
> Alternativamente, esas utilidades pueden ir inline en el template (`class="inline-flex items-center px-4 py-2 ..."`). Lo importante: **no hay clases mágicas que estilicen solas**.

### Tailwind CSS 3 + FontAwesome
- [ ] Layout con `grid grid-cols-12 gap-4` o `flex` + `flex-col md:flex-row` para el tablero
- [ ] Utilidades base: `flex`, `gap-*`, `text-*`, `bg-*`, `p-*`, `m-*`, `rounded-*`, `shadow-*`
- [ ] Responsive: prefijos `sm:`, `md:`, `lg:`, `xl:` (breakpoints 640/768/1024/1280)
- [ ] Estados: `hover:`, `focus:`, `disabled:`, `aria-*` selectors
- [ ] Componentes propios con `@apply` dentro de `*.component.scss` cuando una combinación se repita (badges de tipo, barras de HP, toasts)
- [ ] FontAwesome para íconos de tipos de Pokémon (Fuego, Agua, etc.) — independiente de Tailwind

---

## 2. CONOCIMIENTOS A ADQUIRIR DURANTE EL PROCESO

- **Estrategia mock-first:** Desarrollar toda la UI contra mocks antes de tener el backend real. Se aprende en la práctica con `MOCKS_FRONTEND.md`.
- **STOMP en Angular:** La integración con `@stomp/stompjs` tiene particularidades en Angular (zona.js). Se aprende en PASO_S05_04.
- **Drag & drop en juegos de cartas:** Predicados de validación (no toda carta puede ir a cualquier zona). Se aprende durante PASO_S05_04.
- **Sincronización de estado del juego:** NUNCA modificar el estado local antes de confirmación del servidor. Se entiende en la práctica.

---

## 3. ARCHIVOS DE REFERENCIA OBLIGATORIOS

Leer estos archivos **antes de escribir código**:

| Archivo | Cuándo leerlo | Por qué |
|---------|--------------|---------|
| `CONTRATOS_API.md` | Durante PASO_S00_01 (reunión con equipos) | Define todos los endpoints con DTOs exactos |
| `MOCKS_FRONTEND.md` | Durante PASO_S00_01 (Equipo B lo genera al final) | Define el MockInterceptor y los JSON de prueba |
| `PROTOCOLO_WEBSOCKET.md` | Antes de PASO_S05_04 | Define todos los eventos del juego |
| `ESTRUCTURA_PROYECTO.md` | Antes de PASO_S00_06 | Estructura de carpetas Angular esperada |
| `06-system-logic.md` | Antes de PASO_S05_04 | Reglas de emisión de eventos WebSocket |
| `CONVENCIONES.md` | Antes de todo | Convenciones globales del proyecto |

---

## 4. ESTRATEGIA MOCK-FIRST (FUNDAMENTO DEL TRABAJO DEL EQUIPO B)

> El Equipo B **no espera** al Equipo A para construir la UI. Trabaja contra mocks desde el día 1 y reemplaza los mocks por endpoints reales cuando el Equipo A hace los gates.

### Cómo funciona

Los archivos de environment usan **rutas relativas** para que el mismo código funcione en local con Docker y en producción sin ningún cambio. Nginx (en `:8088` local y en `:443` prod) sirve tanto la SPA como el proxy `/api` y `/ws` — el browser resuelve la URL relativa contra el mismo origen.

```typescript
// src/environments/environment.ts — LOCAL CON DOCKER (http://localhost:8088)
// src/environments/environment.prod.ts — PRODUCCIÓN (https://<dominio>)
// ¡Los valores son IGUALES en ambos archivos! Nginx hace el trabajo en los dos casos.
export const environment = {
  production: false,       // → true en environment.prod.ts
  apiUrl: '/api',          // relativo: Nginx proxea a api:8080/api/
  wsUrl: '/ws',            // relativo: SockJS negocia ws:// o wss:// según el origen
  useMocks: true,          // → false en environment.prod.ts
  mockDelayMs: 300,        // → 0 en environment.prod.ts
};
```

```typescript
// src/environments/environment.development.ts — ng serve SIN Docker
// Solo para desarrollo con hot-reload (API en localhost:8080 directamente)
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8080/api',  // directo a Spring Boot (expuesto en modo debug)
  wsUrl: 'ws://localhost:8080/ws',      // directo a Spring Boot
  useMocks: false,
  mockDelayMs: 0,
};
```

Para que `ng serve` use `environment.development.ts`, declarar la configuración en `angular.json`:
```json
// angular.json → architect.build.configurations
"development": {
  "fileReplacements": [{
    "replace": "src/environments/environment.ts",
    "with": "src/environments/environment.development.ts"
  }]
}
```

> **Por qué rutas relativas:** `localhost:8080` es el puerto interno de Docker — no está expuesto al browser en el docker-compose. Usar `/api` evita hardcodear el host y hace que el mismo build funcione en cualquier dominio sin recompilar.

### Flujo de desarrollo

```
Semana 1-2: useMocks = true
  ↓ Equipo B construye toda la UI contra los mocks de MOCKS_FRONTEND.md
  
GATE 1a llega (Equipo A entrega JWT):
  ↓ Cambiar useMocks a false SOLO para /api/auth/*
  ↓ Probar login real, el resto sigue con mocks

GATE 1b llega (Equipo A entrega cartas y mazos):
  ↓ Cambiar useMocks a false para /api/cards/* y /api/decks/*
  ↓ Probar Deck Builder real

GATE 2 llega (Equipo A entrega WebSocket):
  ↓ Reemplazar el mock de WebSocket por la conexión real
  ↓ PASO_S05_04: integrar tablero completo

GATES 3 y 4 llegan (Equipo C entrega salas privadas y matchmaking):
  ↓ Integrar Lobby real

GATE 5 llega (Equipo C entrega tienda, pagos y sobres):
  ↓ Integrar Shop real

GATE 6 llega (Equipo C entrega social):
  ↓ Integrar leaderboard, noticias y amigos reales

GATE 7 llega (Equipo C entrega OAuth2 + perfil):
  ↓ Integrar login social y Profile UI
```

---

## 5. ESTRUCTURA DE CARPETAS DEL PROYECTO

Todo el frontend vive en `~/codemon/front/`. El Equipo B crea y gestiona esta carpeta.

```
~/codemon/front/
├── package.json
├── angular.json
├── tsconfig.json           ← strict: true
├── Dockerfile              ← Copiar de Dockerfile.front de la raíz del proyecto
├── nginx.conf              ← Copiar de nginx.conf de la raíz del proyecto
└── src/
    ├── index.html
    ├── main.ts
    ├── styles.scss          ← @tailwind base/components/utilities + estilos globales
    ├── environments/
    │   ├── environment.ts   ← useMocks: true, apiUrl, wsUrl
    │   └── environment.prod.ts
    └── app/
        ├── app.config.ts    ← provideHttpClient, provideRouter
        ├── app.routes.ts    ← rutas lazy por feature
        ├── core/
        │   ├── interceptors/
        │   │   ├── auth.interceptor.ts      ← agrega Bearer token a cada request
        │   │   └── mock.interceptor.ts      ← simula el backend (MOCKS_FRONTEND.md)
        │   ├── guards/
        │   │   └── auth.guard.ts            ← redirige a login si no hay token
        │   └── services/
        │       └── auth.service.ts          ← login, logout, currentUser signal
        ├── auth/                            ← PASO_S00_06 + integración con Gate 1a
        │   ├── login/
        │   ├── register/
        │   └── verify-email/
        ├── decks/                           ← PASO_S02_03 frontend
        │   ├── deck-list/
        │   ├── deck-builder/
        │   └── deck-detail/
        ├── cards/                           ← Catálogo, colección
        │   ├── card-catalog/
        │   └── card-detail/
        ├── game/                            ← PASO_S05_04 (principal)
        │   ├── models/
        │   │   └── game.models.ts           ← interfaces TypeScript del juego
        │   ├── services/
        │   │   ├── game.service.ts          ← REST calls al GameEngine
        │   │   └── websocket.service.ts     ← conexión STOMP
        │   ├── pages/
        │   │   └── game-board/              ← el tablero completo
        │   └── components/
        │       ├── pokemon-zone/            ← Pokémon activo
        │       ├── bench-zone/              ← Banca
        │       ├── hand-zone/              ← Cartas en mano
        │       ├── action-buttons/          ← botones contextuales por fase
        │       ├── chat-window/
        │       └── notification-center/
        ├── lobby/                           ← sala de espera + matchmaking (Gate 3)
        │   ├── lobby-home/
        │   ├── private-room/
        │   └── matchmaking-queue/
        ├── shop/                            ← tienda de sobres (Gate 4)
        │   ├── booster-list/
        │   └── open-pack/
        ├── leaderboard/                     ← ranking (Gate 1c)
        ├── news/                            ← noticias (Gate 1c)
        ├── friends/                         ← amigos (Gate 3/4)
        └── shared/
            ├── components/
            │   ├── card-thumbnail/          ← imagen de carta reutilizable
            │   ├── hp-bar/                  ← barra de HP
            │   └── status-badge/            ← ícono de condición especial
            └── pipes/
                └── card-type-color.pipe.ts  ← color según tipo de Pokémon
```

---

## 6. INSTRUCCIONES DE EJECUCIÓN — PASO A PASO

### PASO 0.0 — Contratos de API (TODOS juntos)
**Duración:** 3–4 h | **Rol del Equipo B:**

1. Revisar cada endpoint que necesita la UI y comunicárselo al Equipo A
2. Proponer los JSON de response que le serían más cómodos para renderizar
3. Después de la reunión: generar `MOCKS_FRONTEND.md` con JSON completos para cada endpoint
4. Crear el `MockInterceptor` y probarlo contra los mocks

**Preguntas que el Equipo B debe hacerle al Equipo A en esta reunión:**
- ¿Qué campos tiene exactamente la carta en `GET /api/cards`?
- ¿Cómo se estructura `CARD_DRAWN` — el cardId viene en el evento WebSocket o en otro canal?
- ¿Qué estados puede tener una partida (`status`)? ¿Cuándo cambia cada uno?
- ¿Cómo reconectar si el WebSocket se cae — hay un `GET /api/games/{id}` que devuelve el estado completo?

---

### PASO 0.5 — Proyecto Angular
**Duración:** 30 min | **Ejecuta:** Dev del Equipo B

```bash
# 1. Crear proyecto
ng new front --routing=true --style=scss --standalone=true --strict=true

# 2. Instalar dependencias del proyecto
cd front
npm install @fortawesome/fontawesome-free
npm install @stomp/stompjs sockjs-client
npm install @angular/cdk

# 2.b Instalar Tailwind CSS 3 (devDependencies)
npm install -D tailwindcss@3 postcss autoprefixer
npx tailwindcss init

# 3. Copiar el Dockerfile
cp docs/07-infraestructura/Dockerfile.front ~/codemon/front/Dockerfile
cp docs/07-infraestructura/nginx.conf ~/codemon/front/nginx.conf

# 4. Configurar Tailwind
# 4.a Editar tailwind.config.js generado por `tailwindcss init`:
#     module.exports = {
#       content: ["./src/**/*.{html,ts}"],
#       theme: { extend: {} },
#       plugins: [],
#     };
# 4.b En src/styles.scss agregar (al inicio):
#     @tailwind base;
#     @tailwind components;
#     @tailwind utilities;
# 4.c En angular.json verificar que en "styles" solo esté "src/styles.scss"
#     (Tailwind se carga vía directivas en styles.scss, no como CSS extra).

# 5. Verificar
ng serve
# http://localhost:8088 debe mostrar la app de Angular con utilidades Tailwind activas
```

---

### Setup del MockInterceptor (HACER ANTES DE CUALQUIER OTRA COSA)
**Duración:** 1–2 h

Este es el paso más importante del Equipo B. Sin el MockInterceptor funcionando, no se puede desarrollar nada.

```bash
# 1. Crear el interceptor en src/app/core/interceptors/mock.interceptor.ts
# 2. Copiar el código de MOCKS_FRONTEND.md (sección "Configuración del MockInterceptor")
# 3. Crear src/app/core/interceptors/mocks.data.ts
# 4. Copiar todos los mocks de MOCKS_FRONTEND.md

# 5. Registrar en app.config.ts:
# provideHttpClient(withInterceptors([mockInterceptor, authInterceptor]))

# 6. Verificar que el mock funciona:
# En cualquier componente:
this.http.get('/api/auth/me').subscribe(user => console.log(user));
// Debe mostrar el usuario mock de MOCKS_FRONTEND.md en la consola
```

---

### Auth UI (previo a Gate 1a)
**Duración:** 4–5 h

Construir todos los formularios de autenticación contra mocks:
1. `LoginComponent` — formulario con validaciones reactive forms
2. `RegisterComponent` — registro con confirmación de contraseña
3. `VerifyEmailComponent` — ingreso del código de 6 dígitos
4. `AuthGuard` — redirige a `/login` si no hay token en localStorage
5. `AuthInterceptor` — agrega `Authorization: Bearer <token>` a cada request

**Estructura de `AuthService`:**
```typescript
@Injectable({ providedIn: 'root' })
export class AuthService {
  private currentUser = signal<User | null>(null);
  
  login(credentials): Observable<AuthResponse>
  register(data): Observable<void>
  logout(): void
  refreshToken(): Observable<AuthResponse>
  isAuthenticated(): boolean
  getAccessToken(): string | null
}
```

**Al recibir GATE 1a:** Cambiar `environment.useMocks = false` para las rutas de auth y probar que el login real funciona.

---

### PASO 1.4 (frontend) — Deck Builder UI
**Duración:** 4–5 h

Esta es la primera feature visual compleja. Construir en este orden:
1. `DeckListComponent` — listado de mazos del usuario con acciones (editar, eliminar, favorito)
2. `DeckBuilderComponent` — el editor de mazos. Estructura:
   - Panel izquierdo: catálogo de cartas con búsqueda y filtros
   - Panel derecho: cartas del mazo actual con contadores
   - Barra inferior: estado de validación en tiempo real
3. Drag & drop entre catálogo y mazo (o botón `+/-`)
4. Validación visual en tiempo real (contador de cartas, errores)

**Al recibir GATE 1b:** Reemplazar los mocks de `/api/cards` y `/api/decks` por los endpoints reales.

---

### Componentes de las secciones auxiliares (paralelo a la cadena de motor S3-S5 del Equipo A)

Mientras el Equipo A trabaja 5-8 días en el motor de juego, el Equipo B construye:

#### Leaderboard UI (al recibir GATE 6)
- Tabla con ranking, Elo, wins/losses
- Badge de liga del usuario actual

#### Shop UI (contra mocks inicialmente)
- Grid de sobres disponibles con imagen, precio en coins y precio en ARS
- Modal de apertura de sobre con animación de reveal de cartas
- Wallet con saldo de coins

#### Noticias UI (al recibir GATE 6)
- Feed de noticias con categorías (UPDATE, EVENT, MAINTENANCE)
- Detalle de noticia

#### Amigos UI (contra mocks inicialmente)
- Lista de amigos con estado online/offline
- Solicitudes recibidas y enviadas
- Botón "Retar a partida" (conecta al Lobby)

#### App Shell + Navegación
- Sidebar o navbar con links a todas las secciones
- Indicador de coins del usuario
- Indicador de estado de conexión WebSocket

---

### PASO 3.3 — Tablero de Juego Completo (espera GATE 2)
**Duración:** 10–15 h | **Requiere:** GATE 2 (Equipo A PASO_S05_03)

> ⚠️ **No empezar este paso hasta que GATE 2 esté disponible.** Sin el WebSocket real, solo se pueden construir los componentes visuales.

#### Fase A: Componentes visuales (SIN WebSocket — antes de Gate 2)
Construir los componentes visuales con datos hardcodeados o del mock de eventos:

```typescript
// Usar getMockGameEvents() de MOCKS_FRONTEND.md para probar componentes
const mockEvents = getMockGameEvents();
// Alimentar el estado local del tablero con estos eventos
```

Componentes a construir:
1. **`PokemonZoneComponent`** — muestra un Pokémon activo con HP bar, energías, condición especial
2. **`BenchZoneComponent`** — 5 slots con Pokémon o placeholder vacío
3. **`HandZoneComponent`** — mano de cartas con drag & drop
4. **`GameBoardComponent`** — layout del tablero con zonas superior (oponente) e inferior (propio)
5. **`ActionButtonsComponent`** — botones contextuales según fase y turno

#### Fase B: Integración WebSocket (después de Gate 2)
```
# Prompt: cargar PASO_S05_04.md + PROTOCOLO_WEBSOCKET.md completo + 06-system-logic.md
```

```typescript
// WebsocketService — estructura base
@Injectable({ providedIn: 'root' })
export class WebsocketService {
  private client!: Client;
  private gameEvents$ = new Subject<GameEvent>();

  connect(gameId: string, token: string): void {
    this.client = new Client({
      webSocketFactory: () => new SockJS(`${environment.wsUrl}`),
      connectHeaders: { Authorization: `Bearer ${token}` },
      onConnect: () => {
        // Canal público (eventos del juego)
        this.client.subscribe(`/topic/game/${gameId}`, msg => {
          this.gameEvents$.next(JSON.parse(msg.body));
        });
        // Canal privado (CARD_DRAWN con cardId)
        this.client.subscribe(`/user/queue/game/${gameId}`, msg => {
          this.gameEvents$.next(JSON.parse(msg.body));
        });
      },
      reconnectDelay: 5000,  // reconectar automáticamente
    });
    this.client.activate();
  }

  getGameEvents(): Observable<GameEvent> {
    return this.gameEvents$.asObservable();
  }

  disconnect(): void {
    this.client?.deactivate();
  }
}
```

**Regla de sincronización de estado — NUNCA violar:**
```typescript
// ❌ INCORRECTO — modificar estado local antes de confirmación
onAttachEnergy(energy: Card, target: InPlayPokemon): void {
  target.attachedEnergies.push(energy.id);  // ← NO HACER ESTO
  this.gameService.sendAction(...)
}

// ✅ CORRECTO — esperar confirmación del servidor
onAttachEnergy(energy: Card, target: InPlayPokemon): void {
  this.gameService.sendAction({
    type: 'ATTACH_ENERGY',
    payload: { energyCardId: energy.id, targetPokemonId: target.instanceId }
  });
  // El servidor responde con ENERGY_ATTACHED event → actualizar estado
}
```

#### Lógica de drag & drop con validación
```typescript
// Solo permitir soltar cartas en zonas válidas
canDropCard(card: Card, zone: 'ACTIVE' | 'BENCH'): boolean {
  if (card.supertype === 'Energy') return true;    // energías van a cualquier Pokémon
  if (card.supertype === 'Pokémon' && card.subtypes.includes('Basic')) {
    return zone === 'BENCH';                        // básicos solo a banca
  }
  if (card.supertype === 'Pokémon' && !card.subtypes.includes('Basic')) {
    // Evoluciones solo sobre el Pokémon correspondiente
    return this.hasEvolvableTarget(card);
  }
  return false;
}
```

---

### OAuth2 Frontend (PASO_S10_01 — GATE 7)
**Duración:** 2 h | **Depende de:** Equipo C PASO_S10_01 (backend)

```typescript
// Simplemente redirigir al endpoint de Spring Security
loginWithGoogle(): void {
  window.location.href = `${environment.apiUrl}/oauth2/authorization/google`;
}
loginWithGithub(): void {
  window.location.href = `${environment.apiUrl}/oauth2/authorization/github`;
}

// En la ruta de callback: capturar tokens de los query params
// /oauth2/callback?token=xxx&refreshToken=yyy
```

---

## 7. ESTIMACIÓN DE TIEMPO DETALLADA

| Tarea | Horas mín | Horas máx | Observaciones |
|-------|-----------|-----------|---------------|
| PASO_S00_01 (reunión) | 3 | 4 | Conjunto |
| PASO_S00_06 + MockInterceptor | 2 | 3 | Fundamental |
| Auth UI + guards | 4 | 5 | Gate 1a: integrar real |
| PASO_S02_03 (Deck Builder) | 4 | 5 | Gate 1b: integrar real |
| Card Catalog UI | 3 | 4 | Gate 1b: integrar real |
| App shell + navegación | 2 | 3 | |
| PASO_S05_04 Fase A (componentes visuales) | 5 | 7 | Antes de Gate 2 |
| PASO_S05_04 Fase B (integración WS) | 7 | 10 | Requiere Gate 2 |
| Lobby + matchmaking UI | 3 | 4 | Gate 3: integrar real |
| Shop UI | 3 | 4 | Gate 4: integrar real |
| Leaderboard UI | 2 | 2 | GATE 6 disponible |
| Noticias UI | 2 | 2 | GATE 6 disponible |
| Amigos UI | 2 | 3 | GATE 6: integrar real |
| OAuth2 frontend | 2 | 2 | GATE 7: backend OAuth2 disponible |
| E2E tests Playwright | 4 | 5 | GATE 8 |
| **TOTAL** | **48** | **63** | Media: ~55h |

---

## 8. GATES QUE ESPERA EL EQUIPO B

| Gate | De quién | Cuándo | Qué cambia en el frontend |
|------|---------|--------|--------------------------|
| **GATE 1a** | Equipo A (PASO_S01_01) | S1 | Reemplazar mock de auth → `useMocks = false` para `/api/auth/*` |
| **GATE 1b** | Equipo A (PASO_S02_02+1.4) | S2 | Reemplazar mocks de cartas y mazos |
| **GATE 2** | Equipo A (PASO_S05_03) | S5 | **Iniciar Fase B de PASO_S05_04 — integración WebSocket real** |
| **GATE 3** | Equipo C (PASO_S07_01) | S7 | Integrar salas privadas reales |
| **GATE 4** | Equipo C (PASO_S07_02) | S7 | Integrar matchmaking ranked real |
| **GATE 5** | Equipo C (PASO_S08_04 + PASO_S08_06) | S8 | Integrar Shop, pagos, sobres y wallet reales |
| **GATE 6** | Equipo C/B (PASO_S09_01..05) | S9 | Integrar leaderboard, ligas, amigos y noticias reales |
| **GATE 7** | Equipo C/B (PASO_S10_01..02 + perfil) | S10 | Integrar OAuth2 y Profile UI |
| **GATE 8** | Todos (PASO_S11_06 + PASO_S11_07) | S11 | Cerrar Playwright, responsive y Lighthouse |

**Mientras espera un Gate:** El Equipo B no se detiene. Siempre hay otro componente o feature que construir con mocks.

---

## 9. COMANDOS DE USO DIARIO

```bash
# Iniciar servidor de desarrollo (hot reload)
cd ~/codemon/front && ng serve
# http://localhost:8088

# Build de producción (para verificar que compila sin errores)
cd ~/codemon/front && ng build --configuration production

# Verificar tipos TypeScript
cd ~/codemon/front && npx tsc --noEmit

# Correr tests unitarios
cd ~/codemon/front && ng test

# Correr E2E tests (Playwright — GATE 8)
cd ~/codemon/front && npx playwright test

# Instalar nueva dependencia
cd ~/codemon/front && npm install <paquete>
```

---

## 10. REGLAS DE TRABAJO INTERNO DEL EQUIPO B

1. **`strict: true` es innegociable.** No usar `any`, no usar `// @ts-ignore`.
2. **Cleanup obligatorio en `ngOnDestroy`.** Toda suscripción a Observable, WebSocket o evento debe limpiarse.
3. **Estado del juego: solo el servidor manda.** Nunca modificar el estado local del tablero sin confirmación.
4. **Cada componente visual se prueba con mocks antes de integrarlo con el real.** Primero funcionar, después conectar.
5. **Notificar al Equipo A cuando hay preguntas sobre los eventos WebSocket.** No asumir el comportamiento — consultar `PROTOCOLO_WEBSOCKET.md` o preguntar directamente.
6. **El tablero (PASO_S05_04) se empieza a construir en paralelo** (Fase A) sin esperar Gate 2.

---

## 11. SEÑALES DE ALERTA

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| Memory leak — el tablero se vuelve lento | WebSocket no se desconecta en `ngOnDestroy` | Llamar `disconnect()` en el hook |
| El estado del tablero se desincroniza | Se modificó estado local sin esperar evento del servidor | Revertir a patrón event-driven |
| Error `TS2345: Argument of type 'null'` | TypeScript strict: no verificaste null | Usar `?.` u operador de guarda |
| Drag & drop suelta carta en zona incorrecta | Predicado `cdkDropListEnterPredicate` no implementado | Agregar la función de validación |
| WebSocket conecta en dev pero no en producción | URL hardcodeada | Usar `environment.wsUrl` |
| `ExpressionChangedAfterItHasBeenCheckedError` | Modificación de estado en el ciclo de detección | Usar `ChangeDetectorRef.detectChanges()` o `async pipe` |
| `CARD_DRAWN` del oponente muestra la carta | Usaste el canal público en vez del privado | Solo el canal `/user/queue/` debe mostrar el cardId |

---

## 12. CHECKLIST DE CALIDAD (Equipo B — GATE 8)

Antes de declarar el frontend terminado, verificar cada item:

```
Funcionalidades básicas:
□ Login, registro, verificar email
□ Listar, crear, editar y eliminar mazos
□ Validación de mazo en tiempo real (errores visuales)
□ Catálogo de cartas con filtros y búsqueda
□ Colección del usuario

Tablero de juego:
□ Drag & drop de cartas desde mano a tablero
□ Fase y turno correctamente indicados
□ HP del Pokémon activo actualiza en tiempo real
□ Condiciones especiales (veneno, quemadura, etc.) muestran ícono
□ KO anima el Pokémon saliendo del tablero
□ Chat funciona (incluye mensajes del Bot)
□ Notificación de premio tomado
□ Pantalla de fin de partida con ganador

Lobby:
□ Crear sala privada → muestra código de 6 caracteres
□ Unirse a sala con código
□ Cola de matchmaking → estado "Buscando oponente..."

Shop:
□ Lista de sobres disponibles con precio
□ Comprar sobre con coins → animación de apertura
□ Saldo de coins actualizado

Auxiliares:
□ Leaderboard con ranking
□ Feed de noticias
□ Lista de amigos + solicitudes
□ Login con Google/GitHub
```
