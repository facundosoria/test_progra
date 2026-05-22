---
id: PASO_S02_05
equipo: B
bloque: 2
dep: [PASO_S02_04, PASO_S02_02]
siguiente: PASO_S02_SMOKE
context_files:
  - CONTRATOS_API.md
  - CARTAS_E_IMAGENES.md
  - MOCKS_FRONTEND.md
outputs:
  - front/src/app/pages/cards/card-catalog/card-catalog.component.ts
  - front/src/app/pages/cards/card-detail/card-detail.component.ts
  - front/src/app/shared/services/card.service.ts
  - front/src/app/shared/pipes/card-filter.pipe.ts
---

# PASO 1B.4 — Card Catalog UI (Grid + Filtros + Búsqueda)
**Grupo legacy:** 1B — Frontend Core | **Equipo:** B | **Dificultad:** 🟡 | **Tiempo:** 3–4 h

## Navegación
← **Anterior:** [PASO_S02_04](PASO_S02_04.md) — Deck Builder UI  
→ **Siguiente:** [PASO_S06_01](PASO_S06_01.md) — Lobby UI

---

## Qué construye este paso

El **catálogo completo de cartas** con búsqueda avanzada y vista detallada:

1. **CardCatalogComponent:**
   - Grid responsive de cartas (3-6 columnas según viewport)
   - Search bar en el header
   - Filtros laterales:
     - Type: Pokémon / Trainer / Energy
     - Rarity: Common / Uncommon / Rare / Holo Rare
     - Energy Type: Fire / Water / Grass / Electric / etc.
     - Evolution Stage: Basic / Stage 1 / Stage 2
   - Paginación (20 cartas por página)
   - Loading skeleton mientras carga

2. **CardDetailComponent:**
   - Modal fullscreen con imagen grande de la carta
   - Stats completos (HP, attacks, weakness, resistance)
   - Texto de habilidades/ataques
   - Botón "Add to Deck" → dropdown para elegir mazo
   - Botón "Close" (ESC key también cierra)

3. **CardService:**
   - `getAllCards(filters?): Observable<Card[]>`
   - `getCardById(id): Observable<Card>`
   - `searchCards(term): Observable<Card[]>`
   - Caching local para evitar requests repetidos

4. **CardFilterPipe:**
   - Filtrado en memoria para performance
   - Búsqueda fuzzy (permite typos menores)

---

## Prerrequisito: dependencia con PASO_S02_02

Este paso declara `dep: [PASO_S02_04, PASO_S02_02]`. El motivo: `PASO_S02_02 — SetupState` es el paso del Equipo A que popula la base de datos con las 146 cartas XY1 (seed). Sin ese seed, `GET /api/cards` devuelve una lista vacía.

Durante el desarrollo inicial el Equipo B trabaja contra mocks (`useMocks: true`). Cuando el Equipo A completa PASO_S02_02 y el seed corre en la BD, el Equipo B puede apagar el mock para `/api/cards/*` y verificar el catálogo real.

---

## Prompt listo para el agente

