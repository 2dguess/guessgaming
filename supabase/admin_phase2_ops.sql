-- Admin App Phase 2 Operations
-- Adds mission approve/reject workflow, reported posts queue, and betting KPIs.
-- Run in Supabase SQL editor AFTER admin_phase1_foundation.sql.

-- =========================================================
-- 1) Reported posts queue
-- =========================================================
CREATE TABLE IF NOT EXISTS public.reported_posts (
  report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.posts(post_id) ON DELETE CASCADE,
  reporter_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  details TEXT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed', 'action_taken')),
  reviewed_by UUID NULL REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_reported_post_once_per_user UNIQUE (post_id, reporter_user_id)
);

CREATE INDEX IF NOT EXISTS idx_reported_posts_status_created
ON public.reported_posts(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reported_posts_post
ON public.reported_posts(post_id);

ALTER TABLE public.reported_posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can create report for own uid" ON public.reported_posts;
CREATE POLICY "Users can create report for own uid" ON public.reported_posts
  FOR INSERT WITH CHECK (auth.uid() = reporter_user_id);

DROP POLICY IF EXISTS "Users can read own reports" ON public.reported_posts;
CREATE POLICY "Users can read own reports" ON public.reported_posts
  FOR SELECT USING (auth.uid() = reporter_user_id);

DROP POLICY IF EXISTS "Admins can read all reported posts" ON public.reported_posts;
CREATE POLICY "Admins can read all reported posts" ON public.reported_posts
  FOR SELECT USING (public.is_current_user_admin());

DROP POLICY IF EXISTS "No direct update reported posts" ON public.reported_posts;
CREATE POLICY "No direct update reported posts" ON public.reported_posts
  FOR UPDATE USING (FALSE);

DROP POLICY IF EXISTS "No direct delete reported posts" ON public.reported_posts;
CREATE POLICY "No direct delete reported posts" ON public.reported_posts
  FOR DELETE USING (FALSE);

-- =========================================================
-- 2) Mission claim review function (approve/reject)
-- =========================================================
CREATE OR REPLACE FUNCTION public.admin_review_mission_claim(
  p_claim_id UUID,
  p_status TEXT,
  p_review_note TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID;
  v_claim RECORD;
  v_reward INTEGER;
  v_before_balance INTEGER;
  v_after_balance INTEGER;
BEGIN
  v_admin_id := auth.uid();
  IF v_admin_id IS NULL OR NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF p_status NOT IN ('approved', 'rejected') THEN
    RAISE EXCEPTION 'Invalid status';
  END IF;

  SELECT mc.* INTO v_claim
  FROM public.mission_claims mc
  WHERE mc.claim_id = p_claim_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Mission claim not found';
  END IF;

  IF v_claim.status <> 'pending' THEN
    RAISE EXCEPTION 'Mission claim already reviewed';
  END IF;

  UPDATE public.mission_claims
  SET
    status = p_status,
    reviewed_at = NOW(),
    reviewed_by = v_admin_id,
    review_note = p_review_note
  WHERE claim_id = p_claim_id;

  IF p_status = 'approved' THEN
    SELECT m.reward_coin INTO v_reward
    FROM public.missions m
    WHERE m.mission_id = v_claim.mission_id;

    IF v_reward IS NULL OR v_reward <= 0 THEN
      RAISE EXCEPTION 'Mission reward not found';
    END IF;

    INSERT INTO public.wallets (user_id, balance, updated_at)
    VALUES (v_claim.user_id, 0, NOW())
    ON CONFLICT (user_id) DO NOTHING;

    SELECT w.balance INTO v_before_balance
    FROM public.wallets w
    WHERE w.user_id = v_claim.user_id
    FOR UPDATE;

    v_after_balance := v_before_balance + v_reward;

    UPDATE public.wallets
    SET balance = v_after_balance, updated_at = NOW()
    WHERE user_id = v_claim.user_id;

    INSERT INTO public.coin_transactions (
      user_id, delta, balance_after, source_type, source_id, note, created_by, created_at
    ) VALUES (
      v_claim.user_id, v_reward, v_after_balance, 'mission_claim', v_claim.mission_id,
      COALESCE(p_review_note, 'mission claim approved by admin'),
      v_admin_id, NOW()
    );
  END IF;

  INSERT INTO public.audit_logs (
    actor_admin_id, action, target_type, target_id, reason, meta, created_at
  ) VALUES (
    v_admin_id,
    'admin_review_mission_claim',
    'mission_claim',
    p_claim_id,
    p_review_note,
    jsonb_build_object('status', p_status),
    NOW()
  );

  RETURN jsonb_build_object(
    'ok', TRUE,
    'claim_id', p_claim_id,
    'status', p_status
  );
END;
$$;

-- =========================================================
-- 3) Review reported post helper
-- =========================================================
CREATE OR REPLACE FUNCTION public.admin_review_reported_post(
  p_report_id UUID,
  p_status TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID;
  v_post_id UUID;
BEGIN
  v_admin_id := auth.uid();
  IF v_admin_id IS NULL OR NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF p_status NOT IN ('reviewed', 'dismissed', 'action_taken') THEN
    RAISE EXCEPTION 'Invalid status';
  END IF;

  UPDATE public.reported_posts rp
  SET
    status = p_status,
    reviewed_by = v_admin_id,
    reviewed_at = NOW()
  WHERE rp.report_id = p_report_id
  RETURNING rp.post_id INTO v_post_id;

  IF v_post_id IS NULL THEN
    RAISE EXCEPTION 'Report not found';
  END IF;

  INSERT INTO public.audit_logs (
    actor_admin_id, action, target_type, target_id, meta, created_at
  ) VALUES (
    v_admin_id,
    'admin_review_reported_post',
    'reported_post',
    p_report_id,
    jsonb_build_object('status', p_status),
    NOW()
  );

  RETURN jsonb_build_object('ok', TRUE, 'report_id', p_report_id, 'status', p_status);
END;
$$;

-- =========================================================
-- 4) Bet KPI function for dashboard
-- =========================================================
CREATE OR REPLACE FUNCTION public.admin_bet_kpis(
  p_days INTEGER DEFAULT 1
)
RETURNS TABLE (
  bet_users BIGINT,
  win_users BIGINT,
  lose_users BIGINT,
  total_stake BIGINT,
  total_payout BIGINT,
  admin_profit BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    COUNT(DISTINCT b.user_id)::BIGINT AS bet_users,
    COUNT(DISTINCT CASE WHEN b.status = 'win' THEN b.user_id END)::BIGINT AS win_users,
    COUNT(DISTINCT CASE WHEN b.status = 'lose' THEN b.user_id END)::BIGINT AS lose_users,
    COALESCE(SUM(b.amount), 0)::BIGINT AS total_stake,
    COALESCE(SUM(CASE WHEN b.status = 'win' THEN b.amount * 80 ELSE 0 END), 0)::BIGINT AS total_payout,
    COALESCE(SUM(b.amount), 0)::BIGINT
      - COALESCE(SUM(CASE WHEN b.status = 'win' THEN b.amount * 80 ELSE 0 END), 0)::BIGINT AS admin_profit
  FROM public.bets b
  WHERE public.is_current_user_admin()
    AND b.created_at >= NOW() - make_interval(days => GREATEST(1, p_days));
$$;

GRANT EXECUTE ON FUNCTION public.admin_review_mission_claim(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_review_reported_post(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_bet_kpis(INTEGER) TO authenticated;

