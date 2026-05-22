# Codemon - Guías Técnicas de Implementación

Documento complementario al README principal. Contiene ejemplos de código, patrones y decisiones técnicas específicas.

---

## Tabla de Contenidos

1. [2FA y Email Verification](#2fa-y-email-verification)
2. [Sistema de Pagos (Mercado Pago)](#sistema-de-pagos-mercado-pago)
3. [Sistema de Sobres](#sistema-de-sobres)
4. [Matchmaking y Cola Online](#matchmaking-y-cola-online)
5. [Motor de Juego](#motor-de-juego)
6. [WebSockets](#websockets)
7. [Chat del Bot](#chat-del-bot)
8. [Estructura de BD](#estructura-de-bd)
9. [Patrones y Best Practices](#patrones-y-best-practices)

---

## 2FA y Email Verification

### Flujo general

```
Usuario registra → email sin verificar → envía código → usuario ingresa código → email verificado
```

### Tabla `email_verifications`

```sql
CREATE TABLE email_verifications (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL UNIQUE,
  code_hash VARCHAR(255) NOT NULL,        -- BCrypt hash del código
  code_expires_at TIMESTAMP NOT NULL,
  attempts_count INT DEFAULT 0,
  blocked_until TIMESTAMP,                -- Para bloquear tras 5 intentos
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### Servicio de Verificación

```java
@Service
public class EmailVerificationService {
  
  @Autowired private EmailVerificationRepository repo;
  @Autowired private PasswordEncoder encoder;
  @Autowired private EmailService emailService;
  
  // 1. Generar código y guardar
  public void createVerificationCode(Long userId, String email) {
    String code = generateCode(); // 6 dígitos
    String codeHash = encoder.encode(code); // BCrypt
    
    EmailVerification ev = EmailVerification.builder()
      .userId(userId)
      .codeHash(codeHash)
      .codeExpiresAt(LocalDateTime.now().plusMinutes(30))
      .attemptsCount(0)
      .build();
    
    repo.save(ev);
    
    // Enviar email de forma asíncrona
    emailService.sendVerificationCodeAsync(email, code);
  }
  
  // 2. Validar código
  public void validateCode(Long userId, String code) throws VerificationException {
    EmailVerification ev = repo.findByUserId(userId)
      .orElseThrow(() -> new VerificationNotFoundException("No hay verificación pendiente"));
    
    // Check 1: Código expirado
    if (LocalDateTime.now().isAfter(ev.getCodeExpiresAt())) {
      repo.delete(ev);
      throw new VerificationExpiredException("Código expirado. Solicita uno nuevo.");
    }
    
    // Check 2: Bloqueado por intentos
    if (ev.getBlockedUntil() != null && LocalDateTime.now().isBefore(ev.getBlockedUntil())) {
      throw new VerificationBlockedException("Demasiados intentos fallidos. Intenta en 15 minutos.");
    }
    
    // Check 3: Validar código
    if (!encoder.matches(code, ev.getCodeHash())) {
      ev.setAttemptsCount(ev.getAttemptsCount() + 1);
      
      if (ev.getAttemptsCount() >= 5) {
        ev.setBlockedUntil(LocalDateTime.now().plusMinutes(15));
      }
      
      repo.save(ev);
      throw new VerificationInvalidException("Código incorrecto.");
    }
    
    // Success
    repo.delete(ev);
  }
  
  // 3. Generar código
  private String generateCode() {
    Random random = new Random();
    return String.format("%06d", random.nextInt(1000000));
  }
  
  // 4. Resend (con rate limit)
  public void resendCode(Long userId, String email) throws RateLimitException {
    EmailVerification ev = repo.findByUserId(userId)
      .orElseThrow(() -> new VerificationNotFoundException("No hay verificación pendiente"));
    
    // Rate limit: máximo 1 reintento cada 60 segundos
    if (ev.getCreatedAt().isAfter(LocalDateTime.now().minusSeconds(60))) {
      throw new RateLimitException("Espera 60 segundos antes de resolicitar.");
    }
    
    // Generar nuevo código
    String newCode = generateCode();
    ev.setCodeHash(encoder.encode(newCode));
    ev.setCodeExpiresAt(LocalDateTime.now().plusMinutes(30));
    ev.setAttemptsCount(0);
    ev.setBlockedUntil(null);
    ev.setCreatedAt(LocalDateTime.now());
    
    repo.save(ev);
    emailService.sendVerificationCodeAsync(email, newCode);
  }
}
```

### EmailService

```java
@Service
public class EmailService {
  
  @Autowired private JavaMailSender mailSender;
  @Async // Importante: no bloquea
  public void sendVerificationCodeAsync(String email, String code) {
    try {
      SimpleMailMessage message = new SimpleMailMessage();
      message.setTo(email);
      message.setSubject("Código de verificación - Codemon");
      message.setText("Tu código: " + code + "\nVálido por 30 minutos.");
      message.setFrom("noreply@codemon.com");
      
      mailSender.send(message);
    } catch (Exception e) {
      log.error("Error enviando email de verificación", e);
      // Aquí podrías notificar a Sentry o similar
    }
  }
}
```

### Controller

```java
@RestController
@RequestMapping("/auth")
public class AuthController {
  
  @Autowired private EmailVerificationService verificationService;
  @Autowired private AuthService authService;
  
  @PostMapping("/register")
  public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest req) {
    // 1. Validar input
    if (!req.getPassword().equals(req.getConfirmPassword())) {
      return ResponseEntity.badRequest().body(Map.of(
        "error", "Las contraseñas no coinciden"
      ));
    }
    
    // 2. Crear usuario (email_verified = false)
    User user = authService.createUser(req.getUsername(), req.getEmail(), req.getPassword());
    
    // 3. Crear y enviar código
    verificationService.createVerificationCode(user.getId(), user.getEmail());
    
    return ResponseEntity.ok(Map.of(
      "userId", user.getId(),
      "message", "Código enviado a tu email. Válido por 30 minutos."
    ));
  }
  
  @PostMapping("/verify-email")
  public ResponseEntity<?> verifyEmail(@Valid @RequestBody VerifyEmailRequest req) {
    try {
      // 1. Validar código
      verificationService.validateCode(req.getUserId(), req.getCode());
      
      // 2. Marcar como verificado
      authService.markEmailAsVerified(req.getUserId());
      
      // 3. Generar tokens
      User user = authService.getUser(req.getUserId());
      String accessToken = authService.generateAccessToken(user);
      String refreshToken = authService.generateRefreshToken(user);
      
      return ResponseEntity.ok(Map.of(
        "accessToken", accessToken,
        "refreshToken", refreshToken,
        "expiresIn", 900 // 15 minutos
      ));
      
    } catch (VerificationException e) {
      return ResponseEntity.badRequest().body(Map.of(
        "error", e.getMessage()
      ));
    }
  }
  
  @PostMapping("/resend-code")
  public ResponseEntity<?> resendCode(@RequestBody ResendCodeRequest req) {
    try {
      User user = authService.getUser(req.getUserId());
      verificationService.resendCode(req.getUserId(), user.getEmail());
      
      return ResponseEntity.ok(Map.of(
        "message", "Código reenviado. Válido por 30 minutos."
      ));
      
    } catch (RateLimitException e) {
      return ResponseEntity.status(429).body(Map.of(
        "error", e.getMessage()
      ));
    } catch (Exception e) {
      return ResponseEntity.badRequest().body(Map.of(
        "error", e.getMessage()
      ));
    }
  }
}
```

### Configuración en `application.yml`

```yaml
spring:
  mail:
    host: ${EMAIL_SMTP_HOST:smtp.gmail.com}
    port: ${EMAIL_SMTP_PORT:587}
    username: ${EMAIL_USERNAME}
    password: ${EMAIL_PASSWORD}
    properties:
      mail:
        smtp:
          auth: true
          starttls:
            enable: true
            required: true

# O si usas Mailgun/SendGrid, adapta según su SDK
```

---

## Sistema de Pagos (Mercado Pago)

### Tabla `payment_records`

```sql
CREATE TABLE payment_records (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL,
  amount_usd DECIMAL(10, 2) NOT NULL,
  amount_coins BIGINT NOT NULL,             -- Moneda virtual acreditada
  mercado_pago_preference_id VARCHAR(255),  -- ID de preferencia (para rastreo)
  mercado_pago_transaction_id VARCHAR(255), -- ID de transacción (único)
  status VARCHAR(50) DEFAULT 'PENDING',     -- PENDING, COMPLETED, FAILED, CANCELLED
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  webhook_received_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  UNIQUE(mercado_pago_transaction_id)       -- Evitar duplicados
);

CREATE TABLE user_payments_webhooks (
  id BIGSERIAL PRIMARY KEY,
  mercado_pago_event_id VARCHAR(255) UNIQUE,
  payload JSONB NOT NULL,
  processed BOOLEAN DEFAULT false,
  processed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para performance
CREATE INDEX idx_payment_records_user_id ON payment_records(user_id);
CREATE INDEX idx_payment_records_status ON payment_records(status);
CREATE INDEX idx_payment_records_mp_transaction ON payment_records(mercado_pago_transaction_id);
CREATE INDEX idx_webhooks_event_id ON user_payments_webhooks(mercado_pago_event_id);
```

### Servicio de Pagos

```java
@Service
public class PaymentService {
  
  @Autowired private PaymentRecordRepository paymentRepo;
  @Autowired private WebhookLogRepository webhookRepo;
  @Autowired private WalletService walletService;
  @Autowired private MercadoPagoClient mercadoPagoClient;
  
  // 1. Crear preferencia de pago
  public PreferenceResponse createPreference(Long userId, Long boosterPackId, int quantity) 
      throws PaymentException {
    
    // Get booster pack details
    BoosterPack booster = getBoosterPack(boosterPackId);
    BigDecimal totalUsd = booster.getPriceUsd().multiply(BigDecimal.valueOf(quantity));
    long totalCoins = booster.getCoinsPerPack() * quantity;
    
    // Create preference in Mercado Pago
    Preference preference = new Preference();
    preference.setExternalReference(UUID.randomUUID().toString()); // Unique identifier
    
    Item item = new Item();
    item.setTitle(booster.getName() + " x" + quantity);
    item.setQuantity(1);
    item.setUnitPrice(totalUsd);
    item.setDescription("Booster Pack para Codemon TCG");
    preference.appendItem(item);
    
    // Notifications
    preference.setNotificationUrl(
      "https://api.codemon.com/webhooks/mercado-pago"
    );
    
    // Save pending payment record
    PaymentRecord record = PaymentRecord.builder()
      .userId(userId)
      .amountUsd(totalUsd)
      .amountCoins(totalCoins)
      .status("PENDING")
      .build();
    
    try {
      Preference savedPreference = mercadoPagoClient.createPreference(preference);
      record.setMercadoPagoPreferenceId(savedPreference.getId());
      paymentRepo.save(record);
      
      return PreferenceResponse.builder()
        .paymentUrl(savedPreference.getSandboxInitPoint())
        .preferenceId(savedPreference.getId())
        .totalUsd(totalUsd)
        .totalCoins(totalCoins)
        .build();
      
    } catch (Exception e) {
      log.error("Error creating Mercado Pago preference", e);
      throw new PaymentException("Error al crear preferencia de pago");
    }
  }
  
  // 2. Procesar webhook (CRÍTICO: idempotencia)
  @Transactional
  public void processWebhook(WebhookPayload payload) throws WebhookException {
    String eventId = payload.getId();
    
    // Check 1: ¿Ya procesamos este evento?
    if (webhookRepo.existsByMercadoPagoEventId(eventId)) {
      log.info("Webhook {} ya fue procesado", eventId);
      return; // Idempotencia
    }
    
    // Check 2: Guardar log del webhook
    WebhookLog webhookLog = WebhookLog.builder()
      .mercadoPagoEventId(eventId)
      .payload(payload) // JSONB
      .processed(false)
      .build();
    webhookRepo.save(webhookLog);
    
    // Check 3: ¿Es un evento de pago?
    if (!"payment.created".equals(payload.getType()) && 
        !"payment.updated".equals(payload.getType())) {
      return; // Ignorar otros tipos
    }
    
    // Check 4: Obtener datos del pago
    Map<String, Object> data = (Map<String, Object>) payload.getData();
    String transactionId = (String) data.get("id");
    String status = (String) data.get("status");
    String externalReference = (String) data.get("external_reference");
    
    // Check 5: Buscar registro de pago
    PaymentRecord payment = paymentRepo.findByMercadoPagoPreferenceId(externalReference)
      .orElseThrow(() -> new WebhookException("Pago no encontrado"));
    
    // Check 6: ¿Ya estaba completado?
    if ("COMPLETED".equals(payment.getStatus())) {
      log.warn("Pago {} ya fue completado", transactionId);
      return;
    }
    
    // Check 7: Actualizar estado del pago
    payment.setMercadoPagoTransactionId(transactionId);
    payment.setWebhookReceivedAt(LocalDateTime.now());
    
    if ("approved".equals(status)) {
      // ✅ Acreditar moneda al usuario
      walletService.creditCoins(
        payment.getUserId(), 
        payment.getAmountCoins(),
        transactionId // Trackear por qué fue acreditado
      );
      
      payment.setStatus("COMPLETED");
      payment.setCompletedAt(LocalDateTime.now());
      
      // Crear entries en booster packs del usuario
      createBoosterPacksForUser(payment.getUserId(), payment.getAmountCoins());
      
    } else if ("rejected".equals(status) || "cancelled".equals(status)) {
      payment.setStatus("FAILED");
    }
    
    paymentRepo.save(payment);
    
    // Marcar webhook como procesado
    webhookLog.setProcessed(true);
    webhookLog.setProcessedAt(LocalDateTime.now());
    webhookRepo.save(webhookLog);
    
    log.info("Webhook {} procesado exitosamente", eventId);
  }
  
  // 3. Crear sobres en el perfil del usuario
  private void createBoosterPacksForUser(Long userId, long coins) {
    // Mapeo: 500 coins = 1 sobre genérico, etc.
    // Esto va a depender de tu definición de precios
    log.info("Creando booster packs para usuario {} con {} coins", userId, coins);
    // Implementar según lógica de negocio
  }
}
```

### Controller para Webhook

```java
@RestController
@RequestMapping("/webhooks")
public class WebhookController {
  
  @Autowired private PaymentService paymentService;
  
  @PostMapping("/mercado-pago")
  public ResponseEntity<?> mercadoPagoWebhook(@RequestBody WebhookPayload payload) {
    try {
      log.info("Webhook recibido: {}", payload.getId());
      paymentService.processWebhook(payload);
      
      return ResponseEntity.ok(Map.of("status", "processed"));
      
    } catch (Exception e) {
      log.error("Error procesando webhook", e);
      // Importante: devolver 200 OK para que MP no reintente
      // Pero loguear el error para investigar
      return ResponseEntity.ok(Map.of("status", "error", "message", e.getMessage()));
    }
  }
}
```

### Configuración

```yaml
mercado-pago:
  access-token: ${MP_ACCESS_TOKEN}
  public-key: ${MP_PUBLIC_KEY}
  webhook-secret: ${MP_WEBHOOK_SECRET}
  sandbox: ${MP_SANDBOX:true}
```

---

## Sistema de Sobres

### Tabla `user_booster_packs`

```sql
CREATE TABLE user_booster_packs (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL,
  booster_pack_id BIGINT NOT NULL,
  obtained_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  opened_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (booster_pack_id) REFERENCES booster_packs(id)
);

CREATE TABLE user_collection (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL,
  card_id VARCHAR(255) NOT NULL,
  quantity INT DEFAULT 1,
  obtained_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (card_id) REFERENCES cards_catalog(id),
  UNIQUE(user_id, card_id) -- Una entrada por usuario + carta
);

CREATE INDEX idx_user_booster_user_id ON user_booster_packs(user_id);
CREATE INDEX idx_user_booster_opened ON user_booster_packs(opened_at);
CREATE INDEX idx_user_collection_user_id ON user_collection(user_id);
```

### Servicio de Booster Packs

```java
@Service
public class BoosterPackService {
  
  @Autowired private UserBoosterPackRepository boosterRepo;
  @Autowired private UserCollectionRepository collectionRepo;
  @Autowired private CardRepository cardRepo;
  @Autowired private WalletService walletService;
  @Autowired private RedisTemplate<String, Object> redis;
  
  // 1. Abrir un sobre (con cooldown)
  @Transactional
  public OpenBoosterResponse openBoosterPack(Long userId, Long boosterPackEntryId) 
      throws BoosterException {
    
    // Check 1: Usuario posee el sobre
    UserBoosterPack ubp = boosterRepo.findById(boosterPackEntryId)
      .orElseThrow(() -> new BoosterNotFoundException("Sobre no encontrado"));
    
    if (!ubp.getUser().getId().equals(userId)) {
      throw new BoosterUnauthorizedException("No es tu sobre");
    }
    
    // Check 2: Sobre ya abierto
    if (ubp.getOpenedAt() != null) {
      throw new BoosterAlreadyOpenedException("Sobre ya abierto");
    }
    
    // Check 3: Cooldown (máximo 1 sobre cada 24h)
    String cooldownKey = "booster:cooldown:" + userId;
    Object lastOpenTime = redis.opsForValue().get(cooldownKey);
    
    if (lastOpenTime != null) {
      long nextAvailableTs = (long) lastOpenTime + (24 * 60 * 60 * 1000);
      if (System.currentTimeMillis() < nextAvailableTs) {
        throw new BoosterCooldownException(
          "Próximo sobre disponible en: " + new Date(nextAvailableTs)
        );
      }
    }
    
    // Check 4: Generar cartas
    List<Card> generatedCards = generateCardsFromBooster(ubp.getBoosterPack());
    
    // Check 5: Agregar a colección
    for (Card card : generatedCards) {
      UserCollection existingEntry = collectionRepo.findByUserIdAndCardId(userId, card.getId());
      
      if (existingEntry != null) {
        existingEntry.setQuantity(existingEntry.getQuantity() + 1);
        collectionRepo.save(existingEntry);
      } else {
        UserCollection newEntry = UserCollection.builder()
          .userId(userId)
          .cardId(card.getId())
          .quantity(1)
          .obtainedDate(LocalDateTime.now())
          .build();
        collectionRepo.save(newEntry);
      }
    }
    
    // Check 6: Marcar como abierto
    ubp.setOpenedAt(LocalDateTime.now());
    boosterRepo.save(ubp);
    
    // Check 7: Setear cooldown en Redis
    redis.opsForValue().set(cooldownKey, System.currentTimeMillis(), 24, TimeUnit.HOURS);
    
    // Check 8: Actualizar vista materializada
    updateCollectionStats(userId);
    
    return OpenBoosterResponse.builder()
      .cardsObtained(generatedCards)
      .nextCooldownAvailable(LocalDateTime.now().plusHours(24))
      .build();
  }
  
  // 2. Generar cartas con rarity
  private List<Card> generateCardsFromBooster(BoosterPack booster) {
    List<Card> result = new ArrayList<>();
    Random random = new Random();
    
    // Estructura típica: 10 cartas por sobre
    // 60% Common (6 cartas)
    // 25% Uncommon (2-3 cartas)
    // 12% Rare (1 carta)
    // 3% Holographic (puede estar en cualquier rareza)
    
    Map<String, List<Card>> cardsByRarity = getCardsByRarity(booster);
    
    // Generate distribution
    int[] distribution = {6, 3, 1}; // common, uncommon, rare
    String[] rarities = {"COMMON", "UNCOMMON", "RARE"};
    
    for (int i = 0; i < rarities.length; i++) {
      List<Card> cardsOfRarity = cardsByRarity.get(rarities[i]);
      
      for (int j = 0; j < distribution[i]; j++) {
        Card picked = cardsOfRarity.get(random.nextInt(cardsOfRarity.size()));
        
        // 3% chance de ser holographic (duplicar rarity visualmente)
        if (random.nextDouble() < 0.03) {
          // Marcar como holographic (podría ser un atributo de la colección)
        }
        
        result.add(picked);
      }
    }
    
    return result;
  }
  
  // 3. Verificar cooldown
  public BoosterCooldownStatus getCooldownStatus(Long userId) {
    String cooldownKey = "booster:cooldown:" + userId;
    Object lastOpenTime = redis.opsForValue().get(cooldownKey);
    
    if (lastOpenTime == null) {
      return BoosterCooldownStatus.builder()
        .canOpenNow(true)
        .nextAvailableAt(null)
        .build();
    }
    
    long nextAvailableTs = (long) lastOpenTime + (24 * 60 * 60 * 1000);
    
    return BoosterCooldownStatus.builder()
      .canOpenNow(System.currentTimeMillis() >= nextAvailableTs)
      .nextAvailableAt(new Date(nextAvailableTs))
      .build();
  }
  
  // 4. Actualizar vista materializada
  @Async
  private void updateCollectionStats(Long userId) {
    // En PostgreSQL:
    // REFRESH MATERIALIZED VIEW CONCURRENTLY user_collection_stats;
    // Pero como es específica por usuario, podrías cachear con Redis
    
    long totalCards = collectionRepo.countByUserId(userId);
    long uniqueCards = collectionRepo.countUniqueCardsByUserId(userId);
    
    // Cachear en Redis
    Map<String, Object> stats = Map.of(
      "totalCards", totalCards,
      "uniqueCards", uniqueCards,
      "completionPct", (uniqueCards * 100) / 146 // 146 cartas XY1
    );
    
    redis.opsForValue().set("collection:stats:" + userId, stats, 1, TimeUnit.HOURS);
  }
}
```

---

## Matchmaking y Cola Online

### Tabla `queue_entries` y `skill_ratings`

```sql
CREATE TABLE skill_ratings (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL UNIQUE,
  current_rating INT DEFAULT 1000,
  wins INT DEFAULT 0,
  losses INT DEFAULT 0,
  total_games INT DEFAULT 0,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE queue_entries (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL,
  deck_id BIGINT NOT NULL,
  skill_rating INT NOT NULL,
  join_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(50) DEFAULT 'WAITING', -- WAITING, MATCHED, CANCELLED, TIMEOUT
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (deck_id) REFERENCES decks(id)
);

CREATE INDEX idx_queue_status ON queue_entries(status);
CREATE INDEX idx_queue_skill_rating ON queue_entries(skill_rating);
CREATE INDEX idx_skill_ratings_rating ON skill_ratings(current_rating);
```

### Servicio de Matchmaking

```java
@Service
public class MatchmakingService {
  
  @Autowired private QueueEntryRepository queueRepo;
  @Autowired private SkillRatingRepository skillRepo;
  @Autowired private GameService gameService;
  @Autowired private SimpMessagingTemplate messagingTemplate;
  @Autowired private RedisTemplate<String, Object> redis;
  
  // 1. Agregar a cola
  @Transactional
  public QueueEntry addToQueue(Long userId, Long deckId) throws QueueException {
    // Check: usuario ya en cola
    if (queueRepo.findByUserIdAndStatus(userId, "WAITING").isPresent()) {
      throw new AlreadyInQueueException("Ya estás en la cola");
    }
    
    // Get skill rating
    SkillRating skillRating = skillRepo.findByUserId(userId)
      .orElse(SkillRating.builder().userId(userId).currentRating(1000).build());
    
    QueueEntry entry = QueueEntry.builder()
      .userId(userId)
      .deckId(deckId)
      .skillRating(skillRating.getCurrentRating())
      .status("WAITING")
      .build();
    
    queueRepo.save(entry);
    
    // Agregar a Redis para búsqueda rápida
    // ZADD matchmaking:queue {rating} {userId}
    redis.opsForZSet().add("matchmaking:queue", userId.toString(), skillRating.getCurrentRating());
    
    return entry;
  }
  
  // 2. Cron job: buscar matches cada 3 segundos
  @Scheduled(fixedRate = 3000)
  public void findMatches() {
    // Get all users in queue (from Redis)
    Set<String> usersInQueue = redis.opsForZSet().range("matchmaking:queue", 0, -1);
    
    if (usersInQueue.size() < 2) {
      return; // Nada que matchear
    }
    
    List<Long> userIds = usersInQueue.stream()
      .map(Long::parseLong)
      .collect(Collectors.toList());
    
    // Para cada usuario, buscar mejor match
    for (Long user1Id : userIds) {
      // Skip if user ya encontró match
      QueueEntry entry1 = queueRepo.findByUserIdAndStatus(user1Id, "WAITING")
        .orElse(null);
      
      if (entry1 == null || "MATCHED".equals(entry1.getStatus())) {
        continue;
      }
      
      Long user2Id = null;
      QueueEntry entry2 = null;
      
      // Buscar best match en rango de skill
      int secondsWaiting = (int) Duration.between(
        entry1.getJoinTime(), 
        LocalDateTime.now()
      ).getSeconds();
      
      // Window inicial: ±100, expandir cada 5 segundos
      int skillWindow = 100 + (secondsWaiting / 5) * 50;
      skillWindow = Math.min(skillWindow, 300); // Máximo ±300
      
      int minRating = entry1.getSkillRating() - skillWindow;
      int maxRating = entry1.getSkillRating() + skillWindow;
      
      // Buscar en BD
      List<QueueEntry> candidates = queueRepo.findByStatusAndSkillRatingBetween(
        "WAITING", 
        minRating, 
        maxRating
      );
      
      // Excluir al usuario mismo y al ya matched
      for (QueueEntry candidate : candidates) {
        if (candidate.getId().equals(entry1.getId())) {
          continue;
        }
        
        // Chequear que no esté matcheado con otro
        if ("MATCHED".equals(candidate.getStatus())) {
          continue;
        }
        
        user2Id = candidate.getUser().getId();
        entry2 = candidate;
        break;
      }
      
      // Si encontró match
      if (user2Id != null && entry2 != null) {
        try {
          createGameFromMatch(user1Id, user2Id, entry1, entry2);
        } catch (Exception e) {
          log.error("Error creando game de match", e);
        }
      }
      
      // Si pasó mucho tiempo: timeout
      if (secondsWaiting > 30) {
        entry1.setStatus("TIMEOUT");
        queueRepo.save(entry1);
        redis.opsForZSet().remove("matchmaking:queue", user1Id.toString());
        
        messagingTemplate.convertAndSendToUser(
          user1Id.toString(),
          "/queue/matchmaking",
          Map.of("event", "QUEUE_TIMEOUT", "reason", "no_match_found")
        );
      }
    }
  }
  
  // 3. Crear game del match
  @Transactional
  private void createGameFromMatch(Long user1Id, Long user2Id, 
                                    QueueEntry entry1, QueueEntry entry2) 
      throws QueueException {
    
    // Crear game
    Game game = gameService.createGame(
      user1Id, 
      entry1.getDeckId(),
      "QUEUE",
      null
    );
    game.setPlayer2Id(user2Id);
    game.setPlayer2DeckId(entry2.getDeckId());
    gameService.saveGame(game);
    
    // Marcar queue entries como matched
    entry1.setStatus("MATCHED");
    entry2.setStatus("MATCHED");
    queueRepo.saveAll(List.of(entry1, entry2));
    
    // Eliminar de Redis
    redis.opsForZSet().remove("matchmaking:queue", user1Id.toString(), user2Id.toString());
    
    // Notificar ambos usuarios
    messagingTemplate.convertAndSendToUser(
      user1Id.toString(),
      "/queue/matchmaking",
      Map.of(
        "event", "MATCH_FOUND",
        "gameId", game.getId(),
        "opponent", user2Id
      )
    );
    
    messagingTemplate.convertAndSendToUser(
      user2Id.toString(),
      "/queue/matchmaking",
      Map.of(
        "event", "MATCH_FOUND",
        "gameId", game.getId(),
        "opponent", user1Id
      )
    );
    
    log.info("Match found: {} vs {}, gameId: {}", user1Id, user2Id, game.getId());
  }
  
  // 4. Remover de cola
  @Transactional
  public void removeFromQueue(Long userId) {
    QueueEntry entry = queueRepo.findByUserIdAndStatus(userId, "WAITING")
      .orElse(null);
    
    if (entry != null) {
      entry.setStatus("CANCELLED");
      queueRepo.save(entry);
    }
    
    redis.opsForZSet().remove("matchmaking:queue", userId.toString());
  }
}
```

---

## Motor de Juego

### GameEngine (orquestador)

```java
@Service
public class GameEngine {
  
  @Autowired private GameRepository gameRepo;
  @Autowired private TurnManager turnManager;
  @Autowired private RuleValidator ruleValidator;
  @Autowired private DamageCalculator damageCalc;
  @Autowired private StatusEffectManager statusManager;
  @Autowired private VictoryConditionChecker victoryChecker;
  @Autowired private GameEventPublisher eventPublisher;
  
  @Transactional
  public void processAction(Long gameId, GameAction action) throws GameException {
    // 1. Obtener game
    Game game = gameRepo.findById(gameId)
      .orElseThrow(() -> new GameNotFoundException("Partida no encontrada"));
    
    // 2. Obtener board actual
    GameBoard board = game.getCurrentBoardState();
    
    // 3. Validar turno actual
    Long currentPlayerId = turnManager.getCurrentPlayerId(board);
    if (!currentPlayerId.equals(action.getPlayerId())) {
      throw new NotYourTurnException("No es tu turno");
    }
    
    // 4. Procesar acción según tipo
    GameActionResult result = null;
    
    switch (action.getActionType()) {
      case ATTACK:
        result = processAttack(game, board, (AttackAction) action);
        break;
      case EVOLVE_POKEMON:
        result = processEvolution(game, board, (EvolveAction) action);
        break;
      case RETREAT:
        result = processRetreat(game, board, (RetreatAction) action);
        break;
      // ... otros tipos
    }
    
    if (result != null) {
      // 5. Validar resultado
      ruleValidator.validate(game, board, result);
      
      // 6. Aplicar cambios al board
      board.applyAction(result);
      
      // 7. Crear snapshot
      createSnapshot(game, board);
      
      // 8. Publicar evento
      eventPublisher.publishGameEvent(gameId, result.getEvent());
      
      // 9. Chequear condiciones de victoria
      GameOverCondition gameOver = victoryChecker.checkVictoryConditions(game, board);
      if (gameOver != null) {
        finishGame(game, gameOver);
      }
    }
  }
  
  private GameActionResult processAttack(Game game, GameBoard board, AttackAction action) 
      throws GameException {
    
    // Validar que puede atacar
    if (!ruleValidator.canAttack(board, action.getAttackerId(), action.getTargetId())) {
      throw new InvalidActionException("No puede atacar");
    }
    
    Pokemon attacker = board.getPokemon(action.getAttackerId());
    Pokemon defender = board.getPokemon(action.getTargetId());
    Attack attack = attacker.getAttack(action.getAttackId());
    
    // Calcular daño
    int damage = damageCalc.calculate(
      attack.getBaseDamage(),
      attacker,
      defender
    );
    
    // Aplicar daño
    defender.takeDamage(damage);
    
    // Chequear si se ko
    boolean isKo = defender.getHp() <= 0;
    
    // Aplicar status
    if (attack.hasStatusEffect()) {
      statusManager.applyStatus(defender, attack.getStatusEffect());
    }
    
    return GameActionResult.builder()
      .actionType("ATTACK")
      .attacker(attacker)
      .defender(defender)
      .damage(damage)
      .isKo(isKo)
      .event(new GameEvent("ATTACK", Map.of(
        "attacker", attacker.getName(),
        "damage", damage,
        "defenderHp", defender.getHp()
      )))
      .build();
  }
  
  private void createSnapshot(Game game, GameBoard board) {
    GameStateSnapshot snapshot = GameStateSnapshot.builder()
      .gameId(game.getId())
      .turnNumber(game.getTurnNumber())
      .stateJson(boardToJson(board)) // JSONB
      .createdAt(LocalDateTime.now())
      .build();
    
    snapshotRepo.save(snapshot);
  }
  
  private void finishGame(Game game, GameOverCondition condition) {
    game.setStatus("FINISHED");
    game.setWinnerId(condition.getWinnerId());
    game.setEndedAt(LocalDateTime.now());
    
    gameRepo.save(game);
    
    // Actualizar estadísticas del usuario
    updateUserStats(game);
    
    // Si es PVP ranked: actualizar ELO
    if ("QUEUE".equals(game.getMatchType())) {
      updateSkillRatings(game);
    }
    
    eventPublisher.publishGameEvent(game.getId(), new GameEvent("GAME_OVER", Map.of(
      "winnerId", condition.getWinnerId()
    )));
  }
}
```

---

## WebSockets

### Configuración

```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {
  
  @Override
  public void configureMessageBroker(MessageBrokerRegistry config) {
    config.enableSimpleBroker("/topic", "/user", "/queue");
    config.setApplicationDestinationPrefixes("/app");
    config.setUserDestinationPrefix("/user");
  }
  
  @Override
  public void registerStompEndpoints(StompEndpointRegistry registry) {
    registry.addEndpoint("/ws")
      .setAllowedOrigins("http://localhost:4200", "https://codemon.com")
      .withSockJS()
      .setClientLibraryUrl("https://cdn.jsdelivr.net/npm/sockjs-client@1.6.0/dist/sockjs.min.js");
  }
}
```

### GameEventPublisher

```java
@Service
public class GameEventPublisher {
  
  @Autowired private SimpMessagingTemplate messagingTemplate;
  
  public void publishGameEvent(Long gameId, GameEvent event) {
    messagingTemplate.convertAndSend(
      "/topic/game/" + gameId,
      event
    );
  }
  
  public void publishPrivateEvent(Long userId, GameEvent event) {
    messagingTemplate.convertAndSendToUser(
      userId.toString(),
      "/queue/game",
      event
    );
  }
  
  public void publishChatMessage(Long gameId, ChatMessage message) {
    messagingTemplate.convertAndSend(
      "/topic/game/" + gameId + "/chat",
      message
    );
  }
}
```

---

## Chat del Bot

Ver la seccion "Bot con chat y personalidad argentina" en `ESPECIFICACION_PRODUCTO.md`.

---

## Estructura de BD

### Script Flyway `V1__initial_schema.sql`

```sql
-- Users (extendida)
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  email_verified BOOLEAN DEFAULT FALSE,
  virtual_currency_balance BIGINT DEFAULT 0,
  skill_rating INT DEFAULT 1000,
  wins INT DEFAULT 0,
  losses INT DEFAULT 0,
  draws INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Email verifications
CREATE TABLE email_verifications (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL UNIQUE,
  code_hash VARCHAR(255) NOT NULL,
  code_expires_at TIMESTAMP NOT NULL,
  attempts_count INT DEFAULT 0,
  blocked_until TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Refresh tokens
CREATE TABLE refresh_tokens (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL,
  token_hash VARCHAR(255) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Cards catalog
CREATE TABLE cards_catalog (
  id VARCHAR(255) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  set_code VARCHAR(10) NOT NULL,
  card_type VARCHAR(50),
  super_type VARCHAR(50),
  rarity VARCHAR(20),
  hp INT,
  attack_damage INT,
  retreat_cost INT,
  ability VARCHAR(255),
  ability_description TEXT,
  attacks JSONB,
  image_small_url VARCHAR(500),
  image_large_url VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Imagenes de cartas:
-- No crear tabla card_images ni guardar BYTEA en PostgreSQL.
-- El seed lee xy1.json, descarga images.small/images.large una vez,
-- sube los PNG a MinIO y guarda las URLs publicas en cards_catalog.

-- Decks
CREATE TABLE decks (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  is_favorite BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Deck cards
CREATE TABLE deck_cards (
  id BIGSERIAL PRIMARY KEY,
  deck_id BIGINT NOT NULL,
  card_id VARCHAR(255) NOT NULL,
  quantity INT DEFAULT 1,
  FOREIGN KEY (deck_id) REFERENCES decks(id),
  FOREIGN KEY (card_id) REFERENCES cards_catalog(id),
  UNIQUE(deck_id, card_id)
);

-- Booster packs definition
CREATE TABLE booster_packs (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price_usd DECIMAL(10, 2) NOT NULL,
  price_coins BIGINT NOT NULL,
  rarity_distribution JSONB, -- {"common": 60, "uncommon": 25, "rare": 12, "holographic": 3}
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Booster pack card pool
CREATE TABLE booster_pack_cards (
  id BIGSERIAL PRIMARY KEY,
  booster_pack_id BIGINT NOT NULL,
  card_id VARCHAR(255) NOT NULL,
  rarity VARCHAR(20) NOT NULL,
  FOREIGN KEY (booster_pack_id) REFERENCES booster_packs(id),
  FOREIGN KEY (card_id) REFERENCES cards_catalog(id)
);

-- User booster packs
CREATE TABLE user_booster_packs (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL,
  booster_pack_id BIGINT NOT NULL,
  obtained_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  opened_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (booster_pack_id) REFERENCES booster_packs(id)
);

-- User collection
CREATE TABLE user_collection (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL,
  card_id VARCHAR(255) NOT NULL,
  quantity INT DEFAULT 1,
  obtained_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (card_id) REFERENCES cards_catalog(id),
  UNIQUE(user_id, card_id)
);

-- Payment records
CREATE TABLE payment_records (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL,
  amount_usd DECIMAL(10, 2) NOT NULL,
  amount_coins BIGINT NOT NULL,
  mercado_pago_preference_id VARCHAR(255),
  mercado_pago_transaction_id VARCHAR(255) UNIQUE,
  status VARCHAR(50) DEFAULT 'PENDING',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  webhook_received_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Webhook logs
CREATE TABLE user_payments_webhooks (
  id BIGSERIAL PRIMARY KEY,
  mercado_pago_event_id VARCHAR(255) UNIQUE,
  payload JSONB,
  processed BOOLEAN DEFAULT FALSE,
  processed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Skill ratings
CREATE TABLE skill_ratings (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT UNIQUE NOT NULL,
  current_rating INT DEFAULT 1000,
  wins INT DEFAULT 0,
  losses INT DEFAULT 0,
  total_games INT DEFAULT 0,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Queue entries
CREATE TABLE queue_entries (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL,
  deck_id BIGINT NOT NULL,
  skill_rating INT NOT NULL,
  join_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(50) DEFAULT 'WAITING',
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (deck_id) REFERENCES decks(id)
);

-- Game rooms
CREATE TABLE game_rooms (
  id BIGSERIAL PRIMARY KEY,
  creator_id BIGINT NOT NULL,
  room_code VARCHAR(6) UNIQUE NOT NULL,
  status VARCHAR(50) DEFAULT 'WAITING',
  max_players INT DEFAULT 2,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP,
  FOREIGN KEY (creator_id) REFERENCES users(id)
);

-- Game room players
CREATE TABLE game_room_players (
  id BIGSERIAL PRIMARY KEY,
  room_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  deck_id BIGINT NOT NULL,
  join_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (room_id) REFERENCES game_rooms(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (deck_id) REFERENCES decks(id)
);

-- Games (extendida)
CREATE TABLE games (
  id BIGSERIAL PRIMARY KEY,
  match_type VARCHAR(20), -- QUEUE, ROOM, PVE
  room_code VARCHAR(6),
  player1_id BIGINT NOT NULL,
  player2_id BIGINT,
  bot_difficulty VARCHAR(20), -- EASY, MEDIUM, HARD
  status VARCHAR(50) DEFAULT 'WAITING',
  started_at TIMESTAMP,
  ended_at TIMESTAMP,
  winner_id BIGINT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (player1_id) REFERENCES users(id),
  FOREIGN KEY (player2_id) REFERENCES users(id),
  FOREIGN KEY (winner_id) REFERENCES users(id)
);

-- Game state snapshots
CREATE TABLE game_state_snapshots (
  id BIGSERIAL PRIMARY KEY,
  game_id BIGINT NOT NULL,
  turn_number INT,
  state_json JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (game_id) REFERENCES games(id)
);

-- Game events
CREATE TABLE game_events (
  id BIGSERIAL PRIMARY KEY,
  game_id BIGINT NOT NULL,
  event_type VARCHAR(50),
  payload JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (game_id) REFERENCES games(id)
);

-- Game chat messages
CREATE TABLE game_chat_messages (
  id BIGSERIAL PRIMARY KEY,
  game_id BIGINT NOT NULL,
  user_id BIGINT,
  username VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  message_type VARCHAR(20) DEFAULT 'USER', -- USER, BOT, SYSTEM
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (game_id) REFERENCES games(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Índices
CREATE INDEX idx_email_verifications_user_id ON email_verifications(user_id);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_cards_set_code ON cards_catalog(set_code);
CREATE INDEX idx_decks_user_id ON decks(user_id);
CREATE INDEX idx_deck_cards_deck_id ON deck_cards(deck_id);
CREATE INDEX idx_user_booster_user_id ON user_booster_packs(user_id);
CREATE INDEX idx_user_booster_opened ON user_booster_packs(opened_at);
CREATE INDEX idx_user_collection_user_id ON user_collection(user_id);
CREATE INDEX idx_payment_records_user_id ON payment_records(user_id);
CREATE INDEX idx_payment_records_status ON payment_records(status);
CREATE INDEX idx_payment_records_mp_transaction ON payment_records(mercado_pago_transaction_id);
CREATE INDEX idx_skill_ratings_rating ON skill_ratings(current_rating);
CREATE INDEX idx_queue_entries_status ON queue_entries(status);
CREATE INDEX idx_queue_entries_skill_rating ON queue_entries(skill_rating);
CREATE INDEX idx_games_match_type ON games(match_type);
CREATE INDEX idx_games_room_code ON games(room_code);
CREATE INDEX idx_games_status ON games(status);
CREATE INDEX idx_game_room_players_room_id ON game_room_players(room_id);
CREATE INDEX idx_game_state_snapshots_game_id ON game_state_snapshots(game_id);
CREATE INDEX idx_game_events_game_id ON game_events(game_id);
CREATE INDEX idx_game_chat_game_id ON game_chat_messages(game_id, created_at);

-- Vistas materializadas
CREATE MATERIALIZED VIEW leaderboard AS
SELECT 
  u.id,
  u.username,
  COALESCE(sr.wins, 0) as wins,
  COALESCE(sr.losses, 0) as losses,
  COALESCE(u.draws, 0) as draws,
  COALESCE(sr.current_rating, 1000) as skill_rating,
  COALESCE(sr.total_games, 0) as total_games,
  CASE 
    WHEN (COALESCE(sr.wins, 0) + COALESCE(sr.losses, 0)) > 0 
    THEN COALESCE(sr.wins, 0)::float / (COALESCE(sr.wins, 0) + COALESCE(sr.losses, 0))
    ELSE 0
  END as win_ratio
FROM users u
LEFT JOIN skill_ratings sr ON u.id = sr.user_id
ORDER BY skill_rating DESC, win_ratio DESC;

CREATE INDEX idx_leaderboard_skill_rating ON leaderboard(skill_rating DESC);
```

---

## Patrones y Best Practices

### 1. Transaccionalidad

```java
@Transactional
public void createGameAndSendNotifications(Long user1Id, Long user2Id) {
  // Se ejecuta TODO o NADA
  Game game = createGame(user1Id, user2Id);
  notifyUsers(user1Id, user2Id);
  // Si falla notifyUsers, rollback de createGame
}
```

### 2. Manejo de excepciones

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
  
  @ExceptionHandler(GameNotFoundException.class)
  public ResponseEntity<?> handleGameNotFound(GameNotFoundException e) {
    return ResponseEntity.status(404).body(Map.of(
      "error", e.getMessage(),
      "code", "GAME_NOT_FOUND"
    ));
  }
  
  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<?> handleValidationErrors(MethodArgumentNotValidException e) {
    Map<String, String> errors = e.getBindingResult().getFieldErrors()
      .stream()
      .collect(Collectors.toMap(
        FieldError::getField,
        FieldError::getDefaultMessage
      ));
    return ResponseEntity.badRequest().body(Map.of("errors", errors));
  }
}
```

### 3. DTOs para request/response

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateGameRequest {
  @NotNull(message = "userId requerido")
  private Long userId;
  
  @NotNull(message = "deckId requerido")
  private Long deckId;
  
  @NotNull(message = "matchType requerido")
  @Pattern(regexp = "QUEUE|ROOM|PVE", message = "matchType inválido")
  private String matchType;
  
  private String roomCode;
  private String botDifficulty;
}

@Data
@Builder
public class GameResponse {
  private Long gameId;
  private String status;
  private List<PlayerDTO> players;
  private LocalDateTime createdAt;
}
```

### 4. Logging

```java
@Slf4j
@Service
public class PaymentService {
  
  public void processPayment(Long userId, BigDecimal amount) {
    log.info("Iniciando pago para usuario {} por ${}", userId, amount);
    
    try {
      // lógica
      log.info("Pago completado para usuario {}", userId);
    } catch (Exception e) {
      log.error("Error en pago para usuario {}: {}", userId, e.getMessage(), e);
      throw e;
    }
  }
}
```

### 5. Caché con Redis

```java
@Service
public class UserService {
  
  @Cacheable(value = "users", key = "#userId")
  public User getUser(Long userId) {
    return userRepo.findById(userId).orElse(null);
  }
  
  @CacheEvict(value = "users", key = "#userId")
  public void updateUser(Long userId, UserDTO dto) {
    // actualizar
  }
}
```

### 6. Async y Scheduled

```java
@Service
public class NotificationService {
  
  @Async
  public void sendEmailAsync(String email, String subject, String body) {
    // No bloquea
  }
  
  @Scheduled(fixedRate = 60000) // Cada 60 segundos
  public void cleanupExpiredSessions() {
    // Tarea periódica
  }
}
```

---

## Conclusión

Este documento cubre los aspectos técnicos principales. Úsalo junto al README principal para darle a una IA clara indicación de **qué hacer**, **cómo hacerlo** y **por qué**.

Fecha: 30/04/2025  
Versión: 1.0
