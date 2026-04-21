-- Two draws per day (Myanmar time, Asia/Yangon):
--   Morning picks: 06:00–11:40 (closes 20 min before 12:01 draw).
--   Afternoon picks: 13:00–16:10 (closes 20 min before 16:30 draw).
--   Settle: morning bets vs that day's 12:01 result; afternoon vs 16:30.
-- No cross-draw matching; bets outside windows are rejected at insert.
-- Run after core schema + thai_set_holidays (from popular_digits_sessions.sql).

-- ---------------------------------------------------------------------------
-- 1) Columns on bets
-- ---------------------------------------------------------------------------
ALTER TABLE public.bets
  ADD COLUMN IF NOT EXISTS draw_slot TEXT
    CHECK (draw_slot IS NULL OR draw_slot IN ('12:01', '16:30')),
  ADD COLUMN IF NOT EXISTS draw_date DATE;

COMMENT ON COLUMN public.bets.draw_slot IS
  'Which result this bet targets: 12:01 (morning) or 16:30 (afternoon), Yangon calendar.';
COMMENT ON COLUMN public.bets.draw_date IS
  'Yangon local calendar date of the draw (not UTC date).';

CREATE INDEX IF NOT EXISTS idx_bets_draw_settle
  ON public.bets (draw_date, draw_slot, status)
  WHERE status = 'pending';

-- ---------------------------------------------------------------------------
-- 2) Helpers (Yangon wall clock; Mon–Fri; exclude thai_set_holidays)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.bet_draw_slot_yangon (p_at TIMESTAMPTZ)
RETURNS TEXT
LANGUAGE SQL
STABLE
SET search_path = public
AS $$
  WITH z AS (
    SELECT
      (p_at AT TIME ZONE 'Asia/Yangon') AS local_ts,
      DATE((p_at AT TIME ZONE 'Asia/Yangon')) AS d,
      (EXTRACT(ISODOW FROM (p_at AT TIME ZONE 'Asia/Yangon')))::INT AS isodow,
      ((p_at AT TIME ZONE 'Asia/Yangon')::TIME) AS lt
  )
  SELECT CASE
    WHEN EXISTS (
      SELECT 1 FROM public.thai_set_holidays h WHERE h.hdate = (SELECT d FROM z)
    ) THEN NULL
    WHEN (SELECT isodow FROM z) >= 6 THEN NULL
    WHEN (SELECT lt FROM z) >= TIME '06:00' AND (SELECT lt FROM z) < TIME '11:40' THEN '12:01'
    WHEN (SELECT lt FROM z) >= TIME '13:00' AND (SELECT lt FROM z) < TIME '16:10' THEN '16:30'
    ELSE NULL
  END;
$$;

CREATE OR REPLACE FUNCTION public.bet_draw_date_yangon (p_at TIMESTAMPTZ)
RETURNS DATE
LANGUAGE SQL
STABLE
SET search_path = public
AS $$
  SELECT DATE(p_at AT TIME ZONE 'Asia/Yangon');
$$;

-- Align Top-10 popular windows with the same betting windows (optional but consistent).
CREATE OR REPLACE FUNCTION public.popular_digit_window_key (p_at TIMESTAMPTZ)
RETURNS TEXT
LANGUAGE SQL
STABLE
SET search_path = public
AS $$
  WITH z AS (
    SELECT
      DATE((p_at AT TIME ZONE 'Asia/Yangon')) AS d,
      (EXTRACT(ISODOW FROM (p_at AT TIME ZONE 'Asia/Yangon')))::INT AS isodow,
      ((p_at AT TIME ZONE 'Asia/Yangon')::TIME) AS lt
  )
  SELECT CASE
    WHEN EXISTS (
      SELECT 1 FROM public.thai_set_holidays h WHERE h.hdate = (SELECT d FROM z)
    ) THEN NULL
    WHEN (SELECT isodow FROM z) >= 6 THEN NULL
    WHEN (SELECT lt FROM z) >= TIME '06:00' AND (SELECT lt FROM z) < TIME '11:40' THEN (SELECT d FROM z) || '_am'
    WHEN (SELECT lt FROM z) >= TIME '13:00' AND (SELECT lt FROM z) < TIME '16:10' THEN (SELECT d FROM z) || '_pm'
    ELSE NULL
  END;
$$;

