-- Hybrid Blueprint - Phase 1
-- Scope:
-- 1) Schema primitives for idempotent bet reservation + async settlement queue
-- 2) Idempotent SQL function with SELECT ... FOR UPDATE balance locking
--
-- Notes:
-- - This migration is additive/idempotent.
-- - It does NOT replace existing place_bet/place_bet_locked immediately.
-- - It introduces a new reservation RPC for gradual rollout.

-- =========================================================
-- A) Bets table: idempotency + sharding metadata
-- =========================================================
ALTER TABLE public.bets
  ADD COLUMN IF NOT EXISTS idempotency_key UUID NULL,
  ADD COLUMN IF NOT EXISTS shard_id INTEGER NULL,
  ADD COLUMN IF NOT EXISTS reservation_status TEXT NOT NULL DEFAULT 'reserved'
    CHECK (reservation_status IN ('reserved', 'settled', 'cancelled', 'failed'));

-- Keep idempotency scoped to user for retry safety.
CREATE UNIQUE INDEX IF NOT EXISTS uq_bets_user_idempotency_key
ON public.bets(user_id, idempotency_key)
WHERE idempotency_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_bets_shard_created
ON public.bets(shard_id, created_at DESC);

-- =========================================================
-- B) Pending settlements queue table (DB-backed queue)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.pending_settlements (
  queue_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bet_id UUID NOT NULL REFERENCES public.bets(bet_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  shard_id INTEGER NOT NULL,
  amount INTEGER NOT NULL CHECK (amount > 0),
  status TEXT NOT NULL DEFAULT 'queued'
    CHECK (status IN ('queued', 'processing', 'applied', 'failed')),
  attempts INTEGER NOT NULL DEFAULT 0,
  next_retry_at TIMESTAMPTZ NULL,
  error_message TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  applied_at TIMESTAMPTZ NULL
);

-- Idempotency for worker retries: one bet => one settlement queue row.
CREATE UNIQUE INDEX IF NOT EXISTS uq_pending_settlements_bet_id
ON public.pending_settlements(bet_id);

CREATE INDEX IF NOT EXISTS idx_pending_settlements_due
ON public.pending_settlements(status, COALESCE(next_retry_at, created_at), created_at);

CREATE INDEX IF NOT EXISTS idx_pending_settlements_shard
ON public.pending_settlements(shard_id, status, created_at);

-- =========================================================
-- C) Dead-letter queue for failed settlement jobs
-- =========================================================
CREATE TABLE IF NOT EXISTS public.settlement_dead_letter (
  dlq_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bet_id UUID NOT NULL,
  user_id UUID NOT NULL,
  shard_id INTEGER NOT NULL,
  amount INTEGER NOT NULL,
  final_error TEXT NOT NULL,
  failed_attempts INTEGER NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_settlement_dead_letter_created
ON public.settlement_dead_letter(created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS uq_settlement_dead_letter_bet_id
ON public.settlement_dead_letter(bet_id);

-- =========================================================
-- D) Monitoring view: pending inflow for dashboard
-- =========================================================
DROP VIEW IF EXISTS public.pending_inflow_monitor;
CREATE VIEW public.pending_inflow_monitor AS
SELECT
  COUNT(*) FILTER (WHERE status = 'queued')::BIGINT AS queued_rows,
  COUNT(*) FILTER (WHERE status = 'processing')::BIGINT AS processing_rows,
  COUNT(*) FILTER (WHERE status = 'failed')::BIGINT AS failed_rows,
  COALESCE(SUM(amount) FILTER (WHERE status IN ('queued', 'processing')), 0)::BIGINT AS pending_inflow,
  COALESCE(SUM(amount) FILTER (WHERE status = 'applied'), 0)::BIGINT AS applied_inflow
FROM public.pending_settlements;

-- =========================================================
-- E) RLS: read/admin only, no direct client writes
-- =========================================================
ALTER TABLE public.pending_settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settlement_dead_letter ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can read pending settlements" ON public.pending_settlements;
CREATE POLICY "Admins can read pending settlements"
  ON public.pending_settlements FOR SELECT
  USING (public.is_current_user_admin());

DROP POLICY IF EXISTS "No direct insert pending settlements" ON public.pending_settlements;
CREATE POLICY "No direct insert pending settlements"
  ON public.pending_settlements FOR INSERT
  WITH CHECK (FALSE);

DROP POLICY IF EXISTS "No direct update pending settlements" ON public.pending_settlements;
CREATE POLICY "No direct update pending settlements"
  ON public.pending_settlements FOR UPDATE
  USING (FALSE);

DROP POLICY IF EXISTS "Admins can read settlement DLQ" ON public.settlement_dead_letter;
CREATE POLICY "Admins can read settlement DLQ"
  ON public.settlement_dead_letter FOR SELECT
  USING (public.is_current_user_admin());

DROP POLICY IF EXISTS "No direct insert settlement DLQ" ON public.settlement_dead_letter;
CREATE POLICY "No direct insert settlement DLQ"
  ON public.settlement_dead_letter FOR INSERT
  WITH CHECK (FALSE);