```markdown
Contexto:
Sos el Equipo B del proyecto Codemon TCG. Ya tenés el Deck Builder (PASO_S02_04) funcionando. Ahora necesitás el catálogo de cartas — la librería completa donde los usuarios pueden explorar todas las cartas disponibles.

El seed de cartas lo ejecuta el Equipo A en PASO_S02_02, pero trabajarás contra mocks hasta que ese paso esté completo.

Estructura:
front/src/app/pages/cards/
├── card-catalog/
│   ├── card-catalog.component.ts
│   ├── card-catalog.component.html
│   └── card-catalog.component.scss
└── card-detail/
    ├── card-detail.component.ts
    ├── card-detail.component.html
    └── card-detail.component.scss

Requisitos técnicos:

1. **CardCatalogComponent:**
   ```typescript
   export class CardCatalogComponent implements OnInit {
     allCards: Card[] = [];
     filteredCards: Card[] = [];
     displayedCards: Card[] = [];
     
     // Filters
     searchTerm = '';
     selectedType: CardType | 'ALL' = 'ALL';
     selectedRarity: string | 'ALL' = 'ALL';
     selectedEnergyType: EnergyType | 'ALL' = 'ALL';
     selectedEvolutionStage: string | 'ALL' = 'ALL';
     
     // Pagination
     currentPage = 1;
     pageSize = 20;
     totalPages = 1;
     
     isLoading = true;
     selectedCard?: Card;

     ngOnInit() {
       this.cardService.getAllCards().subscribe({
         next: (cards) => {
           this.allCards = cards;
           this.applyFilters();
           this.isLoading = false;
         }
       });
     }

     applyFilters() {
       let result = [...this.allCards];
       
       // Search term
       if (this.searchTerm) {
         result = result.filter(c => 
           c.name.toLowerCase().includes(this.searchTerm.toLowerCase())
         );
       }
       
       // Type filter
       if (this.selectedType !== 'ALL') {
         result = result.filter(c => c.type === this.selectedType);
       }
       
       // Rarity filter
       if (this.selectedRarity !== 'ALL') {
         result = result.filter(c => c.rarity === this.selectedRarity);
       }
       
       // Energy type filter
       if (this.selectedEnergyType !== 'ALL') {
         result = result.filter(c => c.energyType === this.selectedEnergyType);
       }
       
       // Evolution stage filter
       if (this.selectedEvolutionStage !== 'ALL') {
         result = result.filter(c => c.evolutionStage === this.selectedEvolutionStage);
       }
       
       this.filteredCards = result;
       this.totalPages = Math.ceil(result.length / this.pageSize);
       this.updateDisplayedCards();
     }

     updateDisplayedCards() {
       const start = (this.currentPage - 1) * this.pageSize;
       const end = start + this.pageSize;
       this.displayedCards = this.filteredCards.slice(start, end);
     }

     onCardClick(card: Card) {
       this.selectedCard = card;
       // Abrir modal de detalle
     }

     onPageChange(page: number) {
       this.currentPage = page;
       this.updateDisplayedCards();
       window.scrollTo({ top: 0, behavior: 'smooth' });
     }

     resetFilters() {
       this.searchTerm = '';
       this.selectedType = 'ALL';
       this.selectedRarity = 'ALL';
       this.selectedEnergyType = 'ALL';
       this.selectedEvolutionStage = 'ALL';
       this.applyFilters();
     }
   }
   ```

   HTML template:
   ```html
   <div class="card-catalog">
     <!-- Sidebar filters -->
     <aside class="filters-sidebar">
       <div class="filter-section">
         <h3>Filters</h3>
         <button class="btn-text" (click)="resetFilters()">Reset All</button>
       </div>

       <div class="filter-group">
         <label>Type</label>
         <select [(ngModel)]="selectedType" (ngModelChange)="applyFilters()">
           <option value="ALL">All Types</option>
           <option value="POKEMON">Pokémon</option>
           <option value="TRAINER">Trainer</option>
           <option value="ENERGY">Energy</option>
         </select>
       </div>

       <div class="filter-group">
         <label>Rarity</label>
         <select [(ngModel)]="selectedRarity" (ngModelChange)="applyFilters()">
           <option value="ALL">All Rarities</option>
           <option value="COMMON">Common</option>
           <option value="UNCOMMON">Uncommon</option>
           <option value="RARE">Rare</option>
           <option value="HOLO_RARE">Holo Rare</option>
         </select>
       </div>

       <div class="filter-group" *ngIf="selectedType === 'POKEMON'">
         <label>Evolution Stage</label>
         <select [(ngModel)]="selectedEvolutionStage" (ngModelChange)="applyFilters()">
           <option value="ALL">All Stages</option>
           <option value="BASIC">Basic</option>
           <option value="STAGE_1">Stage 1</option>
           <option value="STAGE_2">Stage 2</option>
         </select>
       </div>

       <div class="filter-group">
         <label>Energy Type</label>
         <select [(ngModel)]="selectedEnergyType" (ngModelChange)="applyFilters()">
           <option value="ALL">All Types</option>
           <option value="FIRE">Fire</option>
           <option value="WATER">Water</option>
           <option value="GRASS">Grass</option>
           <option value="ELECTRIC">Electric</option>
           <option value="PSYCHIC">Psychic</option>
           <option value="FIGHTING">Fighting</option>
           <option value="DARK">Dark</option>
           <option value="COLORLESS">Colorless</option>
         </select>
       </div>
     </aside>

     <!-- Main content -->
     <div class="catalog-content">
       <!-- Search bar -->
       <div class="search-bar">
         <input
           type="text"
           placeholder="Search by name..."
           [(ngModel)]="searchTerm"
           (ngModelChange)="applyFilters()"
         />
         <span class="result-count">{{ filteredCards.length }} cards</span>
       </div>

       <!-- Card grid -->
       <div class="card-grid" *ngIf="!isLoading">
         <app-card-item
           *ngFor="let card of displayedCards"
           [card]="card"
           (cardClick)="onCardClick(card)"
         ></app-card-item>
       </div>

       <!-- Loading skeleton -->
       <div class="card-grid skeleton" *ngIf="isLoading">
         <div class="skeleton-card" *ngFor="let i of [1,2,3,4,5,6,7,8,9,10,11,12]"></div>
       </div>

       <!-- Pagination -->
       <div class="pagination" *ngIf="totalPages > 1">
         <button
           [disabled]="currentPage === 1"
           (click)="onPageChange(currentPage - 1)"
         >
           Previous
         </button>
         
         <span class="page-info">Page {{ currentPage }} of {{ totalPages }}</span>
         
         <button
           [disabled]="currentPage === totalPages"
           (click)="onPageChange(currentPage + 1)"
         >
           Next
         </button>
       </div>
     </div>
   </div>

   <!-- Card detail modal -->
   <app-card-detail
     *ngIf="selectedCard"
     [card]="selectedCard"
     (close)="selectedCard = undefined"
   ></app-card-detail>
   ```

2. **CardDetailComponent:**
   ```typescript
   @Component({
     selector: 'app-card-detail',
     standalone: true,
     template: `
       <div class="overlay-backdrop" (click)="onClose()">
         <div class="overlay-panel" (click)="$event.stopPropagation()">
           <button class="close-btn" (click)="onClose()">✕</button>
           
           <div class="card-detail-layout">
             <div class="card-image-section">
               <img [src]="card.imageUrl" [alt]="card.name" />
             </div>
             
             <div class="card-info-section">
               <h2>{{ card.name }}</h2>
               
               <div class="card-meta">
                 <span class="type">{{ card.type }}</span>
                 <span class="rarity">{{ card.rarity }}</span>
               </div>

               <div class="card-stats" *ngIf="card.type === 'POKEMON'">
                 <div class="stat">
                   <label>HP</label>
                   <span>{{ card.hp }}</span>
                 </div>
                 <div class="stat">
                   <label>Evolution</label>
                   <span>{{ card.evolutionStage }}</span>
                 </div>
               </div>

               <div class="card-attacks" *ngIf="card.attacks?.length">
                 <h3>Attacks</h3>
                 <div class="attack" *ngFor="let attack of card.attacks">
                   <div class="attack-header">
                     <span class="attack-name">{{ attack.name }}</span>
                     <span class="attack-damage">{{ attack.damage }}</span>
                   </div>
                   <p class="attack-text">{{ attack.text }}</p>
                   <div class="attack-cost">
                     <span *ngFor="let energy of attack.energyCost">
                       <i class="energy-icon" [class]="energy.type"></i>
                     </span>
                   </div>
                 </div>
               </div>

               <div class="card-abilities" *ngIf="card.abilities?.length">
                 <h3>Abilities</h3>
                 <div class="ability" *ngFor="let ability of card.abilities">
                   <strong>{{ ability.name }}</strong>
                   <p>{{ ability.text }}</p>
                 </div>
               </div>

               <div class="card-weakness-resistance">
                 <div *ngIf="card.weakness">
                   <label>Weakness</label>
                   <span>{{ card.weakness.type }} ×{{ card.weakness.multiplier }}</span>
                 </div>
                 <div *ngIf="card.resistance">
                   <label>Resistance</label>
                   <span>{{ card.resistance.type }} -{{ card.resistance.value }}</span>
                 </div>
               </div>

               <button class="action-primary" (click)="onAddToDeck()">
                 Add to Deck
               </button>
             </div>
           </div>
         </div>
       </div>
     `
   })
   export class CardDetailComponent {
     @Input() card!: Card;
     @Output() close = new EventEmitter<void>();

     @HostListener('document:keydown.escape')
     onEscapeKey() {
       this.onClose();
     }

     onClose() {
       this.close.emit();
     }

     onAddToDeck() {
       // Mostrar dropdown de mazos o navegar a deck builder
       console.log('Add to deck:', this.card.name);
     }
   }
   ```

3. **CardService con caching:**
   ```typescript
   @Injectable({ providedIn: 'root' })
   export class CardService {
     private readonly API_URL = `${environment.apiUrl}/cards`;
     private cardsCache$ = new BehaviorSubject<Card[] | null>(null);

     constructor(private http: HttpClient) {}

     getAllCards(forceRefresh = false): Observable<Card[]> {
       if (!forceRefresh && this.cardsCache$.value) {
         return of(this.cardsCache$.value);
       }

       return this.http.get<Card[]>(this.API_URL).pipe(
         tap(cards => this.cardsCache$.next(cards)),
         shareReplay(1)
       );
     }

     getCardById(id: number): Observable<Card> {
       // Intentar obtener de cache primero
       const cached = this.cardsCache$.value?.find(c => c.id === id);
       if (cached) {
         return of(cached);
       }

       return this.http.get<Card>(`${this.API_URL}/${id}`);
     }

     searchCards(term: string): Observable<Card[]> {
       return this.http.get<Card[]>(`${this.API_URL}/search`, {
         params: { q: term }
       });
     }

     clearCache() {
       this.cardsCache$.next(null);
     }
   }
   ```

Entregables:
- [ ] CardCatalogComponent con grid responsive
- [ ] Filtros laterales funcionales
- [ ] CardDetailComponent modal
- [ ] CardService con caching
- [ ] Paginación funcional
- [ ] Loading skeleton
```

