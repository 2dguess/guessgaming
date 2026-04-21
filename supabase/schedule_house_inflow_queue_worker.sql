-- Schedule queue worker for house inflow aggregation.
-- Requires pg_cron. Runs every minute.

CREATE EXTENSION IF NOT EXISTS pg_cron;

DO $$
DECLARE
  v_job_id BIGINT;
BEGIN
  SELECT jobid INTO v_job_id
  FROM cron.job
  WHERE jobname = 'house_inflow_queue_worker'
  LIMIT 1;

  IF v_job_id IS NOT NULL THEN
    PERFORM cron.unschedule(v_job_id);
  END IF;
END $$;

SELECT cron.schedule(
  'house_inflow_queue_worker',
  '* * * * *',
  $$SELECT public.process_house_inflow_queue(10000, 5);$$
);

