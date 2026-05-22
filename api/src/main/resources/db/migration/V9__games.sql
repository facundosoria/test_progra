CREATE TABLE games (
    id                       BIGSERIAL PRIMARY KEY,
    match_type               VARCHAR(10) NOT NULL,
    room_code                VARCHAR(6),

    player1_id               BIGINT NOT NULL,
    player1_deck_id          BIGINT NOT NULL,
    player2_id               BIGINT,
    player2_deck_id          BIGINT,

    bot_difficulty           VARCHAR(10),
    bot_personality          VARCHAR(10),

    status                   VARCHAR(15) DEFAULT 'WAITING' NOT NULL,
    current_turn_player_id   BIGINT,
    turn_number              INT DEFAULT 0 NOT NULL,

    winner_id                BIGINT,
    end_reason               VARCHAR(20),
    consecutive_timeouts_p1  INT DEFAULT 0 NOT NULL,
    consecutive_timeouts_p2  INT DEFAULT 0 NOT NULL,
    next_timeout_at          TIMESTAMP,
    disconnected_player_id   BIGINT,
    disconnect_started_at    TIMESTAMP,

    started_at               TIMESTAMP,
    ended_at                 TIMESTAMP,
    created_at               TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

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

CREATE INDEX idx_g_p1           ON games(player1_id);
CREATE INDEX idx_g_p2           ON games(player2_id);
CREATE INDEX idx_g_status       ON games(status);
CREATE INDEX idx_g_type         ON games(match_type);
CREATE INDEX idx_g_next_timeout ON games(next_timeout_at) WHERE status = 'ACTIVE' AND next_timeout_at IS NOT NULL;
CREATE INDEX idx_g_disconnect   ON games(disconnect_started_at) WHERE disconnect_started_at IS NOT NULL;
CREATE INDEX idx_g_end_reason   ON games(end_reason) WHERE end_reason IS NOT NULL;
CREATE INDEX idx_g_p1_history   ON games(player1_id, status, ended_at DESC)
    WHERE status IN ('FINISHED','ABANDONED');
CREATE INDEX idx_g_p2_history   ON games(player2_id, status, ended_at DESC)
    WHERE status IN ('FINISHED','ABANDONED');

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
CREATE INDEX idx_ge_game_type ON game_events(game_id, event_type);
