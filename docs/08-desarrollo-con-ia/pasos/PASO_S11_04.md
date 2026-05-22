---
id: PASO_S11_04
equipo: C
bloque: 11
dep: [PASO_S08_04]
siguiente: PASO_S11_05
context_files:
  - CONTRATOS_API.md
  - BD_Y_TABLAS.md
  - CONVENCIONES.md
outputs:
  - api/src/main/java/com/codemon/payment/dto/WalletResponse.java
  - api/src/main/java/com/codemon/payment/controller/WalletController.java
  - api/src/main/java/com/codemon/payment/service/WalletService.java
  - api/src/test/java/com/codemon/payment/WalletServiceTest.java
  - front/src/app/wallet/services/wallet.service.ts
  - front/src/app/wallet/components/wallet-balance/wallet-balance.component.ts
---

# PASO 6.4 — Wallet: balance y historial de transacciones

> 🧩 **EXTRA — Feature adicional al juego base**
> `WalletService` ya existe internamente en `PASO_S08_04` para debitar/acreditar monedas durante el flujo de pago. Lo que falta es exponer el saldo actual y el historial de transacciones al frontend. Sin este paso, la UI de la tienda no puede mostrar cuántas monedas tiene el usuario.

**Grupo legacy:** 6 — Features Extra | **Equipo:** C (be) + B (fe) | **Dificultad:** 🟢 | **Tiempo:** 2–3 h

## Navegación
← **Anterior:** [PASO_S11_03](PASO_S11_03.md) — Personalidades del Bot con chat
→ **Siguiente:** [PASO_S11_05](PASO_S11_05.md) — Perfil de usuario consolidado

## Qué construye este paso

Expone el balance de monedas y el historial de compras/gastos del usuario autenticado. El `WalletService` de `PASO_S08_04` ya gestiona las operaciones — este paso solo agrega los endpoints de lectura y el componente Angular correspondiente.

## Backend

### Extender WalletService

`WalletService` ya existe en `PASO_S08_04`. Agregar dos métodos de solo lectura:

```java
// Saldo actual del usuario
public int getBalance(UUID userId) {
    return userRepository.findById(userId)
        .map(User::getCoinBalance)
        .orElseThrow(() -> new EntityNotFoundException("User not found"));
}

// Historial de transacciones (compras, gastos)
public Page<TransactionResponse> getTransactionHistory(UUID userId, Pageable pageable) {
    return paymentRecordRepository
        .findByUserIdOrderByCreatedAtDesc(userId, pageable)
        .map(this::toTransactionResponse);
}

private TransactionResponse toTransactionResponse(PaymentRecord record) {
    return new TransactionResponse(
        record.getId(),
        record.getType(),        // PURCHASE | SPEND
        record.getCoinsAmount(),
        record.getDescription(), // "Compra XY1 Booster Pack x3"
        record.getCreatedAt()
    );
}
```

### WalletController

```java
@RestController
@RequestMapping("/api/wallet")
public class WalletController {

    @GetMapping
    public WalletResponse getWallet(@AuthenticationPrincipal UserDetails user) {
        UUID userId = getUserId(user);
        int balance = walletService.getBalance(userId);
        return new WalletResponse(balance);
    }

    @GetMapping("/history")
    public Page<TransactionResponse> getHistory(
            @AuthenticationPrincipal UserDetails user,
            @PageableDefault(size = 20, sort = "createdAt", direction = DESC) Pageable pageable) {
        return walletService.getTransactionHistory(getUserId(user), pageable);
    }
}
```

### DTOs

```java
public record WalletResponse(int coinBalance) {}

public record TransactionResponse(
    UUID id,
    String type,           // "PURCHASE" | "SPEND"
    int coinsAmount,
    String description,
    Instant createdAt
) {}
```

### Endpoints

```
GET /api/wallet
Authorization: Bearer <token>
Response: { "coinBalance": 1500 }

GET /api/wallet/history?page=0&size=20
Authorization: Bearer <token>
Response: Page<TransactionResponse>
```

## Frontend

### WalletService (Angular)

```typescript
@Injectable({ providedIn: 'root' })
export class WalletService {
  private balance$ = new BehaviorSubject<number>(0);
  readonly balance = this.balance$.asObservable();

  constructor(private http: HttpClient) {}

  loadBalance(): Observable<void> {
    return this.http.get<{ coinBalance: number }>('/api/wallet').pipe(
      tap(res => this.balance$.next(res.coinBalance)),
      map(() => void 0)
    );
  }

  getHistory(page = 0): Observable<any> {
    return this.http.get(`/api/wallet/history?page=${page}&size=20`);
  }

  // Llamar después de cada compra para actualizar el saldo
  refresh(): void {
    this.loadBalance().subscribe();
  }
}
```

### WalletBalanceComponent

Componente pequeño que muestra el saldo en el header/topbar. Se incluye en `AppShell` (ya creado en `PASO_S01_03`):

```typescript
@Component({
  selector: 'app-wallet-balance',
  template: `
    <span class="wallet-badge">
      🪙 {{ balance$ | async }}
    </span>
  `
})
export class WalletBalanceComponent implements OnInit {
  balance$ = this.walletService.balance;

  constructor(private walletService: WalletService) {}

  ngOnInit() {
    this.walletService.loadBalance().subscribe();
  }
}
```

Agregar `<app-wallet-balance>` al topbar del AppShell.

## Dónde llamar `walletService.refresh()`

- Después de completar una compra en `PASO_S08_06` (Shop UI)
- Después de abrir un sobre en `PASO_S08_06`
- Al cargar el perfil de usuario (`PASO_S11_05`)

## Verificación

```bash
./mvnw test -Dtest=WalletServiceTest

# Verificar saldo correcto después de compra simulada
# Verificar historial paginado (page 0 = más recientes)
```
