-- Leaderboard profile badges: settlement_id on bets + public RPC for top-10 badges.
-- Run after admin_phase12_shard_aware_draw_settle.sql

-- =========================================================
-- 1) Link each bet to the draw settlement (for match-score stats)
-- =========================================================
ALTER TABLE public.bets
  ADD COLUMN IF NOT EXISTS settlement_id UUID NULL
    REFERENCES public.draw_settlements(settlement_id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_bets_settlement_user_win
  ON public.bets (settlement_id, user_id)
  WHERE status = 'win';

-- =========================================================
-- 2) Patch settle RPC: remember pending bet_ids, set settlement_id after insert
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

  IF NOT pg_try_advisory_lock(hashtext('draw_settle_lock')) THEN
    RAISE EXCEPTION 'Another draw settlement is running';
  END IF;

  DROP TABLE IF EXISTS _settle_pending_bets;
  CREATE TEMP TABLE _settle_pending_bets (bet_id UUID PRIMARY KEY);
  INSERT INTO _settle_pending_bets (bet_id)
  SELECT bet_id FROM public.bets WHERE status = 'pending';

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

  UPDATE public.bets
  SET status = 'win'
  WHERE status = 'pending'
    AND digit = p_winning_digit;

  UPDATE public.bets
  SET status = 'lose'
  WHERE status = 'pending'
    AND digit <> p_winning_digit;

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

  UPDATE public.bets b
  SET settlement_id = v_settlement_id
  WHERE b.bet_id IN (SELECT bet_id FROM _settle_pending_bets);

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

-- =========================================================
-- 3) Public badge helper (ranks + top-10 flags)
-- "Most match" = per user, largest single win payout (amount * 80) ever, all time.
-- Multiple draws: only your largest winning line counts; smaller later wins do not lower the score.
-- =========================================================
CREATE OR REPLACE FUNCTION public.get_profile_leaderboard_badges(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_score_rnk INT;
  v_match_rnk INT;
BEGIN
  SELECT COALESCE(is_admin, FALSE) INTO v_is_admin
  FROM public.profiles WHERE id = p_user_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'score_rank', NULL,
      'match_rank', NULL,
      'score_top10', FALSE,
      'match_top10', FALSE
    );
  END IF;

  IF v_is_admin THEN
    RETURN jsonb_build_object(
      'score_rank', NULL,
      'match_rank', NULL,
      'score_top10', FALSE,
      'match_top10', FALSE
    );
  END IF;

  SELECT s.rnk INTO v_score_rnk
  FROM (
    SELECT
      p.id AS uid,
      ROW_NUMBER() OVER (
        ORDER BY COALESCE(w.available_balance, w.balance, 0) DESC NULLS LAST
      ) AS rnk
    FROM public.profiles p
    LEFT JOIN public.wallets w ON w.user_id = p.id
    WHERE COALESCE(p.is_admin, FALSE) = FALSE
  ) s
  WHERE s.uid = p_user_id;

  SELECT x.rnk INTO v_match_rnk
  FROM (
    SELECT
      p.id AS uid,
      ROW_NUMBER() OVER (ORDER BY COALESCE(m.best_match, 0) DESC) AS rnk
    FROM public.profiles p
    LEFT JOIN (
      SELECT
        user_id,
        MAX((amount * 80)::BIGINT) AS best_match
      FROM public.bets
      WHERE status = 'win'
      GROUP BY user_id
    ) m ON m.user_id = p.id
    WHERE COALESCE(p.is_admin, FALSE) = FALSE
  ) x
  WHERE x.uid = p_user_id;

  RETURN jsonb_build_object(
    'score_rank', v_score_rnk,
    'match_rank', v_match_rnk,
    'score_top10', COALESCE(v_score_rnk, 999) <= 10,
    'match_top10', COALESCE(v_match_rnk, 999) <= 10
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_profile_leaderboard_badges(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_profile_leaderboard_badges(UUID) TO anon;

-- =========================================================
-- 4) 2D Play page: top lists (score balance + best single match)
-- =========================================================
CREATE OR REPLACE FUNCTION public.get_play_leaderboards(p_limit INT DEFAULT 10)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_score JSONB;
  v_match JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(obj ORDER BY ord), '[]'::JSONB)
  INTO v_score
  FROM (
    SELECT
      jsonb_build_object(
        'rank', s.rnk,
        'user_id', s.user_id,
        'username', s.username,
        'avatar_url', s.avatar_url,
        'value', s.val
      ) AS obj,
      s.rnk AS ord
    FROM (
      SELECT
        ROW_NUMBER() OVER (
          ORDER BY COALESCE(w.available_balance, w.balance, 0) DESC NULLS LAST
        ) AS rnk,
        p.id AS user_id,
        p.username,
        p.avatar_url,
        COALESCE(w.available_balance, w.balance, 0)::BIGINT AS val
      FROM public.profiles p
      LEFT JOIN public.wallets w ON w.user_id = p.id
      WHERE COALESCE(p.is_admin, FALSE) = FALSE
    ) s
    WHERE s.rnk <= p_limit
  ) sub;

  SELECT COALESCE(jsonb_agg(obj ORDER BY ord), '[]'::JSONB)
  INTO v_match
  FROM (
    SELECT
      jsonb_build_object(
        'rank', s.rnk,
        'user_id', s.user_id,
        'username', s.username,
        'avatar_url', s.avatar_url,
        'value', s.val
      ) AS obj,
      s.rnk AS ord
    FROM (
      SELECT
        ROW_NUMBER() OVER (ORDER BY m.best_match DESC) AS rnk,
        p.id AS user_id,
        p.username,
        p.avatar_url,
        m.best_match AS val
      FROM public.profiles p
      INNER JOIN (
        SELECT
          user_id,
          MAX((amount * 80)::BIGINT) AS best_match
        FROM public.bets
        WHERE status = 'win'
        GROUP BY user_id
      ) m ON m.user_id = p.id
      WHERE COALESCE(p.is_admin, FALSE) = FALSE
    ) s
    WHERE s.rnk <= p_limit
  ) sub;

  RETURN jsonb_build_object(
    'by_score', v_score,
    'by_best_match', v_match
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_play_leaderboards(INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_play_leaderboards(INT) TO anon;
