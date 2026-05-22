---
id: PASO_S02_04
equipo: B
bloque: 2
dep: [PASO_S01_03, PASO_S02_03]
siguiente: PASO_S02_05
context_files:
  - CONTRATOS_API.md
  - CONVENCIONES.md
  - BD_Y_TABLAS.md
  - 01-setup.md (reglas de validación de mazos)
  - MOCKS_FRONTEND.md
outputs:
  - front/src/app/pages/decks/deck-builder/deck-builder.component.ts
  - front/src/app/pages/decks/deck-builder/deck-builder.component.html
  - front/src/app/pages/decks/deck-builder/deck-builder.component.scss
  - front/src/app/pages/decks/deck-list/deck-list.component.ts
  - front/src/app/pages/decks/deck-list/deck-list.component.html
  - front/src/app/shared/components/card-item/card-item.component.ts
  - front/src/app/shared/directives/drag-drop.directive.ts
  - front/src/app/shared/services/deck.service.ts
---

# PASO 1B.3 — Deck Builder UI (Drag & Drop + Validación Visual)
**Grupo legacy:** 1B — Frontend Core | **Equipo:** B | **Dificultad:** 🔴 | **Tiempo:** 4–5 h

## Navegación
← **Anterior:** [PASO_S01_03](PASO_S01_03.md) — App shell + navegación  
→ **Siguiente:** [PASO_S02_05](PASO_S02_05.md) — Card Catalog UI

---

## Qué construye este paso

El **Deck Builder** — una interfaz drag & drop para armar mazos de 60 cartas con validación visual en tiempo real:

1. **DeckListComponent:**
   - Lista de todos los mazos del usuario
   - Cards con nombre, descripción, cantidad de cartas, última modificación
   - Botón "Create New Deck"
   - Botón "Edit" en cada mazo → navega a DeckBuilderComponent
   - Botón "Delete" con confirmación

2. **DeckBuilderComponent:**
   - **Panel izquierdo:** Card pool (todas las cartas disponibles)
     - Search bar (por nombre)
     - Filtros: Type (Pokémon, Trainer, Energy), Rarity, Color
     - Grid de cartas arrastrables
   - **Panel derecho:** Deck actual
     - Header con nombre editable
     - Counter: "45 / 60 cards" con barra de progreso
     - Validaciones visuales:
       - ✅ Verde: 60 cartas exactas
       - ⚠️ Amarillo: 50-59 o 61-70 cartas
       - ❌ Rojo: < 50 o > 70 cartas
       - ⚠️ Advertencia si una carta aparece > 4 veces (excepto Energías Básicas)
     - Lista agrupada por tipo:
       - Pokémon (ordenados por evolución)
       - Trainer
       - Energy
     - Botón "Save Deck" (deshabilitado si no válido)
     - Botón "Cancel"

3. **Drag & Drop:**
   - Arrastrar carta de pool → deck (agrega 1 copia)
   - Arrastrar carta de deck → fuera (elimina 1 copia)
   - Click en carta de pool → modal con detalles (imagen grande, stats, texto)
   - Contador de copias en cada carta del deck

4. **DeckService:**
   - `getMyDecks(): Observable<Deck[]>`
   - `getDeckById(id): Observable<Deck>`
   - `createDeck(deck): Observable<Deck>`
   - `updateDeck(id, deck): Observable<Deck>`
   - `deleteDeck(id): Observable<void>`
   - Validación local antes de enviar al backend

5. **Validaciones (según 01-setup.md):**
   - Exactamente 60 cartas
   - Máximo 4 copias de cada carta (excepto Energías Básicas que pueden ser ilimitadas)
   - Al menos 1 Pokémon Básico
   - No mezclar cartas de expansiones incompatibles (futuro)

---

## Prompt listo para el agente

