---
id: PASO_S00_01
equipo: ALL
bloque: 0
dep: []
siguiente: PASO_S00_02 PASO_S00_04, PASO_S00_06]
context_files:
  - ESPECIFICACION_PRODUCTO.md
  - BD_Y_TABLAS.md
  - 06-system-logic.md
outputs:
  - CONTRATOS_API.md
  - PROTOCOLO_WEBSOCKET.md
  - MOCKS_FRONTEND.md
---

# PASO 0.0 — Definición de Contratos de API y Protocolo WebSocket
**Grupo legacy:** 0 — Infraestructura | **Sprint:** S0 | **Dificultad:** 🟡 | **Tiempo:** 3–4 h
**Equipo:** TODOS (liderado por Equipo A, con input obligatorio de B y C)

## Navegación
← **Anterior:** *(primer paso del proyecto)*
→ **Siguiente (paralelo):** [PASO_S00_02](PASO_S00_02.md) (Equipo C) · [PASO_S00_04](PASO_S00_04.md) (Equipo A) · [PASO_S00_06](PASO_S00_06.md) (Equipo B)

> **Este paso no existía en el plan original.** Se agrega para habilitar el trabajo paralelo entre los 3 equipos: sin contratos definidos desde el inicio, el Equipo B dependería al 100% del Equipo A para cada integración.

## Archivos a cargar junto a este
- `ESPECIFICACION_PRODUCTO.md` — referencia de todas las features
- `SCHEMA_BD.sql` — para entender los modelos de datos
- `06-system-logic.md` — para el protocolo WebSocket
- `CONTRATOS_API.md` (este paso lo crea)
- `PROTOCOLO_WEBSOCKET.md` (este paso lo crea)
- `MOCKS_FRONTEND.md` (este paso lo crea)

## Qué construye este paso

Produce **3 documentos de coordinación** que permiten a los 3 equipos trabajar de forma independiente desde el día 1:

1. **`CONTRATOS_API.md`** — Todos los endpoints REST con sus DTOs de request y response. El Equipo B usará este documento para construir sus Angular services contra mocks antes de tener el backend real.
2. **`PROTOCOLO_WEBSOCKET.md`** — Todos los eventos STOMP del motor de juego con su formato de payload. El Equipo B construirá el cliente WebSocket del tablero en base a este documento.
3. **`MOCKS_FRONTEND.md`** — JSON de ejemplo para cada endpoint, listos para usar en un interceptor de Angular que simule el backend.

> **Estos documentos son borradores vivos.** Pueden refinarse durante el desarrollo. Lo importante es tener la estructura de cada endpoint definida desde el inicio; los campos pueden ajustarse.

## Cómo ejecutar este paso (dinámica de reunión)

### Segmento 1 (1 h) — Repaso de features (todos juntos)
- Leer juntos la sección de features de `ESPECIFICACION_PRODUCTO.md`
- Identificar todos los dominios: auth, cards, decks, games, rooms, matchmaking, collection, boosters, payments, leaderboard, news, friends, users
- Equipo A presenta los modelos de BD del `SCHEMA_BD.sql` (qué tablas hay y qué exponen)

### Segmento 2 (1.5 h) — Definir endpoints REST (Equipo A lidera, B y C aportan)
- Por cada dominio: definir qué endpoints necesita el frontend (Equipo B propone, Equipo A valida)
- Documentar en `CONTRATOS_API.md`: método HTTP, path, request body, response body
- **Foco del Equipo B:** ¿qué datos necesito para renderizar cada pantalla?
- **Foco del Equipo A:** ¿qué endpoints son fáciles/difíciles de implementar? ¿cuáles tienen dependencias?

### Segmento 3 (30 min) — Definir protocolo WebSocket (Equipo A lidera)
- Repasar `06-system-logic.md` junto a los 3 equipos
- El Equipo B hace preguntas sobre los payloads de cada evento
- Documentar en `PROTOCOLO_WEBSOCKET.md` (ya está disponible como base)

