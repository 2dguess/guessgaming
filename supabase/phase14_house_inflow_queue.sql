-- Phase 14: queue-based house pool inflow for very high concurrency
-- Goal:
-- - place_bet does NOT update house shard immediately (reduces hot-row contention)
-- - place_bet enqueues inflow rows
-- - worker processes queued inflows in batches and updates shards once per shard

-- =========================================================
-- 1) Queue table
-- =========================================================
CREATE TABLE IF NOT EXISTS public.house_inflow_queue (
  inflow_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bet_id UUID UNIQUE NOT NULL REFERENCES public.bets(bet_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  shard_id INTEGER NOT NULL,
  amount INTEGER NOT NULL CHECK (amount > 0),
  status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'applied', 'failed')),
  attempts INTEGER NOT NULL DEFAULT 0,
  error_message TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  applied_at TIMESTAMPTZ NULL
);

ALTER TABLE public.house_inflow_queue
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.house_inflow_queue
  ADD COLUMN IF NOT EXISTS applied_at TIMESTAMPTZ NULL;

CREATE INDEX IF NOT EXISTS idx_house_inflow_queue_due
  ON public.house_inflow_queue(status, created_at);

ALTER TABLE public.house_inflow_queue ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can read house inflow queue" ON public.house_inflow_queue;
CREATE POLICY "Admins can read house inflow queue"
  ON public.house_inflow_queue FOR SELECT
  USING (public.is_current_user_admin());
DROP POLICY IF EXISTS "No direct insert house inflow queue" ON public.house_inflow_queue;
CREATE POLICY "No direct insert house inflow queue"
  ON public.house_inflow_queue FOR INSERT WITH CHECK (FALSE);
DROP POLICY IF EXISTS "No direct update house inflow queue" ON public.house_inflow_queue;
CREATE POLICY "No direct update house inflow queue"
  ON public.house_inflow_queue FOR UPDATE USING (FALSE);

-- =========================================================
-- 2) place_bet => enqueue inflow (no immediate house shard update)
-- =========================================================
CREATE OR REPLACE FUNCTION public.place_bet (p_digit INTEGER, p_amount INTEGER)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_current_balance INTEGER;
  v_new_balance INTEGER;
  v_slot TEXT;
  v_draw_date DATE;
  v_bet_id UUID;
  v_shard_id INTEGER;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', FALSE, 'error', 'Not authenticated');
  END IF;

  IF p_digit < 0 OR p_digit > 99 THEN
    RETURN json_build_object('success', FALSE, 'error', 'Invalid digit (must be 0-99)');
  END IF;

  IF p_amount < 100 THEN
    RETURN json_build_object('success', FALSE, 'error', 'Minimum bet is 100 coins');
  END IF;

  v_slot := public.bet_draw_slot_yangon(CURRENT_TIMESTAMP);
  v_draw_date := public.bet_draw_date_yangon(CURRENT_TIMESTAMP);

  IF v_slot IS NULL THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'betting_closed',
      'message', 'Betting only Mon-Fri, 06:00-11:40 and 13:00-16:10 (Myanmar time), excluding SET holidays.'
    );
  END IF;

  SELECT balance INTO v_current_balance
  FROM public.wallets
  WHERE user_id = v_user_id;

  IF v_current_balance IS NULL THEN
    v_current_balance := 0;
  END IF;

  IF v_current_balance < p_amount THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Insufficient balance',
      'current_balance', v_current_balance,
      'required', p_amount
    );
  END IF;

  UPDATE public.wallets
  SET balance = balance - p_amount, updated_at = CURRENT_TIMESTAMP
  WHERE user_id = v_user_id
  RETURNING balance INTO v_new_balance;

  INSERT INTO public.bets (
    user_id, digit, amount, status, created_at, draw_slot, draw_date
  )
  VALUES (
    v_user_id, p_digit, p_amount, 'pending', CURRENT_TIMESTAMP, v_slot, v_draw_date
  )
  RETURNING bet_id INTO v_bet_id;

  v_shard_id := public.shard_for_uuid(v_user_id, 64);
  INSERT INTO public.house_inflow_queue (
    bet_id, user_id, shard_id, amount, status, created_at
  )
  VALUES (
    v_bet_id, v_user_id, v_shard_id, p_amount, 'queued', NOW()
  )
  ON CONFLICT (bet_id) DO NOTHING;

  RETURN json_build_object(
    'success', TRUE,
    'new_balance', v_new_balance,
    'bet_amount', p_amount,
    'digit', p_digit,
    'draw_slot', v_slot,
    'draw_date', v_draw_date
  );
END;
$$;

