---
id: PASO_S06_01
equipo: B
bloque: 6
dep: [PASO_S02_05, PASO_S07_01, PASO_S07_02]
siguiente: PASO_S07_01
context_files:
  - CONTRATOS_API.md
  - PROTOCOLO_WEBSOCKET.md
  - Codemon_Game_Lobby.html (diseño de referencia)
  - MOCKS_FRONTEND.md
outputs:
  - front/src/app/pages/play/play.component.ts
  - front/src/app/pages/play/components/pve-mode/pve-mode.component.ts
  - front/src/app/pages/play/components/ranked-mode/ranked-mode.component.ts
  - front/src/app/pages/play/components/private-room/private-room.component.ts
  - front/src/app/shared/services/matchmaking.service.ts
---

# PASO 3B.1 — Lobby UI (PVE + Ranked PVP + Private Room)
**Grupo legacy:** 3B — Frontend Features | **Equipo:** B | **Dificultad:** 🔴 | **Tiempo:** 3–4 h

## Navegación
← **Anterior:** [PASO_S02_05](PASO_S02_05.md) — Card Catalog UI  
→ **Siguiente:** [PASO_S08_06](PASO_S08_06.md) — Shop UI

---

> ⚠️ **Alcance por sprint:** Este paso se ejecuta en dos sprints.
> - **Sprint 6:** Construir el Lobby UI completo con mocks del MatchmakingService.
> - **Sprint 7:** Tras completar PASO_S07_01 y PASO_S07_02, reemplazar los mocks con llamadas reales a la API de matchmaking y WebSocket.

## Qué construye este paso

El **lobby de juego** con 3 modos diferentes siguiendo el diseño de `Codemon_Game_Lobby.html`:

1. **PlayComponent (container):**
   - 3 mode cards flotantes: PVE, Ranked PVP, Private Room
   - Animaciones de hover y selección
   - Background con partículas animadas

2. **PvEModeComponent:**
   - Selector de dificultad: Easy / Medium / Hard
   - Selector de mazo (dropdown)
   - Botón "Play vs AI"
   - Redirección a `/game/:gameId` cuando la partida está lista

3. **RankedModeComponent:**
   - Selector de mazo
   - Stats del usuario: Current Rank, W/L Record, Points
   - Botón "Find Match" → entra en cola de matchmaking
   - Queue overlay con:
     - Spinner animado
     - Queue position: "You are #3 in queue"
     - Estimated wait time
     - Botón "Cancel"
   - Match Found overlay con:
     - VS screen (tu avatar vs oponente)
     - Countdown 3...2...1...
     - Redirección a `/game/:gameId`

4. **PrivateRoomComponent:**
   - Dos modos:
     - **Create Room:** Generar código de 6 dígitos → compartir
     - **Join Room:** Ingresar código → conectar
   - Selector de mazo
   - Botón "Create Private Room" / "Join Room"
   - Waiting overlay si sos host (esperando oponente)

5. **MatchmakingService:**
   - `findMatch(deckId): Observable<MatchmakingResponse>`
   - `cancelSearch(): Observable<void>`
   - `createPrivateRoom(deckId): Observable<RoomCode>`
   - `joinPrivateRoom(code, deckId): Observable<GameSession>`
   - WebSocket para escuchar eventos: `match_found`, `queue_position_update`

---

## Prompt listo para el agente

