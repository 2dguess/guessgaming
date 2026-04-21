-- Phase 8: Instant mission rewards (no admin approval waiting)
-- Run after phase1..phase7.

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
  v_before_balance INTEGER;
  v_before_avail INTEGER;
  v_after_balance INTEGER;
  v_after_avail INTEGER;
  v_reward INTEGER;
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

  -- Reward ads mission requires watch flag before claim.
  IF COALESCE(v_mission.mission_kind, '') = 'reward_ad' AND NOT COALESCE(p_ad_watched, FALSE) THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'Watch ads first');
  END IF;

  -- Instant rewards for all mission types.
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

  v_reward := COALESCE(v_mission.reward_coin, v_mission.reward_amount, 0);
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

