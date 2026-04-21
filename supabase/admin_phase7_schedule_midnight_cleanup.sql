-- Phase 7: Schedule non-daily mission cleanup at Myanmar midnight.
-- Run after admin_phase6_mission_type_and_daily_cleanup.sql
--
-- This uses pg_cron. On Supabase projects where pg_cron is available,
-- it will run daily at 00:00 Myanmar time (UTC 17:30).

-- Ensure extension exists (safe if already enabled).
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Remove old job if it exists (idempotent).
DO $$
DECLARE
  v_job_id BIGINT;
BEGIN
  SELECT jobid
  INTO v_job_id
  FROM cron.job
  WHERE jobname = 'mmt_midnight_non_daily_mission_cleanup'
  LIMIT 1;

  IF v_job_id IS NOT NULL THEN
    PERFORM cron.unschedule(v_job_id);
  END IF;
END $$;

-- Schedule at 17:30 UTC = 00:00 Myanmar (+06:30).
SELECT cron.schedule(
  'mmt_midnight_non_daily_mission_cleanup',
  '30 17 * * *',
  $$SELECT public.admin_cleanup_non_daily_missions_mmt();$$
);

-- Optional quick test:
-- SELECT public.admin_cleanup_non_daily_missions_mmt();

-- Optional verify job:
-- SELECT * FROM cron.job WHERE jobname = 'mmt_midnight_non_daily_mission_cleanup';

