-- Hybrid Blueprint - Phase 7
-- Monitoring + alert views/queries for production hardening

-- =========================================================
-- 1) Health summary view
-- =========================================================
DROP VIEW IF EXISTS public.hybrid_ops_health;
CREATE VIEW public.hybrid_ops_health AS
WITH q AS (
  SELECT
    COUNT(*) FILTER (WHERE status = 'queued')::BIGINT AS queued_rows,
    COUNT(*) FILTER (WHERE status = 'processing')::BIGINT AS processing_rows,
    COUNT(*) FILTER (WHERE status = 'applied')::BIGINT AS applied_rows,
    COUNT(*) FILTER (WHERE status = 'failed')::BIGINT AS failed_rows,
    COALESCE(SUM(amount) FILTER (WHERE status IN ('queued', 'processing')), 0)::BIGINT AS pending_inflow_amount,
    MAX(updated_at) AS last_queue_update
  FROM public.pending_settlements
),
e AS (
  SELECT
    COUNT(*)::BIGINT AS errors_1h
  FROM public.settlement_logs
  WHERE level = 'error'
    AND created_at >= NOW() - INTERVAL '1 hour'
),
d AS (
  SELECT
    COUNT(*)::BIGINT AS dlq_rows,
    COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '1 hour')::BIGINT AS dlq_1h
  FROM public.settlement_dead_letter
),
c AS (
  SELECT
    current_user_count,
    batch_size,
    frequency_seconds,
    updated_at AS config_updated_at
  FROM public.system_config
  WHERE is_active = TRUE
  ORDER BY updated_at DESC
  LIMIT 1
),
r AS (
  SELECT
    COUNT(*) FILTER (WHERE checked_at >= NOW() - INTERVAL '1 hour')::BIGINT AS recon_rows_1h,
    COUNT(*) FILTER (WHERE checked_at >= NOW() - INTERVAL '1 hour' AND delta <> 0)::BIGINT AS recon_mismatch_1h
  FROM public.balance_reconciliation_logs
)
SELECT
  q.queued_rows,
  q.processing_rows,
  q.applied_rows,
  q.failed_rows,
  q.pending_inflow_amount,
  q.last_queue_update,
  e.errors_1h,
  d.dlq_rows,
  d.dlq_1h,
  c.current_user_count,
  c.batch_size,
  c.frequency_seconds,
  c.config_updated_at,
  r.recon_rows_1h,
  r.recon_mismatch_1h
FROM q, e, d, c, r;

-- =========================================================
-- 2) Suggested alert checks (run these from dashboard/cron)
-- =========================================================
-- A) Queue backlog alert
DROP VIEW IF EXISTS public.hybrid_alert_queue_backlog;
CREATE VIEW public.hybrid_alert_queue_backlog AS
SELECT
  CASE
    WHEN queued_rows > 0 AND last_queue_update < NOW() - INTERVAL '10 minutes' THEN TRUE
    ELSE FALSE
  END AS is_alert,
  queued_rows,
  last_queue_update,
  pending_inflow_amount
FROM public.hybrid_ops_health;

-- B) Error spike alert
DROP VIEW IF EXISTS public.hybrid_alert_error_spike;
CREATE VIEW public.hybrid_alert_error_spike AS
SELECT
  (errors_1h > 0 OR dlq_1h > 0) AS is_alert,
  errors_1h,
  dlq_1h
FROM public.hybrid_ops_health;

-- C) Reconciliation mismatch alert
DROP VIEW IF EXISTS public.hybrid_alert_recon_mismatch;
CREATE VIEW public.hybrid_alert_recon_mismatch AS
SELECT
  (recon_mismatch_1h > 0) AS is_alert,
  recon_rows_1h,
  recon_mismatch_1h
FROM public.hybrid_ops_health;

-- =========================================================
-- 3) Handy ops queries
-- =========================================================
-- Latest 20 errors:
-- SELECT created_at, stage, message, meta
-- FROM public.settlement_logs
-- WHERE level = 'error'
-- ORDER BY created_at DESC
-- LIMIT 20;
--
-- Current health:
-- SELECT * FROM public.hybrid_ops_health;
--
-- Alert checks:
-- SELECT * FROM public.hybrid_alert_queue_backlog;
-- SELECT * FROM public.hybrid_alert_error_spike;
-- SELECT * FROM public.hybrid_alert_recon_mismatch;

