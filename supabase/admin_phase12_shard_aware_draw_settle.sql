-- Phase 12: shard-aware draw settle from locked balances
-- Run after phase9 + phase11.

-- =========================================================
-- 1) Draw settlement summary table
-- =========================================================
CREATE TABLE IF NOT EXISTS public.draw_settlements (
  settlement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  winning_digit INTEGER NOT NULL CHECK (winning_digit >= 0 AND winning_digit <= 99),
  total_bets INTEGER NOT NULL DEFAULT 0,
  total_winners INTEGER NOT NULL DEFAULT 0,
  total_losers INTEGER NOT NULL DEFAULT 0,
  total_locked_amount BIGINT NOT NULL DEFAULT 0,
  total_loser_amount BIGINT NOT NULL DEFAULT 0,
  total_winner_locked_amount BIGINT NOT NULL DEFAULT 0,
  total_payout_amount BIGINT NOT NULL DEFAULT 0,
  payout_run_id UUID NULL REFERENCES public.payout_runs(run_id),
  settled_by UUID NULL REFERENCES auth.users(id),
  settled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('completed', 'failed'))
);

CREATE INDEX IF NOT EXISTS idx_draw_settlements_settled_at
ON public.draw_settlements(settled_at DESC);

ALTER TABLE public.draw_settlements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can read draw settlements" ON public.draw_settlements;
CREATE POLICY "Admins can read draw settlements" ON public.draw_settlements
FOR SELECT USING (public.is_current_user_admin());
DROP POLICY IF EXISTS "No direct insert draw settlements" ON public.draw_settlements;
CREATE POLICY "No direct insert draw settlements" ON public.draw_settlements
FOR INSERT WITH CHECK (FALSE);
DROP POLICY IF EXISTS "No direct update draw settlements" ON public.draw_settlements;
CREATE POLICY "No direct update draw settlements" ON public.draw_settlements
FOR UPDATE USING (FALSE);

