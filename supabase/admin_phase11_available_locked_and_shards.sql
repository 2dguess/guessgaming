-- Phase 11: available/locked balances + virtual shard house ledger
-- Run after previous phases.

-- =========================================================
-- 1) Wallet model upgrade: available + locked
-- =========================================================
ALTER TABLE public.wallets
  ADD COLUMN IF NOT EXISTS available_balance INTEGER NOT NULL DEFAULT 0 CHECK (available_balance >= 0),
  ADD COLUMN IF NOT EXISTS locked_balance INTEGER NOT NULL DEFAULT 0 CHECK (locked_balance >= 0);

-- Backfill old `balance` into new model once (safe idempotent).
UPDATE public.wallets
SET
  available_balance = CASE
    WHEN available_balance = 0 AND locked_balance = 0 THEN GREATEST(balance, 0)
    ELSE available_balance
  END,
  locked_balance = COALESCE(locked_balance, 0);

CREATE INDEX IF NOT EXISTS idx_wallets_available_balance ON public.wallets(available_balance);
CREATE INDEX IF NOT EXISTS idx_wallets_locked_balance ON public.wallets(locked_balance);

-- =========================================================
-- 2) Bets: idempotency key for burst-safe retries
-- =========================================================
ALTER TABLE public.bets
  ADD COLUMN IF NOT EXISTS client_bet_id UUID NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_bets_user_client_bet_id
ON public.bets(user_id, client_bet_id)
WHERE client_bet_id IS NOT NULL;

-- =========================================================
-- 3) House virtual shards + ledger
-- =========================================================
CREATE TABLE IF NOT EXISTS public.house_wallet_shards (
  shard_id INTEGER PRIMARY KEY,
  available_balance BIGINT NOT NULL DEFAULT 0,
  locked_balance BIGINT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (shard_id >= 0),
  CHECK (available_balance >= 0),
  CHECK (locked_balance >= 0)
);

