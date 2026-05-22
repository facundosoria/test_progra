CREATE TABLE booster_packs (
    id                  BIGSERIAL PRIMARY KEY,
    name                VARCHAR(255) NOT NULL,
    description         TEXT,
    price_usd           DECIMAL(10,2) NOT NULL,
    price_coins         BIGINT NOT NULL,
    cards_per_pack      INT DEFAULT 10 NOT NULL,
    rarity_distribution JSONB NOT NULL,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

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

CREATE TABLE user_booster_packs (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL,
    booster_pack_id BIGINT NOT NULL,
    obtained_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    opened_at       TIMESTAMP,
    obtained_from   VARCHAR(50),
    CONSTRAINT fk_ubp_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_ubp_pack FOREIGN KEY (booster_pack_id)
        REFERENCES booster_packs(id) ON DELETE RESTRICT
);

CREATE INDEX idx_ubp_user ON user_booster_packs(user_id);

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
