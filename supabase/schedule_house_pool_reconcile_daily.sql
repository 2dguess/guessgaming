-- Daily safety reconcile for house pool accounting.
-- Requires: pg_cron extension enabled.
-- Runs every day at 00:20 UTC (06:50 Myanmar time, UTC+6:30).

CREATE EXTENSION IF NOT EXISTS pg_cron;

DO $$
DECLARE
  v_job_id BIGINT;
BEGIN
  -- Remove old job with same name (idempotent deploy).
  SELECT jobid INTO v_job_id
  FROM cron.job
  WHERE jobname = 'house_pool_reconcile_daily'
  LIMIT 1;

  IF v_job_id IS NOT NULL THEN
    PERFORM cron.unschedule(v_job_id);
  END IF;
END $$;

SELECT cron.schedule(
  'house_pool_reconcile_daily',
  '20 0 * * *',
  $$SELECT public.reconcile_house_pool(TRUE);$$
);

-- Verify:
-- SELECT jobid, jobname, schedule, command FROM cron.job WHERE jobname = 'house_pool_reconcile_daily';