CREATE TABLE IF NOT EXISTS public.house_ledger_transactions (
  tx_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shard_id INTEGER NOT NULL REFERENCES public.house_wallet_shards(shard_id) ON DELETE RESTRICT,
  delta_available BIGINT NOT NULL DEFAULT 0,
  delta_locked BIGINT NOT NULL DEFAULT 0,
  balance_available_after BIGINT NOT NULL,
  balance_locked_after BIGINT NOT NULL,
  source_type TEXT NOT NULL CHECK (
    source_type IN (
      'bet_lock',
      'bet_unlock_refund',
      'bet_lose_settle',
      'bet_win_reserve',
      'bet_win_payout',
      'admin_fund',
      'admin_adjust',
      'system'
    )
  ),
  source_id UUID NULL,
  note TEXT NULL,
  created_by UUID NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_house_ledger_shard_created
ON public.house_ledger_transactions(shard_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_house_ledger_source
ON public.house_ledger_transactions(source_type, source_id);

ALTER TABLE public.house_wallet_shards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.house_ledger_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can read house shards" ON public.house_wallet_shards;
CREATE POLICY "Admins can read house shards" ON public.house_wallet_shards
FOR SELECT USING (public.is_current_user_admin());

DROP POLICY IF EXISTS "Admins can read house ledger" ON public.house_ledger_transactions;
CREATE POLICY "Admins can read house ledger" ON public.house_ledger_transactions
FOR SELECT USING (public.is_current_user_admin());

DROP POLICY IF EXISTS "No direct insert house shards" ON public.house_wallet_shards;
CREATE POLICY "No direct insert house shards" ON public.house_wallet_shards
FOR INSERT WITH CHECK (FALSE);
DROP POLICY IF EXISTS "No direct update house shards" ON public.house_wallet_shards;
CREATE POLICY "No direct update house shards" ON public.house_wallet_shards
FOR UPDATE USING (FALSE);

DROP POLICY IF EXISTS "No direct insert house ledger" ON public.house_ledger_transactions;
CREATE POLICY "No direct insert house ledger" ON public.house_ledger_transactions
FOR INSERT WITH CHECK (FALSE);
DROP POLICY IF EXISTS "No direct update house ledger" ON public.house_ledger_transactions;
CREATE POLICY "No direct update house ledger" ON public.house_ledger_transactions
FOR UPDATE USING (FALSE);

-- Seed 16 shards (0..15) if missing.
INSERT INTO public.house_wallet_shards (shard_id, available_balance, locked_balance, updated_at)
SELECT s, 0, 0, NOW()
FROM generate_series(0, 15) AS s
ON CONFLICT (shard_id) DO NOTHING;

-- Optional one-time migrate current admin_wallet into shard 0 (if shard0 is empty).
DO $$
DECLARE
  v_admin_balance BIGINT;
  v_shard0 BIGINT;
BEGIN
  SELECT COALESCE(balance, 0) INTO v_admin_balance
  FROM public.admin_wallet
  ORDER BY updated_at DESC
  LIMIT 1;

  SELECT COALESCE(available_balance, 0) INTO v_shard0
  FROM public.house_wallet_shards
  WHERE shard_id = 0;

  IF v_admin_balance > 0 AND v_shard0 = 0 THEN
    UPDATE public.house_wallet_shards
    SET available_balance = v_admin_balance, updated_at = NOW()
    WHERE shard_id = 0;
  END IF;
END $$;

-- =========================================================
-- 4) Helpers
-- =========================================================
CREATE OR REPLACE FUNCTION public.shard_for_uuid(p_id UUID, p_shard_count INTEGER DEFAULT 16)
RETURNS INTEGER
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT MOD(ABS(hashtext(p_id::text)), GREATEST(1, p_shard_count));
$$;

CREATE OR REPLACE FUNCTION public.house_total_balance()
RETURNS TABLE (
  total_available BIGINT,
  total_locked BIGINT,
  total BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    COALESCE(SUM(h.available_balance), 0)::BIGINT AS total_available,
    COALESCE(SUM(h.locked_balance), 0)::BIGINT AS total_locked,
    (COALESCE(SUM(h.available_balance), 0) + COALESCE(SUM(h.locked_balance), 0))::BIGINT AS total
  FROM public.house_wallet_shards h
  WHERE public.is_current_user_admin();
$$;

-- =========================================================
-- 5) RPC: lock user bet amount (idempotent)
-- - deduct from user available
-- - add to user locked
-- - add to house locked shard
-- - insert bet row with client_bet_id
-- =========================================================
CREATE OR REPLACE FUNCTION public.place_bet_locked(
  p_client_bet_id UUID,
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
  v_existing_bet UUID;
  v_existing_status TEXT;
  v_avail INTEGER;
  v_locked INTEGER;
  v_shard_id INTEGER;
  v_house_avail BIGINT;
  v_house_locked BIGINT;
  v_bet_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_client_bet_id IS NULL THEN
    RAISE EXCEPTION 'client_bet_id is required';
  END IF;
  IF p_digit < 0 OR p_digit > 99 THEN
    RAISE EXCEPTION 'Invalid digit';
  END IF;
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Invalid amount';
  END IF;

  -- Idempotent retry check.
  SELECT b.bet_id, b.status
  INTO v_existing_bet, v_existing_status
  FROM public.bets b
  WHERE b.user_id = v_user_id
    AND b.client_bet_id = p_client_bet_id
  LIMIT 1;

  IF v_existing_bet IS NOT NULL THEN
    RETURN jsonb_build_object(
      'ok', TRUE,
      'idempotent', TRUE,
      'bet_id', v_existing_bet,
      'status', v_existing_status
    );
  END IF;

  INSERT INTO public.wallets (user_id, balance, available_balance, locked_balance, updated_at)
  VALUES (v_user_id, 0, 0, 0, NOW())
  ON CONFLICT (user_id) DO NOTHING;

  SELECT available_balance, locked_balance
  INTO v_avail, v_locked
  FROM public.wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF v_avail < p_amount THEN
    RETURN jsonb_build_object(
      'ok', FALSE,
      'error', 'Insufficient available balance',
      'available_balance', v_avail
    );
  END IF;

  UPDATE public.wallets
  SET
    available_balance = available_balance - p_amount,
    locked_balance = locked_balance + p_amount,
    balance = (available_balance - p_amount) + (locked_balance + p_amount),
    updated_at = NOW()
  WHERE user_id = v_user_id;

  v_shard_id := public.shard_for_uuid(v_user_id, 16);

  SELECT available_balance, locked_balance
  INTO v_house_avail, v_house_locked
  FROM public.house_wallet_shards
  WHERE shard_id = v_shard_id
  FOR UPDATE;

  UPDATE public.house_wallet_shards
  SET
    locked_balance = locked_balance + p_amount,
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
  ) VALUES (
    v_shard_id,
    0,
    p_amount,
    v_house_avail,
    v_house_locked + p_amount,
    'bet_lock',
    'User bet amount locked',
    v_user_id,
    NOW()
  );

  INSERT INTO public.bets (
    user_id, digit, amount, status, client_bet_id, created_at
  ) VALUES (
    v_user_id, p_digit, p_amount, 'pending', p_client_bet_id, NOW()
  )
  RETURNING bet_id INTO v_bet_id;

  RETURN jsonb_build_object(
    'ok', TRUE,
    'idempotent', FALSE,
    'bet_id', v_bet_id
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.shard_for_uuid(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.house_total_balance() TO authenticated;
GRANT EXECUTE ON FUNCTION public.place_bet_locked(UUID, INTEGER, INTEGER) TO authenticated;