```markdown
Contexto:
Sos el Equipo B del proyecto Codemon TCG. Ya tenés el catálogo de cartas y el deck builder (PASO_S02_04 y PASO_S02_05). Ahora necesitás el **lobby de juego** donde los usuarios eligen cómo quieren jugar.

El backend de matchmaking (PASO_S07_01 y PASO_S07_02) está listo, pero usarás mocks por ahora.

Diseño de referencia: Codemon_Game_Lobby.html

Estructura:
front/src/app/pages/play/
├── play.component.ts (container)
├── components/
│   ├── pve-mode/
│   │   └── pve-mode.component.ts
│   ├── ranked-mode/
│   │   └── ranked-mode.component.ts
│   └── private-room/
│       └── private-room.component.ts

Requisitos técnicos:

1. **PlayComponent (mode selector):**
   ```typescript
   export class PlayComponent {
     selectedMode: 'pve' | 'ranked' | 'private' | null = null;

     modes = [
       {
         id: 'pve',
         title: 'Play vs AI',
         description: 'Practice against computer opponents',
         icon: 'robot'
       },
       {
         id: 'ranked',
         title: 'Ranked PVP',
         description: 'Compete in ranked matchmaking',
         icon: 'trophy'
       },
       {
         id: 'private',
         title: 'Private Room',
         description: 'Play with friends using room codes',
         icon: 'users'
       }
     ];

     onModeSelect(mode: string) {
       this.selectedMode = mode as any;
     }

     onBack() {
       this.selectedMode = null;
     }
   }
   ```

   Template:
   ```html
   <!-- Mode selector -->
   <div class="mode-selector" *ngIf="!selectedMode">
     <h1 class="title">Choose Game Mode</h1>
     
     <div class="mode-grid">
       <div
         *ngFor="let mode of modes"
         class="mode-card"
         (click)="onModeSelect(mode.id)"
       >
         <div class="mode-icon">
           <i [class]="'icon-' + mode.icon"></i>
         </div>
         <h3>{{ mode.title }}</h3>
         <p>{{ mode.description }}</p>
       </div>
     </div>
   </div>

   <!-- Mode views -->
   <app-pve-mode
     *ngIf="selectedMode === 'pve'"
     (back)="onBack()"
   ></app-pve-mode>

   <app-ranked-mode
     *ngIf="selectedMode === 'ranked'"
     (back)="onBack()"
   ></app-ranked-mode>

   <app-private-room
     *ngIf="selectedMode === 'private'"
     (back)="onBack()"
   ></app-private-room>
   ```

2. **PvEModeComponent:**
   ```typescript
   export class PvEModeComponent {
     @Output() back = new EventEmitter<void>();

     difficulty: 'easy' | 'medium' | 'hard' = 'medium';
     selectedDeckId?: number;
     myDecks: Deck[] = [];
     isLoading = false;

     ngOnInit() {
       this.deckService.getMyDecks().subscribe({
         next: (decks) => {
           this.myDecks = decks.filter(d => d.cards.length === 60);
           if (this.myDecks.length > 0) {
             this.selectedDeckId = this.myDecks[0].id;
           }
         }
       });
     }

     onPlay() {
       if (!this.selectedDeckId) {
         alert('Select a deck first');
         return;
       }

       this.isLoading = true;
       
       this.matchmakingService.startPvEGame(this.selectedDeckId, this.difficulty).subscribe({
         next: (response) => {
           this.router.navigate(['/game', response.gameId]);
         },
         error: (err) => {
           this.isLoading = false;
           alert('Error starting game: ' + err.message);
         }
       });
     }

     onBack() {
       this.back.emit();
     }
   }
   ```

3. **RankedModeComponent:**
   ```typescript
   export class RankedModeComponent implements OnDestroy {
     @Output() back = new EventEmitter<void>();

     selectedDeckId?: number;
     myDecks: Deck[] = [];
     
     // Queue state
     isSearching = false;
     queuePosition = 0;
     estimatedWaitTime = 0;
     
     // Match found state
     matchFound = false;
     opponent?: User;
     countdown = 3;
     
     // User stats
     currentRank = 'Bronze III';
     wins = 12;
     losses = 8;
     points = 1250;

     private wsSubscription?: Subscription;

     ngOnInit() {
       this.loadDecks();
       this.subscribeToMatchmakingEvents();
     }

     ngOnDestroy() {
       this.wsSubscription?.unsubscribe();
     }

     private subscribeToMatchmakingEvents() {
       this.wsSubscription = this.matchmakingService.matchmakingEvents$.subscribe({
         next: (event) => {
           if (event.type === 'queue_position_update') {
             this.queuePosition = event.data.position;
             this.estimatedWaitTime = event.data.estimatedWaitTime;
           } else if (event.type === 'match_found') {
             this.onMatchFound(event.data);
           }
         }
       });
     }

     onFindMatch() {
       if (!this.selectedDeckId) {
         alert('Select a deck first');
         return;
       }

       this.isSearching = true;
       
       this.matchmakingService.findMatch(this.selectedDeckId).subscribe({
         error: (err) => {
           this.isSearching = false;
           alert('Error finding match: ' + err.message);
         }
       });
     }

     onCancelSearch() {
       this.matchmakingService.cancelSearch().subscribe({
         next: () => {
           this.isSearching = false;
         }
       });
     }

     private onMatchFound(data: MatchFoundData) {
       this.matchFound = true;
       this.opponent = data.opponent;
       this.startCountdown(data.gameId);
     }

     private startCountdown(gameId: string) {
       const interval = setInterval(() => {
         this.countdown--;
         
         if (this.countdown === 0) {
           clearInterval(interval);
           this.router.navigate(['/game', gameId]);
         }
       }, 1000);
     }

     onBack() {
       if (this.isSearching) {
         this.onCancelSearch();
       }
       this.back.emit();
     }
   }
   ```

   Template con overlays:
   ```html
   <div class="ranked-mode">
     <!-- Header con stats -->
     <div class="mode-header">
       <button class="btn-back" (click)="onBack()">← Back</button>
       <h2>Ranked PVP</h2>
     </div>

     <div class="stats-panel">
       <div class="stat-card">
         <label>Current Rank</label>
         <span class="rank">{{ currentRank }}</span>
       </div>
       <div class="stat-card">
         <label>W/L Record</label>
         <span>{{ wins }}W - {{ losses }}L</span>
       </div>
       <div class="stat-card">
         <label>Points</label>
         <span>{{ points }}</span>
       </div>
     </div>

     <!-- Deck selector -->
     <div class="deck-selector">
       <label>Select Deck</label>
       <select [(ngModel)]="selectedDeckId">
         <option *ngFor="let deck of myDecks" [value]="deck.id">
           {{ deck.name }}
         </option>
       </select>
     </div>

     <!-- Find match button -->
     <button
       class="action-primary"
       [disabled]="!selectedDeckId || isSearching"
       (click)="onFindMatch()"
     >
       {{ isSearching ? 'Searching...' : 'Find Match' }}
     </button>

     <!-- Queue overlay -->
     <div class="queue-overlay" *ngIf="isSearching && !matchFound">
       <div class="queue-content">
         <div class="spinner"></div>
         <h3>Searching for opponent...</h3>
         
         <div class="queue-stats">
           <div class="queue-stat">
             <label>Position in Queue</label>
             <span>#{{ queuePosition }}</span>
           </div>
           <div class="queue-stat">
             <label>Estimated Wait</label>
             <span>{{ estimatedWaitTime }}s</span>
           </div>
         </div>

         <button class="action-secondary" (click)="onCancelSearch()">
           Cancel
         </button>
       </div>
     </div>

     <!-- Match found overlay -->
     <div class="match-found-overlay" *ngIf="matchFound">
       <div class="match-vs">
         <div class="match-player">
           <div class="match-avatar">{{ currentUser?.username?.charAt(0) }}</div>
           <div class="match-name">{{ currentUser?.username }}</div>
           <div class="match-rank">{{ currentRank }}</div>
         </div>

         <div class="vs-badge">VS</div>

         <div class="match-player">
           <div class="match-avatar">{{ opponent?.username?.charAt(0) }}</div>
           <div class="match-name">{{ opponent?.username }}</div>
           <div class="match-rank">{{ opponent?.rank }}</div>
         </div>
       </div>

       <h2 class="match-title">Match Found!</h2>
       <p class="match-sub">Starting in...</p>
       <div class="match-countdown">{{ countdown }}</div>
     </div>
   </div>
   ```

4. **PrivateRoomComponent:**
   ```typescript
   export class PrivateRoomComponent {
     @Output() back = new EventEmitter<void>();

     mode: 'create' | 'join' = 'create';
     selectedDeckId?: number;
     myDecks: Deck[] = [];
     
     // Create mode
     roomCode?: string;
     isWaitingForOpponent = false;
     
     // Join mode
     inputCode = '';
     isJoining = false;

     ngOnInit() {
       this.loadDecks();
     }

     onCreateRoom() {
       if (!this.selectedDeckId) {
         alert('Select a deck first');
         return;
       }

       this.matchmakingService.createPrivateRoom(this.selectedDeckId).subscribe({
         next: (response) => {
           this.roomCode = response.code;
           this.isWaitingForOpponent = true;
           this.listenForOpponentJoin();
         }
       });
     }

     private listenForOpponentJoin() {
       this.matchmakingService.privateRoomEvents$.subscribe({
         next: (event) => {
           if (event.type === 'opponent_joined') {
             this.router.navigate(['/game', event.data.gameId]);
           }
         }
       });
     }

     onJoinRoom() {
       if (!this.selectedDeckId || !this.inputCode) {
         alert('Enter room code and select a deck');
         return;
       }

       this.isJoining = true;
       
       this.matchmakingService.joinPrivateRoom(this.inputCode, this.selectedDeckId).subscribe({
         next: (response) => {
           this.router.navigate(['/game', response.gameId]);
         },
         error: (err) => {
           this.isJoining = false;
           alert('Invalid room code or room is full');
         }
       });
     }

     onCopyRoomCode() {
       navigator.clipboard.writeText(this.roomCode!);
       // Mostrar toast "Code copied!"
     }

     onBack() {
       this.back.emit();
     }
   }
   ```

5. **MatchmakingService:**
   ```typescript
   @Injectable({ providedIn: 'root' })
   export class MatchmakingService {
     private readonly API_URL = `${environment.apiUrl}/matchmaking`;
     private readonly WS_URL = environment.wsUrl;
     
     private wsClient?: StompClient;
     private matchmakingSubject = new Subject<MatchmakingEvent>();
     public matchmakingEvents$ = this.matchmakingSubject.asObservable();

     constructor(
       private http: HttpClient,
       private wsService: WebSocketService
     ) {
       this.connectWebSocket();
     }

     private connectWebSocket() {
       this.wsClient = this.wsService.connect();
       
       this.wsClient.subscribe('/user/queue/matchmaking', (message) => {
         const event = JSON.parse(message.body);
         this.matchmakingSubject.next(event);
       });
     }

     startPvEGame(deckId: number, difficulty: string): Observable<GameStartResponse> {
       return this.http.post<GameStartResponse>(`${this.API_URL}/pve`, {
         deckId,
         difficulty
       });
     }

     findMatch(deckId: number): Observable<void> {
       return this.http.post<void>(`${this.API_URL}/ranked/queue`, { deckId });
     }

     cancelSearch(): Observable<void> {
       return this.http.delete<void>(`${this.API_URL}/ranked/queue`);
     }

     createPrivateRoom(deckId: number): Observable<RoomCodeResponse> {
       return this.http.post<RoomCodeResponse>(`${this.API_URL}/private/create`, {
         deckId
       });
     }

     joinPrivateRoom(code: string, deckId: number): Observable<GameStartResponse> {
       return this.http.post<GameStartResponse>(`${this.API_URL}/private/join`, {
         code,
         deckId
       });
     }
   }
   ```

Entregables:
- [ ] PlayComponent con 3 mode cards
- [ ] PvEModeComponent funcional
- [ ] RankedModeComponent con queue overlay
- [ ] PrivateRoomComponent con create/join
- [ ] MatchmakingService con WebSocket
- [ ] Match found overlay con countdown
- [ ] Animaciones suaves
```

