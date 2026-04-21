-- Hybrid Blueprint - Next Day Trial Playbook
-- Purpose:
--   Quickly run controlled trials for:
--   - batch_size 10000 with 60s
--   - batch_size 10000 with 30s
--   - batch_size 12000 with 60s
--   - batch_size 12000 with 30s
--
-- Notes:
--   1) Run one trial at a time.
--   2) Keep each trial window 10-15 minutes under real load.
--   3) Capture KPI snapshots every 2-3 minutes.
--   4) If alerts spike, rollback immediately.

-- =========================================================
-- A) Pre-check (run first)
-- =========================================================
-- Override status
SELECT
  id,
  is_enabled,
  locked_batch_size,
  locked_frequency_seconds,
  reason,
  updated_at
FROM public.system_config_override
ORDER BY id
LIMIT 1;

-- Active config
SELECT *
FROM public.active_system_config_with_tier;

-- Queue status
SELECT
  status,
  COUNT(*) AS cnt,
  COALESCE(SUM(amount), 0) AS amt
FROM public.pending_settlements
GROUP BY status
ORDER BY status;

-- =========================================================
-- B) Trial start commands (choose one only)
-- =========================================================
-- Trial 1: 10000 / 60s
-- SELECT public.enable_system_config_override(10000, 60, 'trial 10000/60 next day');

-- Trial 2: 10000 / 30s
-- SELECT public.enable_system_config_override(10000, 30, 'trial 10000/30 next day');

-- Trial 3: 12000 / 60s
-- SELECT public.enable_system_config_override(12000, 60, 'trial 12000/60 next day');

-- Trial 4: 12000 / 30s
-- SELECT public.enable_system_config_override(12000, 30, 'trial 12000/30 next day');

-- =========================================================
-- C) Monitoring pack (run every 2-3 mins during trial)
-- =========================================================
SELECT * FROM public.hybrid_ops_health;
SELECT * FROM public.hybrid_settlement_kpi;
SELECT * FROM public.hybrid_alert_queue_backlog;
SELECT * FROM public.hybrid_alert_error_spike;
SELECT * FROM public.hybrid_alert_recon_mismatch;

-- Recent settlement logs
SELECT
  created_at,
  run_id,
  stage,
  level,
  message,
  meta
FROM public.settlement_logs
WHERE created_at >= NOW() - INTERVAL '20 minutes'
ORDER BY created_at DESC
LIMIT 200;

-- =========================================================
-- D) Batch apply evidence (did worker actually apply rows?)
-- =========================================================
SELECT
  created_at,
  run_id,
  stage,
  message,
  (meta->>'claimed_rows')::INT AS claimed_rows,
  (meta->>'applied_rows')::INT AS applied_rows,
  (meta->>'admin_delta')::BIGINT AS admin_delta
FROM public.settlement_logs
WHERE stage = 'apply'
  AND created_at >= NOW() - INTERVAL '2 hours'
ORDER BY created_at DESC
LIMIT 100;

-- Approximate run duration by run_id (from first to last log in each run)
WITH run_apply AS (
  SELECT
    run_id,
    created_at AS apply_time,
    (meta->>'claimed_rows')::INT AS claimed_rows,
    (meta->>'applied_rows')::INT AS applied_rows
  FROM public.settlement_logs
  WHERE stage = 'apply'
    AND created_at >= NOW() - INTERVAL '2 hours'
),
run_span AS (
  SELECT
    run_id,
    MIN(created_at) AS first_log_at,
    MAX(created_at) AS last_log_at
  FROM public.settlement_logs
  WHERE created_at >= NOW() - INTERVAL '2 hours'
  GROUP BY run_id
)
SELECT
  a.run_id,
  a.claimed_rows,
  a.applied_rows,
  s.first_log_at,
  s.last_log_at,
  EXTRACT(EPOCH FROM (s.last_log_at - s.first_log_at)) AS approx_duration_sec
FROM run_apply a
JOIN run_span s USING (run_id)
ORDER BY a.apply_time DESC
LIMIT 100;

-- =========================================================
-- E) Emergency rollback (run immediately if unstable)
-- =========================================================
-- Known safe baseline:
-- SELECT public.enable_system_config_override(7000, 600, 'emergency rollback baseline');

-- Or disable override and return to auto-tier:
-- SELECT public.disable_system_config_override('trial ended - return to auto tier');
-- SELECT public.refresh_user_count_and_apply_tier();

-- =========================================================
-- F) End-of-trial closeout (run after each trial)
-- =========================================================
-- 1) Disable manual override
-- SELECT public.disable_system_config_override('trial complete');

-- 2) Force auto-tier refresh now
-- SELECT public.refresh_user_count_and_apply_tier();

-- 3) Confirm final state
SELECT *
FROM public.active_system_config_with_tier;

SELECT
  created_at,
  stage,
  level,
  message
FROM public.settlement_logs
WHERE stage IN ('override_enable', 'override_disable', 'auto_tier_refresh', 'tier_apply', 'tier_apply_override')
ORDER BY created_at DESC
LIMIT 50;