DROP POLICY IF EXISTS "No direct update settlement DLQ" ON public.settlement_dead_letter;
CREATE POLICY "No direct update settlement DLQ"
  ON public.settlement_dead_letter FOR UPDATE
  USING (FALSE);

-- =========================================================
-- F) Idempotent reservation function
-- - uses SELECT ... FOR UPDATE on wallet row
-- - verifies available_balance >= amount
-- - reserves balance (available -> locked)
-- - inserts bet + queue row once (idempotent by idempotency_key)
-- =========================================================
CREATE OR REPLACE FUNCTION public.reserve_bet_balance_hybrid(
  p_idempotency_key UUID,
  p_digit INTEGER,
  p_amount INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_bet_id UUID;
  v_existing_bet UUID;
  v_existing_status TEXT;
  v_draw_slot TEXT;
  v_draw_date DATE;
  v_shard_id INTEGER;
  v_avail INTEGER;
  v_locked INTEGER;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'Not authenticated');
  END IF;

  IF p_idempotency_key IS NULL THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'idempotency_key is required');
  END IF;
  IF p_digit < 0 OR p_digit > 99 THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'Invalid digit');
  END IF;
  IF p_amount <= 0 THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'Invalid amount');
  END IF;

  -- Idempotent retry path: return existing reservation.
  SELECT b.bet_id, b.status
  INTO v_existing_bet, v_existing_status
  FROM public.bets b
  WHERE b.user_id = v_user_id
    AND b.idempotency_key = p_idempotency_key
  LIMIT 1;

  IF v_existing_bet IS NOT NULL THEN
    RETURN jsonb_build_object(
      'ok', TRUE,
      'idempotent', TRUE,
      'bet_id', v_existing_bet,
      'status', v_existing_status
    );
  END IF;

  -- Current scheduling rules.
  v_draw_slot := public.bet_draw_slot_yangon(CURRENT_TIMESTAMP);
  v_draw_date := public.bet_draw_date_yangon(CURRENT_TIMESTAMP);
  IF v_draw_slot IS NULL THEN
    RETURN jsonb_build_object(
      'ok', FALSE,
      'error', 'betting_closed',
      'message', 'Betting only Mon-Fri, 06:00-11:40 and 13:00-16:10 (Myanmar time), excluding SET holidays.'
    );
  END IF;

  -- Ensure wallet row exists.
  INSERT INTO public.wallets (user_id, balance, available_balance, locked_balance, updated_at)
  VALUES (v_user_id, 0, 0, 0, NOW())
  ON CONFLICT (user_id) DO NOTHING;

  -- Pessimistic lock for correct reservation under concurrency.
  SELECT available_balance, locked_balance
  INTO v_avail, v_locked
  FROM public.wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF v_avail < p_amount THEN
    RETURN jsonb_build_object(
      'ok', FALSE,
      'error', 'Insufficient available balance',
      'available_balance', v_avail,
      'required_amount', p_amount
    );
  END IF;

  UPDATE public.wallets
  SET
    available_balance = available_balance - p_amount,
    locked_balance = locked_balance + p_amount,
    balance = (available_balance - p_amount) + (locked_balance + p_amount),
    updated_at = NOW()
  WHERE user_id = v_user_id;

  v_shard_id := public.shard_for_uuid(v_user_id, 64);

  -- Bet insert is idempotent due to unique(user_id, idempotency_key).
  INSERT INTO public.bets (
    user_id,
    digit,
    amount,
    status,
    created_at,
    draw_slot,
    draw_date,
    idempotency_key,
    shard_id,
    reservation_status
  )
  VALUES (
    v_user_id,
    p_digit,
    p_amount,
    'pending',
    NOW(),
    v_draw_slot,
    v_draw_date,
    p_idempotency_key,
    v_shard_id,
    'reserved'
  )
  RETURNING bet_id INTO v_bet_id;

  -- Queue row insert is idempotent by unique bet_id.
  INSERT INTO public.pending_settlements (
    bet_id,
    user_id,
    shard_id,
    amount,
    status,
    created_at,
    updated_at
  )
  VALUES (
    v_bet_id,
    v_user_id,
    v_shard_id,
    p_amount,
    'queued',
    NOW(),
    NOW()
  )
  ON CONFLICT (bet_id) DO NOTHING;

  RETURN jsonb_build_object(
    'ok', TRUE,
    'idempotent', FALSE,
    'bet_id', v_bet_id,
    'shard_id', v_shard_id
  );
EXCEPTION
  WHEN unique_violation THEN
    -- Race-safe fallback for concurrent retries with same idempotency key.
    SELECT b.bet_id, b.status
    INTO v_existing_bet, v_existing_status
    FROM public.bets b
    WHERE b.user_id = v_user_id
      AND b.idempotency_key = p_idempotency_key
    LIMIT 1;

    IF v_existing_bet IS NOT NULL THEN
      RETURN jsonb_build_object(
        'ok', TRUE,
        'idempotent', TRUE,
        'bet_id', v_existing_bet,
        'status', v_existing_status
      );
    END IF;
    RAISE;
END;
$$;

GRANT EXECUTE ON FUNCTION public.reserve_bet_balance_hybrid(UUID, INTEGER, INTEGER) TO authenticated;
