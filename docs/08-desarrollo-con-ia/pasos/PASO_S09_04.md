---
id: PASO_S09_04
equipo: B
bloque: 9
dep: [PASO_S08_06, PASO_S09_03]
siguiente: PASO_S09_05
context_files:
  - CONTRATOS_API.md
  - MOCKS_FRONTEND.md
outputs:
  - front/src/app/pages/leaderboard/leaderboard.component.ts
  - front/src/app/pages/news/news.component.ts
  - front/src/app/shared/services/leaderboard.service.ts
---

# PASO 3B.3 — Leaderboard + News UI
**Grupo legacy:** 3B — Frontend Features | **Equipo:** B | **Dificultad:** 🟢 | **Tiempo:** 2 h

## Navegación
← **Anterior:** [PASO_S08_06](PASO_S08_06.md) — Shop UI  
→ **Siguiente:** [PASO_S09_05](PASO_S09_05.md) — Profile + Friends UI

---

## Qué construye este paso

1. **LeaderboardComponent:**
   - Tabla de top 100 jugadores
   - Columnas: Rank, Username, Points, W/L, Tier
   - Highlight del usuario actual
   - Filtros: Global / Friends Only
   - Paginación (20 por página)

2. **NewsComponent:**
   - Feed de noticias/anuncios
   - Cards con: título, imagen, fecha, preview
   - Click → modal con contenido completo
   - Ordenado por fecha (más reciente primero)

---

## Prompt listo para el agente

```markdown
Requisitos:

1. **LeaderboardComponent:**
   ```typescript
   export class LeaderboardComponent implements OnInit {
     leaderboard: LeaderboardEntry[] = [];
     currentPage = 1;
     pageSize = 20;
     filter: 'global' | 'friends' = 'global';
     currentUserId?: number;

     ngOnInit() {
       this.loadLeaderboard();
       this.authService.currentUser$.subscribe({
         next: (user) => this.currentUserId = user?.id
       });
     }

     loadLeaderboard() {
       this.leaderboardService.getLeaderboard(this.filter, this.currentPage).subscribe({
         next: (data) => this.leaderboard = data
       });
     }

     isCurrentUser(entry: LeaderboardEntry): boolean {
       return entry.userId === this.currentUserId;
     }
   }
   ```

   Template:
   ```html
   <div class="leaderboard-header">
     <h2>Leaderboard</h2>
     <div class="filter-tabs">
       <button
         [class.active]="filter === 'global'"
         (click)="filter = 'global'; loadLeaderboard()"
       >
         Global
       </button>
       <button
         [class.active]="filter === 'friends'"
         (click)="filter = 'friends'; loadLeaderboard()"
       >
         Friends
       </button>
     </div>
   </div>

   <table class="leaderboard-table">
     <thead>
       <tr>
         <th>Rank</th>
         <th>Player</th>
         <th>Points</th>
         <th>W/L</th>
         <th>Tier</th>
       </tr>
     </thead>
     <tbody>
       <tr
         *ngFor="let entry of leaderboard"
         [class.current-user]="isCurrentUser(entry)"
       >
         <td class="rank">{{ entry.rank }}</td>
         <td class="player">{{ entry.username }}</td>
         <td class="points">{{ entry.points }}</td>
         <td class="wl">{{ entry.wins }}W - {{ entry.losses }}L</td>
         <td class="tier">{{ entry.tier }}</td>
       </tr>
     </tbody>
   </table>
   ```

2. **NewsComponent:**
   ```typescript
   export class NewsComponent implements OnInit {
     news: NewsArticle[] = [];
     selectedArticle?: NewsArticle;

     ngOnInit() {
       this.newsService.getNews().subscribe({
         next: (articles) => this.news = articles
       });
     }

     onArticleClick(article: NewsArticle) {
       this.selectedArticle = article;
     }
   }
   ```

Entregables:
- [ ] LeaderboardComponent con tabla
- [ ] Global / Friends filter
- [ ] NewsComponent con feed
- [ ] Modal de artículo completo
```

---

## Criterios de aceptación

✅ Tabla de leaderboard ordenada  
✅ Usuario actual destacado  
✅ Feed de noticias funcional  
✅ Modal de artículo completo
