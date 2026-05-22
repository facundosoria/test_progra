---
id: PASO_S00_06
equipo: B
bloque: 0
dep: [PASO_S00_01]
siguiente: PASO_S00_07
context_files:
  - Dockerfile.front
  - nginx.conf
  - ESTRUCTURA_PROYECTO.md
outputs:
  - front/src/environments/environment.ts
  - front/src/environments/environment.prod.ts
---

# PASO 0.5 — Crear proyecto Angular
**Grupo legacy:** 0 — Infraestructura | **Equipo:** B | **Dificultad:** 🟢 | **Tiempo:** 30 min

## Navegación
← **Anterior:** [PASO_S00_01](PASO_S00_01.md) — Contratos de API y mocks definidos (Equipo B puede empezar)
→ **Siguiente:** [PASO_S01_02](PASO_S01_02.md) — Auth UI (Login + Register + Verify Email)

> ⚠️ **Aclaración de siguiente:** El paso directo del Equipo B después de crear el proyecto Angular es `PASO_S01_02` (Auth UI), no `PASO_S02_03`. El paso `PASO_S02_03` es principalmente backend (Equipo A) y requiere que `PASO_S02_01`, `PASO_S01_01` y `PASO_S02_02` estén completos. El Equipo B puede arrancar `PASO_S01_02` usando el `MockAuthInterceptor` de los mocks definidos en `PASO_S00_01`, sin esperar al backend real.

## Archivos a cargar junto a este
- `Dockerfile.front`
- `nginx.conf`
- `ESTRUCTURA_PROYECTO.md` (sección Frontend, como referencia de la estructura de carpetas)

## Qué construye este paso
Genera el proyecto Angular con la estructura de features, instala las dependencias y configura el entorno de desarrollo y producción.

## Comandos

```bash
cd ~/codemon

# Generar proyecto (Standalone Components, sin SSR)
ng new front --routing=true --style=scss --skip-git=true --standalone=true --ssr=false

cd front

# Instalar dependencias runtime
npm install @stomp/stompjs sockjs-client @fortawesome/fontawesome-free @angular/cdk
npm install -D @types/sockjs-client

# Instalar Tailwind CSS 3 (devDependencies)
npm install -D tailwindcss@3 postcss autoprefixer
npx tailwindcss init

# Copiar Dockerfile y nginx config
cp /ruta/Dockerfile.front ~/codemon/front/Dockerfile
cp /ruta/nginx.conf       ~/codemon/front/nginx.conf
```

## Configurar Tailwind CSS

1. Editar `tailwind.config.js` generado por `tailwindcss init`:

   ```js
   /** @type {import('tailwindcss').Config} */
   module.exports = {
     content: ["./src/**/*.{html,ts}"],
     theme: { extend: {} },
     plugins: [],
   };
   ```

2. En `src/styles.scss` agregar al inicio:

   ```scss
   @tailwind base;
   @tailwind components;
   @tailwind utilities;
   ```

3. En `angular.json` (proyecto `front` → `architect.build.options.styles`) verificar que la lista incluya únicamente `src/styles.scss` (más eventualmente `@fortawesome/fontawesome-free/css/all.min.css`). Tailwind se aplica vía las directivas en `styles.scss`; no se referencian archivos CSS extra de frameworks.

## Estructura de features a crear

```bash
# Crear estructura de módulos (dentro de front/src/app/)
mkdir -p src/app/{auth,home,cards,decks,shop,collection,wallet,lobby,game,leaderboard,profile,friends,news}/
mkdir -p src/app/shared/{interceptors,guards,services,models,components}
mkdir -p src/environments
```

## Archivo environments/environment.ts

El modo oficial de desarrollo es **Full Docker** con el gateway en `localhost:8088`.
Usar rutas relativas tanto en dev como en prod para que el interceptor HTTP funcione igual en ambos entornos:

```typescript
// environment.ts — desarrollo (Full Docker en localhost:8088)
export const environment = {
  production: false,
  apiUrl: '/api',
  wsUrl: '/ws'
};
```

```typescript
// environment.development.ts — debug directo (sin Docker, api en 8080)
// Solo usar cuando se corra la API con mvn spring-boot:run fuera de Docker
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8080/api',
  wsUrl: 'http://localhost:8080/ws'
};
```

## Archivo environments/environment.prod.ts

```typescript
export const environment = {
  production: true,
  apiUrl: '/api',
  wsUrl: '/ws'
};
```

## Errores comunes

- `ng: command not found` → `npm install -g @angular/cli@latest` y reiniciar terminal
- Errores de TypeScript strict → son esperados con los archivos vacíos, se resuelven al implementar
- Tailwind no compila estilos → verificar tres cosas:
  1. `tailwind.config.js` existe en la raíz de `front/` con `content: ["./src/**/*.{html,ts}"]` (sin esto Tailwind purgea todas las clases en build).
  2. `src/styles.scss` empieza con `@tailwind base; @tailwind components; @tailwind utilities;`.
  3. En `angular.json`, el bloque `"styles"` del target `build` referencia `"src/styles.scss"`. Para íconos opcionalmente:
     ```json
     "src/styles.scss",
     "node_modules/@fortawesome/fontawesome-free/css/all.min.css"
     ```
- Si las utilidades responsive (`md:`, `lg:`) no aplican → revisar que el archivo donde están las clases esté incluido en el patrón `content` del `tailwind.config.js`.

## Verificación

```bash
# Verificar que el build de producción compila
cd ~/codemon/front && ng build --configuration production
# PASS: "Application bundle generation complete." sin errores
# FAIL: cualquier error de TypeScript o dependencia faltante

# Verificar el proyecto completo con Docker (modo recomendado)
cd ~/codemon && docker --context colima compose up -d --build
curl -fs http://localhost:8088/ -o /dev/null && echo "Frontend OK via gateway"
# PASS: "Frontend OK via gateway"
# FAIL: Connection refused → verificar que codemon_front está healthy
```

## Dependencias
PASO_S00_04 completado (no depende directamente, pero lógicamente va después de tener el proyecto base).
