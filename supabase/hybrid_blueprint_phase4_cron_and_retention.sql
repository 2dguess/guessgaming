-- Hybrid Blueprint - Phase 4
-- pg_cron schedules + retention procedures + basic monitoring views

-- =========================================================
-- 1) Ensure pg_cron extension
-- =========================================================
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- =========================================================
-- 2) Retention procedure (safe cleanup)
-- =========================================================
CREATE OR REPLACE PROCEDURE public.run_hybrid_retention_cleanup(
  p_keep_applied_queue_days INTEGER DEFAULT 7,
  p_keep_dlq_days INTEGER DEFAULT 30,
  p_keep_bets_days INTEGER DEFAULT 30,
  p_keep_inflow_applied_days INTEGER DEFAULT 30,
  p_keep_settlement_logs_days INTEGER DEFAULT 30,
  p_keep_recon_logs_days INTEGER DEFAULT 30
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_run_id UUID := gen_random_uuid();
  v_deleted_queue BIGINT := 0;
  v_deleted_dlq BIGINT := 0;
  v_deleted_bets BIGINT := 0;
  v_deleted_inflow BIGINT := 0;
  v_deleted_settle_logs BIGINT := 0;
  v_deleted_recon BIGINT := 0;
BEGIN
  DELETE FROM public.pending_settlements
  WHERE status = 'applied'
    AND created_at < NOW() - make_interval(days => GREATEST(1, p_keep_applied_queue_days));
  GET DIAGNOSTICS v_deleted_queue = ROW_COUNT;

  DELETE FROM public.settlement_dead_letter
  WHERE created_at < NOW() - make_interval(days => GREATEST(1, p_keep_dlq_days));
  GET DIAGNOSTICS v_deleted_dlq = ROW_COUNT;

  DELETE FROM public.bets
  WHERE status <> 'pending'
    AND created_at < NOW() - make_interval(days => GREATEST(1, p_keep_bets_days));
  GET DIAGNOSTICS v_deleted_bets = ROW_COUNT;

  DELETE FROM public.admin_wallet_inflow_applied
  WHERE applied_at < NOW() - make_interval(days => GREATEST(1, p_keep_inflow_applied_days));
  GET DIAGNOSTICS v_deleted_inflow = ROW_COUNT;

  DELETE FROM public.settlement_logs
  WHERE created_at < NOW() - make_interval(days => GREATEST(1, p_keep_settlement_logs_days));
  GET DIAGNOSTICS v_deleted_settle_logs = ROW_COUNT;

  DELETE FROM public.balance_reconciliation_logs
  WHERE checked_at < NOW() - make_interval(days => GREATEST(1, p_keep_recon_logs_days));
  GET DIAGNOSTICS v_deleted_recon = ROW_COUNT;

  INSERT INTO public.settlement_logs (run_id, level, stage, message, meta)
  VALUES (
    v_run_id,
    'info',
    'retention_cleanup',
    'Hybrid retention cleanup finished',
    jsonb_build_object(
      'deleted_pending_settlements_applied', v_deleted_queue,
      'deleted_settlement_dead_letter', v_deleted_dlq,
      'deleted_bets', v_deleted_bets,
      'deleted_admin_wallet_inflow_applied', v_deleted_inflow,
      'deleted_settlement_logs', v_deleted_settle_logs,
      'deleted_balance_reconciliation_logs', v_deleted_recon
    )
  );
END;
$$;

-- =========================================================
-- 3) Monitoring views
-- =========================================================
DROP VIEW IF EXISTS public.hybrid_settlement_kpi;
CREATE VIEW public.hybrid_settlement_kpi AS
SELECT
  COUNT(*) FILTER (WHERE status = 'queued')::BIGINT AS queued_rows,
  COUNT(*) FILTER (WHERE status = 'processing')::BIGINT AS processing_rows,
  COUNT(*) FILTER (WHERE status = 'applied')::BIGINT AS applied_rows,
  COUNT(*) FILTER (WHERE status = 'failed')::BIGINT AS failed_rows,
  COALESCE(SUM(amount) FILTER (WHERE status IN ('queued', 'processing')), 0)::BIGINT AS pending_inflow_amount,
  COALESCE(SUM(amount) FILTER (WHERE status = 'applied'), 0)::BIGINT AS applied_inflow_amount,
  MAX(updated_at) AS last_queue_update
FROM public.pending_settlements;

DROP VIEW IF EXISTS public.hybrid_settlement_recent_errors;
CREATE VIEW public.hybrid_settlement_recent_errors AS
SELECT
  created_at,
  stage,
  message,
  meta
FROM public.settlement_logs
WHERE level = 'error'
ORDER BY created_at DESC
LIMIT 100;

-- =========================================================
-- 4) pg_cron schedules
--    NOTE: adjust schedules based on production traffic window.
-- =========================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'hybrid_settle_admin_wallet_every_minute') THEN
    PERFORM cron.unschedule('hybrid_settle_admin_wallet_every_minute');
  END IF;
END $$;

SELECT cron.schedule(
  'hybrid_settle_admin_wallet_every_minute',
  '* * * * *',
  $$CALL public.settle_admin_wallet_hybrid();$$
);

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'hybrid_retention_cleanup_daily') THEN
    PERFORM cron.unschedule('hybrid_retention_cleanup_daily');
  END IF;
END $$;

SELECT cron.schedule(
  'hybrid_retention_cleanup_daily',
  '20 3 * * *',
  $$CALL public.run_hybrid_retention_cleanup(7, 30, 30, 30, 30, 30);$$
);

