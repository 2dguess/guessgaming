-- Keep Admin Wallet and House score pool in sync.
-- Run in Supabase SQL Editor.

CREATE OR REPLACE FUNCTION public.admin_fund_admin_wallet(
  p_amount INTEGER,
  p_reason TEXT DEFAULT 'manual admin wallet top-up'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id UUID;
  v_wallet_id UUID;
  v_before INTEGER;
  v_after INTEGER;
  v_shard_avail BIGINT;
  v_shard_locked BIGINT;
BEGIN
  v_admin_id := auth.uid();
  IF v_admin_id IS NULL OR NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be > 0';
  END IF;

  INSERT INTO public.admin_wallet (balance, updated_at)
  VALUES (0, NOW())
  ON CONFLICT DO NOTHING;

  SELECT id, balance INTO v_wallet_id, v_before
  FROM public.admin_wallet
  ORDER BY updated_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_wallet_id IS NULL THEN
    RAISE EXCEPTION 'Admin wallet missing';
  END IF;

  v_after := v_before + p_amount;

  UPDATE public.admin_wallet
  SET balance = v_after, updated_at = NOW()
  WHERE id = v_wallet_id;

  -- Mirror the same fund into house shard pool (authoritative score pool).
  INSERT INTO public.house_wallet_shards (shard_id, available_balance, locked_balance, updated_at)
  VALUES (0, 0, 0, NOW())
  ON CONFLICT (shard_id) DO NOTHING;

  SELECT available_balance, locked_balance
  INTO v_shard_avail, v_shard_locked
  FROM public.house_wallet_shards
  WHERE shard_id = 0
  FOR UPDATE;

  UPDATE public.house_wallet_shards
  SET
    available_balance = available_balance + p_amount,
    updated_at = NOW()
  WHERE shard_id = 0;

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
    0,
    p_amount,
    0,
    v_shard_avail + p_amount,
    v_shard_locked,
    'admin_fund',
    COALESCE(NULLIF(trim(p_reason), ''), 'manual admin wallet top-up'),
    v_admin_id,
    NOW()
  );

  INSERT INTO public.audit_logs (
    actor_admin_id, action, target_type, target_id, reason, before_data, after_data, created_at
  ) VALUES (
    v_admin_id,
    'admin_fund_admin_wallet',
    'admin_wallet',
    v_wallet_id,
    p_reason,
    jsonb_build_object('balance', v_before, 'amount', p_amount),
    jsonb_build_object('balance', v_after),
    NOW()
  );

  RETURN jsonb_build_object(
    'ok', TRUE,
    'wallet_id', v_wallet_id,
    'before_balance', v_before,
    'after_balance', v_after,
    'funded_amount', p_amount
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_fund_admin_wallet(INTEGER, TEXT) TO authenticated;
