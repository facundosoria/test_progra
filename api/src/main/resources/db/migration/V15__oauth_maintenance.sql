CREATE TABLE user_oauth_accounts (
    id               BIGSERIAL PRIMARY KEY,
    user_id          BIGINT NOT NULL,
    provider         VARCHAR(20) NOT NULL,
    provider_user_id VARCHAR(255) NOT NULL,
    email            VARCHAR(100),
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_oauth_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT uq_oauth_provider UNIQUE (provider, provider_user_id),
    CONSTRAINT chk_oauth_provider CHECK (provider IN ('GOOGLE','GITHUB'))
);

CREATE INDEX idx_oauth_user   ON user_oauth_accounts(user_id);
CREATE INDEX idx_oauth_lookup ON user_oauth_accounts(provider, provider_user_id);

CREATE OR REPLACE FUNCTION purge_expired_data()
RETURNS TABLE(table_name TEXT, deleted_rows BIGINT) AS $$
DECLARE
    v_events    BIGINT;
    v_snapshots BIGINT;
    v_webhooks  BIGINT;
BEGIN
    DELETE FROM game_events
    WHERE created_at < NOW() - INTERVAL '90 days';
    GET DIAGNOSTICS v_events = ROW_COUNT;

    DELETE FROM game_state_snapshots
    WHERE created_at < NOW() - INTERVAL '30 days'
      AND game_id IN (SELECT id FROM games WHERE status IN ('FINISHED','ABANDONED'));
    GET DIAGNOSTICS v_snapshots = ROW_COUNT;

    DELETE FROM payment_webhooks_log
    WHERE created_at < NOW() - INTERVAL '180 days'
      AND processed = TRUE;
    GET DIAGNOSTICS v_webhooks = ROW_COUNT;

    RETURN QUERY VALUES
        ('game_events'::TEXT, v_events),
        ('game_state_snapshots'::TEXT, v_snapshots),
        ('payment_webhooks_log'::TEXT, v_webhooks);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION purge_expired_data() IS
'Invocada por MaintenanceJob.java con @Scheduled(cron="0 0 4 * * *") — diaria 04:00 UTC.';

COMMENT ON TABLE game_events          IS 'Retención: 90 días. Purgado por purge_expired_data().';
COMMENT ON TABLE game_state_snapshots IS 'Retención: 30 días para partidas finalizadas. Purgado por purge_expired_data().';
COMMENT ON TABLE payment_webhooks_log IS 'Retención: 180 días tras processed=TRUE (auditoría regulatoria).';
COMMENT ON TABLE wallet_transactions  IS 'Retención: permanente (auditoría de moneda virtual).';
