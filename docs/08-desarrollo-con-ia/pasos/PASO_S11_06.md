---
id: PASO_S11_06
equipo: B
bloque: 11
dep: [PASO_S10_02, PASO_S05_04]
siguiente: PASO_S11_07
context_files:
  - CONVENCIONES.md
outputs:
  - front/e2e/auth.spec.ts
  - front/e2e/deck-builder.spec.ts
  - front/e2e/matchmaking.spec.ts
  - front/playwright.config.ts
---

# PASO 5B.2 — E2E Tests con Playwright
**Grupo legacy:** 5B — Frontend Final | **Equipo:** B | **Dificultad:** 🟡 | **Tiempo:** 4–5 h

## Navegación
← **Anterior:** [PASO_S10_02](PASO_S10_02.md) — OAuth2 Integration  
→ **Siguiente:** [PASO_S11_07](PASO_S11_07.md) — Responsive Design

---

## Qué construye este paso

Suite completa de E2E tests con Playwright:

1. **auth.spec.ts:**
   - Login flow completo
   - Register flow con email verification
   - Logout
   - AuthGuard redirection

2. **deck-builder.spec.ts:**
   - Crear nuevo mazo
   - Drag & drop cartas
   - Validación de 60 cartas
   - Save deck

3. **matchmaking.spec.ts:**
   - Iniciar PvE game
   - Entrar en cola ranked
   - Match found flow

4. **playwright.config.ts:**
   - Configuración de browsers (chromium, firefox, webkit)
   - Base URL
   - Screenshots on failure
   - Video recording

---

## Prompt listo para el agente

```markdown
Requisitos:

1. **Instalar Playwright:**
   ```bash
   npm install -D @playwright/test
   npx playwright install
   ```

2. **playwright.config.ts:**
   ```typescript
   import { defineConfig } from '@playwright/test';

   export default defineConfig({
     testDir: './e2e',
     fullyParallel: true,
     forbidOnly: !!process.env.CI,
     retries: process.env.CI ? 2 : 0,
     workers: process.env.CI ? 1 : undefined,
     reporter: 'html',
     use: {
       baseURL: 'http://localhost:8088',
       trace: 'on-first-retry',
       screenshot: 'only-on-failure',
     },
     projects: [
       { name: 'chromium', use: { browserName: 'chromium' } },
       { name: 'firefox', use: { browserName: 'firefox' } },
       { name: 'webkit', use: { browserName: 'webkit' } },
     ],
     webServer: {
       command: 'npm run start',
       url: 'http://localhost:8088',
       reuseExistingServer: !process.env.CI,
     },
   });
   ```

3. **auth.spec.ts:**
   ```typescript
   import { test, expect } from '@playwright/test';

   test.describe('Authentication', () => {
     test('should login successfully', async ({ page }) => {
       await page.goto('/auth/login');
       
       await page.fill('input[name="email"]', 'test@example.com');
       await page.fill('input[name="password"]', 'password123');
       await page.click('button[type="submit"]');
       
       await expect(page).toHaveURL('/launcher/play');
     });

     test('should show validation errors', async ({ page }) => {
       await page.goto('/auth/login');
       
       await page.fill('input[name="email"]', 'invalid-email');
       await page.click('button[type="submit"]');
       
       await expect(page.locator('.field-input.error')).toBeVisible();
     });

     test('should register new user', async ({ page }) => {
       await page.goto('/auth/register');
       
       await page.fill('input[name="email"]', 'newuser@example.com');
       await page.fill('input[name="password"]', 'SecurePass123!');
       await page.fill('input[name="confirmPassword"]', 'SecurePass123!');
       await page.check('input[name="acceptTerms"]');
       await page.click('button[type="submit"]');
       
       await expect(page).toHaveURL('/auth/verify-email');
     });

     test('should protect routes with AuthGuard', async ({ page }) => {
       await page.goto('/launcher/decks');
       await expect(page).toHaveURL(/\/auth\/login/);
     });
   });
   ```

4. **deck-builder.spec.ts:**
   ```typescript
   import { test, expect } from '@playwright/test';

   test.describe('Deck Builder', () => {
     test.beforeEach(async ({ page }) => {
       // Login first
       await page.goto('/auth/login');
       await page.fill('input[name="email"]', 'test@example.com');
       await page.fill('input[name="password"]', 'password123');
       await page.click('button[type="submit"]');
       await page.waitForURL('/launcher/play');
     });

     test('should create new deck', async ({ page }) => {
       await page.goto('/launcher/decks');
       await page.click('button:has-text("Create New Deck")');
       
       await expect(page).toHaveURL(/\/launcher\/decks\/builder/);
       
       await page.fill('input.deck-name-input', 'Test Deck');
       
       // Drag card to deck (simplified - adjust based on actual implementation)
       const card = page.locator('.card-item').first();
       const deck = page.locator('.deck-panel');
       await card.dragTo(deck);
       
       await expect(page.locator('.deck-counter')).toContainText('1 / 60');
     });

     test('should validate deck before save', async ({ page }) => {
       await page.goto('/launcher/decks/builder');
       
       const saveButton = page.locator('button:has-text("Save Deck")');
       await expect(saveButton).toBeDisabled();
     });
   });
   ```

5. **matchmaking.spec.ts:**
   ```typescript
   import { test, expect } from '@playwright/test';

   test.describe('Matchmaking', () => {
     test.beforeEach(async ({ page }) => {
       await page.goto('/auth/login');
       await page.fill('input[name="email"]', 'test@example.com');
       await page.fill('input[name="password"]', 'password123');
       await page.click('button[type="submit"]');
       await page.waitForURL('/launcher/play');
     });

     test('should start PvE game', async ({ page }) => {
       await page.click('.mode-card:has-text("Play vs AI")');
       
       await page.selectOption('select', { label: 'Test Deck' });
       await page.click('button:has-text("Play vs AI")');
       
       await expect(page).toHaveURL(/\/game\/\d+/);
     });

     test('should enter ranked queue', async ({ page }) => {
       await page.click('.mode-card:has-text("Ranked PVP")');
       
       await page.selectOption('select', { label: 'Test Deck' });
       await page.click('button:has-text("Find Match")');
       
       await expect(page.locator('.queue-overlay')).toBeVisible();
     });

     test('should cancel ranked queue', async ({ page }) => {
       await page.click('.mode-card:has-text("Ranked PVP")');
       await page.selectOption('select', { label: 'Test Deck' });
       await page.click('button:has-text("Find Match")');
       
       await page.click('button:has-text("Cancel")');
       
       await expect(page.locator('.queue-overlay')).not.toBeVisible();
     });
   });
   ```

Entregables:
- [ ] playwright.config.ts configurado
- [ ] auth.spec.ts completo
- [ ] deck-builder.spec.ts completo
- [ ] matchmaking.spec.ts completo
- [ ] CI/CD integration preparada
```

---

## Comandos

```bash
# Run all tests
npx playwright test

# Run specific test file
npx playwright test e2e/auth.spec.ts

# Run in headed mode (ver browser)
npx playwright test --headed

# Debug mode
npx playwright test --debug

# Generate test report
npx playwright show-report
```

---

## Criterios de aceptación

✅ Tests corren en 3 browsers  
✅ Login/Register flow cubierto  
✅ Deck Builder drag & drop testeado  
✅ Matchmaking flows cubiertos  
✅ Screenshots on failure configurados