### Segmento 4 (30 min) — Generar mocks (Equipo B lidera)
- El Equipo B genera JSON de ejemplo para cada endpoint en `MOCKS_FRONTEND.md`
- El Equipo A valida que los JSON son consistentes con los modelos de BD

## Pseudocódigo del interceptor de mocks (Angular)

```typescript
// src/app/core/interceptors/mock.interceptor.ts
// Solo activo cuando environment.useMocks = true

@Injectable()
export class MockInterceptor implements HttpInterceptor {
  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    if (!environment.useMocks) return next.handle(req);
    
    const mock = MOCKS[`${req.method} ${req.url}`];
    if (mock) {
      return of(new HttpResponse({ status: 200, body: mock })).pipe(delay(200));
    }
    return next.handle(req);
  }
}

// src/environments/environment.ts
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8088/api',
  useMocks: true,  // ← cambiar a false cuando el backend esté listo
};
```

## Estructura del contrato por endpoint

Cada endpoint en `CONTRATOS_API.md` debe tener:
```
### POST /api/auth/login
- Autenticación: No requiere
- Request: { "usernameOrEmail": "string", "password": "string" }
- Response 200: { "accessToken": "string", "refreshToken": "string", "user": { ... } }
- Response 401: { "error": "INVALID_CREDENTIALS" }
- Response 403: { "error": "EMAIL_NOT_VERIFIED" }
- Observaciones: El accessToken expira en JWT_EXPIRY_MS (del .env)
```

## Errores comunes

- **Definir endpoints demasiado específicos:** Mejor empezar con la estructura básica y agregar campos después que bloquear el trabajo por falta de detalles.
- **Olvidar los endpoints de paginación:** Endpoints de listado (`GET /api/cards`, `GET /api/news`) deben tener parámetros `page`, `size`, `sort` desde el inicio.
- **No separar datos públicos de privados en WebSocket:** Los payloads de eventos nunca deben incluir mano del rival, contenido del mazo ni cartas de Premio.
- **Mocks sin datos realistas:** Usar nombres reales de cartas del set XY1 y usernames creíbles en los JSON de ejemplo — facilita detectar bugs de tipeo en el frontend.

## Verificación

Al finalizar este paso, los 3 equipos deben poder responder SÍ a todas estas preguntas:

```
□ ¿Sabe el Equipo B cómo hacer login y guardar el JWT en el frontend?
□ ¿Sabe el Equipo B qué campos tiene una carta en GET /api/cards?
□ ¿Sabe el Equipo B cómo crear y guardar un mazo?
□ ¿Sabe el Equipo B qué eventos WebSocket esperar durante una partida?
□ ¿Tiene el Equipo B JSONs de ejemplo para todas las pantallas?
□ ¿Sabe el Equipo C qué estructura de datos esperan los endpoints de matchmaking?
□ ¿Está el Equipo A de acuerdo con todos los contratos definidos?
# PASS: todos los ítems marcados ✓ — GATE 0 desbloqueado, equipos avanzan en paralelo
# FAIL: algún ítem en duda → continuar reunión antes de avanzar a PASO_S00_02 / PASO_S00_04 / PASO_S00_06
```

## Documentos que crea

| Documento | Responsable de crearlo | Quién lo usa |
|-----------|----------------------|--------------|
| `CONTRATOS_API.md` | Equipo A (con input de B y C) | Equipo B para construir Angular services |
| `PROTOCOLO_WEBSOCKET.md` | Equipo A (con input de B) | Equipo B para el cliente WebSocket del tablero |
| `MOCKS_FRONTEND.md` | Equipo B (validado por A) | Equipo B para el mock interceptor de Angular |

## Dependencias

- **Debe ejecutarse antes que:** PASO_S00_02, PASO_S00_04, PASO_S00_06 (aunque puede hacerse en paralelo con la instalación de herramientas)
- **No depende de:** Ningún paso anterior. Es el punto de partida del proyecto multi-equipo.
- **Output del GATE 0:** Este paso es parte del criterio de completitud del GATE 0.
