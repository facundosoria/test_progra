# Mocks para el Frontend — Codemon TCG

> **Documento del Equipo B.**  
> JSON de ejemplo para cada endpoint de la API. Usar con el `MockInterceptor` de Angular mientras el backend no está disponible.  
> Ver `CONTRATOS_API.md` para la especificación completa de cada endpoint.

## Configuración del MockInterceptor

```typescript
// src/app/core/interceptors/mock.interceptor.ts
import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpResponse } from '@angular/common/http';
import { of, delay } from 'rxjs';
import { MOCKS } from './mocks.data';
import { environment } from '../../../environments/environment';

@Injectable()
export class MockInterceptor implements HttpInterceptor {
  intercept(req: HttpRequest<any>, next: HttpHandler) {
    if (!environment.useMocks) return next.handle(req);

    const key = `${req.method} ${new URL(req.url, 'http://x').pathname}`;
    const mock = MOCKS[key] ?? findByPattern(req, MOCKS);
    if (mock !== undefined) {
      return of(new HttpResponse({ status: mock.status ?? 200, body: mock.body }))
        .pipe(delay(environment.mockDelayMs ?? 300));
    }
    return next.handle(req);
  }
}

function findByPattern(req: HttpRequest<any>, mocks: Record<string, any>) {
  const path = new URL(req.url, 'http://x').pathname;
  for (const [key, val] of Object.entries(mocks)) {
    const [method, pattern] = key.split(' ');
    if (method !== req.method) continue;
    const regex = new RegExp('^' + pattern.replace(/:\w+/g, '[^/]+').replace(/\//g, '\\/') + '$');
    if (regex.test(path)) return val;
  }
  return undefined;
}
```

```typescript
// src/environments/environment.ts
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8080',
  wsUrl: 'ws://localhost:8080/ws',
  useMocks: true,
  mockDelayMs: 300,
};
```

---

## Datos de ejemplo

### Usuarios de prueba
```json
{
  "_users": [
    { "id": 1, "username": "Hernan",   "email": "hernan@codemon.com",   "skillRating": 1450 },
    { "id": 2, "username": "Ramiro",   "email": "ramiro@codemon.com",   "skillRating": 1200 },
    { "id": 3, "username": "Santoro",  "email": "santoro@codemon.com",  "skillRating": 1850 }
  ]
}
```

### Cartas de ejemplo (referencia)
```json
{
  "_sampleCards": [
    { "id": "xy1-1",  "name": "Venusaur-EX",  "supertype": "Pokémon", "rarity": "Ultra Rare",  "types": ["Grass"] },
    { "id": "xy1-11", "name": "Charizard-EX",  "supertype": "Pokémon", "rarity": "Ultra Rare",  "types": ["Fire"] },
    { "id": "xy1-25", "name": "Blastoise-EX",  "supertype": "Pokémon", "rarity": "Ultra Rare",  "types": ["Water"] },
    { "id": "xy1-80", "name": "Professor's Letter", "supertype": "Trainer", "rarity": "Uncommon", "subtypes": ["Item"] },
    { "id": "xy1-96", "name": "Fire Energy",   "supertype": "Energy",  "rarity": "Common",     "subtypes": ["Basic"] },
    { "id": "xy1-97", "name": "Grass Energy",  "supertype": "Energy",  "rarity": "Common",     "subtypes": ["Basic"] },
    { "id": "xy1-98", "name": "Water Energy",  "supertype": "Energy",  "rarity": "Common",     "subtypes": ["Basic"] }
  ]
}
```

---

## Mocks por endpoint

