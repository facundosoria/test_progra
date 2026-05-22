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

CREATE INDEX idx_qe_status      ON queue_entries(status);
CREATE INDEX idx_qe_user_status ON queue_entries(user_id, status);
CREATE INDEX idx_qe_skill       ON queue_entries(skill_rating);
