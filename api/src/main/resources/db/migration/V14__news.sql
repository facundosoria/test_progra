CREATE TABLE news_posts (
    id           BIGSERIAL PRIMARY KEY,
    title        VARCHAR(255) NOT NULL,
    content      TEXT NOT NULL,
    category     VARCHAR(20) NOT NULL,
    author_id    BIGINT NOT NULL,
    published_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_news_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT chk_news_cat CHECK (category IN ('UPDATE','EVENT','MAINTENANCE','ANNOUNCEMENT'))
);

CREATE INDEX idx_news_published ON news_posts(published_at DESC);
CREATE INDEX idx_news_category  ON news_posts(category);
