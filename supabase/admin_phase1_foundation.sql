-- Admin App Phase 1 Foundation
-- Safe incremental migration for existing projects.

-- =========================================================
-- 1) Profiles: add admin + moderation flags
-- =========================================================
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS is_super_admin BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS is_banned BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS banned_until TIMESTAMPTZ NULL,
  ADD COLUMN IF NOT EXISTS ban_reason TEXT NULL,
  ADD COLUMN IF NOT EXISTS banned_by UUID NULL REFERENCES auth.users(id);

CREATE INDEX IF NOT EXISTS idx_profiles_is_admin ON public.profiles(is_admin);
CREATE INDEX IF NOT EXISTS idx_profiles_is_banned ON public.profiles(is_banned, banned_until);

-- =========================================================
-- 2) Posts: add moderation soft-delete fields
-- =========================================================
ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ NULL,
  ADD COLUMN IF NOT EXISTS deleted_reason TEXT NULL,
  ADD COLUMN IF NOT EXISTS deleted_by UUID NULL REFERENCES auth.users(id);

CREATE INDEX IF NOT EXISTS idx_posts_not_deleted_created
ON public.posts(is_deleted, created_at DESC);

-- =========================================================
-- 3) Audit log for admin actions
-- =========================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_admin_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  action TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id UUID NULL,
  reason TEXT NULL,
  before_data JSONB NULL,
  after_data JSONB NULL,
  meta JSONB NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor_created
ON public.audit_logs(actor_admin_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_target_created
ON public.audit_logs(target_type, target_id, created_at DESC);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can read audit logs" ON public.audit_logs;
CREATE POLICY "Admins can read audit logs" ON public.audit_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.is_admin = TRUE
    )
  );

-- Writes should happen via SECURITY DEFINER functions only.
DROP POLICY IF EXISTS "No direct insert audit logs" ON public.audit_logs;
CREATE POLICY "No direct insert audit logs" ON public.audit_logs
  FOR INSERT WITH CHECK (FALSE);

DROP POLICY IF EXISTS "No direct update audit logs" ON public.audit_logs;
CREATE POLICY "No direct update audit logs" ON public.audit_logs
  FOR UPDATE USING (FALSE);

DROP POLICY IF EXISTS "No direct delete audit logs" ON public.audit_logs;
CREATE POLICY "No direct delete audit logs" ON public.audit_logs
  FOR DELETE USING (FALSE);

-- =========================================================
-- 4) Coin transactions ledger (anti-cheat + tracing)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.coin_transactions (
  tx_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  delta INTEGER NOT NULL,
  balance_after INTEGER NOT NULL CHECK (balance_after >= 0),
  source_type TEXT NOT NULL CHECK (
    source_type IN (
      'bet_stake',
      'bet_win',
      'mission_claim',
      'ad_reward',
      'admin_adjust',
      'refund',
      'system'
    )
  ),
  source_id UUID NULL,
  note TEXT NULL,
  meta JSONB NULL,
  created_by UUID NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_coin_tx_user_created
ON public.coin_transactions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_coin_tx_source_created
ON public.coin_transactions(source_type, created_at DESC);

ALTER TABLE public.coin_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own coin transactions" ON public.coin_transactions;
CREATE POLICY "Users can read own coin transactions" ON public.coin_transactions
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can read all coin transactions" ON public.coin_transactions;
CREATE POLICY "Admins can read all coin transactions" ON public.coin_transactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.is_admin = TRUE
    )
  );

DROP POLICY IF EXISTS "No direct insert coin transactions" ON public.coin_transactions;
CREATE POLICY "No direct insert coin transactions" ON public.coin_transactions
  FOR INSERT WITH CHECK (FALSE);

DROP POLICY IF EXISTS "No direct update coin transactions" ON public.coin_transactions;
CREATE POLICY "No direct update coin transactions" ON public.coin_transactions
  FOR UPDATE USING (FALSE);

DROP POLICY IF EXISTS "No direct delete coin transactions" ON public.coin_transactions;
CREATE POLICY "No direct delete coin transactions" ON public.coin_transactions
  FOR DELETE USING (FALSE);

-- =========================================================
-- 5) Missions: enrich existing table for admin-managed tasks
-- =========================================================
ALTER TABLE public.missions
  ADD COLUMN IF NOT EXISTS mission_type TEXT NOT NULL DEFAULT 'custom',
  ADD COLUMN IF NOT EXISTS verification_type TEXT NOT NULL DEFAULT 'manual' CHECK (verification_type IN ('manual', 'auto')),
  ADD COLUMN IF NOT EXISTS reward_coin INTEGER NULL,
  ADD COLUMN IF NOT EXISTS daily_limit INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS starts_at TIMESTAMPTZ NULL,
  ADD COLUMN IF NOT EXISTS ends_at TIMESTAMPTZ NULL,
  ADD COLUMN IF NOT EXISTS requires_proof BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS created_by UUID NULL REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

UPDATE public.missions
SET reward_coin = reward_amount
WHERE reward_coin IS NULL;

