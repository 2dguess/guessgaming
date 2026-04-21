-- Phase 9: Batched payout pipeline (10 min / 5 batches ready)
-- Run after previous phases.

-- =========================================================
-- 1) Payout run + jobs tables
-- =========================================================
CREATE TABLE IF NOT EXISTS public.payout_runs (
  run_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  winning_digit INTEGER NOT NULL CHECK (winning_digit >= 0 AND winning_digit <= 99),
  total_winners INTEGER NOT NULL DEFAULT 0,
  total_payout BIGINT NOT NULL DEFAULT 0,
  batch_count INTEGER NOT NULL DEFAULT 5,
  window_minutes INTEGER NOT NULL DEFAULT 10,
  status TEXT NOT NULL DEFAULT 'prepared' CHECK (status IN ('prepared', 'processing', 'completed', 'failed')),
  prepared_by UUID NULL REFERENCES auth.users(id),
  prepared_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ NULL
);

CREATE TABLE IF NOT EXISTS public.payout_jobs (
  job_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id UUID NOT NULL REFERENCES public.payout_runs(run_id) ON DELETE CASCADE,
  bet_id UUID NOT NULL REFERENCES public.bets(bet_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  payout_amount INTEGER NOT NULL CHECK (payout_amount > 0),
  batch_no INTEGER NOT NULL CHECK (batch_no >= 1),
  scheduled_at TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'paid', 'failed')),
  attempts INTEGER NOT NULL DEFAULT 0,
  error_message TEXT NULL,
  paid_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_payout_job_bet UNIQUE (bet_id)
);

CREATE INDEX IF NOT EXISTS idx_payout_jobs_due
ON public.payout_jobs(status, scheduled_at, batch_no);

ALTER TABLE public.payout_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payout_jobs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can read payout runs" ON public.payout_runs;
CREATE POLICY "Admins can read payout runs" ON public.payout_runs
FOR SELECT USING (public.is_current_user_admin());

DROP POLICY IF EXISTS "Admins can read payout jobs" ON public.payout_jobs;
CREATE POLICY "Admins can read payout jobs" ON public.payout_jobs
FOR SELECT USING (public.is_current_user_admin());

DROP POLICY IF EXISTS "No direct insert payout runs" ON public.payout_runs;
CREATE POLICY "No direct insert payout runs" ON public.payout_runs
FOR INSERT WITH CHECK (FALSE);
DROP POLICY IF EXISTS "No direct update payout runs" ON public.payout_runs;
CREATE POLICY "No direct update payout runs" ON public.payout_runs
FOR UPDATE USING (FALSE);

DROP POLICY IF EXISTS "No direct insert payout jobs" ON public.payout_jobs;
CREATE POLICY "No direct insert payout jobs" ON public.payout_jobs
FOR INSERT WITH CHECK (FALSE);
DROP POLICY IF EXISTS "No direct update payout jobs" ON public.payout_jobs;
CREATE POLICY "No direct update payout jobs" ON public.payout_jobs
FOR UPDATE USING (FALSE);

