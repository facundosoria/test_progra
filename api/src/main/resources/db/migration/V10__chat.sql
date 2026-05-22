CREATE TABLE game_chat_messages (
    id           BIGSERIAL PRIMARY KEY,
    game_id      BIGINT NOT NULL,
    user_id      BIGINT,
    username     VARCHAR(50) NOT NULL,
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
