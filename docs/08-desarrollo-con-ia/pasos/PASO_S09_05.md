---
id: PASO_S09_05
equipo: B
bloque: 9
dep: [PASO_S09_04, PASO_S09_02]
siguiente: PASO_S10_01
context_files:
  - CONTRATOS_API.md
  - MOCKS_FRONTEND.md
outputs:
  - front/src/app/pages/profile/profile.component.ts
  - front/src/app/pages/friends/friends.component.ts
  - front/src/app/shared/services/friends.service.ts
---

# PASO 3B.4 — Profile + Friends UI
**Grupo legacy:** 3B — Frontend Features | **Equipo:** B | **Dificultad:** 🟡 | **Tiempo:** 2–3 h

## Navegación
← **Anterior:** [PASO_S09_04](PASO_S09_04.md) — Leaderboard + News UI  
→ **Siguiente:** [PASO_S10_02](PASO_S10_02.md) — OAuth2 Integration

---

> ⚠️ **Alcance por sprint:** Este paso se ejecuta en dos sprints.
> - **Sprint 9:** Implementar FriendsComponent (lista, requests, search, unfriend) y FriendsService.
> - **Sprint 10:** Implementar ProfileComponent (avatar, stats, edición de email, change password).

## Qué construye este paso

1. **ProfileComponent:**
   - Avatar editable (upload imagen)
   - Username (read-only)
   - Email (editable)
   - Estadísticas: Total Games, W/L, Current Rank
   - Botón "Change Password"
   - Botón "Delete Account"

2. **FriendsComponent:**
   - Lista de amigos
   - Search bar para agregar amigos (por username)
   - Friend requests pendientes
   - Botón "Unfriend"
   - Online status indicator

---

## Prompt listo para el agente

```markdown
Requisitos:

1. **ProfileComponent:**
   ```typescript
   export class ProfileComponent implements OnInit {
     user?: User;
     stats?: UserStats;
     isEditingEmail = false;
     newEmail = '';

     ngOnInit() {
       this.authService.currentUser$.subscribe({
         next: (user) => this.user = user
       });
       
       this.profileService.getMyStats().subscribe({
         next: (stats) => this.stats = stats
       });
     }

     onChangeAvatar(file: File) {
       this.profileService.uploadAvatar(file).subscribe({
         next: (url) => {
           // Actualizar avatar en UI
         }
       });
     }

     onSaveEmail() {
       this.profileService.updateEmail(this.newEmail).subscribe({
         next: () => {
           this.isEditingEmail = false;
         }
       });
     }

     onChangePassword() {
       // Abrir modal de cambio de contraseña
     }

     onDeleteAccount() {
       if (confirm('¿Estás seguro? Esta acción es irreversible.')) {
         this.profileService.deleteAccount().subscribe({
           next: () => {
             this.authService.logout();
           }
         });
       }
     }
   }
   ```

2. **FriendsComponent:**
   ```typescript
   export class FriendsComponent implements OnInit {
     friends: Friend[] = [];
     friendRequests: FriendRequest[] = [];
     searchTerm = '';
     searchResults: User[] = [];

     ngOnInit() {
       this.loadFriends();
       this.loadFriendRequests();
     }

     loadFriends() {
       this.friendsService.getMyFriends().subscribe({
         next: (friends) => this.friends = friends
       });
     }

     onSearch() {
       if (this.searchTerm.length < 3) return;
       
       this.friendsService.searchUsers(this.searchTerm).subscribe({
         next: (results) => this.searchResults = results
       });
     }

     onSendFriendRequest(user: User) {
       this.friendsService.sendFriendRequest(user.id).subscribe({
         next: () => {
           alert('Friend request sent!');
         }
       });
     }

     onAcceptRequest(request: FriendRequest) {
       this.friendsService.acceptFriendRequest(request.id).subscribe({
         next: () => {
           this.loadFriends();
           this.loadFriendRequests();
         }
       });
     }

     onUnfriend(friend: Friend) {
       if (confirm(`Remove ${friend.username} from friends?`)) {
         this.friendsService.removeFriend(friend.id).subscribe({
           next: () => {
             this.friends = this.friends.filter(f => f.id !== friend.id);
           }
         });
       }
     }
   }
   ```

Entregables:
- [ ] ProfileComponent con edición
- [ ] Avatar upload funcional
- [ ] FriendsComponent con lista
- [ ] Friend requests funcionales
- [ ] Search users funcional
```

---

## Criterios de aceptación

✅ Profile editable  
✅ Avatar upload funcional  
✅ Friends list con online status  
✅ Friend requests accept/reject
