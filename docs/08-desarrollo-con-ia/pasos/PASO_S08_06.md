---
id: PASO_S08_06
equipo: B
bloque: 8
dep: [PASO_S06_01, PASO_S08_04]
siguiente: PASO_S08_SMOKE
context_files:
  - CONTRATOS_API.md
  - MOCKS_FRONTEND.md
outputs:
  - front/src/app/pages/shop/shop.component.ts
  - front/src/app/pages/shop/components/pack-opening/pack-opening.component.ts
  - front/src/app/shared/services/shop.service.ts
---

# PASO 3B.2 — Shop UI (Booster Packs + Apertura Animada)
**Grupo legacy:** 3B — Frontend Features | **Equipo:** B | **Dificultad:** 🟡 | **Tiempo:** 3–4 h

## Navegación
← **Anterior:** [PASO_S06_01](PASO_S06_01.md) — Lobby UI  
→ **Siguiente:** [PASO_S09_04](PASO_S09_04.md) — Leaderboard + News UI

---

## Qué construye este paso

La **tienda** donde los usuarios compran sobres de cartas con monedas del juego:

1. **ShopComponent:**
   - Grid de booster packs disponibles
   - Cada pack card muestra:
     - Imagen del sobre
     - Nombre (ej: "Base Set Booster")
     - Precio en coins
     - Botón "Buy Pack"
   - Balance de coins del usuario en header

2. **PackOpeningComponent:**
   - Animación de apertura del sobre (CSS 3D flip)
   - Revelar cartas una por una con delay
   - Efecto holográfico en cartas raras
   - Botón "Open Another" / "Close"

3. **ShopService:**
   - `getAvailablePacks(): Observable<Pack[]>`
   - `buyPack(packId): Observable<PurchaseResponse>`
   - `openPack(purchaseId): Observable<Card[]>`

---

## Prompt listo para el agente

```markdown
Estructura:
front/src/app/pages/shop/
├── shop.component.ts
├── components/
│   └── pack-opening/
│       └── pack-opening.component.ts

Requisitos:

1. **ShopComponent:**
   ```typescript
   export class ShopComponent implements OnInit {
     availablePacks: Pack[] = [];
     userCoins = 0;
     selectedPack?: Pack;
     isOpening = false;

     ngOnInit() {
       this.shopService.getAvailablePacks().subscribe({
         next: (packs) => this.availablePacks = packs
       });
       
       this.authService.currentUser$.subscribe({
         next: (user) => this.userCoins = user?.coins || 0
       });
     }

     onBuyPack(pack: Pack) {
       if (this.userCoins < pack.price) {
         alert('Not enough coins');
         return;
       }

       this.shopService.buyPack(pack.id).subscribe({
         next: (response) => {
           this.userCoins -= pack.price;
           this.selectedPack = pack;
           this.isOpening = true;
         }
       });
     }

     onPackOpened() {
       this.isOpening = false;
       this.selectedPack = undefined;
     }
   }
   ```

2. **PackOpeningComponent:**
   ```typescript
   export class PackOpeningComponent implements OnInit {
     @Input() pack!: Pack;
     @Output() closed = new EventEmitter<void>();

     cards: Card[] = [];
     revealedCards: Card[] = [];
     currentCardIndex = 0;
     isRevealing = false;

     ngOnInit() {
       this.shopService.openPack(this.pack.purchaseId).subscribe({
         next: (cards) => {
           this.cards = cards;
           this.startRevealAnimation();
         }
       });
     }

     private startRevealAnimation() {
       this.isRevealing = true;
       
       const revealInterval = setInterval(() => {
         if (this.currentCardIndex < this.cards.length) {
           this.revealedCards.push(this.cards[this.currentCardIndex]);
           this.currentCardIndex++;
         } else {
           clearInterval(revealInterval);
           this.isRevealing = false;
         }
       }, 800);
     }

     onClose() {
       this.closed.emit();
     }
   }
   ```

Entregables:
- [ ] ShopComponent con grid de packs
- [ ] Buy pack flow funcional
- [ ] PackOpeningComponent con animación CSS
- [ ] Efecto holográfico en raras
- [ ] ShopService con endpoints
```

---

## Tests sugeridos

```typescript
describe('ShopComponent', () => {
  it('should prevent buying if insufficient coins', () => {
    component.userCoins = 100;
    const pack = { price: 200 };
    component.onBuyPack(pack);
    expect(component.isOpening).toBe(false);
  });
});
```

---

## Criterios de aceptación

✅ Grid de packs funcional  
✅ Animación de apertura smooth  
✅ Cartas reveladas secuencialmente  
✅ Balance de coins actualizado
