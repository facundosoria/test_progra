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