```markdown
Contexto:
Sos el Equipo B del proyecto Codemon TCG. Ya tenés el app shell (PASO_S01_03) funcionando. Ahora necesitás crear el **Deck Builder** — la herramienta más importante del juego.

El backend de mazos (PASO_S02_03) ya tiene los endpoints listos, pero por ahora usarás mocks.

Estructura del módulo:
front/src/app/pages/decks/
├── deck-list/
│   ├── deck-list.component.ts
│   ├── deck-list.component.html
│   └── deck-list.component.scss
├── deck-builder/
│   ├── deck-builder.component.ts
│   ├── deck-builder.component.html
│   └── deck-builder.component.scss
└── decks.routes.ts

front/src/app/shared/
├── components/
│   └── card-item/
│       ├── card-item.component.ts  # Reusable card display
│       └── card-item.component.html
├── directives/
│   └── drag-drop.directive.ts  # Custom drag & drop
└── services/
    └── deck.service.ts

Requisitos técnicos:

1. **DeckListComponent:**
   ```typescript
   export class DeckListComponent implements OnInit {
     decks: Deck[] = [];
     isLoading = true;

     ngOnInit() {
       this.deckService.getMyDecks().subscribe({
         next: (decks) => {
           this.decks = decks;
           this.isLoading = false;
         }
       });
     }

     onCreateDeck() {
       const newDeck: Partial<Deck> = {
         name: 'New Deck',
         description: '',
         cards: []
       };
       
       this.router.navigate(['/launcher/decks/builder'], {
         state: { deck: newDeck }
       });
     }

     onEditDeck(deck: Deck) {
       this.router.navigate(['/launcher/decks/builder', deck.id]);
     }

     onDeleteDeck(deck: Deck) {
       if (confirm(`¿Eliminar "${deck.name}"?`)) {
         this.deckService.deleteDeck(deck.id).subscribe({
           next: () => {
             this.decks = this.decks.filter(d => d.id !== deck.id);
           }
         });
       }
     }
   }
   ```

   HTML:
   ```html
   <div class="deck-list-container">
     <div class="list-header">
       <h2>My Decks</h2>
       <button class="action-primary" (click)="onCreateDeck()">
         <i class="icon-plus"></i>
         Create New Deck
       </button>
     </div>

     <div class="deck-grid" *ngIf="!isLoading">
       <div class="deck-card" *ngFor="let deck of decks">
         <div class="deck-header">
           <h3>{{ deck.name }}</h3>
           <span class="deck-card-count">{{ deck.cards.length }} / 60</span>
         </div>
         
         <p class="deck-description">{{ deck.description || 'No description' }}</p>
         
         <div class="deck-stats">
           <div class="stat">
             <i class="icon-pokemon"></i>
             <span>{{ getDeckPokemonCount(deck) }}</span>
           </div>
           <div class="stat">
             <i class="icon-trainer"></i>
             <span>{{ getDeckTrainerCount(deck) }}</span>
           </div>
           <div class="stat">
             <i class="icon-energy"></i>
             <span>{{ getDeckEnergyCount(deck) }}</span>
           </div>
         </div>

         <div class="deck-actions">
           <button class="action-secondary" (click)="onEditDeck(deck)">Edit</button>
           <button class="action-danger" (click)="onDeleteDeck(deck)">Delete</button>
         </div>

         <div class="deck-meta">
           Last modified: {{ deck.updatedAt | date:'short' }}
         </div>
       </div>
     </div>

     <div class="loading-state" *ngIf="isLoading">
       <div class="spinner"></div>
     </div>
   </div>
   ```

2. **DeckBuilderComponent:**
   ```typescript
   interface DeckCard {
     card: Card;
     quantity: number;
   }

   export class DeckBuilderComponent implements OnInit, OnDestroy {
     // State
     deckId?: number;
     deckName = 'Untitled Deck';
     deckDescription = '';
     deckCards: DeckCard[] = [];  // Cards in the deck
     availableCards: Card[] = [];  // Card pool
     
     // Filters
     searchTerm = '';
     selectedType: CardType | 'ALL' = 'ALL';
     selectedRarity: string | 'ALL' = 'ALL';
     
     // Validation
     get totalCards(): number {
       return this.deckCards.reduce((sum, dc) => sum + dc.quantity, 0);
     }

     get isValid(): boolean {
       if (this.totalCards !== 60) return false;
       if (!this.hasBasicPokemon()) return false;
       if (this.hasDuplicateViolations()) return false;
       return true;
     }

     get validationStatus(): 'valid' | 'warning' | 'error' {
       if (this.totalCards === 60 && !this.hasDuplicateViolations()) return 'valid';
       if (this.totalCards >= 50 && this.totalCards <= 70) return 'warning';
       return 'error';
     }

     get validationMessage(): string {
       if (this.totalCards === 60 && this.isValid) return '✓ Deck válido';
       if (this.totalCards < 60) return `Faltan ${60 - this.totalCards} cartas`;
       if (this.totalCards > 60) return `Sobran ${this.totalCards - 60} cartas`;
       return 'Deck incompleto';
     }

     ngOnInit() {
       // Cargar todas las cartas disponibles
       this.cardService.getAllCards().subscribe({
         next: (cards) => this.availableCards = cards
       });

       // Si es edición, cargar deck existente
       const deckId = this.route.snapshot.params['id'];
       if (deckId) {
         this.loadDeck(deckId);
       }
     }

     private loadDeck(id: number) {
       this.deckService.getDeckById(id).subscribe({
         next: (deck) => {
           this.deckId = deck.id;
           this.deckName = deck.name;
           this.deckDescription = deck.description;
           
           // Agrupar cartas por cantidad
           this.deckCards = this.groupCardsByQuantity(deck.cards);
         }
       });
     }

     private groupCardsByQuantity(cardIds: number[]): DeckCard[] {
       const grouped = new Map<number, number>();
       
       cardIds.forEach(id => {
         grouped.set(id, (grouped.get(id) || 0) + 1);
       });

       return Array.from(grouped.entries()).map(([cardId, quantity]) => ({
         card: this.availableCards.find(c => c.id === cardId)!,
         quantity
       }));
     }

     // Drag & Drop handlers
     onCardDrop(card: Card) {
       const existing = this.deckCards.find(dc => dc.card.id === card.id);
       
       if (existing) {
         // Verificar límite de 4 copias (excepto Energías Básicas)
         if (!this.isBasicEnergy(card) && existing.quantity >= 4) {
           this.showToast('Máximo 4 copias por carta', 'warning');
           return;
         }
         existing.quantity++;
       } else {
         this.deckCards.push({ card, quantity: 1 });
       }
     }

     onCardRemove(deckCard: DeckCard) {
       if (deckCard.quantity > 1) {
         deckCard.quantity--;
       } else {
         this.deckCards = this.deckCards.filter(dc => dc.card.id !== deckCard.card.id);
       }
     }

     // Validation helpers
     private hasBasicPokemon(): boolean {
       return this.deckCards.some(dc => 
         dc.card.type === 'POKEMON' && dc.card.evolutionStage === 'BASIC'
       );
     }

     private hasDuplicateViolations(): boolean {
       return this.deckCards.some(dc => {
         if (this.isBasicEnergy(dc.card)) return false;
         return dc.quantity > 4;
       });
     }

     private isBasicEnergy(card: Card): boolean {
       return card.type === 'ENERGY' && card.subtype === 'BASIC';
     }

     // Save deck
     onSaveDeck() {
       if (!this.isValid) {
         this.showToast('El mazo no es válido', 'error');
         return;
       }

       const deckData = {
         name: this.deckName,
         description: this.deckDescription,
         cards: this.flattenDeckCards()
       };

       if (this.deckId) {
         // Update existing
         this.deckService.updateDeck(this.deckId, deckData).subscribe({
           next: () => {
             this.showToast('Deck actualizado', 'success');
             this.router.navigate(['/launcher/decks']);
           }
         });
       } else {
         // Create new
         this.deckService.createDeck(deckData).subscribe({
           next: () => {
             this.showToast('Deck creado', 'success');
             this.router.navigate(['/launcher/decks']);
           }
         });
       }
     }

     private flattenDeckCards(): number[] {
       const result: number[] = [];
       this.deckCards.forEach(dc => {
         for (let i = 0; i < dc.quantity; i++) {
           result.push(dc.card.id);
         }
       });
       return result;
     }

     onCancel() {
       if (confirm('¿Descartar cambios?')) {
         this.router.navigate(['/launcher/decks']);
       }
     }

     // Filters
     get filteredCards(): Card[] {
       return this.availableCards.filter(card => {
         // Search term
         if (this.searchTerm && !card.name.toLowerCase().includes(this.searchTerm.toLowerCase())) {
           return false;
         }
         
         // Type filter
         if (this.selectedType !== 'ALL' && card.type !== this.selectedType) {
           return false;
         }
         
         // Rarity filter
         if (this.selectedRarity !== 'ALL' && card.rarity !== this.selectedRarity) {
           return false;
         }
         
         return true;
       });
     }

     // Grouping for display
     get pokemonCards(): DeckCard[] {
       return this.deckCards.filter(dc => dc.card.type === 'POKEMON');
     }

     get trainerCards(): DeckCard[] {
       return this.deckCards.filter(dc => dc.card.type === 'TRAINER');
     }

     get energyCards(): DeckCard[] {
       return this.deckCards.filter(dc => dc.card.type === 'ENERGY');
     }
   }
   ```

   HTML template (simplificado):
   ```html
   <div class="deck-builder">
     <!-- Left panel: Card pool -->
     <div class="card-pool-panel">
       <div class="panel-header">
         <input
           type="text"
           placeholder="Search cards..."
           [(ngModel)]="searchTerm"
           class="search-input"
         />
         
         <div class="filters">
           <select [(ngModel)]="selectedType">
             <option value="ALL">All Types</option>
             <option value="POKEMON">Pokémon</option>
             <option value="TRAINER">Trainer</option>
             <option value="ENERGY">Energy</option>
           </select>
           
           <select [(ngModel)]="selectedRarity">
             <option value="ALL">All Rarities</option>
             <option value="COMMON">Common</option>
             <option value="UNCOMMON">Uncommon</option>
             <option value="RARE">Rare</option>
             <option value="HOLO_RARE">Holo Rare</option>
           </select>
         </div>
       </div>

       <div class="card-grid">
         <app-card-item
           *ngFor="let card of filteredCards"
           [card]="card"
           [draggable]="true"
           (cardDrop)="onCardDrop(card)"
         ></app-card-item>
       </div>
     </div>

     <!-- Right panel: Deck -->
     <div class="deck-panel">
       <div class="deck-header">
         <input
           type="text"
           [(ngModel)]="deckName"
           class="deck-name-input"
           placeholder="Deck name..."
         />
         
         <div class="deck-counter" [ngClass]="validationStatus">
           <span class="count">{{ totalCards }} / 60</span>
           <div class="progress-track">
             <div class="progress-fill" [style.width.%]="(totalCards / 60) * 100"></div>
           </div>
           <span class="validation-msg">{{ validationMessage }}</span>
         </div>
       </div>

       <textarea
         [(ngModel)]="deckDescription"
         placeholder="Description..."
         class="deck-description"
       ></textarea>

       <!-- Pokémon section -->
       <div class="deck-section" *ngIf="pokemonCards.length > 0">
         <h3>Pokémon ({{ pokemonCards.length }})</h3>
         <div class="deck-card-list">
           <div
             *ngFor="let deckCard of pokemonCards"
             class="deck-card-row"
             (click)="onCardRemove(deckCard)"
           >
             <span class="card-name">{{ deckCard.card.name }}</span>
             <span class="card-quantity">{{ deckCard.quantity }}x</span>
           </div>
         </div>
       </div>

       <!-- Trainer section -->
       <div class="deck-section" *ngIf="trainerCards.length > 0">
         <h3>Trainer ({{ trainerCards.length }})</h3>
         <div class="deck-card-list">
           <div
             *ngFor="let deckCard of trainerCards"
             class="deck-card-row"
             (click)="onCardRemove(deckCard)"
           >
             <span class="card-name">{{ deckCard.card.name }}</span>
             <span class="card-quantity">{{ deckCard.quantity }}x</span>
           </div>
         </div>
       </div>

       <!-- Energy section -->
       <div class="deck-section" *ngIf="energyCards.length > 0">
         <h3>Energy ({{ energyCards.length }})</h3>
         <div class="deck-card-list">
           <div
             *ngFor="let deckCard of energyCards"
             class="deck-card-row"
             (click)="onCardRemove(deckCard)"
           >
             <span class="card-name">{{ deckCard.card.name }}</span>
             <span class="card-quantity">{{ deckCard.quantity }}x</span>
           </div>
         </div>
       </div>

       <!-- Actions -->
       <div class="deck-actions">
         <button
           class="action-primary"
           [disabled]="!isValid"
           (click)="onSaveDeck()"
         >
           Save Deck
         </button>
         <button class="action-secondary" (click)="onCancel()">
           Cancel
         </button>
       </div>
     </div>
   </div>
   ```

3. **CardItemComponent (reusable):**
   ```typescript
   @Component({
     selector: 'app-card-item',
     standalone: true,
     template: `
       <div
         class="card-item"
         [draggable]="draggable"
         (dragstart)="onDragStart($event)"
         (click)="onClick()"
       >
         <img [src]="card.imageUrl" [alt]="card.name" />
         <div class="card-info">
           <h4>{{ card.name }}</h4>
           <span class="card-type">{{ card.type }}</span>
         </div>
       </div>
     `
   })
   export class CardItemComponent {
     @Input() card!: Card;
     @Input() draggable = false;
     @Output() cardDrop = new EventEmitter<Card>();
     @Output() cardClick = new EventEmitter<Card>();

     onDragStart(event: DragEvent) {
       event.dataTransfer!.effectAllowed = 'copy';
       event.dataTransfer!.setData('cardId', this.card.id.toString());
     }

     onClick() {
       this.cardClick.emit(this.card);
     }
   }
   ```

4. **DeckService:**
   ```typescript
   @Injectable({ providedIn: 'root' })
   export class DeckService {
     private readonly API_URL = `${environment.apiUrl}/decks`;

     constructor(private http: HttpClient) {}

     getMyDecks(): Observable<Deck[]> {
       return this.http.get<Deck[]>(`${this.API_URL}/my`);
     }

     getDeckById(id: number): Observable<Deck> {
       return this.http.get<Deck>(`${this.API_URL}/${id}`);
     }

     createDeck(deck: Partial<Deck>): Observable<Deck> {
       return this.http.post<Deck>(this.API_URL, deck);
     }

     updateDeck(id: number, deck: Partial<Deck>): Observable<Deck> {
       return this.http.put<Deck>(`${this.API_URL}/${id}`, deck);
     }

     deleteDeck(id: number): Observable<void> {
       return this.http.delete<void>(`${this.API_URL}/${id}`);
     }

     validateDeck(cards: number[]): Observable<ValidationResult> {
       return this.http.post<ValidationResult>(`${this.API_URL}/validate`, { cards });
     }
   }
   ```

5. **Drag & Drop con HTML5 API:**
   ```typescript
   // En DeckBuilderComponent
   @HostListener('drop', ['$event'])
   onDrop(event: DragEvent) {
     event.preventDefault();
     const cardId = event.dataTransfer!.getData('cardId');
     const card = this.availableCards.find(c => c.id === parseInt(cardId));
     
     if (card) {
       this.onCardDrop(card);
     }
   }

   @HostListener('dragover', ['$event'])
   onDragOver(event: DragEvent) {
     event.preventDefault();
     event.dataTransfer!.dropEffect = 'copy';
   }
   ```

Entregables:
- [ ] DeckListComponent con grid de mazos
- [ ] DeckBuilderComponent con drag & drop funcional
- [ ] Validación visual en tiempo real
- [ ] Filtros de búsqueda
- [ ] DeckService con CRUD completo
- [ ] CardItemComponent reusable
- [ ] Mocks para desarrollo
```

