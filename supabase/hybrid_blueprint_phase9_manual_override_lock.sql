-- Hybrid Blueprint - Phase 9
-- Manual override lock for incident handling (freeze auto-tier updates)

-- =========================================================
-- 1) Override table (single active row pattern)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.system_config_override (
  id BIGSERIAL PRIMARY KEY,
  is_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  locked_batch_size INTEGER NULL CHECK (locked_batch_size IS NULL OR locked_batch_size > 0),
  locked_frequency_seconds INTEGER NULL CHECK (locked_frequency_seconds IS NULL OR locked_frequency_seconds > 0),
  reason TEXT NULL,
  locked_by UUID NULL REFERENCES auth.users(id),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Keep one row easy to manage.
INSERT INTO public.system_config_override (is_enabled, updated_at)
SELECT FALSE, NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.system_config_override);

-- =========================================================
-- 2) Enable / disable helpers
-- =========================================================
CREATE OR REPLACE FUNCTION public.enable_system_config_override(
  p_batch_size INTEGER,
  p_frequency_seconds INTEGER,
  p_reason TEXT DEFAULT 'manual override'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row_id BIGINT;
BEGIN
  IF p_batch_size <= 0 OR p_frequency_seconds <= 0 THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'Invalid override values');
  END IF;

  SELECT id INTO v_row_id
  FROM public.system_config_override
  ORDER BY id
  LIMIT 1;

  IF v_row_id IS NULL THEN
    INSERT INTO public.system_config_override (
      is_enabled,
      locked_batch_size,
      locked_frequency_seconds,
      reason,
      locked_by,
      updated_at
    )
    VALUES (TRUE, p_batch_size, p_frequency_seconds, p_reason, auth.uid(), NOW())
    RETURNING id INTO v_row_id;
  ELSE
    UPDATE public.system_config_override
    SET
      is_enabled = TRUE,
      locked_batch_size = p_batch_size,
      locked_frequency_seconds = p_frequency_seconds,
      reason = p_reason,
      locked_by = auth.uid(),
      updated_at = NOW()
    WHERE id = v_row_id;
  END IF;

  INSERT INTO public.settlement_logs (run_id, level, stage, message, meta)
  VALUES (
    gen_random_uuid(),
    'warn',
    'override_enable',
    'Manual system_config override enabled',
    jsonb_build_object(
      'batch_size', p_batch_size,
      'frequency_seconds', p_frequency_seconds,
      'reason', p_reason
    )
  );

  RETURN jsonb_build_object(
    'ok', TRUE,
    'is_enabled', TRUE,
    'batch_size', p_batch_size,
    'frequency_seconds', p_frequency_seconds
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.disable_system_config_override(
  p_reason TEXT DEFAULT 'manual override cleared'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row_id BIGINT;
BEGIN
  SELECT id INTO v_row_id
  FROM public.system_config_override
  ORDER BY id
  LIMIT 1;

  IF v_row_id IS NULL THEN
    RETURN jsonb_build_object('ok', TRUE, 'is_enabled', FALSE);
  END IF;

  UPDATE public.system_config_override
  SET
    is_enabled = FALSE,
    reason = p_reason,
    locked_by = auth.uid(),
    updated_at = NOW()
  WHERE id = v_row_id;

  INSERT INTO public.settlement_logs (run_id, level, stage, message, meta)
  VALUES (
    gen_random_uuid(),
    'info',
    'override_disable',
    'Manual system_config override disabled',
    jsonb_build_object('reason', p_reason)
  );

  RETURN jsonb_build_object('ok', TRUE, 'is_enabled', FALSE);
END;
$$;

-- =========================================================
-- 3) Patch tier apply function to honor override lock
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
  v_override RECORD;
BEGIN
  SELECT id, is_enabled, locked_batch_size, locked_frequency_seconds, reason
  INTO v_override
  FROM public.system_config_override
  ORDER BY id
  LIMIT 1;

  SELECT id INTO v_cfg_id
  FROM public.system_config
  WHERE is_active = TRUE
  ORDER BY updated_at DESC
  LIMIT 1;

  -- If override is enabled, skip tier mapping and force locked values.
  IF v_override.is_enabled IS TRUE THEN
    IF v_cfg_id IS NULL THEN
      INSERT INTO public.system_config (
        is_active, current_user_count, batch_size, frequency_seconds, max_attempts, updated_at
      )
      VALUES (
        TRUE,
        p_current_user_count,
        v_override.locked_batch_size,
        v_override.locked_frequency_seconds,
        5,
        NOW()
      )
      RETURNING id INTO v_cfg_id;
    ELSE
      UPDATE public.system_config
      SET
        current_user_count = p_current_user_count,
        batch_size = v_override.locked_batch_size,
        frequency_seconds = v_override.locked_frequency_seconds,
        updated_at = NOW()
      WHERE id = v_cfg_id;
    END IF;

    INSERT INTO public.settlement_logs (run_id, level, stage, message, meta)
    VALUES (
      gen_random_uuid(),
      'warn',
      'tier_apply_override',
      'apply_system_config_tier used manual override',
      jsonb_build_object(
        'current_user_count', p_current_user_count,
        'batch_size', v_override.locked_batch_size,
        'frequency_seconds', v_override.locked_frequency_seconds,
        'reason', v_override.reason
      )
    );

    RETURN jsonb_build_object(
      'ok', TRUE,
      'override_enabled', TRUE,
      'current_user_count', p_current_user_count,
      'batch_size', v_override.locked_batch_size,
      'frequency_seconds', v_override.locked_frequency_seconds
    );
  END IF;

  -- Normal tier mapping flow.
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
    'override_enabled', FALSE,
    'current_user_count', p_current_user_count,
    'batch_size', v_tier.batch_size,
    'frequency_seconds', v_tier.frequency_seconds
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.enable_system_config_override(INTEGER, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.disable_system_config_override(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.apply_system_config_tier(BIGINT) TO authenticated;

