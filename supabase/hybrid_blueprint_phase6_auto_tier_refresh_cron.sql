-- Hybrid Blueprint - Phase 6
-- Auto refresh current_user_count + apply matching tier via pg_cron

CREATE EXTENSION IF NOT EXISTS pg_cron;

-- =========================================================
-- 1) Function: count active users and apply tier
-- =========================================================
CREATE OR REPLACE FUNCTION public.refresh_user_count_and_apply_tier()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_count BIGINT := 0;
  v_result JSONB;
BEGIN
  -- Primary source: auth.users
  SELECT COUNT(*)::BIGINT
  INTO v_user_count
  FROM auth.users;

  v_result := public.apply_system_config_tier(v_user_count);

  INSERT INTO public.settlement_logs (run_id, level, stage, message, meta)
  VALUES (
    gen_random_uuid(),
    CASE WHEN COALESCE((v_result->>'ok')::BOOLEAN, FALSE) THEN 'info' ELSE 'error' END,
    'auto_tier_refresh',
    'refresh_user_count_and_apply_tier executed',
    jsonb_build_object(
      'user_count', v_user_count,
      'apply_result', v_result
    )
  );

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.refresh_user_count_and_apply_tier() TO authenticated;

-- =========================================================
-- 2) Schedule: run every 10 minutes
-- =========================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'hybrid_auto_tier_refresh_10m') THEN
    PERFORM cron.unschedule('hybrid_auto_tier_refresh_10m');
  END IF;
END $$;

SELECT cron.schedule(
  'hybrid_auto_tier_refresh_10m',
  '*/10 * * * *',
  $$SELECT public.refresh_user_count_and_apply_tier();$$
);

