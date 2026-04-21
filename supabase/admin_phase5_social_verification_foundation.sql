-- Phase 5: Social verification foundation (Facebook/YouTube)
-- Goal: enable real verification pipeline with OAuth-linked accounts + job queue.
-- Run after phase1..phase4.

-- =========================================================
-- 1) User social account links (for verification identity)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.user_social_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('facebook', 'youtube')),
  platform_user_id TEXT NOT NULL,
  platform_username TEXT NULL,
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  verified_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_user_platform UNIQUE (user_id, platform),
  CONSTRAINT uq_platform_identity UNIQUE (platform, platform_user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_social_accounts_user
ON public.user_social_accounts(user_id, platform);

ALTER TABLE public.user_social_accounts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own social accounts" ON public.user_social_accounts;
CREATE POLICY "Users can read own social accounts" ON public.user_social_accounts
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own social accounts" ON public.user_social_accounts;
CREATE POLICY "Users can insert own social accounts" ON public.user_social_accounts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own social accounts" ON public.user_social_accounts;
CREATE POLICY "Users can update own social accounts" ON public.user_social_accounts
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can read all social accounts" ON public.user_social_accounts;
CREATE POLICY "Admins can read all social accounts" ON public.user_social_accounts
  FOR SELECT USING (public.is_current_user_admin());

-- =========================================================
-- 2) Mission verification jobs queue (processed by Edge Function/worker)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.mission_verification_jobs (
  job_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  claim_id UUID NOT NULL REFERENCES public.mission_claims(claim_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mission_id UUID NOT NULL REFERENCES public.missions(mission_id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('facebook', 'youtube', 'custom')),
  verification_action TEXT NOT NULL CHECK (
    verification_action IN ('follow_page', 'like_post', 'comment_post', 'share_post', 'watch_video', 'like_video', 'comment_video', 'custom')
  ),
  target_ref TEXT NULL, -- page_id / post_id / video_id / url
  status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'verified', 'failed', 'manual_review')),
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_error TEXT NULL,
  processed_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mission_verification_jobs_status_created
ON public.mission_verification_jobs(status, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_mission_verification_jobs_claim
ON public.mission_verification_jobs(claim_id);

ALTER TABLE public.mission_verification_jobs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can read verification jobs" ON public.mission_verification_jobs;
CREATE POLICY "Admins can read verification jobs" ON public.mission_verification_jobs
  FOR SELECT USING (public.is_current_user_admin());

DROP POLICY IF EXISTS "Users can read own verification jobs" ON public.mission_verification_jobs;
CREATE POLICY "Users can read own verification jobs" ON public.mission_verification_jobs
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "No direct insert verification jobs" ON public.mission_verification_jobs;
CREATE POLICY "No direct insert verification jobs" ON public.mission_verification_jobs
  FOR INSERT WITH CHECK (FALSE);

DROP POLICY IF EXISTS "No direct update verification jobs" ON public.mission_verification_jobs;
CREATE POLICY "No direct update verification jobs" ON public.mission_verification_jobs
  FOR UPDATE USING (FALSE);

-- =========================================================
-- 3) Queue helper: create claim + verification job together
-- =========================================================
CREATE OR REPLACE FUNCTION public.submit_social_mission_claim(
  p_mission_id UUID,
  p_proof_text TEXT DEFAULT NULL,
  p_proof_url TEXT DEFAULT NULL,
  p_target_ref TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_mission RECORD;
  v_claim_id UUID;
  v_action TEXT;
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

  IF COALESCE(v_mission.mission_kind, 'external_link') = 'reward_ad' THEN
    RETURN jsonb_build_object(
      'ok', FALSE,
      'error', 'Use submit_mission_claim with ad watched flag for reward_ad mission'
    );
  END IF;

  INSERT INTO public.mission_claims (
    user_id, mission_id, status, proof_text, proof_url, claimed_at
  )
  VALUES (
    v_user_id, p_mission_id, 'pending', p_proof_text, p_proof_url, NOW()
  )
  RETURNING claim_id INTO v_claim_id;

  v_action := CASE
    WHEN COALESCE(v_mission.mission_action, '') = 'follow' THEN 'follow_page'
    WHEN COALESCE(v_mission.mission_action, '') = 'share' THEN 'share_post'
    WHEN COALESCE(v_mission.mission_action, '') = 'comment' THEN 'comment_post'
    WHEN COALESCE(v_mission.mission_action, '') = 'watch' THEN 'watch_video'
    WHEN COALESCE(v_mission.mission_action, '') = 'like' THEN 'like_post'
    ELSE 'custom'
  END;

  INSERT INTO public.mission_verification_jobs (
    claim_id, user_id, mission_id, platform, verification_action, target_ref, status, created_at
  )
  VALUES (
    v_claim_id,
    v_user_id,
    p_mission_id,
    COALESCE(v_mission.platform, 'custom'),
    v_action,
    COALESCE(p_target_ref, v_mission.action_link),
    'queued',
    NOW()
  );

  RETURN jsonb_build_object(
    'ok', TRUE,
    'status', 'pending_verification',
    'claim_id', v_claim_id
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.submit_social_mission_claim(UUID, TEXT, TEXT, TEXT) TO authenticated;