---

## Contexto adicional

### Validación optimista vs pesimista

**Optimista (recomendado):**
```typescript
// Validar en el cliente primero
if (this.isValid) {
  this.deckService.createDeck(deckData).subscribe(...);
} else {
  this.showToast('Deck inválido', 'error');
}
```

**Pesimista:**
```typescript
// Validar en el servidor siempre
this.deckService.createDeck(deckData).subscribe({
  error: (err) => {
    if (err.status === 400) {
      this.showValidationErrors(err.error.violations);
    }
  }
});
```

### Integración con PASO_S02_03 (Backend Deck CRUD)

El backend ya tiene validación de mazos en `DeckValidator.java`. Cuando integres, asegurate de que los mensajes de error del backend coincidan con los del frontend.

---

## Tests sugeridos

```typescript
describe('DeckBuilderComponent', () => {
  it('should add card to deck on drop', () => {
    const card = mockCard({ id: 1, name: 'Pikachu' });
    component.onCardDrop(card);
    expect(component.deckCards.length).toBe(1);
    expect(component.deckCards[0].quantity).toBe(1);
  });

  it('should increment quantity if card already in deck', () => {
    const card = mockCard({ id: 1, name: 'Pikachu' });
    component.onCardDrop(card);
    component.onCardDrop(card);
    expect(component.deckCards.length).toBe(1);
    expect(component.deckCards[0].quantity).toBe(2);
  });

  it('should not allow more than 4 copies of non-basic energy', () => {
    const card = mockCard({ id: 1, type: 'POKEMON' });
    for (let i = 0; i < 5; i++) {
      component.onCardDrop(card);
    }
    expect(component.deckCards[0].quantity).toBe(4);
  });

  it('should validate deck correctly', () => {
    // Add 60 cards with at least 1 basic Pokémon
    for (let i = 0; i < 60; i++) {
      component.onCardDrop(mockCard({ id: 1, evolutionStage: 'BASIC' }));
    }
    expect(component.isValid).toBe(true);
  });
});
```