ALTER TABLE public.missions
  ALTER COLUMN reward_coin SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_missions_active_type
ON public.missions(is_active, mission_type, created_at DESC);

-- Claim workflow (pending/approved/rejected)
CREATE TABLE IF NOT EXISTS public.mission_claims (
  claim_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mission_id UUID NOT NULL REFERENCES public.missions(mission_id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'auto_approved')),
  proof_text TEXT NULL,
  proof_url TEXT NULL,
  claimed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ NULL,
  reviewed_by UUID NULL REFERENCES auth.users(id),
  review_note TEXT NULL
);

CREATE INDEX IF NOT EXISTS idx_mission_claims_user_created
ON public.mission_claims(user_id, claimed_at DESC);
CREATE INDEX IF NOT EXISTS idx_mission_claims_status_created
ON public.mission_claims(status, claimed_at DESC);

ALTER TABLE public.mission_claims ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own mission claims" ON public.mission_claims;
CREATE POLICY "Users can read own mission claims" ON public.mission_claims
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can read all mission claims" ON public.mission_claims;
CREATE POLICY "Admins can read all mission claims" ON public.mission_claims
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.is_admin = TRUE
    )
  );

DROP POLICY IF EXISTS "Users can create own mission claims" ON public.mission_claims;
CREATE POLICY "Users can create own mission claims" ON public.mission_claims
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "No direct update mission claims" ON public.mission_claims;
CREATE POLICY "No direct update mission claims" ON public.mission_claims
  FOR UPDATE USING (FALSE);

DROP POLICY IF EXISTS "No direct delete mission claims" ON public.mission_claims;
CREATE POLICY "No direct delete mission claims" ON public.mission_claims
  FOR DELETE USING (FALSE);

