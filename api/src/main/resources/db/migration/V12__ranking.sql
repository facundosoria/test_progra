ALTER TABLE users
    ADD COLUMN IF NOT EXISTS ranking_points INT DEFAULT 0 NOT NULL,
    ADD COLUMN IF NOT EXISTS league VARCHAR(10) DEFAULT 'BRONZE' NOT NULL,
    ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'USER' NOT NULL,
    ADD CONSTRAINT chk_league CHECK (league IN ('BRONZE','SILVER','GOLD')),
    ADD CONSTRAINT chk_role CHECK (role IN ('USER','ADMIN'));

CREATE INDEX idx_users_league         ON users(league);
CREATE INDEX idx_users_ranking_points ON users(ranking_points DESC);

CREATE TABLE ranking_history (
    id             BIGSERIAL PRIMARY KEY,
    user_id        BIGINT NOT NULL,
    game_id        BIGINT NOT NULL,
    points_earned  INT NOT NULL,
    league_before  VARCHAR(10) NOT NULL,
    league_after   VARCHAR(10) NOT NULL,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_rh_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_rh_game FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE RESTRICT
);

CREATE INDEX idx_rh_user ON ranking_history(user_id);