---

## Tests sugeridos

```typescript
describe('CardCatalogComponent', () => {
  it('should filter cards by type', () => {
    component.allCards = [
      mockCard({ type: 'POKEMON' }),
      mockCard({ type: 'TRAINER' })
    ];
    component.selectedType = 'POKEMON';
    component.applyFilters();
    expect(component.filteredCards.length).toBe(1);
  });

  it('should search cards by name', () => {
    component.allCards = [
      mockCard({ name: 'Pikachu' }),
      mockCard({ name: 'Charizard' })
    ];
    component.searchTerm = 'pika';
    component.applyFilters();
    expect(component.filteredCards.length).toBe(1);
  });

  it('should paginate correctly', () => {
    component.filteredCards = Array(50).fill(null).map((_, i) => mockCard({ id: i }));
    component.pageSize = 20;
    component.updateDisplayedCards();
    expect(component.displayedCards.length).toBe(20);
    expect(component.totalPages).toBe(3);
  });
});
```

---

## Errores comunes

### 1. **Filtros no reaccionan**
**Síntoma:** Cambiar filtro no actualiza grid  
**Causa:** Falta `(ngModelChange)="applyFilters()"`  
**Solución:**
```html
<select [(ngModel)]="selectedType" (ngModelChange)="applyFilters()">
```