-- ---------------------------------------------------------------------------
-- 3) place_bet: require valid draw window; store draw_slot + draw_date
-- ---------------------------------------------------------------------------
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
      'message', 'Betting only Mon–Fri, 06:00–11:40 and 13:00–16:10 (Myanmar time), excluding SET holidays.'
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

  UPDATE public.admin_wallet
  SET balance = balance + p_amount, updated_at = CURRENT_TIMESTAMP
  WHERE id = (SELECT id FROM public.admin_wallet LIMIT 1);

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

-- ---------------------------------------------------------------------------
-- 4) Settlement: only pending bets for that draw (slot + Yangon date)
--    ×80 payout (same as legacy process_bet_win)
-- ---------------------------------------------------------------------------
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
  v_payout_amount INTEGER;
  v_admin_balance INTEGER;
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

  SELECT balance INTO v_admin_balance
  FROM public.admin_wallet
  WHERE id = (SELECT id FROM public.admin_wallet LIMIT 1);

  FOR v_bet_record IN
    SELECT bet_id, user_id, amount
    FROM public.bets
    WHERE digit = p_winning_digit
      AND status = 'pending'
      AND draw_slot = p_draw_slot
      AND draw_date = p_draw_date
  LOOP
    v_payout_amount := v_bet_record.amount * 80;
    v_total_payout := v_total_payout + v_payout_amount;
    v_winner_count := v_winner_count + 1;

    UPDATE public.bets
    SET status = 'win'
    WHERE bet_id = v_bet_record.bet_id;

    INSERT INTO public.wallets (user_id, balance, updated_at)
    VALUES (v_bet_record.user_id, v_payout_amount, CURRENT_TIMESTAMP)
    ON CONFLICT (user_id)
    DO UPDATE SET
      balance = public.wallets.balance + v_payout_amount,
      updated_at = CURRENT_TIMESTAMP;
  END LOOP;

  UPDATE public.bets
  SET status = 'lose'
  WHERE status = 'pending'
    AND draw_slot = p_draw_slot
    AND draw_date = p_draw_date
    AND digit <> p_winning_digit;

  IF v_total_payout > 0 THEN
    UPDATE public.admin_wallet
    SET balance = balance - v_total_payout, updated_at = CURRENT_TIMESTAMP
    WHERE id = (SELECT id FROM public.admin_wallet LIMIT 1);
  END IF;

  RETURN json_build_object(
    'success', TRUE,
    'winning_digit', p_winning_digit,
    'draw_slot', p_draw_slot,
    'draw_date', p_draw_date,
    'winner_count', v_winner_count,
    'total_payout', v_total_payout,
    'admin_balance_before', v_admin_balance,
    'admin_balance_after', v_admin_balance - v_total_payout
  );
END;
$$;

-- Legacy: settle ALL pending without draw filter (dangerous if mixed; keep for old rows only)
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
  v_payout_amount INTEGER;
  v_admin_balance INTEGER;
BEGIN
  IF p_winning_digit < 0 OR p_winning_digit > 99 THEN
    RETURN json_build_object('success', FALSE, 'error', 'Invalid digit (must be 0-99)');
  END IF;

  SELECT balance INTO v_admin_balance
  FROM public.admin_wallet
  WHERE id = (SELECT id FROM public.admin_wallet LIMIT 1);

  FOR v_bet_record IN
    SELECT bet_id, user_id, amount
    FROM public.bets
    WHERE digit = p_winning_digit
      AND status = 'pending'
      AND draw_slot IS NULL
  LOOP
    v_payout_amount := v_bet_record.amount * 80;
    v_total_payout := v_total_payout + v_payout_amount;
    v_winner_count := v_winner_count + 1;

    UPDATE public.bets SET status = 'win' WHERE bet_id = v_bet_record.bet_id;

    INSERT INTO public.wallets (user_id, balance, updated_at)
    VALUES (v_bet_record.user_id, v_payout_amount, CURRENT_TIMESTAMP)
    ON CONFLICT (user_id)
    DO UPDATE SET
      balance = public.wallets.balance + v_payout_amount,
      updated_at = CURRENT_TIMESTAMP;
  END LOOP;

  UPDATE public.bets
  SET status = 'lose'
  WHERE status = 'pending'
    AND draw_slot IS NULL
    AND digit <> p_winning_digit;

  IF v_total_payout > 0 THEN
    UPDATE public.admin_wallet
    SET balance = balance - v_total_payout, updated_at = CURRENT_TIMESTAMP
    WHERE id = (SELECT id FROM public.admin_wallet LIMIT 1);
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

GRANT EXECUTE ON FUNCTION public.process_bet_win_for_draw (INTEGER, TEXT, DATE) TO service_role;
-- Admin runs via SQL editor / cron with elevated role; do not expose to anon.