```typescript
// src/app/core/interceptors/mocks.data.ts
export const MOCKS: Record<string, { status?: number; body: any }> = {

  // ─── AUTH ──────────────────────────────────────────────

  'POST /api/auth/login': {
    body: {
      accessToken: 'eyJhbGciOiJIUzI1NiJ9.mock_access_token',
      refreshToken: '550e8400-e29b-41d4-a716-446655440000',
      user: {
        id: 1,
        username: 'Hernan',
        email: 'hernan@codemon.com',
        emailVerified: true,
        virtualCurrencyBalance: 500,
        skillRating: 1450,
        wins: 30,
        losses: 12
      }
    }
  },

  'POST /api/auth/register': {
    status: 201,
    body: { message: 'Registro exitoso. Revisá tu email para verificar tu cuenta.', userId: 4 }
  },

  'POST /api/auth/refresh': {
    body: {
      accessToken: 'eyJhbGciOiJIUzI1NiJ9.mock_new_access_token',
      refreshToken: '550e8400-e29b-41d4-a716-446655440001'
    }
  },

  'POST /api/auth/logout': {
    body: { message: 'Sesión cerrada correctamente.' }
  },

  'GET /api/auth/me': {
    body: {
      id: 1,
      username: 'Hernan',
      email: 'hernan@codemon.com',
      emailVerified: true,
      virtualCurrencyBalance: 500,
      skillRating: 1450,
      wins: 30,
      losses: 12,
      draws: 2,
      createdAt: '2025-01-01T00:00:00Z'
    }
  },

  'POST /api/auth/verify-email': {
    body: { message: 'Email verificado correctamente.' }
  },

  'POST /api/auth/resend-verification': {
    body: { message: 'Código reenviado. Revisá tu email.' }
  },

  // ─── CARDS ─────────────────────────────────────────────

  'GET /api/cards': {
    body: {
      content: [
        {
          id: 'xy1-1', name: 'Venusaur-EX', number: '1', supertype: 'Pokémon',
          subtypes: ['EX'], rarity: 'Ultra Rare', hp: 180, types: ['Grass'],
          evolvesFrom: 'Ivysaur',
          imageSmallUrl: 'https://images.pokemontcg.io/xy1/1.png',
          imageLargeUrl: 'https://images.pokemontcg.io/xy1/1_hires.png',
          attacks: [
            { name: 'Frog Hop', cost: ['Grass', 'Colorless', 'Colorless'],
              convertedEnergyCost: 3, damage: '40+',
              text: 'Flip a coin. If heads, this attack does 40 more damage.' },
            { name: 'Poison Powder', cost: ['Grass', 'Grass', 'Colorless', 'Colorless'],
              convertedEnergyCost: 4, damage: '60',
              text: 'Your opponent\'s Active Pokémon is now Poisoned.' }
          ],
          weaknesses: [{ type: 'Fire', value: '×2' }],
          resistances: [],
          abilities: []
        },
        {
          id: 'xy1-11', name: 'Charizard-EX', number: '11', supertype: 'Pokémon',
          subtypes: ['EX'], rarity: 'Ultra Rare', hp: 180, types: ['Fire'],
          evolvesFrom: 'Charmeleon',
          imageSmallUrl: 'https://images.pokemontcg.io/xy1/11.png',
          imageLargeUrl: 'https://images.pokemontcg.io/xy1/11_hires.png',
          attacks: [
            { name: 'Stoke', cost: ['Fire', 'Colorless', 'Colorless'],
              convertedEnergyCost: 3, damage: '30',
              text: 'Flip a coin. If heads, search your deck for up to 3 Fire Energy cards.' },
            { name: 'Combustion Blast', cost: ['Fire', 'Fire', 'Colorless', 'Colorless', 'Colorless'],
              convertedEnergyCost: 5, damage: '250',
              text: 'This Pokémon can\'t use Combustion Blast during your next turn.' }
          ],
          weaknesses: [{ type: 'Water', value: '×2' }],
          resistances: [],
          abilities: []
        }
      ],
      totalElements: 146,
      totalPages: 8,
      size: 20,
      number: 0,
      first: true,
      last: false
    }
  },

  'GET /api/cards/:id': {
    body: {
      id: 'xy1-11', name: 'Charizard-EX', number: '11', supertype: 'Pokémon',
      subtypes: ['EX'], rarity: 'Ultra Rare', hp: 180, types: ['Fire'],
      evolvesFrom: 'Charmeleon',
      imageSmallUrl: 'https://images.pokemontcg.io/xy1/11.png',
      imageLargeUrl: 'https://images.pokemontcg.io/xy1/11_hires.png',
      attacks: [
        { name: 'Stoke', cost: ['Fire', 'Colorless', 'Colorless'], convertedEnergyCost: 3,
          damage: '30', text: 'Flip a coin...' }
      ],
      weaknesses: [{ type: 'Water', value: '×2' }],
      resistances: [],
      abilities: []
    }
  },

  // ─── DECKS ─────────────────────────────────────────────

  'GET /api/decks': {
    body: [
      { id: 1, name: 'Mazo Fuego Agresivo', description: 'Charizard-EX principal',
        isFavorite: true, isStarter: false, cardCount: 60,
        createdAt: '2025-01-15T10:00:00Z', updatedAt: '2025-01-20T15:00:00Z' },
      { id: 2, name: 'Control Agua', description: 'Blastoise-EX con mucho draw',
        isFavorite: false, isStarter: false, cardCount: 60,
        createdAt: '2025-01-18T09:00:00Z', updatedAt: '2025-01-18T09:00:00Z' }
    ]
  },

  'GET /api/decks/:id': {
    body: {
      id: 1, name: 'Mazo Fuego Agresivo', description: 'Charizard-EX principal',
      isFavorite: true, isStarter: false,
      cards: [
        { card: { id: 'xy1-11', name: 'Charizard-EX', supertype: 'Pokémon',
                  hp: 180, types: ['Fire'], imageSmallUrl: 'https://images.pokemontcg.io/xy1/11.png' },
          quantity: 2 },
        { card: { id: 'xy1-96', name: 'Fire Energy', supertype: 'Energy',
                  imageSmallUrl: 'https://images.pokemontcg.io/xy1/96.png' },
          quantity: 14 }
      ],
      isValid: true,
      validationErrors: [],
      createdAt: '2025-01-15T10:00:00Z'
    }
  },

  'POST /api/decks': {
    status: 201,
    body: {
      id: 3, name: 'Nuevo Mazo', description: '',
      isFavorite: false, isStarter: false, cards: [], isValid: false,
      validationErrors: ['El mazo debe contener exactamente 60 cartas (tiene 0)'],
      createdAt: new Date().toISOString()
    }
  },

  'PUT /api/decks/:id': {
    body: {
      id: 1, name: 'Mazo Fuego Agresivo (actualizado)', isValid: true,
      validationErrors: [], updatedAt: new Date().toISOString()
    }
  },

  'DELETE /api/decks/:id': { status: 204, body: null },

  'POST /api/decks/:id/validate': {
    body: { valid: true, errors: [] }
  },

  'GET /api/decks/starter': {
    body: [
      { id: 10, name: 'Starter Fuego', isStarter: true, cardCount: 60 },
      { id: 11, name: 'Starter Agua', isStarter: true, cardCount: 60 },
      { id: 12, name: 'Starter Planta', isStarter: true, cardCount: 60 }
    ]
  },

  // ─── GAMES ─────────────────────────────────────────────

  'POST /api/games/pve': {
    status: 201,
    body: {
      gameId: '550e8400-e29b-41d4-a716-446655440001',
      status: 'SETUP',
      webSocketTopic: '/topic/game/550e8400-e29b-41d4-a716-446655440001'
    }
  },

  // ─── ROOMS ─────────────────────────────────────────────

  'POST /api/rooms': {
    status: 201,
    body: {
      roomCode: 'ABC123',
      creatorId: 1,
      status: 'WAITING',
      expiresAt: new Date(Date.now() + 10 * 60 * 1000).toISOString()
    }
  },

  'GET /api/rooms/:code': {
    body: {
      roomCode: 'ABC123',
      status: 'WAITING',
      players: [{ userId: 1, username: 'Hernan', ready: true }],
      expiresAt: new Date(Date.now() + 8 * 60 * 1000).toISOString()
    }
  },

  'POST /api/rooms/:code/join': {
    body: {
      roomCode: 'ABC123',
      status: 'ACTIVE',
      players: [
        { userId: 1, username: 'Hernan', ready: true },
        { userId: 2, username: 'Ramiro', ready: true }
      ]
    }
  },

  'DELETE /api/rooms/:code': { status: 204, body: null },

  // ─── MATCHMAKING ───────────────────────────────────────

  'POST /api/matchmaking/queue': {
    body: { status: 'QUEUED', queuePosition: null, estimatedWaitSeconds: null }
  },

  'DELETE /api/matchmaking/queue': {
    body: { status: 'CANCELLED' }
  },

  'GET /api/matchmaking/status': {
    body: { status: 'WAITING', joinedAt: new Date().toISOString() }
  },

  // ─── COLLECTION ────────────────────────────────────────

  'GET /api/collection': {
    body: {
      content: [
        { card: { id: 'xy1-1', name: 'Venusaur-EX', rarity: 'Ultra Rare',
                  imageSmallUrl: 'https://images.pokemontcg.io/xy1/1.png' },
          quantity: 1, obtainedDate: '2025-01-15T10:00:00Z' },
        { card: { id: 'xy1-11', name: 'Charizard-EX', rarity: 'Ultra Rare',
                  imageSmallUrl: 'https://images.pokemontcg.io/xy1/11.png' },
          quantity: 2, obtainedDate: '2025-01-16T14:00:00Z' }
      ],
      totalElements: 50, totalPages: 3, size: 20, number: 0
    }
  },

  'GET /api/collection/stats': {
    body: {
      uniqueCards: 50, totalCards: 120,
      commonCount: 40, uncommonCount: 30, rareCount: 20,
      ultraRareCount: 8, secretRareCount: 2,
      completionPercentage: 34.2
    }
  },

  // ─── BOOSTERS ──────────────────────────────────────────

  'GET /api/boosters': {
    body: [
      { id: 1, name: 'Sobre XY Kalos Starter Set', description: '10 cartas del set XY1',
        priceUsd: 3.99, priceCoins: 100, cardsPerPack: 10,
        imageUrl: 'https://images.pokemontcg.io/xy1/logo.png' }
    ]
  },

  'POST /api/boosters/:id/purchase': {
    status: 201,
    body: {
      purchaseId: 5,
      cards: [
        { id: 'xy1-11', name: 'Charizard-EX', rarity: 'Ultra Rare',
          imageSmallUrl: 'https://images.pokemontcg.io/xy1/11.png', isNew: true },
        { id: 'xy1-96', name: 'Fire Energy', rarity: 'Common',
          imageSmallUrl: 'https://images.pokemontcg.io/xy1/96.png', isNew: false }
      ],
      remainingCoins: 400
    }
  },

  // ─── LEADERBOARD ───────────────────────────────────────

  'GET /api/leaderboard': {
    body: {
      content: [
        { rank: 1, userId: 3, username: 'Santoro', skillRating: 1850,
          peakRating: 1900, wins: 45, losses: 10, winPercentage: 81.8 },
        { rank: 2, userId: 1, username: 'Hernan', skillRating: 1450,
          peakRating: 1500, wins: 30, losses: 12, winPercentage: 71.4 },
        { rank: 3, userId: 2, username: 'Ramiro', skillRating: 1200,
          peakRating: 1250, wins: 20, losses: 15, winPercentage: 57.1 }
      ],
      totalElements: 250, totalPages: 13, size: 20, number: 0,
      currentUserRank: 2
    }
  },

  // ─── NEWS ──────────────────────────────────────────────

  'GET /api/news': {
    body: {
      content: [
        { id: 1, title: 'Nuevas cartas del set XY2 disponibles pronto',
          content: 'A partir del próximo viernes podrán encontrar las cartas del set XY2...',
          category: 'UPDATE',
          author: { id: 1, username: 'admin' },
          publishedAt: '2025-01-20T12:00:00Z' },
        { id: 2, title: 'Torneo de Año Nuevo — Inscripciones abiertas',
          content: 'Este fin de semana se realizará el torneo de Año Nuevo...',
          category: 'EVENT',
          author: { id: 1, username: 'admin' },
          publishedAt: '2025-01-18T09:00:00Z' }
      ],
      totalElements: 15, totalPages: 2
    }
  },

  'GET /api/news/:id': {
    body: {
      id: 1, title: 'Nuevas cartas del set XY2 disponibles pronto',
      content: 'A partir del próximo viernes...',
      category: 'UPDATE',
      author: { id: 1, username: 'admin' },
      publishedAt: '2025-01-20T12:00:00Z'
    }
  },

  // ─── FRIENDS ───────────────────────────────────────────

  'GET /api/friends': {
    body: [
      { friendshipId: 1,
        friend: { id: 2, username: 'Ramiro', skillRating: 1200, online: true },
        since: '2025-01-10T09:00:00Z' }
    ]
  },

  'GET /api/friends/requests': {
    body: {
      received: [
        { friendshipId: 5,
          from: { id: 3, username: 'Santoro', skillRating: 1850 },
          sentAt: '2025-01-19T14:00:00Z' }
      ],
      sent: []
    }
  },

  'POST /api/friends/request': {
    status: 201,
    body: { friendshipId: 6, status: 'PENDING' }
  },

  'PUT /api/friends/:friendshipId/accept': {
    body: { status: 'ACCEPTED' }
  },

  'PUT /api/friends/:friendshipId/reject': {
    body: { status: 'REJECTED' }
  },

  'DELETE /api/friends/:friendshipId': { status: 204, body: null },

  // ─── USERS ─────────────────────────────────────────────

  'GET /api/users/:id/profile': {
    body: {
      id: 2, username: 'Ramiro', skillRating: 1200,
      wins: 20, losses: 15, draws: 2, totalGames: 37,
      winPercentage: 54.1, createdAt: '2025-01-01T00:00:00Z'
    }
  },

  'PUT /api/users/profile': {
    body: { id: 1, username: 'HernanNuevo', updatedAt: new Date().toISOString() }
  },

};
```

