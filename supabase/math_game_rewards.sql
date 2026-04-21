-- Math quiz win rewards: Claim 500 score; optional rewarded ad grants +1000 (500×2).
-- Run in Supabase SQL Editor after coin_transactions / wallets exist.

CREATE TABLE IF NOT EXISTS public.math_game_reward_sessions (
  session_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  base_claimed_at TIMESTAMPTZ NULL,
  ad_bonus_claimed_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT math_game_base_before_ad CHECK (
    ad_bonus_claimed_at IS NULL OR base_claimed_at IS NOT NULL
  )
);

CREATE INDEX IF NOT EXISTS idx_math_game_sessions_user_created
ON public.math_game_reward_sessions (user_id, created_at DESC);

ALTER TABLE public.math_game_reward_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own math game sessions" ON public.math_game_reward_sessions;
CREATE POLICY "Users read own math game sessions" ON public.math_game_reward_sessions
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "No direct insert math game sessions" ON public.math_game_reward_sessions;
CREATE POLICY "No direct insert math game sessions" ON public.math_game_reward_sessions
  FOR INSERT WITH CHECK (FALSE);

DROP POLICY IF EXISTS "No direct update math game sessions" ON public.math_game_reward_sessions;
CREATE POLICY "No direct update math game sessions" ON public.math_game_reward_sessions
  FOR UPDATE USING (FALSE);

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
      'new_balance', v_after
    );
  END IF;

  -- ad_bonus
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
    'new_balance', v_after
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.claim_math_game_reward(UUID, TEXT) TO authenticated;
