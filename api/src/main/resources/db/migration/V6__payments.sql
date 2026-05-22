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

CREATE TABLE payment_webhooks_log (
    id           BIGSERIAL PRIMARY KEY,
    mp_event_id  VARCHAR(255) UNIQUE NOT NULL,
    payload      JSONB NOT NULL,
    processed    BOOLEAN DEFAULT FALSE NOT NULL,
    processed_at TIMESTAMP,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX idx_wh_event ON payment_webhooks_log(mp_event_id);

CREATE TABLE wallet_transactions (
    id            BIGSERIAL PRIMARY KEY,
    user_id       BIGINT NOT NULL,
    delta         BIGINT NOT NULL,
    reason        VARCHAR(30) NOT NULL,
    ref_table     VARCHAR(40),
    ref_id        BIGINT,
    balance_after BIGINT NOT NULL,
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
