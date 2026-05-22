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
