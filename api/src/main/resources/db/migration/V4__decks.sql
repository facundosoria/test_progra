CREATE TABLE decks (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT,
    name        VARCHAR(255) NOT NULL,
    description TEXT,
    is_favorite BOOLEAN DEFAULT FALSE NOT NULL,
    is_starter  BOOLEAN DEFAULT FALSE NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_decks_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_decks_user_id ON decks(user_id);
CREATE INDEX idx_decks_starter ON decks(is_starter);

CREATE TABLE deck_cards (
    id       BIGSERIAL PRIMARY KEY,
    deck_id  BIGINT NOT NULL,
    card_id  VARCHAR(20) NOT NULL,
    quantity INT DEFAULT 1 NOT NULL,
    CONSTRAINT fk_dc_deck FOREIGN KEY (deck_id)
        REFERENCES decks(id) ON DELETE CASCADE,
    CONSTRAINT fk_dc_card FOREIGN KEY (card_id)
        REFERENCES cards_catalog(id) ON DELETE RESTRICT,
    CONSTRAINT uq_deck_card UNIQUE (deck_id, card_id),
    CONSTRAINT chk_dc_qty CHECK (quantity >= 1 AND quantity <= 60)
);

CREATE INDEX idx_dc_deck_id ON deck_cards(deck_id);
