-- Fix house pool accounting:
-- 1) draw-specific settlement should NOT add extra house shard deltas
--    when place_bet already credits house pool.
-- 2) payout processing should deduct paid amount from house pool.
-- 3) reconcile stale locked balances from old logic.

-- -------------------------------------------------------------------
-- A) payout worker: when paid, subtract payout from house shard 0
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_due_payout_jobs(
  p_limit INTEGER DEFAULT 1000,
  p_max_attempts INTEGER DEFAULT 5
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_job RECORD;
  v_before INTEGER;
  v_before_avail INTEGER;
  v_after INTEGER;
  v_after_avail INTEGER;
  v_processed INTEGER := 0;
  v_paid INTEGER := 0;
  v_failed INTEGER := 0;
  v_shard_id INTEGER;
  v_shard_avail BIGINT;
  v_shard_locked BIGINT;
BEGIN
  FOR v_job IN
    SELECT *
    FROM public.payout_jobs
    WHERE status = 'queued'
      AND scheduled_at <= NOW()
    ORDER BY scheduled_at ASC, created_at ASC
    LIMIT GREATEST(1, LEAST(p_limit, 5000))
    FOR UPDATE SKIP LOCKED
  LOOP
    v_processed := v_processed + 1;
    BEGIN
      UPDATE public.payout_jobs
      SET status = 'processing', attempts = attempts + 1
      WHERE job_id = v_job.job_id;

      INSERT INTO public.wallets (user_id, balance, available_balance, locked_balance, updated_at)
      VALUES (v_job.user_id, 0, 0, 0, NOW())
      ON CONFLICT (user_id) DO NOTHING;

      SELECT balance, COALESCE(available_balance, balance, 0)
      INTO v_before, v_before_avail
      FROM public.wallets
      WHERE user_id = v_job.user_id
      FOR UPDATE;

      v_after := v_before + v_job.payout_amount;
      v_after_avail := v_before_avail + v_job.payout_amount;

      UPDATE public.wallets
      SET
        balance = v_after,
        available_balance = v_after_avail,
        updated_at = NOW()
      WHERE user_id = v_job.user_id;

      -- House pool payout debit from the winner's shard (matches pick credit sharding).
      v_shard_id := public.shard_for_uuid(v_job.user_id, 16);
      INSERT INTO public.house_wallet_shards (shard_id, available_balance, locked_balance, updated_at)
      VALUES (v_shard_id, 0, 0, NOW())
      ON CONFLICT (shard_id) DO NOTHING;

      SELECT available_balance, locked_balance
      INTO v_shard_avail, v_shard_locked
      FROM public.house_wallet_shards
      WHERE shard_id = v_shard_id
      FOR UPDATE;

      UPDATE public.house_wallet_shards
      SET
        available_balance = available_balance - v_job.payout_amount,
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
        -v_job.payout_amount,
        0,
        v_shard_avail - v_job.payout_amount,
        v_shard_locked,
        'bet_win_settle',
        'payout job paid (house pool debit)',
        v_job.user_id,
        NOW()
      );

      INSERT INTO public.coin_transactions (
        user_id, delta, balance_after, source_type, source_id, note, created_by, created_at
      ) VALUES (
        v_job.user_id, v_job.payout_amount, v_after, 'bet_win', v_job.bet_id,
        'Batched payout credit', v_job.user_id, NOW()
      );

      UPDATE public.payout_jobs
      SET status = 'paid', paid_at = NOW(), error_message = NULL
      WHERE job_id = v_job.job_id;

      v_paid := v_paid + 1;
    EXCEPTION
      WHEN OTHERS THEN
        UPDATE public.payout_jobs
        SET
          status = CASE WHEN attempts >= p_max_attempts THEN 'failed' ELSE 'queued' END,
          error_message = SQLERRM
        WHERE job_id = v_job.job_id;
        v_failed := v_failed + 1;
    END;
  END LOOP;

  UPDATE public.payout_runs pr
  SET
    status = 'completed',
    completed_at = NOW()
  WHERE pr.status IN ('prepared', 'processing')
    AND NOT EXISTS (
      SELECT 1
      FROM public.payout_jobs pj
      WHERE pj.run_id = pr.run_id
        AND pj.status IN ('queued', 'processing')
    );

  RETURN jsonb_build_object(
    'ok', TRUE,
    'processed', v_processed,
    'paid', v_paid,
    'failed', v_failed
  );
END;
$$;

-- -------------------------------------------------------------------
-- B) one-time reconcile stale locked balances from previous settle code
--    Keep only expected lock from unpaid payout jobs.
-- -------------------------------------------------------------------
WITH expected AS (
  SELECT
    public.shard_for_uuid(pj.user_id, 16) AS shard_id,
    COALESCE(SUM(pj.payout_amount), 0)::BIGINT AS expected_locked
  FROM public.payout_jobs pj
  WHERE pj.status IN ('queued', 'processing')
  GROUP BY public.shard_for_uuid(pj.user_id, 16)
),
all_shards AS (
  SELECT shard_id FROM public.house_wallet_shards
)
UPDATE public.house_wallet_shards h
SET
  locked_balance = COALESCE(e.expected_locked, 0),
  updated_at = NOW()
FROM all_shards s
LEFT JOIN expected e ON e.shard_id = s.shard_id
WHERE h.shard_id = s.shard_id;

