-- Make house score pool follow bet/payout flow:
-- 1) Every user pick adds bet amount into house pool.
-- 2) Settlement subtracts total payout from house pool.
--
-- This patch updates:
-- - public.place_bet(...)
-- - public.process_bet_win_for_draw(...)
-- - public.process_bet_win(...) legacy
--
-- Requires public.house_wallet_shards (phase11) and draw helpers from bet_draw_match.sql.

-- Ensure shard 0 exists for simple house-pool accounting.
INSERT INTO public.house_wallet_shards (shard_id, available_balance, locked_balance, updated_at)
VALUES (0, 0, 0, NOW())
ON CONFLICT (shard_id) DO NOTHING;

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

  -- House score pool increases when users place picks (shard-aware to reduce hot-row contention).
  v_shard_id := public.shard_for_uuid(v_user_id, 16);
  INSERT INTO public.house_wallet_shards (shard_id, available_balance, locked_balance, updated_at)
  VALUES (v_shard_id, 0, 0, NOW())
  ON CONFLICT (shard_id) DO NOTHING;

  UPDATE public.house_wallet_shards
  SET
    available_balance = available_balance + p_amount,
    updated_at = NOW()
  WHERE shard_id = v_shard_id;

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
  )
  SELECT
    v_shard_id,
    p_amount,
    0,
    h.available_balance,
    h.locked_balance,
    'bet_lock',
    'place_bet credited to house pool (shard-aware)',
    v_user_id,
    NOW()
  FROM public.house_wallet_shards h
  WHERE h.shard_id = v_shard_id;

  INSERT INTO public.bets (
    user_id, digit, amount, status, created_at, draw_slot, draw_date
  )
  VALUES (
    v_user_id, p_digit, p_amount, 'pending', CURRENT_TIMESTAMP, v_slot, v_draw_date
  );

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

CREATE OR REPLACE FUNCTION public.process_bet_win_for_draw (
  p_winning_digit INTEGER,
  p_draw_slot TEXT,
  p_draw_date DATE
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total_payout INTEGER := 0;
  v_winner_count INTEGER := 0;
  v_bet_record RECORD;
BEGIN
  IF p_winning_digit < 0 OR p_winning_digit > 99 THEN
    RETURN json_build_object('success', FALSE, 'error', 'Invalid digit (must be 0-99)');
  END IF;

  IF p_draw_slot NOT IN ('12:01', '16:30') THEN
    RETURN json_build_object('success', FALSE, 'error', 'Invalid draw_slot');
  END IF;

  IF p_draw_date IS NULL THEN
    RETURN json_build_object('success', FALSE, 'error', 'draw_date required');
  END IF;

  FOR v_bet_record IN
    SELECT bet_id, user_id, amount
    FROM public.bets
    WHERE digit = p_winning_digit
      AND status = 'pending'
      AND draw_slot = p_draw_slot
      AND draw_date = p_draw_date
  LOOP
    v_total_payout := v_total_payout + (v_bet_record.amount * 80);
    v_winner_count := v_winner_count + 1;

    UPDATE public.bets
    SET status = 'win'
    WHERE bet_id = v_bet_record.bet_id;

    INSERT INTO public.wallets (user_id, balance, updated_at)
    VALUES (v_bet_record.user_id, v_bet_record.amount * 80, CURRENT_TIMESTAMP)
    ON CONFLICT (user_id)
    DO UPDATE SET
      balance = public.wallets.balance + (v_bet_record.amount * 80),
      updated_at = CURRENT_TIMESTAMP;
  END LOOP;

  UPDATE public.bets
  SET status = 'lose'
  WHERE status = 'pending'
    AND draw_slot = p_draw_slot
    AND draw_date = p_draw_date
    AND digit <> p_winning_digit;

  -- House score pool decreases by total payout.
  IF v_total_payout > 0 THEN
    UPDATE public.house_wallet_shards
    SET
      available_balance = available_balance - v_total_payout,
      updated_at = NOW()
    WHERE shard_id = 0;
  END IF;

  RETURN json_build_object(
    'success', TRUE,
    'winning_digit', p_winning_digit,
    'draw_slot', p_draw_slot,
    'draw_date', p_draw_date,
    'winner_count', v_winner_count,
    'total_payout', v_total_payout
  );
END;
$$;

-- Legacy settle path, kept in sync with same pool behavior.
CREATE OR REPLACE FUNCTION public.process_bet_win (p_winning_digit INTEGER)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total_payout INTEGER := 0;
  v_winner_count INTEGER := 0;
  v_bet_record RECORD;
BEGIN
  IF p_winning_digit < 0 OR p_winning_digit > 99 THEN
    RETURN json_build_object('success', FALSE, 'error', 'Invalid digit (must be 0-99)');
  END IF;

  FOR v_bet_record IN
    SELECT bet_id, user_id, amount
    FROM public.bets
    WHERE digit = p_winning_digit
      AND status = 'pending'
      AND draw_slot IS NULL
  LOOP
    v_total_payout := v_total_payout + (v_bet_record.amount * 80);
    v_winner_count := v_winner_count + 1;

    UPDATE public.bets SET status = 'win' WHERE bet_id = v_bet_record.bet_id;

    INSERT INTO public.wallets (user_id, balance, updated_at)
    VALUES (v_bet_record.user_id, v_bet_record.amount * 80, CURRENT_TIMESTAMP)
    ON CONFLICT (user_id)
    DO UPDATE SET
      balance = public.wallets.balance + (v_bet_record.amount * 80),
      updated_at = CURRENT_TIMESTAMP;
  END LOOP;

  UPDATE public.bets
  SET status = 'lose'
  WHERE status = 'pending'
    AND draw_slot IS NULL
    AND digit <> p_winning_digit;

  IF v_total_payout > 0 THEN
    UPDATE public.house_wallet_shards
    SET
      available_balance = available_balance - v_total_payout,
      updated_at = NOW()
    WHERE shard_id = 0;
  END IF;

  RETURN json_build_object(
    'success', TRUE,
    'winning_digit', p_winning_digit,
    'winner_count', v_winner_count,
    'total_payout', v_total_payout,
    'note', 'legacy: only bets with draw_slot IS NULL'
  );
END;
$$;