### 2. **Modal no cierra con ESC**
**Síntoma:** ESC key no funciona  
**Causa:** Falta `@HostListener`  
**Solución:**
```typescript
@HostListener('document:keydown.escape')
onEscapeKey() {
  this.onClose();
}
```

### 3. **Cards duplicadas después de cambiar página**
**Síntoma:** Al volver a página 1, hay duplicados  
**Causa:** No se resetea `displayedCards`  
**Solución:**
```typescript
updateDisplayedCards() {
  const start = (this.currentPage - 1) * this.pageSize;
  const end = start + this.pageSize;
  this.displayedCards = this.filteredCards.slice(start, end);
}
```

---

## Verificación manual

- [ ] Grid muestra cartas en 3-6 columnas según viewport
- [ ] Filtros actualizan grid inmediatamente
- [ ] Search bar funciona con texto parcial
- [ ] Paginación cambia cartas visibles
- [ ] Click en carta abre modal con detalles
- [ ] Modal se cierra con X, ESC, o click afuera
- [ ] Loading skeleton aparece mientras carga

---

## Criterios de aceptación

### ✅ Obligatorios
1. Grid responsive funcional
2. Filtros múltiples aplicables
3. Search bar en tiempo real
4. Paginación correcta
5. Modal de detalle

### 🎯 Opcionales
- Infinite scroll en vez de paginación
- Sort by (name, rarity, HP)
- Grid/List view toggle