-- =========================================================
-- 2) Prepare batched payout jobs
-- - Marks pending bets => win/lose
-- - Reserves total payout from admin_wallet once
-- - Creates 5 scheduled batches across 10 minutes
-- =========================================================
CREATE OR REPLACE FUNCTION public.admin_prepare_batched_payout(
  p_winning_digit INTEGER,
  p_batch_count INTEGER DEFAULT 5,
  p_window_minutes INTEGER DEFAULT 10
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID;
  v_run_id UUID;
  v_total_payout BIGINT := 0;
  v_total_winners INTEGER := 0;
  v_admin_wallet_id UUID;
  v_admin_balance BIGINT;
BEGIN
  v_admin_id := auth.uid();
  IF v_admin_id IS NULL OR NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF p_winning_digit < 0 OR p_winning_digit > 99 THEN
    RAISE EXCEPTION 'Invalid winning digit';
  END IF;
  IF p_batch_count < 1 THEN
    RAISE EXCEPTION 'batch_count must be >= 1';
  END IF;
  IF p_window_minutes < 1 THEN
    RAISE EXCEPTION 'window_minutes must be >= 1';
  END IF;

  -- Single-writer settlement lock.
  IF NOT pg_try_advisory_lock(hashtext('payout_prepare_lock')) THEN
    RAISE EXCEPTION 'Another payout preparation is running';
  END IF;

  -- Mark winners and losers from current pending pool.
  UPDATE public.bets
  SET status = 'win'
  WHERE status = 'pending'
    AND digit = p_winning_digit;

  UPDATE public.bets
  SET status = 'lose'
  WHERE status = 'pending'
    AND digit <> p_winning_digit;

  SELECT
    COALESCE(COUNT(*), 0)::INTEGER,
    COALESCE(SUM(amount * 80), 0)::BIGINT
  INTO v_total_winners, v_total_payout
  FROM public.bets
  WHERE status = 'win'
    AND NOT EXISTS (
      SELECT 1 FROM public.payout_jobs pj WHERE pj.bet_id = bets.bet_id
    );

  INSERT INTO public.admin_wallet (balance, updated_at)
  VALUES (0, NOW())
  ON CONFLICT DO NOTHING;

  SELECT id, balance
  INTO v_admin_wallet_id, v_admin_balance
  FROM public.admin_wallet
  ORDER BY updated_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_admin_balance < v_total_payout THEN
    PERFORM pg_advisory_unlock(hashtext('payout_prepare_lock'));
    RAISE EXCEPTION 'Insufficient admin wallet balance for payout reserve';
  END IF;

  -- Reserve once (avoid overdraft while batches process).
  UPDATE public.admin_wallet
  SET balance = balance - v_total_payout, updated_at = NOW()
  WHERE id = v_admin_wallet_id;

  INSERT INTO public.payout_runs (
    winning_digit, total_winners, total_payout, batch_count, window_minutes, status, prepared_by, prepared_at
  ) VALUES (
    p_winning_digit, v_total_winners, v_total_payout, p_batch_count, p_window_minutes, 'prepared', v_admin_id, NOW()
  ) RETURNING run_id INTO v_run_id;

  -- Spread winners into N batches across window.
  WITH winners AS (
    SELECT
      b.bet_id,
      b.user_id,
      (b.amount * 80)::INTEGER AS payout_amount,
      ntile(p_batch_count) OVER (ORDER BY b.created_at, b.bet_id) AS batch_no
    FROM public.bets b
    WHERE b.status = 'win'
      AND NOT EXISTS (SELECT 1 FROM public.payout_jobs pj WHERE pj.bet_id = b.bet_id)
  )
  INSERT INTO public.payout_jobs (
    run_id, bet_id, user_id, payout_amount, batch_no, scheduled_at, status, created_at
  )
  SELECT
    v_run_id,
    w.bet_id,
    w.user_id,
    w.payout_amount,
    w.batch_no,
    NOW() + ((w.batch_no - 1) * (p_window_minutes::numeric / p_batch_count)) * INTERVAL '1 minute',
    'queued',
    NOW()
  FROM winners w;

  INSERT INTO public.audit_logs (
    actor_admin_id, action, target_type, target_id, meta, created_at
  ) VALUES (
    v_admin_id,
    'admin_prepare_batched_payout',
    'payout_run',
    v_run_id,
    jsonb_build_object(
      'winning_digit', p_winning_digit,
      'total_winners', v_total_winners,
      'total_payout', v_total_payout,
      'batch_count', p_batch_count,
      'window_minutes', p_window_minutes
    ),
    NOW()
  );

  PERFORM pg_advisory_unlock(hashtext('payout_prepare_lock'));

  RETURN jsonb_build_object(
    'ok', TRUE,
    'run_id', v_run_id,
    'total_winners', v_total_winners,
    'total_payout', v_total_payout
  );
EXCEPTION
  WHEN OTHERS THEN
    PERFORM pg_advisory_unlock(hashtext('payout_prepare_lock'));
    RAISE;
END;
$$;

-- =========================================================
-- 3) Process due payout jobs
-- - Safe for concurrent workers (SKIP LOCKED)
-- - Idempotent via uq_payout_job_bet + status machine
-- =========================================================
CREATE OR REPLACE FUNCTION public.process_due_payout_jobs(
  p_limit INTEGER DEFAULT 1000,
  p_max_attempts INTEGER DEFAULT 5
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_job RECORD;
  v_before INTEGER;
  v_before_avail INTEGER;
  v_after INTEGER;
  v_after_avail INTEGER;
  v_processed INTEGER := 0;
  v_paid INTEGER := 0;
  v_failed INTEGER := 0;
BEGIN
  FOR v_job IN
    SELECT *
    FROM public.payout_jobs
    WHERE status = 'queued'
      AND scheduled_at <= NOW()
    ORDER BY scheduled_at ASC, created_at ASC
    LIMIT GREATEST(1, LEAST(p_limit, 5000))
    FOR UPDATE SKIP LOCKED
  LOOP
    v_processed := v_processed + 1;
    BEGIN
      UPDATE public.payout_jobs
      SET status = 'processing', attempts = attempts + 1
      WHERE job_id = v_job.job_id;

      INSERT INTO public.wallets (user_id, balance, available_balance, locked_balance, updated_at)
      VALUES (v_job.user_id, 0, 0, 0, NOW())
      ON CONFLICT (user_id) DO NOTHING;

      SELECT balance, COALESCE(available_balance, balance, 0)
      INTO v_before, v_before_avail
      FROM public.wallets
      WHERE user_id = v_job.user_id
      FOR UPDATE;

      v_after := v_before + v_job.payout_amount;
      v_after_avail := v_before_avail + v_job.payout_amount;

      UPDATE public.wallets
      SET
        balance = v_after,
        available_balance = v_after_avail,
        updated_at = NOW()
      WHERE user_id = v_job.user_id;

      INSERT INTO public.coin_transactions (
        user_id, delta, balance_after, source_type, source_id, note, created_by, created_at
      ) VALUES (
        v_job.user_id, v_job.payout_amount, v_after, 'bet_win', v_job.bet_id,
        'Batched payout credit', v_job.user_id, NOW()
      );

      UPDATE public.payout_jobs
      SET status = 'paid', paid_at = NOW(), error_message = NULL
      WHERE job_id = v_job.job_id;

      v_paid := v_paid + 1;
    EXCEPTION
      WHEN OTHERS THEN
        UPDATE public.payout_jobs
        SET
          status = CASE WHEN attempts >= p_max_attempts THEN 'failed' ELSE 'queued' END,
          error_message = SQLERRM
        WHERE job_id = v_job.job_id;
        v_failed := v_failed + 1;
    END;
  END LOOP;

  -- Mark completed runs.
  UPDATE public.payout_runs pr
  SET
    status = 'completed',
    completed_at = NOW()
  WHERE pr.status IN ('prepared', 'processing')
    AND NOT EXISTS (
      SELECT 1
      FROM public.payout_jobs pj
      WHERE pj.run_id = pr.run_id
        AND pj.status IN ('queued', 'processing')
    );

  RETURN jsonb_build_object(
    'ok', TRUE,
    'processed', v_processed,
    'paid', v_paid,
    'failed', v_failed
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_prepare_batched_payout(INTEGER, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.process_due_payout_jobs(INTEGER, INTEGER) TO authenticated;

