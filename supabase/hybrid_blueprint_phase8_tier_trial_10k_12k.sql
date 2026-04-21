-- Hybrid Blueprint - Phase 8
-- Trial tuning: raise upper tiers gradually (cap 12k)
--
-- Goal:
-- - Keep low/mid tiers unchanged
-- - Lift high tiers carefully for throughput trials
-- - Provide quick rollback SQL at bottom

-- =========================================================
-- A) Apply trial tier values (active tiers only)
-- =========================================================
UPDATE public.system_config_tiers
SET
  batch_size = CASE
    WHEN min_users = 0       AND max_users = 250000  THEN 7000
    WHEN min_users = 250001  AND max_users = 500000  THEN 8000
    WHEN min_users = 500001  AND max_users = 1000000 THEN 9000   -- from 8000
    WHEN min_users = 1000001 AND max_users = 2500000 THEN 10000  -- from 8500
    WHEN min_users = 2500001 AND max_users = 5000000 THEN 12000  -- from 9000
    ELSE batch_size
  END,
  frequency_seconds = CASE
    WHEN min_users = 0       AND max_users = 250000  THEN 600
    WHEN min_users = 250001  AND max_users = 500000  THEN 360
    WHEN min_users = 500001  AND max_users = 1000000 THEN 180  -- slightly relaxed
    WHEN min_users = 1000001 AND max_users = 2500000 THEN 90
    WHEN min_users = 2500001 AND max_users = 5000000 THEN 60
    ELSE frequency_seconds
  END,
  updated_at = NOW(),
  note = COALESCE(note, 'Tier') || ' [trial 10k/12k]'
WHERE is_active = TRUE;

-- =========================================================
-- B) Re-apply active config using latest user count
-- =========================================================
SELECT public.apply_system_config_tier(
  COALESCE(
    (SELECT current_user_count
     FROM public.system_config
     WHERE is_active = TRUE
     ORDER BY updated_at DESC
     LIMIT 1),
    0
  )
);

-- =========================================================
-- C) Validation query
-- =========================================================
-- SELECT tier_id, min_users, max_users, batch_size, frequency_seconds, note
-- FROM public.system_config_tiers
-- WHERE is_active = TRUE
-- ORDER BY min_users;
--
-- SELECT * FROM public.active_system_config_with_tier;

-- =========================================================
-- D) Rollback block (manual, run only if needed)
-- =========================================================
-- UPDATE public.system_config_tiers
-- SET
--   batch_size = CASE
--     WHEN min_users = 0       AND max_users = 250000  THEN 7000
--     WHEN min_users = 250001  AND max_users = 500000  THEN 8000
--     WHEN min_users = 500001  AND max_users = 1000000 THEN 8000
--     WHEN min_users = 1000001 AND max_users = 2500000 THEN 8500
--     WHEN min_users = 2500001 AND max_users = 5000000 THEN 9000
--     ELSE batch_size
--   END,
--   frequency_seconds = CASE
--     WHEN min_users = 0       AND max_users = 250000  THEN 600
--     WHEN min_users = 250001  AND max_users = 500000  THEN 360
--     WHEN min_users = 500001  AND max_users = 1000000 THEN 150
--     WHEN min_users = 1000001 AND max_users = 2500000 THEN 72
--     WHEN min_users = 2500001 AND max_users = 5000000 THEN 60
--     ELSE frequency_seconds
--   END,
--   updated_at = NOW()
-- WHERE is_active = TRUE;
--
-- SELECT public.apply_system_config_tier(
--   COALESCE(
--     (SELECT current_user_count
--      FROM public.system_config
--      WHERE is_active = TRUE
--      ORDER BY updated_at DESC
--      LIMIT 1),
--     0
--   )
-- );
