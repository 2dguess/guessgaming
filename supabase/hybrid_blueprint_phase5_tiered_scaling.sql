-- Hybrid Blueprint - Phase 5
-- Tiered scaling configuration based on current_user_count

-- =========================================================
-- 1) Tier table
-- =========================================================
CREATE TABLE IF NOT EXISTS public.system_config_tiers (
  tier_id BIGSERIAL PRIMARY KEY,
  min_users BIGINT NOT NULL,
  max_users BIGINT NOT NULL,
  batch_size INTEGER NOT NULL,
  frequency_seconds INTEGER NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  note TEXT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (min_users >= 0),
  CHECK (max_users >= min_users),
  CHECK (batch_size > 0),
  CHECK (frequency_seconds > 0)
);

CREATE INDEX IF NOT EXISTS idx_system_config_tiers_active_range
ON public.system_config_tiers(is_active, min_users, max_users);

-- Optional uniqueness guard for exact duplicate ranges.
CREATE UNIQUE INDEX IF NOT EXISTS uq_system_config_tiers_exact_range
ON public.system_config_tiers(min_users, max_users)
WHERE is_active = TRUE;

-- =========================================================
-- 2) Seed tiers from requested strategy
-- =========================================================
-- 1 - 250k        => 7000 / 600s (10 min)
-- 250k - 500k     => 8000 / 360s (6 min)
-- 500k - 1M       => 8000 / 150s (2.5 min)
-- 1M - 2.5M       => 8500 / 72s  (1.2 min)
-- 2.5M - 5M       => 9000 / 60s  (1 min)
-- Keep 0 users included in first tier for bootstrap.

INSERT INTO public.system_config_tiers (min_users, max_users, batch_size, frequency_seconds, is_active, note)
VALUES
  (0,        250000, 7000, 600, TRUE, 'Tier 1'),
  (250001,   500000, 8000, 360, TRUE, 'Tier 2'),
  (500001,  1000000, 8000, 150, TRUE, 'Tier 3'),
  (1000001, 2500000, 8500,  72, TRUE, 'Tier 4'),
  (2500001, 5000000, 9000,  60, TRUE, 'Tier 5')
ON CONFLICT DO NOTHING;

-- =========================================================
-- 3) Apply matching tier to active system_config
-- =========================================================
CREATE OR REPLACE FUNCTION public.apply_system_config_tier(
  p_current_user_count BIGINT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tier RECORD;
  v_cfg_id BIGINT;
BEGIN
  SELECT tier_id, min_users, max_users, batch_size, frequency_seconds
  INTO v_tier
  FROM public.system_config_tiers
  WHERE is_active = TRUE
    AND p_current_user_count BETWEEN min_users AND max_users
  ORDER BY min_users DESC
  LIMIT 1;

  IF v_tier IS NULL THEN
    RETURN jsonb_build_object(
      'ok', FALSE,
      'error', 'NO_MATCHING_TIER',
      'current_user_count', p_current_user_count
    );
  END IF;

  SELECT id INTO v_cfg_id
  FROM public.system_config
  WHERE is_active = TRUE
  ORDER BY updated_at DESC
  LIMIT 1;

  IF v_cfg_id IS NULL THEN
    INSERT INTO public.system_config (
      is_active, current_user_count, batch_size, frequency_seconds, max_attempts, updated_at
    )
    VALUES (
      TRUE, p_current_user_count, v_tier.batch_size, v_tier.frequency_seconds, 5, NOW()
    )
    RETURNING id INTO v_cfg_id;
  ELSE
    UPDATE public.system_config
    SET
      current_user_count = p_current_user_count,
      batch_size = v_tier.batch_size,
      frequency_seconds = v_tier.frequency_seconds,
      updated_at = NOW()
    WHERE id = v_cfg_id;
  END IF;

  INSERT INTO public.settlement_logs (run_id, level, stage, message, meta)
  VALUES (
    gen_random_uuid(),
    'info',
    'tier_apply',
    'Applied system_config tier',
    jsonb_build_object(
      'tier_id', v_tier.tier_id,
      'current_user_count', p_current_user_count,
      'batch_size', v_tier.batch_size,
      'frequency_seconds', v_tier.frequency_seconds
    )
  );

  RETURN jsonb_build_object(
    'ok', TRUE,
    'tier_id', v_tier.tier_id,
    'current_user_count', p_current_user_count,
    'batch_size', v_tier.batch_size,
    'frequency_seconds', v_tier.frequency_seconds
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.apply_system_config_tier(BIGINT) TO authenticated;

-- =========================================================
-- 4) Convenience view
-- =========================================================
DROP VIEW IF EXISTS public.active_system_config_with_tier;
CREATE VIEW public.active_system_config_with_tier AS
SELECT
  c.id,
  c.current_user_count,
  c.batch_size,
  c.frequency_seconds,
  c.max_attempts,
  c.updated_at,
  t.tier_id,
  t.min_users,
  t.max_users,
  t.note AS tier_note
FROM public.system_config c
LEFT JOIN public.system_config_tiers t
  ON c.current_user_count BETWEEN t.min_users AND t.max_users
 AND t.is_active = TRUE
WHERE c.is_active = TRUE;

