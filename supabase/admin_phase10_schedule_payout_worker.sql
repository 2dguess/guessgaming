-- Phase 10: automate payout processing schedules
-- Run after admin_phase9_batched_payout.sql

CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Recover stuck processing jobs (e.g. worker crashed mid-run)
CREATE OR REPLACE FUNCTION public.recover_stuck_payout_jobs(
  p_stuck_after_minutes INTEGER DEFAULT 5
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INTEGER := 0;
BEGIN
  UPDATE public.payout_jobs
  SET
    status = 'queued',
    error_message = COALESCE(error_message, 'Recovered from stuck processing')
  WHERE status = 'processing'
    AND paid_at IS NULL
    AND created_at <= NOW() - make_interval(mins => GREATEST(1, p_stuck_after_minutes));

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN jsonb_build_object('ok', TRUE, 'recovered_jobs', v_count);
END;
$$;

GRANT EXECUTE ON FUNCTION public.recover_stuck_payout_jobs(INTEGER) TO authenticated;

DO $$
DECLARE
  v_job_id BIGINT;
BEGIN
  -- unschedule old process job
  SELECT jobid INTO v_job_id
  FROM cron.job
  WHERE jobname = 'payout_process_every_minute'
  LIMIT 1;
  IF v_job_id IS NOT NULL THEN
    PERFORM cron.unschedule(v_job_id);
  END IF;

  -- unschedule old recover job
  SELECT jobid INTO v_job_id
  FROM cron.job
  WHERE jobname = 'payout_recover_stuck_every_5min'
  LIMIT 1;
  IF v_job_id IS NOT NULL THEN
    PERFORM cron.unschedule(v_job_id);
  END IF;
END $$;

-- Run due payout jobs every minute.
SELECT cron.schedule(
  'payout_process_every_minute',
  '* * * * *',
  $$SELECT public.process_due_payout_jobs(2000, 5);$$
);

-- Recover stuck jobs every 5 minutes.
SELECT cron.schedule(
  'payout_recover_stuck_every_5min',
  '*/5 * * * *',
  $$SELECT public.recover_stuck_payout_jobs(5);$$
);

-- Optional checks:
-- SELECT * FROM cron.job WHERE jobname IN ('payout_process_every_minute', 'payout_recover_stuck_every_5min');
-- SELECT public.process_due_payout_jobs(2000, 5);
-- SELECT public.recover_stuck_payout_jobs(5);