---

## Tests sugeridos

```typescript
describe('RankedModeComponent', () => {
  it('should enter queue on find match', () => {
    spyOn(matchmakingService, 'findMatch').and.returnValue(of());
    component.selectedDeckId = 1;
    component.onFindMatch();
    expect(component.isSearching).toBe(true);
  });

  it('should cancel search', () => {
    spyOn(matchmakingService, 'cancelSearch').and.returnValue(of());
    component.isSearching = true;
    component.onCancelSearch();
    expect(component.isSearching).toBe(false);
  });

  it('should navigate to game on match found', fakeAsync(() => {
    spyOn(router, 'navigate');
    component.onMatchFound({ gameId: 'game123', opponent: mockUser() });
    tick(3000);
    expect(router.navigate).toHaveBeenCalledWith(['/game', 'game123']);
  }));
});
```

---

## Errores comunes

### 1. **Countdown no se detiene al destruir componente**
**Síntoma:** `setInterval` sigue corriendo  
**Causa:** No se limpia en `ngOnDestroy`  
**Solución:**
```typescript
private countdownInterval?: number;

ngOnDestroy() {
  if (this.countdownInterval) {
    clearInterval(this.countdownInterval);
  }
}
```

### 2. **WebSocket no recibe eventos**
**Síntoma:** Queue position no se actualiza  
**Causa:** Suscripción incorrecta o token inválido  
**Solución:**
```typescript
// Verificar que el token esté en headers
const token = localStorage.getItem('access_token');
this.wsClient = Stomp.over(() => new SockJS(this.WS_URL, null, {
  headers: { Authorization: `Bearer ${token}` }
}));
```

---

## Verificación manual

- [ ] 3 mode cards se muestran correctamente
- [ ] Click en mode card → muestra vista del modo
- [ ] Back button → vuelve a mode selector
- [ ] PvE: seleccionar dificultad y mazo → Play → navega a /game
- [ ] Ranked: Find Match → muestra queue overlay
- [ ] Queue overlay: Cancel → vuelve a ranked view
- [ ] Match Found overlay: countdown 3→2→1 → navega a /game
- [ ] Private Room: Create → genera código de 6 dígitos
- [ ] Private Room: Join → valida código

---

## Criterios de aceptación

### ✅ Obligatorios
1. 3 modos funcionales
2. Queue overlay con cancel
3. Match found overlay con countdown
4. WebSocket conectado
5. Redirección a /game correcta

### 🎯 Opcionales
- Sound effects (match found, countdown beep)
- Particle effects en match found
- Animation al seleccionar mode
