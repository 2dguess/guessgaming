-- House pool health-check + reconcile toolkit
-- Run in Supabase SQL editor.

-- =========================================================
-- 1) Health-check view
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
admin_wallet_sum AS (
  SELECT COALESCE(SUM(balance), 0)::BIGINT AS admin_wallet_total
  FROM public.admin_wallet
)
SELECT
  s.shard_available,
  s.shard_locked,
  s.shard_total,
  e.expected_locked,
  a.admin_wallet_total,
  (s.shard_locked - e.expected_locked) AS locked_drift,
  (a.admin_wallet_total - s.shard_total) AS admin_vs_shard_drift
FROM shard s, expected_lock e, admin_wallet_sum a;

-- Quick check:
-- SELECT * FROM public.house_pool_health;

-- =========================================================
-- 2) Reconcile function (safe, idempotent)
-- - sets shard locked to expected from unpaid payout jobs
-- - optionally syncs admin_wallet.balance to shard_total
-- =========================================================
CREATE OR REPLACE FUNCTION public.reconcile_house_pool(
  p_sync_admin_wallet BOOLEAN DEFAULT TRUE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_shard_available BIGINT := 0;
  v_shard_locked_before BIGINT := 0;
  v_expected_locked BIGINT := 0;
  v_shard_total BIGINT := 0;
  v_admin_before BIGINT := 0;
  v_admin_after BIGINT := 0;
  v_wallet_id UUID;
BEGIN
  IF NOT pg_try_advisory_lock(hashtext('house_pool_reconcile_lock')) THEN
    RAISE EXCEPTION 'Another reconcile is running';
  END IF;

  SELECT
    COALESCE(SUM(available_balance), 0)::BIGINT,
    COALESCE(SUM(locked_balance), 0)::BIGINT
  INTO v_shard_available, v_shard_locked_before
  FROM public.house_wallet_shards;

  SELECT COALESCE(SUM(payout_amount), 0)::BIGINT
  INTO v_expected_locked
  FROM public.payout_jobs
  WHERE status IN ('queued', 'processing');

  -- Reconcile each shard's locked to expected by shard from unpaid jobs.
  WITH expected AS (
    SELECT
      public.shard_for_uuid(pj.user_id, 16) AS shard_id,
      COALESCE(SUM(pj.payout_amount), 0)::BIGINT AS expected_locked
    FROM public.payout_jobs pj
    WHERE pj.status IN ('queued', 'processing')
    GROUP BY public.shard_for_uuid(pj.user_id, 16)
  )
  UPDATE public.house_wallet_shards h
  SET
    locked_balance = COALESCE(e.expected_locked, 0),
    updated_at = NOW()
  FROM (SELECT shard_id FROM public.house_wallet_shards) s
  LEFT JOIN expected e ON e.shard_id = s.shard_id
  WHERE h.shard_id = s.shard_id;

  SELECT
    COALESCE(SUM(available_balance), 0)::BIGINT,
    COALESCE(SUM(locked_balance), 0)::BIGINT
  INTO v_shard_available, v_expected_locked
  FROM public.house_wallet_shards;

  v_shard_total := v_shard_available + v_expected_locked;

  IF p_sync_admin_wallet THEN
    INSERT INTO public.admin_wallet (balance, updated_at)
    VALUES (0, NOW())
    ON CONFLICT DO NOTHING;

    SELECT id, balance
    INTO v_wallet_id, v_admin_before
    FROM public.admin_wallet
    ORDER BY updated_at DESC
    LIMIT 1
    FOR UPDATE;

    UPDATE public.admin_wallet
    SET balance = v_shard_total, updated_at = NOW()
    WHERE id = v_wallet_id;

    v_admin_after := v_shard_total;
  ELSE
    SELECT COALESCE(SUM(balance), 0)::BIGINT
    INTO v_admin_after
    FROM public.admin_wallet;
  END IF;

  PERFORM pg_advisory_unlock(hashtext('house_pool_reconcile_lock'));

  RETURN jsonb_build_object(
    'ok', TRUE,
    'shard_available', v_shard_available,
    'shard_locked', v_expected_locked,
    'shard_total', v_shard_total,
    'admin_wallet_after', v_admin_after,
    'synced_admin_wallet', p_sync_admin_wallet
  );
EXCEPTION
  WHEN OTHERS THEN
    PERFORM pg_advisory_unlock(hashtext('house_pool_reconcile_lock'));
    RAISE;
END;
$$;

GRANT EXECUTE ON FUNCTION public.reconcile_house_pool(BOOLEAN) TO authenticated;

-- Run reconcile manually:
-- SELECT public.reconcile_house_pool(TRUE);

