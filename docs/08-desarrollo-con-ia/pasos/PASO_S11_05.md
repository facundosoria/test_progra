---
id: PASO_S11_05
equipo: C
bloque: 11
dep: [PASO_S09_01, PASO_S08_02, PASO_S11_04]
siguiente: PASO_S11_06
context_files:
  - CONTRATOS_API.md
  - BD_Y_TABLAS.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/users/dto/UserProfileResponse.java
  - api/src/main/java/com/codemon/users/controller/UserController.java
  - api/src/test/java/com/codemon/users/UserControllerTest.java
  - front/src/app/profile/services/profile.service.ts
  - front/src/app/profile/pages/profile-page/profile-page.component.ts
  - front/src/app/profile/pages/profile-page/profile-page.component.html
---

# PASO 6.5 — Perfil de usuario consolidado

> 🧩 **EXTRA — Feature adicional al juego base**
> Los datos del perfil existen dispersos: stats en `PASO_S08_02`, ranking en `PASO_S09_01`, balance en `PASO_S11_04`, historial de compras en `PASO_S08_04`. Este paso los consolida en un único endpoint `GET /api/users/me` y una página de perfil completa en Angular. Es parte del cierre de GATE 7 en S10.

**Grupo legacy:** 6 — Features Extra | **Sprint:** S10 | **Equipo:** C (be) + B (fe) | **Dificultad:** 🟡 | **Tiempo:** 3–4 h

## Navegación
← **Anterior:** [PASO_S11_04](PASO_S11_04.md) — Wallet balance endpoint
→ **Siguiente:** — (cierre de perfil para GATE 7)

## Qué construye este paso

Un endpoint que agrega en una sola llamada toda la información del usuario autenticado, y la página de perfil en Angular que lo consume.

## Backend

### UserProfileResponse (DTO consolidado)

```java
public record UserProfileResponse(
    // Datos básicos
    UUID id,
    String username,
    String email,
    boolean emailVerified,
    String avatarUrl,         // null si no tiene avatar personalizado
    Instant createdAt,

    // Wallet
    int coinBalance,

    // Stats de juego (de LeaderboardService / UserStatsService)
    int totalGames,
    int wins,
    int losses,
    int draws,
    double winRate,           // wins / (wins + losses), 0 si sin partidas

    // Ranking
    int skillRating,          // ELO
    String league,            // "BRONCE" | "PLATA" | "ORO"
    int rankingPoints,
    int pointsToNextLeague,   // 0 si ya es ORO

    // Historial reciente (últimas 5 partidas)
    List<RecentGameResponse> recentGames,

    // Últimas compras (últimas 5 transacciones)
    List<TransactionResponse> recentPurchases
) {}
```

### UserController

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    @GetMapping("/me")
    public UserProfileResponse getMyProfile(@AuthenticationPrincipal UserDetails user) {
        UUID userId = getUserId(user);

        User u = userRepository.findById(userId).orElseThrow();
        UserStats stats = leaderboardService.getUserStats(userId);
        UserRanking ranking = rankingService.getUserRanking(userId);
        int balance = walletService.getBalance(userId);
        List<RecentGameResponse> recentGames =
            leaderboardService.getRecentGames(userId, PageRequest.of(0, 5)).getContent();
        List<TransactionResponse> recentPurchases =
            walletService.getTransactionHistory(userId, PageRequest.of(0, 5)).getContent();

        return new UserProfileResponse(
            u.getId(), u.getUsername(), u.getEmail(), u.isEmailVerified(),
            u.getAvatarUrl(), u.getCreatedAt(),
            balance,
            stats.totalGames(), stats.wins(), stats.losses(), stats.draws(), stats.winRate(),
            ranking.skillRating(), ranking.league().name(), ranking.rankingPoints(),
            ranking.pointsToNextLeague(),
            recentGames, recentPurchases
        );
    }

    // Endpoint para perfil público de otro usuario (sin datos sensibles)
    @GetMapping("/{username}")
    public PublicProfileResponse getPublicProfile(@PathVariable String username) {
        User u = userRepository.findByUsername(username)
            .orElseThrow(() -> new EntityNotFoundException("User not found"));
        UserStats stats = leaderboardService.getUserStats(u.getId());
        UserRanking ranking = rankingService.getUserRanking(u.getId());

        return new PublicProfileResponse(
            u.getUsername(), u.getAvatarUrl(), u.getCreatedAt(),
            stats.wins(), stats.losses(), stats.winRate(),
            ranking.skillRating(), ranking.league().name()
            // NO incluir: email, balance, historial de compras
        );
    }
}
```

### Endpoint

```
GET /api/users/me
Authorization: Bearer <token>
Response 200: UserProfileResponse

GET /api/users/{username}
Response 200: PublicProfileResponse   (sin datos sensibles)
Response 404: si el usuario no existe
```

## Frontend

### ProfileService

```typescript
@Injectable({ providedIn: 'root' })
export class ProfileService {
  constructor(private http: HttpClient) {}

  getMyProfile(): Observable<UserProfile> {
    return this.http.get<UserProfile>('/api/users/me');
  }

  getPublicProfile(username: string): Observable<PublicProfile> {
    return this.http.get<PublicProfile>(`/api/users/${username}`);
  }
}
```

### ProfilePage — estructura de la vista

```
┌─────────────────────────────────────────────┐
│  [Avatar]  @username                        │
│            Miembro desde: 01/01/2025        │
│            Liga: 🥉 BRONCE  ELO: 1250      │
│            Monedas: 🪙 1500                 │
├────────────────────┬────────────────────────┤
│  ESTADÍSTICAS      │  ÚLTIMAS PARTIDAS      │
│  Partidas: 42      │  ✅ vs. misty — +25 pts │
│  Victorias: 28     │  ❌ vs. gary — 0 pts   │
│  Derrotas: 12      │  ✅ vs. brock — +25 pts │
│  Winrate: 70%      │  ...                   │
├────────────────────┴────────────────────────┤
│  ÚLTIMAS COMPRAS                            │
│  🛍️ XY1 Booster Pack x3  — 300 monedas    │
│  🛍️ XY1 Booster Pack x1  — 100 monedas    │
└─────────────────────────────────────────────┘
```

Integrar en el routing de Angular bajo `/profile`.

## Consideraciones de privacidad

- `GET /api/users/me` → privado, requiere JWT
- `GET /api/users/{username}` → público, sin auth (para ver perfil de rivales)
- El perfil público NUNCA expone: email, balance de monedas, historial de compras
- El avatar puede ser null (mostrar avatar genérico en frontend)

## Verificación

```bash
./mvnw test -Dtest=UserControllerTest

# Test: /me retorna todos los campos
# Test: /me con token inválido → 401
# Test: /{username} no expone email ni balance
# Test: /{username} con usuario inexistente → 404
```
