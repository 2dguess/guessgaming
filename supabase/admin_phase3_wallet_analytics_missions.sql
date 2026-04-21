-- Admin App Phase 3: wallet funding, advanced analytics filters, mission links.
-- Run in Supabase SQL editor AFTER admin_phase1_foundation.sql and admin_phase2_ops.sql.

-- =========================================================
-- 1) Mission link fields (Facebook / YouTube / reward ads)
-- =========================================================
ALTER TABLE public.missions
  ADD COLUMN IF NOT EXISTS action_link TEXT NULL,
  ADD COLUMN IF NOT EXISTS platform TEXT NOT NULL DEFAULT 'custom',
  ADD COLUMN IF NOT EXISTS mission_kind TEXT NOT NULL DEFAULT 'external_link'
    CHECK (mission_kind IN ('external_link', 'reward_ad', 'custom'));

CREATE INDEX IF NOT EXISTS idx_missions_kind_active
ON public.missions(mission_kind, is_active, created_at DESC);

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
  p_mission_kind TEXT DEFAULT 'external_link'
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
      requires_proof, action_link, platform, mission_kind, created_by, updated_at
    )
    VALUES (
      p_title, p_description, p_reward_coin, p_reward_coin, 'daily', p_mission_type,
      p_verification_type, p_daily_limit, p_is_active, p_starts_at, p_ends_at,
      p_requires_proof, p_action_link, p_platform, p_mission_kind, v_admin_id, NOW()
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
      updated_at = NOW()
    WHERE mission_id = p_mission_id;
    v_id := p_mission_id;
  END IF;

  RETURN jsonb_build_object('ok', TRUE, 'mission_id', v_id);
END;
$$;

-- =========================================================
-- 2) Admin can fund admin wallet
-- =========================================================
CREATE OR REPLACE FUNCTION public.admin_fund_admin_wallet(
  p_amount INTEGER,
  p_reason TEXT DEFAULT 'manual admin wallet top-up'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID;
  v_wallet_id UUID;
  v_before INTEGER;
  v_after INTEGER;
BEGIN
  v_admin_id := auth.uid();
  IF v_admin_id IS NULL OR NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be > 0';
  END IF;

  INSERT INTO public.admin_wallet (balance, updated_at)
  VALUES (0, NOW())
  ON CONFLICT DO NOTHING;

  SELECT id, balance INTO v_wallet_id, v_before
  FROM public.admin_wallet
  ORDER BY updated_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_wallet_id IS NULL THEN
    RAISE EXCEPTION 'Admin wallet missing';
  END IF;

  v_after := v_before + p_amount;

  UPDATE public.admin_wallet
  SET balance = v_after, updated_at = NOW()
  WHERE id = v_wallet_id;

  INSERT INTO public.audit_logs (
    actor_admin_id, action, target_type, target_id, reason, before_data, after_data, created_at
  ) VALUES (
    v_admin_id,
    'admin_fund_admin_wallet',
    'admin_wallet',
    v_wallet_id,
    p_reason,
    jsonb_build_object('balance', v_before, 'amount', p_amount),
    jsonb_build_object('balance', v_after),
    NOW()
  );

  RETURN jsonb_build_object(
    'ok', TRUE,
    'wallet_id', v_wallet_id,
    'before_balance', v_before,
    'after_balance', v_after,
    'funded_amount', p_amount
  );
END;
$$;

-- =========================================================
-- 3) Dashboard stats with preset/custom time filter
-- =========================================================
CREATE OR REPLACE FUNCTION public.admin_dashboard_stats(
  p_preset TEXT DEFAULT 'day',
  p_from TIMESTAMPTZ DEFAULT NULL,
  p_to TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
  total_bet_user BIGINT,
  total_bet_amount BIGINT,
  total_win_user BIGINT,
  total_win_bet_amount BIGINT,
  total_lose_user BIGINT,
  total_bet_lose_amount BIGINT,
  admin_payout_amount BIGINT,
  admin_profit_amount BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH time_window AS (
    SELECT
      CASE
        WHEN p_preset = 'custom' AND p_from IS NOT NULL THEN p_from
        WHEN p_preset = 'week' THEN NOW() - INTERVAL '7 days'
        WHEN p_preset = 'month' THEN NOW() - INTERVAL '30 days'
        WHEN p_preset = 'session_330' THEN NOW() - INTERVAL '3 hours 30 minutes'
        ELSE NOW() - INTERVAL '1 day'
      END AS from_ts,
      CASE
        WHEN p_preset = 'custom' AND p_to IS NOT NULL THEN p_to
        ELSE NOW()
      END AS to_ts
  )
  SELECT
    COUNT(DISTINCT b.user_id)::BIGINT AS total_bet_user,
    COALESCE(SUM(b.amount), 0)::BIGINT AS total_bet_amount,
    COUNT(DISTINCT CASE WHEN b.status = 'win' THEN b.user_id END)::BIGINT AS total_win_user,
    COALESCE(SUM(CASE WHEN b.status = 'win' THEN b.amount ELSE 0 END), 0)::BIGINT AS total_win_bet_amount,
    COUNT(DISTINCT CASE WHEN b.status = 'lose' THEN b.user_id END)::BIGINT AS total_lose_user,
    COALESCE(SUM(CASE WHEN b.status = 'lose' THEN b.amount ELSE 0 END), 0)::BIGINT AS total_bet_lose_amount,
    COALESCE(SUM(CASE WHEN b.status = 'win' THEN b.amount * 80 ELSE 0 END), 0)::BIGINT AS admin_payout_amount,
    COALESCE(SUM(b.amount), 0)::BIGINT
      - COALESCE(SUM(CASE WHEN b.status = 'win' THEN b.amount * 80 ELSE 0 END), 0)::BIGINT AS admin_profit_amount
  FROM public.bets b
  CROSS JOIN time_window w
  WHERE public.is_current_user_admin()
    AND b.created_at >= w.from_ts
    AND b.created_at <= w.to_ts;
$$;

-- =========================================================
-- 4) Top 10 user balances + total user balance (exclude admin)
-- =========================================================
CREATE OR REPLACE FUNCTION public.admin_top10_non_admin_balances()
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  balance INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    w.user_id,
    p.username,
    w.balance
  FROM public.wallets w
  JOIN public.profiles p ON p.id = w.user_id
  WHERE public.is_current_user_admin()
    AND COALESCE(p.is_admin, FALSE) = FALSE
  ORDER BY w.balance DESC
  LIMIT 10;
$$;

CREATE OR REPLACE FUNCTION public.admin_total_non_admin_balance()
RETURNS BIGINT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(SUM(w.balance), 0)::BIGINT
  FROM public.wallets w
  JOIN public.profiles p ON p.id = w.user_id
  WHERE public.is_current_user_admin()
    AND COALESCE(p.is_admin, FALSE) = FALSE;
$$;

GRANT EXECUTE ON FUNCTION public.admin_fund_admin_wallet(INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_dashboard_stats(TEXT, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_top10_non_admin_balances() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_total_non_admin_balance() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_create_or_update_mission(
  UUID, TEXT, TEXT, TEXT, INTEGER, INTEGER, BOOLEAN, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, BOOLEAN, TEXT, TEXT, TEXT
) TO authenticated;

