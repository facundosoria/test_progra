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
