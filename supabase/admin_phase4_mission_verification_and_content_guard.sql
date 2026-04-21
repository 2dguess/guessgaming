-- Phase 4: Mission verification flow + content guard (18+ text/photo visibility control)
-- Run after phase1/2/3 files.

-- =========================================================
-- 1) Post moderation flags
-- =========================================================
ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS moderation_status TEXT NOT NULL DEFAULT 'approved'
    CHECK (moderation_status IN ('approved', 'pending_image_review', 'blocked', 'rejected')),
  ADD COLUMN IF NOT EXISTS moderation_reason TEXT NULL,
  ADD COLUMN IF NOT EXISTS moderated_at TIMESTAMPTZ NULL,
  ADD COLUMN IF NOT EXISTS moderated_by UUID NULL REFERENCES auth.users(id);

CREATE INDEX IF NOT EXISTS idx_posts_moderation_status_created
ON public.posts(moderation_status, created_at DESC);

CREATE OR REPLACE FUNCTION public.contains_blocked_text(p_text TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    p_text ~* '(?:\b18\+\b|\bsex\b|\bsexy\b|\bporn\b|\bxxx\b|\bnude\b|\bnsfw\b|adult\s*only)',
    FALSE
  );
$$;

CREATE OR REPLACE FUNCTION public.guard_post_content_before_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.contains_blocked_text(NEW.content) THEN
    NEW.moderation_status := 'blocked';
    NEW.moderation_reason := 'Blocked keyword detected';
    NEW.moderated_at := NOW();
    NEW.moderated_by := NULL;
    RETURN NEW;
  END IF;

  -- Strict safety mode: image posts stay hidden until admin approves.
  IF NEW.image_url IS NOT NULL AND btrim(NEW.image_url) <> '' THEN
    NEW.moderation_status := 'pending_image_review';
    NEW.moderation_reason := 'Pending image safety review';
    NEW.moderated_at := NOW();
    NEW.moderated_by := NULL;
  ELSE
    NEW.moderation_status := COALESCE(NEW.moderation_status, 'approved');
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_guard_post_content_before_insert ON public.posts;
CREATE TRIGGER trigger_guard_post_content_before_insert
BEFORE INSERT ON public.posts
FOR EACH ROW
EXECUTE FUNCTION public.guard_post_content_before_insert();

CREATE OR REPLACE FUNCTION public.admin_set_post_moderation(
  p_post_id UUID,
  p_status TEXT,
  p_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID;
BEGIN
  v_admin_id := auth.uid();
  IF v_admin_id IS NULL OR NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF p_status NOT IN ('approved', 'blocked', 'rejected') THEN
    RAISE EXCEPTION 'Invalid moderation status';
  END IF;

  UPDATE public.posts
  SET
    moderation_status = p_status,
    moderation_reason = p_reason,
    moderated_at = NOW(),
    moderated_by = v_admin_id
  WHERE post_id = p_post_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Post not found';
  END IF;

  INSERT INTO public.audit_logs(
    actor_admin_id, action, target_type, target_id, reason, meta, created_at
  ) VALUES (
    v_admin_id,
    'admin_set_post_moderation',
    'post',
    p_post_id,
    p_reason,
    jsonb_build_object('status', p_status),
    NOW()
  );

  RETURN jsonb_build_object('ok', TRUE, 'post_id', p_post_id, 'status', p_status);
END;
$$;

-- =========================================================
-- 2) Mission claim submit function with verification flow
-- =========================================================
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
  v_claim_id UUID;
  v_before_balance INTEGER;
  v_after_balance INTEGER;
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

  SELECT COUNT(*)::INT
  INTO v_existing_today
  FROM public.mission_claims mc
  WHERE mc.user_id = v_user_id
    AND mc.mission_id = p_mission_id
    AND mc.claimed_at >= date_trunc('day', NOW());

  IF v_existing_today >= COALESCE(v_mission.daily_limit, 1) THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'Daily claim limit reached');
  END IF;

  IF v_mission.mission_kind = 'reward_ad' THEN
    IF NOT COALESCE(p_ad_watched, FALSE) THEN
      RETURN jsonb_build_object('ok', FALSE, 'error', 'Watch ads first');
    END IF;

    INSERT INTO public.mission_claims (
      user_id, mission_id, status, proof_text, proof_url, claimed_at, reviewed_at, review_note
    )
    VALUES (
      v_user_id, p_mission_id, 'auto_approved', p_proof_text, p_proof_url, NOW(), NOW(), 'Auto approved: reward_ad'
    )
    RETURNING claim_id INTO v_claim_id;

    INSERT INTO public.wallets (user_id, balance, updated_at)
    VALUES (v_user_id, 0, NOW())
    ON CONFLICT (user_id) DO NOTHING;

    SELECT balance INTO v_before_balance
    FROM public.wallets
    WHERE user_id = v_user_id
    FOR UPDATE;

    v_after_balance := v_before_balance + v_mission.reward_coin;

    UPDATE public.wallets
    SET balance = v_after_balance, updated_at = NOW()
    WHERE user_id = v_user_id;

    INSERT INTO public.coin_transactions (
      user_id, delta, balance_after, source_type, source_id, note, created_by, created_at
    ) VALUES (
      v_user_id, v_mission.reward_coin, v_after_balance, 'ad_reward', p_mission_id,
      'Reward ad mission auto-approved', v_user_id, NOW()
    );

    RETURN jsonb_build_object(
      'ok', TRUE,
      'status', 'auto_approved',
      'claim_id', v_claim_id,
      'reward_coin', v_mission.reward_coin,
      'new_balance', v_after_balance
    );
  END IF;

  INSERT INTO public.mission_claims (
    user_id, mission_id, status, proof_text, proof_url, claimed_at
  )
  VALUES (
    v_user_id, p_mission_id, 'pending', p_proof_text, p_proof_url, NOW()
  )
  RETURNING claim_id INTO v_claim_id;

  RETURN jsonb_build_object(
    'ok', TRUE,
    'status', 'pending',
    'claim_id', v_claim_id
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_set_post_moderation(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_mission_claim(UUID, TEXT, TEXT, BOOLEAN) TO authenticated;

