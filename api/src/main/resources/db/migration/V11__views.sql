CREATE MATERIALIZED VIEW leaderboard AS
SELECT
    u.id AS user_id,
    u.username,
    COALESCE(sr.current_rating, u.skill_rating) AS skill_rating,
    COALESCE(sr.peak_rating, u.skill_rating) AS peak_rating,
    u.wins,
    u.losses,
    u.draws,
    (u.wins + u.losses + u.draws) AS total_games,
    CASE
        WHEN (u.wins + u.losses) > 0
        THEN ROUND((u.wins::numeric / (u.wins + u.losses)) * 100, 2)
        ELSE 0
    END AS win_percentage
FROM users u
LEFT JOIN skill_ratings sr ON u.id = sr.user_id
WHERE u.email_verified = TRUE
ORDER BY skill_rating DESC, win_percentage DESC;

CREATE UNIQUE INDEX idx_lb_user ON leaderboard(user_id);

CREATE MATERIALIZED VIEW user_collection_stats AS
SELECT
    uc.user_id,
    COUNT(DISTINCT uc.card_id) AS unique_cards,
    SUM(uc.quantity) AS total_cards,
    COUNT(DISTINCT CASE WHEN c.rarity = 'Common' THEN uc.card_id END) AS common_count,
    COUNT(DISTINCT CASE WHEN c.rarity = 'Uncommon' THEN uc.card_id END) AS uncommon_count,
    COUNT(DISTINCT CASE WHEN c.rarity = 'Rare' THEN uc.card_id END) AS rare_count,
    COUNT(DISTINCT CASE WHEN c.rarity = 'Rare Holo' THEN uc.card_id END) AS rare_holo_count,
    COUNT(DISTINCT CASE WHEN c.rarity = 'Rare Holo EX' THEN uc.card_id END) AS rare_holo_ex_count,
    COUNT(DISTINCT CASE WHEN c.rarity = 'Rare Ultra' THEN uc.card_id END) AS rare_ultra_count
FROM user_collection uc
JOIN cards_catalog c ON uc.card_id = c.id
GROUP BY uc.user_id;

CREATE UNIQUE INDEX idx_ucs_user ON user_collection_stats(user_id);