-- =========================================================
-- 6) Helper + admin RPC functions
-- =========================================================
CREATE OR REPLACE FUNCTION public.is_current_user_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.is_admin = TRUE
      AND (
        p.is_banned = FALSE
        OR p.banned_until IS NULL
        OR p.banned_until <= NOW()
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.admin_adjust_user_coin(
  p_user_id UUID,
  p_delta INTEGER,
  p_reason TEXT DEFAULT 'manual admin adjustment'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID;
  v_before_balance INTEGER;
  v_after_balance INTEGER;
BEGIN
  v_admin_id := auth.uid();
  IF v_admin_id IS NULL OR NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF p_delta = 0 THEN
    RAISE EXCEPTION 'Delta cannot be 0';
  END IF;

  INSERT INTO public.wallets (user_id, balance, updated_at)
  VALUES (p_user_id, 0, NOW())
  ON CONFLICT (user_id) DO NOTHING;

  SELECT balance INTO v_before_balance
  FROM public.wallets
  WHERE user_id = p_user_id
  FOR UPDATE;

  v_after_balance := v_before_balance + p_delta;
  IF v_after_balance < 0 THEN
    RAISE EXCEPTION 'Insufficient balance for deduction';
  END IF;

  UPDATE public.wallets
  SET balance = v_after_balance, updated_at = NOW()
  WHERE user_id = p_user_id;

  INSERT INTO public.coin_transactions (
    user_id, delta, balance_after, source_type, note, created_by, created_at
  ) VALUES (
    p_user_id, p_delta, v_after_balance, 'admin_adjust', p_reason, v_admin_id, NOW()
  );

  INSERT INTO public.audit_logs (
    actor_admin_id, action, target_type, target_id, reason, before_data, after_data, created_at
  ) VALUES (
    v_admin_id,
    'admin_adjust_user_coin',
    'user',
    p_user_id,
    p_reason,
    jsonb_build_object('balance', v_before_balance, 'delta', p_delta),
    jsonb_build_object('balance', v_after_balance),
    NOW()
  );

  RETURN jsonb_build_object(
    'ok', TRUE,
    'user_id', p_user_id,
    'before_balance', v_before_balance,
    'after_balance', v_after_balance,
    'delta', p_delta
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_ban_user(
  p_user_id UUID,
  p_is_banned BOOLEAN,
  p_banned_until TIMESTAMPTZ DEFAULT NULL,
  p_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID;
  v_before JSONB;
  v_after JSONB;
BEGIN
  v_admin_id := auth.uid();
  IF v_admin_id IS NULL OR NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT jsonb_build_object(
    'is_banned', p.is_banned,
    'banned_until', p.banned_until,
    'ban_reason', p.ban_reason
  )
  INTO v_before
  FROM public.profiles p
  WHERE p.id = p_user_id;

  IF v_before IS NULL THEN
    RAISE EXCEPTION 'User profile not found';
  END IF;

  UPDATE public.profiles
  SET
    is_banned = p_is_banned,
    banned_until = CASE WHEN p_is_banned THEN p_banned_until ELSE NULL END,
    ban_reason = CASE WHEN p_is_banned THEN p_reason ELSE NULL END,
    banned_by = CASE WHEN p_is_banned THEN v_admin_id ELSE NULL END
  WHERE id = p_user_id;

  SELECT jsonb_build_object(
    'is_banned', p.is_banned,
    'banned_until', p.banned_until,
    'ban_reason', p.ban_reason
  )
  INTO v_after
  FROM public.profiles p
  WHERE p.id = p_user_id;

  INSERT INTO public.audit_logs (
    actor_admin_id, action, target_type, target_id, reason, before_data, after_data, created_at
  ) VALUES (
    v_admin_id,
    'admin_ban_user',
    'user',
    p_user_id,
    p_reason,
    v_before,
    v_after,
    NOW()
  );

  RETURN jsonb_build_object('ok', TRUE, 'user_id', p_user_id, 'is_banned', p_is_banned);
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_soft_delete_post(
  p_post_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID;
  v_before JSONB;
BEGIN
  v_admin_id := auth.uid();
  IF v_admin_id IS NULL OR NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT jsonb_build_object(
    'is_deleted', p.is_deleted,
    'content', p.content,
    'user_id', p.user_id
  )
  INTO v_before
  FROM public.posts p
  WHERE p.post_id = p_post_id;

  IF v_before IS NULL THEN
    RAISE EXCEPTION 'Post not found';
  END IF;

  UPDATE public.posts
  SET
    is_deleted = TRUE,
    deleted_at = NOW(),
    deleted_reason = p_reason,
    deleted_by = v_admin_id
  WHERE post_id = p_post_id;

  INSERT INTO public.audit_logs (
    actor_admin_id, action, target_type, target_id, reason, before_data, after_data, created_at
  ) VALUES (
    v_admin_id,
    'admin_soft_delete_post',
    'post',
    p_post_id,
    p_reason,
    v_before,
    jsonb_build_object('is_deleted', TRUE),
    NOW()
  );

  RETURN jsonb_build_object('ok', TRUE, 'post_id', p_post_id, 'is_deleted', TRUE);
END;
$$;

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
  p_requires_proof BOOLEAN DEFAULT TRUE
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
      requires_proof, created_by, updated_at
    )
    VALUES (
      p_title, p_description, p_reward_coin, p_reward_coin, 'daily', p_mission_type,
      p_verification_type, p_daily_limit, p_is_active, p_starts_at, p_ends_at,
      p_requires_proof, v_admin_id, NOW()
    )
    RETURNING mission_id INTO v_id;

    INSERT INTO public.audit_logs (
      actor_admin_id, action, target_type, target_id, after_data, created_at
    ) VALUES (
      v_admin_id,
      'admin_create_mission',
      'mission',
      v_id,
      jsonb_build_object('title', p_title, 'reward_coin', p_reward_coin),
      NOW()
    );
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
      updated_at = NOW()
    WHERE mission_id = p_mission_id;

    v_id := p_mission_id;

    INSERT INTO public.audit_logs (
      actor_admin_id, action, target_type, target_id, after_data, created_at
    ) VALUES (
      v_admin_id,
      'admin_update_mission',
      'mission',
      v_id,
      jsonb_build_object('title', p_title, 'reward_coin', p_reward_coin),
      NOW()
    );
  END IF;

  RETURN jsonb_build_object('ok', TRUE, 'mission_id', v_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_top10_user_coin_flows(
  p_days INTEGER DEFAULT 7
)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  balance INTEGER,
  inflow BIGINT,
  outflow BIGINT,
  bet_win_inflow BIGINT,
  admin_adjust_inflow BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    w.user_id,
    pr.username,
    w.balance,
    COALESCE(SUM(CASE WHEN ct.delta > 0 THEN ct.delta ELSE 0 END), 0)::BIGINT AS inflow,
    COALESCE(SUM(CASE WHEN ct.delta < 0 THEN ABS(ct.delta) ELSE 0 END), 0)::BIGINT AS outflow,
    COALESCE(SUM(CASE WHEN ct.source_type = 'bet_win' THEN GREATEST(ct.delta, 0) ELSE 0 END), 0)::BIGINT AS bet_win_inflow,
    COALESCE(SUM(CASE WHEN ct.source_type = 'admin_adjust' THEN GREATEST(ct.delta, 0) ELSE 0 END), 0)::BIGINT AS admin_adjust_inflow
  FROM public.wallets w
  JOIN public.profiles pr ON pr.id = w.user_id
  LEFT JOIN public.coin_transactions ct
    ON ct.user_id = w.user_id
   AND ct.created_at >= NOW() - make_interval(days => GREATEST(1, p_days))
  WHERE public.is_current_user_admin()
  GROUP BY w.user_id, pr.username, w.balance
  ORDER BY w.balance DESC
  LIMIT 10;
$$;

-- =========================================================
-- 7) Grants (authenticated only; admin check inside functions)
-- =========================================================
GRANT EXECUTE ON FUNCTION public.is_current_user_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_adjust_user_coin(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_ban_user(UUID, BOOLEAN, TIMESTAMPTZ, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_soft_delete_post(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_create_or_update_mission(UUID, TEXT, TEXT, TEXT, INTEGER, INTEGER, BOOLEAN, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_top10_user_coin_flows(INTEGER) TO authenticated;

