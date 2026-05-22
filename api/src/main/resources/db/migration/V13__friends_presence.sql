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

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMP;