---

## Activar y desactivar mocks

### Activar mocks (por defecto en desarrollo)
```typescript
// src/environments/environment.ts
export const environment = {
  useMocks: true,
  mockDelayMs: 300,  // simula latencia de red
  ...
};
```

### Desactivar mocks endpoint por endpoint
```typescript
// En mocks.data.ts, simplemente eliminar la entrada del endpoint real
// o usar el flag environment.useMocks = false para desactivar todo
```

### Simular errores
```typescript
// Agregar temporalmente en mocks.data.ts:
'POST /api/auth/login': {
  status: 401,
  body: { error: 'INVALID_CREDENTIALS', message: 'Usuario o contraseña incorrectos' }
},
```

---

## Eventos WebSocket de ejemplo

Para simular el cliente WebSocket del tablero durante el desarrollo del Equipo B, usar este helper:

```typescript
// src/app/game/services/mock-game-events.service.ts
// Solo para pruebas durante el desarrollo del tablero

import { Observable, of, interval } from 'rxjs';
import { map, take } from 'rxjs/operators';

export function getMockGameEvents(): GameEvent[] {
  return [
    {
      type: 'GAME_START',
      gameId: '550e8400-e29b-41d4-a716-446655440001',
      timestamp: new Date().toISOString(),
      payload: {
        players: [{ id: 1, username: 'Hernan' }, { id: 2, username: 'Bot-EASY' }],
        deckSizes: { '1': 54, '2': 54 },
        firstPlayerId: 1
      }
    },
    {
      type: 'TURN_START',
      gameId: '550e8400-e29b-41d4-a716-446655440001',
      timestamp: new Date().toISOString(),
      payload: { playerId: 1, turnNumber: 1 }
    },
    {
      type: 'POKEMON_PLAYED',
      gameId: '550e8400-e29b-41d4-a716-446655440001',
      timestamp: new Date().toISOString(),
      payload: { playerId: 1, cardId: 'xy1-11', zone: 'ACTIVE' }
    },
    {
      type: 'ATTACK_DECLARED',
      gameId: '550e8400-e29b-41d4-a716-446655440001',
      timestamp: new Date().toISOString(),
      payload: {
        attackerId: 'xy1-11', attackerPlayerId: 1,
        defenderId: 'xy1-25', defenderPlayerId: 2,
        attackName: 'Combustion Blast'
      }
    },
    {
      type: 'DAMAGE_DEALT',
      gameId: '550e8400-e29b-41d4-a716-446655440001',
      timestamp: new Date().toISOString(),
      payload: {
        attackerId: 'xy1-11', defenderId: 'xy1-25',
        baseDamage: 250, weaknessApplied: false, resistanceApplied: false,
        finalDamage: 250, defenderCurrentHp: 0, defenderMaxHp: 180
      }
    },
    {
      type: 'POKEMON_KO',
      gameId: '550e8400-e29b-41d4-a716-446655440001',
      timestamp: new Date().toISOString(),
      payload: { pokemonId: 'xy1-25', ownerId: 2, prizesToTake: 2 }
    },
    {
      type: 'PRIZE_TAKEN',
      gameId: '550e8400-e29b-41d4-a716-446655440001',
      timestamp: new Date().toISOString(),
      payload: { playerId: 1, count: 2, prizesRemaining: 4 }
    }
  ];
}
```
