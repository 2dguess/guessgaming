-- Phase 6: mission type/action improvements + midnight cleanup for non-daily tasks.
-- Run after phase1..phase5.

ALTER TABLE public.missions
  ADD COLUMN IF NOT EXISTS mission_action TEXT NOT NULL DEFAULT 'custom'
    CHECK (mission_action IN ('like', 'comment', 'watch', 'share', 'follow', 'custom'));

CREATE OR REPLACE FUNCTION public.admin_create_or_update_mission(
  p_mission_id UUID DEFAULT NULL,
  p_title TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_mission_type TEXT DEFAULT 'custom',
  p_reward_coin INTEGER DEFAULT 1000,
  p_daily_limit INTEGER DEFAULT 1,
  p_is_active BOOLEAN DEFAULT TRUE,
  p_starts_at TIMESTAMPTZ DEFAULT NULL,
  p_ends_at TIMESTAMPTZ DEFAULT NULL,
  p_verification_type TEXT DEFAULT 'manual',
  p_requires_proof BOOLEAN DEFAULT TRUE,
  p_action_link TEXT DEFAULT NULL,
  p_platform TEXT DEFAULT 'custom',
  p_mission_kind TEXT DEFAULT 'external_link',
  p_mission_action TEXT DEFAULT 'custom'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID;
  v_id UUID;
BEGIN
  v_admin_id := auth.uid();
  IF v_admin_id IS NULL OR NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF p_title IS NULL OR char_length(trim(p_title)) = 0 THEN
    RAISE EXCEPTION 'Mission title is required';
  END IF;

  IF p_reward_coin <= 0 THEN
    RAISE EXCEPTION 'reward_coin must be > 0';
  END IF;

  IF p_daily_limit <= 0 THEN
    RAISE EXCEPTION 'daily_limit must be > 0';
  END IF;

  IF p_mission_id IS NULL THEN
    INSERT INTO public.missions (
      title, description, reward_amount, reward_coin, frequency, mission_type,
      verification_type, daily_limit, is_active, starts_at, ends_at,
      requires_proof, action_link, platform, mission_kind, mission_action,
      created_by, updated_at
    )
    VALUES (
      p_title, p_description, p_reward_coin, p_reward_coin, 'daily', p_mission_type,
      p_verification_type, p_daily_limit, p_is_active, p_starts_at, p_ends_at,
      p_requires_proof, p_action_link, p_platform, p_mission_kind, p_mission_action,
      v_admin_id, NOW()
    )
    RETURNING mission_id INTO v_id;
  ELSE
    UPDATE public.missions
    SET
      title = p_title,
      description = p_description,
      reward_amount = p_reward_coin,
      reward_coin = p_reward_coin,
      mission_type = p_mission_type,
      verification_type = p_verification_type,
      daily_limit = p_daily_limit,
      is_active = p_is_active,
      starts_at = p_starts_at,
      ends_at = p_ends_at,
      requires_proof = p_requires_proof,
      action_link = p_action_link,
      platform = p_platform,
      mission_kind = p_mission_kind,
      mission_action = p_mission_action,
      updated_at = NOW()
    WHERE mission_id = p_mission_id;
    v_id := p_mission_id;
  END IF;

  RETURN jsonb_build_object('ok', TRUE, 'mission_id', v_id);
END;
$$;

-- Myanmar midnight cleanup: disable all non-daily_free_coin missions from previous day.
CREATE OR REPLACE FUNCTION public.admin_cleanup_non_daily_missions_mmt()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_now_mmt TIMESTAMP;
  v_today_start_mmt TIMESTAMP;
  v_today_start_utc TIMESTAMPTZ;
  v_affected INTEGER;
BEGIN
  v_now_mmt := timezone('Asia/Yangon', now());
  v_today_start_mmt := date_trunc('day', v_now_mmt);
  v_today_start_utc := (v_today_start_mmt AT TIME ZONE 'Asia/Yangon');

  UPDATE public.missions
  SET
    is_active = FALSE,
    ends_at = COALESCE(ends_at, NOW()),
    updated_at = NOW()
  WHERE mission_type <> 'daily_free_coin'
    AND created_at < v_today_start_utc
    AND is_active = TRUE;

  GET DIAGNOSTICS v_affected = ROW_COUNT;

  RETURN jsonb_build_object(
    'ok', TRUE,
    'disabled_missions', v_affected,
    'today_start_mmt', v_today_start_mmt
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_create_or_update_mission(
  UUID, TEXT, TEXT, TEXT, INTEGER, INTEGER, BOOLEAN, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, BOOLEAN, TEXT, TEXT, TEXT, TEXT
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_cleanup_non_daily_missions_mmt() TO authenticated;

