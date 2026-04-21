-- Phase 13: draw-specific shard-aware settlement (AM/PM + date)
-- Goal: settle only one draw window, then pay winners in batches within 10 minutes.
-- Run after:
--   - bet_draw_match.sql (draw_slot/draw_date on bets)
--   - admin_phase9_batched_payout.sql (payout_runs/payout_jobs)
--   - admin_phase11_available_locked_and_shards.sql
--   - admin_phase12_shard_aware_draw_settle.sql

ALTER TABLE public.draw_settlements
  ADD COLUMN IF NOT EXISTS draw_slot TEXT NULL CHECK (draw_slot IS NULL OR draw_slot IN ('12:01', '16:30')),
  ADD COLUMN IF NOT EXISTS draw_date DATE NULL;

CREATE INDEX IF NOT EXISTS idx_draw_settlements_draw
  ON public.draw_settlements (draw_date, draw_slot, settled_at DESC);

CREATE OR REPLACE FUNCTION public.admin_settle_draw_shard_aware_for_draw(
  p_winning_digit INTEGER,
  p_draw_slot TEXT,
  p_draw_date DATE,
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
  -- Allow two execution modes:
  -- 1) authenticated admin RPC call (auth.uid() present and admin)
  -- 2) SQL editor / service-role execution (no auth.uid(), but elevated DB role)
  IF v_admin_id IS NOT NULL THEN
    IF NOT public.is_current_user_admin() THEN
      RAISE EXCEPTION 'Forbidden';
    END IF;
  ELSIF current_user NOT IN ('postgres', 'supabase_admin', 'service_role') THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;
  IF p_winning_digit < 0 OR p_winning_digit > 99 THEN
    RAISE EXCEPTION 'Invalid winning digit';
  END IF;
  IF p_draw_slot NOT IN ('12:01', '16:30') THEN
    RAISE EXCEPTION 'Invalid draw slot';
  END IF;
  IF p_draw_date IS NULL THEN
    RAISE EXCEPTION 'draw_date required';
  END IF;
  IF p_batch_count < 1 OR p_window_minutes < 1 THEN
    RAISE EXCEPTION 'Invalid batching config';
  END IF;

  IF NOT pg_try_advisory_lock(hashtext('draw_settle_lock')) THEN
    RAISE EXCEPTION 'Another draw settlement is running';
  END IF;

  DROP TABLE IF EXISTS _settle_target_bets;
  CREATE TEMP TABLE _settle_target_bets (bet_id UUID PRIMARY KEY);
  INSERT INTO _settle_target_bets (bet_id)
  SELECT b.bet_id
  FROM public.bets b
  WHERE b.status = 'pending'
    AND b.draw_slot = p_draw_slot
    AND b.draw_date = p_draw_date;

  SELECT
    COUNT(*)::INTEGER,
    COALESCE(SUM(b.amount), 0)::BIGINT,
    COUNT(*) FILTER (WHERE b.digit = p_winning_digit)::INTEGER,
    COUNT(*) FILTER (WHERE b.digit <> p_winning_digit)::INTEGER,
    COALESCE(SUM(b.amount) FILTER (WHERE b.digit <> p_winning_digit), 0)::BIGINT,
    COALESCE(SUM(b.amount) FILTER (WHERE b.digit = p_winning_digit), 0)::BIGINT,
    COALESCE(SUM((b.amount * 80)::BIGINT) FILTER (WHERE b.digit = p_winning_digit), 0)::BIGINT
  INTO
    v_total_bets,
    v_total_locked,
    v_total_winners,
    v_total_losers,
    v_total_loser_amount,
    v_total_winner_locked,
    v_total_payout
  FROM public.bets b
  WHERE b.bet_id IN (SELECT bet_id FROM _settle_target_bets);

  -- No pending bets for that draw => no-op response.
  IF v_total_bets = 0 THEN
    PERFORM pg_advisory_unlock(hashtext('draw_settle_lock'));
    RETURN jsonb_build_object(
      'ok', TRUE,
      'draw_slot', p_draw_slot,
      'draw_date', p_draw_date,
      'winning_digit', p_winning_digit,
      'message', 'No pending bets for selected draw',
      'total_bets', 0
    );
  END IF;

  -- User wallet unlock for losers.
  UPDATE public.wallets w
  SET
    locked_balance = GREATEST(0, w.locked_balance - u.amt),
    balance = w.available_balance + GREATEST(0, w.locked_balance - u.amt),
    updated_at = NOW()
  FROM (
    SELECT b.user_id, SUM(b.amount)::INTEGER AS amt
    FROM public.bets b
    WHERE b.bet_id IN (SELECT bet_id FROM _settle_target_bets)
      AND b.digit <> p_winning_digit
    GROUP BY b.user_id
  ) u
  WHERE w.user_id = u.user_id;

  -- User wallet unlock for winners (payout credit arrives via payout worker).
  UPDATE public.wallets w
  SET
    locked_balance = GREATEST(0, w.locked_balance - u.amt),
    balance = w.available_balance + GREATEST(0, w.locked_balance - u.amt),
    updated_at = NOW()
  FROM (
    SELECT b.user_id, SUM(b.amount)::INTEGER AS amt
    FROM public.bets b
    WHERE b.bet_id IN (SELECT bet_id FROM _settle_target_bets)
      AND b.digit = p_winning_digit
    GROUP BY b.user_id
  ) u
  WHERE w.user_id = u.user_id;

  -- House shard updates from this draw only.
  FOR r IN
    WITH settle_rows AS (
      SELECT
        public.shard_for_uuid(b.user_id, 16) AS shard_id,
        SUM(CASE WHEN b.digit <> p_winning_digit THEN b.amount ELSE 0 END)::BIGINT AS loser_amount,
        SUM(CASE WHEN b.digit = p_winning_digit THEN (b.amount * 80)::BIGINT ELSE 0 END)::BIGINT AS winner_payout_amount
      FROM public.bets b
      WHERE b.bet_id IN (SELECT bet_id FROM _settle_target_bets)
      GROUP BY public.shard_for_uuid(b.user_id, 16)
    )
    SELECT * FROM settle_rows
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
      'Draw settle shard update (draw-specific)',
      v_admin_id,
      NOW()
    );
  END LOOP;

  -- Update statuses only for selected draw.
  UPDATE public.bets b
  SET status = 'win'
  WHERE b.bet_id IN (SELECT bet_id FROM _settle_target_bets)
    AND b.digit = p_winning_digit;

  UPDATE public.bets b
  SET status = 'lose'
  WHERE b.bet_id IN (SELECT bet_id FROM _settle_target_bets)
    AND b.digit <> p_winning_digit;

  -- Create payout run with 10-minute default payout window.
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
    WHERE b.bet_id IN (SELECT bet_id FROM _settle_target_bets)
      AND b.status = 'win'
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

  INSERT INTO public.draw_settlements (
    winning_digit,
    draw_slot,
    draw_date,
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
    p_draw_slot,
    p_draw_date,
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

  UPDATE public.bets b
  SET settlement_id = v_settlement_id
  WHERE b.bet_id IN (SELECT bet_id FROM _settle_target_bets);

  IF v_admin_id IS NOT NULL THEN
    INSERT INTO public.audit_logs (
      actor_admin_id, action, target_type, target_id, meta, created_at
    ) VALUES (
      v_admin_id,
      'admin_settle_draw_shard_aware_for_draw',
      'draw_settlement',
      v_settlement_id,
      jsonb_build_object(
        'winning_digit', p_winning_digit,
        'draw_slot', p_draw_slot,
        'draw_date', p_draw_date,
        'total_bets', v_total_bets,
        'total_winners', v_total_winners,
        'total_losers', v_total_losers,
        'total_payout', v_total_payout,
        'payout_run_id', v_run_id,
        'window_minutes', p_window_minutes
      ),
      NOW()
    );
  END IF;

  PERFORM pg_advisory_unlock(hashtext('draw_settle_lock'));

  RETURN jsonb_build_object(
    'ok', TRUE,
    'settlement_id', v_settlement_id,
    'payout_run_id', v_run_id,
    'draw_slot', p_draw_slot,
    'draw_date', p_draw_date,
    'total_bets', v_total_bets,
    'total_winners', v_total_winners,
    'total_losers', v_total_losers,
    'total_payout', v_total_payout,
    'payout_window_minutes', p_window_minutes
  );
EXCEPTION
  WHEN OTHERS THEN
    PERFORM pg_advisory_unlock(hashtext('draw_settle_lock'));
    RAISE;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_settle_draw_shard_aware_for_draw(INTEGER, TEXT, DATE, INTEGER, INTEGER) TO authenticated;