---

## Errores comunes

### 1. **Drag & drop no funciona**
**Síntoma:** Cartas no se mueven  
**Causa:** Falta `dragover` event con `preventDefault`  
**Solución:**
```typescript
@HostListener('dragover', ['$event'])
onDragOver(event: DragEvent) {
  event.preventDefault(); // ← CRÍTICO
  event.dataTransfer!.dropEffect = 'copy';
}
```

### 2. **Conteo de cartas incorrecto**
**Síntoma:** totalCards no coincide con la suma real  
**Causa:** No se está reduciendo correctamente  
**Solución:**
```typescript
get totalCards(): number {
  return this.deckCards.reduce((sum, dc) => sum + dc.quantity, 0);
}
```

### 3. **Validación de energías básicas falla**
**Síntoma:** Energías básicas se limitan a 4 copias  
**Causa:** `isBasicEnergy` no detecta correctamente  
**Solución:**
```typescript
private isBasicEnergy(card: Card): boolean {
  return card.type === 'ENERGY' && card.subtype === 'BASIC';
  // O verificar por nombre: card.name.includes('Energy')
}
```

---

## Verificación manual

- [ ] Arrastrar carta de pool → deck agrega 1 copia
- [ ] Click en carta de deck → elimina 1 copia
- [ ] Contador "45 / 60" se actualiza en tiempo real
- [ ] Barra de progreso cambia color (verde/amarillo/rojo)
- [ ] Filtros de búsqueda funcionan
- [ ] Save button deshabilitado si deck inválido
- [ ] Delete deck muestra confirmación

---

## Criterios de aceptación

### ✅ Obligatorios
1. Drag & drop funcional
2. Validación en tiempo real
3. Filtros de búsqueda
4. CRUD completo de mazos

### 🎯 Opcionales
- Undo/Redo para cambios
- Export deck to text
- Import deck from text

---

## Notas finales

Handoff para PASO_S02_05: El Card Catalog usará el mismo `CardItemComponent` que creaste acá.
