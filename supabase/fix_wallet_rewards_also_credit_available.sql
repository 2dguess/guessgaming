-- Mission + math-game rewards must increment BOTH balance and available_balance
-- so the app (which shows available score) updates immediately.
-- Run once in Supabase SQL Editor.

-- ---------------------------------------------------------------------------
-- Instant mission claims (Number Quiz, ads, etc.)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_mission_claim(
  p_mission_id UUID,
  p_proof_text TEXT DEFAULT NULL,
  p_proof_url TEXT DEFAULT NULL,
  p_ad_watched BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_mission RECORD;
  v_existing_today INTEGER;
  v_mmt_day_start TIMESTAMPTZ;
  v_mmt_day_end TIMESTAMPTZ;
  v_claim_id UUID;
  v_reward INTEGER;
  v_before_balance INTEGER;
  v_before_avail INTEGER;
  v_after_balance INTEGER;
  v_after_avail INTEGER;
  v_status TEXT;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT *
  INTO v_mission
  FROM public.missions
  WHERE mission_id = p_mission_id
    AND is_active = TRUE
    AND (starts_at IS NULL OR starts_at <= NOW())
    AND (ends_at IS NULL OR ends_at >= NOW());

  IF v_mission.mission_id IS NULL THEN
    RAISE EXCEPTION 'Mission not found or inactive';
  END IF;

  -- Myanmar daily window: [00:00, next 00:00) Asia/Yangon.
  v_mmt_day_start := (date_trunc('day', timezone('Asia/Yangon', NOW())) AT TIME ZONE 'Asia/Yangon');
  v_mmt_day_end := v_mmt_day_start + INTERVAL '1 day';

  v_reward := COALESCE(
    v_mission.reward_coin,
    v_mission.reward_amount,
    0
  );

  SELECT COUNT(*)::INT
  INTO v_existing_today
  FROM public.mission_claims mc
  WHERE mc.user_id = v_user_id
    AND mc.mission_id = p_mission_id
    AND mc.claimed_at >= v_mmt_day_start
    AND mc.claimed_at < v_mmt_day_end;

  IF v_existing_today >= COALESCE(v_mission.daily_limit, 1) THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'Daily claim limit reached');
  END IF;

  IF COALESCE(v_mission.mission_kind, '') = 'reward_ad' AND NOT COALESCE(p_ad_watched, FALSE) THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'Watch ads first');
  END IF;

  v_status := CASE
    WHEN COALESCE(v_mission.mission_kind, '') = 'reward_ad' THEN 'auto_approved'
    ELSE 'approved'
  END;

  INSERT INTO public.mission_claims (
    user_id, mission_id, status, proof_text, proof_url, claimed_at, reviewed_at, review_note
  )
  VALUES (
    v_user_id, p_mission_id, v_status, p_proof_text, p_proof_url, NOW(), NOW(),
    'Instant auto reward (no admin review)'
  )
  RETURNING claim_id INTO v_claim_id;

  INSERT INTO public.wallets (user_id, balance, available_balance, locked_balance, updated_at)
  VALUES (v_user_id, 0, 0, 0, NOW())
  ON CONFLICT (user_id) DO NOTHING;

  SELECT balance, COALESCE(available_balance, balance, 0)
  INTO v_before_balance, v_before_avail
  FROM public.wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  v_after_balance := v_before_balance + v_reward;
  v_after_avail := v_before_avail + v_reward;

  UPDATE public.wallets
  SET
    balance = v_after_balance,
    available_balance = v_after_avail,
    updated_at = NOW()
  WHERE user_id = v_user_id;

  INSERT INTO public.coin_transactions (
    user_id, delta, balance_after, source_type, source_id, note, created_by, created_at
  ) VALUES (
    v_user_id, v_reward, v_after_balance,
    CASE
      WHEN COALESCE(v_mission.mission_kind, '') = 'reward_ad' THEN 'ad_reward'
      ELSE 'mission_claim'
    END,
    p_mission_id,
    'Instant mission reward',
    v_user_id,
    NOW()
  );

  RETURN jsonb_build_object(
    'ok', TRUE,
    'status', v_status,
    'claim_id', v_claim_id,
    'reward_coin', v_reward,
    'new_balance', v_after_balance,
    'new_available_balance', v_after_avail
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.submit_mission_claim(UUID, TEXT, TEXT, BOOLEAN) TO authenticated;

-- ---------------------------------------------------------------------------
-- Legacy daily mission RPC (if still deployed)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.complete_daily_mission(p_mission_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_reward INTEGER;
  v_last_claimed TIMESTAMPTZ;
  v_can_claim BOOLEAN;
  v_new_balance INTEGER;
  v_b INTEGER;
  v_a INTEGER;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  SELECT COALESCE(reward_amount, reward_coin, 0) INTO v_reward
  FROM missions
  WHERE mission_id = p_mission_id;

  IF v_reward IS NULL OR v_reward <= 0 THEN
    RETURN json_build_object('success', false, 'error', 'Mission not found');
  END IF;

  SELECT last_claimed_at INTO v_last_claimed
  FROM user_missions
  WHERE user_id = v_user_id AND mission_id = p_mission_id;

  v_can_claim := (v_last_claimed IS NULL)
    OR (DATE(v_last_claimed) < DATE(CURRENT_TIMESTAMP));

  IF NOT v_can_claim THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Already claimed today',
      'next_claim_at', (DATE(CURRENT_TIMESTAMP) + INTERVAL '1 day')::TIMESTAMP + INTERVAL '1 minute'
    );
  END IF;

  INSERT INTO user_missions (user_id, mission_id, last_claimed_at)
  VALUES (v_user_id, p_mission_id, CURRENT_TIMESTAMP)
  ON CONFLICT (user_id, mission_id)
  DO UPDATE SET last_claimed_at = CURRENT_TIMESTAMP;

  INSERT INTO public.wallets (user_id, balance, available_balance, locked_balance, updated_at)
  VALUES (v_user_id, v_reward, v_reward, 0, NOW())
  ON CONFLICT (user_id)
  DO UPDATE SET
    balance = public.wallets.balance + v_reward,
    available_balance = COALESCE(public.wallets.available_balance, public.wallets.balance, 0) + v_reward,
    updated_at = NOW()
  RETURNING balance INTO v_new_balance;

  RETURN json_build_object(
    'success', true,
    'reward', v_reward,
    'new_balance', v_new_balance
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.complete_daily_mission(UUID) TO authenticated;

-- ---------------------------------------------------------------------------
-- Math quiz rewards (same issue: only balance was updated)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.claim_math_game_reward(
  p_session_id UUID,
  p_kind TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_base_amount INTEGER := 500;
  v_ad_amount INTEGER := 1000;
  v_before INTEGER;
  v_before_avail INTEGER;
  v_after INTEGER;
  v_after_avail INTEGER;
  v_row public.math_game_reward_sessions%ROWTYPE;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'Not authenticated');
  END IF;

  IF p_kind NOT IN ('base', 'ad_bonus') THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'Invalid kind');
  END IF;

  INSERT INTO public.math_game_reward_sessions (session_id, user_id)
  VALUES (p_session_id, v_uid)
  ON CONFLICT (session_id) DO NOTHING;

  SELECT * INTO v_row
  FROM public.math_game_reward_sessions
  WHERE session_id = p_session_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'Invalid session');
  END IF;

  IF v_row.user_id IS DISTINCT FROM v_uid THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'Session mismatch');
  END IF;

  INSERT INTO public.wallets (user_id, balance, available_balance, locked_balance, updated_at)
  VALUES (v_uid, 0, 0, 0, NOW())
  ON CONFLICT (user_id) DO NOTHING;

  IF p_kind = 'base' THEN
    IF v_row.base_claimed_at IS NOT NULL THEN
      RETURN jsonb_build_object('ok', FALSE, 'error', 'Already claimed');
    END IF;

    SELECT balance, COALESCE(available_balance, balance, 0)
    INTO v_before, v_before_avail
    FROM public.wallets
    WHERE user_id = v_uid
    FOR UPDATE;

    v_after := v_before + v_base_amount;
    v_after_avail := v_before_avail + v_base_amount;

    UPDATE public.wallets
    SET
      balance = v_after,
      available_balance = v_after_avail,
      updated_at = NOW()
    WHERE user_id = v_uid;

    UPDATE public.math_game_reward_sessions
    SET base_claimed_at = NOW()
    WHERE session_id = p_session_id;

    INSERT INTO public.coin_transactions (
      user_id, delta, balance_after, source_type, source_id, note, created_by, created_at
    ) VALUES (
      v_uid, v_base_amount, v_after, 'system', p_session_id,
      'math_game_claim_500', v_uid, NOW()
    );

    RETURN jsonb_build_object(
      'ok', TRUE,
      'kind', 'base',
      'amount', v_base_amount,
      'new_balance', v_after,
      'new_available_balance', v_after_avail
    );
  END IF;

  IF v_row.base_claimed_at IS NULL THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'Claim base reward first');
  END IF;

  IF v_row.ad_bonus_claimed_at IS NOT NULL THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'Ad bonus already claimed');
  END IF;

  SELECT balance, COALESCE(available_balance, balance, 0)
  INTO v_before, v_before_avail
  FROM public.wallets
  WHERE user_id = v_uid
  FOR UPDATE;

  v_after := v_before + v_ad_amount;
  v_after_avail := v_before_avail + v_ad_amount;

  UPDATE public.wallets
  SET
    balance = v_after,
    available_balance = v_after_avail,
    updated_at = NOW()
  WHERE user_id = v_uid;

  UPDATE public.math_game_reward_sessions
  SET ad_bonus_claimed_at = NOW()
  WHERE session_id = p_session_id;

  INSERT INTO public.coin_transactions (
    user_id, delta, balance_after, source_type, source_id, note, created_by, created_at
  ) VALUES (
    v_uid, v_ad_amount, v_after, 'ad_reward', p_session_id,
    'math_game_ad_bonus_500x2', v_uid, NOW()
  );

  RETURN jsonb_build_object(
    'ok', TRUE,
    'kind', 'ad_bonus',
    'amount', v_ad_amount,
    'new_balance', v_after,
    'new_available_balance', v_after_avail
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.claim_math_game_reward(UUID, TEXT) TO authenticated;
