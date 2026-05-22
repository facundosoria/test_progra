# Backend — Codemon TCG API

Spring Boot 3.x · Java 21 · PostgreSQL · Redis · MinIO · WebSocket STOMP

## Estructura de dominios

```
src/main/java/com/codemon/
├── auth/          ← Autenticación JWT + 2FA por email
├── cards/         ← Catálogo de cartas XY1 (146 cartas)
├── decks/         ← CRUD y validación de mazos (60 cartas, reglas XY1)
├── game/          ← Motor de juego — CRÍTICO (≥90% cobertura de tests)
│   ├── engine/    ← GameEngine: orquestador central
│   ├── rules/     ← RuleValidator: valida cada acción del jugador
│   ├── damage/    ← DamageCalculator: debilidad, resistencia, efectos
│   ├── effects/   ← StatusEffectManager: POISONED, BURNED, ASLEEP, etc.
│   ├── victory/   ← VictoryConditionChecker: premios, mazo vacío, KO total
│   └── bot/       ← BotAgent (EASY/MEDIUM/HARD) + BotChatService
├── lobby/         ← Matchmaking por ELO + salas privadas
├── payment/       ← Mercado Pago + wallet de moneda virtual
├── booster/       ← Sistema de sobres (compra, cooldown 24h, apertura)
├── collection/    ← Colección personal de cartas
├── users/         ← Perfil y estadísticas
├── chat/          ← Mensajes en tiempo real (usuario + bot)
└── shared/        ← Config, excepciones globales, JWT, utils
```

## Desarrollo local (sin Docker completo)

```bash
# Requisitos: Java 21, Maven 3.9+

# 1. Levantar solo la infraestructura necesaria
docker compose up postgres redis minio minio_setup -d

# 2. Correr la API en modo dev
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
# API disponible en http://localhost:8080
# Swagger: http://localhost:8080/swagger-ui.html

# 3. Correr todos los tests
./mvnw test

# 4. Ver reporte de cobertura
./mvnw test jacoco:report
open target/site/jacoco/index.html
```

## Cobertura mínima requerida

| Componente | Cobertura |
|---|---|
| Global | ≥ 80% |
| RuleValidator | ≥ 90% |
| DamageCalculator | ≥ 90% |
| StatusEffectManager | ≥ 90% |
| AuthService | ≥ 85% |
| PaymentService | ≥ 85% |

## Referencias

- [Contratos API](../docs/05-referencia-tecnica/CONTRATOS_API.md)
- [Schema BD](../docs/05-referencia-tecnica/SCHEMA_BD.sql)
- [Motor de juego — Parte 1](../docs/05-referencia-tecnica/GAME_ENGINE_DETALLES.md)
- [Motor de juego — Parte 2](../docs/05-referencia-tecnica/GAME_ENGINE_DETALLES_PARTE2.md)
- [Guía Equipo A](../docs/03-equipos/GUIA_EQUIPO_A.md)
- [Patrones de diseño](../docs/05-referencia-tecnica/PATRONES_DISENO.md)