-- =========================================================
-- 2) Shard-aware settle RPC
-- - moves user locked -> house available for losers
-- - moves user locked -> house locked reserve for winners
-- - marks bet status from pending -> win/lose
-- - creates payout run + jobs in batches
-- =========================================================
CREATE OR REPLACE FUNCTION public.admin_settle_draw_shard_aware(
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
  v_settlement_id UUID;
  v_run_id UUID;
  v_total_bets INTEGER := 0;
  v_total_winners INTEGER := 0;
  v_total_losers INTEGER := 0;
  v_total_locked BIGINT := 0;
  v_total_loser_amount BIGINT := 0;
  v_total_winner_locked BIGINT := 0;
  v_total_payout BIGINT := 0;
  r RECORD;
  v_avail BIGINT;
  v_locked BIGINT;
BEGIN
  v_admin_id := auth.uid();
  IF v_admin_id IS NULL OR NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;
  IF p_winning_digit < 0 OR p_winning_digit > 99 THEN
    RAISE EXCEPTION 'Invalid winning digit';
  END IF;
  IF p_batch_count < 1 OR p_window_minutes < 1 THEN
    RAISE EXCEPTION 'Invalid batching config';
  END IF;

  -- single-writer lock for settle
  IF NOT pg_try_advisory_lock(hashtext('draw_settle_lock')) THEN
    RAISE EXCEPTION 'Another draw settlement is running';
  END IF;

  -- Snapshot totals from pending bets.
  SELECT
    COUNT(*)::INTEGER,
    COALESCE(SUM(amount), 0)::BIGINT,
    COUNT(*) FILTER (WHERE digit = p_winning_digit)::INTEGER,
    COUNT(*) FILTER (WHERE digit <> p_winning_digit)::INTEGER,
    COALESCE(SUM(amount) FILTER (WHERE digit <> p_winning_digit), 0)::BIGINT,
    COALESCE(SUM(amount) FILTER (WHERE digit = p_winning_digit), 0)::BIGINT,
    COALESCE(SUM((amount * 80)::BIGINT) FILTER (WHERE digit = p_winning_digit), 0)::BIGINT
  INTO
    v_total_bets,
    v_total_locked,
    v_total_winners,
    v_total_losers,
    v_total_loser_amount,
    v_total_winner_locked,
    v_total_payout
  FROM public.bets
  WHERE status = 'pending';

  -- 2.1 User wallet unlock for losers (locked -= amount)
  UPDATE public.wallets w
  SET
    locked_balance = GREATEST(0, w.locked_balance - u.amt),
    balance = w.available_balance + GREATEST(0, w.locked_balance - u.amt),
    updated_at = NOW()
  FROM (
    SELECT b.user_id, SUM(b.amount)::INTEGER AS amt
    FROM public.bets b
    WHERE b.status = 'pending'
      AND b.digit <> p_winning_digit
    GROUP BY b.user_id
  ) u
  WHERE w.user_id = u.user_id;

  -- 2.2 User wallet unlock for winners (locked -= amount) (their payout goes via payout jobs later)
  UPDATE public.wallets w
  SET
    locked_balance = GREATEST(0, w.locked_balance - u.amt),
    balance = w.available_balance + GREATEST(0, w.locked_balance - u.amt),
    updated_at = NOW()
  FROM (
    SELECT b.user_id, SUM(b.amount)::INTEGER AS amt
    FROM public.bets b
    WHERE b.status = 'pending'
      AND b.digit = p_winning_digit
    GROUP BY b.user_id
  ) u
  WHERE w.user_id = u.user_id;

  -- 2.3 House shard updates:
  -- losers add to available, winners add to locked reserve
  FOR r IN
    WITH pending_rows AS (
      SELECT
        public.shard_for_uuid(b.user_id, 16) AS shard_id,
        SUM(CASE WHEN b.digit <> p_winning_digit THEN b.amount ELSE 0 END)::BIGINT AS loser_amount,
        SUM(CASE WHEN b.digit = p_winning_digit THEN (b.amount * 80)::BIGINT ELSE 0 END)::BIGINT AS winner_payout_amount
      FROM public.bets b
      WHERE b.status = 'pending'
      GROUP BY public.shard_for_uuid(b.user_id, 16)
    )
    SELECT * FROM pending_rows
  LOOP
    SELECT h.available_balance, h.locked_balance
    INTO v_avail, v_locked
    FROM public.house_wallet_shards h
    WHERE h.shard_id = r.shard_id
    FOR UPDATE;

    UPDATE public.house_wallet_shards
    SET
      available_balance = available_balance + COALESCE(r.loser_amount, 0),
      locked_balance = locked_balance + COALESCE(r.winner_payout_amount, 0),
      updated_at = NOW()
    WHERE shard_id = r.shard_id;

    INSERT INTO public.house_ledger_transactions (
      shard_id,
      delta_available,
      delta_locked,
      balance_available_after,
      balance_locked_after,
      source_type,
      note,
      created_by,
      created_at
    ) VALUES (
      r.shard_id,
      COALESCE(r.loser_amount, 0),
      COALESCE(r.winner_payout_amount, 0),
      v_avail + COALESCE(r.loser_amount, 0),
      v_locked + COALESCE(r.winner_payout_amount, 0),
      'bet_win_reserve',
      'Draw settle shard update',
      v_admin_id,
      NOW()
    );
  END LOOP;

  -- 2.4 Mark bet status
  UPDATE public.bets
  SET status = 'win'
  WHERE status = 'pending'
    AND digit = p_winning_digit;

  UPDATE public.bets
  SET status = 'lose'
  WHERE status = 'pending'
    AND digit <> p_winning_digit;

  -- 2.5 Create payout run + jobs for winners
  INSERT INTO public.payout_runs (
    winning_digit, total_winners, total_payout, batch_count, window_minutes, status, prepared_by, prepared_at
  ) VALUES (
    p_winning_digit, v_total_winners, v_total_payout, p_batch_count, p_window_minutes, 'prepared', v_admin_id, NOW()
  ) RETURNING run_id INTO v_run_id;

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

  -- 2.6 Settlement summary
  INSERT INTO public.draw_settlements (
    winning_digit,
    total_bets,
    total_winners,
    total_losers,
    total_locked_amount,
    total_loser_amount,
    total_winner_locked_amount,
    total_payout_amount,
    payout_run_id,
    settled_by,
    settled_at,
    status
  ) VALUES (
    p_winning_digit,
    v_total_bets,
    v_total_winners,
    v_total_losers,
    v_total_locked,
    v_total_loser_amount,
    v_total_winner_locked,
    v_total_payout,
    v_run_id,
    v_admin_id,
    NOW(),
    'completed'
  ) RETURNING settlement_id INTO v_settlement_id;

  INSERT INTO public.audit_logs (
    actor_admin_id, action, target_type, target_id, meta, created_at
  ) VALUES (
    v_admin_id,
    'admin_settle_draw_shard_aware',
    'draw_settlement',
    v_settlement_id,
    jsonb_build_object(
      'winning_digit', p_winning_digit,
      'total_bets', v_total_bets,
      'total_winners', v_total_winners,
      'total_losers', v_total_losers,
      'total_payout', v_total_payout,
      'payout_run_id', v_run_id
    ),
    NOW()
  );

  PERFORM pg_advisory_unlock(hashtext('draw_settle_lock'));

  RETURN jsonb_build_object(
    'ok', TRUE,
    'settlement_id', v_settlement_id,
    'payout_run_id', v_run_id,
    'total_bets', v_total_bets,
    'total_winners', v_total_winners,
    'total_losers', v_total_losers,
    'total_payout', v_total_payout
  );
EXCEPTION
  WHEN OTHERS THEN
    PERFORM pg_advisory_unlock(hashtext('draw_settle_lock'));
    RAISE;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_settle_draw_shard_aware(INTEGER, INTEGER, INTEGER) TO authenticated;