-- =========================================================
-- 3) Worker: apply queued inflow rows in batches
-- =========================================================
DROP FUNCTION IF EXISTS public.process_house_inflow_queue(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.process_house_inflow_queue(INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION public.process_house_inflow_queue(
  p_limit INTEGER DEFAULT 5000,
  p_max_attempts INTEGER DEFAULT 5,
  p_requeue_after_seconds INTEGER DEFAULT 120
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_processed INTEGER := 0;
  v_applied INTEGER := 0;
  v_failed INTEGER := 0;
  v_requeued INTEGER := 0;
BEGIN
  -- Self-heal: stale processing rows are re-queued.
  UPDATE public.house_inflow_queue
  SET
    status = 'queued',
    updated_at = NOW(),
    error_message = COALESCE(error_message, 'auto-requeued stale processing row')
  WHERE status = 'processing'
    AND updated_at < NOW() - make_interval(secs => GREATEST(10, p_requeue_after_seconds))
    AND attempts < p_max_attempts;
  GET DIAGNOSTICS v_requeued = ROW_COUNT;

  DROP TABLE IF EXISTS _inflow_picked;
  CREATE TEMP TABLE _inflow_picked (
    inflow_id UUID PRIMARY KEY,
    shard_id INTEGER NOT NULL,
    amount INTEGER NOT NULL
  ) ON COMMIT DROP;

  INSERT INTO _inflow_picked (inflow_id, shard_id, amount)
  SELECT q.inflow_id, q.shard_id, q.amount
  FROM public.house_inflow_queue q
  WHERE q.status = 'queued'
  ORDER BY q.created_at ASC
  LIMIT GREATEST(1, LEAST(p_limit, 20000))
  FOR UPDATE SKIP LOCKED;

  SELECT COUNT(*) INTO v_processed FROM _inflow_picked;

  IF v_processed > 0 THEN
    UPDATE public.house_inflow_queue q
    SET status = 'processing', attempts = attempts + 1, updated_at = NOW()
    WHERE q.inflow_id IN (SELECT inflow_id FROM _inflow_picked);

    INSERT INTO public.house_wallet_shards (shard_id, available_balance, locked_balance, updated_at)
    SELECT p.shard_id, 0, 0, NOW()
    FROM _inflow_picked p
    GROUP BY p.shard_id
    ON CONFLICT (shard_id) DO NOTHING;

    UPDATE public.house_wallet_shards h
    SET
      available_balance = h.available_balance + a.total_amount,
      updated_at = NOW()
    FROM (
      SELECT shard_id, SUM(amount)::BIGINT AS total_amount
      FROM _inflow_picked
      GROUP BY shard_id
    ) a
    WHERE h.shard_id = a.shard_id;

    UPDATE public.house_inflow_queue q
    SET status = 'applied', applied_at = NOW(), updated_at = NOW(), error_message = NULL
    WHERE q.inflow_id IN (SELECT inflow_id FROM _inflow_picked)
      AND q.status = 'processing';
    GET DIAGNOSTICS v_applied = ROW_COUNT;
  END IF;

  -- Move over-retried processing rows back to queued/failed only when needed.
  UPDATE public.house_inflow_queue
  SET
    status = 'failed',
    updated_at = NOW(),
    error_message = COALESCE(error_message, 'retry after worker interruption')
  WHERE status = 'processing'
    AND updated_at < NOW() - make_interval(secs => GREATEST(10, p_requeue_after_seconds))
    AND attempts >= p_max_attempts;

  GET DIAGNOSTICS v_failed = ROW_COUNT;

  RETURN jsonb_build_object(
    'ok', TRUE,
    'processed', v_processed,
    'applied', v_applied,
    'requeued', v_requeued,
    'failed_marked', v_failed
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.process_house_inflow_queue(INTEGER, INTEGER, INTEGER) TO authenticated;

-- =========================================================
-- 4) Health view with pending inflow queue totals
-- =========================================================
DROP VIEW IF EXISTS public.house_pool_health;

CREATE OR REPLACE VIEW public.house_pool_health AS
WITH shard AS (
  SELECT
    COALESCE(SUM(available_balance), 0)::BIGINT AS shard_available,
    COALESCE(SUM(locked_balance), 0)::BIGINT AS shard_locked,
    (COALESCE(SUM(available_balance), 0) + COALESCE(SUM(locked_balance), 0))::BIGINT AS shard_total
  FROM public.house_wallet_shards
),
expected_lock AS (
  SELECT COALESCE(SUM(payout_amount), 0)::BIGINT AS expected_locked
  FROM public.payout_jobs
  WHERE status IN ('queued', 'processing')
),
pending_inflow AS (
  SELECT COALESCE(SUM(amount), 0)::BIGINT AS pending_inflow_total
  FROM public.house_inflow_queue
  WHERE status IN ('queued', 'processing')
),
admin_wallet_sum AS (
  SELECT COALESCE(SUM(balance), 0)::BIGINT AS admin_wallet_total
  FROM public.admin_wallet
)
SELECT
  s.shard_available,
  s.shard_locked,
  s.shard_total,
  e.expected_locked,
  p.pending_inflow_total,
  a.admin_wallet_total,
  (s.shard_locked - e.expected_locked) AS locked_drift,
  (a.admin_wallet_total - s.shard_total) AS admin_vs_shard_drift
FROM shard s, expected_lock e, pending_inflow p, admin_wallet_sum a;

