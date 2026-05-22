-- ══════════════════════════════════════════════════════════════
-- CODEMON TCG - SCHEMA COMPLETO DE BASE DE DATOS
-- PostgreSQL 16 | Flyway migrations
-- Generado a partir del card.json real (146 cartas, set XY1)
-- ══════════════════════════════════════════════════════════════


-- ┌──────────────────────────────────────────────────────────┐
-- │  V1: USUARIOS Y AUTENTICACIÓN                            │
-- └──────────────────────────────────────────────────────────┘

CREATE TABLE users (
    id                       BIGSERIAL PRIMARY KEY,
    username                 VARCHAR(50) UNIQUE NOT NULL,
    email                    VARCHAR(100) UNIQUE NOT NULL,
    password_hash            VARCHAR(255) NOT NULL,
    email_verified           BOOLEAN DEFAULT FALSE NOT NULL,
    virtual_currency_balance BIGINT DEFAULT 0 NOT NULL,
    skill_rating             INT DEFAULT 1000 NOT NULL,
    wins                     INT DEFAULT 0 NOT NULL,
    losses                   INT DEFAULT 0 NOT NULL,
    draws                    INT DEFAULT 0 NOT NULL,
    created_at               TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at               TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX idx_users_email        ON users(email);
CREATE INDEX idx_users_username     ON users(username);
CREATE INDEX idx_users_skill_rating ON users(skill_rating DESC);

CREATE TABLE refresh_tokens (
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    revoked_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_refresh_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_rt_user_id    ON refresh_tokens(user_id);
CREATE INDEX idx_rt_token_hash ON refresh_tokens(token_hash);


-- ┌──────────────────────────────────────────────────────────┐
-- │  V2: VERIFICACIÓN 2FA POR EMAIL                          │
-- └──────────────────────────────────────────────────────────┘

CREATE TABLE email_verifications (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT UNIQUE NOT NULL,
    code_hash       VARCHAR(255) NOT NULL,
    code_expires_at TIMESTAMP NOT NULL,
    attempts_count  INT DEFAULT 0 NOT NULL,
    blocked_until   TIMESTAMP,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_emailverif_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_ev_user_id ON email_verifications(user_id);


-- ┌──────────────────────────────────────────────────────────┐
-- │  V3: CATÁLOGO DE CARTAS                                  │
-- │  Basado en card.json real: 146 cartas, set XY1           │
-- │                                                          │
-- │  Campos del JSON:                                        │
-- │    id, name, supertype, subtypes[], hp, types[],         │
-- │    evolvesFrom, evolvesTo[], rules[], attacks[],         │
-- │    weaknesses[], resistances[], retreatCost[],           │
-- │    convertedRetreatCost, number, artist, rarity,         │
-- │    flavorText, nationalPokedexNumbers[], abilities[],    │
-- │    legalities{}, images{small, large}                    │
-- │                                                          │
-- │  Supertypes:  Pokémon, Trainer, Energy                   │
-- │  Subtypes:    Basic, Stage 1, Stage 2, EX, MEGA,        │
-- │               Item, Supporter, Stadium,                  │
-- │               Pokémon Tool, Special                      │
-- │  Rarities:    Common, Uncommon, Rare, Rare Holo,        │
-- │               Rare Holo EX, Rare Ultra                   │
-- │  Types:       Grass, Fire, Water, Lightning, Psychic,   │
-- │               Fighting, Darkness, Metal, Fairy,          │
-- │               Colorless                                  │
-- └──────────────────────────────────────────────────────────┘

CREATE TABLE cards_catalog (
    -- Identificación (del JSON)
    id                       VARCHAR(20) PRIMARY KEY,    -- "xy1-1"
    name                     VARCHAR(255) NOT NULL,       -- "Venusaur-EX"
    number                   VARCHAR(10) NOT NULL,        -- "1"

    -- Clasificación
    supertype                VARCHAR(20) NOT NULL,        -- "Pokémon" | "Trainer" | "Energy"
    subtypes                 TEXT[] DEFAULT '{}',         -- {"Basic","EX"} | {"Supporter"} | {"Special"}
    rarity                   VARCHAR(30),                 -- "Common" | "Uncommon" | "Rare" | "Rare Holo" | "Rare Holo EX" | "Rare Ultra"

    -- Stats de Pokémon (NULL si Trainer o Energy)
    hp                       INT,                         -- 180 (viene como string en JSON, convertir)
    types                    TEXT[] DEFAULT '{}',         -- {"Grass"} | {"Fire","Water"}
    evolves_from             VARCHAR(255),                -- "Weedle" (NULL si no evoluciona de nada)
    evolves_to               TEXT[] DEFAULT '{}',         -- {"Kakuna"} (vacío si no evoluciona)
    converted_retreat_cost   INT,                         -- 4 (NULL si Trainer/Energy)
    retreat_cost             TEXT[] DEFAULT '{}',         -- {"Colorless","Colorless","Colorless","Colorless"}

    -- Datos complejos → JSONB
    -- Cada attack: {name, cost[], convertedEnergyCost, damage, text}
    attacks                  JSONB DEFAULT '[]'::jsonb,

    -- Cada weakness: {type, value}  ej: {"type":"Fire","value":"×2"}
    weaknesses               JSONB DEFAULT '[]'::jsonb,

    -- Cada resistance: {type, value}  ej: {"type":"Fighting","value":"-20"}
    resistances              JSONB DEFAULT '[]'::jsonb,

    -- Cada ability: {name, text, type}  ej: {"name":"Spiky Shield","text":"...","type":"Ability"}
    abilities                JSONB DEFAULT '[]'::jsonb,

    -- Reglas especiales (ej: "Pokémon-EX rule: When a Pokémon-EX has been Knocked Out...")
    rules                    JSONB DEFAULT '[]'::jsonb,

    -- Legalidades: {"unlimited":"Legal","expanded":"Legal"}
    legalities               JSONB DEFAULT '{}'::jsonb,

    -- Imágenes → URLs a MinIO (NO a pokemontcg.io)
    image_small_url          VARCHAR(500),
    image_large_url          VARCHAR(500),

    -- Metadata
    artist                   VARCHAR(255),
    flavor_text              TEXT,
    national_pokedex_numbers INT[] DEFAULT '{}',

    created_at               TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT chk_supertype CHECK (supertype IN ('Pokémon','Trainer','Energy'))
);

-- Índices para búsquedas del catálogo
CREATE INDEX idx_cards_supertype ON cards_catalog(supertype);
CREATE INDEX idx_cards_rarity    ON cards_catalog(rarity);
CREATE INDEX idx_cards_name_search ON cards_catalog USING gin(to_tsvector('english', name));
CREATE INDEX idx_cards_types     ON cards_catalog USING gin(types);
CREATE INDEX idx_cards_subtypes  ON cards_catalog USING gin(subtypes);


-- ┌──────────────────────────────────────────────────────────┐
-- │  V4: MAZOS                                               │
-- │  Los usuarios arman mazos con cartas del catálogo        │
-- │  También existen starter decks pre-armados del sistema   │
-- └──────────────────────────────────────────────────────────┘

CREATE TABLE decks (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT,                             -- NULL para starter decks del sistema
    name        VARCHAR(255) NOT NULL,
    description TEXT,
    is_favorite BOOLEAN DEFAULT FALSE NOT NULL,
    is_starter  BOOLEAN DEFAULT FALSE NOT NULL,      -- TRUE = mazo del sistema
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_decks_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_decks_user_id ON decks(user_id);
CREATE INDEX idx_decks_starter ON decks(is_starter);

-- Cartas dentro de un mazo (muchos a muchos con cantidad)
CREATE TABLE deck_cards (
    id       BIGSERIAL PRIMARY KEY,
    deck_id  BIGINT NOT NULL,
    card_id  VARCHAR(20) NOT NULL,
    quantity INT DEFAULT 1 NOT NULL,
    CONSTRAINT fk_dc_deck FOREIGN KEY (deck_id)
        REFERENCES decks(id) ON DELETE CASCADE,
    CONSTRAINT fk_dc_card FOREIGN KEY (card_id)
        REFERENCES cards_catalog(id) ON DELETE RESTRICT,
    CONSTRAINT uq_deck_card UNIQUE (deck_id, card_id),
    CONSTRAINT chk_dc_qty CHECK (quantity >= 1 AND quantity <= 60)
);

CREATE INDEX idx_dc_deck_id ON deck_cards(deck_id);


-- ┌──────────────────────────────────────────────────────────┐
-- │  V5: SOBRES (BOOSTER PACKS) Y COLECCIÓN                 │
-- └──────────────────────────────────────────────────────────┘

-- Definición de tipos de sobres que existen en la tienda
CREATE TABLE booster_packs (
    id                  BIGSERIAL PRIMARY KEY,
    name                VARCHAR(255) NOT NULL,
    description         TEXT,
    price_usd           DECIMAL(10,2) NOT NULL,
    price_coins         BIGINT NOT NULL,
    cards_per_pack      INT DEFAULT 10 NOT NULL,
    rarity_distribution JSONB NOT NULL,
    -- Ejemplo: {"COMMON":60,"UNCOMMON":25,"RARE":10,"RARE_HOLO":3,"RARE_HOLO_EX":2}
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Qué cartas pueden salir de cada tipo de sobre
CREATE TABLE booster_pack_cards (
    id              BIGSERIAL PRIMARY KEY,
    booster_pack_id BIGINT NOT NULL,
    card_id         VARCHAR(20) NOT NULL,
    rarity          VARCHAR(30) NOT NULL,
    CONSTRAINT fk_bpc_pack FOREIGN KEY (booster_pack_id)
        REFERENCES booster_packs(id) ON DELETE CASCADE,
    CONSTRAINT fk_bpc_card FOREIGN KEY (card_id)
        REFERENCES cards_catalog(id) ON DELETE RESTRICT
);

CREATE INDEX idx_bpc_pack_rarity ON booster_pack_cards(booster_pack_id, rarity);

-- Sobres que posee cada usuario (comprados o gratis)
CREATE TABLE user_booster_packs (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL,
    booster_pack_id BIGINT NOT NULL,
    obtained_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    opened_at       TIMESTAMP,              -- NULL si no abrió todavía
    obtained_from   VARCHAR(50),            -- 'PURCHASE' | 'DAILY' | 'REWARD'
    CONSTRAINT fk_ubp_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_ubp_pack FOREIGN KEY (booster_pack_id)
        REFERENCES booster_packs(id) ON DELETE RESTRICT
);

CREATE INDEX idx_ubp_user ON user_booster_packs(user_id);

-- Cartas que coleccionó el usuario (salen de sobres)
CREATE TABLE user_collection (
    id            BIGSERIAL PRIMARY KEY,
    user_id       BIGINT NOT NULL,
    card_id       VARCHAR(20) NOT NULL,
    quantity      INT DEFAULT 1 NOT NULL,
    obtained_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_uc_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_uc_card FOREIGN KEY (card_id)
        REFERENCES cards_catalog(id) ON DELETE RESTRICT,
    CONSTRAINT uq_user_card UNIQUE (user_id, card_id),
    CONSTRAINT chk_uc_qty CHECK (quantity > 0)
);

CREATE INDEX idx_uc_user ON user_collection(user_id);


-- ┌──────────────────────────────────────────────────────────┐
-- │  V6: PAGOS (MERCADO PAGO)                                │
-- └──────────────────────────────────────────────────────────┘

CREATE TABLE payment_records (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT NOT NULL,
    amount_usd          DECIMAL(10,2) NOT NULL,
    amount_coins        BIGINT NOT NULL,
    mp_preference_id    VARCHAR(255),
    mp_transaction_id   VARCHAR(255),
    status              VARCHAR(20) DEFAULT 'PENDING' NOT NULL,
    booster_pack_id     BIGINT,
    quantity            INT DEFAULT 1 NOT NULL,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    completed_at        TIMESTAMP,
    webhook_received_at TIMESTAMP,
    CONSTRAINT fk_pay_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_pay_pack FOREIGN KEY (booster_pack_id)
        REFERENCES booster_packs(id) ON DELETE RESTRICT,
    CONSTRAINT uq_mp_txn UNIQUE (mp_transaction_id),
    CONSTRAINT chk_pay_status CHECK (status IN ('PENDING','COMPLETED','FAILED','CANCELLED'))
);

CREATE INDEX idx_pay_user   ON payment_records(user_id);
CREATE INDEX idx_pay_status ON payment_records(status);

-- Log de webhooks de Mercado Pago (para idempotencia)
CREATE TABLE payment_webhooks_log (
    id           BIGSERIAL PRIMARY KEY,
    mp_event_id  VARCHAR(255) UNIQUE NOT NULL,
    payload      JSONB NOT NULL,
    processed    BOOLEAN DEFAULT FALSE NOT NULL,
    processed_at TIMESTAMP,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX idx_wh_event ON payment_webhooks_log(mp_event_id);


-- ┌──────────────────────────────────────────────────────────┐
-- │  V6.5: AUDITORÍA DE MONEDA VIRTUAL (WALLET)              │
-- └──────────────────────────────────────────────────────────┘

-- Toda mutación de users.virtual_currency_balance debe registrar una fila aquí.
-- Reglas: (a) la fila se inserta en la MISMA transacción que actualiza el balance;
--         (b) balance_after = users.virtual_currency_balance posterior al UPDATE;
--         (c) la suma de delta para un user_id debe coincidir con el balance actual.
CREATE TABLE wallet_transactions (
    id            BIGSERIAL PRIMARY KEY,
    user_id       BIGINT NOT NULL,
    delta         BIGINT NOT NULL,            -- positivo=crédito, negativo=débito
    reason        VARCHAR(30) NOT NULL,       -- ver chk_wt_reason
    ref_table     VARCHAR(40),                -- p.ej. 'payment_records', 'games', 'booster_packs'
    ref_id        BIGINT,                     -- FK lógica al registro origen
    balance_after BIGINT NOT NULL,            -- snapshot del balance tras la transacción
    description   TEXT,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_wt_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT chk_wt_reason CHECK (reason IN (
        'PURCHASE','PACK_PURCHASE','MATCH_REWARD','DAILY_REWARD',
        'PROMO','REFUND','ADMIN_ADJUST'
    )),
    CONSTRAINT chk_wt_delta_nonzero CHECK (delta <> 0),
    CONSTRAINT chk_wt_balance_nonneg CHECK (balance_after >= 0)
);

CREATE INDEX idx_wt_user_created ON wallet_transactions(user_id, created_at DESC);
CREATE INDEX idx_wt_reason       ON wallet_transactions(reason);
CREATE INDEX idx_wt_ref          ON wallet_transactions(ref_table, ref_id) WHERE ref_table IS NOT NULL;


-- ┌──────────────────────────────────────────────────────────┐
-- │  V7: MATCHMAKING Y SKILL RATINGS                         │
-- └──────────────────────────────────────────────────────────┘

CREATE TABLE skill_ratings (
    id             BIGSERIAL PRIMARY KEY,
    user_id        BIGINT UNIQUE NOT NULL,
    current_rating INT DEFAULT 1000 NOT NULL,
    peak_rating    INT DEFAULT 1000 NOT NULL,
    wins           INT DEFAULT 0 NOT NULL,
    losses         INT DEFAULT 0 NOT NULL,
    total_games    INT DEFAULT 0 NOT NULL,
    updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_sr_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_sr_rating ON skill_ratings(current_rating DESC);

-- Cola de matchmaking
CREATE TABLE queue_entries (
    id           BIGSERIAL PRIMARY KEY,
    user_id      BIGINT NOT NULL,
    deck_id      BIGINT NOT NULL,
    skill_rating INT NOT NULL,
    join_time    TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status       VARCHAR(20) DEFAULT 'WAITING' NOT NULL,
    CONSTRAINT fk_qe_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_qe_deck FOREIGN KEY (deck_id)
        REFERENCES decks(id) ON DELETE RESTRICT,
    CONSTRAINT chk_qe_status CHECK (status IN ('WAITING','MATCHED','CANCELLED','TIMEOUT'))
);

CREATE INDEX idx_qe_status ON queue_entries(status);
CREATE INDEX idx_qe_user_status ON queue_entries(user_id, status);
CREATE INDEX idx_qe_skill ON queue_entries(skill_rating);


-- ┌──────────────────────────────────────────────────────────┐
-- │  V8: SALAS PRIVADAS                                      │
-- └──────────────────────────────────────────────────────────┘

CREATE TABLE game_rooms (
    id          BIGSERIAL PRIMARY KEY,
    creator_id  BIGINT NOT NULL,
    room_code   VARCHAR(6) UNIQUE NOT NULL,
    status      VARCHAR(20) DEFAULT 'WAITING' NOT NULL,
    max_players INT DEFAULT 2 NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at  TIMESTAMP NOT NULL,
    CONSTRAINT fk_gr_creator FOREIGN KEY (creator_id)
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_gr_status CHECK (status IN ('WAITING','ACTIVE','FINISHED','EXPIRED'))
);

CREATE INDEX idx_gr_code   ON game_rooms(room_code);
CREATE INDEX idx_gr_status ON game_rooms(status);

CREATE TABLE game_room_players (
    id        BIGSERIAL PRIMARY KEY,
    room_id   BIGINT NOT NULL,
    user_id   BIGINT NOT NULL,
    deck_id   BIGINT NOT NULL,
    join_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_grp_room FOREIGN KEY (room_id)
        REFERENCES game_rooms(id) ON DELETE CASCADE,
    CONSTRAINT fk_grp_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_grp_deck FOREIGN KEY (deck_id)
        REFERENCES decks(id) ON DELETE RESTRICT,
    CONSTRAINT uq_grp_room_user UNIQUE (room_id, user_id)
);

CREATE INDEX idx_grp_room ON game_room_players(room_id);


-- ┌──────────────────────────────────────────────────────────┐
-- │  V9: PARTIDAS                                            │
-- └──────────────────────────────────────────────────────────┘

CREATE TABLE games (
    id                     BIGSERIAL PRIMARY KEY,
    match_type             VARCHAR(10) NOT NULL,         -- QUEUE | ROOM | PVE
    room_code              VARCHAR(6),                   -- solo si ROOM

    player1_id             BIGINT NOT NULL,
    player1_deck_id        BIGINT NOT NULL,
    player2_id             BIGINT,                       -- NULL si PVE
    player2_deck_id        BIGINT,                       -- NULL si PVE (bot usa mazo generado)

    bot_difficulty          VARCHAR(10),                  -- EASY | MEDIUM | HARD (solo PVE)
    bot_personality         VARCHAR(10),                  -- HERNAN | SANTORO | RAMIRO (solo PVE)

    status                 VARCHAR(15) DEFAULT 'WAITING' NOT NULL,
    current_turn_player_id BIGINT,
    turn_number            INT DEFAULT 0 NOT NULL,

    winner_id              BIGINT,
    end_reason             VARCHAR(20),                  -- PRIZES | DECK_EMPTY | NO_POKEMON | SUDDEN_DEATH | CONCEDED | TIMEOUT | DISCONNECTED (ver 07-edge-cases.md)
    consecutive_timeouts_p1 INT DEFAULT 0 NOT NULL,      -- contador para R-TIMEOUT-03 (player1)
    consecutive_timeouts_p2 INT DEFAULT 0 NOT NULL,      -- contador para R-TIMEOUT-03 (player2)
    next_timeout_at        TIMESTAMP,                    -- usado por job @Scheduled de turn timer
    disconnected_player_id BIGINT,                       -- jugador actualmente desconectado (NULL si ambos conectados)
    disconnect_started_at  TIMESTAMP,                    -- inicio de la ventana de reconexión (90 s; R-RECONNECT-01)

    started_at             TIMESTAMP,
    ended_at               TIMESTAMP,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT fk_g_p1      FOREIGN KEY (player1_id)             REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_g_p1_deck FOREIGN KEY (player1_deck_id)        REFERENCES decks(id) ON DELETE RESTRICT,
    CONSTRAINT fk_g_p2      FOREIGN KEY (player2_id)             REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_g_p2_deck FOREIGN KEY (player2_deck_id)        REFERENCES decks(id) ON DELETE RESTRICT,
    CONSTRAINT fk_g_winner  FOREIGN KEY (winner_id)              REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_g_disc    FOREIGN KEY (disconnected_player_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT chk_g_match  CHECK (match_type IN ('QUEUE','ROOM','PVE')),
    CONSTRAINT chk_g_status CHECK (status IN ('WAITING','SETUP','ACTIVE','FINISHED','ABANDONED')),
    CONSTRAINT chk_g_bot    CHECK (bot_difficulty IS NULL OR bot_difficulty IN ('EASY','MEDIUM','HARD')),
    CONSTRAINT chk_g_pers   CHECK (bot_personality IS NULL OR bot_personality IN ('HERNAN','SANTORO','RAMIRO')),
    CONSTRAINT chk_g_reason CHECK (end_reason IS NULL OR end_reason IN ('PRIZES','DECK_EMPTY','NO_POKEMON','SUDDEN_DEATH','CONCEDED','TIMEOUT','DISCONNECTED'))
);

CREATE INDEX idx_g_p1            ON games(player1_id);
CREATE INDEX idx_g_p2            ON games(player2_id);
CREATE INDEX idx_g_status        ON games(status);
CREATE INDEX idx_g_type          ON games(match_type);
CREATE INDEX idx_g_next_timeout  ON games(next_timeout_at) WHERE status = 'ACTIVE' AND next_timeout_at IS NOT NULL;
CREATE INDEX idx_g_disconnect    ON games(disconnect_started_at) WHERE disconnect_started_at IS NOT NULL;
CREATE INDEX idx_g_end_reason    ON games(end_reason) WHERE end_reason IS NOT NULL;
-- Historial por jugador (perfil, recentGames de EPIC-09): partial index sobre estados terminales
CREATE INDEX idx_g_p1_history    ON games(player1_id, status, ended_at DESC)
    WHERE status IN ('FINISHED','ABANDONED');
CREATE INDEX idx_g_p2_history    ON games(player2_id, status, ended_at DESC)
    WHERE status IN ('FINISHED','ABANDONED');

-- Estado completo del tablero serializado después de cada acción importante
CREATE TABLE game_state_snapshots (
    id          BIGSERIAL PRIMARY KEY,
    game_id     BIGINT NOT NULL,
    turn_number INT NOT NULL,
    state_json  JSONB NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_ss_game FOREIGN KEY (game_id)
        REFERENCES games(id) ON DELETE CASCADE
);

CREATE INDEX idx_ss_game      ON game_state_snapshots(game_id);
CREATE INDEX idx_ss_game_turn ON game_state_snapshots(game_id, turn_number);

-- Historial de eventos de la partida
CREATE TABLE game_events (
    id         BIGSERIAL PRIMARY KEY,
    game_id    BIGINT NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    payload    JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_ge_game FOREIGN KEY (game_id)
        REFERENCES games(id) ON DELETE CASCADE
);

CREATE INDEX idx_ge_game      ON game_events(game_id);
-- Filtrado de eventos por tipo dentro de una partida (replays, analytics)
CREATE INDEX idx_ge_game_type ON game_events(game_id, event_type);


-- ┌──────────────────────────────────────────────────────────┐
-- │  V10: CHAT DE PARTIDAS                                   │
-- └──────────────────────────────────────────────────────────┘

CREATE TABLE game_chat_messages (
    id           BIGSERIAL PRIMARY KEY,
    game_id      BIGINT NOT NULL,
    user_id      BIGINT,                            -- NULL si es mensaje del BOT
    username     VARCHAR(50) NOT NULL,               -- "Hernán" para el bot, username para usuario
    message      VARCHAR(200) NOT NULL,
    message_type VARCHAR(10) DEFAULT 'USER' NOT NULL,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_cm_game FOREIGN KEY (game_id)
        REFERENCES games(id) ON DELETE CASCADE,
    CONSTRAINT fk_cm_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_cm_type CHECK (message_type IN ('USER','BOT','SYSTEM'))
);

CREATE INDEX idx_cm_game ON game_chat_messages(game_id, created_at);


-- ┌──────────────────────────────────────────────────────────┐
-- │  V11: VISTAS MATERIALIZADAS                              │
-- └──────────────────────────────────────────────────────────┘

-- Leaderboard global (se refresca después de cada partida ranked)
CREATE MATERIALIZED VIEW leaderboard AS
SELECT
    u.id AS user_id,
    u.username,
    COALESCE(sr.current_rating, u.skill_rating) AS skill_rating,
    COALESCE(sr.peak_rating, u.skill_rating) AS peak_rating,
    u.wins,
    u.losses,
    u.draws,
    (u.wins + u.losses + u.draws) AS total_games,
    CASE
        WHEN (u.wins + u.losses) > 0
        THEN ROUND((u.wins::numeric / (u.wins + u.losses)) * 100, 2)
        ELSE 0
    END AS win_percentage
FROM users u
LEFT JOIN skill_ratings sr ON u.id = sr.user_id
WHERE u.email_verified = TRUE
ORDER BY skill_rating DESC, win_percentage DESC;

CREATE UNIQUE INDEX idx_lb_user ON leaderboard(user_id);

-- Stats de colección por usuario
CREATE MATERIALIZED VIEW user_collection_stats AS
SELECT
    uc.user_id,
    COUNT(DISTINCT uc.card_id) AS unique_cards,
    SUM(uc.quantity) AS total_cards,
    COUNT(DISTINCT CASE WHEN c.rarity = 'Common' THEN uc.card_id END) AS common_count,
    COUNT(DISTINCT CASE WHEN c.rarity = 'Uncommon' THEN uc.card_id END) AS uncommon_count,
    COUNT(DISTINCT CASE WHEN c.rarity = 'Rare' THEN uc.card_id END) AS rare_count,
    COUNT(DISTINCT CASE WHEN c.rarity = 'Rare Holo' THEN uc.card_id END) AS rare_holo_count,
    COUNT(DISTINCT CASE WHEN c.rarity = 'Rare Holo EX' THEN uc.card_id END) AS rare_holo_ex_count,
    COUNT(DISTINCT CASE WHEN c.rarity = 'Rare Ultra' THEN uc.card_id END) AS rare_ultra_count
FROM user_collection uc
JOIN cards_catalog c ON uc.card_id = c.id
GROUP BY uc.user_id;

CREATE UNIQUE INDEX idx_ucs_user ON user_collection_stats(user_id);


-- ══════════════════════════════════════════════════════════════
-- RESUMEN: 20 TABLAS + 2 VISTAS MATERIALIZADAS
--
-- Auth:         users, refresh_tokens, email_verifications
-- Cartas:       cards_catalog
-- Mazos:        decks, deck_cards
-- Sobres:       booster_packs, booster_pack_cards,
--               user_booster_packs, user_collection
-- Pagos:        payment_records, payment_webhooks_log
-- Matchmaking:  skill_ratings, queue_entries
-- Salas:        game_rooms, game_room_players
-- Juego:        games, game_state_snapshots, game_events
-- Chat:         game_chat_messages
--
-- Vistas:       leaderboard, user_collection_stats
-- ══════════════════════════════════════════════════════════════


-- ┌──────────────────────────────────────────────────────────┐
-- │  V12: SISTEMA DE RANKING POR LIGAS                       │
-- └──────────────────────────────────────────────────────────┘

-- Agregar columnas de ranking a users
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS ranking_points INT DEFAULT 0 NOT NULL,
    ADD COLUMN IF NOT EXISTS league VARCHAR(10) DEFAULT 'BRONZE' NOT NULL,
    ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'USER' NOT NULL,
    ADD CONSTRAINT chk_league CHECK (league IN ('BRONZE','SILVER','GOLD')),
    ADD CONSTRAINT chk_role CHECK (role IN ('USER','ADMIN'));

CREATE INDEX idx_users_league ON users(league);
CREATE INDEX idx_users_ranking_points ON users(ranking_points DESC);

-- Historial de cambios de puntos
CREATE TABLE ranking_history (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    game_id     BIGINT NOT NULL,
    points_earned INT NOT NULL,
    league_before VARCHAR(10) NOT NULL,
    league_after  VARCHAR(10) NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_rh_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_rh_game FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE RESTRICT
);

CREATE INDEX idx_rh_user ON ranking_history(user_id);


-- ┌──────────────────────────────────────────────────────────┐
-- │  V13: SISTEMA DE AMIGOS Y PRESENCIA                      │
-- └──────────────────────────────────────────────────────────┘

CREATE TABLE friendships (
    id           BIGSERIAL PRIMARY KEY,
    requester_id BIGINT NOT NULL,
    receiver_id  BIGINT NOT NULL,
    status       VARCHAR(20) DEFAULT 'PENDING' NOT NULL,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_fs_requester FOREIGN KEY (requester_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_fs_receiver  FOREIGN KEY (receiver_id)  REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT uq_friendship   UNIQUE (requester_id, receiver_id),
    CONSTRAINT chk_fs_status   CHECK (status IN ('PENDING','ACCEPTED','BLOCKED')),
    CONSTRAINT chk_no_self     CHECK (requester_id != receiver_id)
);

CREATE INDEX idx_fs_requester ON friendships(requester_id, status);
CREATE INDEX idx_fs_receiver  ON friendships(receiver_id, status);

-- Presencia se guarda en Redis (user:presence:{userId} = ONLINE|PLAYING|OFFLINE, TTL 5min)
-- Esta tabla es solo para auditoría de última conexión
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMP;


-- ┌──────────────────────────────────────────────────────────┐
-- │  V14: SECCIÓN DE NOTICIAS Y UPDATES                      │
-- └──────────────────────────────────────────────────────────┘

CREATE TABLE news_posts (
    id           BIGSERIAL PRIMARY KEY,
    title        VARCHAR(255) NOT NULL,
    content      TEXT NOT NULL,
    category     VARCHAR(20) NOT NULL,
    author_id    BIGINT NOT NULL,
    published_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_news_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT chk_news_cat CHECK (category IN ('UPDATE','EVENT','MAINTENANCE','ANNOUNCEMENT'))
);

CREATE INDEX idx_news_published ON news_posts(published_at DESC);
CREATE INDEX idx_news_category  ON news_posts(category);


-- ┌──────────────────────────────────────────────────────────┐
-- │  V15: OAUTH2 (Google + GitHub)                           │
-- └──────────────────────────────────────────────────────────┘

CREATE TABLE user_oauth_accounts (
    id               BIGSERIAL PRIMARY KEY,
    user_id          BIGINT NOT NULL,
    provider         VARCHAR(20) NOT NULL,
    provider_user_id VARCHAR(255) NOT NULL,
    email            VARCHAR(100),
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_oauth_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT uq_oauth_provider UNIQUE (provider, provider_user_id),
    CONSTRAINT chk_oauth_provider CHECK (provider IN ('GOOGLE','GITHUB'))
);

CREATE INDEX idx_oauth_user ON user_oauth_accounts(user_id);
CREATE INDEX idx_oauth_lookup ON user_oauth_accounts(provider, provider_user_id);


-- ┌──────────────────────────────────────────────────────────┐
-- │  V16: RETENCIÓN Y MANTENIMIENTO DE DATOS                 │
-- └──────────────────────────────────────────────────────────┘

-- Política de retención por tabla:
--   game_events:           90 días desde created_at
--   game_state_snapshots:  30 días para partidas FINISHED/ABANDONED
--   payment_webhooks_log:  180 días tras processed=TRUE (auditoría regulatoria)
-- Las partidas (games) NO se purgan — son historial permanente.

CREATE OR REPLACE FUNCTION purge_expired_data()
RETURNS TABLE(table_name TEXT, deleted_rows BIGINT) AS $$
DECLARE
    v_events    BIGINT;
    v_snapshots BIGINT;
    v_webhooks  BIGINT;
BEGIN
    DELETE FROM game_events
    WHERE created_at < NOW() - INTERVAL '90 days';
    GET DIAGNOSTICS v_events = ROW_COUNT;

    DELETE FROM game_state_snapshots
    WHERE created_at < NOW() - INTERVAL '30 days'
      AND game_id IN (SELECT id FROM games WHERE status IN ('FINISHED','ABANDONED'));
    GET DIAGNOSTICS v_snapshots = ROW_COUNT;

    DELETE FROM payment_webhooks_log
    WHERE created_at < NOW() - INTERVAL '180 days'
      AND processed = TRUE;
    GET DIAGNOSTICS v_webhooks = ROW_COUNT;

    RETURN QUERY VALUES
        ('game_events'::TEXT, v_events),
        ('game_state_snapshots'::TEXT, v_snapshots),
        ('payment_webhooks_log'::TEXT, v_webhooks);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION purge_expired_data() IS
'Invocada por MaintenanceJob.java con @Scheduled(cron="0 0 4 * * *") — diaria 04:00 UTC.';

COMMENT ON TABLE game_events           IS 'Retención: 90 días. Purgado por purge_expired_data().';
COMMENT ON TABLE game_state_snapshots  IS 'Retención: 30 días para partidas finalizadas. Purgado por purge_expired_data().';
COMMENT ON TABLE payment_webhooks_log  IS 'Retención: 180 días tras processed=TRUE (auditoría regulatoria).';
COMMENT ON TABLE wallet_transactions   IS 'Retención: permanente (auditoría de moneda virtual).';
