# Frontend — Codemon TCG

Angular 21+ · TypeScript strict · Tailwind CSS 3 · SockJS/StompJS

## Estructura de módulos

```
src/app/
├── auth/          ← Register · verify-email · login
├── home/          ← Landing con mazos favoritos
├── cards/         ← Catálogo con filtros, paginación e imágenes
├── decks/         ← Deck builder con validación en tiempo real
├── game/          ← Tablero de juego con WebSocket STOMP
├── lobby/         ← Cola de matchmaking + salas privadas
├── shop/          ← Tienda de sobres + apertura animada
├── collection/    ← Galería de cartas coleccionadas
├── wallet/        ← Saldo de moneda virtual + historial
├── leaderboard/   ← Ranking global por ELO
├── profile/       ← Perfil de usuario y estadísticas
└── shared/        ← Interceptors JWT · Guards · Models · Components
```

## Desarrollo local

```bash
# Requisitos: Node.js 20+, Angular CLI 17+

# Instalar dependencias
npm install

# Modo mock (sin backend — usa interceptores)
ng serve
# Abre: http://localhost:4200

# Apuntando al backend local (docker compose up o ./mvnw spring-boot:run)
ng serve --configuration=development
```

## Variables de entorno

Configurar en `src/environments/`:

```typescript
// environment.ts (desarrollo)
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8088/api',
  wsUrl:  'http://localhost:8088/ws',
};

// environment.prod.ts (producción / Docker)
export const environment = {
  production: true,
  apiUrl: '/api',   // relativo — Nginx hace el proxy
  wsUrl:  '/ws',
};
```

## Tests

```bash
# Unit tests
ng test

# E2E con Playwright
npx playwright test
```

## Referencias

- [Contratos API](../docs/05-referencia-tecnica/CONTRATOS_API.md)
- [Protocolo WebSocket](../docs/05-referencia-tecnica/PROTOCOLO_WEBSOCKET.md)
- [Mocks Frontend](../docs/05-referencia-tecnica/MOCKS_FRONTEND.md)
- [Mockups UI](../docs/04-diseno-ui/)
- [Guía Equipo B](../docs/03-equipos/GUIA_EQUIPO_B.md)
